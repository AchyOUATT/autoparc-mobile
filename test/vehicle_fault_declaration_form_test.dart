import 'dart:async';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as partner;
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart'
    as directory;
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/fault_declaration.dart';
import 'package:auto/features/vehicles/data/models/vehicle_fault.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/data/vehicle_fault_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/features/vehicles/presentation/widgets/fault_declaration_widget.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vehicle_classification_test.dart' as classification;

Map<String, dynamic> _fault(
  int id, {
  String status = 'declared',
  bool editable = true,
}) => {
  'id': id,
  'category': 'engine',
  'title': 'Fault $id',
  'description': 'Complete diagnostic',
  'severity': 'major',
  'status': status,
  'affects_drivability': true,
  'is_safety_critical': false,
  'editable': editable,
};

Vehicle _existing({
  String state = 'has_faults',
  List<Map<String, dynamic>> faults = const [],
}) => Vehicle.fromJson(
  classification.vehicleJson()
    ..['fault_declaration'] = {'state': state, 'faults': faults},
);

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(String role)
    : super(
        AuthState(
          type: AuthType.staff,
          staffUser: StaffUser(
            id: 1,
            name: 'Staff',
            email: 'staff@example.test',
            role: role,
          ),
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FaultRepository extends VehicleFaultRepository {
  _FaultRepository() : super(ApiClient());
  int reads = 0;
  bool fail = false;
  Completer<List<VehicleFault>>? pending;
  List<Map<String, dynamic>> rows = [
    _fault(10),
    _fault(11, status: 'repaired'),
  ];
  @override
  Future<List<VehicleFault>> getFaults(
    int vehicleId, {
    bool openOnly = false,
  }) async {
    reads++;
    expect(openOnly, isFalse);
    if (fail) throw const ApiException(message: 'Offline', statusCode: 503);
    return pending == null
        ? rows.map(VehicleFault.fromJson).toList()
        : pending!.future;
  }
}

class _StaffRepository extends VehicleAdminRepository {
  _StaffRepository() : super(ApiClient(), CatalogLocalCache());
  Map<String, dynamic>? payload;
  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async =>
      _capture(data);
  @override
  Future<Vehicle> createVehicle(Map<String, dynamic> data) async =>
      _capture(data);
  Never _capture(Map<String, dynamic> data) {
    payload = Map<String, dynamic>.from(data);
    throw const ApiException(message: 'Captured request', statusCode: 422);
  }
}

class _PartnerRepository extends partner.PartnerRepository {
  int reads = 0;
  Map<String, dynamic>? payload;
  Map<String, dynamic> detail = {
    'fault_declaration': {
      'state': 'has_faults',
      'faults': [_fault(20), _fault(21, status: 'repairing', editable: false)],
    },
  };
  @override
  Future<Map<String, dynamic>> listing(
    partner.PartnerListingKind kind,
    int id,
  ) async {
    reads++;
    return detail;
  }

  @override
  Future<Map<String, dynamic>> saveListing(
    partner.PartnerListingKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) async {
    payload = Map<String, dynamic>.from(data);
    throw const ApiException(message: 'Captured request', statusCode: 422);
  }
}

class _Directory extends directory.PartnerRepository {
  _Directory() : super(ApiClient());
  @override
  Future<PaginatedResponse<Partner>> getPartners({
    int page = 1,
    int perPage = 50,
    String? search,
    bool includeInactive = false,
  }) async => const PaginatedResponse(
    data: [],
    currentPage: 1,
    lastPage: 1,
    total: 0,
    perPage: 50,
  );
}

Finder get _editor => find.byType(FaultDeclarationWidget, skipOffstage: false);
FaultDeclarationWidget _current(WidgetTester tester) =>
    tester.widget<FaultDeclarationWidget>(_editor);

Future<void> _open(
  WidgetTester tester, {
  required _FaultRepository faults,
  required _StaffRepository staff,
  required _PartnerRepository partnerRepo,
  String role = 'manager',
  Vehicle? existing,
  bool create = false,
  bool settle = true,
  VehicleFormMode mode = VehicleFormMode.personnel,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _Auth(role)),
        catalogRefsProvider.overrideWith((_) async => classification.refs),
        countriesProvider.overrideWith((_) async => <CountryRef>[]),
        vehicleFaultRepositoryProvider.overrideWithValue(faults),
        vehicleAdminRepositoryProvider.overrideWithValue(staff),
        partner.partnerRepositoryProvider.overrideWithValue(partnerRepo),
        directory.partnerRepositoryProvider.overrideWithValue(_Directory()),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VehicleRegisterPage(
          existing: create ? null : existing ?? _existing(),
          mode: mode,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }
}

Future<void> _submit(WidgetTester tester) async {
  for (var step = 0; step < 4; step++) {
    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();
  }
}

Future<void> _fillCreation(WidgetTester tester) async {
  final l10n = AppLocalizationsFr();
  final body = find.byWidgetPredicate(
    (w) =>
        w is DropdownButtonFormField<String> &&
        w.decoration.labelText == l10n.vehiclesBodyStyleLabel,
    skipOffstage: false,
  );
  tester.widget<DropdownButtonFormField<String>>(body).onChanged!('sedan');
  await tester.pumpAndSettle();
  await classification.choose<BrandRef>(tester, classification.toyota);
  await classification.choose<ModelRef>(tester, classification.existante);
  await classification.choose<EngineTypeRef>(tester, classification.essence);
  for (final entry in {
    l10n.vehiclesManufactureYearLabel: '2018',
    l10n.vehiclesSalePriceLabel: '6500000',
  }.entries) {
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == entry.key,
      skipOffstage: false,
    );
    tester.widget<TextField>(field).controller!.text = entry.value;
  }
  await tester.pumpAndSettle();
}

void main() {
  late _FaultRepository faults;
  late _StaffRepository staff;
  late _PartnerRepository partnerRepo;
  setUp(() {
    faults = _FaultRepository();
    staff = _StaffRepository();
    partnerRepo = _PartnerRepository();
  });

  testWidgets(
    'staff waits for the complete internal list and retains repaired rows and IDs',
    (tester) async {
      faults.pending = Completer<List<VehicleFault>>();
      await _open(
        tester,
        faults: faults,
        staff: staff,
        partnerRepo: partnerRepo,
        existing: _existing(faults: [_fault(999)]),
        settle: false,
      );
      expect(_editor, findsNothing);
      faults.pending!.complete(faults.rows.map(VehicleFault.fromJson).toList());
      await tester.pumpAndSettle();
      expect(faults.reads, 1);
      final editor = _current(tester);
      final rows = (editor.value.toPayload()['faults'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      expect(rows.map((row) => row['id']), [10, 11]);
      expect(rows.last['status'], 'repaired');
      expect(rows.first['disclosed_to_buyer'], isFalse);
      rows.first['title'] = 'Updated diagnosis';
      editor.onChanged(
        FaultDeclaration.fromJson({'state': 'has_faults', 'faults': rows}),
      );
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(staff.payload!['fault_declaration_state'], 'has_faults');
      expect((staff.payload!['faults'] as List).last['status'], 'repaired');
      expect((staff.payload!['faults'] as List).first['id'], 10);
      expect(
        (staff.payload!['faults'] as List).first['disclosed_to_buyer'],
        isFalse,
      );
    },
  );

  testWidgets('price-only staff editing omits an unchanged declaration', (
    tester,
  ) async {
    await _open(tester, faults: faults, staff: staff, partnerRepo: partnerRepo);
    await _submit(tester);
    expect(staff.payload, isNotNull);
    expect(staff.payload!.containsKey('faults'), isFalse);
    expect(staff.payload!.containsKey('fault_declaration_state'), isFalse);
  });

  testWidgets(
    'legacy empty internal rows keep an explicit unknown declaration',
    (tester) async {
      faults.rows = [];
      await _open(
        tester,
        faults: faults,
        staff: staff,
        partnerRepo: partnerRepo,
        existing: _existing(state: 'unknown'),
      );
      expect(_current(tester).value.state, 'unknown');
      await _submit(tester);
      expect(staff.payload, isNotNull);
      expect(staff.payload!.containsKey('fault_declaration_state'), isFalse);
    },
  );

  testWidgets('sales can save stock without loading or changing faults', (
    tester,
  ) async {
    await _open(
      tester,
      faults: faults,
      staff: staff,
      partnerRepo: partnerRepo,
      role: 'sales',
    );
    expect(_editor, findsNothing);
    expect(faults.reads, 0);
    await _submit(tester);
    expect(staff.payload!.containsKey('faults'), isFalse);
    expect(staff.payload!.containsKey('fault_declaration_state'), isFalse);
  });

  testWidgets(
    'failed loading permits price-only save and retry restores the full editor',
    (tester) async {
      faults.fail = true;
      await _open(
        tester,
        faults: faults,
        staff: staff,
        partnerRepo: partnerRepo,
      );
      expect(_editor, findsNothing);
      await _submit(tester);
      expect(staff.payload!.containsKey('faults'), isFalse);
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
      faults.fail = false;
      final retry = find.widgetWithText(
        TextButton,
        AppLocalizationsFr().commonRetry,
        skipOffstage: false,
      );
      tester.widget<TextButton>(retry).onPressed!();
      await tester.pumpAndSettle();
      expect(faults.reads, 2);
      expect(_current(tester).value.toPayload()['faults'], hasLength(2));
    },
  );

  for (final declaredNone in [false, true]) {
    testWidgets(
      'import creation keeps declaration optional, none=$declaredNone',
      (tester) async {
        await _open(
          tester,
          faults: faults,
          staff: staff,
          partnerRepo: partnerRepo,
          create: true,
        );
        await _fillCreation(tester);
        expect(_current(tester).value.state, 'unknown');
        if (declaredNone) {
          _current(tester).onChanged(
            FaultDeclaration.fromJson({'state': 'none', 'faults': []}),
          );
          await tester.pumpAndSettle();
        }
        await _submit(tester);
        expect(staff.payload, isNotNull);
        expect(staff.payload!['registration_status'], 'unregistered');
        expect(
          staff.payload!.containsKey('fault_declaration_state'),
          declaredNone,
        );
        if (declaredNone) expect(staff.payload!['faults'], isEmpty);
      },
    );
  }

  testWidgets(
    'partner refetches management rows, preserves staff rows and submits only owned edits',
    (tester) async {
      await _open(
        tester,
        faults: faults,
        staff: staff,
        partnerRepo: partnerRepo,
        mode: VehicleFormMode.partenaire,
        existing: _existing(state: 'unknown'),
      );
      expect(partnerRepo.reads, 1);
      expect(faults.reads, 0);
      final editor = _current(tester);
      expect(editor.staffStatuses, isFalse);
      expect(editor.value.faults, hasLength(2));
      final payloadRows = editor.value.toPayload()['faults'] as List;
      expect(payloadRows, hasLength(1));
      final edited = Map<String, dynamic>.from(payloadRows.single as Map)
        ..['status'] = 'repaired';
      editor.onChanged(
        FaultDeclaration.fromJson({
          'state': 'has_faults',
          'faults': [edited, _fault(21, status: 'repairing', editable: false)],
        }),
      );
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(partnerRepo.payload!['fault_declaration_state'], 'has_faults');
      expect(partnerRepo.payload!['faults'], [edited..remove('editable')]);
    },
  );

  testWidgets(
    'partner price-only edit omits declarations from partial public initial data',
    (tester) async {
      await _open(
        tester,
        faults: faults,
        staff: staff,
        partnerRepo: partnerRepo,
        mode: VehicleFormMode.partenaire,
        existing: _existing(state: 'unknown'),
      );
      await _submit(tester);
      expect(partnerRepo.payload, isNotNull);
      expect(partnerRepo.payload!.containsKey('faults'), isFalse);
      expect(
        partnerRepo.payload!.containsKey('fault_declaration_state'),
        isFalse,
      );
    },
  );
}
