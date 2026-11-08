import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as partner;
import 'package:auto/features/partner_accounts/presentation/partner_session.dart'
    as partner;
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/equipment_register_page.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/features/vehicles/presentation/widgets/vehicle_reference_dropdown.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/presentation/pages/media_upload_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/polices.dart';

const _cat = BrandRef(id: 3, name: 'Caterpillar', isActive: true);
const _toyota = BrandRef(id: 4, name: 'Toyota', isActive: true);
const _platform = ModelRef(
  id: 11,
  brandId: 3,
  name: 'Platform 18',
  equipmentCategory: 'aerial_platform',
);
const _excavator = ModelRef(
  id: 12,
  brandId: 3,
  name: 'Excavator 320',
  equipmentCategory: 'excavator',
);
const _car = ModelRef(id: 13, brandId: 3, name: 'Road car', bodyType: 'sedan');
const _otherBrandPlatform = ModelRef(
  id: 14,
  brandId: 4,
  name: 'Other platform',
  equipmentCategory: 'aerial_platform',
);
const _refs = CatalogRefs(
  brands: [_cat, _toyota],
  vehicleModels: [_platform, _excavator, _car, _otherBrandPlatform],
  trims: [],
  engineTypes: [],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

Vehicle _equipment({
  String availability = 'rent',
  bool proposedPrices = false,
  bool weeklyOnly = false,
}) {
  final data =
      (jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
              as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
  data.addAll({
    'id': 71,
    'asset_kind': 'equipment',
    'equipment_type': 'aerial_platform',
    'brand_id': 3,
    'vehicle_model_id': 11,
    'engine_type_id': null,
    'vehicle_type': null,
    'body_style': null,
    'equipment_details': {
      'serial_number': 'SN/42',
      'operating_hours': 1200.5,
      'working_height_m': 18.25,
      // Hidden for this type: an edit must leave it with the server.
      'bucket_capacity_m3': 2.75,
      'attachments': 'Fork attachment',
    },
    if (proposedPrices)
      'partner_pricing': {
        'taux': 10,
        'prix_proposes': {
          'rental_daily_rate': 25000,
          'rental_weekly_rate': 150000,
          'rental_monthly_rate': 500000,
          'sale_price': 8000000,
        },
      },
  });
  (data['identity'] as Map<String, dynamic>).addAll({
    'brand': 'Caterpillar',
    'model': 'Platform 18',
    'year': null,
    'engine_type': null,
  });
  (data['commercial'] as Map<String, dynamic>).addAll({
    'availability': availability,
    'sale_price': 8800000,
    'rental_daily_rate': weeklyOnly ? null : (proposedPrices ? 27500 : 25000),
    'rental_weekly_rate': proposedPrices ? 165000 : 150000,
    'rental_monthly_rate': weeklyOnly
        ? null
        : (proposedPrices ? 550000 : 500000),
    'rental_deposit': null,
    'currency': 'XOF',
    'site': null,
    'location_id': null,
  });
  return Vehicle.fromJson(data);
}

class _StaffRepository extends VehicleAdminRepository {
  _StaffRepository({this.succeed = false})
    : super(ApiClient(), CatalogLocalCache());

  final bool succeed;
  Map<String, dynamic>? payload;
  int? editedId;

  Future<Vehicle> _capture(Map<String, dynamic> data) async {
    payload = Map<String, dynamic>.from(data);
    if (!succeed) {
      throw const ApiException(message: 'Captured', statusCode: 422);
    }
    return _equipment();
  }

  @override
  Future<Vehicle> createVehicle(Map<String, dynamic> data) => _capture(data);

  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) {
    editedId = id;
    return _capture(data);
  }
}

class _PartnerRepository extends partner.PartnerRepository {
  _PartnerRepository({this.succeed = false});

  final bool succeed;
  Map<String, dynamic>? payload;
  int? editedId;

  @override
  Future<Map<String, dynamic>> saveListing(
    partner.PartnerListingKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) async {
    expect(kind, partner.PartnerListingKind.vehicles);
    payload = Map<String, dynamic>.from(data);
    editedId = id;
    if (!succeed) throw const partner.PartnerApiException('Captured');
    return {'id': id ?? 71};
  }
}

class _PartnerSession extends StateNotifier<partner.PartnerSession>
    implements partner.PartnerSessionNotifier {
  _PartnerSession()
    : super(
        const partner.PartnerSession(
          profile: partner.PartnerProfile(
            user: {'role': 'partner'},
            account: {'status': 'approved', 'contact_name': 'Vendeur'},
            boutique: {'marge_pourcentage': 10},
          ),
        ),
      );

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

Finder _field(String key) => find.byKey(ValueKey(key), skipOffstage: false);

String _text(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(_field(key)).controller!.text;

void _setText(WidgetTester tester, String key, String value) {
  tester.widget<TextFormField>(_field(key)).controller!.text = value;
}

Future<void> _selectType(WidgetTester tester, String value) async {
  final keyed = _field('equip-type');
  final dropdown = tester.widget(keyed);
  if (dropdown is VehicleReferenceDropdown<String>) {
    dropdown.onChanged(value);
  } else if (dropdown is DropdownButtonFormField<String>) {
    dropdown.onChanged!(value);
  } else {
    tester
        .widget<DropdownButtonFormField<String>>(
          find.descendant(
            of: keyed,
            matching: find.byType(DropdownButtonFormField<String>),
          ),
        )
        .onChanged!(value);
  }
  await tester.pumpAndSettle();
}

Future<void> _referenceIdentity(WidgetTester tester) async {
  await _selectType(tester, 'aerial_platform');
  tester
      .widget<VehicleReferenceDropdown<int>>(_field('equip-brand'))
      .onChanged(_cat.id);
  await tester.pumpAndSettle();
  tester
      .widget<VehicleReferenceDropdown<int>>(_field('equip-model'))
      .onChanged(_platform.id);
  await tester.pumpAndSettle();
}

Future<void> _freeIdentity(WidgetTester tester) async {
  await _selectType(tester, 'aerial_platform');
  final brands = tester.widget<VehicleReferenceDropdown<int>>(
    _field('equip-brand'),
  );
  brands.onChanged(-1);
  await tester.pumpAndSettle();
  _setText(tester, 'equip-brand-label', 'Acme workshop');
  _setText(tester, 'equip-model-label', 'Lift custom');
}

Future<void> _save(WidgetTester tester) async {
  final button = _field('equip-save');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _expand(WidgetTester tester, String key) async {
  final tile = _field(key);
  await tester.ensureVisible(tile);
  await tester.tap(
    find.descendant(of: tile, matching: find.byType(ListTile)).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester, {
  required _StaffRepository staff,
  _PartnerRepository? account,
  Vehicle? existing,
  VehicleFormMode mode = VehicleFormMode.personnel,
  String availability = 'rent',
  String language = 'fr',
  double textScale = 1,
  ValueChanged<bool?>? onReturned,
  ValueChanged<MediaUploadConfig>? onMedia,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            key: const ValueKey('open-equipment'),
            onPressed: () async {
              final result = await context.push<bool>('/new');
              onReturned?.call(result);
            },
            child: const Text('Home'),
          ),
        ),
      ),
      GoRoute(
        path: '/new',
        builder: (_, _) => EquipmentRegisterPage(
          existing: existing,
          mode: mode,
          initialAvailability: availability,
        ),
      ),
      GoRoute(
        path: '/media-upload',
        builder: (_, state) {
          onMedia?.call(state.extra! as MediaUploadConfig);
          return const Scaffold(body: Text('Photos destination'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRefsProvider.overrideWith((_) async => _refs),
        vehicleAdminRepositoryProvider.overrideWithValue(staff),
        partner.partnerRepositoryProvider.overrideWithValue(
          account ?? _PartnerRepository(),
        ),
        partner.partnerSessionProvider.overrideWith((_) => _PartnerSession()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-equipment')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolices);

  testWidgets('monthly rental accepts free identity without year or fuel', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    expect(find.byType(Stepper), findsNothing);
    await _freeIdentity(tester);
    _setText(tester, 'equip-monthly', '500000');
    await _save(tester);
    final payload = staff.payload!;
    expect(payload['asset_kind'], 'equipment');
    expect(payload['equipment_type'], 'aerial_platform');
    expect(payload['brand_id'], isNull);
    expect(payload['vehicle_model_id'], isNull);
    expect(payload['manufacturing_year'], isNull);
    expect(payload['engine_type_id'], isNull);
    expect(payload['rental_monthly_rate'], 500000);
    expect(payload.containsKey('rental_daily_rate'), isFalse);
    expect(payload.containsKey('rental_weekly_rate'), isFalse);
    expect(
      payload['equipment_details'],
      containsPair('brand_label', 'Acme workshop'),
    );
    expect(
      payload['equipment_details'],
      containsPair('model_label', 'Lift custom'),
    );
    expect(payload.containsKey('seats'), isFalse);
    expect(payload['body_style'], isNull);
    expect(payload['vehicle_type'], isNull);
    expect(tester.takeException(), isNull);
  });

  for (final rate in ['150000', '0']) {
    testWidgets('weekly-only rental rate $rate is independent', (tester) async {
      final staff = _StaffRepository();
      await _mount(tester, staff: staff);
      await _referenceIdentity(tester);
      _setText(tester, 'equip-weekly', rate);
      await _save(tester);
      expect(staff.payload!['rental_weekly_rate'], int.parse(rate));
      expect(staff.payload!.containsKey('rental_daily_rate'), isFalse);
      expect(staff.payload!.containsKey('rental_monthly_rate'), isFalse);
    });
  }

  testWidgets('sale needs a price and accepts an explicit zero', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, availability: 'sale');
    await _referenceIdentity(tester);
    await _save(tester);
    expect(staff.payload, isNull);
    _setText(tester, 'equip-sale-price', '0');
    await _save(tester);
    expect(staff.payload!['sale_price'], 0);
    expect(staff.payload!['availability'], 'sale');
  });

  testWidgets('a known brand can use an unlisted model label', (tester) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _referenceIdentity(tester);
    tester
        .widget<VehicleReferenceDropdown<int>>(_field('equip-model'))
        .onChanged(-1);
    await tester.pumpAndSettle();
    _setText(tester, 'equip-model-label', 'Custom lift');
    _setText(tester, 'equip-daily', '25000');
    await _save(tester);
    expect(staff.payload!['brand_id'], 3);
    expect(staff.payload!['vehicle_model_id'], isNull);
    expect(
      staff.payload!['equipment_details'],
      containsPair('model_label', 'Custom lift'),
    );
  });

  testWidgets('an entered manufacturing year must be valid', (tester) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _referenceIdentity(tester);
    _setText(tester, 'equip-daily', '25000');
    _setText(tester, 'equip-year', '${DateTime.now().year + 1}');
    await _save(tester);
    expect(staff.payload, isNull);
    expect(
      tester.state<FormFieldState<String>>(_field('equip-year')).hasError,
      isTrue,
    );
  });

  testWidgets('serial number is optional and has no VIN length constraint', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _freeIdentity(tester);
    _setText(tester, 'equip-daily', '25000');
    await _expand(tester, 'equip-optional-identity');
    _setText(tester, 'equip-serial-number', 'S/42');
    await _save(tester);
    expect(
      staff.payload!['equipment_details'],
      containsPair('serial_number', 'S/42'),
    );
    expect(staff.payload!.containsKey('vin'), isFalse);
  });

  testWidgets('decimal operating hours and height retain their precision', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _referenceIdentity(tester);
    _setText(tester, 'equip-daily', '25000');
    await _expand(tester, 'equip-optional-technical');
    _setText(tester, 'equip-operating-hours', '1200,5');
    _setText(tester, 'equip-working-height', '18.25');
    await _save(tester);
    expect(
      staff.payload!['equipment_details'],
      containsPair('operating_hours', 1200.5),
    );
    expect(
      staff.payload!['equipment_details'],
      containsPair('working_height_m', 18.25),
    );
  });

  testWidgets('malformed optional numbers still prevent submission', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _referenceIdentity(tester);
    _setText(tester, 'equip-daily', '25000');
    await _expand(tester, 'equip-optional-technical');
    _setText(tester, 'equip-operating-hours', '-1');
    await _save(tester);
    expect(staff.payload, isNull);
    expect(
      tester
          .state<FormFieldState<String>>(_field('equip-operating-hours'))
          .hasError,
      isTrue,
    );
  });

  testWidgets('reference models match both selected brand and equipment type', (
    tester,
  ) async {
    await _mount(tester, staff: _StaffRepository());
    await _referenceIdentity(tester);
    final aerial = tester.widget<VehicleReferenceDropdown<int>>(
      _field('equip-model'),
    );
    expect(aerial.items.where((id) => id > 0), [11]);
    await _selectType(tester, 'excavator');
    final excavators = tester.widget<VehicleReferenceDropdown<int>>(
      _field('equip-model'),
    );
    expect(excavators.items.where((id) => id > 0), [12]);
    expect(excavators.value, isNull);
  });

  testWidgets(
    'editing only sends changed details and preserves hidden values by omission',
    (tester) async {
      final staff = _StaffRepository();
      await _mount(tester, staff: staff, existing: _equipment());
      await _expand(tester, 'equip-optional-technical');
      _setText(tester, 'equip-operating-hours', '1201.25');
      await _save(tester);
      expect(staff.editedId, 71);
      expect(staff.payload!['equipment_details'], {'operating_hours': 1201.25});
      expect(staff.payload!.containsKey('availability'), isFalse);
      expect(staff.payload!.containsKey('rental_daily_rate'), isFalse);
      expect(staff.payload!.containsKey('rental_weekly_rate'), isFalse);
      expect(staff.payload!.containsKey('rental_monthly_rate'), isFalse);
    },
  );

  testWidgets(
    'clearing a visible detail sends null without erasing hidden details',
    (tester) async {
      final staff = _StaffRepository();
      await _mount(tester, staff: staff, existing: _equipment());
      await _expand(tester, 'equip-optional-technical');
      _setText(tester, 'equip-working-height', '');
      await _save(tester);
      expect(staff.payload!['equipment_details'], {'working_height_m': null});
    },
  );

  testWidgets('the last rental rate cannot be removed', (tester) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _equipment(weeklyOnly: true));
    _setText(tester, 'equip-weekly', '');
    await _save(tester);
    expect(staff.payload, isNull);
  });

  testWidgets('a type change preserves measurements hidden by the new type', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _equipment());
    await _selectType(tester, 'excavator');
    tester
        .widget<VehicleReferenceDropdown<int>>(_field('equip-model'))
        .onChanged(_excavator.id);
    await tester.pumpAndSettle();
    await _save(tester);
    expect(staff.payload!['equipment_type'], 'excavator');
    final details = staff.payload!['equipment_details'] as Map? ?? {};
    expect(details.containsKey('working_height_m'), isFalse);
    expect(details.containsKey('bucket_capacity_m3'), isFalse);
  });

  testWidgets('hour reading dates reject impossible calendar days', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _referenceIdentity(tester);
    _setText(tester, 'equip-daily', '25000');
    await _expand(tester, 'equip-optional-technical');
    _setText(tester, 'equip-hour-reading-date', '2025-02-30');
    await _save(tester);
    expect(staff.payload, isNull);
    expect(
      tester
          .state<FormFieldState<String>>(_field('equip-hour-reading-date'))
          .hasError,
      isTrue,
    );
  });

  testWidgets('an existing combined offer exposes sale and rent prices', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(
      tester,
      staff: staff,
      existing: _equipment(availability: 'both'),
    );
    expect(_text(tester, 'equip-sale-price'), '8800000');
    expect(_text(tester, 'equip-weekly'), '150000');
    _setText(tester, 'equip-sale-price', '9000000');
    await _save(tester);
    expect(staff.payload!['sale_price'], 9000000);
    expect(staff.payload!.containsKey('availability'), isFalse);
    expect(staff.payload!.containsKey('rental_weekly_rate'), isFalse);
  });

  testWidgets('partner restores proposed prices and sends only changed rate', (
    tester,
  ) async {
    final account = _PartnerRepository();
    await _mount(
      tester,
      staff: _StaffRepository(),
      account: account,
      existing: _equipment(proposedPrices: true),
      mode: VehicleFormMode.partenaire,
    );
    expect(_text(tester, 'equip-weekly'), '150000');
    _setText(tester, 'equip-weekly', '160000');
    await _save(tester);
    expect(account.payload!['rental_weekly_rate'], 160000);
    expect(account.payload!.containsKey('rental_daily_rate'), isFalse);
    expect(account.payload!.containsKey('rental_monthly_rate'), isFalse);
    expect(account.payload!.containsKey('location_id'), isFalse);
    expect(account.payload!.containsKey('partner_pricing'), isFalse);
  });

  testWidgets('staff creation continues to vehicle photos', (tester) async {
    MediaUploadConfig? media;
    await _mount(
      tester,
      staff: _StaffRepository(succeed: true),
      onMedia: (value) => media = value,
    );
    await _referenceIdentity(tester);
    _setText(tester, 'equip-daily', '25000');
    await _save(tester);
    expect(media?.id, 71);
    expect(find.text('Photos destination'), findsOneWidget);
  });

  testWidgets('partner success returns true', (tester) async {
    bool? returned;
    await _mount(
      tester,
      staff: _StaffRepository(),
      account: _PartnerRepository(succeed: true),
      mode: VehicleFormMode.partenaire,
      onReturned: (value) => returned = value,
    );
    await _referenceIdentity(tester);
    _setText(tester, 'equip-daily', '25000');
    await _save(tester);
    expect(returned, isTrue);
  });

  for (final language in ['fr', 'en']) {
    testWidgets('$language form fits 320px at 2x text scale', (tester) async {
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        staff: _StaffRepository(),
        language: language,
        textScale: 2,
      );
      await _freeIdentity(tester);
      await _expand(tester, 'equip-optional-identity');
      await _expand(tester, 'equip-optional-technical');
      await _expand(tester, 'equip-optional-attachments');
      await tester.ensureVisible(_field('equip-save'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
