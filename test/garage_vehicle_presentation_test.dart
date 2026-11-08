import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/vehicle_card_actions.dart';
import 'package:auto/features/garage/presentation/widgets/vehicle_card_header.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _name = 'Ma Toyota familiale pour les longs trajets';
const _vehicle = OwnedVehicle(
  id: 7,
  designation: _name,
  brandId: 1,
  year: 2020,
  plateNumber: 'AB-1234-CD',
  mileageKm: 97432,
  identity: OwnedVehicleIdentity(
    brand: 'Toyota',
    model: 'Corolla Touring Sports',
  ),
  compatibilityReady: false,
);

Widget _app(
  Widget child, {
  String locale = 'fr',
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => ProviderScope(
  child: MaterialApp(
    locale: Locale(locale),
    theme: themeAutoParc(brightness),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

void main() {
  for (final locale in ['fr', 'en']) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('header $locale $brightness text scale $scale at 320px', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          await tester.pumpWidget(
            _app(
              const Card(
                child: VehicleCardHeader(
                  vehicle: _vehicle,
                  trailing: IconButton(
                    onPressed: null,
                    icon: Icon(Icons.more_vert),
                  ),
                ),
              ),
              locale: locale,
              brightness: brightness,
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          final l10n = await AppLocalizations.delegate.load(Locale(locale));
          expect(find.text(_vehicle.displayName), findsOneWidget);
          expect(
            find.text('Toyota Corolla Touring Sports · 2020'),
            findsOneWidget,
          );
          expect(find.text('AB-1234-CD'), findsOneWidget);
          expect(
            find.text(
              l10n.garageMileageValue(
                NumberFormat.decimalPattern(locale).format(97432),
              ),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final width in [268.0, 600.0]) {
      testWidgets('actions $locale at $width retain both callbacks', (
        tester,
      ) async {
        var parts = 0;
        var mileage = 0;
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: width,
              child: VehicleCardActions(
                onParts: () => parts++,
                onMileage: () => mileage++,
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        final buttons = find.byType(OutlinedButton);
        expect(buttons, findsNWidgets(2));
        final first = tester.getRect(buttons.at(0));
        final second = tester.getRect(buttons.at(1));
        if (width < 380) {
          expect(second.top, greaterThanOrEqualTo(first.bottom + 8));
          expect(second.width, first.width);
        } else {
          expect(second.top, first.top);
        }
        await tester.tap(buttons.at(0));
        await tester.tap(buttons.at(1));
        expect(parts, 1);
        expect(mileage, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('large text stacks actions even on wide screens ($locale)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          VehicleCardActions(onParts: () {}, onMileage: () {}),
          locale: locale,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      final buttons = find.byType(OutlinedButton);
      expect(
        tester.getTopLeft(buttons.at(1)).dy,
        greaterThan(tester.getBottomLeft(buttons.at(0)).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('optional facts are omitted rather than fabricated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const VehicleCardHeader(
          vehicle: OwnedVehicle(
            id: 1,
            designation: 'Toyota',
            brandId: 1,
            year: 2020,
            identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
            compatibilityReady: false,
          ),
          trailing: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.speed), findsNothing);
    expect(find.byIcon(Icons.badge_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
