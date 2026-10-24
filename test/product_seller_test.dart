import 'dart:convert';
import 'dart:io';

import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/models/product_seller.dart';
import 'package:auto/shared/presentation/widgets/seller_contact_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture(String name) {
  final data = (jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
      as Map<String, dynamic>)['data'];
  return Map<String, dynamic>.from(data is List ? data.first as Map : data as Map);
}

const sellerJson = {
  'id': 27,
  'company_name': 'Garage du vendeur',
  'phone': '+226 70 00 22 44',
  'whatsapp': '+226 71 00 22 44',
};

class _GuestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _GuestAuth() : super(const AuthState());

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('les coordonnées publiques visent le vendeur et normalisent WhatsApp', () {
    final seller = ProductSeller.fromJson(sellerJson);
    expect(seller.companyName, 'Garage du vendeur');
    expect(seller.telephoneUri?.scheme, 'tel');
    expect(seller.telephoneUri?.path, '+22670002244');
    expect(seller.whatsappUri.toString(), 'https://wa.me/22671002244');
  });

  test('WhatsApp reprend le téléphone si le vendeur ne fournit pas un autre numéro', () {
    final seller = ProductSeller.fromJson({...sellerJson, 'whatsapp': null});
    expect(seller.whatsappUri.toString(), 'https://wa.me/22670002244');
    expect(
      ProductSeller.fromJson({...sellerJson, 'phone': '', 'whatsapp': ''}).telephoneUri,
      isNull,
    );
  });

  test('les trois modèles conservent le vendeur et tolèrent les champs privés masqués', () {
    final vehicle = fixture('vehicle_detail')..remove('reference');
    vehicle['seller'] = sellerJson;
    expect(Vehicle.fromJson(vehicle).seller?.id, 27);

    final part = fixture('part_detail')..remove('sku');
    part['seller'] = sellerJson;
    part['stock'] = {'is_available': true};
    final parsedPart = Part.fromJson(part);
    expect(parsedPart.seller?.id, 27);
    expect(parsedPart.stock.hasQuantity, isFalse);
    expect(parsedPart.isAvailableForSale, isTrue);
    part['stock'] = {'is_available': false};
    expect(Part.fromJson(part).isAvailableForSale, isFalse);

    final accessory = fixture('accessories_list')..remove('sku');
    accessory['seller'] = sellerJson;
    accessory['stock'] = {'is_available': true};
    final parsedAccessory = Accessory.fromJson(accessory);
    expect(parsedAccessory.seller?.id, 27);
    expect(parsedAccessory.stock.hasQuantity, isFalse);
    expect(parsedAccessory.isAvailableForSale, isTrue);
    accessory['stock'] = {'is_available': false};
    expect(Accessory.fromJson(accessory).isAvailableForSale, isFalse);
  });

  test('les anciens produits sans vendeur conservent leurs quantités et disponibilité', () {
    final part = Part.fromJson(fixture('part_detail'));
    final accessory = Accessory.fromJson(fixture('accessories_list'));
    expect(part.seller, isNull);
    expect(part.stock.hasQuantity, isTrue);
    expect(part.stock.quantity, 7);
    expect(part.isAvailableForSale, isTrue);
    expect(accessory.seller, isNull);
    expect(accessory.stock.hasQuantity, isTrue);
    expect(accessory.stock.quantity, 18);
    expect(accessory.isAvailableForSale, isTrue);
  });

  Future<void> mount(WidgetTester tester, Widget page, {
    Part? part,
    Accessory? accessory,
    Vehicle? vehicle,
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _GuestAuth()),
        garageCompatibilityProvider.overrideWith((_, __) async => []),
        if (part != null) partDetailProvider.overrideWith((_, __) async => part),
        if (accessory != null) accessoryDetailProvider.overrideWith((_, __) async => accessory),
        if (vehicle != null) vehicleDetailProvider.overrideWith((_, __) async => vehicle),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('la pièce partenaire propose les contacts et ne présente pas le stock masqué comme nul', (tester) async {
    final json = fixture('part_detail');
    json['seller'] = sellerJson;
    json['stock'] = {'is_available': true};
    final part = Part.fromJson(json);
    await mount(tester, PartDetailPage(partId: part.id), part: part);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.byType(SellerContactBar), findsOneWidget);
    expect(find.text('Garage du vendeur'), findsOneWidget);
    expect(find.text(l10n.catalogAddToCart), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text(l10n.catalogStockIn), findsOneWidget);
    expect(find.text(l10n.catalogOutOfStock), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l’accessoire partenaire propose le contact plutôt que le panier boutique', (tester) async {
    final json = fixture('accessories_list');
    json['seller'] = sellerJson;
    json['stock'] = {'is_available': true};
    final accessory = Accessory.fromJson(json);
    await mount(tester, AccessoryDetailPage(accessoryId: accessory.id), accessory: accessory);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.byType(SellerContactBar), findsOneWidget);
    expect(find.text(l10n.catalogAddToCart), findsNothing);
    expect(find.text(l10n.catalogOutOfStock), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le véhicule partenaire utilise lui aussi les contacts du vendeur', (tester) async {
    final json = fixture('vehicle_detail');
    json['seller'] = sellerJson;
    final vehicle = Vehicle.fromJson(json);
    await mount(tester, VehicleDetailPage(vehicleId: vehicle.id), vehicle: vehicle);
    expect(find.byType(SellerContactBar), findsOneWidget);
    expect(find.text('Garage du vendeur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une pièce historique garde son bouton de panier', (tester) async {
    final part = Part.fromJson(fixture('part_detail'));
    await mount(tester, PartDetailPage(partId: part.id), part: part);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.byType(SellerContactBar), findsNothing);
    expect(find.text(l10n.catalogAddToCart), findsOneWidget);
  });
}
