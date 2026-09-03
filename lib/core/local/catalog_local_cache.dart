import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

final catalogLocalCacheProvider =
    Provider<CatalogLocalCache>((_) => CatalogLocalCache());

/// Cache SQLite local pour les données de référence du catalogue.
///
/// Stratégie : TTL de 24 h.
/// - Si l'entrée existe et a moins de 24 h → servie depuis SQLite (0 appel réseau).
/// - Sinon → appel API, résultat stocké, TTL réinitialisé.
/// - Invalider manuellement via [clear] après une mise à jour admin.
class CatalogLocalCache {
  static const _kRefs      = 'refs';
  static const _kCountries = 'countries';
  static const _ttlMs      = 24 * 60 * 60 * 1000; // 24 h

  Database? _db;

  // ── Ouverture / initialisation ─────────────────────────────────────────────

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir  = await getDatabasesPath();
    final path = p.join(dir, 'catalog_cache.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE entries (
          key        TEXT PRIMARY KEY,
          data       TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      '''),
    );
    return _db!;
  }

  // ── Refs catalogue (/catalog/sync) ────────────────────────────────────────

  /// Retourne les refs brutes si le cache est frais, null sinon.
  Future<Map<String, dynamic>?> loadRawRefs() async {
    if (!await _isFresh(_kRefs)) return null;
    return _load(_kRefs);
  }

  /// Persiste la réponse brute de /catalog/sync.
  Future<void> saveRefs(Map<String, dynamic> json) => _save(_kRefs, json);

  // ── Pays (/catalog/countries) ─────────────────────────────────────────────

  /// Retourne la liste brute des pays si le cache est frais, null sinon.
  Future<List<dynamic>?> loadRawCountries() async {
    if (!await _isFresh(_kCountries)) return null;
    final m = await _load(_kCountries);
    return m?['list'] as List<dynamic>?;
  }

  /// Persiste la liste brute des pays.
  Future<void> saveCountries(List<dynamic> list) =>
      _save(_kCountries, {'list': list});

  // ── Invalidation ──────────────────────────────────────────────────────────

  /// Vide toutes les entrées → forcer un rechargement depuis l'API au prochain accès.
  Future<void> clear() async {
    final db = await _open();
    await db.delete('entries');
  }

  // ── Helpers privés ────────────────────────────────────────────────────────

  Future<bool> _isFresh(String key) async {
    final db  = await _open();
    final row = await db.query(
      'entries',
      columns:   ['updated_at'],
      where:     'key = ?',
      whereArgs: [key],
    );
    if (row.isEmpty) return false;
    final age = DateTime.now().millisecondsSinceEpoch - (row.first['updated_at'] as int);
    return age < _ttlMs;
  }

  Future<Map<String, dynamic>?> _load(String key) async {
    final db  = await _open();
    final row = await db.query(
      'entries',
      columns:   ['data'],
      where:     'key = ?',
      whereArgs: [key],
    );
    if (row.isEmpty) return null;
    return jsonDecode(row.first['data'] as String) as Map<String, dynamic>;
  }

  Future<void> _save(String key, Map<String, dynamic> data) async {
    final db = await _open();
    await db.insert(
      'entries',
      {
        'key':        key,
        'data':       jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
