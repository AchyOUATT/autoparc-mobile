import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../partner_accounts/data/partner_repository.dart' as partner;
import '../presentation/pages/vehicle_form_mode.dart';

final equipmentDocumentsRepositoryProvider =
    Provider<EquipmentDocumentsRepository>(
      (ref) => EquipmentDocumentsRepository(
        ref.read(apiClientProvider),
        ref.read(partner.partnerRepositoryProvider),
      ),
    );

enum EquipmentDocumentType {
  ownership,
  registration,
  inspection,
  insurance,
  other,
}

/// Private metadata only: there is deliberately no public URL or storage path.
class EquipmentDocument {
  const EquipmentDocument({
    required this.id,
    required this.type,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.status,
    this.expiresOn,
    this.uploadedAt,
  });

  factory EquipmentDocument.fromJson(
    Map<String, dynamic> json,
  ) => EquipmentDocument(
    id: (json['id'] as num).toInt(),
    type: EquipmentDocumentType.values.firstWhere(
      (value) => value.name == json['document_type'],
      orElse: () => EquipmentDocumentType.other,
    ),
    originalName: json['original_name'] as String? ?? '',
    mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
    size: (json['size'] as num?)?.toInt() ?? 0,
    // This is a declared document, not an inspection or verification decision.
    status: json['status'] as String? ?? 'provided',
    expiresOn: json['expires_on'] as String?,
    uploadedAt: DateTime.tryParse(json['uploaded_at']?.toString() ?? ''),
  );

  final int id;
  final EquipmentDocumentType type;
  final String originalName;
  final String mimeType;
  final int size;
  final String status;
  final String? expiresOn;
  final DateTime? uploadedAt;

  bool isExpired([DateTime? now]) {
    final expiry = DateTime.tryParse(expiresOn ?? '');
    if (expiry == null) return false;
    final today = now ?? DateTime.now();
    return expiry.isBefore(DateTime(today.year, today.month, today.day));
  }
}

/// Chooses the existing authenticated client for each session mode.
class EquipmentDocumentsRepository {
  const EquipmentDocumentsRepository(this._staff, this._partner);

  final ApiClient _staff;
  final partner.PartnerRepository _partner;

  String _path(int vehicleId) => '/vehicles/$vehicleId/equipment-documents';

  Future<List<EquipmentDocument>> documents(
    int vehicleId, {
    required VehicleFormMode mode,
  }) async {
    final List<dynamic> items;
    if (mode.estPartenaire) {
      items = await _partner.equipmentDocuments(vehicleId);
    } else {
      final json = await _staff.get(_path(vehicleId));
      items = json['data'] as List? ?? const [];
    }
    return items
        .map(
          (item) => EquipmentDocument.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<EquipmentDocument> upload(
    int vehicleId, {
    required VehicleFormMode mode,
    required String filename,
    required List<int> bytes,
    required EquipmentDocumentType type,
    String? expiresOn,
  }) async {
    final fields = <String, String>{
      'document_type': type.name,
      if (expiresOn != null && expiresOn.isNotEmpty) 'expires_on': expiresOn,
    };
    final Map<String, dynamic> data;
    if (mode.estPartenaire) {
      data = await _partner.uploadEquipmentDocument(
        vehicleId,
        filename: filename,
        bytes: bytes,
        fields: fields,
      );
    } else {
      final json = await _staff.uploadDocument(
        _path(vehicleId),
        filename: filename,
        bytes: bytes,
        fields: fields,
      );
      data = Map<String, dynamic>.from(json['data'] as Map);
    }
    return EquipmentDocument.fromJson(data);
  }

  Future<List<int>> download(
    int vehicleId,
    int documentId, {
    required VehicleFormMode mode,
  }) => mode.estPartenaire
      ? _partner.downloadEquipmentDocument(vehicleId, documentId)
      : _staff.downloadBytes('${_path(vehicleId)}/$documentId/download');

  Future<void> delete(
    int vehicleId,
    int documentId, {
    required VehicleFormMode mode,
  }) async {
    if (mode.estPartenaire) {
      await _partner.deleteEquipmentDocument(vehicleId, documentId);
    } else {
      await _staff.delete('${_path(vehicleId)}/$documentId');
    }
  }
}
