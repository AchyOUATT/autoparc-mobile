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
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  setUpAll(() async {
    await _chargerPolices();

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

  final gabarit = (jsonDecode(
    File('test/fixtures/vehicles_list.json').readAsStringSync(),
  ) as Map<String, dynamic>)['data'][0] as Map<String, dynamic>;

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
    id['brand_slug'] = marque.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
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
  }) async {
    final taille = Size(largeur, hauteur);
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(taille);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      // Une clé neuve à chaque pose : sans elle, Flutter réutilise l'élément du
      // `ProviderScope`, donc son conteneur, donc l'état déjà chargé de
      // `vehicleListProvider` — qui ne relit son dépôt que sur un changement de
      // filtre. Deux captures du même test montreraient le premier jeu.
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith((_) => _FauxAuth(const AuthState(
              type: AuthType.staff,
              staffUser: StaffUser(
                id: 1,
                name: 'Administrateur',
                email: 'admin@autoparc.bf',
                role: 'admin',
              ),
            ))),
        catalogRepositoryProvider.overrideWithValue(_Depot(parc())),
        catalogRefsProvider.overrideWith((_) async => const CatalogRefs(
              brands: [],
              vehicleModels: [],
              trims: [],
              engineTypes: [],
              drivetrains: [],
              colors: [],
              features: [],
              locations: [],
            )),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
          child: const Scaffold(
            body: VehicleListPage(),
            bottomNavigationBar: BarreNavigationPrincipale(
              selectedIndex: 1,
              destinations: [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined), label: 'Accueil'),
                NavigationDestination(
                    icon: Icon(Icons.directions_car_outlined),
                    label: 'Véhicules'),
                NavigationDestination(
                    icon: Icon(Icons.tune_outlined), label: 'Accessoires'),
                NavigationDestination(
                    icon: Icon(Icons.settings_outlined), label: 'Pièces'),
              ],
            ),
          ),
        ),
      ),
    ));
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
  testWidgets('catalogue, 360x720, texte normal, clair', (tester) async {
    await monter(tester,
        largeur: 360, hauteur: 720, echelle: 1.0, mode: Brightness.light);
    await capturer(tester, 'catalogue-360-x10-clair');
  });

  testWidgets('catalogue, 360x720, texte normal, sombre', (tester) async {
    await monter(tester,
        largeur: 360, hauteur: 720, echelle: 1.0, mode: Brightness.dark);
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
    await monter(tester,
        largeur: 320, hauteur: 640, echelle: 1.3, mode: Brightness.light);
    await capturer(tester, 'catalogue-320-x13-clair');
  });

  // LE DERNIER CRAN D'ANDROID. La rangée y fait 509,2 points pour 400,0 de
  // liste : plus aucune annonce n'y tient entière, et c'est le prix assumé du
  // repli — le titre y prend six lignes au lieu d'être ellipsé. Ce qu'on vient
  // voir, c'est si une carte de 509 points reste lisible ou si elle a l'air
  // cassée.
  testWidgets('catalogue, 360x720, très grande police, clair', (tester) async {
    await monter(tester,
        largeur: 360, hauteur: 720, echelle: 2.0, mode: Brightness.light);
    await capturer(tester, 'catalogue-360-x20-clair');
  });

  // L'ÉMULATEUR DE RÉFÉRENCE, et il remplace la capture de tablette en
  // paysage : celle-ci n'avait de sens que tant que deux colonnes étaient
  // réservées aux écrans de plus de 808 points. Deux colonnes sont partout
  // maintenant, et c'est sur un Pixel qu'on regardera l'écran — quatre annonces
  // entières, deux rangées pleines.
  testWidgets('catalogue, 411x923, émulateur de référence', (tester) async {
    await monter(tester,
        largeur: 411, hauteur: 923, echelle: 1.0, mode: Brightness.light);
    await capturer(tester, 'catalogue-411-x10-clair');
  });

  // LES DEUX COLONNES SE DÉCALENT, et c'est le prix visuel de la maçonnerie.
  // Sur un parc où les quatre annonces n'ont ni le même nom ni le même nombre de
  // lignes, la quatrième carte remonte de 16,0 points à 360 et de 36,0 à 411 :
  // la colonne de droite n'est plus en face de celle de gauche. Les cinq
  // captures ci-dessus le montrent déjà ; celle-ci n'existe pas en plus, et
  // c'est dit ici pour que personne ne la cherche.
}

/// Charge Roboto et les icônes Material depuis le cache du SDK.
///
/// Lues là plutôt que copiées dans le dépôt : deux fichiers binaires de plus
/// dans l'historique pour des métriques de test ne se justifient pas, et
/// `captures_controle_test.dart` fait déjà ainsi.
Future<void> _chargerPolices() async {
  final racine = Platform.environment['FLUTTER_ROOT'];
  if (racine == null) return;
  final dossier = Directory('$racine/bin/cache/artifacts/material_fonts');
  if (!dossier.existsSync()) return;

  const fontes = {
    'Roboto': ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf'],
    'MaterialIcons': ['materialicons-regular.otf'],
  };

  for (final entree in fontes.entries) {
    final chargeur = FontLoader(entree.key);
    var trouvee = false;
    for (final nom in entree.value) {
      final fichier = File('${dossier.path}/$nom');
      if (!fichier.existsSync()) continue;
      chargeur.addFont(
          Future.value(fichier.readAsBytesSync().buffer.asByteData()));
      trouvee = true;
    }
    if (trouvee) await chargeur.load();
  }
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
  }) async =>
      PaginatedResponse<Vehicle>(
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
