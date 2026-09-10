import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Réponses de `/catalog/sync` : le corps complet, puis les deltas.
Map<String, dynamic> _refs(
  String serverTime, {
  List<Map<String, dynamic>> brands = const [],
}) => {
  'server_time':    serverTime,
  'brands':         brands,
  'vehicle_models': const [],
  'trims':          const [],
  'engine_types':   const [],
  'drivetrains':    const [],
  'colors':         const [],
  'features':       const [],
  'locations':      const [],
};

Map<String, dynamic> _brand(int id, String name) =>
    {'id': id, 'name': name, 'is_active': true};

/// Client qui répond depuis un scénario en mémoire et retient les appels reçus.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this._respond);

  final Map<String, dynamic> Function(Map<String, dynamic>? params) _respond;
  final calls = <Map<String, dynamic>?>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    calls.add(params);
    return _respond(params);
  }
}

/// Cache en mémoire : évite sqflite, qui exige un appareil.
class _FakeCache extends CatalogLocalCache {
  _FakeCache({this.stored, this.savedAt});

  Map<String, dynamic>? stored;
  DateTime?             savedAt;
  int                   writes = 0;

  @override
  Future<CachedPayload?> loadRefs() async =>
      stored == null ? null : CachedPayload(stored!, savedAt!);

  @override
  Future<void> saveRefs(Map<String, dynamic> json) async {
    stored  = json;
    savedAt = DateTime.now();
    writes++;
  }
}

void main() {
  group('VehicleAdminRepository.loadRefs', () {
    test('sans cache : appel complet, sans paramètre « since »', () async {
      final client = _FakeApiClient((_) => _refs(
            '2026-09-10T08:00:00+00:00',
            brands: [_brand(1, 'Toyota')],
          ));
      final cache = _FakeCache();

      final refs = await VehicleAdminRepository(client, cache).loadRefs();

      expect(client.calls, [null]);
      expect(refs.brands.map((b) => b.name), ['Toyota']);
      expect(cache.writes, 1);
    });

    test('cache écrit il y a 5 min : servi sans toucher au réseau', () async {
      final client = _FakeApiClient((_) => fail('aucun appel attendu'));
      final cache  = _FakeCache(
        stored: _refs('2026-09-10T08:00:00+00:00',
            brands: [_brand(1, 'Toyota')]),
        savedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final refs = await VehicleAdminRepository(client, cache).loadRefs();

      expect(client.calls, isEmpty);
      expect(refs.brands.map((b) => b.name), ['Toyota']);
    });

    test('cache d\'une heure : delta fusionné sur les lignes existantes',
        () async {
      final client = _FakeApiClient((_) => _refs(
            '2026-09-10T09:00:00+00:00',
            brands: [
              _brand(2, 'Hyundai'),        // renommé côté serveur
              _brand(3, 'Suzuki'),         // nouvelle marque
            ],
          ));
      final cache = _FakeCache(
        stored: _refs('2026-09-10T08:00:00+00:00', brands: [
          _brand(1, 'Toyota'),
          _brand(2, 'Hyunday'),            // faute corrigée depuis
        ]),
        savedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final refs = await VehicleAdminRepository(client, cache).loadRefs();

      // Le curseur du cache part bien dans la requête…
      expect(client.calls, [
        {'since': '2026-09-10T08:00:00+00:00'}
      ]);
      // …la ligne modifiée remplace l'ancienne, la nouvelle s'ajoute, et
      // celle qu'aucun delta ne mentionne survit.
      expect(refs.brands.map((b) => b.name), ['Hyundai', 'Suzuki', 'Toyota']);
      // Le prochain appel repartira du nouveau curseur.
      expect(cache.stored!['server_time'], '2026-09-10T09:00:00+00:00');
    });

    test('réseau indisponible : la dernière version connue est renvoyée',
        () async {
      final client = _FakeApiClient((_) => throw Exception('hors ligne'));
      final cache  = _FakeCache(
        stored: _refs('2026-09-10T08:00:00+00:00',
            brands: [_brand(1, 'Toyota')]),
        savedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final refs = await VehicleAdminRepository(client, cache).loadRefs();

      expect(refs.brands.map((b) => b.name), ['Toyota']);
      expect(cache.writes, 0);
    });

    test('cache vieux d\'un mois : rechargement complet, pas de delta',
        () async {
      final client = _FakeApiClient((_) => _refs(
            '2026-09-10T09:00:00+00:00',
            brands: [_brand(1, 'Toyota')],
          ));
      final cache = _FakeCache(
        stored: _refs('2026-08-10T08:00:00+00:00', brands: [
          _brand(1, 'Toyota'),
          _brand(9, 'Marque supprimée depuis'),
        ]),
        savedAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      final refs = await VehicleAdminRepository(client, cache).loadRefs();

      expect(client.calls, [null]);
      // Le rechargement complet est ce qui purge les lignes supprimées :
      // un delta ne les signale pas.
      expect(refs.brands.map((b) => b.name), ['Toyota']);
    });
  });
}
