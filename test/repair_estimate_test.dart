import 'package:auto/features/vehicles/data/models/fault_declaration.dart';
import 'package:auto/features/vehicles/data/models/repair_estimate.dart';
import 'package:auto/features/vehicles/presentation/widgets/declared_faults_section.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _estimate({
  int min = 35000,
  int max = 50000,
  String source = 'workshop',
  String date = '2026-05-14',
  bool stale = true,
}) => {
  'cost_min': min,
  'cost_max': max,
  'currency': 'XOF',
  'source': source,
  'estimated_at': date,
  'is_stale': stale,
};

Map<String, dynamic> _fault({
  String title = 'Pare-chocs arrière rayé',
  String necessity = 'optional',
  Map<String, dynamic>? estimate,
  String status = 'declared',
}) => {
  'id': 1,
  'category': 'bodywork',
  'title': title,
  'description': 'Reprise esthétique facultative.',
  'severity': 'minor',
  'status': status,
  'is_open': status != 'repaired' && status != 'wont_fix',
  'affects_drivability': false,
  'is_safety_critical': false,
  'disclosed_to_buyer': true,
  'editable': true,
  'repair_necessity': necessity,
  'repair_estimate': ?estimate,
};

void main() {
  test('old payloads without estimate fields still parse', () {
    final fault = DeclaredVehicleFault.fromJson({
      'category': 'braking',
      'title': 'Plaquettes usées',
      'severity': 'moderate',
      'status': 'declared',
    });
    expect(fault.repairEstimate, isNull);
    expect(fault.repairNecessity, 'necessary');
    expect(fault.publishedQuote, isNull);
    expect(fault.isValid, isTrue);
  });

  test('a complete range is kept and serialized without inventing bounds', () {
    final fault = DeclaredVehicleFault.fromJson(
      _fault(estimate: _estimate(stale: false, date: '2026-11-01')),
    );
    expect(fault.repairEstimate, isNotNull);
    expect(fault.repairEstimate!.costMin, 35000);
    expect(fault.repairEstimate!.costMax, 50000);
    expect(fault.repairEstimate!.source, 'workshop');
    expect(fault.toJson()['repair_estimate'], {
      'cost_min': 35000,
      'cost_max': 50000,
      'source': 'workshop',
      'estimated_at': '2026-11-01',
    });
    expect(fault.toJson()['repair_necessity'], 'optional');
  });

  test('an explicit empty estimate serializes as null, never 0 F CFA', () {
    final payload = DeclaredVehicleFault.fromJson(_fault()).toJson();
    expect(payload['repair_estimate'], isNull);
    expect(
      formatCfaRange(35000, 50000, locale: 'fr'),
      isNot(equals('0 F CFA')),
    );
  });

  test('an incomplete or inverted range is ignored, not forced', () {
    final inverted = DeclaredVehicleFault.fromJson(
      _fault(estimate: _estimate(min: 80000, max: 10000)),
    );
    expect(inverted.repairEstimate, isNull);
    final incomplete = DeclaredVehicleFault.fromJson(
      _fault(estimate: {'cost_min': 35000, 'source': 'seller'}),
    );
    expect(incomplete.repairEstimate, isNull);
  });

  test('the budget DTO accepts a partial public summary', () {
    final declaration = FaultDeclaration.fromJson({
      'state': 'has_faults',
      'faults': [
        _fault(
          title: 'Freins à réparer',
          necessity: 'necessary',
          estimate: _estimate(min: 45000, max: 65000, stale: false),
        ),
        _fault(title: 'Bruit moteur', necessity: 'necessary', estimate: null),
      ],
      'repair_budget': {
        'status': 'partial',
        'cost_min': 45000,
        'cost_max': 65000,
        'currency': 'XOF',
        'estimated_count': 1,
        'unestimated_count': 1,
        'optional': [
          {
            'id': 9,
            'title': 'Pare-chocs arrière rayé',
            'repair_estimate': _estimate(stale: false),
          },
        ],
      },
    });
    expect(declaration.repairBudget!.status, 'partial');
    expect(declaration.repairBudget!.optional, hasLength(1));
    expect(declaration.state, 'has_faults');
  });

  testWidgets(
    'the public card shows the range, stale flag, source, and never 0 F CFA',
    (tester) async {
      final declaration = FaultDeclaration.fromJson({
        'state': 'has_faults',
        'declared_at': '2026-11-14T10:00:00Z',
        'faults': [
          _fault(estimate: _estimate()),
          {
            ..._fault(title: 'Bruit moteur', necessity: 'necessary'),
            'description': 'Cause inconnue.',
          },
        ],
        'unresolved_count': 2,
        'repair_budget': {
          'status': 'to_estimate',
          'estimated_count': 0,
          'unestimated_count': 1,
          'optional': [
            {
              'title': 'Pare-chocs arrière rayé',
              'repair_estimate': _estimate(stale: false, date: '2026-11-01'),
            },
          ],
        },
      });
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeclaredFaultsSection(declaration: declaration),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l.repairBudgetTitle), findsOneWidget);
      expect(find.text(l.repairBudgetToEstimate), findsOneWidget);
      expect(find.text(l.repairBudgetOptionalTitle), findsOneWidget);
      expect(find.text(l.repairEstimateStale), findsOneWidget);
      expect(find.text(l.repairEstimateToEstimate), findsWidgets);
      expect(find.text(l.repairEstimateNecessary), findsOneWidget);
      expect(find.text(l.repairEstimateOptional), findsOneWidget);
      expect(find.textContaining(l.repairEstimateSourceWorkshop), findsWidgets);
      expect(find.text('0 F CFA'), findsNothing);
      expect(find.textContaining('35'), findsWidgets);
    },
  );

  testWidgets('a partial necessary budget uses the remaining plural', (
    tester,
  ) async {
    final declaration = FaultDeclaration.fromJson({
      'state': 'has_faults',
      'faults': [
        _fault(
          title: 'Freins à réparer',
          necessity: 'necessary',
          estimate: _estimate(
            min: 45000,
            max: 65000,
            stale: false,
            date: '2026-11-01',
          ),
        ),
      ],
      'repair_budget': {
        'status': 'partial',
        'cost_min': 45000,
        'cost_max': 65000,
        'estimated_count': 1,
        'unestimated_count': 1,
        'optional': <dynamic>[],
      },
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeclaredFaultsSection(declaration: declaration),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('pour les travaux chiffrés'), findsOneWidget);
    expect(
      find.textContaining('1 réparation reste à chiffrer'),
      findsOneWidget,
    );
    expect(find.text('0 F CFA'), findsNothing);
  });
  testWidgets(
    'optional-only work shows optional repairs and never a missing budget',
    (tester) async {
      final declaration = FaultDeclaration.fromJson({
        'state': 'has_faults',
        'faults': [
          _fault(estimate: _estimate(stale: false, date: '2026-11-01')),
        ],
        'repair_budget': {
          'status': 'none',
          'estimated_count': 0,
          'unestimated_count': 0,
          'optional': [
            {
              'title': 'Pare-chocs arrière rayé',
              'repair_estimate': _estimate(stale: false, date: '2026-11-01'),
            },
          ],
        },
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeclaredFaultsSection(declaration: declaration),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l.repairBudgetOptionalTitle), findsOneWidget);
      expect(find.text(l.repairBudgetToEstimate), findsNothing);
      expect(find.text(l.repairBudgetTitle), findsNothing);
      expect(find.text('0 F CFA'), findsNothing);
    },
  );

  testWidgets('a complete necessary budget shows the range only', (
    tester,
  ) async {
    final declaration = FaultDeclaration.fromJson({
      'state': 'has_faults',
      'faults': [
        _fault(
          title: 'Freins à réparer',
          necessity: 'necessary',
          estimate: _estimate(
            min: 45000,
            max: 65000,
            stale: false,
            date: '2026-11-01',
          ),
        ),
      ],
      'repair_budget': {
        'status': 'complete',
        'cost_min': 45000,
        'cost_max': 65000,
        'estimated_count': 1,
        'unestimated_count': 0,
        'optional': <dynamic>[],
      },
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeclaredFaultsSection(declaration: declaration),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l.repairBudgetTitle), findsOneWidget);
    expect(find.text(l.repairBudgetToEstimate), findsNothing);
    expect(find.textContaining('45'), findsWidgets);
    expect(find.text('0 F CFA'), findsNothing);
  });
}
