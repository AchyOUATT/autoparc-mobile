import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/garage/data/models/motorisation.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_reference_details.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_reference_candidates.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> reference({String level = 'incomplete'}) => {
    'label': '2,5 l 4 cyl. boîte auto. 6',
    'model_raw': 'Camry Hybrid LE',
    'power_kw': '151.0',
    'model_year': 2013,
    'requested_year': 2014,
    'year_kind': 'model_year',
    'reference_status': 'documented',
    'market': 'CA',
    'method': 'test',
    'combined_l_100km': null,
    'reference_combined_l_100km': '5.7',
    'source': 'Ressources naturelles Canada',
    'cycle': '5-cycle',
    'match': {
      'level': level,
      'reasons': ['model_year_mismatch'],
    },
    'provenance': {
      'resource_url': 'https://example.org/camry.csv',
      'resource_id': 'camry-2013',
      'file_sha256': 'file-checksum',
      'retrieved_at': '2026-10-30',
      'imported_at': '2026-10-31',
    },
  };

  test(
    'legacy numbers are retained for inspection without being an exact rating',
    () {
      final value = VehicleConsumption.fromJson({
        'label': 'Camry',
        'combined_l_100km': '8.2',
        'source': 'NRCan',
        'cycle': '5-cycle',
      });
      expect(value.matchLevel, 'incomplete');
      expect(value.referenceStatus, 'legacy');
      expect(value.primaryCombinedL100km, isNull);
      expect(value.sourceCombinedL100km, 8.2);
      expect(value.verifiedAt, isNull);
    },
  );

  test(
    'catalog preserves variant metadata and the source number when the primary is null',
    () {
      final json = reference(level: 'approximate');
      final value = Motorisation.fromJson({
        ...json,
        'id': 17,
        'engine_l': '2.5',
        'consumption': {
          'combined_l_100km': null,
          'reference_combined_l_100km': '5.7',
        },
        'source': {'label': 'NRCan', 'cycle': '5-cycle'},
      });
      expect(value.consumption.matchLevel, 'approximate');
      expect(value.consumption.sourceModel, 'Camry Hybrid LE');
      expect(value.consumption.powerKw, 151);
      expect(value.consumption.primaryCombinedL100km, isNull);
      expect(value.consumption.sourceCombinedL100km, 5.7);
      expect(value.consumption.modelYear, 2013);
      expect(value.consumption.requestedYear, 2014);
      expect(value.consumption.sourceUri?.host, 'example.org');
    },
  );

  test(
    'unrecognized levels and withdrawn references never expose a primary value',
    () {
      final unknown = VehicleConsumption.fromJson({
        ...reference(level: 'certain'),
        'combined_l_100km': 8.2,
      });
      final withdrawn = VehicleConsumption.fromJson({
        ...reference(level: 'corresponding'),
        'reference_status': 'withdrawn',
        'combined_l_100km': 8.2,
      });
      expect(unknown.primaryCombinedL100km, isNull);
      expect(withdrawn.primaryCombinedL100km, isNull);
    },
  );

  test(
    'empty array metadata and contradictory legacy status remain conservative',
    () {
      final value = VehicleConsumption.fromJson({
        ...reference(level: 'corresponding'),
        'combined_l_100km': 8.2,
        'reference_status': 'legacy',
        'provenance': <dynamic>[],
      });
      expect(value.provenance, isEmpty);
      expect(value.primaryCombinedL100km, isNull);
      final noMatch = VehicleConsumption.fromJson({
        ...reference(),
        'match': <dynamic>[],
      });
      expect(noMatch.matchLevel, 'incomplete');
    },
  );

  test(
    'listing references retain sources separately instead of reducing them to a range',
    () {
      Map<String, dynamic> candidate(
        int id,
        String source,
        String cycle,
        String number,
      ) => {
        ...reference(),
        'id': id,
        'source': {'label': source, 'cycle': cycle},
        'consumption': {
          'combined_l_100km': null,
          'reference_combined_l_100km': number,
        },
      };
      final vehicle = Vehicle.fromJson({
        'id': 1,
        'designation': 'Toyota Camry',
        'registration_status': 'registered',
        'identity': {'brand': 'Toyota', 'model': 'Camry'},
        'commercial': {
          'condition': 'used',
          'status': 'in_stock',
          'availability': 'sale',
        },
        'consumption': {
          'combined_l_100km': '8.5',
          'official': null,
          'references': [
            candidate(1, 'NRCan', '5-cycle', '8.2'),
            candidate(2, 'EEA', 'WLTP', '6.4'),
          ],
        },
      });
      expect(vehicle.officialConsumption, isNull);
      expect(
        vehicle.combinedL100km,
        8.5,
        reason: 'The seller declaration remains separate.',
      );
      expect(vehicle.consumptionReferences.length, 2);
      expect(vehicle.consumptionReferences.map((r) => r.consumption.source), [
        'NRCan',
        'EEA',
      ]);
      expect(
        vehicle.consumptionReferences.every(
          (r) => r.consumption.primaryCombinedL100km == null,
        ),
        isTrue,
      );
    },
  );

  test(
    'source links reject executable schemes and credential-bearing URLs',
    () {
      for (final url in [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'https://user:password@example.org/file',
        '/relative/path',
      ]) {
        final value = VehicleConsumption.fromJson({
          ...reference(),
          'provenance': {'source_url': url},
        });
        expect(value.sourceUri, isNull, reason: url);
      }
    },
  );

  Widget screen(VehicleConsumption value, {String locale = 'fr'}) =>
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConsumptionReferenceSummary(
              reference: value,
              vehicleYear: 2014,
              onChange: () {},
            ),
          ),
        ),
      );

  testWidgets(
    'an approximate year is visible and its number remains a source comparison',
    (tester) async {
      await tester.pumpWidget(
        screen(VehicleConsumption.fromJson(reference(level: 'approximate'))),
      );
      expect(find.text('Référence approchante'), findsOneWidget);
      expect(find.text('Millésime de référence : 2013'), findsOneWidget);
      expect(find.text('Année renseignée : 2014'), findsOneWidget);
      expect(find.textContaining('5,7'), findsNothing);
      await tester.tap(find.text('Détails et source'));
      await tester.pumpAndSettle();
      expect(find.text('Valeur de la source : 5,7 L/100 km'), findsOneWidget);
      expect(find.text('Camry Hybrid LE'), findsOneWidget);
      expect(
        find.text('Correspondance documentaire non vérifiée'),
        findsOneWidget,
      );
      expect(find.text('Import : 2026-10-31'), findsOneWidget);
      expect(find.text('Récupération : 2026-10-30'), findsOneWidget);
      expect(
        find.text('Vérification documentaire : 2026-10-31'),
        findsNothing,
        reason: 'An import date never becomes a verification date.',
      );
    },
  );

  testWidgets(
    'English labels preserve the distinction between registry year and model year',
    (tester) async {
      final value = VehicleConsumption.fromJson({
        ...reference(),
        'year_kind': 'registration_year',
        'market': null,
        'method': 'aggregation',
      });
      await tester.pumpWidget(screen(value, locale: 'en'));
      expect(find.text('Version needs clarification'), findsOneWidget);
      expect(find.text('Registration year: 2013'), findsOneWidget);
      expect(
        find.text('Original specification market unknown'),
        findsOneWidget,
      );
      expect(find.textContaining('Model year'), findsNothing);
      expect(find.textContaining('L/100 km'), findsNothing);
    },
  );

  testWidgets(
    'a corresponding reference keeps its source and match labels separate',
    (tester) async {
      final value = VehicleConsumption.fromJson({
        ...reference(level: 'corresponding'),
        'combined_l_100km': '5.7',
      });
      await tester.pumpWidget(screen(value, locale: 'en'));
      expect(find.text('Reference for this version'), findsOneWidget);
      expect(find.text('Reference: 5.7 L/100 km'), findsOneWidget);
      expect(find.textContaining('Manufacturer'), findsNothing);
    },
  );
  testWidgets(
    'listing comparison exposes distinct references without a combined range',
    (tester) async {
      final first = VehicleConsumption.fromJson({
        ...reference(),
        'source': 'NRCan',
      });
      final second = VehicleConsumption.fromJson({
        ...reference(),
        'source': 'EEA',
        'cycle': 'WLTP',
        'reference_combined_l_100km': 6.4,
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConsumptionReferenceCandidates(
                references: [
                  Motorisation(id: 1, label: first.label, modelYear: 2013, consumption: first),
                  Motorisation(id: 2, label: second.label, modelYear: 2013, consumption: second),
                ],
                vehicleYear: 2014,
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Comparer les références de consommation'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('NRCan'), findsOneWidget);
      expect(find.textContaining('EEA'), findsOneWidget);
      expect(find.textContaining('5,7 à 6,4'), findsNothing);
      expect(
        find.textContaining('Aucune n’est attribuée à cette annonce.'),
        findsOneWidget,
      );
    },
  );
}
