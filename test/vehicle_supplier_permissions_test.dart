import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as partner;
import 'package:auto/features/partner_accounts/presentation/partner_session.dart';
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart'
    as directory;
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/vehicle_fault.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/data/vehicle_fault_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'vehicle_classification_test.dart' as fixtures;

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  void change(AuthState next) => state = next;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthState _staff(String role) => AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Staff',
    email: 'staff@example.test',
    role: role,
  ),
);

class _Session extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  _Session(bool associated)
    : super(
        PartnerSession(
          profile: associated
              ? partner.PartnerProfile(
                  user: const {'role': 'partner'},
                  account: const {
                    'id': 12,
                    'company_name': 'Own partner',
                    'status': 'approved',
                  },
                )
              : null,
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Directory extends directory.PartnerRepository {
  _Directory() : super(ApiClient());
  int reads = 0;
  @override
  Future<PaginatedResponse<Partner>> getPartners({
    int page = 1,
    int perPage = 50,
    String? search,
    bool includeInactive = false,
  }) async {
    reads++;
    return const PaginatedResponse(
      data: [
        Partner(
          id: 99,
          companyName: 'Other supplier',
          phone: '00000000',
          isActive: true,
        ),
      ],
      currentPage: 1,
      lastPage: 1,
      total: 1,
      perPage: 200,
    );
  }
}

class _StaffRepository extends VehicleAdminRepository {
  _StaffRepository() : super(ApiClient(), CatalogLocalCache());
  Map<String, dynamic>? payload;
  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    payload = Map.of(data);
    throw const ApiException(message: 'Captured', statusCode: 422);
  }
}

class _Faults extends VehicleFaultRepository {
  _Faults() : super(ApiClient());
  @override
  Future<List<VehicleFault>> getFaults(int id, {bool openOnly = false}) async =>
      [];
}

class _PartnerRepository extends partner.PartnerRepository {
  Map<String, dynamic>? payload;
  @override
  Future<Map<String, dynamic>> listing(
    partner.PartnerListingKind kind,
    int id,
  ) async => {};
  @override
  Future<Map<String, dynamic>> saveListing(
    partner.PartnerListingKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) async {
    payload = Map.of(data);
    throw const ApiException(message: 'Captured', statusCode: 422);
  }
}

Future<void> _open(
  WidgetTester tester, {
  required _Auth auth,
  required _Directory directoryRepo,
  required _StaffRepository staff,
  required _PartnerRepository partnerRepo,
  required Locale locale,
  VehicleFormMode mode = VehicleFormMode.personnel,
  bool associated = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => auth),
        partnerSessionProvider.overrideWith((_) => _Session(associated)),
        catalogRefsProvider.overrideWith((_) async => fixtures.refs),
        countriesProvider.overrideWith((_) async => <CountryRef>[]),
        directory.partnerRepositoryProvider.overrideWithValue(directoryRepo),
        vehicleAdminRepositoryProvider.overrideWithValue(staff),
        vehicleFaultRepositoryProvider.overrideWithValue(_Faults()),
        partner.partnerRepositoryProvider.overrideWithValue(partnerRepo),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VehicleRegisterPage(
          mode: mode,
          existing: Vehicle.fromJson(
            fixtures.vehicleJson()
              ..['fault_declaration'] = {'state': 'none', 'faults': []},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _supplier => find.byWidgetPredicate(
  (w) => w is DropdownButtonFormField<int?>,
  skipOffstage: false,
);

Future<void> _submit(WidgetTester tester) async {
  for (var step = 0; step < 4; step++) {
    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final entry in {
      'admin': _staff('admin'),
      'manager': _staff('manager'),
      'sales': _staff('sales'),
      'viewer': _staff('viewer'),
      'mechanic': _staff('mechanic'),
      'partner-role': _staff('partner'),
      'client': const AuthState(type: AuthType.client),
      'visitor': const AuthState(),
      'partner-session': const AuthState(),
    }.entries) {
      testWidgets(
        'supplier uses server catalog permission: ${entry.key} $locale',
        (tester) async {
          final directoryRepo = _Directory();
          final staff = _StaffRepository();
          await _open(
            tester,
            auth: _Auth(entry.value),
            directoryRepo: directoryRepo,
            staff: staff,
            partnerRepo: _PartnerRepository(),
            locale: locale,
            associated: entry.key == 'partner-session',
          );
          final allowed = const {
            'admin',
            'manager',
            'sales',
          }.contains(entry.key);
          expect(entry.value.canManageCatalog, allowed);
          expect(_supplier, allowed ? findsOneWidget : findsNothing);
          expect(directoryRepo.reads, allowed ? 1 : 0);
          if (allowed) {
            tester.widget<DropdownButtonFormField<int?>>(_supplier).onChanged!(
              99,
            );
            await tester.pumpAndSettle();
            await _submit(tester);
            expect(staff.payload?['partner_id'], 99);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final associated in [false, true]) {
      testWidgets(
        'partner mode cannot select a supplier, associated=$associated $locale',
        (tester) async {
          final directoryRepo = _Directory();
          final partnerRepo = _PartnerRepository();
          // Even a simultaneous staff session cannot enable the partner field.
          await _open(
            tester,
            auth: _Auth(_staff('admin')),
            directoryRepo: directoryRepo,
            staff: _StaffRepository(),
            partnerRepo: partnerRepo,
            locale: locale,
            mode: VehicleFormMode.partenaire,
            associated: associated,
          );
          expect(_supplier, findsNothing);
          expect(directoryRepo.reads, 0);
          await _submit(tester);
          expect(partnerRepo.payload, isNotNull);
          expect(partnerRepo.payload!.containsKey('partner_id'), isFalse);
          expect(
            partnerRepo.payload!.containsKey('owner_partner_account_id'),
            isFalse,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'role loss removes selector and drops previously selected ID $locale',
      (tester) async {
        final auth = _Auth(_staff('sales'));
        final staff = _StaffRepository();
        await _open(
          tester,
          auth: auth,
          directoryRepo: _Directory(),
          staff: staff,
          partnerRepo: _PartnerRepository(),
          locale: locale,
        );
        tester.widget<DropdownButtonFormField<int?>>(_supplier).onChanged!(99);
        await tester.pumpAndSettle();
        auth.change(const AuthState());
        await tester.pumpAndSettle();
        expect(_supplier, findsNothing);
        await _submit(tester);
        expect(staff.payload, isNotNull);
        expect(staff.payload!.containsKey('partner_id'), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
