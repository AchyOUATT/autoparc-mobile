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

  /// Silence total : sous ce délai, le cache est servi sans rien demander au
  /// serveur. Évite un aller-retour à chaque redémarrage rapproché.
  static const _quietWindow = Duration(minutes: 15);

  /// Au-delà, on retélécharge tout. Le mode incrémental ne signale pas les
  /// suppressions : ce rechargement périodique est ce qui purge du cache une
  /// marque ou une agence retirée côté serveur.
  static const _fullReloadAfter = Duration(days: 7);

  /// Charge les tables de référence (≈ 79 Ko en version complète).
  ///
  /// Stratégie, du moins coûteux au plus coûteux :
  /// 1. cache écrit il y a moins de 15 min → servi tel quel, zéro réseau ;
  /// 2. cache plus ancien → `/catalog/sync?since=…` ne renvoie que les lignes
  ///    modifiées depuis, soit quelques centaines d'octets tant que rien ne
  ///    bouge — et les ajouts du personnel apparaissent au lancement suivant
  ///    au lieu d'attendre l'expiration d'un TTL ;
  /// 3. pas de cache, cache vieux d'une semaine ou format inconnu → appel complet.
  ///
  /// En cas d'échec réseau, la dernière version connue est renvoyée : la
  /// connectivité est trop irrégulière pour qu'un formulaire reste vide alors
  /// que les données sont déjà sur l'appareil.
  Future<CatalogRefs> loadRefs() async {
    final cached    = await _cache.loadRefs();
    final since     = cached?.data['server_time'] as String?;
    final canDelta  = cached != null && since != null &&
                      cached.age < _fullReloadAfter;

    if (canDelta && cached.age < _quietWindow) {
      return _parseRefs(cached.data);
    }

    try {
      if (canDelta) {
        final delta  = await _client.get(
          Endpoints.catalogSync,
          params: {'since': since},
        );
        final merged = _mergeRefs(cached.data, delta);
        await _cache.saveRefs(merged);
        return _parseRefs(merged);
      }

      final json = await _client.get(Endpoints.catalogSync);
      await _cache.saveRefs(json);
      return _parseRefs(json);
    } catch (_) {
      if (cached != null) return _parseRefs(cached.data);
      rethrow;
    }
  }

  /// Applique un delta de `/catalog/sync?since=…` sur les refs en cache.
  ///
  /// Chaque liste est indexée par `id` : une ligne présente dans le delta
  /// remplace son homologue locale, une nouvelle est ajoutée. Les clés scalaires
  /// du delta (dont `server_time`, curseur du prochain appel) écrasent les anciennes.
  Map<String, dynamic> _mergeRefs(
    Map<String, dynamic> cached,
    Map<String, dynamic> delta,
  ) {
    final merged = Map<String, dynamic>.from(cached);

    delta.forEach((key, value) {
      if (value is! List) {
        merged[key] = value;
        return;
      }

      final byId = <Object?, Map<String, dynamic>>{
        for (final row in (cached[key] as List<dynamic>? ?? const []))
          (row as Map<String, dynamic>)['id']: row,
      };
      for (final row in value) {
        final map = row as Map<String, dynamic>;
        byId[map['id']] = map;
      }
      merged[key] = byId.values.toList();
    });

    return merged;
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
