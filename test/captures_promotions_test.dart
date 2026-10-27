import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_listing_form.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_session.dart'
    as espace;
import 'package:auto/l10n/app_localizations.dart';

import 'support/langues.dart';
import 'support/polices.dart';

/// Captures des promotions : ce que voit l'acheteur, ce que compose le vendeur.
///
/// Même convention que les autres fichiers de capture : rien n'est écrit sans
/// `CAPTURES=1`, et chaque banc vérifie d'abord que la capture ne serait pas
/// vide — un `matchesGoldenFile` sur un écran qui n'a rien rendu produit une
/// image grise sans que rien ne s'en plaigne.

class _Session extends StateNotifier<espace.PartnerSession>
    implements espace.PartnerSessionNotifier {
  _Session()
      : super(espace.PartnerSession(
          profile: espace.PartnerProfile(
            user: const {'role': 'partner'},
            account: const {'status': 'approved', 'contact_name': 'Salif Kaboré'},
            boutique: const {
              'marge_pourcentage': 0,
              'promotion_remise_max_pourcentage': 40,
            },
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Depot extends espace.PartnerRepository {
  @override
  Future<espace.PartnerReferences> references() async =>
      const espace.PartnerReferences(
        brands: [], models: [], engineTypes: [],
        partCategories: [], manufacturers: [],
      );
}

Vehicle _vehiculePromu() {
  final page = jsonDecode(
    File('test/fixtures/vehicles_list.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final brut = Map<String, dynamic>.from((page['data'] as List).first as Map);

  (brut['commercial'] as Map<String, dynamic>)
    ..['availability'] = 'sale'
    ..['sale_price'] = '4000000.00'
    ..['deal_label'] = 'Promo -20 %';
  // Sans photo : une image reseau en banc ouvre un `HttpClient` et un cache
  // sur disque, dont le canal `path_provider` n existe pas ici. La capture
  // etait ecrite, puis le banc tombait sur l exception differee.
  brut['media'] = const [];
  brut['deal'] = const {
    'price': 4000000,
    'normal_price': 5000000,
    'discount_percent': 20,
  };

  return Vehicle.fromJson(brut);
}

void main() {
  final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

  setUpAll(chargerPolices);

  Future<void> capturer(WidgetTester tester, String nom, Finder temoin) async {
    expect(temoin, findsWidgets,
        reason: 'La capture serait vide : $nom n a rien rendu.');
    if (!ecrireCaptures) return;

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/captures/$nom.png'),
    );
  }

  testWidgets('la promotion sur la carte du catalogue', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: localeFr,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 163,
              child: VehicleCard(vehicle: _vehiculePromu()),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await capturer(tester, 'promotion-carte-catalogue',
        find.byKey(const Key('promotion-pastille')));
  });

  testWidgets('le vendeur compose sa promotion', (tester) async {
    tester.view.physicalSize = const Size(360, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        espace.partnerRepositoryProvider.overrideWithValue(_Depot()),
        espace.partnerSessionProvider.overrideWith((_) => _Session()),
      ],
      child: const MaterialApp(
        home: espace.PartnerListingFormPage(
          kind: espace.PartnerListingKind.accessories,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final prix = find.widgetWithText(TextFormField, 'Prix de vente (FCFA)');
    await tester.ensureVisible(prix);
    await tester.enterText(prix, '12500');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('promotion-prix')), '10000');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('promotion-resume')));
    await tester.pumpAndSettle();

    await capturer(tester, 'promotion-formulaire-vendeur',
        find.byKey(const Key('promotion-resume')));
  });

  testWidgets('le refus quand la remise dépasse le plafond', (tester) async {
    tester.view.physicalSize = const Size(360, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        espace.partnerRepositoryProvider.overrideWithValue(_Depot()),
        espace.partnerSessionProvider.overrideWith((_) => _Session()),
      ],
      child: const MaterialApp(
        home: espace.PartnerListingFormPage(
          kind: espace.PartnerListingKind.accessories,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final prix = find.widgetWithText(TextFormField, 'Prix de vente (FCFA)');
    await tester.ensureVisible(prix);
    await tester.enterText(prix, '12500');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();

    // 12 500 -> 5 000 : 60 %, au-delà du plafond de 40.
    await tester.enterText(find.byKey(const Key('promotion-prix')), '5000');
    await tester.pumpAndSettle();

    await capturer(tester, 'promotion-refus-plafond',
        find.textContaining('ne peut pas dépasser'));
  });
}
