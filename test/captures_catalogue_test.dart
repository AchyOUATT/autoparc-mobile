// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  AVERTISSEMENT — CE QUE CE BANC SAIT MONTRER, ET CE QU'IL NE SAIT PAS    ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Il a induit en erreur TROIS FOIS, et chaque fois dans le même sens : on y a
// cru voir un défaut que l'application n'a pas. D'où cet en-tête.
//
// IL EST FIABLE POUR LA MISE EN PAGE ET POUR LA TRONCATURE. Les positions, les
// largeurs, le nombre de lignes posées, ce qui tient sous le pli et ce qui est
// coupé : tout cela sort du même moteur de mise en page que l'appareil, et une
// capture qui montre un titre amputé montre un titre réellement amputé.
//
// IL N'EST PAS FIABLE POUR LE RELIEF. `flutter_tester` compose les ombres en
// LOGICIEL, sans le flou du GPU : une élévation Material y devient un cerne net
// au lieu d'un dégradé, et ce cerne se lit comme une bordure épaisse. Trois
// surfaces de cet écran en portent une sur les captures — la `SearchBar`, le
// bouton flottant et chaque `Card` —, et AUCUNE n'est une bordure. Le fait, qui
// se vérifie en deux greps : `themeAutoParc` (lib/core/theme/app_theme.dart, 51
// lignes) ne déclare que `colorScheme`, `useMaterial3` et `appBarTheme` — ni
// `searchBarTheme`, ni `floatingActionButtonTheme`, ni `cardTheme` — et le mot
// `BorderSide` n'y apparaît pas une seule fois ; côté page, la `SearchBar` de
// `vehicle_list_page.dart` ne pose que `constraints`, `controller`, `hintText`,
// `leading`, `trailing` et `onChanged`, et le `FloatingActionButton.extended`
// que `onPressed`, `icon` et `label` : aucun des deux ne déclare de `side` ni de
// `shape`. Ce qu'on voit est une ombre mal rendue, pas un trait.
//
// IL A DÉJÀ MONTRÉ UN LOGO DE LA MAUVAISE MARQUE. La fixture porte son propre
// `brand_slug`, et le repli de vignette se choisit sur le SLUG et non sur le
// nom : tant que l'appelant ne le surchargeait pas, les quatre cartes
// affichaient le logo Hyundai du gabarit, Toyota comprise. Corrigé dans
// `vehicule()` plus bas — mais toute fixture recopiée refera le défaut.
//
// IL A DÉJÀ COMPTÉ 112 POINTS DE LISTE EN TROP. Il montait `VehicleGrid` nue :
// la grille occupait tout l'écran, sans barre de titre, sans barre de recherche,
// sans puces de filtre et sans barre de navigation. On y jugeait donc une
// densité que l'écran ne produit pas. Corrigé — `monter()` pose la page entière
// dans sa coque — mais une capture généreuse est pire qu'aucune capture, et
// c'est l'erreur qu'un banc de captures fait le plus naturellement.
//
// CONCLUSION, ET ELLE EST PRATIQUE : pour juger le RELIEF ou la DÉSIRABILITÉ —
// la profondeur des cartes, le poids des ombres, l'envie de descendre dans la
// liste —, il faut une capture d'ÉMULATEUR, pas ce banc. Ce banc répond à
// « est-ce coupé ? » et « qu'est-ce qui tient à l'écran ? », et à rien d'autre.

import 'dart:convert';
import 'dart:io';

import 'package:auto/core/widgets/navigation_bar_theme.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/catalog/presentation/widgets/ligne_compatibilite.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:auto/l10n/app_localizations.dart';

import 'support/langues.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

/// Captures du catalogue, pour regarder la grille au lieu d'en lire les cotes.
///
/// Ce fichier existe parce qu'une décision de mise en page se juge à l'œil et
/// se vérifie au chiffre, et que les deux ne se remplacent pas :
/// `carte_geometrie_test.dart` dit que rien n'est tronqué, il ne dit pas si la
/// liste donne envie d'y descendre.
///
/// Les données NE SONT PAS de fantaisie — c'est la raison d'être du fichier.
/// Une capture faite sur « Voiture 1 / 1 000 000 FCFA » montrerait une densité
/// que le vrai parc ne produit jamais : les noms composés et les prix à huit
/// chiffres sont précisément ce qui remplit une carte.
///
/// Les photos sont absentes à dessein. En banc d'essai une image distante ne se
/// charge pas, et une vignette cassée dirait moins que le repli que
/// l'application montre réellement quand une annonce n'a pas de photo.
///
/// CE QUE CES CAPTURES MONTRENT DEPUIS LES DEUX COLONNES EN MAÇONNERIE. Le
/// propriétaire a tranché : deux annonces de front à toutes les largeurs de
/// téléphone, et l'alignement n'est pas nécessaire. La grille à hauteur fixe
/// coupait le titre dans les douze configurations mesurées ; les cartes ont
/// désormais une hauteur intrinsèque et chaque colonne se remplit
/// indépendamment, le titre se replie, et deux choses ne se jugent plus qu'à
/// l'œil.
///
/// La première est le RATIO DE PHOTO. Il est passé de 4:3 à 16:9 pour une
/// raison chiffrée — vingt-cinq points de hauteur, et une annonce entière à 320
/// points dès « Grande police » —, mais le coût ne se chiffre pas : la même
/// photo est recadrée plus serré ici que sur la fiche de détail, et il faut
/// regarder si une voiture y est encore reconnaissable.
///
/// La seconde est LE DÉCALAGE DES DEUX COLONNES. Les rangées n'existent plus :
/// chaque colonne se remplit pour son compte, donc à partir de la troisième
/// annonce les deux colonnes ne commencent plus leurs cartes à la même hauteur.
/// Le propriétaire a dit que l'alignement n'était pas nécessaire, et c'est ce
/// qui fait disparaître le vide sous la carte la plus courte de chaque rangée —
/// 16,0 points sous la première rangée à 360 points d'écran, 36,0 à 411. Ces
/// captures sont là pour vérifier que le décalage se voit comme une maçonnerie
/// et non comme une liste cassée.
///
/// ET ELLES MONTENT LA PAGE ENTIÈRE, DANS SA COQUE, ce qui est la correction du
/// relecteur. Elles montaient `VehicleGrid` nue : la liste y occupait tout
/// l'écran, sans barre de titre, sans barre de recherche, sans puces de filtre
/// et sans barre de navigation — 112 points de plus que ce que l'application lui
/// laisse. Une capture généreuse est pire qu'aucune capture.
/// Comme `captures_controle_test.dart`, les PNG ne sont pas comparés : un
/// golden est exact au pixel et la CI tourne sous Ubuntu quand le poste est
/// sous Windows. Ils ne s'écrivent que sur demande :
///
///   CAPTURES=1 flutter test test/captures_catalogue_test.dart --update-goldens
///
/// Hors de ce mode le fichier reste un vrai test : il monte les mêmes écrans et
/// vérifie qu'ils rendent des cartes.
void main() {
  final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

  // Le drapeau de `formatXof` est un réglage de MODULE : il survit à la fin du
  // test qui l'a posé. Sans ce retour au français, la première capture
  // française exécutée après une capture anglaise montrerait des virgules de
  // milliers. Même garde que `accueil_langues_test.dart` et `langue_test.dart`.
  tearDown(() => definirLocaleMontants(localeFr));

  setUpAll(() async {
    await chargerPolices(exigerRoboto: false);

    // Sans cette ligne, le banc peint un anneau de focus épais autour de la
    // barre de recherche et du bouton flottant — et SEULEMENT dans le banc.
    // `FocusManager` part en `automatic`, ce que le banc d'essai interprète
    // comme une navigation au clavier ; un téléphone, lui, est en `touch` et
    // ne peint rien. Vérifié en comparant à une capture d'émulateur, où ces
    // contours n'existent pas.
    //
    // Une capture qui montre une bordure que l'application n'a pas est pire
    // qu'une capture absente : elle fait corriger un défaut imaginaire.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
  });

  final gabarit =
      (jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
              as Map<String, dynamic>)['data'][0]
          as Map<String, dynamic>;

  Vehicle vehicule({
    required String marque,
    required String modele,
    required String? finition,
    required int annee,
    required int kilometrage,
    required String motorisation,
    required String boite,
    required String disponibilite,
    required String ville,
    required String? affaire,
    required String prix,
  }) {
    final json = jsonDecode(jsonEncode(gabarit)) as Map<String, dynamic>;
    final id = json['identity'] as Map<String, dynamic>;
    final tec = json['technical'] as Map<String, dynamic>;
    final com = json['commercial'] as Map<String, dynamic>;
    id['brand'] = marque;
    // Le repli de vignette se choisit sur le SLUG, pas sur le nom : sans cette
    // ligne les quatre cartes portaient le logo Hyundai du gabarit, Toyota
    // comprise. Une capture qui ment sur son contenu ne vaut rien.
    id['brand_slug'] = marque.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    id['model'] = modele;
    id['year'] = annee;
    id['trim'] = finition;
    id['engine_type'] = motorisation;
    tec['transmission'] = boite;
    tec['mileage_km'] = kilometrage;
    com['availability'] = disponibilite;
    com['sale_price'] = prix;
    com['rental_daily_rate'] = null;
    com['deal_label'] = affaire;
    com['location'] = {'id': 3, 'name': 'Agence Ouaga 2000', 'city': ville};
    com['site'] = null;
    json['media'] = <dynamic>[];
    return Vehicle.fromJson(json);
  }

  /// Un échantillon plausible du parc : un tout-terrain, un SUV, une berline
  /// haut de gamme et une citadine. Trois des quatre libellés de disponibilité
  /// y passent, « Vente & Location » compris, qui est le badge le plus large.
  List<Vehicle> parc() => [
    vehicule(
      marque: 'Toyota',
      modele: 'Land Cruiser Prado',
      finition: 'TXL',
      annee: 2015,
      kilometrage: 345900,
      motorisation: 'Diesel',
      boite: 'automatic',
      disponibilite: 'both',
      ville: 'Ouagadougou',
      affaire: 'Bonne affaire',
      prix: '18500000.00',
    ),
    vehicule(
      marque: 'Hyundai',
      modele: 'Tucson',
      finition: 'Executive',
      annee: 2019,
      kilometrage: 96000,
      motorisation: 'Essence',
      boite: 'automatic',
      disponibilite: 'sale',
      ville: 'Bobo-Dioulasso',
      affaire: null,
      prix: '12900000.00',
    ),
    vehicule(
      marque: 'Mercedes-Benz',
      modele: 'Classe C 220 d',
      finition: 'AMG Line',
      annee: 2017,
      kilometrage: 128400,
      motorisation: 'Diesel',
      boite: 'automatic',
      disponibilite: 'sale',
      ville: 'Ouagadougou',
      affaire: 'Prix revu',
      prix: '9750000.00',
    ),
    vehicule(
      marque: 'Suzuki',
      modele: 'Alto',
      finition: null,
      annee: 2021,
      kilometrage: 41200,
      motorisation: 'Essence',
      boite: 'manual',
      disponibilite: 'rent',
      ville: 'Koudougou',
      affaire: null,
      prix: '3200000.00',
    ),
  ];

  /// Monte la PAGE ENTIÈRE DANS SA COQUE, et c'est la correction du relecteur.
  ///
  /// Cette fonction montait `VehicleGrid` nue dans un `Scaffold`. La capture
  /// montrait donc une liste qui occupait tout l'écran : pas de barre de titre,
  /// pas de barre de recherche, pas de rangées de puces, pas de barre de
  /// navigation en bas. Elle était GÉNÉREUSE — elle donnait à la liste 112
  /// points de plus que ce que l'application lui laisse —, et une capture
  /// généreuse est pire qu'aucune capture : on y juge une densité que l'écran ne
  /// produit pas.
  ///
  /// La coque reproduit `_AppShell` de `main.dart`, qui est privé : un
  /// `Scaffold` dont le `bottomNavigationBar` est `BarreNavigationPrincipale`,
  /// la barre des quatre onglets. C'est le MÊME widget que l'application, et
  /// non une copie : la copie d'avant avait fini par en différer — il lui
  /// manquait la borne d'échelle de texte, donc la capture montrait un
  /// « Accessoires » sur deux lignes que l'application n'a plus.
  Future<void> monter(
    WidgetTester tester, {
    required double largeur,
    required double hauteur,
    required double echelle,
    required Brightness mode,

    /// La langue de la capture. Le français par défaut, parce que tout le parc
    /// installé est francophone et que ces captures servent d'abord à juger ce
    /// qu'il voit. La vague 2 en ajoute trois en ANGLAIS, à la configuration de
    /// référence : des mesures au dixième de point disent qu'une traduction ne
    /// tronque pas, elles ne disent pas si l'écran se lit.
    Locale locale = localeFr,
  }) async {
    // LE FORMAT DES MONTANTS, ET LA CAPTURE ANGLAISE L'A RÉVÉLÉ. `formatXof`
    // lit un drapeau de module que `AutoParcApp.build` pose dans
    // l'application ; une coque de banc doit le poser elle-même. Sans cette
    // ligne, la première capture anglaise montrait « 18 500 000 FCFA » —
    // espaces fines insécables françaises — sous une interface anglaise, qui
    // attend « 18,500,000 FCFA ». Aucune mesure ne l'aurait dit : les deux
    // formes font la même largeur à un cheveu près.
    definirLocaleMontants(locale);

    final taille = Size(largeur, hauteur);
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(taille);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        // Une clé neuve à chaque pose : sans elle, Flutter réutilise l'élément du
        // `ProviderScope`, donc son conteneur, donc l'état déjà chargé de
        // `vehicleListProvider` — qui ne relit son dépôt que sur un changement de
        // filtre. Deux captures du même test montreraient le premier jeu.
        key: UniqueKey(),
        overrides: [
          authProvider.overrideWith(
            (_) => _FauxAuth(
              const AuthState(
                type: AuthType.staff,
                staffUser: StaffUser(
                  id: 1,
                  name: 'Administrateur',
                  email: 'admin@autoparc.bf',
                  role: 'admin',
                ),
              ),
            ),
          ),
          catalogRepositoryProvider.overrideWithValue(_Depot(parc())),
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
          debugShowCheckedModeBanner: false,
          // Les délégués ET la locale : voir test/support/langues.dart. Sans
          // `locale:`, ce banc mesurerait l'ANGLAIS — la liste des locales du
          // banc vaut `[en_US]` et `supportedLocales` commence par `en`.
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: themeAutoParc(mode),
          home: MediaQuery(
            data: MediaQueryData(
              size: taille,
              textScaler: TextScaler.linear(echelle),
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
            ),
            // La barre vient de `BarreNavigationPrincipale`, comme dans
            // `_AppShell` : la recopier ici a fait diverger la capture de
            // l'application — la copie n'avait pas la borne d'échelle de texte
            // qui empêche « Accessoires » de se casser sur deux lignes.
            //
            // LES QUATRE INTITULÉS SONT LUS, et ils étaient recopiés. La
            // première capture anglaise l'a montré du premier coup d'œil : une
            // barre de titre « Vehicles » au-dessus d'une barre du bas
            // « Accueil / Véhicules / Accessoires / Pièces ». C'est exactement
            // ce que le widget partagé évitait pour la hauteur, et que la copie
            // des libellés rouvrait pour la langue. La coque des articles,
            // elle, les lisait déjà — les deux posent maintenant la même chose.
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  body: const VehicleListPage(),
                  bottomNavigationBar: BarreNavigationPrincipale(
                    selectedIndex: 1,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        label: l10n.commonHome,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.directions_car_outlined),
                        label: l10n.commonVehicles,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.tune_outlined),
                        label: l10n.commonAccessories,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        label: l10n.commonParts,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    // Le dépôt répond sur une microtâche ; cinq pompes laissent la page passer
    // de son indicateur de chargement à ses cartes.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> capturer(WidgetTester tester, String nom) async {
    expect(
      find.byType(VehicleCard),
      findsWidgets,
      reason: 'La capture serait vide : la grille a rendu zéro carte.',
    );
    if (!ecrireCaptures) return;
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/captures/$nom.png'),
    );
  }

  // ── Les deux autres catalogues : pièces et accessoires ────────────────────

  /// Quatre pièces plausibles, dont UNE SANS COMPATIBILITÉ.
  ///
  /// Les noms sont des MODÈLES SEULS, sans la marque, parce que c'est ce que
  /// le serveur compose depuis que le propriétaire l'a tranché — voir
  /// `PartResource::resumeCompatibilite`. Les fixtures portaient
  /// « Toyota Corolla » et « Mercedes-Benz Classe C 220 d » ; une capture faite
  /// sur une chaîne que l'API ne peut plus envoyer montrerait une ligne que
  /// personne ne verra.
  ///
  /// Leur longueur reste le sujet : « Grand Cherokee Trackhawk » est le plus
  /// long modèle du référentiel, et c'est lui qui dit si la ligne tient encore
  /// à trois noms. Les totaux à deux chiffres sont ceux d'une pièce courante —
  /// un filtre à huile va sur des dizaines de modèles, et c'est précisément ce
  /// que le « +N » existe pour dire.
  List<Part> pieces() => [
    _piece(
      nom: 'Filtre à huile moteur cartouche 04152-YZZA1',
      prix: '4500.00',
      compatibilite: {
        'count': 12,
        'vehicles': ['Corolla', 'Tucson', 'Rio'],
      },
    ),
    // AUCUNE COMPATIBILITÉ, ET EN DEUXIÈME POSITION. La carte doit n'avoir ni
    // ligne vide ni séparateur orphelin, et la place compte : deuxième, elle
    // est dans la PREMIÈRE RANGÉE, donc visible entière sur les six captures,
    // à côté d'une carte qui porte la ligne. Mise en quatrième, elle passait
    // sous le pli dans toutes et le commentaire aurait promis une vérification
    // que personne ne pouvait faire.
    _piece(
      nom: 'Bidon d\'huile moteur 5W30 — 5 l',
      prix: '18000.00',
      compatibilite: {'count': 0, 'vehicles': <String>[]},
    ),
    _piece(
      nom: 'Plaquettes de frein avant',
      prix: '28000.00',
      compatibilite: {
        'count': 37,
        'vehicles': [
          'Grand Cherokee Trackhawk',
          'Range Rover Sport',
          'Classe C 220 d',
        ],
      },
    ),
    // TROIS MODÈLES EN TOUT, TROIS AFFICHÉS : aucun compte, parce qu'il n'y a
    // rien à compter. C'est l'autre moitié de la règle, et elle se voit sur la
    // capture 360 × 1,0, où cette carte ouvre la deuxième rangée.
    _piece(
      nom: 'Amortisseur arrière gauche',
      prix: '62500.00',
      compatibilite: {
        'count': 3,
        'vehicles': ['Alto', 'Yaris', 'Picanto'],
      },
    ),
  ];

  /// Quatre accessoires, même composition et pour les mêmes raisons.
  List<Accessory> accessoires() => [
    _accessoire(
      nom: 'Coffre de toit 350 l',
      prix: '109500.00',
      compatibilite: {
        'count': 12,
        'vehicles': ['Corolla', 'Tucson', 'Rio'],
      },
    ),
    // Sans compatibilité, en deuxième position. Voir [pieces].
    _accessoire(
      nom: 'Chargeur allume-cigare double USB',
      prix: '4000.00',
      compatibilite: {'count': 0, 'vehicles': <String>[]},
    ),
    _accessoire(
      nom: 'Tapis de sol caoutchouc sur mesure',
      prix: '22000.00',
      compatibilite: {
        'count': 37,
        'vehicles': [
          'Grand Cherokee Trackhawk',
          'Range Rover Sport',
          'Classe C 220 d',
        ],
      },
    ),
    // Deux modèles, deux affichés, aucun compte.
    _accessoire(
      nom: 'Attelage démontable',
      prix: '185000.00',
      compatibilite: {
        'count': 2,
        'vehicles': ['Hilux', 'Ranger'],
      },
    ),
  ];

  /// Monte la liste des pièces DANS SA COQUE, comme [monter] le fait pour les
  /// véhicules — barre de titre, barre de recherche, bande de filtres et barre
  /// de navigation du bas comprises.
  ///
  /// La session est celle du PERSONNEL, qui est aussi celle de la capture des
  /// véhicules : elle ajoute le bouton flottant et la bascule de
  /// disponibilité, donc c'est la carte la plus chargée des deux. Ce qu'elle ne
  /// montre pas est le badge « Disponible » du client ; `bandes_filtres_test`
  /// en porte la hauteur, et dit pourquoi un client ne se monte pas sur la
  /// liste des pièces.
  Future<void> monterPieces(
    WidgetTester tester, {
    required double largeur,
    required double hauteur,
    required double echelle,
    required Brightness mode,
    Locale locale = localeFr,
  }) => _monterArticles(
    tester,
    largeur: largeur,
    hauteur: hauteur,
    echelle: echelle,
    locale: locale,
    mode: mode,
    onglet: 3,
    page: const PartListPage(),
    depot: _DepotArticles(pieces: pieces()),
    surcharges: [
      partCategoriesProvider.overrideWith((_) async => _branches),
      categoriesAvecPiecesProvider.overrideWith((_) async => _branches),
    ],
  );

  /// Monte la liste des accessoires dans sa coque. Voir [monterPieces].
  Future<void> monterAccessoires(
    WidgetTester tester, {
    required double largeur,
    required double hauteur,
    required double echelle,
    required Brightness mode,
    Locale locale = localeFr,
  }) => _monterArticles(
    tester,
    largeur: largeur,
    hauteur: hauteur,
    echelle: echelle,
    locale: locale,
    mode: mode,
    onglet: 2,
    page: const AccessoryListPage(),
    depot: _DepotArticles(accessoires: accessoires()),
    surcharges: [
      categoriesAccessoiresOccupeesProvider.overrideWith(
        (_) async => {'esthetique', 'confort', 'utilitaire'},
      ),
    ],
  );

  /// La capture d'une liste d'articles.
  ///
  /// La non-vacuité porte sur la LIGNE DE COMPATIBILITÉ et pas seulement sur la
  /// carte : une capture où la ligne n'aurait pas été rendue — clé absente de
  /// la fixture, widget oublié — montrerait des cartes correctes et ne dirait
  /// rien de ce qu'on vient voir.
  Future<void> capturerArticles(WidgetTester tester, String nom) async {
    expect(
      find.byType(Card),
      findsWidgets,
      reason: 'La capture serait vide : la liste a rendu zéro carte.',
    );
    expect(
      find.byType(LigneCompatibilite),
      findsWidgets,
      reason:
          'Aucune `LigneCompatibilite` dans l\'arbre : la capture montrerait '
          'des cartes sans la ligne que ce test existe pour regarder.',
    );
    if (!ecrireCaptures) return;
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/captures/$nom.png'),
    );
  }

  testWidgets('catalogue, 360x720, texte normal, clair', (tester) async {
    await monter(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 1.0,
      mode: Brightness.light,
    );
    await capturer(tester, 'catalogue-360-x10-clair');
  });

  testWidgets('catalogue, 360x720, texte normal, sombre', (tester) async {
    await monter(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 1.0,
      mode: Brightness.dark,
    );
    await capturer(tester, 'catalogue-360-x10-sombre');
  });

  // LE CAS QUI A MOTIVÉ LA DÉCISION, et le seul endroit où le choix du ratio de
  // photo se voit : « Grande police » sur le plus petit téléphone du parc. La
  // rangée y fait 266,9 points pour 320,0 de liste, donc deux annonces entières
  // et un bout de la troisième ; en 4:3 elle en ferait 292,3 et il n'y aurait
  // AUCUNE annonce entière. C'est pour ces vingt-cinq points que la photo est
  // passée en 16:9, contre la cohérence avec la fiche de détail — et ça ne se
  // juge pas au chiffre : il faut regarder si une voiture recadrée en 16:9 est
  // encore reconnaissable.
  testWidgets('catalogue, 320x640, grande police, clair', (tester) async {
    await monter(
      tester,
      largeur: 320,
      hauteur: 640,
      echelle: 1.3,
      mode: Brightness.light,
    );
    await capturer(tester, 'catalogue-320-x13-clair');
  });

  // LE DERNIER CRAN D'ANDROID. La rangée y fait 509,2 points pour 400,0 de
  // liste : plus aucune annonce n'y tient entière, et c'est le prix assumé du
  // repli — le titre y prend six lignes au lieu d'être ellipsé. Ce qu'on vient
  // voir, c'est si une carte de 509 points reste lisible ou si elle a l'air
  // cassée.
  testWidgets('catalogue, 360x720, très grande police, clair', (tester) async {
    await monter(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 2.0,
      mode: Brightness.light,
    );
    await capturer(tester, 'catalogue-360-x20-clair');
  });

  // L'ÉMULATEUR DE RÉFÉRENCE, et il remplace la capture de tablette en
  // paysage : celle-ci n'avait de sens que tant que deux colonnes étaient
  // réservées aux écrans de plus de 808 points. Deux colonnes sont partout
  // maintenant, et c'est sur un Pixel qu'on regardera l'écran — quatre annonces
  // entières, deux rangées pleines.
  testWidgets('catalogue, 411x923, émulateur de référence', (tester) async {
    await monter(
      tester,
      largeur: 411,
      hauteur: 923,
      echelle: 1.0,
      mode: Brightness.light,
    );
    await capturer(tester, 'catalogue-411-x10-clair');
  });

  // LES DEUX COLONNES SE DÉCALENT, et c'est le prix visuel de la maçonnerie.
  // Sur un parc où les quatre annonces n'ont ni le même nom ni le même nombre de
  // lignes, la quatrième carte remonte de 16,0 points à 360 et de 36,0 à 411 :
  // la colonne de droite n'est plus en face de celle de gauche. Les cinq
  // captures ci-dessus le montrent déjà ; celle-ci n'existe pas en plus, et
  // c'est dit ici pour que personne ne la cherche.

  // ── LES CARTES DE PIÈCE ET D'ACCESSOIRE, pour la ligne de compatibilité ───

  /// LE PROPRIÉTAIRE A DEMANDÉ CES DEUX CAPTURES, et ce banc ne les avait pas :
  /// il ne montait que la liste des véhicules. La ligne des modèles compatibles
  /// est une décision qui se juge à l'œil — « police très petite, couleur
  /// sobre » n'est pas un chiffre —, et les bancs de géométrie ne répondent
  /// qu'à « est-ce coupé ? ».
  ///
  /// CE QU'IL FAUT REGARDER SUR CES CAPTURES, dans cet ordre :
  ///
  ///  1. LE « +N » EST-IL LISIBLE ? Il est à 10 points, en demi-gras, dans le
  ///     gris d'habillage, collé au bord droit de la carte. S'il se confond
  ///     avec les noms, c'est la graisse qui ne suffit pas.
  ///  2. LA LIGNE SE LIT-ELLE COMME UNE MENTION et non comme un second titre ?
  ///     Elle est d'un cran sous le nom de l'article, et dans une encre plus
  ///     claire.
  ///  3. LES DEUX LIGNES SONT-ELLES PLEINES ? Aux réglages où un seul nom
  ///     tient, la ligne n'occupe qu'une ligne et le « +11 » reste à droite : à
  ///     vérifier que cela n'a pas l'air d'un vide.
  ///  4. L'ÉCART AVEC LE NOM AU-DESSUS ET LE PRIX EN DESSOUS. Trois points
  ///     au-dessus, six en dessous.
  ///
  /// LES DONNÉES NE SONT PAS DE FANTAISIE, pour la raison déjà écrite en tête
  /// de ce fichier : des noms de modèle composés et des totaux à deux chiffres
  /// sont exactement ce qui remplit la ligne. Le DEUXIÈME article n'a AUCUNE
  /// compatibilité, et c'est voulu : sa carte doit n'avoir ni ligne vide ni
  /// séparateur orphelin, et c'est sur une capture que ça se voit d'un coup
  /// d'œil — d'où sa place dans la première rangée, à côté d'une carte qui
  /// porte la ligne.
  ///
  /// CE QUI SE VOIT SUR CES CAPTURES ET QUI EST UNE DÉGRADATION ACCEPTÉE. À
  /// l'échelle 2,0, le PRIX se replie sur deux lignes et la coupure tombe au
  /// milieu du mot : « 109 500 FCF » puis « A ». Le prix d'une carte de pièce ou
  /// d'accessoire est un `Text` nu, sans le `FittedBox` que porte celui d'un
  /// véhicule, et un prix est un seul segment insécable.
  ///
  /// TROIS CASES SUR VINGT-QUATRE, ET LES VINGT-QUATRE ONT ÉTÉ VÉRIFIÉES : les
  /// trois sont à 2,0, aucune à 1,0, 1,3 ou 1,5. C'est ce qui les fait passer en
  /// dégradation acceptée plutôt qu'en défaut à corriger — voir
  /// `support/echelles.dart` pour la règle, et `bandes_filtres_test.dart` pour
  /// le relevé des vingt-quatre cases et la marge de 6,5 points qui reste à
  /// 1,5. Un prix faux est le défaut que ce dépôt refuse le plus durement ;
  /// c'est pour cela qu'on a compté avant d'accepter.
  ///
  /// La ligne de compatibilité n'y est pour rien — la largeur reçue par le prix
  /// est la même avec et sans elle —, mais elle est sur la même capture, et une
  /// capture livrée sans explication fait corriger le mauvais objet.
  for (final cas in <(String, double, double, double)>[
    // Le réglage par défaut, c'est-à-dire ce que presque tout le monde voit.
    // Les trois modèles y tiennent sur UNE ligne depuis que la marque est
    // tombée, et la carte ne grandit que de 15,0 points.
    ('360-x10', 360, 720, 1.0),
    // « Grande police » sur le plus petit téléphone. Les trois noms tiennent
    // encore, mais il leur faut DEUX lignes : c'est la seule des trois
    // captures où la mention se replie à ce cran-là, et la carte y prend 35,0
    // points. Le compte d'annonces entières ne bouge pas pour autant — 2 avant
    // comme après.
    ('320-x13', 320, 640, 1.3),
    // Le dernier cran d'Android, où il ne tient plus que DEUX noms sur trois.
    // C'est la capture qui dit si « Corolla · Tucson  +10 » a l'air d'une
    // information ou d'un reste — et c'est le seul des trois réglages où le
    // mécanisme du « +N » calculé sur ce qui est peint change encore le
    // chiffre affiché.
    ('360-x20', 360, 720, 2.0),

    // Le plus petit écran au dernier cran, qui est le pire cas de largeur
    // pour le prix. Un banc affirme que « 109 500 FCFA » s'y replie EN
    // COUPANT DANS LE MOT ; aucune capture ne le montrait, et le propriétaire
    // en doute. Une mesure qu'on ne peut pas regarder ne vaut pas qu'on la
    // croie sur parole.
    ('320-x20', 320, 640, 2.0),
  ]) {
    testWidgets('pièces, ${cas.$1}, ligne de compatibilité', (tester) async {
      await monterPieces(
        tester,
        largeur: cas.$2,
        hauteur: cas.$3,
        echelle: cas.$4,
        mode: Brightness.light,
      );
      await capturerArticles(tester, 'pieces-${cas.$1}-clair');
    });

    testWidgets('accessoires, ${cas.$1}, ligne de compatibilité', (
      tester,
    ) async {
      await monterAccessoires(
        tester,
        largeur: cas.$2,
        hauteur: cas.$3,
        echelle: cas.$4,
        mode: Brightness.light,
      );
      await capturerArticles(tester, 'accessoires-${cas.$1}-clair');
    });
  }

  // Le mode sombre, sur une seule largeur : la ligne de compatibilité est la
  // seule surface de ces cartes qui emploie `outline`, et c'est en sombre qu'un
  // gris d'habillage disparaît dans le fond.
  testWidgets('pièces, 360x720, texte normal, sombre', (tester) async {
    await monterPieces(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 1.0,
      mode: Brightness.dark,
    );
    await capturerArticles(tester, 'pieces-360-x10-sombre');
  });

  testWidgets('accessoires, 360x720, texte normal, sombre', (tester) async {
    await monterAccessoires(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 1.0,
      mode: Brightness.dark,
    );
    await capturerArticles(tester, 'accessoires-360-x10-sombre');
  });

  // ── LES TROIS CATALOGUES EN ANGLAIS ───────────────────────────────────────
  //
  // Une capture par liste, à la configuration de référence — 360 points, texte
  // normal, thème clair —, et c'est l'apport de la vague 2 à ce fichier.
  //
  // POURQUOI UNE SEULE CONFIGURATION PAR ÉCRAN. Les mesures, elles, couvrent
  // les vingt-quatre cases de chaque liste dans les deux langues :
  // `bandes_filtres_test.dart` pour les puces et les écrans vides,
  // `carte_geometrie_test.dart` pour les cartes, `accueil_langues_test.dart`
  // pour les barres de titre. Elles disent qu'aucune chaîne anglaise ne se
  // coupe ; elles ne disent pas si l'écran se LIT — si « Customs cleared »
  // déséquilibre la bande d'offre, si « Good deal » a l'air d'un filtre, si
  // « Sale & rental » tient sur une ligne au lieu de deux. Ce sont des
  // questions de regard, et trois images y répondent mieux que trois cents
  // chiffres.
  //
  // Le reste du parc est francophone : les captures françaises ci-dessus
  // restent la référence, et ces trois-là s'ajoutent sans les remplacer.
  testWidgets('catalogue, 360x720, texte normal, clair, anglais', (
    tester,
  ) async {
    await monter(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 1.0,
      mode: Brightness.light,
      locale: localeEn,
    );
    await capturer(tester, 'catalogue-360-x10-clair-en');
  });

  testWidgets('pièces, 360x720, texte normal, clair, anglais', (tester) async {
    await monterPieces(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 1.0,
      mode: Brightness.light,
      locale: localeEn,
    );
    await capturerArticles(tester, 'pieces-360-x10-clair-en');
  });

  testWidgets('accessoires, 360x720, texte normal, clair, anglais', (
    tester,
  ) async {
    await monterAccessoires(
      tester,
      largeur: 360,
      hauteur: 720,
      echelle: 1.0,
      mode: Brightness.light,
      locale: localeEn,
    );
    await capturerArticles(tester, 'accessoires-360-x10-clair-en');
  });
}

/// Charge Roboto et les icônes Material depuis le cache du SDK.
///
/// Lues là plutôt que copiées dans le dépôt : deux fichiers binaires de plus
/// dans l'historique pour des métriques de test ne se justifient pas, et
/// `captures_controle_test.dart` fait déjà ainsi.

// ── Les gabarits des deux autres catalogues ─────────────────────────────────

/// Deux branches peuplées, pour que la bande de filtres des pièces propose
/// quelque chose : `niveauDiscriminant` ne rend rien quand aucun niveau de
/// l'arbre n'est partagé. Même jeu que `bandes_filtres_test.dart`.
final _branches = [
  const PartCategory(id: 1, name: 'Moteur', parentId: null, hasOwnParts: false),
  const PartCategory(id: 2, name: 'Filtres', parentId: 1, hasOwnParts: false),
  const PartCategory(
    id: 3,
    name: 'Filtre à huile',
    parentId: 2,
    hasOwnParts: true,
  ),
  const PartCategory(
    id: 24,
    name: 'Freinage',
    parentId: null,
    hasOwnParts: false,
  ),
  const PartCategory(
    id: 26,
    name: 'Plaquettes avant',
    parentId: 24,
    hasOwnParts: true,
  ),
];

/// Une pièce bâtie sur le gabarit du serveur, nom, prix et compatibilité
/// remplacés.
///
/// Le gabarit est relu et recopié à chaque appel : `jsonDecode` rend des
/// structures MUTABLES, et quatre pièces construites sur la même carte auraient
/// partagé leurs sous-objets — la quatrième aurait écrasé la compatibilité de
/// la première.
Part _piece({
  required String nom,
  required String prix,
  required Map<String, dynamic> compatibilite,
}) {
  final json = _gabarit('test/fixtures/parts_list.json');
  json['name'] = nom;
  (json['pricing'] as Map<String, dynamic>)['selling_price'] = prix;
  json['compatibility'] = compatibilite;
  json['media'] = <dynamic>[];
  return Part.fromJson(json);
}

/// Un accessoire bâti sur le gabarit du serveur. Voir [_piece].
Accessory _accessoire({
  required String nom,
  required String prix,
  required Map<String, dynamic> compatibilite,
}) {
  final json = _gabarit('test/fixtures/accessories_list.json');
  json['name'] = nom;
  (json['pricing'] as Map<String, dynamic>)['selling_price'] = prix;
  json['compatibility'] = compatibilite;
  json['media'] = <dynamic>[];
  return Accessory.fromJson(json);
}

Map<String, dynamic> _gabarit(String chemin) =>
    jsonDecode(
          jsonEncode(
            (jsonDecode(File(chemin).readAsStringSync())
                as Map<String, dynamic>)['data'][0],
          ),
        )
        as Map<String, dynamic>;

/// Monte une liste d'articles dans la coque de l'application.
///
/// Même coque que `monter()` pour les véhicules, et pour la même raison : une
/// capture faite sur une page nue lui donne 112 points de plus que ce que
/// l'application lui laisse, et on y juge une densité que l'écran ne produit
/// pas. L'en-tête de ce fichier raconte ce que cette erreur a coûté.
Future<void> _monterArticles(
  WidgetTester tester, {
  required double largeur,
  required double hauteur,
  required double echelle,
  required Brightness mode,
  required int onglet,
  required Widget page,
  required CatalogRepository depot,
  required List<Override> surcharges,
  Locale locale = localeFr,
}) async {
  // Même raison que dans `monter` : voir le commentaire là-bas.
  definirLocaleMontants(locale);

  final taille = Size(largeur, hauteur);
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(taille);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith(
          (_) => _FauxAuth(
            const AuthState(
              type: AuthType.staff,
              staffUser: StaffUser(
                id: 1,
                name: 'Administrateur',
                email: 'admin@autoparc.bf',
                role: 'admin',
              ),
            ),
          ),
        ),
        catalogRepositoryProvider.overrideWithValue(depot),
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
        ...surcharges,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeAutoParc(mode),
        home: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
            padding: const EdgeInsets.only(top: 24, bottom: 48),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
          ),
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: page,
                bottomNavigationBar: BarreNavigationPrincipale(
                  selectedIndex: onglet,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      label: l10n.commonHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.directions_car_outlined),
                      label: l10n.commonVehicles,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.tune_outlined),
                      label: l10n.commonAccessories,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      label: l10n.commonParts,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Un dépôt qui rend des pièces et des accessoires fixés, sans réseau.
class _DepotArticles implements CatalogRepository {
  _DepotArticles({this.pieces = const [], this.accessoires = const []});
  final List<Part> pieces;
  final List<Accessory> accessoires;

  @override
  Future<PaginatedResponse<Part>> getParts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? oem,
    int? categoryId,
    String? type,
    String? condition,
    bool inStockOnly = false,
    double? priceMax,
    int? vehicleModelId,
    int? year,
    String? city,
    int? locationId,
  }) async => PaginatedResponse<Part>(
    data: pieces,
    currentPage: 1,
    lastPage: 1,
    total: pieces.length,
    perPage: perPage,
  );

  @override
  Future<PaginatedResponse<Accessory>> getAccessories({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
    String? manufacturerId,
    double? priceMax,
    int? vehicleModelId,
    String? city,
    int? locationId,
  }) async => PaginatedResponse<Accessory>(
    data: accessoires,
    currentPage: 1,
    lastPage: 1,
    total: accessoires.length,
    perPage: perPage,
  );

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Un dépôt qui rend le parc d'échantillon, sans réseau.
class _Depot implements CatalogRepository {
  _Depot(this.liste);
  final List<Vehicle> liste;

  @override
  Future<PaginatedResponse<Vehicle>> getVehicles({
    int page = 1,
    int perPage = 20,
    String? search,
    String? availability,
    String? vehicleType,
    String? bodyStyle,
    String? brandId,
    int? yearMin,
    int? yearMax,
    double? priceMax,
    String? condition,
    String? originCountryId,
    String? city,
    int? locationId,
    bool? customsCleared,
    bool? deal,
  }) async => PaginatedResponse<Vehicle>(
    data: liste,
    currentPage: 1,
    lastPage: 1,
    total: liste.length,
    perPage: perPage,
  );

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Une session figée, sans Firebase : la page ne lit de l'authentification que
/// les capacités.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
