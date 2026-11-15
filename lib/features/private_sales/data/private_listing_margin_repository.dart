import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';

class PrivateListingMargin {
  const PrivateListingMargin({
    required this.taux,
    this.tauxPrecedent,
    this.modifieParId,
    this.modifieParNom,
    this.modifieLe,
  });

  final double taux;
  final double? tauxPrecedent;
  final int? modifieParId;
  final String? modifieParNom;
  final DateTime? modifieLe;

  factory PrivateListingMargin.fromPublic(Map<String, dynamic> json) {
    return PrivateListingMargin(taux: _nombre(json['taux']) ?? 0);
  }

  factory PrivateListingMargin.fromAdmin(Map<String, dynamic> json) {
    final changement = json['derniere_modification'];
    final Map<String, dynamic>? detail = changement is Map
        ? Map<String, dynamic>.from(changement)
        : null;
    final auteur = detail?['modifie_par'];
    final Map<String, dynamic>? personne = auteur is Map
        ? Map<String, dynamic>.from(auteur)
        : null;
    return PrivateListingMargin(
      taux: _nombre(json['taux']) ?? 0,
      tauxPrecedent: _nombre(detail?['taux_precedent']),
      modifieParId: int.tryParse('${personne?['id'] ?? ''}'),
      modifieParNom: personne?['name']?.toString(),
      modifieLe: DateTime.tryParse('${detail?['modifie_le'] ?? ''}'),
    );
  }

  static double? _nombre(Object? value) =>
      value == null ? null : double.tryParse('$value');
}

class PrivateListingMarginRepository {
  PrivateListingMarginRepository(this._client);
  final ApiClient _client;

  Future<double> tauxPublic() async => PrivateListingMargin.fromPublic(
    await _client.get(Endpoints.appPrivateListingMargin),
  ).taux;

  Future<PrivateListingMargin> lireReglage() async =>
      PrivateListingMargin.fromAdmin(
        await _client.get(Endpoints.privateListingMarginSettings),
      );

  Future<PrivateListingMargin> enregistrer(double taux) async =>
      PrivateListingMargin.fromAdmin(
        await _client.put(
          Endpoints.privateListingMarginSettings,
          data: {'taux': taux},
        ),
      );
}

final privateListingMarginRepositoryProvider =
    Provider<PrivateListingMarginRepository>(
      (ref) => PrivateListingMarginRepository(ref.watch(apiClientProvider)),
    );

final privateListingMarginRateProvider = FutureProvider<double>((ref) async {
  return ref.watch(privateListingMarginRepositoryProvider).tauxPublic();
});
