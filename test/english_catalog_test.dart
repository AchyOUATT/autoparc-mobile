import 'dart:convert';
import 'dart:io';

import 'package:auto/core/l10n/reference_labels.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/catalog_reference_labels.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/catalog/presentation/widgets/fitments_section.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Guest extends StateNotifier<AuthState> implements AuthNotifier {
  _Guest() : super(const AuthState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  const refs = CatalogRefs(
    brands: [], vehicleModels: [], trims: [], engineTypes: [],
    drivetrains: [], colors: [], features: [], locations: [],
  );
  for (final language in ['fr', 'en']) {
    test('Controlled references and custom names remain distinct in $language', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      expect(referenceFuelLabel('petrol', 'Essence', l10n), language == 'en' ? 'Petrol' : 'Essence');
      expect(referenceFuelLabel(null, 'Électrique', l10n), language == 'en' ? 'Electric' : 'Électrique');
      expect(referenceFuelLabel('custom', 'Mon carburant', l10n), 'Mon carburant');
      expect(referenceColourLabel('Argent', l10n), language == 'en' ? 'Silver' : 'Argent');
      expect(referenceColourLabel('Bleu de mon atelier', l10n), 'Bleu de mon atelier');
      expect(catalogPartCategoryLabel('Filtres', l10n), language == 'en' ? 'Filters' : 'Filtres');
      expect(catalogPartCategoryLabel('Pièces de mon atelier', l10n), 'Pièces de mon atelier');
      expect(catalogFeatureLabel('Caméra de recul', l10n), language == 'en' ? 'Reversing camera' : 'Caméra de recul');
      expect(catalogFeatureLabel('Option personnelle', l10n), 'Option personnelle');
      const model = ModelRef(id: 1, brandId: 1, name: 'Corolla', productionStart: 2019);
      final entry = FitmentEntry.saisie(brand: const BrandRef(id: 1, name: 'Toyota', isActive: true), model: model);
      expect(entry.labelDans(l10n), contains(language == 'en' ? 'since 2019' : 'depuis 2019'));
    });

    testWidgets('Vehicle card translates its fuel in $language', (tester) async {
      final vehicle = Vehicle.fromJson(fixture('vehicle_detail')['data'] as Map<String, dynamic>);
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: 163, child: VehicleCard(vehicle: vehicle)))),
      )));
      await tester.pump();
      expect(find.textContaining(language == 'en' ? 'Electric' : 'Électrique'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final kind in ['vehicle', 'part', 'accessory']) {
      testWidgets('$kind detail translates references, preserving seller content in $language', (tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const sellerText = 'Description personnelle : très bon état.';
        final vehicleData = fixture('vehicle_detail')['data'] as Map<String, dynamic>;
        (vehicleData['identity'] as Map<String, dynamic>)['model'] = 'Modèle personnel';
        final partData = fixture('part_detail')['data'] as Map<String, dynamic>;
        partData['description'] = sellerText;
        final accessoryData = (fixture('accessories_list')['data'] as List).first as Map<String, dynamic>;
        accessoryData['description'] = sellerText;
        final v = Vehicle.fromJson(vehicleData);
        final p = Part.fromJson(partData);
        final a = Accessory.fromJson(accessoryData);
        final page = switch (kind) {
          'vehicle' => VehicleDetailPage(vehicleId: v.id, initialVehicle: v),
          'part' => PartDetailPage(partId: p.id, initialPart: p),
          _ => AccessoryDetailPage(accessoryId: a.id, initialAccessory: a),
        };
        await tester.pumpWidget(ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => _Guest()),
            garageCompatibilityProvider.overrideWith((_, __) async => []),
            catalogRefsProvider.overrideWith((_) async => refs),
            vehicleDetailProvider(v.id).overrideWith((_) async => v),
            partDetailProvider(p.id).overrideWith((_) async => p),
            accessoryDetailProvider(a.id).overrideWith((_) async => a),
          ],
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: page,
          ),
        ));
        await tester.pumpAndSettle();
        final expected = switch (kind) {
          'vehicle' => language == 'en' ? 'Electric' : 'Électrique',
          'part' => language == 'en' ? 'Filters' : 'Filtres',
          _ => language == 'en' ? 'Utility' : 'Utilitaire',
        };
        await tester.scrollUntilVisible(find.text(expected), 180, scrollable: find.byType(Scrollable).first);
        expect(find.text(expected), findsOneWidget);
        final unchangedContent = kind == 'vehicle' ? 'Modèle personnel' : sellerText;
        // The vehicle's model appears before its technical specifications.
        // Reset its scroll offset to reach that field again.
        if (kind == 'vehicle') {
          tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
          await tester.pump();
        }
        await tester.scrollUntilVisible(find.text(unchangedContent), 180, scrollable: find.byType(Scrollable).first);
        expect(find.text(unchangedContent), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
