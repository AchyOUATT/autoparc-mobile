import 'package:auto/core/api/api_client.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/motorisation.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_recommendations.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_tile.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> vehicleJson() => {
  'id': 1,
  'designation': 'Toyota Corolla',
  'brand_id': 1,
  'vehicle_model_id': 2,
  'year': 2017,
  'model_year': 2018,
  'specification_market': 'EU',
  'identity': <String, dynamic>{'model': 'Corolla'},
  'compatibility_ready': false,
};

Map<String, dynamic> candidateJson() => {
  'id': 31,
  'label': '1.8 L',
  'model_year': 2018,
  'engine_l': 1.8,
  'cylinders': 4,
  'source': {'code': 'eea', 'label': 'EEA', 'cycle': 'WLTP'},
  'reference_status': 'documented',
  'year_kind': 'model_year',
  'consumption': {'reference_combined_l_100km': 5.5},
  'match': {
    'level': 'incomplete',
    'reasons': ['configuration_unverified'],
  },
  'recommendation': {
    'rank': 1,
    'matched_criteria': ['engine_displacement_l'],
    'missing_criteria': ['engine_code'],
    'has_discriminating_match': true,
    'eligible': true,
    'conflicting_criteria': <String>[],
  },
};

class _Api extends ApiClient {
  Map<String, dynamic>? params;
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    this.params = params;
    return {
      'data': [candidateJson()],
    };
  }
}

class _Repo implements GarageRepository {
  final calls = <Map<String, dynamic>>[];
  @override
  Future<List<Motorisation>> motorisations({
    required int vehicleModelId,
    int? year,
    int? engineTypeId,
    int? drivetrainId,
    int? trimId,
    String? engineCode,
    int? modelYear,
    String? specificationMarket,
    int? engineDisplacementCc,
    double? engineDisplacementL,
    int? cylinders,
    int? powerHp,
  }) async {
    calls.add({
      'cc': engineDisplacementCc,
      'litres': engineDisplacementL,
      'model_year': modelYear,
      'year': year,
      'market': specificationMarket,
    });
    return [Motorisation.fromJson(candidateJson())];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Garage extends GarageNotifier {
  final saved = <Map<String, dynamic>>[];
  @override
  Future<List<OwnedVehicle>> build() async => [
    OwnedVehicle.fromJson(vehicleJson()),
  ];
  @override
  Future<String?> updateVehicle(int id, Map<String, dynamic> payload) async {
    saved.add(payload);
    state = AsyncData([
      OwnedVehicle.fromJson({...vehicleJson(), ...payload}),
    ]);
    return null;
  }
}

void main() {
  test(
    'server ranking metadata stays separate from a confirmed consumption',
    () {
      final candidate = Motorisation.fromJson(candidateJson());
      expect(candidate.recommendationRank, 1);
      expect(candidate.matchedCriteria, ['engine_displacement_l']);
      expect(candidate.missingCriteria, ['engine_code']);
      expect(candidate.hasDiscriminatingMatch, isTrue);
      expect(candidate.recommendationEligible, isTrue);
      expect(candidate.consumption.primaryCombinedL100km, isNull);
      final legacy = Motorisation.fromJson({'id': 2, 'label': 'Legacy'});
      expect(legacy.recommendationRank, isNull);
      expect(legacy.hasDiscriminatingMatch, isFalse);
      final conflict = Motorisation.fromJson({
        ...candidateJson(),
        'recommendation': {
          'rank': 2,
          'eligible': false,
          'conflicting_criteria': ['cylinders'],
        },
      });
      expect(conflict.recommendationEligible, isFalse);
      expect(conflict.conflictingCriteria, ['cylinders']);
    },
  );

  test(
    'query forwards explicit model year independently from manufacturing year and engine data',
    () async {
      final api = _Api();
      final repo = GarageRepository(api);
      final options = await repo.motorisations(
        vehicleModelId: 2,
        year: 2017,
        modelYear: 2018,
        specificationMarket: 'EU',
        engineDisplacementCc: 1798,
        engineDisplacementL: 1.8,
        cylinders: 4,
        powerHp: 140,
      );
      expect(api.params!['year'], 2017);
      expect(api.params!['model_year'], 2018);
      expect(api.params!['specification_market'], 'EU');
      expect(api.params!['engine_displacement_cc'], 1798);
      expect(api.params!['engine_displacement_l'], 1.8);
      expect(api.params!['cylinders'], 4);
      expect(api.params!['power_hp'], 140);
      expect(options.single.recommendationRank, 1);
    },
  );

  testWidgets(
    'refining engine details refreshes recommendations without selecting automatically',
    (tester) async {
      final repo = _Repo();
      final garage = _Garage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garageRepositoryProvider.overrideWithValue(repo),
            garageProvider.overrideWith(() => garage),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final vehicles = ref.watch(garageProvider).valueOrNull;
                  return TextButton(
                    onPressed: vehicles?.isNotEmpty == true
                        ? () =>
                              choisirMotorisation(context, ref, vehicles!.first)
                        : null,
                    child: const Text('Open recommendations'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open recommendations'));
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(1));
      expect(garage.saved, isEmpty);
      tester
          .widget<ConsumptionRecommendationsDialog>(
            find.byType(ConsumptionRecommendationsDialog),
          )
          .onRefine!();
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('engine-cc'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '1798');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(2));
      expect(repo.calls.last['cc'], 1798);
      expect(repo.calls.last['model_year'], 2018);
      expect(repo.calls.last['year'], 2017);
      expect(repo.calls.last['market'], 'EU');
      expect(garage.saved, hasLength(1));
      expect(garage.saved.single.containsKey('motorisation_id'), isFalse);
      expect(find.byType(ConsumptionRecommendationsDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
