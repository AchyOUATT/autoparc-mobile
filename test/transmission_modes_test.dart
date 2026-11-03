import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/l10n/transmission_labels.dart';
import 'package:auto/core/l10n/reference_labels.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/libelles_vehicule.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as partner;
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart'
    as directory;
import 'package:auto/features/private_sales/presentation/private_listing_labels.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/l10n/app_localizations_en.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _refs = CatalogRefs(
  brands: [BrandRef(id: 3, name: 'Toyota', isActive: true)],
  vehicleModels: [ModelRef(id: 11, brandId: 3, name: 'Corolla')],
  trims: [],
  engineTypes: [
    EngineTypeRef(
      id: 5,
      code: 'petrol',
      label: 'Essence',
      usesFuel: true,
      usesBattery: false,
    ),
  ],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

Vehicle _existing(String transmission) {
  final json =
      (jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
              as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
  json.addAll({'brand_id': 3, 'vehicle_model_id': 11, 'engine_type_id': 5});
  (json['identity'] as Map<String, dynamic>)['year'] = 2016;
  (json['technical'] as Map<String, dynamic>)['transmission'] = transmission;
  return Vehicle.fromJson(json);
}

class _StaffRepository extends VehicleAdminRepository {
  _StaffRepository() : super(ApiClient(), CatalogLocalCache());
  Map<String, dynamic>? payload;

  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    payload = Map<String, dynamic>.from(data);
    throw const ApiException(message: 'Captured request', statusCode: 422);
  }
}

class _PartnerRepository extends partner.PartnerRepository {
  Map<String, dynamic>? payload;

  @override
  Future<Map<String, dynamic>> listing(
    partner.PartnerListingKind kind,
    int id,
  ) async => {
    'fault_declaration': {'state': 'unknown', 'faults': []},
  };

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

class _DirectoryRepository extends directory.PartnerRepository {
  _DirectoryRepository() : super(ApiClient());

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

void main() {
  test(
    'driven-wheel families do not inherit a permanent or selectable mode',
    () {
      for (final l10n in [AppLocalizationsFr(), AppLocalizationsEn()]) {
        expect(
          referenceDrivetrainLabel(
            'AWD',
            'Transmission intégrale permanente',
            l10n,
          ),
          l10n.vehiclesReferenceDriveAllWheel,
        );
        expect(
          referenceDrivetrainLabel(
            null,
            'Transmission intégrale permanente',
            l10n,
          ),
          l10n.vehiclesReferenceDriveAllWheel,
        );
        expect(
          referenceDrivetrainLabel(null, '4x4 débrayable', l10n),
          l10n.vehiclesReferenceDriveFourWheel,
        );
        expect(
          referenceDrivetrainLabel('FWD', 'custom label', l10n),
          l10n.vehiclesReferenceDriveFrontWheel,
        );
        expect(
          referenceDrivetrainLabel('RWD', 'custom label', l10n),
          l10n.vehiclesReferenceDriveRearWheel,
        );
        expect(
          referenceDrivetrainLabel('custom', 'Custom driven wheels', l10n),
          'Custom driven wheels',
        );
      }
    },
  );

  test('all supported gearboxes have consistent French and English labels', () {
    expect(vehicleTransmissionCodes, [
      'manual',
      'automatic',
      'cvt',
      'dual_clutch',
      'single_speed',
    ]);
    for (final l10n in [AppLocalizationsFr(), AppLocalizationsEn()]) {
      for (final code in vehicleTransmissionCodes) {
        final label = transmissionLabel(code, l10n);
        expect(label, isNot(code));
        expect(libelleTransmission(l10n, code), label);
        expect(privateListingTransmissionLabel(code, l10n), label);
      }
      expect(transmissionLabel('future_gearbox', l10n), 'future_gearbox');
    }
  });

  for (final mode in VehicleFormMode.values) {
    for (final code in ['dual_clutch', 'single_speed']) {
      testWidgets(
        '${mode.name} preserves $code in editing, summary and request',
        (tester) async {
          final staffRepo = _StaffRepository();
          final partnerRepo = _PartnerRepository();
          final l10n = AppLocalizationsFr();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                catalogRefsProvider.overrideWith((_) async => _refs),
                countriesProvider.overrideWith((_) async => <CountryRef>[]),
                vehicleAdminRepositoryProvider.overrideWithValue(staffRepo),
                partner.partnerRepositoryProvider.overrideWithValue(
                  partnerRepo,
                ),
                directory.partnerRepositoryProvider.overrideWithValue(
                  _DirectoryRepository(),
                ),
              ],
              child: MaterialApp(
                locale: const Locale('fr'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: VehicleRegisterPage(
                  mode: mode,
                  existing: _existing(code),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          for (final option in vehicleTransmissionCodes) {
            final chip = find.widgetWithText(
              ChoiceChip,
              transmissionLabel(option, l10n),
              skipOffstage: false,
            );
            expect(chip, findsOneWidget);
            expect(tester.widget<ChoiceChip>(chip).selected, option == code);
          }
          final technical = tester
              .widget<Stepper>(find.byType(Stepper))
              .steps[2];
          expect(
            (technical.subtitle as Text).data,
            contains(transmissionLabel(code, l10n)),
          );
          expect(
            (technical.subtitle as Text).data,
            isNot(contains(l10n.catalogTransmissionAutomatic)),
          );

          for (var step = 0; step < 4; step++) {
            tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
            await tester.pumpAndSettle();
          }
          final payload = mode.estPartenaire
              ? partnerRepo.payload
              : staffRepo.payload;
          expect(payload, isNotNull);
          expect(payload!['transmission'], code);
        },
      );
    }
  }
}
