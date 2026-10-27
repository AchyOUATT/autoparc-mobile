import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/marge_recapitulatif.dart';
import 'package:auto/features/partner_accounts/presentation/partner_listing_form.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_listings_page.dart'
    as espace;
import 'package:auto/features/partner_accounts/presentation/partner_session.dart'
    as espace;
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart'
    as annuaire;
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';

/// Ce que le vendeur lit avant d'enregistrer son prix.
///
/// ── POURQUOI CET ECRAN EXISTE ──────────────────────────────────────────────
///
/// Le prix enregistre en base est le prix PUBLIC, marge comprise : c'est lui
/// que le catalogue trie et filtre, et lui que l'acheteur voit. Si le
/// formulaire n'affichait que ce nombre, le vendeur croirait avoir propose
/// 4 950 000 alors qu'il a tape 4 500 000 — et il baisserait son prix pour
/// « corriger », en se trompant a chaque fois.
///
/// ── CE QUE CE BANC TIENT ───────────────────────────────────────────────────
///
/// Les trois nombres ; le MEME arrondi que le serveur, sans quoi l'ecran
/// annoncerait un franc d'ecart avec ce qui sera enregistre ; le silence quand
/// le taux est nul ou inconnu ; et le fait que le PERSONNEL n'en voie rien,
/// puisque la marge porte sur ce qu'un tiers propose.

class _Session extends StateNotifier<espace.PartnerSession>
    implements espace.PartnerSessionNotifier {
  _Session(double taux)
      : super(espace.PartnerSession(
          profile: espace.PartnerProfile(
            user: const {'role': 'partner'},
            account: const {'status': 'approved', 'contact_name': 'Salif'},
            boutique: {'marge_pourcentage': taux},
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Annuaire extends annuaire.PartnerRepository {
  _Annuaire() : super(ApiClient());

  @override
  Future<PaginatedResponse<Partner>> getPartners({
    int page = 1,
    int perPage = 50,
    String? search,
    bool includeInactive = false,
  }) async => const PaginatedResponse(
    data: [], currentPage: 1, lastPage: 1, total: 0, perPage: 50,
  );
}

class _DepotVehicules extends VehicleAdminRepository {
  _DepotVehicules() : super(ApiClient(), CatalogLocalCache());
}

const _refs = CatalogRefs(
  brands: [], vehicleModels: [], trims: [], engineTypes: [],
  drivetrains: [], colors: [], features: [], locations: [],
);

Vehicle _vehiculeAVendre() {
  final json = jsonDecode(
    File('test/fixtures/vehicle_detail.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final data = Map<String, dynamic>.from(json['data'] as Map);
  (data['commercial'] as Map<String, dynamic>)['availability'] = 'sale';

  return Vehicle.fromJson(data);
}

Future<void> _ouvrirFormulaire(
  WidgetTester tester, {
  required VehicleFormMode mode,
  double taux = 10,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      catalogRefsProvider.overrideWith((_) async => _refs),
      countriesProvider.overrideWith((_) async => <CountryRef>[]),
      vehicleAdminRepositoryProvider.overrideWithValue(_DepotVehicules()),
      annuaire.partnerRepositoryProvider.overrideWithValue(_Annuaire()),
      espace.partnerSessionProvider.overrideWith((_) => _Session(taux)),
    ],
    child: MaterialApp(
      home: VehicleRegisterPage(mode: mode, existing: _vehiculeAVendre()),
    ),
  ));
  await tester.pumpAndSettle();
}

class _DepotAnnonces extends espace.PartnerRepository {
  _DepotAnnonces(this.annonces);

  final List<Map<String, dynamic>> annonces;

  @override
  Future<espace.PartnerListingPage> listListings(
    espace.PartnerListingKind kind, {
    int page = 1,
    String? query,
  }) async => espace.PartnerListingPage(
    items: annonces, page: 1, lastPage: 1, total: annonces.length,
  );

  /// Le formulaire d'article charge ses referentiels avant de se rendre :
  /// sans cette reponse il resterait sur son indicateur de chargement, et la
  /// capture comme le banc ne verraient aucun champ.
  @override
  Future<espace.PartnerReferences> references() async =>
      const espace.PartnerReferences(
        brands: [], models: [], engineTypes: [],
        partCategories: [], manufacturers: [],
      );
}

Future<void> _ouvrirAnnonces(
  WidgetTester tester,
  List<Map<String, dynamic>> annonces,
) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      espace.partnerRepositoryProvider
          .overrideWithValue(_DepotAnnonces(annonces)),
      espace.partnerSessionProvider.overrideWith((_) => _Session(10)),
    ],
    child: const MaterialApp(
      home: espace.PartnerListingsPage(kind: espace.PartnerListingKind.vehicles),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Le `Stepper` ne monte qu'une etape : les prix sont a la derniere.
Future<void> _allerAuxPrix(WidgetTester tester) async {
  for (var etape = 0; etape < 3; etape++) {
    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();
  }
}

void main() {
  // ── LE CALCUL, QUI DOIT ETRE CELUI DU SERVEUR ───────────────────────────

  test('le total emploie le meme arrondi que le serveur', () {
    // `MargePartenaire::majorer` fait `round($prix * (1 + $taux / 100))`.
    expect(MargeRecapitulatif.total(4500000, 10), 4950000);
    expect(MargeRecapitulatif.total(3333, 7.5), 3583); // 3582.975
    expect(MargeRecapitulatif.total(3000, 0), 3000);

    // AU PLUS PROCHE, et non au superieur : majorer systematiquement
    // ajouterait une pichenette que personne n'a decidee, et l'ecran
    // annoncerait un franc de plus que ce que le serveur enregistre.
    expect(MargeRecapitulatif.total(3333, 10), 3666); // 3666.3
  });

  // ── L'ENCART, ISOLE ─────────────────────────────────────────────────────

  Future<void> montrer(WidgetTester tester, {num? prix, double taux = 10}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MargeRecapitulatif(prixPropose: prix, pourcentage: taux),
      ),
    ));
    await tester.pump();
  }

  testWidgets('les trois nombres sont dits, et le taux avec', (tester) async {
    await montrer(tester, prix: 4500000);

    expect(find.text('Votre prix'), findsOneWidget);
    expect(find.text('4 500 000 FCFA'), findsOneWidget);
    expect(find.text('Marge boutique (10 %)'), findsOneWidget);
    expect(find.text('+ 450 000 FCFA'), findsOneWidget);
    expect(find.text('4 950 000 FCFA'), findsOneWidget);
  });

  /// Un taux a virgule ne doit pas s'afficher « 7.5 % » d'un cote et
  /// « 8 % » de l'autre : c'est le genre d'ecart qu'un vendeur releve.
  testWidgets('un taux a virgule est dit tel quel', (tester) async {
    await montrer(tester, prix: 3333, taux: 7.5);

    expect(find.text('Marge boutique (7.5 %)'), findsOneWidget);
    expect(find.text('3 583 FCFA'), findsOneWidget);
  });

  /// Rien a 0 % : une ligne « marge 0 % » attirerait l'attention sur un
  /// reglage que personne n'a arme.
  testWidgets('a zero pour cent, rien ne s’affiche', (tester) async {
    await montrer(tester, prix: 4500000, taux: 0);

    expect(find.byKey(const Key('marge-recapitulatif')), findsNothing);
  });

  /// Et rien non plus sans prix : mieux vaut se taire qu'annoncer un total
  /// qu'on ne sait pas calculer.
  testWidgets('sans prix saisi, rien ne s’affiche', (tester) async {
    await montrer(tester, prix: null);

    expect(find.byKey(const Key('marge-recapitulatif')), findsNothing);
  });

  // ── DANS LE FORMULAIRE VEHICULE ─────────────────────────────────────────

  testWidgets('le partenaire voit la marge sous son prix de vente',
      (tester) async {
    await _ouvrirFormulaire(tester, mode: VehicleFormMode.partenaire);
    await _allerAuxPrix(tester);

    expect(find.byKey(const Key('marge-recapitulatif'), skipOffstage: false),
        findsWidgets);
  });

  /// LE CONTRASTE. La marge porte sur ce qu'un TIERS propose : l'afficher au
  /// personnel majorerait un prix que la boutique a fixe elle-meme.
  testWidgets('le personnel n’en voit rien', (tester) async {
    await _ouvrirFormulaire(tester, mode: VehicleFormMode.personnel);
    await _allerAuxPrix(tester);

    expect(find.byKey(const Key('marge-recapitulatif'), skipOffstage: false),
        findsNothing);
  });

  /// Taux inconnu — session enregistree avant cette version, ou serveur pas
  /// encore deploye : le profil n'a pas la cle, et on se tait.
  testWidgets('un taux absent du profil n’affiche rien', (tester) async {
    await _ouvrirFormulaire(tester, mode: VehicleFormMode.partenaire, taux: 0);
    await _allerAuxPrix(tester);

    expect(find.byKey(const Key('marge-recapitulatif'), skipOffstage: false),
        findsNothing);
  });

  // ── DANS LE FORMULAIRE PIECE / ACCESSOIRE ───────────────────────────────
  //
  // Le meme besoin que pour un vehicule : le prix enregistre est le prix
  // public, et sans les trois nombres le vendeur croit s'etre trompe.

  testWidgets('le prix d’un accessoire porte aussi son recapitulatif',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        espace.partnerRepositoryProvider
            .overrideWithValue(_DepotAnnonces(const [])),
        espace.partnerSessionProvider.overrideWith((_) => _Session(10)),
      ],
      child: const MaterialApp(
        home: espace.PartnerListingFormPage(
          kind: espace.PartnerListingKind.accessories,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final champ = find.widgetWithText(TextFormField, 'Prix de vente (FCFA)');
    await tester.ensureVisible(champ);
    await tester.enterText(champ, '12500');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('marge-recapitulatif')), findsOneWidget);
    expect(find.text('13 750 FCFA'), findsOneWidget);
  });

  // ── LA LIGNE DE LA CARTE D'ANNONCE ──────────────────────────────────────
  //
  // Le prix affiche sur la carte est le prix PUBLIC, marge comprise. Sans
  // cette ligne, le vendeur relit un nombre qu'il n'a pas tape, croit s'etre
  // trompe, et baisse son prix pour « corriger » — a chaque fois.

  testWidgets('la carte dit ce que la marge a ajoute', (tester) async {
    await _ouvrirAnnonces(tester, [
      {
        'id': 1,
        'name': 'Corolla 2020',
        'commercial': {'sale_price': '4950000.00', 'currency': 'FCFA'},
        'partner_pricing': {
          'taux': 10,
          'prix_proposes': {'sale_price': 4500000},
          'total': {'sale_price': 4950000},
        },
      },
    ]);

    expect(
      find.textContaining('dont 450000 de marge boutique (10 %)'),
      findsOneWidget,
    );
  });

  /// Les annonces d'AVANT la marge n'ont pas de detail, et leur prix est celui
  /// que le vendeur a propose. Leur inventer une ligne a 0 % laisserait croire
  /// qu'un calcul a eu lieu.
  testWidgets('une annonce sans detail n’affiche aucune ligne de marge',
      (tester) async {
    await _ouvrirAnnonces(tester, [
      {
        'id': 1,
        'name': 'Corolla 2020',
        'commercial': {'sale_price': '4500000.00', 'currency': 'FCFA'},
      },
    ]);

    expect(find.textContaining('marge boutique'), findsNothing);
  });

  // ── LE PROFIL ───────────────────────────────────────────────────────────

  test('le taux se lit dans le profil, et vaut zero quand il manque', () {
    const sansClef = espace.PartnerProfile(user: {}, account: {});
    expect(sansClef.margePourcentage, 0);

    final avec = espace.PartnerProfile.fromJson(const {
      'user': {'role': 'partner'},
      'partner_account': {'status': 'approved'},
      'boutique': {'marge_pourcentage': 10},
    });
    expect(avec.margePourcentage, 10);

    // Le serveur peut serialiser un decimal en CHAINE : c'est la faute qui
    // avait fait tomber le catalogue entier. On la lit quand meme.
    final chaine = espace.PartnerProfile.fromJson(const {
      'user': {'role': 'partner'},
      'partner_account': {'status': 'approved'},
      'boutique': {'marge_pourcentage': '7.5'},
    });
    expect(chaine.margePourcentage, 7.5);
  });

  /// Le taux retourne au COFFRE avec le reste du profil : c'est ce qui permet
  /// au demarrage optimiste d'ouvrir un formulaire complet avant que
  /// `/partner/me` n'ait repondu.
  test('le taux survit a l’aller-retour par le coffre', () {
    final profil = espace.PartnerProfile.fromJson(const {
      'user': {'role': 'partner'},
      'partner_account': {'status': 'approved'},
      'boutique': {'marge_pourcentage': 12.5},
    });

    expect(
      espace.PartnerProfile.fromJson(profil.toJson()).margePourcentage,
      12.5,
    );
  });
}
