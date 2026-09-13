import 'dart:convert';
import 'dart:io';

import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
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
///   (backend) php artisan test --filter=ApiContractFixturesTest
///   cp ../autoparc-backend/tests/Fixtures/api/*.json test/fixtures/
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
      expect(categories.any((c) => c.isRoot), isTrue,
          reason: 'La barre de filtres ne propose que les racines.');
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
  });
}
