import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/manufacturer.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/presentation/pages/add_part_page.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/langues.dart';

/// Le champ Description du formulaire staff de création / édition d'une pièce.
///
/// Il manquait à l'écran alors que la fiche l'affiche déjà, que le modèle le
/// porte, et que l'API l'accepte en création comme en modification. Sans ce
/// champ, une description ne peut être ni saisie, ni corrigée, ni effacée.
void main() {
  const refs = CatalogRefs(
    brands: [],
    vehicleModels: [],
    trims: [],
    engineTypes: [],
    drivetrains: [],
    colors: [],
    features: [],
    locations: [],
  );

  Part piece({String? description}) => Part(
    id: 211,
    sku: 'PE02-18-211',
    name: 'Capteur MAP Mazda',
    description: description,
    type: 'aftermarket',
    condition: 'new',
    categoryId: 1,
    pricing: const PartPricing(
      sellingPrice: 20000,
      currency: 'XOF',
      vatRate: 18,
      priceIncludingVat: 23600,
    ),
    stock: const PartStock(
      isAvailable: true,
      quantity: 2,
      alertThreshold: 5,
      isLow: false,
    ),
    isActive: true,
    fitments: const [],
  );

  Future<void> poser(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Widget ecran(_FauxDepot depot, {Part? existante, Locale locale = localeFr}) =>
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(depot),
          catalogRefsProvider.overrideWith((_) async => refs),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddPartPage(existing: existante),
        ),
      );

  Finder champDescription() =>
      find.widgetWithText(TextFormField, 'Description');

  testWidgets('le champ est présent à la création, en français et en anglais', (
    tester,
  ) async {
    for (final locale in [localeFr, localeEn]) {
      final depot = _FauxDepot();
      await tester.pumpWidget(ecran(depot, locale: locale));
      await poser(tester);

      expect(
        champDescription(),
        findsOneWidget,
        reason:
            'Le libellé « Description » est identique dans les deux langues.',
      );
    }
  });

  testWidgets('en modification, la description existante préremplit le champ', (
    tester,
  ) async {
    const texte = 'Capteur MAP pour moteurs SKYACTIV-G atmosphériques.';
    final existante = piece(description: texte);
    final depot = _FauxDepot(complete: existante);

    await tester.pumpWidget(ecran(depot, existante: existante));
    await poser(tester);

    expect(champDescription(), findsOneWidget);
    expect(find.text(texte), findsOneWidget);
  });

  testWidgets('l\'enregistrement envoie la description saisie', (tester) async {
    final existante = piece(description: 'Ancienne description');
    final depot = _FauxDepot(complete: existante);

    await tester.pumpWidget(ecran(depot, existante: existante));
    await poser(tester);

    await tester.enterText(
      champDescription(),
      '  Nouvelle description, achetée en Chine.  ',
    );
    await tester.tap(find.text('Enregistrer'));
    await poser(tester);

    expect(depot.dernierEnvoi, isNotNull);
    expect(
      depot.dernierEnvoi!['description'],
      'Nouvelle description, achetée en Chine.',
    );
  });

  testWidgets(
    'vider le champ envoie null, pour effacer la description en base',
    (tester) async {
      final existante = piece(description: 'Texte à retirer');
      final depot = _FauxDepot(complete: existante);

      await tester.pumpWidget(ecran(depot, existante: existante));
      await poser(tester);

      await tester.enterText(champDescription(), '   ');
      await tester.tap(find.text('Enregistrer'));
      await poser(tester);

      expect(depot.dernierEnvoi, isNotNull);
      expect(depot.dernierEnvoi!.containsKey('description'), isTrue);
      expect(depot.dernierEnvoi!['description'], isNull);
    },
  );

  testWidgets('à la création, la description saisie part avec le reste', (
    tester,
  ) async {
    final depot = _FauxDepot(complete: piece());

    await tester.pumpWidget(ecran(depot));
    await poser(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Désignation *'),
      'Capteur MAP Mazda',
    );
    await tester.enterText(
      champDescription(),
      'Pièce adaptable, achetée en Chine.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prix de vente *'),
      '20000',
    );

    // Catégorie obligatoire.
    await tester.tap(find.text('Catégorie *'));
    await poser(tester);
    await tester.tap(find.text('Capteur de pression').last);
    await poser(tester);

    await tester.tap(find.text('Enregistrer'));
    await poser(tester);

    expect(depot.creation, isNotNull, reason: 'La création doit partir.');
    expect(depot.creation!['name'], 'Capteur MAP Mazda');
    expect(
      depot.creation!['description'],
      'Pièce adaptable, achetée en Chine.',
    );
  });
}

class _FauxDepot extends CatalogRepository {
  _FauxDepot({this.complete}) : super(ApiClient(), CatalogLocalCache());

  final Part? complete;
  Map<String, dynamic>? dernierEnvoi;
  Map<String, dynamic>? creation;

  @override
  Future<Part> getPart(int id, {bool forStaff = false}) async =>
      complete ?? (throw StateError('getPart appelé sans fiche en mémoire'));

  @override
  Future<Part> updatePart(int id, Map<String, dynamic> data) async {
    dernierEnvoi = data;
    return complete ?? await getPart(id);
  }

  @override
  Future<Part> createPart(Map<String, dynamic> data) async {
    creation = data;
    return complete ??
        Part(
          id: 1,
          name: data['name'] as String,
          description: data['description'] as String?,
          type: null,
          condition: data['condition'] as String? ?? 'new',
          pricing: const PartPricing(
            sellingPrice: 0,
            currency: 'XOF',
            vatRate: 0,
            priceIncludingVat: 0,
          ),
          stock: const PartStock(quantity: 0, alertThreshold: 0, isLow: false),
          isActive: true,
        );
  }

  @override
  Future<List<PartCategory>> getPartCategories() async => const [
    PartCategory(id: 1, name: 'Capteur de pression'),
  ];

  @override
  Future<List<Manufacturer>> getManufacturers() async => const [
    Manufacturer(id: 1, name: 'Chine'),
  ];
}
