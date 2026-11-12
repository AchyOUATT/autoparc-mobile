import 'dart:async';

import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/providers/shell_scaffold_provider.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/update/version_minimale.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/garage_page.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/onboarding/data/profil_service.dart';
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

class _PendingGarage extends GarageNotifier {
  _PendingGarage(this.porte);
  final Completer<List<OwnedVehicle>> porte;
  @override
  Future<List<OwnedVehicle>> build() => porte.future;
}

class _FailingGarage extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async {
    throw const ApiException(statusCode: 500, message: 'Serveur indisponible.');
  }
}

enum _Garage { empty, populated, pending, failing }

Future<void> _mount(
  WidgetTester tester, {
  required Locale locale,
  required AuthState auth,
  Brightness brightness = Brightness.light,
  void Function()? onGarageRead,
  _Garage garage = _Garage.empty,
  Completer<List<OwnedVehicle>>? pending,
  ProfilUtilisateur? profil,
  bool settle = true,
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
        if (profil != null) profilInitialProvider.overrideWithValue(profil),
        garageProvider.overrideWith(() {
          onGarageRead?.call();
          return switch (garage) {
            _Garage.empty => _EmptyGarage(),
            _Garage.populated => _PopulatedGarage(),
            _Garage.pending => _PendingGarage(pending!),
            _Garage.failing => _FailingGarage(),
          };
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  const employe = StaffUser(
    id: 1,
    name: 'Awa Traoré',
    email: 'awa@autoparc.bf',
    role: 'admin',
  );

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final brightness in Brightness.values) {
      for (final client in [false, true]) {
        testWidgets(
          'invitation si garage vide: $locale $brightness client=$client',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
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
            expect(find.text(l10n.homeAddVehicleTitle), findsOneWidget);
            expect(find.text(l10n.homeAddVehicleBody), findsOneWidget);
            expect(find.text(l10n.homeAddVehicleCta), findsOneWidget);
            expect(find.text(l10n.commonParts), findsOneWidget);
            expect(find.text(l10n.commonAccessories), findsOneWidget);
            expect(find.text(l10n.homeNeedPrompt), findsOneWidget);
            expect(tester.takeException(), isNull);
            expect(garageReads, client ? 1 : 0);
            await tester.ensureVisible(find.text(l10n.homeAddVehicleCta));
            await tester.tap(find.text(l10n.homeAddVehicleCta));
            await tester.pumpAndSettle();
            expect(find.text('add-vehicle-route'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('un véhicule déjà enregistré masque l\'invitation ($locale)', (
      tester,
    ) async {
      await _mount(
        tester,
        locale: locale,
        garage: _Garage.populated,
        auth: const AuthState(type: AuthType.client),
      );
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text('Toyota Corolla'), findsOneWidget);
      expect(find.text(l10n.homeUpdateMileage), findsOneWidget);
      expect(find.text(l10n.homeAddVehicleTitle), findsNothing);
      expect(find.text(l10n.homeAddVehicleCta), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'le menu Mon garage et l\'ajout restent disponibles ($locale)',
      (tester) async {
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
      },
    );

    testWidgets('le besoin et le catalogue restent utilisables ($locale)', (
      tester,
    ) async {
      await _mount(tester, locale: locale, auth: const AuthState());
      final l10n = await AppLocalizations.delegate.load(locale);
      await tester.ensureVisible(find.text(l10n.commonParts));
      await tester.tap(find.text(l10n.commonParts));
      await tester.pumpAndSettle();
      expect(find.text('/parts'), findsOneWidget);
    });
  }

  testWidgets('le personnel ne voit pas l\'invitation', (tester) async {
    await _mount(
      tester,
      locale: const Locale('fr'),
      auth: const AuthState(type: AuthType.staff, staffUser: employe),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.homeAddVehicleTitle), findsNothing);
    expect(find.text(l10n.homeAddVehicleCta), findsNothing);
    expect(find.text(l10n.commonParts), findsOneWidget);
  });

  testWidgets(
    'un vendeur sans session voit sa carte, pas l\'invitation garage',
    (tester) async {
      await _mount(
        tester,
        locale: const Locale('fr'),
        auth: const AuthState(),
        profil: ProfilUtilisateur.vendeur,
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.byKey(const Key('accueil-carte-vendeur')), findsOneWidget);
      expect(find.text(l10n.homeAddVehicleTitle), findsNothing);
      expect(find.text(l10n.homeAddVehicleCta), findsNothing);
    },
  );

  testWidgets('aucun flash d\'invitation pendant le chargement du garage', (
    tester,
  ) async {
    final porte = Completer<List<OwnedVehicle>>();
    await _mount(
      tester,
      locale: const Locale('fr'),
      auth: const AuthState(type: AuthType.client),
      garage: _Garage.pending,
      pending: porte,
      settle: false,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.homeAddVehicleTitle), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    porte.complete([]);
    await tester.pumpAndSettle();
    expect(find.text(l10n.homeAddVehicleTitle), findsOneWidget);
  });

  testWidgets('une erreur garage ne se déguise pas en invitation', (
    tester,
  ) async {
    await _mount(
      tester,
      locale: const Locale('fr'),
      auth: const AuthState(type: AuthType.client),
      garage: _Garage.failing,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.homeAddVehicleTitle), findsNothing);
    expect(find.text(l10n.homeGarageUnavailable), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
  });
}
