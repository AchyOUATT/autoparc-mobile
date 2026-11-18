import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/garage_action_tiles.dart';
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

    for (final width in [264.0, 334.0, 600.0]) {
      testWidgets('action grid $locale at $width keeps every callback', (
        tester,
      ) async {
        final taps = <String, int>{};
        GarageAction action(String id) => GarageAction(
          key: Key(id),
          icon: Icons.speed,
          title: 'Titre $id',
          subtitle: 'Sous-titre $id',
          onTap: () => taps[id] = (taps[id] ?? 0) + 1,
        );
        await tester.pumpWidget(
          _app(
            Center(
              child: SizedBox(
                width: width,
                child: GarageActionGrid(
                  actions: [action('a'), action('b'), action('c')],
                ),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        final a = tester.getRect(find.byKey(const Key('a')));
        final b = tester.getRect(find.byKey(const Key('b')));
        final c = tester.getRect(find.byKey(const Key('c')));
        // Two columns: a and b side by side, same height; c on the next row.
        expect(b.top, a.top);
        expect(b.height, a.height);
        expect(c.top, greaterThan(a.bottom));
        for (final r in [a, b, c]) {
          expect(r.height, greaterThanOrEqualTo(48));
          expect(r.width, greaterThanOrEqualTo(48));
        }
        for (final id in ['a', 'b', 'c']) {
          await tester.tap(find.byKey(Key(id)));
        }
        expect(taps, {'a': 1, 'b': 1, 'c': 1});
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('narrow column with large text falls back to one column '
        '($locale)', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 264,
            child: GarageActionGrid(
              actions: [
                for (final id in ['a', 'b'])
                  GarageAction(
                    key: Key(id),
                    icon: Icons.speed,
                    title: 'Kilométrage',
                    subtitle: 'Relever le compteur',
                    onTap: () {},
                  ),
              ],
            ),
          ),
          locale: locale,
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(b.top, greaterThan(a.bottom));
      expect(b.width, a.width);
      expect(tester.takeException(), isNull);
    });
  }

  test('grid layout follows the column width and the text scale', () {
    expect(GarageActionGrid.layoutFor(334, 1), GarageTileLayout.compact);
    expect(GarageActionGrid.layoutFor(264, 1), GarageTileLayout.stacked);
    expect(GarageActionGrid.layoutFor(334, 1.3), GarageTileLayout.stacked);
    expect(GarageActionGrid.layoutFor(264, 1.3), isNull);
  });

  testWidgets('a tile is announced as one button with its title and subtitle', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        GarageActionTile(
          action: GarageAction(
            key: const Key('t'),
            icon: Icons.checklist_rtl,
            title: 'Contrôler mon véhicule',
            subtitle: 'Avant un voyage ou une saison',
            emphasis: GarageActionEmphasis.primary,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byKey(const Key('t')));
    expect(node.label, contains('Contrôler mon véhicule'));
    expect(node.label, contains('Avant un voyage ou une saison'));
    expect(node.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

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
