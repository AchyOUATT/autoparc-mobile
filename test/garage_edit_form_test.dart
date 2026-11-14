import 'dart:async';

import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/add_vehicle_to_garage_page.dart';
import 'package:auto/features/garage/presentation/pages/edit_vehicle_in_garage_page.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const toyota = BrandRef(id: 1, name: 'Toyota', isActive: true);
const hilux = ModelRef(
  id: 40,
  brandId: 1,
  name: 'Hilux',
  productionStart: 2015,
  defaultVehicleType: 'utility',
);
const corolla = ModelRef(
  id: 10,
  brandId: 1,
  name: 'Corolla',
  productionStart: 2019,
  defaultVehicleType: 'passenger',
);

const refs = CatalogRefs(
  brands: [toyota],
  vehicleModels: [hilux, corolla],
  trims: [],
  engineTypes: [],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

const utilitaire = OwnedVehicle(
  id: 12,
  designation: 'Toyota Hilux',
  nickname: 'Le pick-up',
  brandId: 1,
  vehicleModelId: 40,
  year: 2018,
  plateNumber: 'AB-1234-CD',
  mileageKm: 97432,
  identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Hilux'),
  compatibilityReady: true,
);

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(type: AuthType.client));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo extends Fake implements GarageRepository {
  _Repo({this.vehicles = const [], this.getVehicleResult});

  final List<OwnedVehicle> vehicles;
  final Future<OwnedVehicle> Function(int id)? getVehicleResult;
  final updates = <MapEntry<int, Map<String, dynamic>>>[];
  final additions = <Map<String, dynamic>>[];

  @override
  Future<List<OwnedVehicle>> getVehicles() async => vehicles;

  @override
  Future<OwnedVehicle> getVehicle(int id) {
    if (getVehicleResult != null) return getVehicleResult!(id);
    try {
      return Future.value(vehicles.firstWhere((vehicle) => vehicle.id == id));
    } catch (_) {
      return Future.error(
        const ApiException(statusCode: 404, message: 'missing'),
      );
    }
  }

  @override
  Future<OwnedVehicle> updateVehicle(
    int id,
    Map<String, dynamic> payload,
  ) async {
    updates.add(MapEntry(id, Map<String, dynamic>.from(payload)));
    return vehicles.cast<OwnedVehicle?>().firstWhere(
          (vehicle) => vehicle?.id == id,
          orElse: () => utilitaire,
        ) ??
        utilitaire;
  }

  @override
  Future<OwnedVehicle> addVehicle(Map<String, dynamic> payload) async {
    additions.add(payload);
    fail('l’édition ne doit pas créer un nouveau véhicule');
  }
}

Widget _app({
  required Widget home,
  required _Repo repo,
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [
      catalogRefsProvider.overrideWith((_) async => refs),
      authProvider.overrideWith((_) => _Auth()),
      garageRepositoryProvider.overrideWithValue(repo),
      ...extra,
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        '/': (_) => const SizedBox.shrink(),
        '/edit': (_) => home,
      },
      initialRoute: '/edit',
    ),
  );
}

Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> enlargeScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'édition d’un ancien utilitaire sans type : le type et le modèle restent, seul le surnom change',
    (tester) async {
      await enlargeScreen(tester);
      final repo = _Repo(vehicles: [utilitaire]);
      await tester.pumpWidget(
        _app(
          home: const AddVehicleToGaragePage(existing: utilitaire),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final utility = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Utilitaire'),
      );
      expect(utility.selected, isTrue);
      expect(find.textContaining('Hilux'), findsWidgets);
      expect(find.text('Le pick-up'), findsWidgets);

      await tester.enterText(_field('Surnom'), 'Pick-up du service');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Modifier le véhicule'),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Modifier le véhicule'),
      );
      await tester.pumpAndSettle();

      expect(repo.additions, isEmpty);
      expect(repo.updates, hasLength(1));
      expect(repo.updates.single.key, 12);
      final payload = repo.updates.single.value;
      expect(payload['vehicle_type'], 'utility');
      expect(
        payload.containsKey('vehicle_type') &&
            payload['vehicle_type'] == 'passenger',
        isFalse,
      );
      expect(payload['vehicle_model_id'], 40);
      expect(payload['nickname'], 'Pick-up du service');
      expect(payload['plate_number'], 'AB-1234-CD');
      expect(payload['mileage_km'], 97432);
    },
  );

  testWidgets(
    'en édition, vider la plaque, le surnom ou le kilométrage envoie null',
    (tester) async {
      await enlargeScreen(tester);
      final repo = _Repo(vehicles: [utilitaire]);
      await tester.pumpWidget(
        _app(
          home: const AddVehicleToGaragePage(existing: utilitaire),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_field('Surnom'), '');
      await tester.enterText(_field('Plaque d\'immatriculation'), '');
      await tester.enterText(_field('Kilométrage actuel'), '');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Modifier le véhicule'),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Modifier le véhicule'),
      );
      await tester.pumpAndSettle();

      expect(repo.updates, hasLength(1));
      expect(repo.updates.single.value['nickname'], isNull);
      expect(repo.updates.single.value.containsKey('nickname'), isTrue);
      expect(repo.updates.single.value['plate_number'], isNull);
      expect(repo.updates.single.value['mileage_km'], isNull);
    },
  );

  testWidgets('en édition, un kilométrage de 0 km est envoyé comme 0', (
    tester,
  ) async {
    await enlargeScreen(tester);
    final repo = _Repo(vehicles: [utilitaire]);
    await tester.pumpWidget(
      _app(
        home: const AddVehicleToGaragePage(existing: utilitaire),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field('Kilométrage actuel'), '0');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Modifier le véhicule'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Modifier le véhicule'));
    await tester.pumpAndSettle();

    expect(repo.updates, hasLength(1));
    expect(repo.updates.single.value['mileage_km'], 0);
  });


  testWidgets(
    'ouvrir /garage/:id/edit sans objet en mémoire charge le véhicule et reste en édition',
    (tester) async {
      await enlargeScreen(tester);
      final pending = Completer<OwnedVehicle>();
      final repo = _Repo(getVehicleResult: (_) => pending.future);
      final router = GoRouter(
        initialLocation: '/garage/12/edit',
        routes: [
          GoRoute(
            path: '/garage/:id/edit',
            builder: (_, state) => EditGarageVehiclePage(
              vehicleId: int.tryParse(state.pathParameters['id'] ?? ''),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogRefsProvider.overrideWith((_) async => refs),
            authProvider.overrideWith((_) => _Auth()),
            garageRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Ajouter à mon garage'), findsNothing);

      pending.complete(utilitaire);
      await tester.pumpAndSettle();
      expect(find.text('Modifier le véhicule'), findsWidgets);
      expect(find.text('Le pick-up'), findsWidgets);
      expect(find.text('Ajouter à mon garage'), findsNothing);
    },
  );

  testWidgets(
    'un identifiant inconnu affiche Véhicule introuvable et ne passe pas en ajout',
    (tester) async {
      await enlargeScreen(tester);
      final repo = _Repo(
        getVehicleResult: (_) => Future.error(
          const ApiException(statusCode: 404, message: 'missing'),
        ),
      );
      await tester.pumpWidget(
        _app(home: const EditGarageVehiclePage(vehicleId: 99), repo: repo),
      );
      await tester.pumpAndSettle();
      expect(find.text('Véhicule introuvable'), findsOneWidget);
      expect(find.text('Ajouter à mon garage'), findsNothing);
      expect(find.byType(AddVehicleToGaragePage), findsNothing);
    },
  );

  testWidgets('un identifiant d’URL invalide affiche Véhicule introuvable', (
    tester,
  ) async {
    await enlargeScreen(tester);
    await tester.pumpWidget(
      _app(home: const EditGarageVehiclePage(vehicleId: null), repo: _Repo()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Véhicule introuvable'), findsOneWidget);
    expect(find.text('Ajouter à mon garage'), findsNothing);
  });
}
