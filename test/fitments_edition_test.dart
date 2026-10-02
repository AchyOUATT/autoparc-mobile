import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/manufacturer.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/presentation/pages/add_part_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/catalog/presentation/widgets/fitments_section.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';

/// Déclarer les véhicules compatibles d'une pièce existante.
///
/// Le défaut que ce fichier verrouille était silencieux et destructeur. La
/// section « Compatibilités véhicules » démarrait vide, y compris en
/// modification. Le formulaire n'envoyait la clé `fitments` que si la liste
/// était non vide, et le `PUT` remplace la liste entière : ne pas toucher la
/// section préservait les données, en ajouter UNE remplaçait les cinq
/// existantes par celle-là. Sans message, sans confirmation — et c'est
/// exactement le geste qu'on vient faire sur cet écran.
///
/// Trois règles sont tenues ici.
///
/// La liste part de l'existant. Le test central ajoute une compatibilité à une
/// pièce qui en porte deux, et exige que l'envoi en contienne trois.
///
/// Rien ne se perd dans l'aller-retour. La ressource rend des identifiants et
/// des libellés ; `FitmentEntry` doit renvoyer les premiers sans se laisser
/// réduire aux seconds. Une colonne absente du renvoi serait vidée en base.
///
/// Ne pas savoir n'autorise pas à effacer. Si les compatibilités n'ont pas pu
/// être relues, l'enregistrement est refusé plutôt que de partir avec une
/// liste vide.
void main() {
  // ── Référentiel de test ────────────────────────────────────────

  const marque = BrandRef(id: 3, name: 'Toyota', isActive: true);
  const corolla = ModelRef(id: 11, brandId: 3, name: 'Corolla');
  const hilux = ModelRef(id: 12, brandId: 3, name: 'Hilux');
  const finition = TrimRef(id: 5, vehicleModelId: 11, name: 'Luxe');

  const refs = CatalogRefs(
    brands: [marque],
    vehicleModels: [corolla, hilux],
    trims: [finition],
    engineTypes: [],
    drivetrains: [],
    colors: [],
    features: [],
    locations: [],
  );

  /// Une ligne telle que l'API la rend sur la fiche d'une pièce.
  Map<String, dynamic> ligneApi({
    int modele = 11,
    String libelle = 'Toyota Corolla',
    String source = 'declared',
  }) =>
      {
        'id': modele,
        'vehicle_model_id': modele,
        'vehicle_model': libelle,
        'brand_id': 3,
        'trim_id': 5,
        'trim': 'Luxe',
        'engine_type_id': 8,
        'engine_type': '1.4 D-4D',
        'drivetrain_id': 2,
        'engine_code': '1ND-TV',
        'year_from': 2010,
        'year_to': 2014,
        'position': 'avant gauche',
        'notes': 'releve sur le vehicule du client',
        'source': source,
      };

  Part piece({List<Map<String, dynamic>>? fitments}) => Part(
        id: 42,
        sku: 'ESSAI-1',
        name: 'Filtre a huile',
        type: 'aftermarket',
        condition: 'new',
        categoryId: 1,
        pricing: const PartPricing(
          sellingPrice: 5000,
          currency: 'XOF',
          vatRate: 18,
          priceIncludingVat: 5900,
        ),
        stock: const PartStock(
          isAvailable: true,
          quantity: 4,
          alertThreshold: 1,
          isLow: false,
        ),
        isActive: true,
        fitments: fitments,
      );

  // ── L'aller-retour ─────────────────────────────────────────────

  group('Aller-retour d\'une compatibilité', () {
    test('toutes les colonnes écrites par l\'API reviennent dans le renvoi', () {
      final renvoi = FitmentEntry.depuisJson(ligneApi(), refs: refs).toJson();

      expect(renvoi, {
        'vehicle_model_id': 11,
        'trim_id': 5,
        'engine_type_id': 8,
        'drivetrain_id': 2,
        'engine_code': '1ND-TV',
        'year_from': 2010,
        'year_to': 2014,
        'position': 'avant gauche',
        'notes': 'releve sur le vehicule du client',
      });
    });

    test('l\'origine ne repart jamais : c\'est au serveur d\'en décider', () {
      final renvoi =
          FitmentEntry.depuisJson(ligneApi(source: 'generated'), refs: refs)
              .toJson();

      expect(renvoi.containsKey('source'), isFalse);
    });

    test('une ligne proposée est reconnue comme telle', () {
      expect(
        FitmentEntry.depuisJson(ligneApi(source: 'generated'), refs: refs).origin,
        FitmentOrigin.proposee,
      );
      expect(
        FitmentEntry.depuisJson(ligneApi(), refs: refs).origin,
        FitmentOrigin.declaree,
      );
    });

    /// Un modèle retiré du catalogue n'est plus dans le référentiel. Perdre
    /// son nom dégrade l'affichage ; perdre son identifiant perdrait la
    /// compatibilité elle-même.
    test('un modèle inconnu du référentiel garde son identifiant', () {
      final entree = FitmentEntry.depuisJson(
        ligneApi(modele: 999, libelle: 'Marque X Modele Y'),
        refs: refs,
      );

      expect(entree.vehicleModelId, 999);
      expect(entree.toJson()['vehicle_model_id'], 999);
      expect(entree.label, contains('Modele Y'));
    });

    /// La distinction qui tient tout l'écran, éprouvée à la source.
    ///
    /// La liste des pièces ne charge pas la relation : la clé est absente de
    /// la réponse, et `null` veut dire « on ne sait pas ». Une liste vide veut
    /// dire « aucune ». Les confondre fait effacer.
    test('clé absente et liste vide ne se confondent pas', () {
      Map<String, dynamic> base() => {
            'id': 1,
            'name': 'P',
            'type': 'aftermarket',
            'condition': 'new',
            'pricing': {
              'selling_price': 1,
              'currency': 'XOF',
              'vat_rate': 0,
              'price_including_vat': 1,
            },
            'stock': {
              'is_available': true,
              'quantity': 0,
              'alert_threshold': 0,
              'is_low': false,
            },
          };

      expect(Part.fromJson(base()).fitments, isNull,
          reason: 'Clé absente : la réponse ne le dit pas.');
      expect(Part.fromJson({...base(), 'fitments': []}).fitments, isEmpty,
          reason: 'Liste vide : la pièce n\'en déclare aucune.');
      expect(
        Part.fromJson({...base(), 'fitments': [ligneApi()]}).fitments,
        hasLength(1),
      );
    });

    test('sans libellé ni référentiel, la ligne reste identifiable', () {
      final entree = FitmentEntry.depuisJson({'vehicle_model_id': 77});

      expect(entree.label, contains('77'));
      expect(entree.initiale, isNotEmpty);
      expect(entree.toJson(), {'vehicle_model_id': 77});
    });
  });

  // ── La section ─────────────────────────────────────────────────

  group('Section des compatibilités', () {
    Widget hote(List<FitmentEntry> initiales,
            {void Function(List<FitmentEntry>)? onChanged}) =>
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FitmentsSection(
                refs: refs,
                showPosition: true,
                initiales: initiales,
                onChanged: onChanged ?? (_) {},
              ),
            ),
          ),
        );

    testWidgets('elle affiche les compatibilités déjà enregistrées',
        (tester) async {
      await tester.pumpWidget(hote([
        FitmentEntry.depuisJson(ligneApi(), refs: refs),
      ]));

      expect(find.textContaining('Toyota Corolla'), findsOneWidget);
      expect(find.text('Aucune compatibilité déclarée'), findsNothing);
    });

    testWidgets('elle dit lesquelles n\'ont été vérifiées par personne',
        (tester) async {
      await tester.pumpWidget(hote([
        FitmentEntry.depuisJson(ligneApi(source: 'generated'), refs: refs),
      ]));

      expect(find.text('Proposée automatiquement, non vérifiée'), findsOneWidget);
    });

    testWidgets('retirer une ligne ne retire que celle-là', (tester) async {
      var dernier = <FitmentEntry>[];

      await tester.pumpWidget(hote(
        [
          FitmentEntry.depuisJson(ligneApi(), refs: refs),
          FitmentEntry.depuisJson(
              ligneApi(modele: 12, libelle: 'Toyota Hilux'),
              refs: refs),
        ],
        onChanged: (l) => dernier = l,
      ));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(dernier.length, 1);
      expect(dernier.single.vehicleModelId, 12);
    });
  });

  // ── L'écran de modification ────────────────────────────────────

  /// Laisse l'écran se stabiliser.
  ///
  /// `pumpAndSettle` ne rend jamais la main ici : la page porte des
  /// `LinearProgressIndicator`, dont l'animation ne s'arrête pas. On pompe
  /// donc un nombre fini de fois, ce qui suffit à résoudre les futures du
  /// dépôt simulé.
  Future<void> poser(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Écran de modification', () {
    Widget ecran(_FauxDepot depot, Part existante) => ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(depot),
            catalogRefsProvider.overrideWith((_) async => refs),
          ],
          child: MaterialApp(home: AddPartPage(existing: existante)),
        );

    /// Le test central : le geste même qui détruisait.
    ///
    /// Une pièce porte deux compatibilités, on en ajoute une troisième par le
    /// formulaire, et l'envoi doit en contenir trois. Avant, la section
    /// démarrait vide : l'ajout remontait une liste d'un seul élément, et le
    /// `PUT` remplaçait les deux autres par celle-là.
    testWidgets('ajouter une compatibilité conserve les existantes',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Les deux existantes portent des modèles que l'ajout n'utilisera pas,
      // sans quoi la ligne ajoutée serait indistinguable d'une survivante.
      final depot = _FauxDepot(
        complete: piece(fitments: [
          ligneApi(),
          ligneApi(modele: 999, libelle: 'Marque X Ancien'),
        ]),
      );

      await tester.pumpWidget(ecran(depot, piece()));
      await poser(tester);

      // Le formulaire d'ajout, piloté comme le ferait quelqu'un.
      await tester.tap(find.text('Ajouter une compatibilité'));
      await poser(tester);

      await tester.tap(find.text('Marque *'));
      await poser(tester);
      await tester.tap(find.text('Toyota').last);
      await poser(tester);

      await tester.tap(find.text('Modèle *'));
      await poser(tester);
      await tester.tap(find.textContaining('Hilux').last);
      await poser(tester);

      await tester.tap(find.text('Ajouter cette compatibilité'));
      await poser(tester);

      await tester.tap(find.text('Enregistrer'));
      await poser(tester);

      final envoyees = depot.dernierEnvoi?['fitments'] as List?;

      expect(envoyees, isNotNull, reason: 'La clé doit toujours partir.');
      expect(envoyees!.length, 3,
          reason: 'Les deux compatibilités existantes doivent survivre à l\'ajout.');
      expect(
        envoyees.map((f) => (f as Map)['vehicle_model_id']).toList(),
        [11, 999, 12],
        reason: 'Les deux premières sont les existantes, la dernière l\'ajout.',
      );
    });

    /// Relire et renvoyer sans rien toucher ne doit rien changer.
    testWidgets('enregistrer sans toucher aux compatibilités les renvoie toutes',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final depot = _FauxDepot(
        complete: piece(fitments: [
          ligneApi(),
          ligneApi(modele: 12, libelle: 'Toyota Hilux'),
        ]),
      );

      // La pièce arrive de la liste, qui ne porte pas les compatibilités.
      await tester.pumpWidget(ecran(depot, piece()));
      await poser(tester);

      expect(depot.pieceRelue, 42, reason: 'La fiche doit être relue.');
      expect(find.textContaining('Toyota Corolla'), findsWidgets);
      expect(find.textContaining('Toyota Hilux'), findsWidgets);

      await tester.tap(find.text('Enregistrer'));
      await poser(tester);

      final envoyees = depot.dernierEnvoi?['fitments'] as List?;

      expect(envoyees, isNotNull, reason: 'La clé doit partir.');
      expect(envoyees!.length, 2,
          reason: 'Les deux compatibilités existantes doivent repartir.');
      expect(
        envoyees.map((f) => (f as Map)['vehicle_model_id']).toList(),
        [11, 12],
      );

      // Et elles repartent entières, pas réduites à leur modèle.
      expect((envoyees.first as Map)['trim_id'], 5);
      expect((envoyees.first as Map)['engine_code'], '1ND-TV');
      expect((envoyees.first as Map)['notes'], 'releve sur le vehicule du client');
    });

    testWidgets('une pièce sans compatibilité envoie une liste vide, pas rien',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final depot = _FauxDepot(complete: piece(fitments: const []));

      await tester.pumpWidget(ecran(depot, piece()));
      await poser(tester);

      await tester.tap(find.text('Enregistrer'));
      await poser(tester);

      expect(depot.dernierEnvoi?['fitments'], isEmpty);
    });

    /// Le réseau flanche au mauvais moment.
    ///
    /// Envoyer une liste qu'on n'a pas relue l'effacerait. Refuser tout
    /// l'enregistrement ferait de l'écran un cul-de-sac — plus moyen de
    /// corriger un prix. L'API ne touche aux compatibilités que si la clé est
    /// présente : on l'omet, et le reste part.
    testWidgets('compatibilités illisibles : la clé est omise, le reste passe',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final depot = _FauxDepot(echoueRelecture: true);

      await tester.pumpWidget(ecran(depot, piece()));
      await poser(tester);

      expect(find.text('Compatibilités non relues'), findsOneWidget);

      await tester.tap(find.text('Enregistrer'));
      await poser(tester);

      expect(depot.dernierEnvoi, isNotNull,
          reason: 'Le reste de la fiche doit rester enregistrable.');
      expect(
        depot.dernierEnvoi!.containsKey('fitments'),
        isFalse,
        reason: 'Sans la liste relue, la clé ne doit pas partir : '
            'l\'API remplacerait tout par ce qu\'elle reçoit.',
      );
      expect(depot.dernierEnvoi!['name'], 'Filtre a huile');
    });

    /// Tant que la relecture est en cours, l'écran ne doit pas annoncer un
    /// échec — ni laisser enregistrer une liste vide.
    testWidgets('pendant la relecture, aucun échec n\'est annoncé',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final attente = Completer<Part>();
      final depot = _FauxDepot(relecture: () => attente.future);

      await tester.pumpWidget(ecran(depot, piece()));
      await poser(tester);

      expect(find.text('Compatibilités non relues'), findsNothing);
      expect(find.byType(FitmentsSection), findsNothing,
          reason: 'Une section vide inviterait à saisir en double.');

      attente.complete(piece(fitments: [ligneApi()]));
      await poser(tester);

      expect(find.byType(FitmentsSection), findsOneWidget);
      expect(find.textContaining('Toyota Corolla'), findsWidgets);
    });

    /// Quand la fiche porte déjà ses compatibilités, inutile de la relire.
    testWidgets('une fiche complète n\'est pas rechargée', (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final depot = _FauxDepot(complete: piece(fitments: [ligneApi()]));

      await tester.pumpWidget(ecran(depot, piece(fitments: [ligneApi()])));
      await poser(tester);

      expect(depot.pieceRelue, isNull);
      expect(find.textContaining('Toyota Corolla'), findsWidgets);
    });
  });
}

/// Dépôt qui répond depuis un scénario en mémoire et retient ce qu'on envoie.
class _FauxDepot extends CatalogRepository {
  _FauxDepot({this.complete, this.echoueRelecture = false, this.relecture})
      : super(ApiClient(), CatalogLocalCache());

  final Part? complete;
  final bool echoueRelecture;

  /// Pour tenir la relecture en suspens et observer l'écran pendant.
  final Future<Part> Function()? relecture;

  int? pieceRelue;
  Map<String, dynamic>? dernierEnvoi;

  @override
  Future<Part> getPart(int id) async {
    pieceRelue = id;
    if (echoueRelecture) throw Exception('reseau indisponible');
    if (relecture != null) return relecture!();
    return complete!;
  }

  @override
  Future<Part> updatePart(int id, Map<String, dynamic> data) async {
    dernierEnvoi = data;
    return complete ?? await getPart(id);
  }

  @override
  Future<List<PartCategory>> getPartCategories() async =>
      const [PartCategory(id: 1, name: 'Filtration')];

  @override
  Future<List<Manufacturer>> getManufacturers() async =>
      const [Manufacturer(id: 1, name: 'Bosch')];
}
