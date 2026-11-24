import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/core/theme/app_theme.dart';
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
import 'support/polices.dart';

/// Captures avant / après du champ « Description » sur le formulaire pièce.
///
///   CAPTURES=1 CAPTURE_PREFIX=avant flutter test \
///     test/captures_description_piece_test.dart --update-goldens
///
/// Les PNG sont aussi copiés dans `/workspace/captures-description-piece/`.
final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';
final String prefixe = Platform.environment['CAPTURE_PREFIX'] ?? 'apres';

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

Part _piece() => Part(
  id: 211,
  sku: 'PE02-18-211',
  name: 'Capteur MAP (pression d\'admission) Mazda',
  description:
      'Capteur MAP pour moteurs SKYACTIV-G atmosphériques. '
      'Hors 2,5 l Turbo (PY8W-18-211) et diesel (SH01-18-211).',
  type: 'aftermarket',
  condition: 'new',
  categoryId: 1,
  categoryName: 'Capteur de pression',
  manufacturerId: 1,
  manufacturer: 'Chine',
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
    location: 'Ouagadougou',
  ),
  isActive: true,
  fitments: const [],
);

class _FauxDepot extends CatalogRepository {
  _FauxDepot() : super(ApiClient(), CatalogLocalCache());

  @override
  Future<Part> getPart(int id, {bool forStaff = false}) async => _piece();

  @override
  Future<List<PartCategory>> getPartCategories() async => const [
    PartCategory(id: 1, name: 'Capteur de pression'),
  ];

  @override
  Future<List<Manufacturer>> getManufacturers() async => const [
    Manufacturer(id: 1, name: 'Chine'),
  ];
}

void main() {
  setUpAll(() => chargerPolices(exigerRoboto: false));

  Future<void> poser(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Widget ecran() => ProviderScope(
    overrides: [
      catalogRepositoryProvider.overrideWithValue(_FauxDepot()),
      catalogRefsProvider.overrideWith((_) async => refs),
    ],
    child: MaterialApp(
      locale: localeFr,
      theme: themeAutoParc(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AddPartPage(existing: _piece()),
    ),
  );

  testWidgets('formulaire d\'édition d\'une pièce', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ecran());
    await poser(tester);

    expect(find.textContaining('Capteur MAP'), findsWidgets);
    expect(find.text('PE02-18-211'), findsOneWidget);

    final champDescription = find.widgetWithText(TextFormField, 'Description');
    if (prefixe == 'apres') {
      expect(champDescription, findsOneWidget);
      expect(
        find.textContaining('SKYACTIV-G'),
        findsOneWidget,
        reason: 'La description existante doit préremplir le champ.',
      );
      await tester.ensureVisible(champDescription);
      await tester.pump();
    } else {
      expect(
        champDescription,
        findsNothing,
        reason: 'Sur « avant », le champ n\'existe pas encore.',
      );
    }

    await _capturer(tester, 'formulaire-piece');
  });
}

Future<void> _capturer(WidgetTester tester, String nom) async {
  if (!ecrireCaptures) return;
  final fichier = '$prefixe-$nom';
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../build/captures-description-piece/$fichier.png'),
  );
  final source = File('build/captures-description-piece/$fichier.png');
  if (source.existsSync()) {
    Directory(
      '/workspace/captures-description-piece',
    ).createSync(recursive: true);
    source.copySync('/workspace/captures-description-piece/$fichier.png');
  }
}
