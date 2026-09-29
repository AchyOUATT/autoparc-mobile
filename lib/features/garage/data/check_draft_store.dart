import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final checkDraftStoreProvider = Provider<CheckDraftStore>(
  (ref) => const CheckDraftStore(),
);

/// Le brouillon d'un contrôle, et l'envoi qui n'est pas passé.
///
/// Un contrôle avant voyage ne se remplit pas assis au bureau : il se remplit
/// dans une cour, capot ouvert, téléphone dans une main, souvent sans réseau.
/// Deux choses doivent donc survivre à l'application elle-même.
///
/// Le brouillon : on coche quatre points, on va chercher le cric, on revient
/// dix minutes plus tard. Si l'application a été déchargée entre-temps, perdre
/// les quatre réponses suffit à ce qu'il n'y ait pas de deuxième contrôle.
///
/// L'envoi en attente : le contrôle est fini, le verdict compte, et le réseau
/// n'est pas là. L'envoi est gardé et rejoué à la prochaine ouverture. Il porte
/// une clé que le serveur reconnaît, de sorte qu'un rejeu ne crée jamais un
/// second passage — c'est cette clé qui rend l'attente sans danger.
///
/// Ce n'est pas une file d'attente générale : un seul brouillon et un seul envoi
/// par véhicule. Un propriétaire ne contrôle pas deux fois la même voiture dans
/// la même journée, et une vraie file demanderait une détection de connectivité
/// que le projet n'a pas.
class CheckDraftStore {
  const CheckDraftStore();

  static const String _prefixeBrouillon = 'check_draft_';
  static const String _prefixeEnAttente = 'check_pending_';

  /// Au-delà, un brouillon ne décrit plus l'état du véhicule : le kilométrage a
  /// bougé, l'assurance a peut-être été renouvelée, et le reprendre ferait
  /// enregistrer un constat périmé comme s'il était d'aujourd'hui.
  static const Duration validite = Duration(days: 2);

  /// Au-delà, le serveur refuse le contrôle : sa validation n'accepte pas un
  /// `performed_at` de plus de trente jours. Sans cette péremption, un envoi
  /// bloqué repartait à chaque ouverture de l'écran pour se faire refuser
  /// chaque fois — et la bannière continuait de promettre qu'il passerait.
  /// Vingt-cinq jours laissent la marge d'un décalage d'horloge.
  static const Duration peremptionEnvoi = Duration(days: 25);

  // ── Brouillon ───────────────────────────────────────────────────

  Future<void> enregistrerBrouillon(int vehiculeId, CheckDraft brouillon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefixeBrouillon$vehiculeId', jsonEncode(brouillon.toJson()));
  }

  Future<CheckDraft?> lireBrouillon(int vehiculeId) async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString('$_prefixeBrouillon$vehiculeId');
    if (brut == null) return null;

    final brouillon = _decoder(brut, CheckDraft.fromJson);

    if (brouillon == null || brouillon.estPerime) {
      await effacerBrouillon(vehiculeId);
      return null;
    }

    return brouillon;
  }

  Future<void> effacerBrouillon(int vehiculeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefixeBrouillon$vehiculeId');
  }

  // ── Envoi en attente ────────────────────────────────────────────

  Future<void> mettreEnAttente(int vehiculeId, Map<String, dynamic> charge) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefixeEnAttente$vehiculeId', jsonEncode(charge));
  }

  Future<Map<String, dynamic>?> lireEnAttente(int vehiculeId) async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString('$_prefixeEnAttente$vehiculeId');
    if (brut == null) return null;

    final charge = _decoder(brut, (json) => json);

    if (charge == null || _troptard(charge['performed_at'])) {
      await effacerEnAttente(vehiculeId);
      return null;
    }

    return charge;
  }

  /// La date du contrôle est-elle hors de ce que le serveur accepte encore ?
  ///
  /// Elle est lue dans la charge elle-même, et non stockée à part, parce que
  /// c'est exactement le champ sur lequel le serveur tranche : lier la
  /// péremption à autre chose laisserait les deux règles diverger.
  bool _troptard(Object? performedAt) {
    final date = DateTime.tryParse(performedAt?.toString() ?? '');
    if (date == null) return false;

    return DateTime.now().toUtc().difference(date.toUtc()) > peremptionEnvoi;
  }

  Future<void> effacerEnAttente(int vehiculeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefixeEnAttente$vehiculeId');
  }

  /// Une valeur illisible est jetée, jamais propagée.
  ///
  /// Le format peut changer d'une version de l'application à l'autre, et un
  /// brouillon d'une version précédente ferait planter l'écran à l'ouverture —
  /// précisément l'écran censé être le plus robuste de l'application.
  T? _decoder<T>(String brut, T Function(Map<String, dynamic>) depuis) {
    try {
      final json = jsonDecode(brut);
      if (json is! Map<String, dynamic>) return null;
      return depuis(json);
    } catch (_) {
      return null;
    }
  }
}

/// Les réponses déjà données, et le contexte qui les rend interprétables.
class CheckDraft {
  final int? tripDistanceKm;
  final int? mileageKm;

  /// code du point → `ok`, `watch` ou `bad`.
  final Map<String, String> answers;

  /// La clé d'idempotence du contrôle en cours.
  ///
  /// Persistée avec le brouillon, et pas seulement gardée en mémoire : sans
  /// cela, une relance de l'application en fabriquait une neuve, et un contrôle
  /// dont le premier envoi avait atteint le serveur sans que la réponse revienne
  /// s'enregistrait une seconde fois. C'est la garantie même du mécanisme.
  final String? clientReference;

  /// Le nombre de points que la liste comptait, pour que le verdict puisse dire
  /// combien n'ont pas été vérifiés même quand il est atteint par un renvoi,
  /// sans que la liste ait été recomposée.
  final int? itemsCount;

  /// Le motif du contrôle en cours : `trip` ou `seasonal`. Sans lui, un
  /// brouillon d'hivernage repris le lendemain repartirait comme un contrôle
  /// avant voyage, avec un verdict qui parlerait de partir.
  final String? reason;

  final DateTime savedAt;

  const CheckDraft({
    this.tripDistanceKm,
    this.mileageKm,
    required this.answers,
    this.clientReference,
    this.itemsCount,
    this.reason,
    required this.savedAt,
  });

  bool get estVide => answers.isEmpty;

  bool get estPerime =>
      DateTime.now().difference(savedAt) > CheckDraftStore.validite;

  Map<String, dynamic> toJson() => {
    'trip_distance_km': tripDistanceKm,
    'mileage_km': mileageKm,
    'answers': answers,
    'client_reference': clientReference,
    'items_count': itemsCount,
    'reason': reason,
    'saved_at': savedAt.toIso8601String(),
  };

  factory CheckDraft.fromJson(Map<String, dynamic> json) => CheckDraft(
    tripDistanceKm:  json['trip_distance_km'] as int?,
    mileageKm:       json['mileage_km']       as int?,
    clientReference: json['client_reference'] as String?,
    itemsCount:      json['items_count']      as int?,
    reason:          json['reason']           as String?,
    answers: (json['answers'] as Map?)?.map(
          (cle, valeur) => MapEntry(cle.toString(), valeur.toString()),
        ) ??
        const {},
    savedAt: DateTime.tryParse(json['saved_at']?.toString() ?? '') ?? DateTime.now(),
  );
}
