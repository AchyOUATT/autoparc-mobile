import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../catalog/data/catalog_repository.dart';
import 'models/customer_need.dart';

final needsRepositoryProvider = Provider<NeedsRepository>(
  (ref) => NeedsRepository(ref.read(apiClientProvider)),
);

/// Marques publiques — triées alphabétiquement, dédupliquées par id.
final publicBrandsProvider =
    FutureProvider.autoDispose<List<({int id, String name})>>((ref) async {
  final client = ref.read(apiClientProvider);
  final json   = await client.get('/catalog/brands');
  final list   = json['data'] as List<dynamic>? ?? [];
  final seen   = <int>{};
  return list
      .map((e) => e as Map<String, dynamic>)
      .map((e) => (id: e['id'] as int, name: e['name'] as String))
      .where((b) => seen.add(b.id))     // élimine les doublons
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

/// Modèles d'une marque — chargés à la demande, dédupliqués par id.
final publicModelsProvider =
    FutureProvider.autoDispose.family<List<({int id, String name})>, int>(
        (ref, brandId) async {
  final client = ref.read(apiClientProvider);
  final json   = await client.get('/catalog/brands/$brandId/models');
  final list   = json['data'] as List<dynamic>? ?? [];
  final seen   = <int>{};
  return list
      .map((e) => e as Map<String, dynamic>)
      .map((e) => (id: e['id'] as int, name: e['name'] as String))
      .where((m) => seen.add(m.id))     // élimine les doublons
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

/// Catégories de pièces détachées — pour le formulaire de besoin.
///
/// Passe par le dépôt catalogue plutôt que d'appeler l'endpoint en direct :
/// c'est le même arbre que la barre de filtres de la page « Pièces », et il est
/// désormais servi depuis le cache SQLite.
final publicPartCategoriesProvider =
    FutureProvider.autoDispose<List<({int id, String name})>>((ref) async {
  final categories = await ref.read(catalogRepositoryProvider).getPartCategories();
  return categories.map((c) => (id: c.id, name: c.name)).toList();
});

/// Fabricants / équipementiers — pour le formulaire de besoin.
final publicManufacturersProvider =
    FutureProvider.autoDispose<List<({int id, String name})>>((ref) async {
  final client = ref.read(apiClientProvider);
  final json   = await client.get('/catalog/manufacturers');
  final list   = json as List<dynamic>? ?? [];
  return list
      .map((e) => e as Map<String, dynamic>)
      .map((e) => (id: e['id'] as int, name: e['name'] as String))
      .toList();
});

class NeedsRepository {
  final ApiClient _client;
  const NeedsRepository(this._client);

  /// Soumet un besoin — accessible sans authentification.
  Future<void> submitNeed(Map<String, dynamic> payload) async {
    await _client.post('/needs', data: payload);
  }

  /// Besoins du client connecté — filtré par firebase_uid.
  Future<List<CustomerNeed>> getMyNeeds(String firebaseUid) async {
    final json = await _client.get('/needs/mine', params: {'firebase_uid': firebaseUid});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => CustomerNeed.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Liste tous les besoins — staff uniquement.
  Future<List<CustomerNeed>> getNeeds({String? type, String? status}) async {
    final params = <String, dynamic>{
      'per_page': 50,
      if (type   != null) 'type':   type,
      if (status != null) 'status': status,
    };
    final json = await _client.get('/needs', params: params);
    final data = json['data'] as List<dynamic>;
    return data.map((e) => CustomerNeed.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Met à jour le statut d'un besoin — staff uniquement.
  Future<CustomerNeed> updateStatus(
    int id, {
    required String status,
    String? staffNotes,
  }) async {
    final json = await _client.put('/needs/$id', data: {
      'status': status,
      if (staffNotes != null) 'staff_notes': staffNotes,
    });
    return CustomerNeed.fromJson(json['data'] as Map<String, dynamic>);
  }
}
