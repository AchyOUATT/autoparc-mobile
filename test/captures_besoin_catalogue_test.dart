import 'dart:convert';
import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
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
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/partner_accounts/presentation/partner_session.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/models/paged_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

/// Captures à 390 points, thème clair : état vide et fin de liste.
///
///   CAPTURES=1 flutter test test/captures_besoin_catalogue_test.dart \
///     --update-goldens
final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

const vehicule = Vehicle(
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

Part unePiece() {
  final json =
      jsonDecode(File('test/fixtures/parts_list.json').readAsStringSync())
          as Map<String, dynamic>;
  return Part.fromJson((json['data'] as List).first as Map<String, dynamic>);
}

Accessory unAccessoire() {
  final json =
      jsonDecode(File('test/fixtures/accessories_list.json').readAsStringSync())
          as Map<String, dynamic>;
  return Accessory.fromJson(
    (json['data'] as List).first as Map<String, dynamic>,
  );
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  _Session() : super(const PartnerSession());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Vehicules extends VehicleListNotifier {
  _Vehicules(this.etat);
  final PagedState<CatalogVehicleItem> etat;
  @override
  PagedState<CatalogVehicleItem> build() => etat;
}

class _Pieces extends PartListNotifier {
  _Pieces(this.etat);
  final PagedState<Part> etat;
  @override
  PagedState<Part> build() => etat;
}

class _Accessoires extends AccessoryListNotifier {
  _Accessoires(this.etat);
  final PagedState<Accessory> etat;
  @override
  PagedState<Accessory> build() => etat;
}

class _GarageVide extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [];
}

PagedState<T> vide<T>() => PagedState<T>(
  items: <T>[],
  total: 0,
  hasMore: false,
  isLoading: false,
  isLoadingMore: false,
);

PagedState<T> complete<T>(List<T> items) => PagedState<T>(
  items: items,
  total: items.length,
  hasMore: false,
  isLoading: false,
  isLoadingMore: false,
);

Future<void> monter(
  WidgetTester tester, {
  required Widget page,
  PagedState<CatalogVehicleItem>? vehicules,
  PagedState<Part>? pieces,
  PagedState<Accessory>? accessoires,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _Auth()),
        partnerSessionProvider.overrideWith((_) => _Session()),
        vehicleListProvider.overrideWith(() => _Vehicules(vehicules ?? vide())),
        partListProvider.overrideWith(() => _Pieces(pieces ?? vide())),
        accessoryListProvider.overrideWith(
          () => _Accessoires(accessoires ?? vide()),
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
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        theme: themeAutoParc(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> capturer(WidgetTester tester, String nom) async {
  if (!ecrireCaptures) return;
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../build/captures/$nom.png'),
  );
  // Une requête Dio laissée en attente (référentiels, notifications) fait
  // échouer le démontage : « A Timer is still pending ». La capture est
  // déjà écrite ; on démonte l'arbre avant que le banc ne vérifie.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> capturerFinDeListe(WidgetTester tester, String nom) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('catalog-need-end-cta')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  expect(find.text('Émettre un besoin'), findsOneWidget);
  expect(tester.takeException(), isNull);
  await capturer(tester, nom);
}

void main() {
  setUpAll(chargerPolices);

  testWidgets('véhicules, état vide à 390, thème clair', (tester) async {
    await monter(tester, page: const VehicleListPage(), vehicules: vide());
    expect(find.text('Émettre un besoin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturer(tester, 'besoin-catalogue-vide-390-light');
  });

  testWidgets('véhicules, fin de liste à 390, thème clair', (tester) async {
    await monter(
      tester,
      page: const VehicleListPage(),
      vehicules: complete([const CatalogVehicleItem.vehicle(vehicule)]),
    );
    await capturerFinDeListe(tester, 'besoin-catalogue-fin-390-light');
  });

  testWidgets('pièces, état vide à 390, thème clair', (tester) async {
    await monter(tester, page: const PartListPage(), pieces: vide());
    expect(find.text('Aucune pièce trouvée'), findsOneWidget);
    expect(find.text('Émettre un besoin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturer(tester, 'besoin-pieces-vide-390-light');
  });

  testWidgets('pièces, fin de liste à 390, thème clair', (tester) async {
    await monter(
      tester,
      page: const PartListPage(),
      pieces: complete([unePiece()]),
    );
    await capturerFinDeListe(tester, 'besoin-pieces-fin-390-light');
  });

  testWidgets('accessoires, état vide à 390, thème clair', (tester) async {
    await monter(tester, page: const AccessoryListPage(), accessoires: vide());
    expect(find.text('Émettre un besoin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturer(tester, 'besoin-accessoires-vide-390-light');
  });

  testWidgets('accessoires, fin de liste à 390, thème clair', (tester) async {
    await monter(
      tester,
      page: const AccessoryListPage(),
      accessoires: complete([unAccessoire()]),
    );
    await capturerFinDeListe(tester, 'besoin-accessoires-fin-390-light');
  });
}
