import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

final catalogLocalCacheProvider =
    Provider<CatalogLocalCache>((_) => CatalogLocalCache());

/// Entrée du cache accompagnée de sa date d'écriture.
///
/// Les données de référence ne sont pas rechargées de la même façon selon leur
/// fraîcheur : l'appelant a donc besoin de l'âge, pas seulement du contenu.
class CachedPayload {
  final Map<String, dynamic> data;
  final DateTime             savedAt;

  const CachedPayload(this.data, this.savedAt);

  Duration get age => DateTime.now().difference(savedAt);
}

/// Cache SQLite local pour les données de référence du catalogue.
///
/// Ces tables (marques, modèles, catégories, pays…) décrivent « ce qui
/// existe » : elles bougent rarement mais pèsent lourd — la seule réponse de
/// `/catalog/sync` fait environ 79 Ko. Les garder en local évite de les
/// retélécharger à chaque ouverture de l'application, ce qui compte sur une
/// connexion mobile facturée au volume.
///
/// Deux stratégies coexistent :
/// - les listes simples ([loadRawCountries], [loadRawPartCategories]) ont un
///   TTL de 24 h : passé ce délai, l'appel réseau est refait en entier ;
/// - les références ([loadRefs]) sont rafraîchies par delta — voir
///   `VehicleAdminRepository.loadRefs`, qui exploite l'âge renvoyé ici.
///
/// Dans tous les cas, [clear] force un rechargement complet au prochain accès.
class CatalogLocalCache {
  static const _kRefs           = 'refs';
  static const _kCountries      = 'countries';
  static const _kPartCategories = 'part_categories';
  static const _ttlMs           = 24 * 60 * 60 * 1000; // 24 h

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

  /// Retourne les refs stockées **quel que soit leur âge**, avec leur date
  /// d'écriture.
  ///
  /// Pas de TTL ici : l'appelant décide entre rafraîchissement par delta,
  /// rechargement complet et repli hors ligne.
  Future<CachedPayload?> loadRefs() async {
    final row = await _row(_kRefs);
    if (row == null) return null;
    return CachedPayload(
      jsonDecode(row['data'] as String) as Map<String, dynamic>,
      DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  /// Persiste la réponse de /catalog/sync (complète ou fusionnée).
  Future<void> saveRefs(Map<String, dynamic> json) => _save(_kRefs, json);

  // ── Pays (/catalog/countries) ─────────────────────────────────────────────

  /// Retourne la liste brute des pays si le cache est frais, null sinon.
  Future<List<dynamic>?> loadRawCountries() => _loadFreshList(_kCountries);

  /// Persiste la liste brute des pays.
  Future<void> saveCountries(List<dynamic> list) =>
      _save(_kCountries, {'list': list});

  // ── Catégories de pièces (/catalog/part-categories) ───────────────────────

  /// Retourne l'arbre des catégories si le cache est frais, null sinon.
  ///
  /// Cette liste est demandée à chaque ouverture de la page « Pièces » pour
  /// construire la barre de filtres : sans cache, ce sont 4,5 Ko rappelés à
  /// chaque visite pour un arbre qui ne change pratiquement jamais.
  Future<List<dynamic>?> loadRawPartCategories() =>
      _loadFreshList(_kPartCategories);

  /// Persiste l'arbre brut des catégories de pièces.
  Future<void> savePartCategories(List<dynamic> list) =>
      _save(_kPartCategories, {'list': list});

  // ── Invalidation ──────────────────────────────────────────────────────────

  /// Vide toutes les entrées → forcer un rechargement depuis l'API au prochain accès.
  Future<void> clear() async {
    final db = await _open();
    await db.delete('entries');
  }

  // ── Helpers privés ────────────────────────────────────────────────────────

  Future<Map<String, Object?>?> _row(String key) async {
    final db  = await _open();
    final row = await db.query(
      'entries',
      columns:   ['data', 'updated_at'],
      where:     'key = ?',
      whereArgs: [key],
    );
    return row.isEmpty ? null : row.first;
  }

  /// Liste stockée sous la clé [key], ou null si absente ou périmée.
  Future<List<dynamic>?> _loadFreshList(String key) async {
    final row = await _row(key);
    if (row == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - (row['updated_at'] as int);
    if (age >= _ttlMs) return null;

    final map = jsonDecode(row['data'] as String) as Map<String, dynamic>;
    return map['list'] as List<dynamic>?;
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
