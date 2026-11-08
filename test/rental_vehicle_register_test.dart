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
import 'package:auto/features/vehicles/presentation/pages/rental_vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/features/vehicles/presentation/widgets/transmission_selector.dart';
import 'package:auto/features/vehicles/presentation/widgets/vehicle_reference_dropdown.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/presentation/pages/media_upload_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/polices.dart';

const _toyota = BrandRef(id: 3, name: 'Toyota', isActive: true);
const _honda = BrandRef(id: 4, name: 'Honda', isActive: true);
const _corolla = ModelRef(
  id: 11,
  brandId: 3,
  name: 'Corolla',
  generation: 'E180',
  bodyType: 'berline',
  productionStart: 2013,
  productionEnd: 2019,
  defaultTransmission: 'automatic',
  defaultSeats: 5,
);
const _civic = ModelRef(id: 12, brandId: 4, name: 'Civic', bodyType: 'berline');
const _petrol = EngineTypeRef(
  id: 5,
  code: 'petrol',
  label: 'Essence',
  usesFuel: true,
  usesBattery: false,
);
const _diesel = EngineTypeRef(
  id: 8,
  code: 'diesel',
  label: 'Diesel',
  usesFuel: true,
  usesBattery: false,
);
const _refs = CatalogRefs(
  brands: [_toyota, _honda],
  vehicleModels: [_corolla, _civic],
  trims: [TrimRef(id: 20, vehicleModelId: 11, name: 'LE')],
  engineTypes: [_petrol, _diesel],
  drivetrains: [DrivetrainRef(id: 6, code: 'FWD', label: 'Traction')],
  colors: [],
  features: [
    FeatureRef(id: 31, name: 'Climatisation automatique', category: 'confort'),
    FeatureRef(id: 32, name: 'Triangle de signalisation', category: 'dotation'),
    FeatureRef(
      id: 33,
      name: 'Support de téléphone et câble de recharge pour les passagers',
      category: 'accessoire',
    ),
  ],
  locations: [LocationRef(id: 7, name: 'Nord', city: 'Ouagadougou')],
);

Vehicle _vehicle({
  String availability = 'rent',
  bool proposedPrices = false,
  bool weeklyOnly = false,
  List<Map<String, dynamic>>? equipment,
}) {
  final data =
      (jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
              as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
  data.addAll({
    'id': 71,
    'brand_id': 3,
    'vehicle_model_id': 11,
    'engine_type_id': 5,
    'trim_id': 20,
    'drivetrain_id': 6,
    'color_id': 7,
    'vehicle_type': 'passenger',
    'body_style': 'sedan',
    'vin': 'JT123456789012345',
    'description': 'Climatisation et livraison sur demande.',
    'features': ?equipment,
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
  (data['identity'] as Map<String, dynamic>)['year'] = 2016;
  (data['technical'] as Map<String, dynamic>).addAll({
    'transmission': 'cvt',
    'seats': 7,
    'engine_code': '2ZR-FE',
    'power_hp': 132,
    'mileage_km': 75000,
  });
  (data['commercial'] as Map<String, dynamic>).addAll({
    'availability': availability,
    'condition': 'used',
    'status': 'rented',
    'sale_price': 8800000,
    'rental_daily_rate': weeklyOnly ? null : (proposedPrices ? 27500 : 25000),
    'rental_monthly_rate': weeklyOnly
        ? null
        : (proposedPrices ? 550000 : 500000),
    'rental_weekly_rate': proposedPrices ? 165000 : 150000,
    'rental_deposit': 100000,
    'site': 'Ouagadougou, centre-ville',
    'currency': 'XOF',
    'location_id': 7,
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
      throw const ApiException(message: 'Charge capturée', statusCode: 422);
    }
    return _vehicle();
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
    if (!succeed) {
      throw const partner.PartnerApiException('Charge capturée');
    }
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

Future<void> _select<T>(WidgetTester tester, String key, T value) async {
  tester.widget<VehicleReferenceDropdown<T>>(_field(key)).onChanged(value);
  await tester.pumpAndSettle();
}

Future<void> _identity(WidgetTester tester) async {
  await _select(tester, 'rental-brand', _toyota);
  await _select(tester, 'rental-model', _corolla);
  await _select(tester, 'rental-fuel', _petrol);
  _setText(tester, 'rental-year', '2016');
}

Future<void> _save(WidgetTester tester) async {
  final button = _field('rental-save');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _extras(WidgetTester tester) async {
  final tile = _field('rental-optional');
  await tester.ensureVisible(tile);
  await tester.tap(find.descendant(of: tile, matching: find.byType(ListTile)));
  await tester.pumpAndSettle();
}

Future<void> _equipment(WidgetTester tester) async {
  final tile = _field('rental-equipment');
  await tester.ensureVisible(tile);
  await tester.tap(
    find.descendant(of: tile, matching: find.byType(ListTile)).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _toggleEquipment(WidgetTester tester, int id) async {
  final field = _field('rental-feature-$id');
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
}

Future<GoRouter> _mount(
  WidgetTester tester, {
  required _StaffRepository staff,
  _PartnerRepository? account,
  Vehicle? existing,
  VehicleFormMode mode = VehicleFormMode.personnel,
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
            key: const ValueKey('open-rental'),
            onPressed: () async {
              final returned = await context.push<bool>('/new');
              onReturned?.call(returned);
            },
            child: const Text('Home'),
          ),
        ),
      ),
      GoRoute(
        path: '/new',
        builder: (_, _) =>
            RentalVehicleRegisterPage(existing: existing, mode: mode),
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
  await tester.tap(find.byKey(const ValueKey('open-rental')));
  await tester.pumpAndSettle();
  return router;
}

const _hiddenKeys = {
  'sale_price',
  'purchase_price',
  'vin',
  'registration_status',
  'plate_number',
  'registration',
  'import',
  'trim_id',
  'drivetrain_id',
  'engine_code',
  'power_hp',
  'condition',
  'status',
  'heavy_configuration',
  'features',
  'faults',
  'fault_declaration_state',
  'deal_type',
  'deal_price',
};

void main() {
  setUpAll(chargerPolices);

  testWidgets('monthly-only rental saves without sale or import questions', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    expect(find.byType(Stepper), findsNothing);
    await _identity(tester);
    _setText(tester, 'rental-monthly', '500000');
    await _save(tester);
    final data = staff.payload!;
    expect(data['brand_id'], 3);
    expect(data['vehicle_model_id'], 11);
    expect(data['engine_type_id'], 5);
    expect(data['manufacturing_year'], 2016);
    expect(data['availability'], 'rent');
    expect(data['rental_monthly_rate'], 500000);
    expect(data['rental_daily_rate'], isNull);
    expect(data['transmission'], isNull);
    expect(data['seats'], isNull);
    expect(data.keys.toSet().intersection(_hiddenKeys), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a zero daily rate is explicit and never converted to monthly', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _identity(tester);
    _setText(tester, 'rental-daily', '0');
    await _save(tester);
    expect(staff.payload!['rental_daily_rate'], 0);
    expect(staff.payload!['rental_monthly_rate'], isNull);
  });

  for (final weeklyRate in ['175000', '0']) {
    testWidgets('a weekly-only rate of $weeklyRate saves independently', (
      tester,
    ) async {
      final staff = _StaffRepository();
      await _mount(tester, staff: staff);
      await _identity(tester);
      _setText(tester, 'rental-weekly', weeklyRate);
      await _save(tester);

      expect(staff.payload!['rental_weekly_rate'], int.parse(weeklyRate));
      expect(staff.payload!.containsKey('rental_daily_rate'), isFalse);
      expect(staff.payload!.containsKey('rental_monthly_rate'), isFalse);
      expect(staff.payload!.containsKey('features'), isFalse);
    });
  }

  testWidgets('editing a weekly-only rental restores and preserves its rate', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _vehicle(weeklyOnly: true));
    expect(_text(tester, 'rental-weekly'), '150000');
    expect(_text(tester, 'rental-daily'), isEmpty);
    expect(_text(tester, 'rental-monthly'), isEmpty);
    await _save(tester);

    expect(staff.payload, isNotNull);
    for (final field in [
      'rental_daily_rate',
      'rental_weekly_rate',
      'rental_monthly_rate',
    ]) {
      expect(staff.payload!.containsKey(field), isFalse, reason: field);
    }
  });

  testWidgets('a changed weekly rate is the only price sent on editing', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _vehicle());
    _setText(tester, 'rental-weekly', '180000');
    await _save(tester);

    expect(staff.payload!['rental_weekly_rate'], 180000);
    expect(staff.payload!.containsKey('rental_daily_rate'), isFalse);
    expect(staff.payload!.containsKey('rental_monthly_rate'), isFalse);
  });

  testWidgets('clearing a weekly rate keeps existing day and month prices', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _vehicle());
    _setText(tester, 'rental-weekly', '');
    await _save(tester);

    expect(staff.payload!.containsKey('rental_weekly_rate'), isTrue);
    expect(staff.payload!['rental_weekly_rate'], isNull);
    expect(staff.payload!.containsKey('rental_daily_rate'), isFalse);
    expect(staff.payload!.containsKey('rental_monthly_rate'), isFalse);
  });

  testWidgets('the last weekly rate cannot be cleared without another rate', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _vehicle(weeklyOnly: true));
    _setText(tester, 'rental-weekly', '');
    await _save(tester);

    expect(staff.payload, isNull);
    expect(
      tester.state<FormFieldState<String>>(_field('rental-weekly')).hasError,
      isTrue,
    );
  });

  testWidgets('a negative weekly rate is rejected even with a valid month', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _identity(tester);
    _setText(tester, 'rental-monthly', '500000');
    _setText(tester, 'rental-weekly', '-1');
    await _save(tester);

    expect(staff.payload, isNull);
    expect(
      tester.state<FormFieldState<String>>(_field('rental-weekly')).hasError,
      isTrue,
    );
  });

  testWidgets('partner weekly edits use the proposed price before margin', (
    tester,
  ) async {
    final account = _PartnerRepository();
    await _mount(
      tester,
      staff: _StaffRepository(),
      account: account,
      mode: VehicleFormMode.partenaire,
      existing: _vehicle(proposedPrices: true),
    );
    expect(_text(tester, 'rental-weekly'), '150000');
    _setText(tester, 'rental-weekly', '160000');
    await _save(tester);

    expect(account.payload!['rental_weekly_rate'], 160000);
    expect(account.payload!.containsKey('rental_daily_rate'), isFalse);
    expect(account.payload!.containsKey('rental_monthly_rate'), isFalse);
    expect(account.payload!.containsKey('partner_pricing'), isFalse);
  });

  testWidgets('equipment is optional and has no automatic selections', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _identity(tester);
    _setText(tester, 'rental-weekly', '150000');
    await _equipment(tester);
    for (final id in [31, 32, 33]) {
      expect(
        tester.widget<CheckboxListTile>(_field('rental-feature-$id')).value,
        isFalse,
      );
    }
    await _equipment(tester);
    await _save(tester);

    expect(staff.payload!.containsKey('features'), isFalse);
  });

  testWidgets(
    'selected equipment survives folding and is saved as sorted IDs',
    (tester) async {
      final staff = _StaffRepository();
      await _mount(tester, staff: staff);
      await _identity(tester);
      _setText(tester, 'rental-weekly', '150000');
      await _equipment(tester);
      await _toggleEquipment(tester, 32);
      await _toggleEquipment(tester, 31);
      await _equipment(tester);
      await _equipment(tester);
      expect(
        tester.widget<CheckboxListTile>(_field('rental-feature-31')).value,
        isTrue,
      );
      await _save(tester);

      expect(staff.payload!['features'], [31, 32]);
    },
  );

  testWidgets('editing equipment preserves an older choice absent from refs', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(
      tester,
      staff: staff,
      existing: _vehicle(
        equipment: [
          {
            'id': 31,
            'name': 'Climatisation automatique',
            'category': 'confort',
          },
          {
            'id': 999,
            'name': 'Ancien accessoire de voyage',
            'category': 'autre',
          },
        ],
      ),
    );
    await _equipment(tester);
    expect(
      tester.widget<CheckboxListTile>(_field('rental-feature-999')).value,
      isTrue,
    );
    await _toggleEquipment(tester, 32);
    await _save(tester);

    expect(staff.payload!['features'], [31, 32, 999]);
  });

  testWidgets('clearing every equipment sends an explicit empty list', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(
      tester,
      staff: staff,
      existing: _vehicle(
        equipment: [
          {
            'id': 31,
            'name': 'Climatisation automatique',
            'category': 'confort',
          },
          {
            'id': 999,
            'name': 'Ancien accessoire de voyage',
            'category': 'autre',
          },
        ],
      ),
    );
    await _equipment(tester);
    await _toggleEquipment(tester, 31);
    await _toggleEquipment(tester, 999);
    await _save(tester);

    expect(staff.payload!.containsKey('features'), isTrue);
    expect(staff.payload!['features'], isEmpty);
  });

  testWidgets('equipment without a category is restored in the other group', (
    tester,
  ) async {
    final vehicle = _vehicle(
      equipment: [
        {'id': 999, 'name': 'Accessoire non classé', 'category': null},
      ],
    );
    expect(vehicle.features.single.category, 'autre');
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: vehicle);
    await _equipment(tester);

    expect(
      tester.widget<CheckboxListTile>(_field('rental-feature-999')).value,
      isTrue,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RentalVehicleRegisterPage)),
    );
    expect(find.text(l10n.vehiclesFeatureOther), findsOneWidget);
    await _save(tester);
    expect(staff.payload!.containsKey('features'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'changing vehicle identity keeps the observed equipment choices',
    (tester) async {
      final staff = _StaffRepository();
      await _mount(
        tester,
        staff: staff,
        existing: _vehicle(
          equipment: [
            {
              'id': 31,
              'name': 'Climatisation automatique',
              'category': 'confort',
            },
          ],
        ),
      );
      await _equipment(tester);
      await _toggleEquipment(tester, 32);
      await _select(tester, 'rental-brand', _honda);
      await _select(tester, 'rental-model', _civic);
      await _select(tester, 'rental-fuel', _diesel);
      await _save(tester);

      expect(staff.payload!['features'], [31, 32]);
      expect(staff.payload!['vehicle_model_id'], 12);
    },
  );

  testWidgets('a partner can select accessories without sending staff fields', (
    tester,
  ) async {
    final account = _PartnerRepository();
    await _mount(
      tester,
      staff: _StaffRepository(),
      account: account,
      mode: VehicleFormMode.partenaire,
    );
    await _identity(tester);
    _setText(tester, 'rental-weekly', '150000');
    await _equipment(tester);
    await _toggleEquipment(tester, 33);
    await _save(tester);

    expect(account.payload!['features'], [33]);
    for (final key in ['location_id', 'partner_id', 'partner_pricing']) {
      expect(account.payload!.containsKey(key), isFalse, reason: key);
    }
  });

  testWidgets('identity and one rental rate are required before sending', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _save(tester);
    expect(staff.payload, isNull);
    await _identity(tester);
    await _save(tester);
    expect(staff.payload, isNull);
    for (final key in ['rental-daily', 'rental-weekly', 'rental-monthly']) {
      expect(
        tester.state<FormFieldState<String>>(_field(key)).hasError,
        isTrue,
        reason: key,
      );
    }
    _setText(tester, 'rental-daily', '-1');
    await _save(tester);
    expect(staff.payload, isNull);
    expect(
      tester.state<FormFieldState<String>>(_field('rental-daily')).hasError,
      isTrue,
    );
  });

  testWidgets('future years and invalid optional seats block submission', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff);
    await _identity(tester);
    _setText(tester, 'rental-monthly', '500000');
    _setText(tester, 'rental-year', '${DateTime.now().year + 1}');
    _setText(tester, 'rental-seats', '71');
    await _save(tester);
    expect(staff.payload, isNull);
    expect(
      tester.state<FormFieldState<String>>(_field('rental-year')).hasError,
      isTrue,
    );
    expect(
      tester.state<FormFieldState<String>>(_field('rental-seats')).hasError,
      isTrue,
    );
    _setText(tester, 'rental-year', '2016');
    _setText(tester, 'rental-seats', '');
    await _save(tester);
    expect(staff.payload, isNotNull);
  });

  testWidgets(
    'changing brand clears the old model and offers only its models',
    (tester) async {
      await _mount(tester, staff: _StaffRepository());
      await _identity(tester);
      await _select(tester, 'rental-brand', _honda);
      final model = tester.widget<VehicleReferenceDropdown<ModelRef>>(
        _field('rental-model'),
      );
      expect(model.value, isNull);
      expect(model.items.map((value) => value.id), [12]);
      expect(
        tester
            .widget<TransmissionSelector>(_field('rental-transmission'))
            .value,
        isNull,
      );
      expect(_text(tester, 'rental-seats'), isEmpty);
    },
  );

  testWidgets(
    'editing restores visible data and omits untouched hidden fields',
    (tester) async {
      final staff = _StaffRepository();
      await _mount(tester, staff: staff, existing: _vehicle());
      expect(_text(tester, 'rental-year'), '2016');
      expect(_text(tester, 'rental-seats'), '7');
      expect(
        tester
            .widget<TransmissionSelector>(_field('rental-transmission'))
            .value,
        'cvt',
      );
      await _extras(tester);
      expect(_text(tester, 'rental-site'), 'Ouagadougou, centre-ville');
      expect(
        _text(tester, 'rental-description'),
        'Climatisation et livraison sur demande.',
      );
      await _save(tester);
      final data = staff.payload!;
      expect(staff.editedId, 71);
      expect(data.keys.toSet().intersection(_hiddenKeys), isEmpty);
      for (final key in [
        'availability',
        'rental_daily_rate',
        'rental_monthly_rate',
        'rental_weekly_rate',
        'currency',
      ]) {
        expect(data.containsKey(key), isFalse, reason: key);
      }
    },
  );

  testWidgets(
    'editing one rate omits the other rates and preserves both offer',
    (tester) async {
      final staff = _StaffRepository();
      await _mount(
        tester,
        staff: staff,
        existing: _vehicle(availability: 'both'),
      );
      _setText(tester, 'rental-monthly', '600000');
      await _save(tester);
      expect(staff.payload!['rental_monthly_rate'], 600000);
      expect(staff.payload!.containsKey('rental_daily_rate'), isFalse);
      expect(staff.payload!.containsKey('rental_weekly_rate'), isFalse);
      expect(staff.payload!.containsKey('sale_price'), isFalse);
      expect(staff.payload!.containsKey('availability'), isFalse);
    },
  );

  testWidgets('clearing one saved rate sends null while keeping the other', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _vehicle());
    _setText(tester, 'rental-daily', '');
    await _save(tester);
    expect(staff.payload!['rental_daily_rate'], isNull);
    expect(staff.payload!.containsKey('rental_daily_rate'), isTrue);
    expect(staff.payload!.containsKey('rental_monthly_rate'), isFalse);
  });

  testWidgets('changed model clears dependent technical identity explicitly', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _vehicle());
    await _select(tester, 'rental-brand', _honda);
    await _select(tester, 'rental-model', _civic);
    await _select(tester, 'rental-fuel', _petrol);
    await _save(tester);
    expect(staff.payload!['brand_id'], 4);
    expect(staff.payload!['vehicle_model_id'], 12);
    for (final key in [
      'trim_id',
      'drivetrain_id',
      'engine_code',
      'power_hp',
      'engine_displacement_cc',
      'heavy_configuration',
    ]) {
      expect(staff.payload!.containsKey(key), isTrue, reason: key);
      expect(staff.payload![key], isNull, reason: key);
    }
    expect(staff.payload!.containsKey('sale_price'), isFalse);
    expect(staff.payload!.containsKey('status'), isFalse);
  });

  testWidgets(
    'partner edits proposed rates without applying the margin twice',
    (tester) async {
      final account = _PartnerRepository();
      await _mount(
        tester,
        staff: _StaffRepository(),
        account: account,
        existing: _vehicle(proposedPrices: true),
        mode: VehicleFormMode.partenaire,
      );
      expect(
        _text(tester, 'rental-daily').replaceAll(RegExp(r'\s'), ''),
        '25000',
      );
      expect(
        _text(tester, 'rental-monthly').replaceAll(RegExp(r'\s'), ''),
        '500000',
      );
      _setText(tester, 'rental-monthly', '600000');
      await _save(tester);
      expect(account.editedId, 71);
      expect(account.payload!['rental_monthly_rate'], 600000);
      expect(account.payload!.containsKey('rental_daily_rate'), isFalse);
      for (final key in [
        'location_id',
        'partner_id',
        'deal_type',
        'partner_pricing',
        'sale_price',
      ]) {
        expect(account.payload!.containsKey(key), isFalse, reason: key);
      }
    },
  );

  testWidgets('partner success returns true to refresh the listings page', (
    tester,
  ) async {
    bool? returned;
    final account = _PartnerRepository(succeed: true);
    await _mount(
      tester,
      staff: _StaffRepository(),
      account: account,
      mode: VehicleFormMode.partenaire,
      onReturned: (value) => returned = value,
    );
    await _identity(tester);
    _setText(tester, 'rental-daily', '25000');
    await _save(tester);
    expect(returned, isTrue);
    expect(find.byKey(const ValueKey('open-rental')), findsOneWidget);
    expect(find.text('Photos destination'), findsNothing);
  });

  testWidgets('staff creation opens photos for the saved rental', (
    tester,
  ) async {
    MediaUploadConfig? media;
    await _mount(
      tester,
      staff: _StaffRepository(succeed: true),
      onMedia: (value) => media = value,
    );
    await _identity(tester);
    _setText(tester, 'rental-daily', '25000');
    await _save(tester);
    expect(find.text('Photos destination'), findsOneWidget);
    expect(media!.id, 71);
  });

  testWidgets(
    'staff editing closes the form without redoing photo onboarding',
    (tester) async {
      final staff = _StaffRepository(succeed: true);
      await _mount(tester, staff: staff, existing: _vehicle());
      _setText(tester, 'rental-daily', '30000');
      await _save(tester);
      expect(staff.editedId, 71);
      expect(find.byKey(const ValueKey('open-rental')), findsOneWidget);
      expect(find.text('Photos destination'), findsNothing);
    },
  );

  testWidgets('invalid optional data reopens a folded section before saving', (
    tester,
  ) async {
    final staff = _StaffRepository();
    await _mount(tester, staff: staff, existing: _vehicle());
    await _extras(tester);
    _setText(tester, 'rental-deposit', '-1');
    await _extras(tester);
    await _save(tester);
    expect(staff.payload, isNull);
    expect(
      tester.state<FormFieldState<String>>(_field('rental-deposit')).hasError,
      isTrue,
    );
    expect(find.byKey(const ValueKey('rental-deposit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['fr', 'en']) {
    testWidgets(
      'rental form remains usable at 320px and text x2 in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final staff = _StaffRepository();
        await _mount(tester, staff: staff, language: language, textScale: 2);
        await _identity(tester);
        _setText(tester, 'rental-monthly', '500000');
        await _extras(tester);
        await _equipment(tester);
        for (final key in [
          'rental-weekly',
          'rental-feature-31',
          'rental-feature-33',
          'rental-deposit',
          'rental-site',
          'rental-description',
          'rental-save',
        ]) {
          await tester.ensureVisible(_field(key));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: key);
        }
        await _save(tester);
        expect(staff.payload!['rental_monthly_rate'], 500000);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
