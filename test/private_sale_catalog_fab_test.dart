import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:auto/features/partner_accounts/presentation/partner_session.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_form.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/models/paged_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/polices.dart';

class FabAuth extends StateNotifier<AuthState> implements AuthNotifier {
  FabAuth(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FabPartner extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  FabPartner(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FabVehicles extends VehicleListNotifier {
  int refreshes = 0;
  @override
  PagedState<CatalogVehicleItem> build() => const PagedState.idle();
  @override
  Future<void> refresh() async => refreshes++;
}

class FabGarage extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [];
}

AuthState staff(String role) => AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Staff',
    email: 'staff@test.invalid',
    role: role,
  ),
);

const partner = PartnerSession(
  profile: PartnerProfile(
    user: {'id': 9, 'role': 'partner'},
    account: {'id': 1, 'status': 'approved', 'contact_name': 'Partner'},
  ),
);

Future<(GoRouter, FabVehicles)> open(
  WidgetTester tester, {
  AuthState auth = const AuthState(),
  PartnerSession partnerSession = const PartnerSession(),
  Locale locale = const Locale('fr'),
  bool home = false,
}) async {
  tester.view.physicalSize = const Size(500, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final vehicles = FabVehicles();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => home ? const HomePage() : const VehicleListPage(),
      ),
      GoRoute(path: '/sell', builder: (_, _) => const PrivateListingForm()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Login destination')),
      ),
      GoRoute(
        path: '/vehicles/new',
        builder: (_, _) => const Scaffold(body: Text('Stock form destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => FabAuth(auth)),
        partnerSessionProvider.overrideWith((_) => FabPartner(partnerSession)),
        vehicleListProvider.overrideWith(() => vehicles),
        dealCountProvider.overrideWith((_) async => 0),
        unreadCountProvider.overrideWith((_) async => 0),
        homeDealsProvider.overrideWith((_) async => []),
        garageProvider.overrideWith(FabGarage.new),
        catalogRefsProvider.overrideWith(
          (_) async => const CatalogRefs(
            brands: [],
            vehicleModels: [],
            trims: [],
            engineTypes: [],
            drivetrains: [],
            colors: [],
            features: [],
            locations: [],
          ),
        ),
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, vehicles);
}

void main() {
  setUpAll(chargerPolices);

  for (final role in ['admin', 'manager', 'sales']) {
    testWidgets('$role keeps stock add FAB and refreshes after return', (
      tester,
    ) async {
      final (router, vehicles) = await open(tester, auth: staff(role));
      expect(
        find.widgetWithText(FloatingActionButton, 'Ajouter'),
        findsOneWidget,
      );
      expect(find.text('Vendre ma voiture'), findsNothing);
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Ajouter'));
      await tester.pumpAndSettle();
      expect(find.text('Stock form destination'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(vehicles.refreshes, 1);
    });
  }

  for (final role in ['viewer', 'warehouse', 'mechanic']) {
    testWidgets('$role has neither catalog FAB', (tester) async {
      await open(tester, auth: staff(role));
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  }

  for (final auth in [
    const AuthState(),
    const AuthState(type: AuthType.client),
  ]) {
    testWidgets('${auth.type} selling FAB follows private-sales flag', (
      tester,
    ) async {
      await open(tester, auth: auth);
      expect(
        find.widgetWithText(FloatingActionButton, 'Vendre ma voiture'),
        privateSalesEnabled ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final auth in [
    const AuthState(),
    const AuthState(type: AuthType.client),
  ]) {
    testWidgets('partner session blocks selling FAB beside ${auth.type}', (
      tester,
    ) async {
      await open(tester, auth: auth, partnerSession: partner);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  }

  testWidgets(
    'known Firebase partner refusal never looks like a visitor sale',
    (tester) async {
      await open(
        tester,
        auth: const AuthState(clientLoginRequiresPartner: true),
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  for (final status in ['pending', 'rejected', 'suspended']) {
    testWidgets('a $status partner never gets the private selling FAB', (
      tester,
    ) async {
      await open(tester, partnerSession: PartnerSession(deniedStatus: status));
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  }

  testWidgets('a failed partner restore does not turn into a visitor sale', (
    tester,
  ) async {
    await open(
      tester,
      partnerSession: const PartnerSession(restoreFailed: true),
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('pending account validation/restoration has no selling FAB', (
    tester,
  ) async {
    await open(tester, auth: const AuthState(isLoading: true));
    expect(find.byType(FloatingActionButton), findsNothing);
    await open(tester, partnerSession: const PartnerSession(loading: true));
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  if (privateSalesEnabled) {
    testWidgets('visitor selling FAB opens sell form then customer sign-in', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Vendre ma voiture'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Se connecter pour vendre'), findsOneWidget);
      await tester.tap(find.text('Se connecter pour vendre'));
      await tester.pumpAndSettle();
      expect(find.text('Login destination'), findsOneWidget);
    });
    testWidgets('English selling FAB uses the existing translation', (
      tester,
    ) async {
      await open(
        tester,
        auth: const AuthState(type: AuthType.client),
        locale: const Locale('en'),
      );
      expect(
        find.widgetWithText(FloatingActionButton, 'Sell my car'),
        findsOneWidget,
      );
    });
  }

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    testWidgets('home no longer promotes private sales in $locale', (
      tester,
    ) async {
      await open(
        tester,
        auth: const AuthState(type: AuthType.client),
        locale: locale,
        home: true,
      );
      expect(find.text('Les voitures de particuliers'), findsNothing);
      expect(find.text('Cars from private sellers'), findsNothing);
      expect(find.text('Vendre ma voiture'), findsNothing);
      expect(find.text('Sell my car'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
