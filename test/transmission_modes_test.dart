import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/l10n/transmission_labels.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/libelles_vehicule.dart';
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_labels.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/vehicle_classification_selection.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/features/vehicles/presentation/widgets/vehicle_identity_fields.dart';
import 'package:auto/features/vehicles/presentation/widgets/transmission_selector.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/l10n/app_localizations_en.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _labelsFr = {
  'manual': 'Manuelle',
  'automatic': 'Automatique',
  'automated_manual': 'Robotisée (AMT)',
  'dual_clutch': 'Double embrayage (DCT)',
  'cvt': 'Variation continue (CVT)',
  'e_cvt': 'Hybride e-CVT',
  'single_speed': 'Rapport unique',
};
const _labelsEn = {
  'manual': 'Manual',
  'automatic': 'Automatic',
  'automated_manual': 'Automated manual (AMT)',
  'dual_clutch': 'Dual-clutch (DCT)',
  'cvt': 'Continuously variable (CVT)',
  'e_cvt': 'Hybrid e-CVT',
  'single_speed': 'Single-speed',
};
const _brand = BrandRef(id: 3, name: 'Toyota', isActive: true);
const _model = ModelRef(id: 11, brandId: 3, name: 'Corolla');
const _engine = EngineTypeRef(
  id: 5,
  code: 'petrol',
  label: 'Essence',
  usesFuel: true,
  usesBattery: false,
);
const _refs = CatalogRefs(
  brands: [_brand],
  vehicleModels: [_model],
  trims: [],
  engineTypes: [_engine],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

Vehicle _vehicle(String transmission) {
  final json =
      (jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
              as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
  json.addAll({
    'brand_id': _brand.id,
    'vehicle_model_id': _model.id,
    'engine_type_id': _engine.id,
    'trim_id': null,
  });
  (json['technical'] as Map<String, dynamic>)['transmission'] = transmission;
  (json['identity'] as Map<String, dynamic>)['year'] = 2016;
  return Vehicle.fromJson(json);
}

class _Vehicles extends VehicleAdminRepository {
  _Vehicles() : super(ApiClient(), CatalogLocalCache());
  Map<String, dynamic>? saved;

  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    saved = Map<String, dynamic>.from(data);
    throw const ApiException(message: 'Captured request', statusCode: 422);
  }
}

class _Partners extends PartnerRepository {
  _Partners() : super(ApiClient());

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

Future<void> _registration(
  WidgetTester tester,
  _Vehicles repository, {
  String transmission = 'automatic',
  Locale locale = const Locale('fr'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRefsProvider.overrideWith((_) async => _refs),
        countriesProvider.overrideWith((_) async => []),
        vehicleAdminRepositoryProvider.overrideWithValue(repository),
        partnerRepositoryProvider.overrideWithValue(_Partners()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: VehicleRegisterPage(existing: _vehicle(transmission)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _chip(String label) =>
    find.widgetWithText(ChoiceChip, label, skipOffstage: false);

Finder _automaticDetail() => find.descendant(
  of: find.byType(TransmissionSelector, skipOffstage: false),
  matching: find.byType(DropdownButtonFormField<String>, skipOffstage: false),
  skipOffstage: false,
);

DropdownButton<String> _detailButton(WidgetTester tester) =>
    tester.widget<DropdownButton<String>>(
      find.descendant(
        of: _automaticDetail(),
        matching: find.byType(DropdownButton<String>, skipOffstage: false),
        skipOffstage: false,
      ),
    );

void main() {
  test(
    'catalogue and private details name every transmission in both languages',
    () {
      for (final pair in [
        (l10n: AppLocalizationsFr() as AppLocalizations, labels: _labelsFr),
        (l10n: AppLocalizationsEn() as AppLocalizations, labels: _labelsEn),
      ]) {
        expect(transmissionCodes.toSet(), pair.labels.keys.toSet());
        for (final entry in pair.labels.entries) {
          expect(transmissionLabel(entry.key, pair.l10n), entry.value);
          expect(libelleTransmission(pair.l10n, entry.key), entry.value);
          expect(
            privateListingTransmissionLabel(entry.key, pair.l10n),
            entry.value,
          );
        }
        expect(
          transmissionLabel('future_gearbox', pair.l10n),
          'future_gearbox',
        );
        expect(
          libelleTransmission(pair.l10n, 'future_gearbox'),
          'future_gearbox',
        );
        expect(
          privateListingTransmissionLabel('future_gearbox', pair.l10n),
          'future_gearbox',
        );
      }
    },
  );

  for (final language in ['fr', 'en']) {
    testWidgets(
      'staff selects a simple group and optional detail in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repository = _Vehicles();
        await _registration(
          tester,
          repository,
          locale: Locale(language),
          textScale: 1.5,
        );
        for (var step = 0; step < 2; step++) {
          tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
          await tester.pumpAndSettle();
        }
        final labels = language == 'fr' ? _labelsFr : _labelsEn;
        final groupChips = find.descendant(
          of: find.byType(TransmissionSelector, skipOffstage: false),
          matching: find.byType(ChoiceChip, skipOffstage: false),
          skipOffstage: false,
        );
        expect(groupChips, findsNWidgets(2));
        expect(_chip(labels['manual']!), findsOneWidget);
        expect(_chip(labels['automatic']!), findsOneWidget);
        expect(_chip(labels['automated_manual']!), findsNothing);
        expect(
          _detailButton(tester).items!.map((item) => item.value).toSet(),
          labels.keys.where((code) => code != 'manual').toSet(),
        );
        await tester.ensureVisible(_automaticDetail());
      await tester.pumpAndSettle();
        await tester.tap(_automaticDetail());
        await tester.pumpAndSettle();
        await tester.tap(find.text(labels['automated_manual']!).last);
        await tester.pumpAndSettle();
        expect(
          tester.state<FormFieldState<String>>(_automaticDetail()).value,
          'automated_manual',
        );
        // The collapsed technical summary must describe the selected AMT.
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
        final summary =
            tester.widget<Stepper>(find.byType(Stepper)).steps[2].subtitle
                as Text;
        expect(summary.data, contains(labels['automated_manual']!));
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
        expect(
          repository.saved,
          containsPair('transmission', 'automated_manual'),
        );
      },
    );
  }

  for (final code in transmissionCodes) {
    testWidgets('editing preserves and submits the saved $code gearbox', (
      tester,
    ) async {
      final repository = _Vehicles();
      await _registration(tester, repository, transmission: code);
      expect(
        tester
            .widget<ChoiceChip>(
              _chip(_labelsFr[code == 'manual' ? 'manual' : 'automatic']!),
            )
            .selected,
        isTrue,
      );
      if (code != 'manual') {
        expect(
          tester.state<FormFieldState<String>>(_automaticDetail()).value,
          code,
        );
      } else {
        expect(_automaticDetail(), findsNothing);
      }
      for (var step = 0; step < 4; step++) {
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
      }
      expect(repository.saved, containsPair('transmission', code));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an unknown saved mode is not summarized as automatic', (
    tester,
  ) async {
    await _registration(tester, _Vehicles(), transmission: 'future_gearbox');
    final summary =
        tester.widget<Stepper>(find.byType(Stepper)).steps[2].subtitle as Text;
    expect(summary.data, contains('future_gearbox'));
    expect(summary.data, isNot(contains('Automatique')));
    expect(tester.widget<ChoiceChip>(_chip('Automatique')).selected, isFalse);
  });

  testWidgets('private identity groups gearboxes and retains edited e-CVT', (
    tester,
  ) async {
    final year = TextEditingController(text: '2016');
    final mileage = TextEditingController();
    final freeModel = TextEditingController();
    addTearDown(year.dispose);
    addTearDown(mileage.dispose);
    addTearDown(freeModel.dispose);
    final selection = VehicleClassificationSelection.fromIds(
      _refs,
      brandId: _brand.id,
      modelId: _model.id,
      engineTypeId: _engine.id,
    );
    String? selected = 'e_cvt';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => VehicleIdentityFields(
                refs: _refs,
                selection: selection,
                yearController: year,
                mileageController: mileage,
                freeModelController: freeModel,
                freeModel: false,
                onFreeModelChanged: (_) {},
                onChanged: () => setState(() {}),
                onModelChanged: () {},
                color: null,
                onColorChanged: (_) {},
                transmission: selected,
                onTransmissionChanged: (value) =>
                    setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = _automaticDetail();
    expect(tester.state<FormFieldState<String>>(field).value, 'e_cvt');
    final button = tester.widget<DropdownButton<String>>(
      find.descendant(of: field, matching: find.byType(DropdownButton<String>)),
    );
    expect(
      button.items!.map((item) => item.value).toSet(),
      _labelsFr.keys.where((code) => code != 'manual').toSet(),
    );
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Robotisée (AMT)').last);
    await tester.pumpAndSettle();
    expect(selected, 'automated_manual');
    await tester.tap(_chip('Automatique'));
    await tester.pumpAndSettle();
    expect(
      selected,
      'automated_manual',
      reason: 'Selecting the existing group must keep its precision.',
    );
    await tester.tap(_chip('Manuelle'));
    await tester.pumpAndSettle();
    expect(selected, 'manual');
    expect(_automaticDetail(), findsNothing);
    await tester.tap(_chip('Automatique'));
    await tester.pumpAndSettle();
    expect(selected, 'automatic');
    expect(
      tester.state<FormFieldState<String>>(_automaticDetail()).value,
      'automatic',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('transmission-clear')),
    );
    await tester.tap(find.byKey(const ValueKey('transmission-clear')));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(_automaticDetail(), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
