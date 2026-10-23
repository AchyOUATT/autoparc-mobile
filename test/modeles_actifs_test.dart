import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un modèle désactivé ne doit plus être proposé — et doit rester lisible.
///
/// ── CE QUE CE BANC GARDE, ET POURQUOI IL N'EXISTAIT PAS ────────────────────
///
/// `/catalog/sync` envoie `is_active` pour chaque modèle depuis toujours, et
/// `ModelRef.fromJson` le JETAIT. Dans le même fichier, `BrandRef` le gardait
/// et les menus de marques le filtraient déjà : l'asymétrie était là depuis le
/// début, sans conséquence tant qu'aucun modèle n'était désactivé.
///
/// Le 23/10/2026, le référentiel a remplacé les lignes nues `tacoma` et
/// `venza` par leurs générations en désactivant les deux lignes nues. Le menu
/// s'est mis à proposer « Tacoma » À CÔTÉ de Tacoma I, II, III et IV : six
/// entrées pour deux véhicules, dont deux qui ne mènent à aucune finition ni
/// aucune cote de consommation.
///
/// Le serveur a été corrigé le même jour — sa route `/catalog/brands/{id}/models`
/// filtre désormais — MAIS L'APPLICATION NE S'EN SERT PAS : ses listes
/// viennent du cache de synchronisation. Corriger le serveur seul ne corrigeait
/// donc rien à l'écran, et rien ne le signalait.
///
/// ── L'ASYMÉTRIE QU'IL NE FAUT PAS « HARMONISER » ───────────────────────────
///
/// `vehicleModels` reste entier. Un véhicule déjà enregistré sur une
/// génération depuis désactivée doit continuer de s'afficher avec son nom :
/// on filtre ce qu'on PROPOSE, pas ce qu'on LIT. Le dernier test de ce fichier
/// tombera si quelqu'un filtre la liste brute par symétrie.

ModelRef _tacoma(int id, String? generation, {bool actif = true}) => ModelRef(
      id: id,
      brandId: 1,
      name: 'Tacoma',
      generation: generation,
      isActive: actif,
    );

final _nue = _tacoma(1, null, actif: false);
final _generations = [
  _tacoma(2, 'I'),
  _tacoma(3, 'II'),
  _tacoma(4, 'III'),
  _tacoma(5, 'IV'),
];

CatalogRefs _refs(List<ModelRef> modeles) => CatalogRefs(
      brands: const [],
      vehicleModels: modeles,
      trims: const [],
      engineTypes: const [],
      drivetrains: const [],
      colors: const [],
      features: const [],
      locations: const [],
    );

void main() {
  group('Le drapeau arrive', () {
    test('is_active est lu depuis la charge utile', () {
      final actif = ModelRef.fromJson(const {
        'id': 1,
        'brand_id': 1,
        'name': 'Tacoma',
        'is_active': true,
      });
      final eteint = ModelRef.fromJson(const {
        'id': 2,
        'brand_id': 1,
        'name': 'Tacoma',
        'is_active': false,
      });

      expect(actif.isActive, isTrue);
      expect(
        eteint.isActive,
        isFalse,
        reason: 'Le drapeau est jeté au parsing : le menu ne peut pas trancher.',
      );
    });

    test('absent de la charge utile, le modèle est supposé actif', () {
      // Un serveur plus ancien n'envoie pas la colonne. La supposer fausse
      // viderait tout le catalogue d'un coup, ce qui est bien pire que le
      // doublon qu'on cherche à retirer.
      final sansDrapeau = ModelRef.fromJson(const {
        'id': 1,
        'brand_id': 1,
        'name': 'Tacoma',
      });

      expect(sansDrapeau.isActive, isTrue);
    });
  });

  group('Ce qu’on propose', () {
    test('le menu d’une marque écarte les modèles désactivés', () {
      final refs = _refs([_nue, ..._generations]);

      final proposes = refs.modelsForBrand(1);

      expect(proposes.length, 4, reason: 'Cinq entrées pour un seul véhicule.');
      expect(proposes.map((m) => m.generation), ['I', 'II', 'III', 'IV']);
      expect(proposes.any((m) => m.id == _nue.id), isFalse);
    });

    test('une génération désactivée n’est pas proposée en rattrapage d’année', () {
      // `generationsPour` sert quand l'année saisie ne tombe pas dans la
      // génération choisie : il propose celles qui la couvrent. Proposer une
      // ligne retirée serait corriger une erreur par une entrée morte.
      // LES DEUX CANDIDATES COUVRENT L'ANNÉE. Sans cette précaution, l'année
      // ferait seule le tri et ce test passerait même sans le filtre — la
      // première version de ce banc avait ce défaut, et la mutation l'a montré.
      final eteinte = ModelRef(
        id: 10, brandId: 1, name: 'Tacoma', generation: 'III',
        productionStart: 2023, isActive: false,
      );
      const vivante = ModelRef(
        id: 11, brandId: 1, name: 'Tacoma', generation: 'IV',
        productionStart: 2023,
      );
      const choisie = ModelRef(
        id: 12, brandId: 1, name: 'Tacoma', generation: 'II',
        productionStart: 2004, productionEnd: 2015,
      );

      final refs = _refs([eteinte, vivante, choisie]);

      // Les deux couvrent 2024 : seul le drapeau peut les départager.
      expect(eteinte.couvreAnnee(2024), isTrue);
      expect(vivante.couvreAnnee(2024), isTrue);

      final candidates = refs.generationsPour(choisie, 2024);

      expect(
        candidates.map((m) => m.id),
        [vivante.id],
        reason: 'Une génération retirée est proposée en remplacement : on '
            'corrige une erreur de saisie par une entrée morte.',
      );
    });
  });

  group('Ce qu’on lit', () {
    test('la liste brute garde les modèles désactivés', () {
      // Un véhicule enregistré sur la ligne nue avant sa désactivation doit
      // continuer de s'afficher avec son nom. Filtrer ici par symétrie
      // transformerait un doublon visible en véhicule sans modèle.
      final refs = _refs([_nue, ..._generations]);

      final retrouve =
          refs.vehicleModels.where((m) => m.id == _nue.id).firstOrNull;

      expect(
        retrouve,
        isNotNull,
        reason: 'La liste brute a été filtrée : un véhicule déjà enregistré '
            'sur cette génération perd son modèle à l’affichage.',
      );
      expect(retrouve!.name, 'Tacoma');
    });
  });
}
