import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/catalog/presentation/widgets/fitments_section.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

/// Captures avant / après du champ « Code châssis ».
///
///   CAPTURES=1 CAPTURE_PREFIX=avant flutter test \
///     test/captures_code_chassis_test.dart --update-goldens
///
/// Les PNG sont aussi copiés dans `/workspace/captures-code-chassis/`.
final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';
final String prefixe = Platform.environment['CAPTURE_PREFIX'] ?? 'apres';

const marque = BrandRef(id: 3, name: 'Toyota', isActive: true);
const corolla = ModelRef(
  id: 11,
  brandId: 3,
  name: 'Corolla',
  generation: 'E120',
);
const refs = CatalogRefs(
  brands: [marque],
  vehicleModels: [corolla],
  trims: [],
  engineTypes: [],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

void main() {
  setUpAll(() => chargerPolices(exigerRoboto: false));

  testWidgets('liste des compatibilités d\'une pièce', (tester) async {
    await _poserTaille(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final ligne = FitmentEntry.depuisJson({
      'vehicle_model_id': 11,
      'vehicle_model': 'Toyota Corolla E120',
      'brand_id': 3,
      'engine_code': '1ZZ-FE',
      'chassis_code': 'ZZE122/ZZE124',
      'year_from': 2000,
      'year_to': 2006,
      'source': 'declared',
    }, refs: refs);

    await tester.pumpWidget(_hote(initiales: [ligne]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Corolla'), findsWidgets);
    expect(ligne.labelDans(l10n), contains('1ZZ-FE'));
    await _capturer(tester, 'liste-compatibilite');
  });

  testWidgets('formulaire d\'ajout d\'une compatibilité', (tester) async {
    await _poserTaille(tester);
    await tester.pumpWidget(_hote());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Ajouter une compatibilité'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Code moteur'), findsOneWidget);
    // Le champ châssis n'existe pas encore sur « avant ».
    final champChassis = find.text('Code châssis');
    if (prefixe == 'apres') {
      expect(champChassis, findsOneWidget);
    }

    await tester.ensureVisible(find.text('Code moteur'));
    await tester.pump();
    await _capturer(tester, 'formulaire-compatibilite');
  });
}

Widget _hote({List<FitmentEntry> initiales = const []}) => MaterialApp(
  locale: const Locale('fr'),
  theme: themeAutoParc(Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    appBar: AppBar(title: const Text('Compatibilités')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FitmentsSection(
        refs: refs,
        showPosition: true,
        recommanderCodeMoteur: true,
        initiales: initiales,
        onChanged: (_) {},
      ),
    ),
  ),
);

Future<void> _poserTaille(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _capturer(WidgetTester tester, String nom) async {
  if (!ecrireCaptures) return;
  final fichier = '${prefixe}-$nom';
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../build/captures-code-chassis/$fichier.png'),
  );
  final source = File('build/captures-code-chassis/$fichier.png');
  if (source.existsSync()) {
    Directory('/workspace/captures-code-chassis').createSync(recursive: true);
    source.copySync('/workspace/captures-code-chassis/$fichier.png');
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}
