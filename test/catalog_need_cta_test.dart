import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/compatible_parts_page.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/needs/data/needs_repository.dart';
import 'package:auto/features/needs/presentation/need_draft.dart';
import 'package:auto/features/needs/presentation/pages/submit_need_page.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/partner_accounts/presentation/partner_session.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/l10n/app_localizations_en.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:auto/shared/models/paged_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/polices.dart';

const _vehicule = Vehicle(
  id: 1,
  reference: 'STOCK-1',
  designation: 'Toyota Camry',
  registrationStatus: 'registered',
  identity: VehicleIdentity(brand: 'Toyota', model: 'Camry', year: 2013),
  commercial: VehicleCommercial(
    condition: 'used',
    status: 'in_stock',
    availability: 'sale',
    salePrice: 4500000,
    currency: 'XOF',
    priceNegotiable: false,
  ),
  faultsCount: 0,
  mediaUrls: [],
);

const _garage = OwnedVehicle(
  id: 9,
  designation: 'Toyota Corolla',
  brandId: 1,
  vehicleModelId: 11,
  year: 2018,
  identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
  compatibilityReady: true,
);

Part _unePiece() {
  final json = jsonDecode(
    File('test/fixtures/parts_list.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return Part.fromJson((json['data'] as List).first as Map<String, dynamic>);
}

Accessory _unAccessoire() {
  final json = jsonDecode(
    File('test/fixtures/accessories_list.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return Accessory.fromJson(
    (json['data'] as List).first as Map<String, dynamic>,
  );
}

AuthState get _visiteur => const AuthState();
AuthState get _client => const AuthState(type: AuthType.client);
AuthState get _personnel => const AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Administrateur',
    email: 'admin@autoparc.bf',
    role: 'admin',
  ),
);

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SessionPartenaire extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  _SessionPartenaire() : super(const PartnerSession());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VehiculesFixes extends VehicleListNotifier {
  _VehiculesFixes(this.etat);
  final PagedState<CatalogVehicleItem> etat;
  @override
  PagedState<CatalogVehicleItem> build() => etat;
}

class _PiecesFixes extends PartListNotifier {
  _PiecesFixes(this.etat);
  final PagedState<Part> etat;
  @override
  PagedState<Part> build() => etat;
}

class _AccessoiresFixes extends AccessoryListNotifier {
  _AccessoiresFixes(this.etat);
  final PagedState<Accessory> etat;
  @override
  PagedState<Accessory> build() => etat;
}

class _GarageVide extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [];
}

class _DepotGarage extends GarageRepository {
  _DepotGarage(this.pieces) : super(ApiClient());
  final List<Part> pieces;
  @override
  Future<List<Part>> compatibleParts(
    int ownedVehicleId, {
    int? categoryId,
  }) async => pieces;
}

PagedState<T> _vide<T>() => PagedState<T>(
  items: <T>[],
  total: 0,
  hasMore: false,
  isLoading: false,
  isLoadingMore: false,
);

PagedState<T> _pageComplete<T>(List<T> items, {bool hasMore = false}) =>
    PagedState<T>(
      items: items,
      total: items.length,
      hasMore: hasMore,
      isLoading: false,
      isLoadingMore: false,
    );

Finder get _boutonEmettre => find.byKey(const Key('catalog-need-empty-cta'));
Finder get _carteFin => find.byKey(const Key('catalog-need-end-cta'));

Future<GoRouter> monter(
  WidgetTester tester, {
  required Widget page,
  String chemin = '/',
  AuthState auth = const AuthState(),
  PagedState<CatalogVehicleItem>? vehicules,
  PagedState<Part>? pieces,
  PagedState<Accessory>? accessoires,
  Locale locale = const Locale('fr'),
  Size ecran = const Size(390, 844),
  double echelle = 1,
  Brightness mode = Brightness.light,
}) async {
  tester.view.physicalSize = Size(ecran.width, ecran.height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: chemin,
    routes: [
      GoRoute(path: '/', builder: (_, _) => page),
      GoRoute(path: '/vehicles', builder: (_, _) => page),
      GoRoute(path: '/parts', builder: (_, _) => page),
      GoRoute(path: '/accessories', builder: (_, _) => page),
      GoRoute(
        path: '/needs/new',
        builder: (_, state) => SubmitNeedPage(
          draft: state.extra is NeedDraft
              ? state.extra as NeedDraft
              : NeedDraft.fromQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Connexion')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _Auth(auth)),
        partnerSessionProvider.overrideWith((_) => _SessionPartenaire()),
        vehicleListProvider.overrideWith(
          () => _VehiculesFixes(vehicules ?? _vide()),
        ),
        partListProvider.overrideWith(() => _PiecesFixes(pieces ?? _vide())),
        accessoryListProvider.overrideWith(
          () => _AccessoiresFixes(accessoires ?? _vide()),
        ),
        unreadCountProvider.overrideWith((_) async => 0),
        garageProvider.overrideWith(_GarageVide.new),
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
        partCategoriesProvider.overrideWith((_) async => <PartCategory>[]),
        categoriesAvecPiecesProvider.overrideWith(
          (_) async => <PartCategory>[],
        ),
        categoriesAccessoiresOccupeesProvider.overrideWith(
          (_) async => <String>{},
        ),
        publicBrandsProvider.overrideWith(
          (_) async => <({int id, String name})>[],
        ),
        publicPartCategoriesProvider.overrideWith(
          (_) async => <({int id, String name})>[],
        ),
        publicManufacturersProvider.overrideWith(
          (_) async => <({int id, String name})>[],
        ),
      ],
      child: MaterialApp.router(
        locale: locale,
        theme: themeAutoParc(mode),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(size: ecran, textScaler: TextScaler.linear(echelle)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return router;
}

void main() {
  setUpAll(chargerPolices);

  final l10nFr = AppLocalizationsFr();
  final l10nEn = AppLocalizationsEn();

  group('NeedDraft', () {
    test('reprend la recherche, la location, l\'engin et la ville', () {
      final draft = NeedDraft.fromVehicleFilter(
        const VehicleFilter(
          search: 'Mazda 3',
          availability: 'rent',
          assetKind: 'equipment',
          city: 'Ouagadougou',
          bodyStyle: 'suv',
          yearMin: 2018,
          yearMax: 2024,
          priceMax: 15000000,
        ),
        l10nFr,
      );
      expect(draft.type, 'vehicle');
      expect(draft.description, contains('Véhicule à louer'));
      expect(draft.description, contains('Engin'));
      expect(draft.description, contains('Mazda 3'));
      expect(draft.description, contains('Ouagadougou'));
      expect(draft.bodyStyle, 'suv');
      expect(draft.yearMin, 2018);
      expect(draft.yearMax, 2024);
      expect(draft.budgetMax, 15000000);
    });

    test('préremplit une pièce avec le véhicule du garage', () {
      final draft = NeedDraft.fromPartFilter(
        const PartFilter(
          search: 'filtre à huile',
          oem: '04152-YZZA1',
          categoryId: 4,
        ),
        l10nFr,
        garageVehicle: _garage,
      );
      expect(draft.type, 'part');
      expect(draft.partCategoryId, 4);
      expect(draft.oemNumber, '04152-YZZA1');
      expect(draft.description, contains('filtre à huile'));
      expect(draft.description, contains('Toyota Corolla'));
    });

    test('préremplit un accessoire', () {
      final draft = NeedDraft.fromAccessoryFilter(
        const AccessoryFilter(
          search: 'camera',
          category: 'securite',
          city: 'Bobo-Dioulasso',
        ),
        l10nEn,
      );
      expect(draft.type, 'accessory');
      expect(draft.accessoryCategory, 'securite');
      expect(draft.description, contains('camera'));
      expect(draft.description, contains('Bobo-Dioulasso'));
    });

    test('ignore un type de requête inconnu', () {
      expect(NeedDraft.fromQuery({'type': 'rental'}).type, 'vehicle');
      expect(NeedDraft.fromQuery({'type': 'part'}).type, 'part');
    });

    test('préremplit depuis les pièces compatibles du garage', () {
      final draft = NeedDraft.fromCompatibleParts(
        l10nFr,
        vehicle: _garage,
        categoryId: 7,
      );
      expect(draft.type, 'part');
      expect(draft.partCategoryId, 7);
      expect(draft.description, contains('Toyota Corolla'));
    });
  });

  group('Écran vide du catalogue', () {
    testWidgets('propose d\'émettre un besoin au visiteur', (tester) async {
      await monter(tester, page: const VehicleListPage(), auth: _visiteur);
      expect(find.text('Aucun véhicule trouvé'), findsOneWidget);
      expect(_boutonEmettre, findsOneWidget);
      expect(
        find.text('Vous ne trouvez pas ce que vous cherchez ?'),
        findsOneWidget,
      );
      expect(find.text('Émettre un besoin'), findsOneWidget);
    });

    testWidgets('le propose aussi au client, en anglais', (tester) async {
      await monter(
        tester,
        page: const VehicleListPage(),
        auth: _client,
        locale: const Locale('en'),
      );
      expect(find.text("Can't find what you're looking for?"), findsOneWidget);
      expect(find.text('Post a request'), findsOneWidget);
    });

    testWidgets('le masque pour le personnel', (tester) async {
      await monter(tester, page: const VehicleListPage(), auth: _personnel);
      expect(find.text('Aucun véhicule trouvé'), findsOneWidget);
      expect(_boutonEmettre, findsNothing);
      expect(find.text('Émettre un besoin'), findsNothing);
    });

    testWidgets('le propose sur les pièces et les accessoires', (tester) async {
      await monter(tester, page: const PartListPage(), auth: _visiteur);
      expect(_boutonEmettre, findsOneWidget);
      await monter(tester, page: const AccessoryListPage(), auth: _visiteur);
      expect(_boutonEmettre, findsOneWidget);
    });

    testWidgets('tient à 320 points et à l\'échelle 1,3', (tester) async {
      await monter(
        tester,
        page: const VehicleListPage(),
        auth: _visiteur,
        ecran: const Size(320, 640),
        echelle: 1.3,
      );
      expect(_boutonEmettre, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ouvre le formulaire prérempli depuis les filtres', (
      tester,
    ) async {
      await monter(tester, page: const VehicleListPage(), auth: _client);
      final conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      conteneur
          .read(vehicleFilterProvider.notifier)
          .state = const VehicleFilter(
        search: 'Mazda 3',
        availability: 'rent',
        city: 'Ouagadougou',
        yearMin: 2018,
        priceMax: 8000000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Émettre un besoin'));
      await tester.pumpAndSettle();

      expect(find.byType(SubmitNeedPage), findsOneWidget);
      final type = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(type.selected, {'vehicle'});
      final description = tester.widget<TextFormField>(
        find.byKey(const Key('besoin-description')),
      );
      expect(description.controller?.text, contains('Mazda 3'));
      expect(description.controller?.text, contains('Véhicule à louer'));
      expect(description.controller?.text, contains('Ouagadougou'));
    });

    testWidgets('demande la connexion au visiteur, sans perdre le brouillon', (
      tester,
    ) async {
      await monter(tester, page: const PartListPage(), auth: _visiteur);
      await tester.tap(find.text('Émettre un besoin'));
      await tester.pumpAndSettle();
      expect(find.byType(SubmitNeedPage), findsOneWidget);
      expect(find.text(l10nFr.needsSignInRequiredTitle), findsOneWidget);
    });
  });

  group('Fin de liste', () {
    testWidgets('affiche la carte une fois la pagination terminée', (
      tester,
    ) async {
      await monter(
        tester,
        page: const VehicleListPage(),
        auth: _visiteur,
        vehicules: _pageComplete([const CatalogVehicleItem.vehicle(_vehicule)]),
      );
      await tester.scrollUntilVisible(
        _carteFin,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_carteFin, findsOneWidget);
      expect(
        find.text('Vous ne trouvez pas ce que vous cherchez ?'),
        findsOneWidget,
      );
      expect(find.text('Émettre un besoin'), findsOneWidget);
    });

    testWidgets('ne l\'affiche pas tant qu\'il reste une page', (tester) async {
      await monter(
        tester,
        page: const VehicleListPage(),
        auth: _visiteur,
        vehicules: _pageComplete([
          const CatalogVehicleItem.vehicle(_vehicule),
        ], hasMore: true),
      );
      expect(_carteFin, findsNothing);
    });

    testWidgets('la masque pour le personnel', (tester) async {
      await monter(
        tester,
        page: const VehicleListPage(),
        auth: _personnel,
        vehicules: _pageComplete([const CatalogVehicleItem.vehicle(_vehicule)]),
      );
      expect(_carteFin, findsNothing);
      expect(find.text('Émettre un besoin'), findsNothing);
    });

    testWidgets('l\'ajoute aux pièces et aux accessoires', (tester) async {
      await monter(
        tester,
        page: const PartListPage(),
        auth: _client,
        pieces: _pageComplete([_unePiece()]),
      );
      await tester.scrollUntilVisible(
        _carteFin,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_carteFin, findsOneWidget);

      await monter(
        tester,
        page: const AccessoryListPage(),
        auth: _client,
        accessoires: _pageComplete([_unAccessoire()]),
      );
      await tester.scrollUntilVisible(
        _carteFin,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_carteFin, findsOneWidget);
    });
  });

  group('Formulaire prérempli', () {
    testWidgets(
      'applique un brouillon pièce, y compris la catégorie et l\'OEM',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((_) => _Auth(_client)),
              publicBrandsProvider.overrideWith(
                (_) async => <({int id, String name})>[],
              ),
              publicPartCategoriesProvider.overrideWith(
                (_) async => <({int id, String name})>[
                  (id: 4, name: 'Filtres'),
                ],
              ),
              publicManufacturersProvider.overrideWith(
                (_) async => <({int id, String name})>[],
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              theme: themeAutoParc(Brightness.light),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SubmitNeedPage(
                draft: NeedDraft.fromPartFilter(
                  const PartFilter(
                    search: 'filtre à huile',
                    oem: '04152-YZZA1',
                    categoryId: 4,
                  ),
                  l10nFr,
                  garageVehicle: _garage,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final type = tester.widget<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>),
        );
        expect(type.selected, {'part'});
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('besoin-description')),
              )
              .controller
              ?.text,
          contains('Toyota Corolla'),
        );
      },
    );
  });

  group('Pièces compatibles du garage', () {
    Future<void> monterCompatibles(
      WidgetTester tester, {
      required List<Part> pieces,
      AuthState auth = const AuthState(type: AuthType.client),
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => _Auth(auth)),
            garageRepositoryProvider.overrideWithValue(_DepotGarage(pieces)),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            theme: themeAutoParc(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CompatiblePartsPage(
              ownedVehicleId: _garage.id,
              vehicle: _garage,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('propose le besoin quand aucune pièce n\'est rattachée', (
      tester,
    ) async {
      await monterCompatibles(tester, pieces: []);
      expect(_boutonEmettre, findsOneWidget);
      expect(find.text('Émettre un besoin'), findsOneWidget);
    });

    testWidgets('ajoute la carte en fin de liste', (tester) async {
      await monterCompatibles(tester, pieces: [_unePiece()]);
      expect(_carteFin, findsOneWidget);
    });

    testWidgets('les masque pour le personnel', (tester) async {
      await monterCompatibles(tester, pieces: [], auth: _personnel);
      expect(_boutonEmettre, findsNothing);
      await monterCompatibles(tester, pieces: [_unePiece()], auth: _personnel);
      expect(_carteFin, findsNothing);
    });
  });
}
