import 'dart:async';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/inspections/data/staff_inspection.dart';
import 'package:auto/features/inspections/data/staff_inspection_repository.dart';
import 'package:auto/features/inspections/presentation/staff_inspection_form.dart';
import 'package:auto/features/inspections/presentation/staff_inspection_widgets.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _summary({String result = 'clear', String? until}) => {
  'id': 12,
  'inspected_at': '2026-10-25T09:00:00Z',
  'mileage_km': 85000,
  'result': result,
  'checked_count': 1,
  'attention_count': result == 'attention' ? 1 : 0,
  'blocking_count': result == 'blocked' ? 1 : 0,
  'valid_until': until,
};

Map<String, dynamic> _report({
  String result = 'clear',
  String state = 'active',
  String? until,
}) => {
  ..._summary(result: result, until: until),
  'source': 'vehicle',
  'source_id': 4,
  'state': state,
  'summary': 'Contrôle sur pont effectué.',
  'items': [
    {
      'label': 'Freinage',
      'status': result == 'clear'
          ? 'ok'
          : result == 'blocked'
          ? 'blocking'
          : 'attention',
      'note': 'Plaquettes à remplacer.',
    },
    {'label': 'Climatisation', 'status': 'not_checked'},
  ],
  // Staff identity is intentionally not part of the DTO/public UI.
  'inspector_name': 'PRIVATE STAFF NAME',
};

class _Api implements ApiClient {
  final reads = <({String path, Map<String, dynamic>? params})>[];
  final writes = <({String path, Map<String, dynamic>? data})>[];
  final historyReports = <Map<String, dynamic>>[];
  Object? publicError;
  Object? historyError;
  Object? createError;
  int lastPage = 1;
  Completer<Map<String, dynamic>>? pendingCreate;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    reads.add((path: path, params: params));
    if (path.startsWith('/catalog/')) {
      if (publicError != null) throw publicError!;
      return {'data': _report(result: 'attention')};
    }
    if (historyError != null) throw historyError!;
    return {
      'data': historyReports,
      'meta': {'current_page': params?['page'] ?? 1, 'last_page': lastPage},
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    writes.add((path: path, data: data));
    if (path.endsWith('/withdraw')) {
      final id = int.parse(path.split('/')[2]);
      final existing = historyReports.firstWhere(
        (report) => report['id'] == id,
      );
      existing['state'] = 'withdrawn';
      existing['withdrawal_reason'] = data!['reason'];
      return {'data': existing};
    }
    if (createError != null) throw createError!;
    if (pendingCreate != null) return pendingCreate!.future;
    final items = (data!['items'] as List).cast<Map<String, dynamic>>();
    final attention = items
        .where((item) => item['status'] == 'attention')
        .length;
    final blocking = items.where((item) => item['status'] == 'blocking').length;
    for (final report in historyReports) {
      if (report['state'] == 'active') report['state'] = 'superseded';
    }
    final report = <String, dynamic>{
      ...data,
      'id': 13,
      'source': path.split('/')[2],
      'source_id': int.parse(path.split('/')[3]),
      'state': 'active',
      'checked_count': items
          .where((item) => item['status'] != 'not_checked')
          .length,
      'attention_count': attention,
      'blocking_count': blocking,
      'result': blocking > 0
          ? 'blocked'
          : attention > 0
          ? 'attention'
          : 'clear',
    };
    historyReports.insert(0, report);
    return {'data': report};
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

Future<void> _show(
  WidgetTester tester,
  Widget child,
  _Api api, {
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(820, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'summary parsing fails closed on absent, malformed or contradictory data',
    () {
      expect(StaffInspectionSummary.parse(null), isNull);
      expect(StaffInspectionSummary.parse('checked'), isNull);
      for (final json in [
        {..._summary(), 'id': 'p12'},
        {..._summary(), 'checked_count': 0},
        {..._summary(), 'mileage_km': -1},
        {..._summary(), 'result': 'approved'},
        {..._summary(), 'inspected_at': 'unknown'},
        {..._summary(), 'attention_count': 1},
        {..._summary(), 'valid_until': 'unknown'},
        {..._summary(), 'valid_until': '2026-10-24T00:00:00Z'},
      ]) {
        expect(StaffInspectionSummary.parse(json), isNull, reason: '$json');
      }
      final valid = StaffInspectionSummary.parse(_summary(result: 'blocked'))!;
      expect(valid.blockingCount, 1);
      expect(valid.hasFindings, isTrue);
      expect(valid.isCurrent(DateTime(2050)), isTrue); // No invented expiry.
      final expiring = StaffInspectionSummary.parse(
        _summary(until: '2026-11-02T10:00:00Z'),
      )!;
      expect(expiring.isCurrent(DateTime.utc(2026, 11, 2, 10)), isFalse);
    },
  );

  test(
    'report preserves all points and refuses inconsistent clear findings',
    () {
      final report = StaffInspectionReport.fromJson(
        _report(result: 'attention'),
      );
      expect(report.inspection.attentionCount, 1);
      expect(report.items.last.status, 'not_checked');
      expect(report.sourceId, 4);
      expect(report.canWithdraw, isTrue);
      expect(
        StaffInspectionReport.fromJson(_report(state: 'outdated')).canWithdraw,
        isTrue,
      );
      expect(
        StaffInspectionReport.fromJson(_report(state: 'withdrawn')).canWithdraw,
        isFalse,
      );
      expect(
        StaffInspectionReport.fromJson(
          _report(state: 'superseded'),
        ).canWithdraw,
        isFalse,
      );
      expect(
        () => StaffInspectionReport.fromJson({
          ..._report(result: 'attention'),
          ..._summary(),
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'repository uses distinct public and staff routes and paginated history',
    () async {
      final api = _Api()
        ..historyReports.add(_report())
        ..lastPage = 3;
      final repo = StaffInspectionRepository(api);
      expect((await repo.report(12)).inspection.id, 12);
      final page = await repo.history('vehicle', 4, page: 2);
      expect(page.nextPage, 3);
      expect(api.reads.first.path, '/catalog/vehicle-inspections/12');
      expect(api.reads.last.path, '/vehicle-inspections/vehicle/4');
      expect(api.reads.last.params, {'page': 2});
      await repo.withdraw(12, '  Contrôle à refaire  ');
      expect(api.writes.last.path, '/vehicle-inspections/12/withdraw');
      expect(api.writes.last.data, {'reason': 'Contrôle à refaire'});
      await expectLater(repo.history('../catalog', 4), throwsArgumentError);
      expect(api.reads, hasLength(2));
    },
  );

  testWidgets(
    'badges show exact label plus findings in both languages and fit narrow intrinsic cards',
    (tester) async {
      final api = _Api();
      for (final locale in ['fr', 'en']) {
        await _show(
          tester,
          SizedBox(
            width: 150,
            child: IntrinsicHeight(
              child: StaffInspectionBadge(
                inspection: StaffInspectionSummary.fromJson(
                  _summary(result: 'blocked'),
                ),
              ),
            ),
          ),
          api,
          locale: locale,
        );
        expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
        expect(
          find.text(
            locale == 'fr' ? 'Inspecté par AutoParc' : 'Inspected by AutoParc',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            locale == 'fr'
                ? 'Défauts bloquants signalés'
                : 'Blocking issues reported',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await _show(
        tester,
        StaffInspectionBadge(
          inspection: StaffInspectionSummary.fromJson(
            _summary(until: '2026-10-26T00:00:00Z'),
          ),
        ),
        api,
      );
      expect(find.byIcon(Icons.verified_user_outlined), findsNothing);
    },
  );

  testWidgets(
    'public report opens on tap, shows notes and unchecked points, with no inspector identity',
    (tester) async {
      final api = _Api();
      await _show(
        tester,
        StaffInspectionBadge(
          inspection: StaffInspectionSummary.fromJson(
            _summary(result: 'attention'),
          ),
        ),
        api,
      );
      await _tap(tester, find.text('Inspected by AutoParc'));
      expect(api.reads.single.path, '/catalog/vehicle-inspections/12');
      expect(find.text('Inspection report'), findsOneWidget);
      expect(find.text('Points needing attention'), findsWidgets);
      expect(find.text('Plaquettes à remplacer.'), findsOneWidget);
      expect(find.text('Not checked'), findsOneWidget);
      expect(find.text('1 point checked'), findsOneWidget);
      expect(find.textContaining('PRIVATE STAFF NAME'), findsNothing);
    },
  );

  testWidgets(
    'unavailable public report gives localized recovery and can retry',
    (tester) async {
      final api = _Api()
        ..publicError = const ApiException(
          statusCode: 404,
          message: 'not found',
        );
      await _show(
        tester,
        StaffInspectionBadge(
          inspection: StaffInspectionSummary.fromJson(_summary()),
        ),
        api,
      );
      await _tap(tester, find.text('Inspected by AutoParc'));
      expect(
        find.text(
          'This report is no longer available. Refresh the vehicle details.',
        ),
        findsOneWidget,
      );
      api.publicError = null;
      await _tap(tester, find.text('Retry'));
      expect(api.reads, hasLength(2));
      expect(find.text('Freinage'), findsOneWidget);
    },
  );

  testWidgets(
    'public section never fetches staff history or renders staff actions',
    (tester) async {
      final api = _Api();
      await _show(
        tester,
        const StaffInspectionSection(
          source: 'private_listing',
          sourceId: 4,
          uninspectedLabel: 'Not inspected',
        ),
        api,
      );
      expect(find.text('Not inspected'), findsOneWidget);
      expect(find.byKey(const ValueKey('inspection-manage')), findsNothing);
      expect(find.text('Inspection history'), findsNothing);
      expect(api.reads, isEmpty);
    },
  );

  testWidgets(
    'staff reads pending target report from authenticated history and can withdraw an outdated report',
    (tester) async {
      final api = _Api()..historyReports.add(_report(state: 'outdated'));
      var changes = 0;
      await _show(
        tester,
        StaffInspectionSection(
          source: 'vehicle',
          sourceId: 4,
          canManage: true,
          uninspectedLabel: 'Not inspected',
          onChanged: () => changes++,
        ),
        api,
      );
      expect(find.text('Not inspected'), findsOneWidget);
      expect(find.byType(StaffInspectionBadge), findsNothing);
      await _tap(tester, find.text('Inspection history'));
      await _tap(tester, find.text('Inactive inspection'));
      expect(find.text('Inspection report'), findsOneWidget);
      expect(
        api.reads.every((read) => !read.path.startsWith('/catalog/')),
        isTrue,
      );
      await _tap(tester, find.text('Close'));
      await _tap(tester, find.byTooltip('Withdraw inspection'));
      await _tap(tester, find.text('Withdraw').last);
      expect(find.text('Enter a reason for withdrawal.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('inspection-withdraw-reason')),
        'Contrôle devenu caduc',
      );
      await _tap(tester, find.text('Withdraw').last);
      expect(api.writes.single.data, {'reason': 'Contrôle devenu caduc'});
      expect(changes, 1);
      expect(find.byTooltip('Withdraw inspection'), findsNothing);
      expect(find.text('Not inspected'), findsOneWidget);
    },
  );

  testWidgets(
    'new inspection requires physical confirmation and a checked point, then actually saves',
    (tester) async {
      final api = _Api();
      var changes = 0;
      await _show(
        tester,
        StaffInspectionSection(
          source: 'private_listing',
          sourceId: 4,
          canManage: true,
          uninspectedLabel: 'Not inspected',
          onChanged: () => changes++,
        ),
        api,
      );
      await _tap(tester, find.byKey(const ValueKey('inspection-manage')));
      await tester.enterText(
        find.byKey(const ValueKey('inspection-mileage')),
        '85000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inspection-summary')),
        'Contrôle physique effectué.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inspection-point-label-0')),
        'Freinage',
      );
      await _tap(tester, find.byKey(const ValueKey('inspection-save')));
      expect(
        find.text('Confirm that the vehicle was physically inspected.'),
        findsOneWidget,
      );
      expect(api.writes, isEmpty);
      await _tap(tester, find.byKey(const ValueKey('inspection-confirmation')));
      await _tap(tester, find.byKey(const ValueKey('inspection-save')));
      expect(
        find.text('Check at least one point before saving the inspection.'),
        findsOneWidget,
      );
      expect(api.writes, isEmpty);
      await _tap(
        tester,
        find.byKey(const ValueKey('inspection-point-status-0')),
      );
      await _tap(tester, find.text('Needs attention').last);
      await tester.enterText(
        find.byKey(const ValueKey('inspection-point-note-0')),
        'Plaquettes à remplacer.',
      );
      await _tap(tester, find.byKey(const ValueKey('inspection-save')));
      expect(api.writes.single.path, '/vehicle-inspections/private_listing/4');
      expect(api.writes.single.data!['confirmed'], isTrue);
      expect(api.writes.single.data!['valid_until'], isNull);
      expect(api.writes.single.data!['mileage_km'], 85000);
      expect(changes, 1);
      expect(find.byType(StaffInspectionForm), findsNothing);
      expect(find.text('Not inspected'), findsNothing);
      expect(find.text('Inspected by AutoParc'), findsOneWidget);
      expect(find.text('Points needing attention'), findsOneWidget);
      // The just-created, non-public target opens its authenticated report.
      await _tap(tester, find.text('Inspected by AutoParc'));
      expect(find.text('Plaquettes à remplacer.'), findsOneWidget);
      expect(
        api.reads.every((read) => !read.path.startsWith('/catalog/')),
        isTrue,
      );
      await _tap(tester, find.text('Close'));
      await _tap(tester, find.text('Inspection history'));
      await _tap(tester, find.byTooltip('Withdraw inspection'));
      await tester.enterText(
        find.byKey(const ValueKey('inspection-withdraw-reason')),
        'Nouvelle anomalie constatée',
      );
      await _tap(tester, find.text('Withdraw').last);
      expect(changes, 2);
      expect(find.text('Inspected by AutoParc'), findsNothing);
      expect(find.text('Not inspected'), findsOneWidget);
    },
  );

  testWidgets(
    'save errors preserve the form and allow retry without a second confirmation',
    (tester) async {
      final api = _Api()
        ..createError = const ApiException(
          statusCode: 503,
          message: 'Temporary failure',
        );
      await _show(
        tester,
        const StaffInspectionSection(
          source: 'vehicle',
          sourceId: 4,
          canManage: true,
        ),
        api,
      );
      await _tap(tester, find.byKey(const ValueKey('inspection-manage')));
      await tester.enterText(
        find.byKey(const ValueKey('inspection-mileage')),
        '85000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inspection-summary')),
        'Contrôle physique effectué.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inspection-point-label-0')),
        'Freinage',
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('inspection-point-status-0')),
      );
      await _tap(tester, find.text('Checked: no issue found').last);
      await _tap(tester, find.byKey(const ValueKey('inspection-confirmation')));
      await _tap(tester, find.byKey(const ValueKey('inspection-save')));
      expect(api.writes, hasLength(1));
      expect(find.byType(StaffInspectionForm), findsOneWidget);
      expect(find.text('Contrôle physique effectué.'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('inspection-confirmation')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('inspection-save')))
            .onPressed,
        isNotNull,
      );
      api.createError = null;
      api.pendingCreate = Completer<Map<String, dynamic>>();
      final save = find.byKey(const ValueKey('inspection-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(api.writes, hasLength(2));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.tap(save);
      await tester.pump();
      expect(api.writes, hasLength(2));
      api.historyReports.add(_report());
      api.pendingCreate!.complete({'data': _report()});
      await tester.pumpAndSettle();
      expect(find.byType(StaffInspectionForm), findsNothing);
      expect(find.text('Inspected by AutoParc'), findsOneWidget);
    },
  );

  testWidgets(
    'expiry picker clamps a previously selected expiry after moving the inspection date forward',
    (tester) async {
      await _show(
        tester,
        const StaffInspectionForm(source: 'vehicle', sourceId: 4),
        _Api(),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final yesterday = today.subtract(const Duration(days: 1));
      await _tap(tester, find.byIcon(Icons.calendar_today_outlined));
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(weekAgo);
      await _tap(tester, find.text('OK'));
      await _tap(tester, find.byType(SwitchListTile));
      await _tap(tester, find.byIcon(Icons.event_outlined));
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(yesterday);
      await _tap(tester, find.text('OK'));
      await _tap(tester, find.byIcon(Icons.calendar_today_outlined));
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(today);
      await _tap(tester, find.text('OK'));
      await _tap(tester, find.byIcon(Icons.event_outlined));
      expect(tester.takeException(), isNull);
      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(picker.initialDate, today);
      expect(picker.firstDate, today);
    },
  );
}
