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

/// Responsivité du formulaire de pièce, notamment le nouveau champ Description.
///
/// Les captures se régénèrent ainsi :
///
///   CAPTURES=1 flutter test test/description_piece_responsivite_test.dart \
///     --update-goldens --name capture
///
/// Les PNG sont aussi copiés dans `/workspace/captures-description-piece/responsivity/`.
final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

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

/// Un nom et une description volontairement trop longs pour un petit écran.
const nomLong =
    'Capteur MAP (pression d\'admission) compatible Mazda PE02-18-211 '
    'pour moteurs SKYACTIV-G atmosphériques';

const descriptionLongue = '''
Capteur MAP pour moteurs SKYACTIV-G atmosphériques.
Pièce adaptable, achetée en Chine.
Compatible avec la référence d'origine Mazda PE02-18-211.
Hors 2,5 l Turbo (PY8W-18-211).
Hors diesel (SH01-18-211).
Hors CX-30 et CX-50 (PEDD-18-211).
Sur Mazda 3, vérifier le VIN entre PE02-18-211 et PEDD-18-211.
Ne pas monter sur un moteur turbo.
''';

Part _piece() => Part(
  id: 211,
  sku: 'PE02-18-211',
  name: nomLong,
  description: descriptionLongue,
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

class _Cas {
  const _Cas({
    required this.nom,
    required this.taille,
    this.echelle = 1.0,
    this.clavier = 0,
    this.locale = localeFr,
  });

  final String nom;
  final Size taille;
  final double echelle;
  final double clavier;
  final Locale locale;
}

/// Tous les formats demandés, en français et en anglais, avec le texte long.
const cas = <_Cas>[
  // Téléphones étroits
  _Cas(nom: '320x568 fr x1.0', taille: Size(320, 568)),
  _Cas(nom: '320x568 fr x1.3', taille: Size(320, 568), echelle: 1.3),
  _Cas(nom: '320x568 fr x1.5', taille: Size(320, 568), echelle: 1.5),
  _Cas(nom: '360x640 fr x1.0', taille: Size(360, 640)),
  _Cas(nom: '360x640 fr x1.3', taille: Size(360, 640), echelle: 1.3),
  _Cas(nom: '360x640 fr x1.5', taille: Size(360, 640), echelle: 1.5),
  // Téléphone courant
  _Cas(nom: '390x844 fr x1.0', taille: Size(390, 844)),
  _Cas(nom: '390x844 fr x1.3', taille: Size(390, 844), echelle: 1.3),
  // Paysage
  _Cas(nom: '844x390 fr x1.0', taille: Size(844, 390)),
  _Cas(nom: '844x390 fr x1.3', taille: Size(844, 390), echelle: 1.3),
  _Cas(nom: '640x360 fr x1.0', taille: Size(640, 360)),
  _Cas(nom: '640x360 fr x1.3', taille: Size(640, 360), echelle: 1.3),
  // Clavier ouvert
  _Cas(nom: '360x640 fr x1.0 clavier', taille: Size(360, 640), clavier: 300),
  _Cas(
    nom: '360x640 fr x1.3 clavier',
    taille: Size(360, 640),
    echelle: 1.3,
    clavier: 300,
  ),
  _Cas(
    nom: '360x640 fr x1.5 clavier',
    taille: Size(360, 640),
    echelle: 1.5,
    clavier: 300,
  ),
  // Anglais, mêmes formats critiques
  _Cas(nom: '320x568 en x1.0', taille: Size(320, 568), locale: localeEn),
  _Cas(
    nom: '320x568 en x1.3',
    taille: Size(320, 568),
    echelle: 1.3,
    locale: localeEn,
  ),
  _Cas(
    nom: '360x640 en x1.3',
    taille: Size(360, 640),
    echelle: 1.3,
    locale: localeEn,
  ),
  _Cas(
    nom: '360x640 en x1.5',
    taille: Size(360, 640),
    echelle: 1.5,
    locale: localeEn,
  ),
  _Cas(nom: '390x844 en x1.0', taille: Size(390, 844), locale: localeEn),
  _Cas(nom: '844x390 en x1.0', taille: Size(844, 390), locale: localeEn),
  _Cas(
    nom: '640x360 en x1.3',
    taille: Size(640, 360),
    echelle: 1.3,
    locale: localeEn,
  ),
  _Cas(
    nom: '360x640 en x1.3 clavier',
    taille: Size(360, 640),
    echelle: 1.3,
    clavier: 300,
    locale: localeEn,
  ),
];

void main() {
  setUpAll(() => chargerPolices(exigerRoboto: true));

  Future<void> poser(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Widget ecran(_Cas cas) => MediaQuery(
    data: MediaQueryData(
      size: cas.taille,
      textScaler: TextScaler.linear(cas.echelle),
      padding: const EdgeInsets.only(top: 24, bottom: 48),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
      viewInsets: EdgeInsets.only(bottom: cas.clavier),
    ),
    child: ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(_FauxDepot()),
        catalogRefsProvider.overrideWith((_) async => refs),
      ],
      child: MaterialApp(
        locale: cas.locale,
        debugShowCheckedModeBanner: false,
        theme: themeAutoParc(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddPartPage(existing: _piece()),
      ),
    ),
  );

  Future<Object?> mesurer(WidgetTester tester, _Cas cas) async {
    tester.view.physicalSize = cas.taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ecran(cas));
    await poser(tester);

    final immediat = tester.takeException();
    if (immediat != null) return immediat;

    expect(
      find.textContaining('PE02-18-211'),
      findsWidgets,
      reason:
          'L\'écran ne s\'est pas dessiné : rien n\'a été mesuré (${cas.nom}).',
    );
    expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);

    // Atteindre le champ Description, puis les lignes à deux colonnes.
    final defilable = find.byType(Scrollable);
    if (defilable.evaluate().isNotEmpty) {
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Description'),
      );
      await poser(tester);
      final apresDescription = tester.takeException();
      if (apresDescription != null) return apresDescription;

      // Les puces d'état et les lignes Prix / Stock peuvent déborder
      // plus bas, hors du premier écran — surtout en paysage ou au clavier.
      for (var i = 0; i < 10; i++) {
        await tester.drag(defilable.first, const Offset(0, -220));
        await poser(tester);
        final erreur = tester.takeException();
        if (erreur != null) return erreur;
      }
    }

    return tester.takeException();
  }

  group('Formulaire pièce, textes longs', () {
    for (final cas in cas) {
      testWidgets('tient en ${cas.nom}', (tester) async {
        final erreur = await mesurer(tester, cas);
        expect(
          erreur,
          isNull,
          reason: 'Débordement ou FlutterError en ${cas.nom} : $erreur',
        );
      });
    }
  });

  group('captures', () {
    Future<void> capturer(
      WidgetTester tester,
      _Cas cas,
      String fichier, {
      Finder? viser,
    }) async {
      tester.view.physicalSize = cas.taille;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ecran(cas));
      await poser(tester);
      if (viser != null && viser.evaluate().isNotEmpty) {
        await tester.ensureVisible(viser);
        await poser(tester);
      }
      expect(tester.takeException(), isNull);

      if (!ecrireCaptures) return;
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../build/captures-description-piece/responsivity/$fichier.png',
        ),
      );
      final source = File(
        'build/captures-description-piece/responsivity/$fichier.png',
      );
      if (source.existsSync()) {
        Directory(
          '/workspace/captures-description-piece/responsivity',
        ).createSync(recursive: true);
        source.copySync(
          '/workspace/captures-description-piece/responsivity/$fichier.png',
        );
      }
    }

    testWidgets('petit-ecran-320', (tester) async {
      await capturer(
        tester,
        const _Cas(nom: 'capture 320', taille: Size(320, 568)),
        'petit-ecran-320',
      );
    });

    testWidgets('grand-texte-130', (tester) async {
      await capturer(
        tester,
        const _Cas(
          nom: 'capture 360 x1.3',
          taille: Size(360, 640),
          echelle: 1.3,
        ),
        'grand-texte-130',
      );
    });

    testWidgets('paysage', (tester) async {
      await capturer(
        tester,
        const _Cas(nom: 'capture paysage', taille: Size(844, 390)),
        'paysage',
      );
    });
  });
}
