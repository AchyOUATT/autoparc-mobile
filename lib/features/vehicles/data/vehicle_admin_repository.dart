import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/local/catalog_local_cache.dart';
import '../../catalog/data/models/vehicle.dart';
import 'models/catalog_refs.dart';

final vehicleAdminRepositoryProvider = Provider<VehicleAdminRepository>(
  (ref) => VehicleAdminRepository(
    ref.read(apiClientProvider),
    ref.read(catalogLocalCacheProvider),
  ),
);

class VehicleAdminRepository {
  final ApiClient         _client;
  final CatalogLocalCache _cache;

  const VehicleAdminRepository(this._client, this._cache);

  // ── Références catalogue ──────────────────────────────────────────────────

  /// Charge les tables de référence.
  /// Priorité : cache SQLite local (TTL 24 h) → appel API si expiré.
  Future<CatalogRefs> loadRefs() async {
    // 1. Cache frais ?
    final cached = await _cache.loadRawRefs();
    if (cached != null) return _parseRefs(cached);

    // 2. Appel réseau
    final json = await _client.get(Endpoints.catalogSync);

    // 3. Sauvegarde locale
    await _cache.saveRefs(json);

    return _parseRefs(json);
  }

  /// Charge les pays.
  /// Priorité : cache SQLite local (TTL 24 h) → appel API si expiré.
  Future<List<CountryRef>> loadCountries() async {
    // 1. Cache frais ?
    final cached = await _cache.loadRawCountries();
    if (cached != null) return _parseCountries(cached);

    // 2. Appel réseau
    final list = await _client.getList(Endpoints.catalogCountries);

    // 3. Sauvegarde locale
    await _cache.saveCountries(list);

    return _parseCountries(list);
  }

  // ── CRUD véhicules (staff) ────────────────────────────────────────────────

  Future<Vehicle> createVehicle(Map<String, dynamic> payload) async {
    final json = await _client.post(Endpoints.staffVehicles, data: payload);
    return Vehicle.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> payload) async {
    final json = await _client.put(Endpoints.staffVehicleDetail(id), data: payload);
    return Vehicle.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(int id) async {
    await _client.delete(Endpoints.staffVehicleDetail(id));
  }

  Future<Vehicle> syncVehicleFeatures(int id, List<int> featureIds) async {
    final json = await _client.put(
      Endpoints.vehicleFeatures(id),
      data: {'features': featureIds},
    );
    return Vehicle.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  CatalogRefs _parseRefs(Map<String, dynamic> json) {
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

    final brands   = _list(json, 'brands',        BrandRef.fromJson)
        ..sort((a, b) => cmp(a.name, b.name));
    final models   = _list(json, 'vehicle_models', ModelRef.fromJson)
        ..sort((a, b) => cmp(a.name, b.name));
    final trims    = _list(json, 'trims',          TrimRef.fromJson)
        ..sort((a, b) => cmp(a.name, b.name));
    final engines  = _list(json, 'engine_types',   EngineTypeRef.fromJson)
        ..sort((a, b) => cmp(a.label, b.label));
    final drives   = _list(json, 'drivetrains',    DrivetrainRef.fromJson)
        ..sort((a, b) => cmp(a.label, b.label));
    final colors   = _list(json, 'colors',         ColorRef.fromJson)
        ..sort((a, b) => cmp(a.name, b.name));
    final features = _list(json, 'features',       FeatureRef.fromJson)
        ..sort((a, b) => cmp(a.name, b.name));
    final locs     = _list(json, 'locations',      LocationRef.fromJson)
        ..sort((a, b) => cmp(a.displayLabel, b.displayLabel));

    return CatalogRefs(
      brands:        brands,
      vehicleModels: models,
      trims:         trims,
      engineTypes:   engines,
      drivetrains:   drives,
      colors:        colors,
      features:      features,
      locations:     locs,
    );
  }

  List<CountryRef> _parseCountries(List<dynamic> list) =>
      (list
          .map((e) => CountryRef.fromJson(e as Map<String, dynamic>))
          .toList())
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  // ── Helper ────────────────────────────────────────────────────────────────

  static List<T> _list<T>(
    dynamic json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = json[key] as List<dynamic>? ?? [];
    return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
