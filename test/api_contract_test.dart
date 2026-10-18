import 'dart:convert';
import 'dart:io';

import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/widgets/niveau_categories.dart';
import 'package:auto/features/garage/data/models/fuel_fill.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrat entre l'API et l'application.
///
/// Les fichiers de `test/fixtures/` sont de vraies réponses du serveur,
/// produites par `ApiContractFixturesTest` côté backend et recopiées ici. Ce
/// n'est pas un détail : Laravel sérialise les colonnes `decimal` en **chaînes
/// de caractères**, et c'est précisément ce qui avait tout cassé — les modèles
/// lisaient `num?`, le catalogue entier remontait
/// `type 'String' is not a subtype of type 'num?'`. Une charge utile écrite à
/// la main aurait porté des nombres et n'aurait rien révélé.
///
/// Rafraîchir après toute modification d'une ressource côté serveur :
///   (backend) UPDATE_FIXTURES=1 php artisan test --filter=ApiContractFixturesTest
///   cp ../autoparc-backend/tests/Fixtures/api/*.json test/fixtures/
///
/// **Une divergence assumée, et une seule : les `media` des deux fixtures de
/// véhicule.** `ApiContractFixturesTest` ne crée aucun média — le mot n'y
/// apparaît pas —, donc le serveur rend `"media": []`, et les douze fixtures
/// étaient dans ce cas. Or l'ordre des photos est un contrat : la couverture
/// en tête, `is_cover` honoré. Avec des listes vides, on pouvait remettre
/// `mediaUrls` sur un `map(url)` sans ordre et garder toute la suite au vert —
/// exactement la panne qu'on venait de réparer. `vehicles_list.json` et
/// `vehicle_detail.json` portent donc trois médias dont la couverture en
/// DEUXIÈME position, à la forme de `VehicleResource` (id, url, collection,
/// is_cover — pas de `position`).
///
/// La recopie ci-dessus les écrase. Ce n'est pas silencieux : le groupe « Les
/// médias des fixtures » de `photo_couverture_test.dart` vérifie d'abord la
/// fixture elle-même et tombe en nommant ce paragraphe. Les remettre à la main
/// — ou les faire créer côté serveur — est alors le travail à faire.
void main() {
  Map<String, dynamic> objet(String nom) =>
      jsonDecode(File('test/fixtures/$nom.json').readAsStringSync())
          as Map<String, dynamic>;

  List<dynamic> liste(String nom) =>
      jsonDecode(File('test/fixtures/$nom.json').readAsStringSync())
          as List<dynamic>;

  group('Catalogue', () {
    test('la liste des véhicules se lit entièrement', () {
      final page = PaginatedResponse.fromJson(objet('vehicles_list'), Vehicle.fromJson);

      expect(page.data, isNotEmpty);
      expect(page.total, greaterThan(0));

      for (final v in page.data) {
        expect(v.reference, isNotEmpty);
        expect(v.identity.brand, isNotEmpty);
      }
    });

    /// Le champ qui avait fait tomber le catalogue : « 2450000.00 », en chaîne.
    test('un prix sérialisé en chaîne est converti en nombre', () {
      final brut = objet('vehicles_list');
      final prixBrut = (brut['data'] as List)
          .map((e) => (e['commercial'] as Map)['sale_price'])
          .firstWhere((p) => p != null);

      expect(prixBrut, isA<String>(),
          reason: 'La fixture doit conserver la forme réelle du serveur.');

      final page = PaginatedResponse.fromJson(brut, Vehicle.fromJson);
      final prix = page.data
          .map((v) => v.commercial.salePrice)
          .firstWhere((p) => p != null);

      expect(prix, isA<num>());
      expect(prix, greaterThan(0));
    });

    test('la fiche véhicule se lit, équipements et mention comprises', () {
      final fiche = Vehicle.fromJson(objet('vehicle_detail')['data'] as Map<String, dynamic>);

      expect(fiche.reference, isNotEmpty);
      expect(fiche.features, isNotEmpty);
      expect(fiche.optionalFeatureCount, isNotNull);
      expect(fiche.isFullOption, isA<bool>());
    });

    test('une consommation décimale en chaîne est convertie', () {
      final brut = objet('vehicle_detail')['data'] as Map<String, dynamic>;
      final conso = (brut['consumption'] as Map)['combined_l_100km'];

      expect(conso, isA<String>());
      expect(Vehicle.fromJson(brut).combinedL100km, isA<double>());
    });

    test('la liste des pièces se lit', () {
      final page = PaginatedResponse.fromJson(objet('parts_list'), Part.fromJson);

      expect(page.data, isNotEmpty);
      for (final p in page.data) {
        expect(p.name, isNotEmpty);
      }
    });

    test('la fiche pièce se lit', () {
      final piece = Part.fromJson(objet('part_detail')['data'] as Map<String, dynamic>);

      expect(piece.name, isNotEmpty);
      expect(piece.pricing.sellingPrice, greaterThan(0));
    });

    test('la liste des accessoires se lit', () {
      final page = PaginatedResponse.fromJson(objet('accessories_list'), Accessory.fromJson);

      expect(page.data, isNotEmpty);
    });
  });

  group('Référentiels', () {
    test('l\'arbre des catégories porte le parent', () {
      final categories = liste('part_categories')
          .map((e) => PartCategory.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.isRoot), isTrue);
    });

    /// L'arbre élagué alimente les pastilles de filtre, l'arbre complet les
    /// menus de saisie. Deux réponses de même forme, aux lignes différentes :
    /// c'est cette différence que l'application exploite, et `has_own_parts`
    /// est ce qui lui permet de choisir le niveau des pastilles.
    test('l\'arbre élagué porte le drapeau du niveau', () {
      final elaguees = liste('part_categories_non_empty')
          .map((e) => PartCategory.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(elaguees, isNotEmpty);
      expect(elaguees.any((c) => c.hasOwnParts), isTrue,
          reason: 'Une catégorie élaguée au moins porte des pièces.');
      expect(niveauDiscriminant(elaguees), isA<List<PartCategory>>());
    });

    test('les catégories d\'accessoires occupées se lisent', () {
      final valeurs = liste('accessory_categories').cast<String>().toSet();

      expect(valeurs, isNotEmpty);
      // L'application garde ses libellés et ses icônes : le serveur ne doit
      // rendre que des valeurs d'énumération, qu'elle recoupe avec sa liste.
      expect(valeurs.every((v) => v == v.toLowerCase()), isTrue);
    });

    test('les pays se lisent', () {
      final pays = liste('countries')
          .map((e) => CountryRef.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(pays, isNotEmpty);
      expect(pays.first.name, isNotEmpty);
    });

    test('la synchronisation porte le curseur et les tables attendues', () {
      final refs = objet('catalog_sync');

      expect(refs['server_time'], isA<String>(),
          reason: 'Curseur du mode incrémental : sans lui, l\'app retélécharge tout.');

      for (final table in ['brands', 'vehicle_models', 'colors', 'features', 'locations']) {
        expect(refs[table], isA<List>(), reason: 'Table « $table » absente.');
      }
    });

    test('les tables de référence se lisent une à une', () {
      final refs = objet('catalog_sync');

      expect(
        (refs['brands'] as List).map((e) => BrandRef.fromJson(e as Map<String, dynamic>)).toList(),
        isNotEmpty,
      );
      for (final e in refs['colors'] as List) {
        ColorRef.fromJson(e as Map<String, dynamic>);
      }
      for (final e in refs['features'] as List) {
        FeatureRef.fromJson(e as Map<String, dynamic>);
      }
      for (final e in refs['locations'] as List) {
        LocationRef.fromJson(e as Map<String, dynamic>);
      }
    });
  });

  group('Mon garage', () {
    test('le véhicule du garage se lit, échéances comprises', () {
      final data = objet('my_vehicles')['data'] as List;
      final vehicules = data
          .map((e) => OwnedVehicle.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(vehicules, isNotEmpty);

      final v = vehicules.first;
      expect(v.identity.brand, isNotEmpty);
      expect(v.deadlines, isNotEmpty,
          reason: 'Les échéances alimentent les rappels d\'entretien.');
    });

    /// La clé doit être là même quand elle n'a rien à dire : c'est ainsi que
    /// l'application sépare « aucun passage » — compteurs à zéro — de « pas
    /// demandé », où la tuile s'en tient à la cote constructeur et ne propose
    /// aucune saisie. Si le serveur ne la rendait qu'à l'index, ou qu'après un
    /// premier passage, l'écran serait juste à un endroit et faux ailleurs
    /// sans qu'aucune erreur ne le signale.
    test('le suivi carburant est présent et se lit entièrement', () {
      final brut = (objet('my_vehicles')['data'] as List).first
          as Map<String, dynamic>;

      expect(brut.containsKey('fuel_tracking'), isTrue,
          reason: 'OwnedVehicleResource doit toujours porter « fuel_tracking ».');

      final suivi = OwnedVehicle.fromJson(brut).fuelTracking;

      expect(suivi, isNotNull);
      expect(suivi!.totalFills, greaterThan(0),
          reason: 'La fixture doit porter des passages, sinon elle ne mesure '
              'que le cas vide.');
      expect(suivi.fullFills, greaterThan(0));
      expect(suivi.l100km, isNotNull);
      expect(suivi.basedOnFills, greaterThan(0));
      // Les faits bruts sont rendus même quand aucun intervalle n'est retenu :
      // c'est l'écran du propriétaire qui ne fait jamais le plein.
      expect(suivi.totals.litres, greaterThan(0));
      expect(suivi.totals.distanceKm, greaterThan(0));

      // Les deux clés que la tuile lit en plus du chiffre : celle du verdict
      // et celle du compteur remplacé. Toujours présentes, même nulle et
      // fausse — leur absence et leur valeur de repos se confondraient, et
      // l'écran se tairait sur un serveur qui a quelque chose à dire.
      final tracking = brut['fuel_tracking'] as Map<String, dynamic>;
      expect(tracking.containsKey('alerte_l_100km'), isTrue);
      expect(tracking.containsKey('series_rompue'), isTrue);
    });

    /// Les quatre champs de mesure ne décrivent pas le passage mais
    /// l'intervalle qui finit sur lui. Un demi-plein n'en porte aucun : il
    /// apporte ses litres au calcul sans jamais borner un intervalle. La
    /// fixture doit contenir les deux natures, sinon elle ne prouve rien de
    /// cette distinction.
    test('les passages à la pompe se lisent, pleins et demi-pleins', () {
      final page =
          PaginatedResponse.fromJson(objet('my_fuel_fills'), FuelFill.fromJson);

      expect(page.data, isNotEmpty);
      expect(page.data.any((p) => p.isFull), isTrue);
      expect(page.data.any((p) => !p.isFull), isTrue,
          reason: 'Sans demi-plein, la fixture ne couvre que la moitié du cas.');

      for (final p in page.data) {
        expect(p.mileageKm, greaterThan(0));
        expect(p.litres, greaterThan(0));
        if (!p.isFull) {
          expect(p.l100km, isNull,
              reason: 'Un demi-plein ne ferme jamais d\'intervalle.');
        }
      }

      final mesure = page.data.firstWhere((p) => p.l100km != null);
      expect(mesure.isFull, isTrue);
      expect(mesure.distanceKm, isNotNull);
    });

    /// Ce que la suppression d'une ligne détruirait, et la seule donnée dont
    /// la confirmation ait besoin. Elle ne se déduit PAS de la ligne : un
    /// passage peut ne fermer aucun intervalle retenu — `retenu` faux, pas de
    /// `l_100km` — et pourtant en OUVRIR un, qui disparaîtrait avec lui. La
    /// fixture porte ce cas (94 800 km, premier plein de la série), et c'est
    /// lui qui interdit de remplacer la clé par un `retenu ? 1 : 0`.
    ///
    /// Sans ce nombre, la confirmation retombe sur son texte générique et
    /// laisse supprimer un passage correct qui divise le chiffre par deux :
    /// 90 000/40 L, 90 600/48 L, 91 200/50 L affichent 8,2 l/100 km, et 4,2
    /// une fois celui du milieu effacé.
    test('chaque passage dit combien d\'intervalles retenus il borne', () {
      final brut = (objet('my_fuel_fills')['data'] as List)
          .cast<Map<String, dynamic>>();

      for (final e in brut) {
        expect(e.containsKey('bornes_intervalles'), isTrue,
            reason: 'FuelFillResource doit toujours porter '
                '« bornes_intervalles », même à zéro.');
      }

      final lus = brut.map(FuelFill.fromJson).toList();

      expect(lus.any((p) => p.bornesIntervalles == 2), isTrue,
          reason: 'Sans un passage qui borne DEUX intervalles, la fixture ne '
              'couvre pas l\'avertissement de fusion.');
      expect(lus.any((p) => !p.retenu && p.bornesIntervalles > 0), isTrue,
          reason: 'C\'est le cas qui prouve que « retenu » ne peut pas tenir '
              'lieu de ce nombre.');
    });

    /// L'incident cité en tête de ce fichier, sur la table des pleins :
    /// `litres` et `price_per_litre` sont des colonnes `decimal`, donc des
    /// chaînes dans la réponse. Un `as num?` ici ferait tomber l'historique
    /// entier, pas la ligne fautive.
    test('litres et prix au litre arrivent en chaînes, et sont convertis', () {
      final brut = (objet('my_fuel_fills')['data'] as List)
          .cast<Map<String, dynamic>>();

      expect(brut.first['litres'], isA<String>(),
          reason: 'La fixture doit conserver la forme réelle du serveur.');
      expect(brut.map((e) => e['price_per_litre']).whereType<String>(),
          isNotEmpty);

      for (final e in brut) {
        final p = FuelFill.fromJson(e);
        expect(p.litres, isA<double>());
        expect(p.litres, greaterThan(0));
      }
    });
  });
}
