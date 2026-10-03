import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/garage/data/models/owned_vehicle.dart';

/// Un véhicule dont le modèle n'est pas au catalogue.
///
/// Le référentiel est bâti sur les flux d'occasion européens ; le parc vient
/// aussi des États-Unis, du Golfe et du Japon. Il manquera toujours des
/// modèles — un CX-9, jamais vendu en Europe, rendait l'enregistrement
/// impossible : le champ était obligatoire, la validation aussi, et la colonne
/// NOT NULL. Qui ne trouvait pas le sien ne pouvait ni enregistrer, ni
/// signaler le manque.
///
/// Le modèle devenant facultatif, deux choses doivent tenir côté application.
///
/// D'abord ne pas planter : `json['vehicle_model_id'] as int` levait une
/// exception sur un identifiant nul, et cette exception emportait la liste
/// entière du garage — un seul véhicule au modèle libre rendait l'écran
/// inutilisable, pas seulement sa ligne.
///
/// Ensuite ne pas mentir : les compatibilités sont déclarées par modèle. Sans
/// lui, la recherche de pièces rend zéro résultat, et ce zéro veut dire « on
/// ne sait pas », jamais « aucune pièce ne convient ».
void main() {
  OwnedVehicle depuisJson({
    int? modelId,
    String? modelLibre,
    String? engineCode,
    String? engineType,
    bool pret = false,
  }) =>
      OwnedVehicle.fromJson({
        'id': 1,
        'designation': 'Mazda CX-9 2015',
        'brand_id': 1,
        'vehicle_model_id': modelId,
        'model_libre': modelLibre,
        'engine_code': engineCode,
        'year': 2015,
        'identity': {
          'brand': 'Mazda',
          'brand_slug': 'mazda',
          'model': modelLibre,
          'engine_type': engineType,
        },
        'compatibility_ready': pret,
      });

  // ── Ne pas planter ───────────────────────────────────────────────────────

  test('un véhicule sans identifiant de modèle se lit sans exception', () {
    final v = depuisJson(modelLibre: 'CX-9');

    expect(v.vehicleModelId, isNull);
    expect(v.modelLibre, 'CX-9');
  });

  test('la clé model_libre peut être absente de la réponse', () {
    // Une version antérieure du serveur ne l'émet pas : la fiche doit s'ouvrir
    // quand même, sans modèle libre, plutôt que lever sur une clé manquante.
    final v = OwnedVehicle.fromJson({
      'id': 1,
      'designation': 'Toyota Corolla 2017',
      'brand_id': 1,
      'vehicle_model_id': 2,
      'year': 2017,
      'identity': <String, dynamic>{},
      'compatibility_ready': true,
    });

    expect(v.modelLibre, isNull);
    expect(v.modeleHorsCatalogue, isFalse);
  });

  // ── Ne pas mentir ────────────────────────────────────────────────────────

  test('le modèle tapé à la main se reconnaît', () {
    expect(depuisJson(modelLibre: 'CX-9').modeleHorsCatalogue, isTrue);
    expect(depuisJson(modelId: 7).modeleHorsCatalogue, isFalse);
  });

  /// C'est le cœur de la correction.
  ///
  /// `hasEngineData` ne regardait que le moteur. Un véhicule au modèle libre
  /// mais au code moteur renseigné — ce que le décodage VIN fournit tout seul
  /// — passait donc pour exploitable. L'écran annonçait alors une recherche de
  /// pièces qui ne rendrait jamais rien, et la fiche d'une pièce affichait
  /// « Non compatible » sur un véhicule dont on ignore tout.
  test('un code moteur ne rend pas un modèle absent exploitable', () {
    final v = depuisJson(modelLibre: 'CX-9', engineCode: 'PY-VPS');

    expect(v.engineCode, 'PY-VPS');
    expect(
      v.hasEngineData,
      isFalse,
      reason: 'Sans modèle, aucune compatibilité ne peut correspondre.',
    );
  });

  test('un libellé de motorisation non plus', () {
    expect(depuisJson(modelLibre: 'CX-9', engineType: 'Essence').hasEngineData,
        isFalse);
  });

  test('avec un modèle du catalogue, le moteur compte à nouveau', () {
    expect(depuisJson(modelId: 7, engineCode: 'PY-VPS').hasEngineData, isTrue);
    expect(depuisJson(modelId: 7, engineType: 'Essence').hasEngineData, isTrue);
    expect(depuisJson(modelId: 7).hasEngineData, isFalse);
  });

  test('le nom affiché ne perd pas le modèle tapé à la main', () {
    // Le serveur compose la désignation et y reprend la saisie libre : sans
    // cela la fiche afficherait « Mazda 2015 », un libellé plausible dont rien
    // ne dirait qu'il a perdu son modèle.
    final v = depuisJson(modelLibre: 'CX-9');

    expect(v.displayName, 'Mazda CX-9 2015');
    expect(v.identity.model, 'CX-9');
  });
}
