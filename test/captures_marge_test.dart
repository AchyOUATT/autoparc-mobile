import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_listing_form.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_listings_page.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_session.dart'
    as espace;

import 'support/polices.dart';

/// Captures de ce que le vendeur lit sur ses prix.
///
/// Meme convention que les autres fichiers de capture : rien n'est ecrit sans
/// `CAPTURES=1`, et les images vont dans `build/captures/`. Hors de ce mode,
/// chaque banc verifie quand meme que la capture ne serait pas vide — un
/// `matchesGoldenFile` sur un ecran qui n'a rien rendu produit une image grise
/// sans que rien ne s'en plaigne.

class _Session extends StateNotifier<espace.PartnerSession>
    implements espace.PartnerSessionNotifier {
  _Session()
      : super(espace.PartnerSession(
          profile: espace.PartnerProfile(
            user: const {'role': 'partner'},
            account: const {'status': 'approved', 'contact_name': 'Salif Kaboré'},
            boutique: const {'marge_pourcentage': 10},
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Depot extends espace.PartnerRepository {
  _Depot(this.annonces);

  final List<Map<String, dynamic>> annonces;

  @override
  Future<espace.PartnerListingPage> listListings(
    espace.PartnerListingKind kind, {
    int page = 1,
    String? query,
  }) async => espace.PartnerListingPage(
    items: annonces, page: 1, lastPage: 1, total: annonces.length,
  );

  @override
  Future<espace.PartnerReferences> references() async =>
      const espace.PartnerReferences(
        brands: [], models: [], engineTypes: [],
        partCategories: [], manufacturers: [],
      );
}

void main() {
  final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

  // Sans les vraies polices, une capture rend tout le texte en rectangles.
  setUpAll(chargerPolices);

  Future<void> poser(WidgetTester tester, Widget ecran,
      {List<Map<String, dynamic>> annonces = const []}) async {
    // 360x720 : la plus petite taille que `responsive_test.dart` eprouve.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        espace.partnerRepositoryProvider.overrideWithValue(_Depot(annonces)),
        espace.partnerSessionProvider.overrideWith((_) => _Session()),
      ],
      child: MaterialApp(home: ecran),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> capturer(WidgetTester tester, String nom, Finder temoin) async {
    expect(temoin, findsWidgets,
        reason: 'La capture serait vide : $nom n a rien rendu.');
    if (!ecrireCaptures) return;

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/captures/$nom.png'),
    );
  }

  testWidgets('la marge sous le prix d’un accessoire', (tester) async {
    await poser(
      tester,
      const espace.PartnerListingFormPage(
        kind: espace.PartnerListingKind.accessories,
      ),
    );

    final champ = find.widgetWithText(TextFormField, 'Prix de vente (FCFA)');
    await tester.ensureVisible(champ);
    await tester.enterText(champ, '12500');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('marge-recapitulatif')));
    await tester.pumpAndSettle();

    await capturer(tester, 'marge-formulaire-accessoire',
        find.byKey(const Key('marge-recapitulatif')));
  });

  testWidgets('la marge sur la carte d’une annonce', (tester) async {
    await poser(
      tester,
      const espace.PartnerListingsPage(kind: espace.PartnerListingKind.vehicles),
      annonces: [
        {
          'id': 1,
          'name': 'Toyota Corolla 2020',
          'commercial': {'sale_price': '4950000.00', 'currency': 'FCFA'},
          'partner_pricing': {
            'taux': 10,
            'prix_proposes': {'sale_price': 4500000},
            'total': {'sale_price': 4950000},
          },
        },
        {
          'id': 2,
          'name': 'Hyundai Tucson 2018',
          'commercial': {'sale_price': '7000000.00', 'currency': 'FCFA'},
        },
      ],
    );

    await capturer(tester, 'marge-cartes-annonces',
        find.textContaining('marge boutique'));
  });
}
