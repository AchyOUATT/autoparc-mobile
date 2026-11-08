import 'dart:async';

import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/pages/rental_vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/pages/equipment_register_page.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_registration_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

class _GuestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _GuestAuth() : super(const AuthState());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Vehicle _vehicle(String availability) => Vehicle.fromJson({
  'id': 17,
  'reference': 'VH-EXISTING',
  'designation': 'Toyota Corolla 2020',
  'registration_status': 'registered',
  'vehicle_type': 'passenger',
  'identity': {'brand': 'Toyota', 'model': 'Corolla', 'year': 2020},
  'commercial': {
    'availability': availability,
    'condition': 'used',
    'status': 'in_stock',
    'sale_price': availability == 'rent' ? null : 8000000,
    'rental_daily_rate': availability == 'sale' ? null : 25000,
  },
});

Future<void> _mount(
  WidgetTester tester, {
  Vehicle? existing,
  VehicleFormMode mode = VehicleFormMode.personnel,
  Locale locale = const Locale('fr'),
  double textScale = 1,
  Widget? home,
}) async {
  // Navigation tests stop at the destination page. Pending references avoid
  // unrelated repository calls while still mounting each real form widget.
  final references = Completer<CatalogRefs>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _GuestAuth()),
        catalogRefsProvider.overrideWith((_) => references.future),
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
        home: home ?? VehicleRegistrationPage(existing: existing, mode: mode),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(chargerPolices);

  for (final language in ['fr', 'en']) {
    testWidgets(
      'purpose choices fit a narrow screen with large text in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(tester, locale: Locale(language), textScale: 2);
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(VehicleRegistrationPage)),
        );
        expect(
          find.text(l10n.vehicleRegistrationChoosePurpose),
          findsOneWidget,
        );
        expect(find.text(l10n.vehicleRegistrationRentalTitle), findsOneWidget);
        final sale = find.byKey(const ValueKey('vehicle-registration-sale'));
        await tester.scrollUntilVisible(sale, 250);
        await tester.pumpAndSettle();
        expect(find.text(l10n.vehicleRegistrationSaleTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in VehicleFormMode.values) {
    testWidgets('new $mode rental opens only the simplified rental form', (
      tester,
    ) async {
      await _mount(tester, mode: mode);
      await tester.tap(
        find.byKey(const ValueKey('vehicle-registration-rental')),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('vehicle-registration-road')));
      await tester.pump();
      final rental = tester.widget<RentalVehicleRegisterPage>(
        find.byType(RentalVehicleRegisterPage),
      );
      expect(rental.mode, mode);
      expect(rental.existing, isNull);
      expect(find.byType(VehicleRegisterPage), findsNothing);
      expect(
        find.byKey(const ValueKey('vehicle-registration-choice')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('new $mode sale opens the sale-only form', (tester) async {
      await _mount(tester, mode: mode);
      final sale = find.byKey(const ValueKey('vehicle-registration-sale'));
      await tester.scrollUntilVisible(sale, 250);
      await tester.tap(sale);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('vehicle-registration-road')));
      await tester.pump();
      final form = tester.widget<VehicleRegisterPage>(
        find.byType(VehicleRegisterPage),
      );
      expect(form.mode, mode);
      expect(form.saleOnly, isTrue);
      expect(form.existing, isNull);
      expect(find.byType(RentalVehicleRegisterPage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final mode in VehicleFormMode.values) {
    for (final purpose in ['sale', 'rental']) {
      testWidgets('new $mode $purpose can register equipment', (tester) async {
        await _mount(tester, mode: mode);
        final choice = find.byKey(ValueKey('vehicle-registration-$purpose'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('vehicle-registration-family')),
          findsOneWidget,
        );
        final equipment = find.byKey(
          const ValueKey('vehicle-registration-equipment'),
        );
        await tester.ensureVisible(equipment);
        await tester.tap(equipment);
        await tester.pump();
        final form = tester.widget<EquipmentRegisterPage>(
          find.byType(EquipmentRegisterPage),
        );
        expect(form.mode, mode);
        expect(form.initialAvailability, purpose == 'sale' ? 'sale' : 'rent');
        expect(find.byType(VehicleRegisterPage), findsNothing);
        expect(find.byType(RentalVehicleRegisterPage), findsNothing);
      });
    }
  }

  testWidgets('editing a rental skips the choice and preserves the vehicle', (
    tester,
  ) async {
    final existing = _vehicle('rent');
    await _mount(tester, existing: existing);
    final form = tester.widget<RentalVehicleRegisterPage>(
      find.byType(RentalVehicleRegisterPage),
    );
    expect(identical(form.existing, existing), isTrue);
    expect(
      find.byKey(const ValueKey('vehicle-registration-choice')),
      findsNothing,
    );
    expect(find.byType(VehicleRegisterPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a sale keeps the sale-only form', (tester) async {
    final existing = _vehicle('sale');
    await _mount(tester, existing: existing);
    final form = tester.widget<VehicleRegisterPage>(
      find.byType(VehicleRegisterPage),
    );
    expect(identical(form.existing, existing), isTrue);
    expect(form.saleOnly, isTrue);
    expect(
      find.byKey(const ValueKey('vehicle-registration-choice')),
      findsNothing,
    );
  });

  testWidgets(
    'editing a legacy mixed offer retains its complete form and prices',
    (tester) async {
      final existing = _vehicle('both');
      await _mount(tester, existing: existing);
      final form = tester.widget<VehicleRegisterPage>(
        find.byType(VehicleRegisterPage),
      );
      expect(identical(form.existing, existing), isTrue);
      expect(form.saleOnly, isFalse);
      expect(form.existing!.commercial.salePrice, 8000000);
      expect(form.existing!.commercial.rentalDailyRate, 25000);
      expect(find.byType(RentalVehicleRegisterPage), findsNothing);
      expect(
        find.byKey(const ValueKey('vehicle-registration-choice')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'partner purpose selection keeps the original route save result',
    (tester) async {
      var completions = 0;
      bool? saved;
      await _mount(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const VehicleRegistrationPage(
                      mode: VehicleFormMode.partenaire,
                    ),
                  ),
                );
                completions++;
              },
              child: const Text('Open registration'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open registration'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('vehicle-registration-rental')),
      );
      await tester.pump();
      expect(completions, 0);

      await tester.tap(find.byKey(const ValueKey('vehicle-registration-road')));
      await tester.pump();

      Navigator.of(
        tester.element(find.byType(RentalVehicleRegisterPage)),
      ).pop(true);
      await tester.pumpAndSettle();
      expect(completions, 1);
      expect(saved, isTrue);
      expect(find.text('Open registration'), findsOneWidget);
    },
  );
}
