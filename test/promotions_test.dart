import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/data/models/promotion.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/features/catalog/presentation/promotion_affichage.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/champs_de_promotion.dart';
import 'package:auto/features/partner_accounts/presentation/partner_listing_form.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_session.dart'
    as espace;

import 'support/langues.dart';

/// Les promotions a duree limitee, cote application.
///
/// ── CE QUI SE JOUE ICI, ET QUI N'EST PAS EVIDENT ──────────────────────────
///
/// Le champ de prix d'une fiche PUBLIQUE porte DEJA le prix remise : c'est le
/// serveur qui l'y substitue, pour que l'application deja publiee — qui ne
/// connait pas le bloc `deal` — affiche un prix coherent avec les filtres et
/// le tri. Ce que l'application ajoute est donc ce qui MANQUE : le prix barre
/// et la remise.
///
/// Dans l'espace du VENDEUR, c'est l'inverse : le champ de prix porte son prix
/// NORMAL, parce que son formulaire le preremplit. Confondre les deux ferait
/// enregistrer la remise comme prix habituel a la premiere correction.
///
/// ── LE PLAFOND EST DIT DES DEUX COTES ─────────────────────────────────────
///
/// Le serveur tranche, mais le vendeur doit lire le refus PENDANT qu'il tape.
/// Le calcul de remise est donc le meme ici que dans
/// `PromotionPartenaire::remise()` : s'ils divergeaient, l'ecran accepterait ce
/// que le serveur refuse.

class _Session extends StateNotifier<espace.PartnerSession>
    implements espace.PartnerSessionNotifier {
  _Session({double plafond = 40})
      : super(espace.PartnerSession(
          profile: espace.PartnerProfile(
            user: const {'role': 'partner'},
            account: const {'status': 'approved', 'contact_name': 'Salif'},
            boutique: {
              'marge_pourcentage': 0,
              'promotion_remise_max_pourcentage': plafond,
            },
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Depot extends espace.PartnerRepository {
  Map<String, dynamic>? enregistre;

  @override
  Future<espace.PartnerReferences> references() async =>
      const espace.PartnerReferences(
        brands: [], models: [], engineTypes: [],
        partCategories: [], manufacturers: [],
      );

  @override
  Future<Map<String, dynamic>> saveListing(
    espace.PartnerListingKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) async {
    enregistre = Map<String, dynamic>.from(data);

    return {'id': id ?? 1, ...data};
  }
}

void main() {
  // ── LA LECTURE, QUI NE DOIT JAMAIS FAIRE TOMBER UNE FICHE ───────────────

  group('Promotion.fromJson', () {
    test('lit un bloc complet, meme serialise en chaines', () {
      final promo = Promotion.fromJson(const {
        'price': '4000000.00',
        'normal_price': '5000000.00',
        'discount_percent': '20.0',
        'ends_at': '2026-11-03T00:00:00+00:00',
      });

      expect(promo, isNotNull);
      expect(promo!.price, 4000000);
      expect(promo.normalPrice, 5000000);
      expect(promo.discountPercent, 20);
      expect(promo.economie, 1000000);
    });

    /// Un bloc absent est le cas NORMAL : le serveur ne le rend que pendant la
    /// fenetre. Il ne doit rien casser.
    test('rend null sur un bloc absent ou illisible', () {
      expect(Promotion.fromJson(null), isNull);
      expect(Promotion.fromJson('pas une carte'), isNull);
      expect(Promotion.fromJson(const {'price': 'abc'}), isNull);
    });

    /// Une promotion plus chere que le prix normal n'est pas une promotion.
    /// Le serveur ne devrait jamais en produire ; si cela arrivait, mieux vaut
    /// ne rien annoncer qu'annoncer une hausse comme une remise.
    test('rend null quand le prix promotionnel n est pas inferieur', () {
      expect(
        Promotion.fromJson(const {'price': 5000000, 'normal_price': 5000000}),
        isNull,
      );
    });
  });

  /// Une page ouverte traverse minuit. Le serveur a cesse d'envoyer le bloc,
  /// mais l'ecran, lui, est reste ouvert.
  test('une promotion dont la fin est passee se dit finie', () {
    final promo = Promotion(
      price: 4000000,
      normalPrice: 5000000,
      discountPercent: 20,
      endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    expect(promo.finie, isTrue);
  });

  // ── CE QUI S'AFFICHE ────────────────────────────────────────────────────

  const active = Promotion(
    price: 4000000,
    normalPrice: 5000000,
    discountPercent: 20,
  );

  Future<void> poser(WidgetTester tester, Widget enfant) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: enfant)));
    await tester.pump();
  }

  testWidgets('la pastille dit la remise', (tester) async {
    await poser(tester, const PastillePromotion(promotion: active));

    expect(find.text('-20 %'), findsOneWidget);
  });

  testWidgets('le prix normal s affiche barre', (tester) async {
    await poser(tester, const PrixNormalBarre(promotion: active));

    final texte = tester.widget<Text>(find.byKey(const Key('promotion-prix-barre')));
    expect(texte.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('sans promotion, rien ne s affiche', (tester) async {
    await poser(tester, const Column(children: [
      PastillePromotion(promotion: null),
      PrixNormalBarre(promotion: null),
    ]));

    expect(find.byKey(const Key('promotion-pastille')), findsNothing);
    expect(find.byKey(const Key('promotion-prix-barre')), findsNothing);
  });

  testWidgets('une promotion finie ne s affiche plus', (tester) async {
    final finie = Promotion(
      price: 4000000,
      normalPrice: 5000000,
      discountPercent: 20,
      endsAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    await poser(tester, Column(children: [
      PastillePromotion(promotion: finie),
      PrixNormalBarre(promotion: finie),
    ]));

    expect(find.byKey(const Key('promotion-pastille')), findsNothing);
    expect(find.byKey(const Key('promotion-prix-barre')), findsNothing);
  });

  // ── SUR LA CARTE DU CATALOGUE ───────────────────────────────────────────
  //
  // C'est l'endroit que le proprietaire a nomme : « on aura cela comme
  // indication sur la carte ». Le prix affiche porte deja la remise ; sans
  // pastille ni prix barre, l'acheteur ne voit qu'un prix.

  Vehicle vehicule({Map<String, dynamic>? promotion}) {
    final page = jsonDecode(
      File('test/fixtures/vehicles_list.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final brut = Map<String, dynamic>.from(
      (page['data'] as List).first as Map,
    );
    (brut['commercial'] as Map<String, dynamic>)['availability'] = 'sale';
    (brut['commercial'] as Map<String, dynamic>)['sale_price'] = '4000000.00';
    if (promotion != null) {
      brut['deal'] = promotion;
      // Le serveur pose aussi ce libelle, pour l application deja publiee.
      (brut['commercial'] as Map<String, dynamic>)['deal_label'] = 'Promo -20 %';
    }

    return Vehicle.fromJson(brut);
  }

  Future<void> poserCarte(WidgetTester tester, Vehicle v) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: localeFr,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(child: SizedBox(width: 163, child: VehicleCard(vehicle: v))),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('la carte dit la remise et barre le prix normal',
      (tester) async {
    await poserCarte(tester, vehicule(promotion: const {
      'price': 4000000,
      'normal_price': 5000000,
      'discount_percent': 20,
    }));

    expect(find.byKey(const Key('promotion-pastille')), findsOneWidget);
    expect(find.byKey(const Key('promotion-prix-barre')), findsOneWidget);
  });

  /// Le serveur pose `deal_label` a « Promo -20 % » pour l application DEJA
  /// PUBLIEE, qui ne connait pas le bloc `deal`. Cette version-ci a mieux :
  /// afficher les deux dirait deux fois « -20 % » sur une carte de 163 points.
  testWidgets('le libelle du serveur s efface devant la pastille',
      (tester) async {
    final v = vehicule(promotion: const {
      'price': 4000000,
      'normal_price': 5000000,
      'discount_percent': 20,
    });
    await poserCarte(tester, v);

    expect(find.text('Promo -20 %'), findsNothing);
    expect(find.text('-20 %'), findsOneWidget);
  });

  testWidgets('une carte sans promotion n affiche rien de plus',
      (tester) async {
    await poserCarte(tester, vehicule());

    expect(find.byKey(const Key('promotion-pastille')), findsNothing);
    expect(find.byKey(const Key('promotion-prix-barre')), findsNothing);
  });

  // ── LE CALCUL, QUI DOIT ETRE CELUI DU SERVEUR ───────────────────────────

  test('la remise se calcule comme cote serveur', () {
    // `PromotionPartenaire::remise()` fait (normal - promo) / normal * 100.
    const saisie = PromotionSaisie(prix: 3000000);

    expect(saisie.remise(5000000), 40);
    expect(saisie.remise(0), isNull);
    expect(saisie.remise(null), isNull);
    expect(const PromotionSaisie().remise(5000000), isNull);
  });

  // ── CE QUE LE VENDEUR SAISIT ────────────────────────────────────────────

  Future<void> ouvrirFormulaire(
    WidgetTester tester,
    _Depot depot, {
    double plafond = 40,
    Map<String, dynamic>? annonce,
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        espace.partnerRepositoryProvider.overrideWithValue(depot),
        espace.partnerSessionProvider.overrideWith((_) => _Session(plafond: plafond)),
      ],
      child: MaterialApp(
        home: espace.PartnerListingFormPage(
          kind: espace.PartnerListingKind.accessories,
          initialListing: annonce,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> remplir(WidgetTester tester, String cle, String valeur) async {
    final champ = find.byKey(Key(cle));
    await tester.ensureVisible(champ);
    await tester.enterText(champ, valeur);
    await tester.pumpAndSettle();
  }

  Future<void> saisirPrix(WidgetTester tester, String valeur) async {
    final champ = find.widgetWithText(TextFormField, 'Prix de vente (FCFA)');
    await tester.ensureVisible(champ);
    await tester.enterText(champ, valeur);
    await tester.pumpAndSettle();
  }

  testWidgets('sans prix de vente, la promotion n est pas proposable',
      (tester) async {
    await ouvrirFormulaire(tester, _Depot());

    final commutateur = tester.widget<SwitchListTile>(
      find.byKey(const Key('promotion-activer')),
    );

    expect(commutateur.onChanged, isNull,
        reason: 'Le serveur refuse une promotion sans prix a remiser : la '
            'laisser cliquable ferait composer l impossible.');
    expect(find.text('Indiquez d’abord un prix de vente.'), findsOneWidget);
  });

  testWidgets('une remise au-dela du plafond est refusee a la saisie',
      (tester) async {
    await ouvrirFormulaire(tester, _Depot());
    await saisirPrix(tester, '10000');

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();

    // 10 000 -> 5 000 : 50 %, au-dela du plafond de 40.
    await remplir(tester, 'promotion-prix', '5000');

    expect(find.textContaining('ne peut pas dépasser 40 %'), findsOneWidget);
    expect(find.textContaining('50.0 %'), findsOneWidget,
        reason: 'Le vendeur doit lire SA remise autant que le plafond.');
  });

  testWidgets('une remise sous le plafond annonce ce que verra l acheteur',
      (tester) async {
    await ouvrirFormulaire(tester, _Depot());
    await saisirPrix(tester, '10000');

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();

    await remplir(tester, 'promotion-prix', '8000');

    expect(find.byKey(const Key('promotion-resume')), findsOneWidget);
    expect(find.textContaining('−20 %'), findsOneWidget);
  });

  testWidgets('le plafond du profil est celui qui s applique', (tester) async {
    await ouvrirFormulaire(tester, _Depot(), plafond: 60);
    await saisirPrix(tester, '10000');

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();

    await remplir(tester, 'promotion-prix', '5000');

    expect(find.textContaining('ne peut pas dépasser'), findsNothing,
        reason: 'A 60 % de plafond, une remise de 50 % passe.');
  });

  /// Le serveur exige les deux bornes des qu'il y a un prix : les poser par
  /// defaut epargne deux selecteurs au vendeur presse, et evite un 422 sur une
  /// promotion par ailleurs valide.
  testWidgets('activer la promotion pose une fenetre par defaut',
      (tester) async {
    final depot = _Depot();
    await ouvrirFormulaire(tester, depot);
    await saisirPrix(tester, '10000');

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('promotion-debut')), findsOneWidget);
    expect(find.byKey(const Key('promotion-fin')), findsOneWidget);

    final aujourdHui = DateTime.now();
    final debut = '${aujourdHui.day.toString().padLeft(2, '0')}/'
        '${aujourdHui.month.toString().padLeft(2, '0')}';
    expect(find.text(debut), findsOneWidget);
  });

  testWidgets('la promotion part avec ses deux bornes', (tester) async {
    final depot = _Depot();
    await ouvrirFormulaire(tester, depot);

    await saisirPrix(tester, '10000');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom de l’article'), 'Tapis',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();
    await remplir(tester, 'promotion-prix', '8000');

    final bouton = find.widgetWithText(FilledButton, 'Enregistrer le brouillon');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    expect(depot.enregistre, isNotNull);
    expect(depot.enregistre!['deal_price'], 8000);
    expect(depot.enregistre!['deal_starts_at'], isNotNull);
    expect(depot.enregistre!['deal_ends_at'], isNotNull);
  });

  /// Sans promotion a la CREATION, les trois champs ne partent pas : le
  /// serveur exige les bornes des qu'il y a un prix, et envoyer trois nuls
  /// pour rien brouille la charge.
  testWidgets('sans promotion, aucun champ de promotion ne part',
      (tester) async {
    final depot = _Depot();
    await ouvrirFormulaire(tester, depot);

    await saisirPrix(tester, '10000');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom de l’article'), 'Tapis',
    );
    await tester.pumpAndSettle();

    final bouton = find.widgetWithText(FilledButton, 'Enregistrer le brouillon');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    expect(depot.enregistre!.containsKey('deal_price'), isFalse);
  });

  /// A l'EDITION en revanche, un `deal_price` nul RETIRE la promotion, ce qui
  /// doit rester possible sans attendre sa date de fin.
  testWidgets('a l edition, retirer la promotion envoie un prix nul',
      (tester) async {
    final depot = _Depot();
    await ouvrirFormulaire(tester, depot, annonce: {
      'id': 7,
      'name': 'Tapis',
      'pricing': {'selling_price': '10000.00'},
      'stock': {'quantity': 3},
      'deal': {
        'price': 8000,
        'normal_price': 10000,
        'discount_percent': 20,
        'starts_at': DateTime.now().toIso8601String(),
        'ends_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      },
    });

    // La promotion enregistree est reprise : le commutateur est actif.
    expect(find.byKey(const Key('promotion-prix')), findsOneWidget);

    await tester.tap(find.byKey(const Key('promotion-activer')));
    await tester.pumpAndSettle();

    final bouton = find.widgetWithText(FilledButton, 'Enregistrer les modifications');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    expect(depot.enregistre!.containsKey('deal_price'), isTrue);
    expect(depot.enregistre!['deal_price'], isNull);
  });
}
