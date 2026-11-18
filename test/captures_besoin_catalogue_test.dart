import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
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

class _GarageVide extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [];
}

Future<void> monter(
  WidgetTester tester, {
  required PagedState<CatalogVehicleItem> liste,
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
        vehicleListProvider.overrideWith(() => _Vehicules(liste)),
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
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        theme: themeAutoParc(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VehicleListPage(),
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

void main() {
  setUpAll(chargerPolices);

  testWidgets('état vide à 390, thème clair', (tester) async {
    await monter(
      tester,
      liste: const PagedState(
        items: [],
        total: 0,
        hasMore: false,
        isLoading: false,
        isLoadingMore: false,
      ),
    );
    expect(find.text('Émettre un besoin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturer(tester, 'besoin-catalogue-vide-390-light');
  });

  testWidgets('fin de liste à 390, thème clair', (tester) async {
    await monter(
      tester,
      liste: PagedState(
        items: const [CatalogVehicleItem.vehicle(vehicule)],
        total: 1,
        hasMore: false,
        isLoading: false,
        isLoadingMore: false,
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('catalog-need-end-cta')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Émettre un besoin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturer(tester, 'besoin-catalogue-fin-390-light');
  });
}
