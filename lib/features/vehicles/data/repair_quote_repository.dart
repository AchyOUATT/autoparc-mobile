import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../partner_accounts/data/partner_repository.dart';
import 'models/fault_declaration.dart';

final repairQuoteRepositoryProvider = Provider<RepairQuoteRepository>(
  (ref) => RepairQuoteRepository(
    ref.read(apiClientProvider),
    ref.read(partnerRepositoryProvider),
  ),
);

enum RepairQuoteHostKind { listing, vehicle, partnerVehicle }

class RepairQuoteHost {
  const RepairQuoteHost.listing(this.id) : kind = RepairQuoteHostKind.listing;

  const RepairQuoteHost.vehicle(this.id, {bool partner = false})
    : kind = partner
          ? RepairQuoteHostKind.partnerVehicle
          : RepairQuoteHostKind.vehicle;

  final RepairQuoteHostKind kind;
  final int id;
}

class RepairQuoteActions {
  const RepairQuoteActions({
    required this.uploadPrivate,
    required this.deletePrivate,
    this.publish,
    this.deletePublished,
    this.canPublish = false,
  });

  final Future<DeclaredVehicleFault> Function({
    required int faultId,
    required String filename,
    required List<int> bytes,
  })
  uploadPrivate;

  final Future<void> Function({required int faultId}) deletePrivate;

  final Future<DeclaredVehicleFault> Function({
    required int faultId,
    required String filename,
    required List<int> bytes,
  })?
  publish;

  final Future<void> Function({required int faultId})? deletePublished;

  final bool canPublish;
}

class RepairQuoteRepository {
  const RepairQuoteRepository(this._client, this._partner);

  final ApiClient _client;
  final PartnerRepository _partner;

  RepairQuoteActions actionsFor(
    RepairQuoteHost host, {
    bool canPublish = false,
  }) {
    final publishable =
        canPublish && host.kind != RepairQuoteHostKind.partnerVehicle;
    return RepairQuoteActions(
      uploadPrivate:
          ({
            required int faultId,
            required String filename,
            required List<int> bytes,
          }) => _upload(
            host,
            faultId,
            filename: filename,
            bytes: bytes,
            publish: false,
          ),
      deletePrivate: ({required int faultId}) =>
          _delete(host, faultId, published: false),
      publish: publishable
          ? ({
              required int faultId,
              required String filename,
              required List<int> bytes,
            }) => _upload(
              host,
              faultId,
              filename: filename,
              bytes: bytes,
              publish: true,
            )
          : null,
      deletePublished: publishable
          ? ({required int faultId}) => _delete(host, faultId, published: true)
          : null,
      canPublish: publishable,
    );
  }

  String _path(RepairQuoteHost host, int faultId, {required bool publish}) {
    return switch (host.kind) {
      RepairQuoteHostKind.listing =>
        publish
            ? '/private-listing-reviews/${host.id}/faults/$faultId/repair-quote/publish'
            : '/my/private-listings/${host.id}/faults/$faultId/repair-quote',
      RepairQuoteHostKind.vehicle =>
        publish
            ? '/vehicles/${host.id}/faults/$faultId/repair-quote/publish'
            : '/vehicles/${host.id}/faults/$faultId/repair-quote',
      RepairQuoteHostKind.partnerVehicle =>
        '/partner/vehicles/${host.id}/faults/$faultId/repair-quote',
    };
  }

  String _deletePath(
    RepairQuoteHost host,
    int faultId, {
    required bool published,
  }) {
    return switch (host.kind) {
      RepairQuoteHostKind.listing =>
        published
            ? '/private-listing-reviews/${host.id}/faults/$faultId/repair-quote/published'
            : '/my/private-listings/${host.id}/faults/$faultId/repair-quote',
      RepairQuoteHostKind.vehicle =>
        published
            ? '/vehicles/${host.id}/faults/$faultId/repair-quote/published'
            : '/vehicles/${host.id}/faults/$faultId/repair-quote',
      RepairQuoteHostKind.partnerVehicle =>
        '/partner/vehicles/${host.id}/faults/$faultId/repair-quote',
    };
  }

  Future<DeclaredVehicleFault> _upload(
    RepairQuoteHost host,
    int faultId, {
    required String filename,
    required List<int> bytes,
    required bool publish,
  }) async {
    final path = _path(host, faultId, publish: publish);
    final Map<String, dynamic> json;
    if (host.kind == RepairQuoteHostKind.partnerVehicle) {
      json = await _partner.uploadRepairQuote(
        host.id,
        faultId,
        filename: filename,
        bytes: bytes,
      );
      return DeclaredVehicleFault.fromJson(json);
    }
    json = await _client.uploadDocument(
      path,
      filename: filename,
      bytes: bytes,
      fields: const {},
    );
    return DeclaredVehicleFault.fromJson(
      Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  Future<void> _delete(
    RepairQuoteHost host,
    int faultId, {
    required bool published,
  }) async {
    if (host.kind == RepairQuoteHostKind.partnerVehicle) {
      await _partner.deleteRepairQuote(host.id, faultId);
      return;
    }
    await _client.delete(_deletePath(host, faultId, published: published));
  }
}
