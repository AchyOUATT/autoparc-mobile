import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/garage/data/models/motorisation.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_recommendation_card.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_reference_candidates.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> candidateJson(
  int id, {
  int? rank = 1,
  bool evidence = true,
  bool eligible = true,
  String source = 'Official source',
  String cycle = 'WLTP',
  double consumption = 8.2,
  String status = 'documented',
}) => {
  'id': id,
  'label': 'Engine $id',
  'model_raw': 'Variant $id',
  'model_year': 2018,
  'year_kind': 'model_year',
  'market': 'CA',
  'engine_l': 1.8,
  'cylinders': 4,
  'reference_status': status,
  'source': {'code': 'custom', 'label': source, 'cycle': cycle},
  'consumption': {
    'combined_l_100km': null,
    'reference_combined_l_100km': consumption,
  },
  'match': {
    'level': 'incomplete',
    'reasons': ['configuration_unverified'],
  },
  if (rank != null)
    'recommendation': {
      'rank': rank,
      'matched_criteria': evidence ? ['engine_displacement_cc'] : <String>[],
      'missing_criteria': ['model_year'],
      'has_discriminating_match': evidence,
      'eligible': eligible,
      'conflicting_criteria': eligible ? <String>[] : ['cylinders'],
    },
};

Motorisation candidate(
  int id, {
  int? rank = 1,
  bool evidence = true,
  bool eligible = true,
}) => Motorisation.fromJson(
  candidateJson(id, rank: rank, evidence: evidence, eligible: eligible),
);

Widget page(
  List<Motorisation> references, {
  String locale = 'fr',
  double scale = 1,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: ConsumptionReferenceCandidates(
        references: references,
        vehicleYear: 2017,
      ),
    ),
  ),
);

Finder card(int id) =>
    find.byKey(ValueKey('consumption-recommendation-option-$id'));
Finder get toggle => find.byKey(const ValueKey('consumption-listing-show-all'));

Future<void> showAll(WidgetTester tester) async {
  await tester.ensureVisible(toggle);
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'vehicle parsing retains ranks and source values without replacing seller declaration',
    () {
      final vehicle = Vehicle.fromJson({
        'id': 1,
        'designation': 'Toyota Corolla',
        'registration_status': 'registered',
        'identity': {'brand': 'Toyota', 'model': 'Corolla'},
        'commercial': {
          'condition': 'used',
          'status': 'in_stock',
          'availability': 'sale',
        },
        'consumption': {
          'combined_l_100km': 12.3,
          'official': null,
          'references': [
            candidateJson(1),
            candidateJson(2, rank: 2, consumption: 4.0),
          ],
        },
      });
      expect(vehicle.combinedL100km, 12.3);
      expect(vehicle.officialConsumption, isNull);
      expect(vehicle.consumptionReferences.first.recommendationRank, 1);
      expect(vehicle.consumptionReferences.last.recommendationRank, 2);
      expect(
        vehicle.consumptionReferences.first.hasDiscriminatingMatch,
        isTrue,
      );
      expect(
        vehicle.consumptionReferences.first.consumption.sourceCombinedL100km,
        8.2,
      );
      expect(
        vehicle.consumptionReferences.last.consumption.sourceCombinedL100km,
        4,
      );
      expect(
        vehicle.consumptionReferences.every(
          (m) => m.consumption.primaryCombinedL100km == null,
        ),
        isTrue,
      );
    },
  );

  for (final locale in ['fr', 'en']) {
    testWidgets(
      'listing displays the closest reference immediately and remains read-only in $locale',
      (tester) async {
        await tester.pumpWidget(
          page([
            Motorisation.fromJson(candidateJson(2, rank: 2, consumption: 4.0)),
            Motorisation.fromJson(candidateJson(1)),
          ], locale: locale),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            locale == 'fr' ? 'Référence la plus proche' : 'Closest reference',
          ),
          findsOneWidget,
        );
        expect(card(1), findsOneWidget);
        expect(
          card(2),
          findsNothing,
          reason: 'A lower consumption number cannot outrank the server match.',
        );
        expect(
          find.textContaining(
            locale == 'fr' ? 'Valeur de la source : 8,2' : 'Source value: 8.2',
          ),
          findsOneWidget,
        );
        final displayed = tester.widget<ConsumptionRecommendationCard>(
          find.byType(ConsumptionRecommendationCard),
        );
        expect(displayed.onSelect, isNull);
        expect(
          find.byKey(const ValueKey('consumption-recommendation-refine')),
          findsNothing,
        );
        await tester.tap(find.text('Variant 1'));
        await tester.pumpAndSettle();
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: 'Read-only tap opens provenance, never a selection workflow.',
        );
        expect(
          find.widgetWithText(
            SelectableText,
            locale == 'fr'
                ? 'Source : Official source'
                : 'Source: Official source',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'listing keeps all equal ranks, preserves order and reveals remaining sources',
    (tester) async {
      await tester.pumpWidget(
        page([
          for (final id in [31, 2, 44, 8, 90, 1]) candidate(id),
          candidate(99, rank: 2),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Références à départager'), findsOneWidget);
      expect(
        find.text(
          '6 références sont aussi proches. Les trois premières sont affichées.',
        ),
        findsOneWidget,
      );
      for (final id in [31, 2, 44]) {
        expect(card(id), findsOneWidget);
      }
      for (final id in [8, 90, 1, 99]) {
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
      await showAll(tester);
      for (final id in [8, 90, 1, 99]) {
        expect(card(id), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sources and test cycles remain distinct instead of becoming one range',
    (tester) async {
      await tester.pumpWidget(
        page([
          Motorisation.fromJson(
            candidateJson(
              1,
              source: 'Official A',
              cycle: 'WLTP',
              consumption: 8.2,
            ),
          ),
          Motorisation.fromJson(
            candidateJson(
              2,
              source: 'Official B',
              cycle: 'Five-cycle',
              consumption: 6.4,
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(card(1), findsOneWidget);
      expect(card(2), findsOneWidget);
      expect(find.textContaining('Official A'), findsOneWidget);
      expect(find.textContaining('Official B'), findsOneWidget);
      expect(find.textContaining('Five-cycle'), findsOneWidget);
      expect(find.textContaining('8,2 à 6,4'), findsNothing);
      expect(
        find.textContaining('Aucune n’est attribuée à cette annonce.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'conflicting and withdrawn references stay outside shortlist but inspectable',
    (tester) async {
      await tester.pumpWidget(
        page([
          candidate(1, eligible: false),
          Motorisation.fromJson(candidateJson(2, status: 'withdrawn')),
        ]),
      );
      await tester.pumpAndSettle();
      expect(card(1), findsNothing);
      expect(card(2), findsNothing);
      expect(find.text('Référence la plus proche'), findsNothing);
      await showAll(tester);
      expect(card(1), findsOneWidget);
      expect(card(2), findsOneWidget);
      for (final widget in tester.widgetList<ConsumptionRecommendationCard>(
        find.byType(ConsumptionRecommendationCard),
      )) {
        expect(widget.onSelect, isNull);
      }
      await tester.ensureVisible(find.text('Variant 1'));
      await tester.tap(find.text('Variant 1'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy and uninformative rankings do not pretend to identify a closest version',
    (tester) async {
      await tester.pumpWidget(
        page([candidate(1, rank: null), candidate(2, rank: null)]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Précisez la version du moteur'), findsOneWidget);
      expect(find.text('Référence la plus proche'), findsNothing);
      expect(card(1), findsOneWidget);
      expect(card(2), findsOneWidget);
      await tester.pumpWidget(
        page([
          candidate(3, evidence: false),
          candidate(4, rank: 2, evidence: false),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Précisez la version du moteur'), findsOneWidget);
      expect(find.text('Référence la plus proche'), findsNothing);
    },
  );

  for (final locale in ['fr', 'en']) {
    testWidgets(
      'listing references stay readable at 320px and text x2 in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          page(
            [candidate(1), candidate(2), candidate(3), candidate(4, rank: 2)],
            locale: locale,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(card(3));
        await showAll(tester);
        await tester.ensureVisible(card(4));
        await tester.pumpAndSettle();
        expect(card(4), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
