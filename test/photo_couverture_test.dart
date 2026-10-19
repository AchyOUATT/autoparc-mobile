import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/widgets/catalog_image.dart';
import 'package:auto/core/widgets/product_gallery.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/models/paginated_response.dart';

import 'support/langues.dart';

/// La photo de couverture arrive-t-elle bien en tête, sur les TROIS modèles ?
///
/// L'API envoie `is_cover` sur les trois ressources — VehicleResource,
/// PartResource, AccessoryResource — et les écrans qui lisent ces listes
/// supposent tous la couverture en tête : la carte de la grille et la tuile du
/// carrousel d'accueil lisent `coverUrl`, la galerie de la fiche affiche la
/// liste telle quelle.
///
/// Ce fichier posait six cas sur `Vehicle` et, pour `Part` et `Accessory`, le
/// seul chemin heureux, écrit deux fois. Le cas qui manquait était précisément
/// celui de l'URL VIDE, c'est-à-dire le seul où les trois modèles
/// divergeaient : `Vehicle` filtrait les adresses vides avant d'en dériver la
/// couverture, les deux autres lisaient `coverItem['url']` d'abord et
/// rendaient `coverUrl == ''` plus un premier élément vide. Le test annonçait
/// « le même contrat » sans pouvoir le tenir.
///
/// D'où un seul corps de test, déroulé sur les trois parseurs. Un modèle qui
/// repart à la dérive tombe désormais sur le cas exact qui le trahit, et non
/// sur rien.
///
/// Un mot sur `position`. PartResource et AccessoryResource le sérialisent, et
/// leurs parseurs trient dessus ; VehicleResource ne le fait pas — il rend id,
/// url, collection, is_cover. Les médias de ce fichier portent donc un
/// `position` qui SUIT l'ordre de la liste : les deux parseurs qui trient
/// retrouvent alors l'ordre du serveur, que le troisième conserve faute de
/// pouvoir trier, et les trois doivent rendre la même chose. Mesurer autre
/// chose ici reviendrait à comparer deux règles différentes et à conclure
/// qu'elles divergent.
void main() {
  Map<String, dynamic> vehiculeJson(Object? medias) => <String, dynamic>{
        'id': 7,
        'reference': 'VH-0007',
        'designation': 'Toyota Corolla 2013',
        'registration_status': 'registered',
        'identity': {'brand': 'Toyota', 'model': 'Corolla', 'year': 2013},
        'commercial': {
          'condition': 'used',
          'status': 'in_stock',
          'availability': 'sale',
          'sale_price': '3500000.00',
        },
        // `?medias` et non `if (medias != null)` : le marqueur null-aware est
        // ce que le projet exige (use_null_aware_elements), et il dit la même
        // chose — pas de média, pas de clé, exactement comme `whenLoaded`.
        'media': ?medias,
      };

  Map<String, dynamic> pieceJson(Object? medias) => <String, dynamic>{
        'id': 1,
        'name': 'Filtre à huile',
        'type': 'aftermarket',
        'condition': 'new',
        'pricing': {
          'selling_price': '3000.00',
          'currency': 'XOF',
          'vat_rate': '0.00',
          'price_including_vat': '3000.00',
        },
        'stock': {'quantity': 2, 'alert_threshold': 0, 'is_low': false},
        'media': ?medias,
      };

  Map<String, dynamic> accessoireJson(Object? medias) => <String, dynamic>{
        'id': 1,
        'name': 'Tapis de sol',
        'category': {'value': 'confort', 'label': 'Confort'},
        'pricing': {
          'selling_price': '12000.00',
          'currency': 'XOF',
          'vat_rate': '0.00',
          'price_including_vat': '12000.00',
        },
        'stock': {'quantity': 2, 'alert_threshold': 0, 'is_low': false},
        'is_active': true,
        'media': ?medias,
      };

  /// Un média, à la forme la plus riche des trois ressources.
  ///
  /// `position` suit l'indice d'appel : voir l'en-tête du fichier. Les listes
  /// qui les portent sont écrites `<dynamic>[…]` et non laissées à
  /// l'inférence, qui en ferait des `List<Map<String, dynamic>>`. Ce n'est pas
  /// une coquetterie : les trois parseurs appellent `firstWhere` avec un
  /// `orElse` dont le type de retour est `dynamic`, et le contrôle de type
  /// réifié rejette cet `orElse` sur une liste plus précisément typée —
  /// « type '() => dynamic' is not a subtype of type
  /// '(() => Map<String, dynamic>)?' ». `jsonDecode` rend toujours des
  /// `List<dynamic>` : une fixture plus précise mesurerait une forme que le
  /// serveur ne produit jamais, et ferait échouer les trois modèles.
  Map<String, dynamic> media(int position, String url, {bool? cover}) =>
      <String, dynamic>{
        'id': position,
        'url': url,
        'collection': 'gallery',
        'position': position,
        'is_cover': cover,
      };

  /// Ce que chaque modèle expose de ses photos, sous un seul nom.
  ///
  /// Les deux champs ne portent pas le même nom d'un modèle à l'autre —
  /// `mediaUrls` chez `Vehicle`, `photoUrls` chez les deux autres — et c'est
  /// bien la seule différence qui doive rester entre eux.
  ({String? couverture, List<String> photos}) lire(
    String modele,
    Object? medias,
  ) =>
      switch (modele) {
        'Vehicle' => (() {
            final v = Vehicle.fromJson(vehiculeJson(medias));
            return (couverture: v.coverUrl, photos: v.mediaUrls);
          })(),
        'Part' => (() {
            final p = Part.fromJson(pieceJson(medias));
            return (couverture: p.coverUrl, photos: p.photoUrls);
          })(),
        'Accessory' => (() {
            final a = Accessory.fromJson(accessoireJson(medias));
            return (couverture: a.coverUrl, photos: a.photoUrls);
          })(),
        _ => throw ArgumentError(modele),
      };

  const modeles = <String>['Vehicle', 'Part', 'Accessory'];

  /// Les six cas, et ce qu'ils doivent rendre — les mêmes pour les trois.
  final cas = <String, (Object?, String?, List<String>)>{
    'la couverture remonte en tête quand elle arrive en troisième position': (
      <dynamic>[
        media(1, 'https://ex.test/jante.jpg'),
        media(2, 'https://ex.test/moteur.jpg'),
        media(3, 'https://ex.test/voiture.jpg', cover: true),
      ],
      'https://ex.test/voiture.jpg',
      // Le reste suit dans l'ordre du serveur, et sans doublon : la couverture
      // est écartée du reste, pas recopiée devant.
      <String>[
        'https://ex.test/voiture.jpg',
        'https://ex.test/jante.jpg',
        'https://ex.test/moteur.jpg',
      ],
    ),
    'la couverture est la première photo quand aucun média ne porte le drapeau':
        (
      <dynamic>[
        media(1, 'https://ex.test/a.jpg'),
        media(2, 'https://ex.test/b.jpg'),
        media(3, 'https://ex.test/c.jpg'),
      ],
      'https://ex.test/a.jpg',
      <String>[
        'https://ex.test/a.jpg',
        'https://ex.test/b.jpg',
        'https://ex.test/c.jpg',
      ],
    ),
    // Cas anormal mais atteignable : la contrainte « une seule couverture »
    // vit en base, et une reprise de données peut la violer. Le parseur doit
    // alors choisir, pas lever.
    'la couverture est la première marquée quand plusieurs portent le drapeau':
        (
      <dynamic>[
        media(1, 'https://ex.test/a.jpg'),
        media(2, 'https://ex.test/b.jpg', cover: true),
        media(3, 'https://ex.test/c.jpg', cover: true),
      ],
      'https://ex.test/b.jpg',
      <String>[
        'https://ex.test/b.jpg',
        'https://ex.test/a.jpg',
        'https://ex.test/c.jpg',
      ],
    ),
    // Ce n'est pas un cas de bord : `whenLoaded` retire la clé dès que la
    // relation n'est pas chargée.
    'tout est nul quand la clé media est absente': (
      null,
      null,
      <String>[],
    ),
    'tout est nul quand la liste media est vide': (
      const <dynamic>[],
      null,
      <String>[],
    ),
    // LE CAS QUI MANQUAIT, et le seul où les trois divergeaient. Une URL vide
    // ferait un cadre noir dans la galerie ; pire, `coverUrl != null` est vrai
    // pour la chaîne vide, et les trois écrans qui testent cela affichaient le
    // carré gris de repli alors que la vraie photo attendait en position 2.
    'les médias sans adresse sont ignorés, couverture comprise': (
      <dynamic>[
        media(1, '', cover: true),
        media(2, 'https://ex.test/b.jpg'),
        media(3, ''),
      ],
      'https://ex.test/b.jpg',
      <String>['https://ex.test/b.jpg'],
    ),
  };

  for (final modele in modeles) {
    group('$modele.fromJson', () {
      for (final entree in cas.entries) {
        test(entree.key, () {
          final (medias, couvertureAttendue, photosAttendues) = entree.value;

          final rendu = lire(modele, medias);

          expect(rendu.photos, photosAttendues);
          expect(
            rendu.couverture,
            couvertureAttendue,
            reason: 'La couverture est le premier élément de la liste, '
                'toujours, et pour les trois modèles.',
          );
        });
      }

      /// L'invariant lui-même, énoncé une fois : c'est la phrase que le
      /// dartdoc de `Vehicle.coverUrl` affirme, et qui était fausse pour deux
      /// modèles sur trois.
      test('la couverture est toujours le premier élément de la liste', () {
        for (final entree in cas.entries) {
          final rendu = lire(modele, entree.value.$1);

          expect(
            rendu.couverture,
            rendu.photos.isEmpty ? isNull : rendu.photos.first,
            reason: '$modele, cas « ${entree.key} ».',
          );
        }
      });
    });
  }

  // ── Les médias des fixtures ───────────────────────────────────────────────

  /// Ce que les six cas ci-dessus ne peuvent pas protéger.
  ///
  /// Ils mesurent les parseurs sur des charges écrites ici. Les douze fixtures
  /// de `test/fixtures/`, elles, portaient toutes `"media": []` — `grep
  /// is_cover test/fixtures/*.json` ne rendait rien. Tout l'étage au-dessus du
  /// parseur — cartes, galeries, écrans — était donc mesuré sans une seule
  /// photo : on pouvait remettre `mediaUrls` sur un `map(url)` sans ordre et
  /// garder les quatre cents tests au vert, c'est-à-dire laisser revenir la
  /// panne qu'on vient de réparer.
  ///
  /// Les deux fixtures de véhicule portent maintenant trois médias dont la
  /// couverture en DEUXIÈME position. Le serveur ne les produit pas — voir
  /// l'en-tête d'`api_contract_test.dart`, où la divergence et son risque de
  /// recopie sont écrits.
  group('Les médias des fixtures', () {
    Map<String, dynamic> fixture(String nom) =>
        jsonDecode(File('test/fixtures/$nom.json').readAsStringSync())
            as Map<String, dynamic>;

    const couverture = 'https://media.autoparc.test/vehicles/1/tucson.jpg';

    /// Le garde-fou de la recopie : si `cp` depuis le backend remet
    /// `"media": []`, c'est ICI que ça tombe, en nommant la cause, au lieu de
    /// laisser les tests de rendu passer sur un article sans photo.
    void exigerLaFixture(List<dynamic> medias, String nom) {
      expect(
        medias.length,
        greaterThanOrEqualTo(2),
        reason: '$nom a perdu ses médias. Les fixtures ont probablement été '
            'recopiées depuis le backend, qui n\'en crée aucun : voir '
            'l\'en-tête d\'api_contract_test.dart.',
      );
      expect(
        medias.first['is_cover'],
        isNot(true),
        reason: 'La couverture doit être AILLEURS qu\'en première position, '
            'sans quoi un parseur qui ignore `is_cover` passerait quand même.',
      );
      expect(
        medias.firstWhere((m) => m['is_cover'] == true)['url'],
        couverture,
      );
    }

    test('la liste des véhicules porte une couverture non première', () {
      final brut = fixture('vehicles_list');
      final medias =
          ((brut['data'] as List).first as Map<String, dynamic>)['media']
              as List<dynamic>;

      exigerLaFixture(medias, 'vehicles_list.json');

      final page = PaginatedResponse.fromJson(brut, Vehicle.fromJson);
      expect(page.data.first.coverUrl, couverture);
      expect(page.data.first.mediaUrls.first, couverture);
    });

    test('la fiche véhicule porte la même couverture non première', () {
      final brut = fixture('vehicle_detail')['data'] as Map<String, dynamic>;

      exigerLaFixture(brut['media'] as List<dynamic>, 'vehicle_detail.json');

      final fiche = Vehicle.fromJson(brut);
      expect(fiche.coverUrl, couverture);
      expect(fiche.mediaUrls, hasLength(3));
      expect(fiche.mediaUrls.first, couverture);
    });

    /// La carte de la grille du catalogue, telle que l'écran la dessine. Elle
    /// ne montre qu'une image : c'est la couverture, et pas la première photo
    /// reçue.
    testWidgets('la carte du catalogue affiche la couverture', (tester) async {
      final vehicule = PaginatedResponse.fromJson(
        fixture('vehicles_list'),
        Vehicle.fromJson,
      ).data.first;

      // La carte n'a plus de hauteur imposée : la rangée la laisse grandir avec
      // son contenu, et un `SizedBox` à hauteur fixe ferait déborder une carte
      // qui, dans la vraie liste, se contente d'être plus haute. Seule la
      // largeur est contrainte — 188,5 points, la carte d'un écran de 411.
      // Les délégués et la locale : depuis la vague 2, la carte lit
      // `AppLocalizations.of(context)` pour son badge d'offre, et cette
      // méthode lève sur une coque qui ne les pose pas. `locale:` est
      // explicite pour la raison écrite dans test/support/langues.dart — un
      // banc sans elle résout l'anglais.
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: localeFr,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: 188.5,
                  child: VehicleCard(vehicle: vehicule),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      final images = tester.widgetList<CatalogImage>(find.byType(CatalogImage));
      expect(images, hasLength(1),
          reason: 'La carte ne montre qu\'une photo.');
      expect(images.first.url, couverture);
    });

    /// La galerie de la fiche, qui montre toutes les photos : c'est sa
    /// PREMIÈRE page qui doit être la couverture. Avec une couverture vide,
    /// cette page-là était un cadre blanc et le point de position comptait un
    /// média de plus que ce qu'il y avait à voir.
    testWidgets('la galerie de la fiche ouvre sur la couverture',
        (tester) async {
      final fiche = Vehicle.fromJson(
          fixture('vehicle_detail')['data'] as Map<String, dynamic>);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 240,
            child: ProductGallery(
              urls: fiche.mediaUrls,
              fallback: const ColoredBox(color: Color(0xFFEEEEEE)),
              titre: fiche.designation,
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(
        tester.widgetList<CatalogImage>(find.byType(CatalogImage)).first.url,
        couverture,
      );
    });
  });
}
