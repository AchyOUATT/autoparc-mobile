import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import 'autoparc_contact.dart';

export 'autoparc_contact.dart';

class AutoParcContactRepository {
  AutoParcContactRepository(this._client);
  final ApiClient _client;

  Future<AutoParcContact> fetch() async =>
      AutoParcContact.fromJson(await _client.get(Endpoints.appContact));

  Future<AutoParcContact> fetchSettings() async =>
      AutoParcContact.fromJson(await _client.get(Endpoints.contactSettings));

  Future<AutoParcContact> save(String phone) async => AutoParcContact.fromJson(
    await _client.put(Endpoints.contactSettings, data: {'phone': phone}),
  );
}

/// Le dernier numéro confirmé reste utilisable sans connexion.
class AutoParcContactCache {
  static const _key = 'autoparc_contact_phone:${Endpoints.baseUrl}';

  Future<AutoParcContact?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null || !AutoParcContact.isValid(value)) return null;
    return AutoParcContact.parse(value);
  }

  Future<void> write(AutoParcContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, contact.phone);
  }
}

final autoparcContactRepositoryProvider = Provider<AutoParcContactRepository>(
  (ref) => AutoParcContactRepository(ref.watch(apiClientProvider)),
);

final autoparcContactCacheProvider = Provider<AutoParcContactCache>(
  (_) => AutoParcContactCache(),
);

final autoparcContactProvider =
    StateNotifierProvider<AutoParcContactNotifier, AutoParcContact>((ref) {
      return AutoParcContactNotifier(
        ref.watch(autoparcContactRepositoryProvider),
        ref.watch(autoparcContactCacheProvider),
      );
    });

class AutoParcContactNotifier extends StateNotifier<AutoParcContact> {
  AutoParcContactNotifier(this._repository, this._cache)
    : super(AutoParcContact.fallback) {
    _cacheReady = _restoreCache();
  }

  final AutoParcContactRepository _repository;
  final AutoParcContactCache _cache;
  late final Future<void> _cacheReady;
  Future<bool>? _refreshing;
  int _revision = 0;
  bool _saving = false;

  Future<void> _restoreCache() async {
    try {
      final saved = await _cache.read();
      if (mounted && _revision == 0 && saved != null) state = saved;
    } catch (_) {
      // Préférences indisponibles : le réseau peut toujours fournir le contact.
    }
  }

  Future<void> _remember(AutoParcContact contact) async {
    try {
      await _cache.write(contact);
    } catch (_) {
      // L'enregistrement serveur réussi reste valable si le disque est plein.
    }
  }

  /// Appelé au démarrage et au retour au premier plan, sans bloquer l'interface.
  Future<bool> refresh() {
    if (_saving) return Future.value(false);
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _refresh() async {
    await _cacheReady;
    final revision = _revision;
    try {
      final contact = await _repository.fetch();
      if (!mounted || revision != _revision || _saving) return false;
      state = contact;
      await _remember(contact);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Le formulaire charge la valeur serveur avant de permettre sa modification.
  Future<AutoParcContact> loadSettings() async {
    await _cacheReady;
    final revision = ++_revision;
    final contact = await _repository.fetchSettings();
    if (mounted && revision == _revision) {
      state = contact;
      await _remember(contact);
    }
    return contact;
  }

  Future<AutoParcContact> save(String phone) async {
    final value = AutoParcContact.parse(phone);
    if (_saving) throw StateError('Un enregistrement est déjà en cours.');
    _saving = true;
    ++_revision;
    try {
      final contact = await _repository.save(value.phone);
      ++_revision; // Une ancienne lecture publique ne peut annuler ce changement.
      if (mounted) state = contact;
      await _remember(contact);
      return contact;
    } finally {
      _saving = false;
    }
  }
}
