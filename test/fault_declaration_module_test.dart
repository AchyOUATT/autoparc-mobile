import 'package:auto/features/vehicles/data/models/fault_declaration.dart';
import 'package:auto/features/vehicles/presentation/widgets/declared_faults_section.dart';
import 'package:auto/features/vehicles/presentation/widgets/fault_declaration_widget.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  int id = 4,
  String status = 'declared',
  bool editable = true,
}) => {
  'id': id,
  'category': 'braking',
  'title': 'Plaquettes usées',
  'description': 'Bruit au freinage.',
  'severity': 'moderate',
  'status': status,
  'is_open': status != 'repaired' && status != 'wont_fix',
  'affects_drivability': true,
  'is_safety_critical': true,
  'disclosed_to_buyer': false,
  'editable': editable,
};

FaultDeclaration _declaration({
  String state = 'has_faults',
  List<Map<String, dynamic>>? rows,
  int? count,
}) => FaultDeclaration.fromJson({
  'state': state,
  'declared_at': '2026-11-02T10:30:00Z',
  'faults': rows ?? [_row()],
  'unresolved_count': ?count,
});

class _EditorHarness extends StatefulWidget {
  final FaultDeclaration initial;
  final bool enabled;
  final bool requireChoice;
  final bool staffStatuses;
  const _EditorHarness({
    super.key,
    this.initial = const FaultDeclaration.unknown(),
    this.enabled = true,
    this.requireChoice = false,
    this.staffStatuses = false,
  });
  @override
  State<_EditorHarness> createState() => _EditorHarnessState();
}

class _EditorHarnessState extends State<_EditorHarness> {
  final form = GlobalKey<FormState>();
  late FaultDeclaration value;
  int changes = 0;
  bool showEditor = true;

  void replace(FaultDeclaration next) => setState(() => value = next);
  void hideEditor() => setState(() => showEditor = false);

  @override
  void initState() {
    super.initState();
    value = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (showEditor)
              FaultDeclarationWidget(
                value: value,
                enabled: widget.enabled,
                requireChoice: widget.requireChoice,
                staffStatuses: widget.staffStatuses,
                onChanged: (next) => setState(() {
                  changes++;
                  value = next;
                }),
              ),
            TextButton(
              onPressed: () => form.currentState!.validate(),
              child: const Text('Validate declaration'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _show(
  WidgetTester tester,
  Widget home, {
  String locale = 'en',
  Size size = const Size(600, 1100),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _key(String value) => find.byKey(ValueKey(value));

Iterable<String?> _options(WidgetTester tester, String key) => tester
    .widget<DropdownButton<String>>(
      find.descendant(
        of: _key(key),
        matching: find.byType(DropdownButton<String>),
      ),
    )
    .items!
    .map((item) => item.value);

void main() {
  test(
    'legacy and malformed data remain unknown; no empty list becomes a none declaration',
    () {
      for (final value in [
        null,
        true,
        [],
        {},
        {'state': 'unknown', 'faults': []},
        {'state': 'approved', 'faults': []},
        {
          'state': 'none',
          'faults': ['bad'],
        },
      ]) {
        final declaration = FaultDeclaration.fromJson(value);
        expect(declaration.state, 'unknown');
        expect(declaration.canSubmit, isFalse);
      }
      expect(_declaration(state: 'none', rows: []).canSubmit, isTrue);
      expect(_declaration(rows: []).canSubmit, isFalse);
      final unknownWithFaults = _declaration(state: 'unknown');
      expect(unknownWithFaults.state, 'unknown');
      expect(unknownWithFaults.faults, hasLength(1));
      expect(unknownWithFaults.canSubmit, isFalse);
      expect(_declaration(state: 'none').state, 'unknown');
      expect(_declaration(state: 'none', rows: [], count: 2).state, 'unknown');
    },
  );

  test(
    'wont_fix is unresolved even with closed maintenance, and visible faults cannot be undercounted',
    () {
      final closed = _declaration(rows: [_row(status: 'wont_fix')], count: 0);
      expect(closed.faults.single.isOpen, isFalse);
      expect(closed.faults.single.isUnresolved, isTrue);
      expect(closed.unresolvedCount, 1);
      final repaired = _declaration(rows: [_row(status: 'repaired')]);
      expect(repaired.state, 'has_faults');
      expect(repaired.unresolvedCount, 0);
      expect(repaired.canSubmit, isTrue);
      expect(_declaration(rows: [], count: 3).unresolvedCount, 3);
    },
  );

  test(
    'declaration and callbacks use immutable copies; input preserves identity/status/disclosure but omits staff rows and server fields',
    () {
      final rows = [DeclaredVehicleFault.fromJson(_row(status: 'repaired'))];
      final declaration = FaultDeclaration(state: 'has_faults', faults: rows);
      rows.clear();
      expect(declaration.faults, hasLength(1));
      expect(() => declaration.faults.clear(), throwsUnsupportedError);
      final next = declaration.copyWith(
        faults: [
          ...declaration.faults,
          DeclaredVehicleFault.fromJson(_row(id: 5, editable: false)),
        ],
      );
      expect(declaration.faults, hasLength(1));
      final payload = next.toPayload();
      expect(
        payload.keys,
        unorderedEquals(['fault_declaration_state', 'faults']),
      );
      final fault = (payload['faults'] as List).single as Map;
      expect(fault['id'], 4);
      expect(fault['status'], 'repaired');
      expect(fault['disclosed_to_buyer'], isFalse);
      expect(fault['is_safety_critical'], isTrue);
      expect(fault.containsKey('editable'), isFalse);
      expect(fault.containsKey('declared_at'), isFalse);
      expect(fault.containsKey('inspection'), isFalse);
      expect(next.canSubmit, isTrue);
    },
  );

  testWidgets(
    'controlled editor initializes unknown without callbacks and reflects external updates',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      await _show(tester, _EditorHarness(key: key));
      expect(key.currentState!.changes, 0);
      expect(key.currentState!.value.state, 'unknown');
      expect(
        key.currentState!.form.currentState!.validate(),
        isTrue,
      ); // Draft is allowed.
      key.currentState!.replace(_declaration());
      await tester.pumpAndSettle();
      expect(find.text('Plaquettes usées'), findsOneWidget);
      expect(key.currentState!.changes, 0);
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        'has_faults',
      );
    },
  );

  testWidgets(
    'requiring a choice rejects unknown and an empty has_faults list until an explicit none choice',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      await _show(tester, _EditorHarness(key: key, requireChoice: true));
      await _tap(tester, find.text('Validate declaration'));
      expect(
        find.text(
          'Declare the vehicle’s condition: no faults or a list of faults.',
        ),
        findsOneWidget,
      );
      await _tap(tester, _key('fault-declaration-state-has_faults'));
      expect(key.currentState!.value.state, 'has_faults');
      expect(key.currentState!.form.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Add at least one fault or explicitly choose another condition.',
        ),
        findsOneWidget,
      );
      await _tap(tester, _key('fault-declaration-state-none'));
      expect(key.currentState!.value.state, 'none');
      expect(key.currentState!.form.currentState!.validate(), isTrue);
    },
  );

  testWidgets(
    'new fault offers all API categories and severities but only three private statuses; last removal never auto-confirms none',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      await _show(tester, _EditorHarness(key: key));
      await _tap(tester, _key('fault-declaration-state-has_faults'));
      await _tap(tester, _key('fault-declaration-add'));
      expect(
        _options(tester, 'fault-declaration-category'),
        unorderedEquals([
          'engine',
          'transmission',
          'electrical',
          'braking',
          'suspension',
          'steering',
          'cooling',
          'air_conditioning',
          'bodywork',
          'interior',
          'electronics',
          'tyres',
          'other',
        ]),
      );
      expect(
        _options(tester, 'fault-declaration-severity'),
        unorderedEquals(['minor', 'moderate', 'major', 'critical']),
      );
      expect(
        _options(tester, 'fault-declaration-status'),
        unorderedEquals(['declared', 'repaired', 'wont_fix']),
      );
      await _tap(tester, _key('fault-declaration-apply'));
      expect(find.text('Title is required'), findsOneWidget);
      await tester.enterText(_key('fault-declaration-title'), 'Fuite d’huile');
      await _tap(tester, _key('fault-declaration-apply'));
      expect(key.currentState!.value.faults.single.title, 'Fuite d’huile');
      final previous = key.currentState!.value;
      await _tap(tester, _key('fault-declaration-remove-0'));
      expect(previous.faults, hasLength(1));
      expect(key.currentState!.value.faults, isEmpty);
      expect(key.currentState!.value.state, 'has_faults');
      expect(key.currentState!.value.canSubmit, isFalse);
    },
  );

  testWidgets(
    'editing preserves fault ID, repaired status and non-public disclosure; staff gets six statuses',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      await _show(
        tester,
        _EditorHarness(
          key: key,
          initial: _declaration(rows: [_row(status: 'repaired')]),
          staffStatuses: true,
        ),
      );
      await _tap(tester, _key('fault-declaration-edit-0'));
      expect(
        _options(tester, 'fault-declaration-status'),
        unorderedEquals([
          'declared',
          'diagnosed',
          'quoted',
          'repairing',
          'repaired',
          'wont_fix',
        ]),
      );
      await tester.enterText(
        _key('fault-declaration-title'),
        'Plaquettes remplacées',
      );
      await tester.enterText(_key('fault-declaration-description'), '');
      await _tap(tester, _key('fault-declaration-apply'));
      final fault = key.currentState!.value.faults.single;
      expect(fault.id, 4);
      expect(fault.status, 'repaired');
      expect(fault.disclosedToBuyer, isFalse);
      expect(fault.description, isNull);
      expect(fault.affectsDrivability, isTrue);
    },
  );

  testWidgets(
    'none requires confirmation before clearing rows; cancelling and choosing unknown preserve the original declaration',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      final initial = _declaration();
      await _show(tester, _EditorHarness(key: key, initial: initial));
      await _tap(tester, _key('fault-declaration-state-unknown'));
      expect(key.currentState!.value, same(initial));
      expect(key.currentState!.changes, 0);
      await _tap(tester, _key('fault-declaration-state-none'));
      expect(find.text('Clear the entered faults?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect(key.currentState!.value, same(initial));
      await _tap(tester, _key('fault-declaration-state-none'));
      await _tap(tester, find.text('Clear and continue'));
      expect(key.currentState!.value.state, 'none');
      expect(key.currentState!.value.faults, isEmpty);
      expect(initial.faults, hasLength(1));
      expect(key.currentState!.changes, 1);
    },
  );

  testWidgets(
    'read-only staff faults cannot be edited, removed or cleared through a none choice',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      final initial = _declaration(rows: [_row(editable: false)]);
      await _show(tester, _EditorHarness(key: key, initial: initial));
      expect(_key('fault-declaration-edit-0'), findsNothing);
      expect(_key('fault-declaration-remove-0'), findsNothing);
      await _tap(tester, _key('fault-declaration-state-none'));
      expect(
        find.text(
          'Faults managed by AutoParc are still present. You cannot clear this list.',
        ),
        findsOneWidget,
      );
      expect(key.currentState!.value, same(initial));
      expect(key.currentState!.changes, 0);
      expect(initial.toPayload()['faults'], isEmpty);
      expect(initial.canSubmit, isTrue);
    },
  );

  testWidgets('disabled editor never emits changes', (tester) async {
    final key = GlobalKey<_EditorHarnessState>();
    await _show(
      tester,
      _EditorHarness(key: key, initial: _declaration(), enabled: false),
    );
    await _tap(tester, _key('fault-declaration-state-none'));
    await _tap(tester, _key('fault-declaration-edit-0'));
    expect(key.currentState!.changes, 0);
    expect(
      tester.widget<OutlinedButton>(_key('fault-declaration-add')).onPressed,
      isNull,
    );
  });

  testWidgets(
    'sheet scrolls above the keyboard on a small screen at large text size',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      await _show(
        tester,
        _EditorHarness(key: key),
        size: const Size(320, 700),
        scale: 1.6,
      );
      await _tap(tester, _key('fault-declaration-state-has_faults'));
      await _tap(tester, _key('fault-declaration-add'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(_key('fault-declaration-title'), 'Fuite');
      await _tap(tester, _key('fault-declaration-apply'));
      expect(key.currentState!.value.faults.single.title, 'Fuite');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'closing a sheet after the parent editor is disposed does not call its callback or setState',
    (tester) async {
      final key = GlobalKey<_EditorHarnessState>();
      await _show(tester, _EditorHarness(key: key));
      await _tap(tester, _key('fault-declaration-state-has_faults'));
      await _tap(tester, _key('fault-declaration-add'));
      await tester.enterText(_key('fault-declaration-title'), 'Fuite');
      final changes = key.currentState!.changes;
      key.currentState!.hideEditor();
      await tester.pumpAndSettle();
      await _tap(tester, _key('fault-declaration-apply'));
      expect(key.currentState!.changes, changes);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'public condition stays a seller statement in FR and EN, with unresolved wont_fix and no inspection symbol',
    (tester) async {
      for (final locale in ['fr', 'en']) {
        await _show(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: DeclaredFaultsSection(
                declaration: _declaration(rows: [_row(status: 'wont_fix')]),
              ),
            ),
          ),
          locale: locale,
          size: const Size(320, 1000),
          scale: 1.6,
        );
        expect(
          find.text(locale == 'fr' ? 'Pannes à déclarer' : 'Faults to declare'),
          findsOneWidget,
        );
        expect(
          find.text(
            locale == 'fr'
                ? '1 défaut non réparé déclaré'
                : '1 declared unrepaired fault',
          ),
          findsOneWidget,
        );
        expect(
          find.text(locale == 'fr' ? 'Non réparé' : 'Unrepaired'),
          findsOneWidget,
        );
        expect(
          find.text(
            locale == 'fr' ? 'Critique pour la sécurité' : 'Safety-critical',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.verified_user_outlined), findsNothing);
        expect(find.byType(FaultDeclarationWidget), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await _show(
        tester,
        const Scaffold(
          body: DeclaredFaultsSection(declaration: FaultDeclaration.unknown()),
        ),
      );
      expect(find.text('Not provided'), findsOneWidget);
      expect(find.text('No faults declared by the seller'), findsNothing);
      await _show(
        tester,
        Scaffold(
          body: DeclaredFaultsSection(
            declaration: _declaration(state: 'none', rows: []),
          ),
        ),
      );
      expect(find.text('No faults declared by the seller'), findsOneWidget);
    },
  );

  testWidgets(
    'public hidden details retain a visible fault declaration and a contact explanation',
    (tester) async {
      await _show(
        tester,
        Scaffold(
          body: DeclaredFaultsSection(
            declaration: _declaration(rows: [], count: 2),
          ),
        ),
      );
      expect(find.text('Faults declared'), findsOneWidget);
      expect(find.text('2 declared unrepaired faults'), findsOneWidget);
      expect(
        find.text('Faults have been declared. Contact AutoParc for details.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.verified_user_outlined), findsNothing);
    },
  );
}
