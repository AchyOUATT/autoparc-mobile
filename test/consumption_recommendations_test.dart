import 'package:auto/features/garage/data/models/motorisation.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_recommendations.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleConsumption reference(int id) => VehicleConsumption(
  label: 'Engine $id',
  sourceModel: 'Variant $id',
  source: 'Source $id',
  cycle: 'WLTP',
  cycleCode: 'wltp',
  referenceCombinedL100km: 6 + id / 10,
  referenceStatus: 'documented',
  matchLevel: 'approximate',
  modelYear: 2018,
  yearKind: 'model_year',
  market: 'CA',
);

Motorisation option(
  int id, {
  int? rank = 1,
  bool evidence = true,
  bool eligible = true,
}) => Motorisation(
  id: id,
  label: 'Engine $id',
  modelYear: 2018,
  recommendationRank: rank,
  hasDiscriminatingMatch: evidence,
  recommendationEligible: eligible,
  matchedCriteria: evidence ? const ['engine_l', 'cylinders'] : const [],
  missingCriteria: const ['model_year', 'market'],
  conflictingCriteria: eligible ? const [] : const ['cylinders'],
  consumption: reference(id),
);

OwnedVehicle vehicle({int? selectedId, VehicleConsumption? consumption}) =>
    OwnedVehicle(
      id: 1,
      designation: 'Toyota Camry',
      brandId: 1,
      vehicleModelId: 2,
      year: 2018,
      identity: const OwnedVehicleIdentity(brand: 'Toyota', model: 'Camry'),
      compatibilityReady: false,
      motorisationId: selectedId,
      consumption: consumption,
    );

Future<void> open(
  WidgetTester tester,
  List<Motorisation> options, {
  String language = 'fr',
  OwnedVehicle? ownedVehicle,
  ValueChanged<Motorisation?>? onSelected,
  VoidCallback? onRefine,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showDialog<Motorisation>(
                context: context,
                builder: (_) => ConsumptionRecommendationsDialog(
                  vehicle: ownedVehicle ?? vehicle(),
                  options: options,
                  onRefine: onRefine,
                ),
              );
              onSelected?.call(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder card(int id) =>
    find.byKey(ValueKey('consumption-recommendation-option-$id'));
Finder get toggle =>
    find.byKey(const ValueKey('consumption-recommendation-show-all'));

Future<void> revealAll(WidgetTester tester) async {
  await tester.ensureVisible(toggle);
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['fr', 'en']) {
    testWidgets(
      'one clear closest rank is shown without choosing automatically in $language',
      (tester) async {
        Motorisation? selected;
        await open(
          tester,
          [option(2, rank: 2), option(1)],
          language: language,
          onSelected: (value) => selected = value,
        );
        expect(
          find.text(
            language == 'fr' ? 'Référence la plus proche' : 'Closest reference',
          ),
          findsOneWidget,
        );
        expect(card(1), findsOneWidget);
        expect(
          card(2),
          findsNothing,
          reason: 'A lower rank is not part of the best group.',
        );
        expect(selected, isNull);
        expect(
          find.textContaining(
            language == 'fr' ? 'Valeur de la source' : 'Source value',
          ),
          findsOneWidget,
        );
        await revealAll(tester);
        expect(card(2), findsOneWidget);
        await tester.ensureVisible(card(1));
        await tester.tap(find.text('Variant 1'));
        await tester.pumpAndSettle();
        expect(selected?.id, 1);
      },
    );
  }

  testWidgets('equally ranked candidates are capped and remain ties', (
    tester,
  ) async {
    await open(tester, [
      for (var i = 1; i <= 5; i++) option(i),
      option(6, rank: 2),
    ]);
    expect(find.text('Références à départager'), findsOneWidget);
    expect(
      find.text(
        '5 références sont aussi proches. Les trois premières sont affichées.',
      ),
      findsOneWidget,
    );
    for (final id in [1, 2, 3]) {
      expect(card(id), findsOneWidget);
    }
    for (final id in [4, 5, 6]) {
      expect(card(id), findsNothing);
    }
    await revealAll(tester);
    for (final id in [4, 5, 6]) {
      expect(card(id), findsOneWidget);
    }
  });

  testWidgets(
    'equal ranks preserve the server order rather than sorting by values',
    (tester) async {
      await open(tester, [
        for (final id in [31, 2, 44, 8, 90, 1]) option(id),
      ]);
      for (final id in [31, 2, 44]) {
        expect(card(id), findsOneWidget);
      }
      for (final id in [8, 90, 1]) {
        expect(card(id), findsNothing);
      }
      expect(
        tester.getTopLeft(card(31)).dy,
        lessThan(tester.getTopLeft(card(2)).dy),
      );
      expect(
        tester.getTopLeft(card(2)).dy,
        lessThan(tester.getTopLeft(card(44)).dy),
      );
    },
  );

  testWidgets(
    'a withdrawn reference cannot become the closest selectable candidate',
    (tester) async {
      final withdrawn = Motorisation(
        id: 99,
        label: 'Withdrawn engine',
        modelYear: 2018,
        recommendationRank: 1,
        hasDiscriminatingMatch: true,
        consumption: const VehicleConsumption(
          label: 'Withdrawn engine',
          source: 'Old source',
          cycle: 'WLTP',
          referenceStatus: 'withdrawn',
          matchLevel: 'corresponding',
          combinedL100km: 5,
        ),
      );
      await open(tester, [withdrawn]);
      expect(find.text('Référence la plus proche'), findsNothing);
      expect(card(99), findsNothing);
      await revealAll(tester);
      expect(card(99), findsOneWidget);
      await tester.ensureVisible(find.text('Withdrawn engine'));
      await tester.tap(find.text('Withdrawn engine'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('Écart avec les caractéristiques'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'unranked older-server candidates do not claim an exact or closest match',
    (tester) async {
      await open(tester, [option(1, rank: null), option(2, rank: null)]);
      expect(find.text('Précisez la version du moteur'), findsOneWidget);
      expect(find.text('Référence la plus proche'), findsNothing);
      expect(find.text('Références à départager'), findsNothing);
      expect(card(1), findsOneWidget);
      expect(card(2), findsOneWidget);
      expect(find.textContaining('informations connues'), findsOneWidget);
    },
  );

  testWidgets(
    'a rank without discriminating evidence asks for engine details',
    (tester) async {
      var refined = false;
      await open(tester, [
        option(1, evidence: false),
        option(2, rank: 2, evidence: false),
      ], onRefine: () => refined = true);
      expect(find.text('Précisez la version du moteur'), findsOneWidget);
      expect(find.text('Référence la plus proche'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('consumption-recommendation-refine')),
      );
      await tester.tap(
        find.byKey(const ValueKey('consumption-recommendation-refine')),
      );
      expect(refined, isTrue);
    },
  );

  testWidgets('proven conflicts are inspectable but cannot be selected', (
    tester,
  ) async {
    Motorisation? selected;
    await open(tester, [
      option(1),
      option(2, eligible: false),
    ], onSelected: (value) => selected = value);
    expect(card(2), findsNothing);
    await revealAll(tester);
    expect(card(2), findsOneWidget);
    expect(
      find.text('Écart avec les caractéristiques connues : cylindres.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Variant 2'));
    await tester.tap(find.text('Variant 2'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(selected, isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('consumption-recommendation-details-2')),
    );
    await tester.tap(
      find.byKey(const ValueKey('consumption-recommendation-details-2')),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SelectableText, 'Source : Source 2'),
      findsOneWidget,
    );
  });

  testWidgets('current reference remains visible outside the best group', (
    tester,
  ) async {
    await open(tester, [
      option(1),
      option(2, rank: 2),
      option(3, rank: 3),
    ], ownedVehicle: vehicle(selectedId: 3));
    expect(card(1), findsOneWidget);
    expect(card(3), findsOneWidget);
    expect(card(2), findsNothing);
    expect(find.text('Référence actuellement sélectionnée'), findsWidgets);
  });

  testWidgets(
    'a saved reference absent from candidates is preserved for inspection',
    (tester) async {
      await open(tester, [
        option(1),
      ], ownedVehicle: vehicle(selectedId: 9, consumption: reference(9)));
      expect(find.text('Référence actuellement sélectionnée'), findsOneWidget);
      expect(find.text('Détails et source'), findsOneWidget);
    },
  );

  testWidgets('all conflicting candidates explain the empty recommendation', (
    tester,
  ) async {
    await open(tester, [
      option(1, eligible: false),
      option(2, eligible: false),
    ]);
    expect(
      find.text(
        'Aucune des références proposées ne correspond aux caractéristiques connues.',
      ),
      findsOneWidget,
    );
    expect(card(1), findsNothing);
    await revealAll(tester);
    expect(card(1), findsOneWidget);
    expect(card(2), findsOneWidget);
  });

  for (final language in ['fr', 'en']) {
    testWidgets(
      'recommendations scroll at 320px with large text in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await open(
          tester,
          [option(1), option(2), option(3), option(4)],
          language: language,
          textScale: 2,
        );
        await revealAll(tester);
        await tester.ensureVisible(card(4));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
