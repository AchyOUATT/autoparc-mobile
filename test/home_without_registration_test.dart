import 'package:auto/core/providers/shell_scaffold_provider.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/update/version_minimale.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/garage_page.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyGarage extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [];
}

class _PopulatedGarage extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [
    const OwnedVehicle(
      id: 42,
      designation: 'Toyota Corolla',
      brandId: 1,
      year: 2020,
      mileageKm: 97432,
      identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
      compatibilityReady: true,
      engineDataProvided: true,
    ),
  ];
}

Future<void> _mount(
  WidgetTester tester, {
  required Locale locale,
  required AuthState auth,
  Brightness brightness = Brightness.light,
  void Function()? onGarageRead,
  bool populated = false,
}) async {
  final shellKey = GlobalKey<ScaffoldState>();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          key: shellKey,
          drawer: const AppDrawer(),
          body: const HomePage(),
        ),
      ),
      GoRoute(path: '/garage', builder: (_, _) => const GaragePage()),
      GoRoute(
        path: '/garage/add',
        builder: (_, _) => const Scaffold(body: Text('add-vehicle-route')),
      ),
      for (final path in ['/parts', '/vehicles', '/accessories', '/needs/new'])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(path)),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shellScaffoldKeyProvider.overrideWithValue(shellKey),
        authProvider.overrideWith((_) => _Auth(auth)),
        garageProvider.overrideWith(() {
          onGarageRead?.call();
          return populated ? _PopulatedGarage() : _EmptyGarage();
        }),
        homeDealsProvider.overrideWith((_) async => []),
        homeCompatiblePartsProvider.overrideWith((_, _) async => []),
        unreadCountProvider.overrideWith((_) async => 0),
        espacePartenaireOuvertProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: themeAutoParc(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final brightness in Brightness.values) {
      for (final client in [false, true]) {
        testWidgets(
          'no registration pitch: $locale $brightness client=$client',
          (tester) async {
            tester.view.physicalSize = const Size(320, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            var garageReads = 0;
            await _mount(
              tester,
              locale: locale,
              brightness: brightness,
              auth: AuthState(type: client ? AuthType.client : AuthType.none),
              onGarageRead: () => garageReads++,
            );
            final l10n = await AppLocalizations.delegate.load(locale);
            expect(find.text(l10n.homeAddVehicleTitle), findsNothing);
            expect(find.text(l10n.homeAddVehicleBody), findsNothing);
            expect(find.text(l10n.homeAddVehicleCta), findsNothing);
            expect(find.text(l10n.commonParts), findsOneWidget);
            expect(find.text(l10n.commonAccessories), findsOneWidget);
            expect(find.text(l10n.homeNeedPrompt), findsOneWidget);
            // No empty registration-card space above the browse destinations.
            expect(
              tester.getTopLeft(find.text(l10n.commonParts)).dy,
              lessThan(220),
            );
            expect(garageReads, client ? 1 : 0);
            await tester.tap(find.text(l10n.commonParts));
            await tester.pumpAndSettle();
            expect(find.text('/parts'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('garage menu still opens garage and its add action ($locale)', (
      tester,
    ) async {
      await _mount(
        tester,
        locale: locale,
        auth: const AuthState(type: AuthType.client),
      );
      final l10n = await AppLocalizations.delegate.load(locale);
      await tester.tap(find.byTooltip(l10n.commonMenuTooltip));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.shellMyGarage));
      await tester.tap(find.text(l10n.shellMyGarage));
      await tester.pumpAndSettle();
      expect(find.byType(GaragePage), findsOneWidget);
      expect(find.text(l10n.garageEmptyTitle), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.garageAddVehicleAction),
      );
      await tester.pumpAndSettle();
      expect(find.text('add-vehicle-route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('existing vehicle context stays on home ($locale)', (
      tester,
    ) async {
      await _mount(
        tester,
        locale: locale,
        populated: true,
        auth: const AuthState(type: AuthType.client),
      );
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text('Toyota Corolla'), findsOneWidget);
      expect(find.text(l10n.homeUpdateMileage), findsOneWidget);
      expect(find.text(l10n.homeAddVehicleTitle), findsNothing);
      expect(find.text(l10n.homeAddVehicleCta), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('existing needs entry remains usable ($locale)', (
      tester,
    ) async {
      await _mount(tester, locale: locale, auth: const AuthState());
      final l10n = await AppLocalizations.delegate.load(locale);
      await tester.tap(find.text(l10n.homeNeedPrompt));
      await tester.pumpAndSettle();
      expect(find.text('/needs/new'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
