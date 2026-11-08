import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/catalog/presentation/widgets/garage_registration_prompt.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/models/paged_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;
final _part = Part.fromJson(
  _fixture('part_detail')['data'] as Map<String, dynamic>,
);
final _accessory = Accessory.fromJson(
  (_fixture('accessories_list')['data'] as List).first as Map<String, dynamic>,
);
const _vehicle = OwnedVehicle(
  id: 7,
  designation: 'Toyota Corolla',
  brandId: 1,
  year: 2020,
  identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
  compatibilityReady: false,
);

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Garage extends GarageNotifier {
  _Garage(this.source);
  final Future<List<OwnedVehicle>> Function() source;
  @override
  Future<List<OwnedVehicle>> build() => source();
  void change(AsyncValue<List<OwnedVehicle>> value) => state = value;
}

class _Parts extends PartListNotifier {
  @override
  PagedState<Part> build() => PagedState(
    items: [_part],
    total: 1,
    hasMore: false,
    isLoading: false,
    isLoadingMore: false,
  );
}

class _Accessories extends AccessoryListNotifier {
  @override
  PagedState<Accessory> build() => PagedState(
    items: [_accessory],
    total: 1,
    hasMore: false,
    isLoading: false,
    isLoadingMore: false,
  );
}

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  required String kind,
  required Locale locale,
  required _Garage garage,
  AuthState auth = const AuthState(type: AuthType.client),
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool componentOnly = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((_) => _Auth(auth)),
      garageProvider.overrideWith(() => garage),
      partListProvider.overrideWith(_Parts.new),
      accessoryListProvider.overrideWith(_Accessories.new),
      categoriesAvecPiecesProvider.overrideWith((_) async => []),
      categoriesAccessoiresOccupeesProvider.overrideWith((_) async => {}),
      compatiblePartIdsProvider.overrideWith((_, _) async => {}),
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
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => componentOnly
            ? const Scaffold(body: GarageRegistrationPrompt())
            : kind == 'parts'
            ? const PartListPage()
            : const AccessoryListPage(),
      ),
      GoRoute(
        path: '/garage/add',
        builder: (_, _) => const Scaffold(body: Text('garage-add-route')),
      ),
    ],
  );
  addTearDown(() async {
    // The existing parts fitment banner clears selection after deactivate.
    // Keep its container alive until that frame has completed.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    router.dispose();
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: themeAutoParc(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final kind in ['parts', 'accessories']) {
    for (final locale in [const Locale('fr'), const Locale('en')]) {
      for (final state in ['empty', 'owned', 'loading', 'error']) {
        testWidgets('$kind $locale garage=$state preserves search and offers', (
          tester,
        ) async {
          final pending = Completer<List<OwnedVehicle>>();
          final garage = _Garage(
            () => switch (state) {
              'empty' => Future.value([]),
              'owned' => Future.value([_vehicle]),
              'error' => Future.error(StateError('Offline')),
              _ => pending.future,
            },
          );
          final container = await _mount(
            tester,
            kind: kind,
            locale: locale,
            garage: garage,
          );
          final l10n = await AppLocalizations.delegate.load(locale);
          expect(
            find.text(l10n.catalogGarageInviteBody),
            state == 'empty' ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(kind == 'parts' ? _part.name : _accessory.name),
            findsOneWidget,
          );
          expect(find.byType(SearchBar), findsOneWidget);
          await tester.enterText(find.byType(SearchBar), 'filtre');
          await tester.pumpAndSettle();
          expect(
            kind == 'parts'
                ? container.read(partFilterProvider).search
                : container.read(accessoryFilterProvider).search,
            'filtre',
          );
          if (state == 'empty') {
            await tester.tap(
              find.widgetWithText(TextButton, l10n.garageAddVehicleAction),
            );
            await tester.pumpAndSettle();
            expect(find.text('garage-add-route'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final role in ['visitor', 'staff', 'unverified']) {
      testWidgets(
        '$kind never assumes an unknown/staff session has an empty garage: $role',
        (tester) async {
          final auth = switch (role) {
            'staff' => const AuthState(
              type: AuthType.staff,
              staffUser: StaffUser(
                id: 1,
                name: 'Staff',
                email: 'staff@example.test',
                role: 'admin',
              ),
            ),
            'unverified' => const AuthState(
              type: AuthType.client,
              verified: false,
            ),
            _ => const AuthState(),
          };
          await _mount(
            tester,
            kind: kind,
            locale: const Locale('fr'),
            garage: _Garage(() async => []),
            auth: auth,
          );
          final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
          expect(find.text(l10n.catalogGarageInviteBody), findsNothing);
          expect(find.byType(SearchBar), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '$kind hides stale empty data during refresh/error and after adding a vehicle',
      (tester) async {
        final garage = _Garage(() async => []);
        await _mount(
          tester,
          kind: kind,
          locale: const Locale('fr'),
          garage: garage,
        );
        final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
        expect(find.text(l10n.catalogGarageInviteBody), findsOneWidget);
        garage.change(
          const AsyncLoading<List<OwnedVehicle>>().copyWithPrevious(
            const AsyncData([]),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.catalogGarageInviteBody), findsNothing);
        garage.change(
          AsyncError<List<OwnedVehicle>>(
            StateError('Offline'),
            StackTrace.current,
          ).copyWithPrevious(const AsyncData([])),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.catalogGarageInviteBody), findsNothing);
        garage.change(const AsyncData([_vehicle]));
        await tester.pumpAndSettle();
        expect(find.text(l10n.catalogGarageInviteBody), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'compact invitation keeps offers usable at 320px $locale $brightness',
        (tester) async {
          tester.view.physicalSize = const Size(320, 720);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await _mount(
            tester,
            kind: 'accessories',
            locale: locale,
            garage: _Garage(() async => []),
            brightness: brightness,
            scale: 1.5,
          );
          final l10n = await AppLocalizations.delegate.load(locale);
          expect(find.text(l10n.catalogGarageInviteBody), findsOneWidget);
          expect(find.byType(SearchBar), findsOneWidget);
          expect(find.text(_accessory.name), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'own vehicle suppresses invitation even with no selected vehicle',
    (tester) async {
      final container = await _mount(
        tester,
        kind: 'parts',
        locale: const Locale('fr'),
        garage: _Garage(() async => [_vehicle]),
        componentOnly: true,
      );
      expect(container.read(selectedGarageVehicleProvider), isNull);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.catalogGarageInviteBody), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
