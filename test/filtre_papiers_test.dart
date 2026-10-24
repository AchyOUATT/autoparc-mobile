import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Client qui retient les paramètres de chaque appel.
class _ClientEspion extends ApiClient {
  final calls = <Map<String, dynamic>?>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    calls.add(params);
    // L'enveloppe que `PaginatedResponse.fromJson` exige : `meta` ET `links`,
    // tous deux lus en cast non nullable.
    return const {
      'data': [],
      'meta': {'current_page': 1, 'last_page': 1, 'total': 0, 'per_page': 20},
      'links': {'next': null},
    };
  }
}

/// Les deux critères que l'acheteur d'ici oppose d'abord.
///
/// ── CE QUI MANQUAIT ────────────────────────────────────────────────────────
///
/// L'API filtre sur `registration_status` depuis le début — la route
/// `/catalog/vehicles` le lit sur `filled()` — et l'application ne le demandait
/// JAMAIS. Son filtre portait `customsCleared` et rien d'autre côté papiers,
/// si bien qu'on pouvait chercher « dédouané » mais pas « immatriculé ».
///
/// Or c'est la première question posée sur un parc : un véhicule immatriculé
/// se conduit le jour même, un importé demande des démarches — et le
/// dédouanement n'en est que la première.
///
/// ── POURQUOI CE N'EST PAS UN BOOLÉEN ───────────────────────────────────────
///
/// `customsCleared` est un booléen parce que l'API n'applique ce filtre que
/// lorsqu'il est vrai : « non dédouané » n'existe pas comme recherche.
/// `registrationStatus` a DEUX valeurs utiles, parce que l'API le lit sur
/// `filled()` : 'unregistered' est une recherche à part entière, pas l'absence
/// de 'registered'. Le premier test de ce fichier tient cette différence.

void main() {
  group('Le filtre porte les deux valeurs', () {
    test('un filtre neuf ne demande rien', () {
      const neuf = VehicleFilter();

      expect(neuf.registrationStatus, isNull);
    });

    test('les deux valeurs sont distinctes, et pas un booléen déguisé', () {
      const neuf = VehicleFilter();

      expect(neuf.copyWith(registrationStatus: 'registered').registrationStatus,
          'registered');
      expect(neuf.copyWith(registrationStatus: 'unregistered').registrationStatus,
          'unregistered');
    });

    test('le drapeau d’effacement remet à zéro', () {
      const pose = VehicleFilter(registrationStatus: 'registered');

      expect(
        pose.copyWith(clearRegistrationStatus: true).registrationStatus,
        isNull,
        reason: 'Sans ce drapeau, une puce décochée resterait active : '
            'copyWith ne peut pas distinguer « null » de « non fourni ».',
      );
    });

    test('effacer un critère ne touche pas les autres', () {
      const pose = VehicleFilter(
        registrationStatus: 'registered',
        customsCleared: true,
        city: 'Ouagadougou',
      );

      final apres = pose.copyWith(clearRegistrationStatus: true);

      expect(apres.registrationStatus, isNull);
      expect(apres.customsCleared, isTrue);
      expect(apres.city, 'Ouagadougou');
    });

    test('le dédouanement reste combinable, même sans puce à l’écran', () {
      // LA PUCE « DÉDOUANÉ » N'EST PLUS AFFICHÉE — retirée sur décision du
      // propriétaire, parce que « Immatriculé + Dédouané » rendait MOINS de
      // résultats que « Immatriculé » seul : un véhicule immatriculé
      // localement n'a aucun dossier d'import, donc rien à dédouaner.
      //
      // Ce test garde la chaîne en vie pour le jour où elle revient. Sans
      // lui, `customsCleared` deviendrait un champ que plus rien n'exerce,
      // et il pourrirait en silence jusqu'à ce qu'on veuille le reposer.
      const filtre = VehicleFilter(
        registrationStatus: 'unregistered',
        customsCleared: true,
      );

      expect(filtre.registrationStatus, 'unregistered');
      expect(filtre.customsCleared, isTrue);
    });
  });

  // ── Le critère atteint-il la requête ? ──────────────────────────────────
  //
  // C'est ici que porte le vrai risque. Un champ ajouté au filtre mais que le
  // dépôt oublie de transmettre compile, passe les tests de modèle ci-dessus,
  // et ne filtre rien : l'écran coche la puce et la liste ne bouge pas.

  group('Le critère part sur le réseau', () {
    late _ClientEspion espion;
    late CatalogRepository depot;

    setUp(() {
      espion = _ClientEspion();
      depot = CatalogRepository(espion, CatalogLocalCache());
    });

    test('registration_status accompagne la requête', () async {
      await depot.getVehicles(registrationStatus: 'registered');

      expect(espion.calls.single!['registration_status'], 'registered');
    });

    test('« non immatriculé » part aussi, et ce n’est pas l’absence de l’autre', () async {
      await depot.getVehicles(registrationStatus: 'unregistered');

      expect(espion.calls.single!['registration_status'], 'unregistered');
    });

    test('sans critère, le paramètre est absent et non vide', () async {
      // Une chaîne vide serait `filled()` côté API sur certaines versions de
      // Laravel : l'absence est la seule forme qui ne filtre rien à coup sûr.
      await depot.getVehicles();

      expect(espion.calls.single!.containsKey('registration_status'), isFalse);
    });

    test('les deux critères de papiers partent ensemble', () async {
      await depot.getVehicles(
        registrationStatus: 'unregistered',
        customsCleared: true,
      );

      final params = espion.calls.single!;
      expect(params['registration_status'], 'unregistered');
      expect(params['customs_cleared'], '1');
    });
  });
}
