import 'dart:convert';
import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/widgets/navigation_bar_theme.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La GÉOMÉTRIE des fiches du catalogue : ce qui est peint, pas ce qui est
/// voulu, et sur la PAGE ENTIÈRE plutôt que sur la grille nue.
///
/// ── LES TROIS LEÇONS QUI ONT FAIT CE FICHIER ────────────────────────────────
///
/// 1. ON MESURE SUR LES GLYPHES PEINTS. `vehicle_card_test.dart` affirmait que
///    la ligne de caractéristiques s'affichait ; elle était tronquée sur TOUTES
///    les cartes du catalogue, au réglage de texte par défaut. Son banc assertait
///    `find.text('95 000 km • Auto • Essence')`, et `find.text` compare le champ
///    `data` du widget `Text` : le texte VOULU. Un texte ellipsé le passe sans
///    broncher — l'ellipse se décide à la mise en page, pas à la construction.
///    On lit donc la largeur DEMANDÉE par le paragraphe contre la contrainte
///    qu'il a REÇUE, et `RenderParagraph.didExceedMaxLines`, qui est l'état de
///    dépassement que le `TextPainter` a réellement constaté.
///
///    ET UNE SECONDE LECTURE, qui manquait encore : `didExceedMaxLines` ne dit
///    RIEN d'un mot plus large que la ligne. Un tel mot est posé seul sur sa
///    ligne, dépasse horizontalement, et le `clipBehavior` du `Card` le coupe en
///    silence. On compare donc aussi `TextPainter.minIntrinsicWidth` — la
///    largeur du plus long segment insécable — à la contrainte reçue. C'est
///    cette lecture qui a condamné la ligne de ville : « Dioulasso » réclame 121
///    points pour 105 reçus à 320 points d'écran et à l'échelle 2,0.
///
/// 2. ON CHARGE LA VRAIE POLICE. Le banc d'essai de Flutter n'embarque aucune
///    fonte : il peint chaque caractère comme un carré du corps du texte, et
///    « 95 000 km • Essence » y mesurerait 19 × 12 = 228,0 points contre 117,1
///    avec Roboto — presque le double. Le premier test vérifie que la police
///    chargée EST Roboto ; sans lui, un cache de SDK absent rendrait tout ce
///    fichier vert avec des mesures fausses.
///
/// 3. ON MONTE LA PAGE DANS SA COQUE, ET C'EST LA CORRECTION DU RELECTEUR DE CE
///    LOT. La version précédente de ce fichier montait `VehicleGrid` nue dans un
///    `Scaffold` et comptait les annonces entières contre une hauteur utile
///    écrite à la main — 432,0 points à 320 d'écran, 512,0 à 360. Les deux
///    chiffres étaient FAUX et tous deux trop généreux : la liste vit dans une
///    `ShellRoute` dont la `NavigationBar` et le creux système prennent 112
///    points en bas, et la page porte en plus une barre de titre, une barre de
///    recherche, une bande de puces et un en-tête « N résultats ». Mesuré sur
///    la page montée dans sa coque, la liste dispose de 360,0 points à 320
///    points d'écran, 440,0 à 360 et 643,0 à 411 — et ces chiffres sont LUS dans
///    la hauteur du `Viewport`, jamais posés.
///
///    LES TROIS CHIFFRES ONT MONTÉ DE 40,0 POINTS avec la bande unique : la
///    page portait DEUX rangées de puces de 44 points, elle n'en porte plus
///    qu'une, de 48. Ils valaient 320,0 / 400,0 / 603,0 avant ce lot.
///
/// ── CE QUE CE FICHIER VERROUILLE ────────────────────────────────────────────
///
/// DEUX ANNONCES PAR RANGÉE, à toutes les largeurs de téléphone : c'est la
/// décision du propriétaire, et le tableau la vérifie case par case.
///
/// RIEN N'EST TRONQUÉ. Ni le titre, ni les caractéristiques, ni le prix, ni le
/// badge — à 320, 360 et 411 points, aux échelles 1,0 / 1,3 / 1,5 / 2,0, dans
/// les deux modes du thème. La grille d'origine coupait le titre dans les DOUZE
/// configurations.
///
/// LE PRIX NE SE COUPE JAMAIS. « 9 500 000 FCFA » coupé en « 9 500 00… » se lit
/// comme un dixième du prix. L'assertion est doublée d'un test de non-vacuité :
/// un prix que même le plancher absolu ne peut loger DOIT être vu comme coupé.
/// Un test de régression qu'aucune régression ne déclenche ne protège rien.
void main() {
  setUpAll(_chargerPolices);

  // ── Le gabarit du catalogue, remoulé champ par champ ──────────────────────

  final gabarit = (jsonDecode(
    File('test/fixtures/vehicles_list.json').readAsStringSync(),
  ) as Map<String, dynamic>)['data'][0] as Map<String, dynamic>;

  /// LE PIRE CONTENU QUE LE SERVEUR PUISSE RENDRE, et chaque valeur est tirée
  /// du référentiel du backend, pas inventée :
  ///
  /// — « Land Rover Range Rover Sport » est la plus longue combinaison marque +
  ///   modèle de `database/seeders/VehicleModelsSeeder.php` croisée avec
  ///   `BrandsSeeder.php` (35 signes avec l'année) ;
  /// — « TRD Off-Road » est la plus longue finition de `TrimsSeeder.php` ;
  /// — « Électrique » est le plus long des quatre libellés de carburant ;
  /// — « Vente & Location » est le plus large des quatre libellés de
  ///   disponibilité ;
  /// — « Showroom Paspanga — Bobo-Dioulasso » suit le gabarit `nom — ville` de
  ///   `Vehicle.locationLabel`, avec les exemples nommés dans la migration
  ///   `create_locations_table` et la plus longue ville du parc ;
  /// — 246 965 km : six chiffres, le kilométrage du jeu de données de la fiche
  ///   de détail ;
  /// — 99 999 999 FCFA : huit chiffres, la borne demandée.
  ///
  /// La finition et la ville sont toujours renseignées, même si la carte ne les
  /// affiche plus : elles doivent rester dans le gabarit pour que le jour où
  /// quelqu'un les y remet, le tableau mesure le pire cas et non un cas vide.
  ///
  /// Pas de photo par défaut : `CatalogImage` irait chercher le réseau, que le
  /// banc d'essai refuse, et la vignette ne décide d'aucune largeur de texte.
  Vehicle vehicule({
    String marque = 'Land Rover',
    String modele = 'Range Rover Sport',
    String? finition = 'TRD Off-Road',
    int? kilometrage = 246965,
    String? motorisation = 'Électrique',
    String? boite = 'automatic',
    String disponibilite = 'both',
    String? agence = 'Showroom Paspanga',
    String? ville = 'Bobo-Dioulasso',
    String? affaire = 'Bonne affaire',
    String prix = '99999999.00',
    int photos = 0,
  }) {
    final json = jsonDecode(jsonEncode(gabarit)) as Map<String, dynamic>;
    final id  = json['identity']  as Map<String, dynamic>;
    final tec = json['technical'] as Map<String, dynamic>;
    final com = json['commercial'] as Map<String, dynamic>;
    id['brand']  = marque;
    id['model']  = modele;
    id['year']   = 2018;
    id['trim']   = finition;
    id['engine_type']  = motorisation;
    tec['transmission'] = boite;
    tec['mileage_km']   = kilometrage;
    com['availability'] = disponibilite;
    com['sale_price']   = prix;
    com['rental_daily_rate'] = null;
    com['deal_label']   = affaire;
    com['location'] = agence == null && ville == null
        ? null
        : {'id': 3, 'name': agence, 'city': ville};
    com['site'] = null;
    // `<dynamic>` et `<String, dynamic>` explicites : sans eux l'inférence
    // produit un `List<Map<String, Object>>`, et `Vehicle.fromJson` y casse sur
    // le `orElse` de son `firstWhere`. Le vrai JSON du serveur arrive toujours
    // en `dynamic` ; c'est le banc qui mentirait sur sa forme.
    json['media'] = <dynamic>[
      for (var i = 0; i < photos; i++)
        <String, dynamic>{
          'id': i + 1,
          'url': 'https://exemple.test/p$i.jpg',
          'is_cover': i == 0,
          'position': i,
        },
    ];
    return Vehicle.fromJson(json);
  }

  // ── Les écrans et les échelles du tableau ─────────────────────────────────

  /// 320 × 640 : le plus petit format encore courant (Galaxy A01, iPhone SE
  /// première génération). 360 × 720 : la médiane du parc Android. 411 × 923 :
  /// le Pixel de l'émulateur par défaut, donc l'écran sur lequel un défaut ne se
  /// voit pas.
  ///
  /// LA HAUTEUR ENTRE DANS LE TABLEAU, et c'est nouveau : la densité se compte
  /// sur la page entière, donc sur un écran entier, et un téléphone de 320
  /// points de large n'a jamais 923 points de haut.
  const ecrans = <String, Size>{
    '320x640': Size(320, 640),
    '360x720': Size(360, 720),
    '411x923': Size(411, 923),
  };

  /// 1,0 est le réglage par défaut — et c'est là que le défaut d'origine vivait.
  /// 1,3 est le deuxième cran des réglages Android, « Grande police ». 1,5 est
  /// le troisième. 2,0 EST LE DERNIER, et c'est le cran qu'aucun lot avant
  /// l'avant-dernier n'avait mesuré.
  const echelles = <double>[1.0, 1.3, 1.5, 2.0];

  const modes = <String, Brightness>{
    'clair':  Brightness.light,
    'sombre': Brightness.dark,
  };

  // ── Les outils de mesure ──────────────────────────────────────────────────

  /// La largeur que ce paragraphe DEMANDE, remis en page sans borne et sur une
  /// seule ligne.
  double voulue(RenderParagraph p) => (TextPainter(
        text: p.text,
        textDirection: p.textDirection,
        textScaler: p.textScaler,
        maxLines: 1,
      )..layout())
      .width;

  /// La largeur que ce paragraphe a REÇUE.
  ///
  /// Lue dans la contrainte de l'objet de rendu, et non recalculée depuis la
  /// largeur de la case : c'est la seule valeur qui compte toutes les marges
  /// intermédiaires sans qu'on ait à les connaître — celle du `Card`, celle du
  /// `Padding` du bloc de texte, et les 14 points que l'icône de localisation
  /// retirait à la ligne de ville.
  double recue(RenderParagraph p) => p.constraints.maxWidth;

  /// Le paragraphe remis en page à la largeur qu'il a REÇUE.
  TextPainter pose(RenderParagraph p) => TextPainter(
        text: p.text,
        textDirection: p.textDirection,
        textScaler: p.textScaler,
      )..layout(maxWidth: p.constraints.maxWidth);

  /// La largeur du plus long segment INSÉCABLE du paragraphe.
  ///
  /// C'est la mesure qui attrape ce que `didExceedMaxLines` laisse passer : un
  /// mot plus large que la ligne est posé seul sur sa ligne et dépasse
  /// horizontalement, sans que le paragraphe se déclare tronqué. Le `Card` le
  /// rogne alors en silence.
  double motLePlusLarge(RenderParagraph p) => pose(p).minIntrinsicWidth;

  /// Combien de lignes le paragraphe occupe réellement à la largeur reçue.
  int lignesPosees(RenderParagraph p) => pose(p).computeLineMetrics().length;

  /// Le plus long préfixe du texte qui tienne dans [dispo] AVEC son ellipse.
  ///
  /// C'est-à-dire ce que l'œil voit réellement. `didExceedMaxLines` dit QU'IL
  /// manque des signes ; ceci dit LESQUELS restent.
  String peint(RenderParagraph p, double dispo) {
    final texte = (p.text as TextSpan).toPlainText();
    if (voulue(p) <= dispo) return texte;
    var garde = '';
    for (var n = 1; n <= texte.length; n++) {
      final tp = TextPainter(
        text: TextSpan(
            text: '${texte.substring(0, n)}…',
            style: (p.text as TextSpan).style),
        textDirection: p.textDirection,
        textScaler: p.textScaler,
        maxLines: 1,
      )..layout();
      if (tp.width > dispo) break;
      garde = texte.substring(0, n);
    }
    return garde;
  }

  // ── LA COQUE, et c'est elle que le relecteur réclamait ────────────────────

  /// Monte `VehicleListPage` DANS SA COQUE, à la taille d'écran demandée.
  ///
  /// La coque reproduit `_AppShell` de `main.dart`, qui est privé : un
  /// `Scaffold` dont le `bottomNavigationBar` est la `NavigationBar` des quatre
  /// onglets.
  ///
  /// ELLE NE LA RECOPIE PLUS À LA MAIN, et c'est la correction de ce lot : le
  /// banc et l'application construisaient chacun leur barre habillée, et les
  /// deux ont divergé — la copie du banc n'avait pas la borne d'échelle de
  /// texte qui empêche « Accessoires » de se casser sur deux lignes à 320
  /// points et à l'échelle 1,3. Les deux passent désormais par
  /// `BarreNavigationPrincipale`. Ces 64 points de barre plus
  /// les 48 du creux système font les 112 points que la version précédente de ce
  /// fichier offrait gratuitement à la liste — c'est le test
  /// « la coque retire bien ses 112 points » qui le verrouille.
  ///
  /// Les creux du système sont posés comme dans `responsive_test.dart` : sans
  /// eux on mesure un appareil sans barre d'état ni barre de navigation, c'est à
  /// dire aucun appareil réel. 48 en bas, la barre à trois boutons, qui est le
  /// cas le plus contraignant.
  ///
  /// `tester.view.physicalSize`, `setSurfaceSize` ET `MediaQueryData.size` : la
  /// première décide de la surface rendue, la seconde de la fenêtre du banc, la
  /// troisième de ce que la page lit. Les laisser diverger mesurerait un écran
  /// qui n'existe pas.
  Future<Object?> poserPage(
    WidgetTester tester, {
    required Size ecran,
    required double echelle,
    required Brightness mode,
    required List<Vehicle> vehicules,
  }) async {
    tester.view.physicalSize = ecran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(ecran);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      // UNE CLÉ NEUVE À CHAQUE POSE, et ce n'est pas une précaution : sans
      // elle, Flutter réutilise l'élément du `ProviderScope` d'une pose à la
      // suivante, donc son conteneur, donc l'état déjà chargé de
      // `vehicleListProvider` — qui ne relit son dépôt que sur un changement de
      // filtre. Deux poses dans le même test mesuraient alors DEUX FOIS le
      // premier jeu de véhicules, et un test de contenu y passait au vert sans
      // avoir rien remplacé.
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
        catalogRepositoryProvider.overrideWithValue(_Depot(vehicules)),
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
        theme: themeAutoParc(mode),
        home: MediaQuery(
          data: MediaQueryData(
            size: ecran,
            textScaler: TextScaler.linear(echelle),
            padding: const EdgeInsets.only(top: 24, bottom: 48),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
          ),
          child: Builder(
            builder: (context) => const Scaffold(
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
      ),
    ));
    // Le dépôt répond sur une microtâche ; cinq pompes laissent la page passer
    // de son indicateur de chargement à ses cartes.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return tester.takeException();
  }

  /// La hauteur UTILE de la liste, LUE et non posée.
  ///
  /// C'est la hauteur du `Viewport` qui porte les cartes : la barre de titre, la
  /// barre de recherche, les deux rangées de puces, l'en-tête « N résultats » et
  /// les 112 points de la coque en sont déjà déduits par la mise en page
  /// elle-même.
  double utile(WidgetTester tester) => tester
      .renderObject<RenderBox>(find.descendant(
          of: find.byType(VehicleGrid), matching: find.byType(Viewport)))
      .size
      .height;

  /// Les rangées réellement posées, chacune avec son haut, son bas et le nombre
  /// de cartes qu'elle porte.
  ///
  /// Groupées par le HAUT des cartes. CE REGROUPEMENT N'EST PLUS UNE PROPRIÉTÉ DE
  /// LA GRILLE DEPUIS LA MAÇONNERIE : deux colonnes qui se remplissent
  /// indépendamment n'alignent plus leurs cartes, et seules les deux PREMIÈRES
  /// partagent encore leur `dy`. Les appelants de ce banc posent tous des
  /// véhicules IDENTIQUES — même contenu, donc même hauteur de carte —, et c'est
  /// cela, et cela seul, qui refait coïncider les ordonnées colonne par colonne.
  /// Un test qui poserait des contenus inégaux verrait autant de « rangées » que
  /// de cartes, et il aurait raison. Les ordonnées sont relatives au haut du
  /// `Viewport`, pour se comparer à [utile].
  List<({double haut, double bas, int cartes})> rangs(WidgetTester tester) {
    final origine = tester
        .renderObject<RenderBox>(find.descendant(
            of: find.byType(VehicleGrid), matching: find.byType(Viewport)))
        .localToGlobal(Offset.zero)
        .dy;

    final parHaut = <double, List<RenderBox>>{};
    for (final carte
        in tester.renderObjectList<RenderBox>(find.byType(VehicleCard))) {
      final haut = carte.localToGlobal(Offset.zero).dy - origine;
      parHaut.putIfAbsent(haut, () => []).add(carte);
    }

    final cles = parHaut.keys.toList()..sort();
    return [
      for (final haut in cles)
        (
          haut: haut,
          bas: haut +
              parHaut[haut]!
                  .map((c) => c.size.height)
                  .reduce((a, b) => a > b ? a : b),
          cartes: parHaut[haut]!.length,
        ),
    ];
  }

  /// Les lignes nommées de la PREMIÈRE carte, chacune par un morceau de texte.
  ///
  /// La finition et la ville n'y sont plus : la carte ne les porte plus, et les
  /// chercher ferait échouer le tableau pour la bonne raison — le test de
  /// contenu, plus bas, dit qu'elles sont parties et pourquoi.
  Map<String, RenderParagraph> lignes(WidgetTester tester) {
    final carte = find.byType(VehicleCard).first;
    RenderParagraph p(Finder f) =>
        tester.renderObject<RenderParagraph>(find.descendant(
          of: carte,
          matching: f,
        ));
    return {
      'titre': p(find.text('Land Rover Range Rover Sport (2018)')),
      'specs': p(find.textContaining('km')),
      'prix':  p(find.textContaining('FCFA')),
      'badge': p(find.text('Vente & Location')),
      'affaire': p(find.text('Bonne affaire')),
    };
  }

  // ── Le garde-fou de la police ─────────────────────────────────────────────

  testWidgets('la vraie police est chargée, et le banc le vérifie',
      (tester) async {
    // 19 signes en corps 12 : la police du banc d'essai en ferait 228,0 points,
    // Roboto 117,1. Le seuil est posé largement au-dessous de la première et
    // largement au-dessus de la seconde — il ne mesure pas une métrique
    // précise, il distingue deux polices qui n'ont rien à voir.
    final tp = TextPainter(
      text: const TextSpan(
        text: '95 000 km • Essence',
        style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();

    expect(tp.width, lessThan(170.0),
        reason: 'Roboto n\'est pas chargée : ${tp.width.toStringAsFixed(1)} '
            'points pour « 95 000 km • Essence » en corps 12, alors que la '
            'police du banc d\'essai en donnerait 228,0. Toutes les mesures de '
            'ce fichier seraient fausses, et vertes. Le cache du SDK est-il là '
            '(\$FLUTTER_ROOT/bin/cache/artifacts/material_fonts) ?');
  });

  // ── Le garde-fou de la coque ──────────────────────────────────────────────

  testWidgets('la coque retire bien ses 112 points à la liste',
      (tester) async {
    // LE DÉFAUT QUE LE RELECTEUR A RELEVÉ, rendu impossible à reconduire. La
    // version précédente comptait les annonces contre 512,0 points à 360
    // d'écran ; la liste n'en a que 400,0. L'écart venait d'ici.
    //
    // La hauteur de la barre n'est pas écrite en clair : elle est LUE dans
    // `barreNavigationTheme`, qui est la source de vérité de l'application. Si
    // quelqu'un y change 64, ce test suit au lieu de mentir.
    await poserPage(tester,
        ecran: const Size(360, 720),
        echelle: 1.0,
        mode: Brightness.light,
        vehicules: [vehicule()]);

    final barre = tester.renderObject<RenderBox>(find.byType(NavigationBar));
    final attendue =
        barreNavigationTheme(themeAutoParc(Brightness.light).colorScheme)
                .height! +
            48;

    expect(barre.size.height, closeTo(attendue, 0.01),
        reason: 'La coque de mesure ne reproduit plus celle de `_AppShell` : '
            'la barre fait ${barre.size.height.toStringAsFixed(1)} points au '
            'lieu de ${attendue.toStringAsFixed(1)}. Tout le tableau de densité '
            'mesurerait une page qui n\'existe pas.');

    // 392,0 : TROIS ÉTATS SE SONT SUCCÉDÉ ICI, et les garder écrits évite de
    // refaire deux fois le même raisonnement.
    //   400,0  deux bandes de 44 — cible tactile rabotée à 44, sous le
    //          plancher Material de 48, et personne ne le voyait ;
    //   440,0  une bande de 48 — 40 points rendus, mais les carrosseries
    //          derrière un défilement horizontal ;
    //   392,0  deux bandes de 48 — les carrosseries revisibles, et 8 points
    //          de moins qu'à l'origine parce que la cible tactile, elle, est
    //          désormais respectée.
    // Le dernier état est celui que le propriétaire a choisi en connaissant
    // le prix : voir le tableau de densité, deux cases y perdent.
    expect(utile(tester), closeTo(392.0, 0.01),
        reason: 'La liste dispose de ${utile(tester).toStringAsFixed(1)} points '
            'à 360 × 720 au lieu de 392,0. Le chrome de la page a changé, et '
            'les comptes d\'annonces du tableau avec lui — remesurez avant de '
            'les réécrire.');
  });

  // ── LE TABLEAU DE TRONCATURE, remesuré à chaque exécution ─────────────────

  group('Tableau de troncature', () {
    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        for (final mode in modes.entries) {
          testWidgets('${ecran.key}, texte x$echelle, ${mode.key}',
              (tester) async {
            final exception = await poserPage(
              tester,
              ecran: ecran.value,
              echelle: echelle,
              mode: mode.value,
              vehicules: List.generate(4, (_) => vehicule()),
            );

            final mesures = lignes(tester);

            final rapport = <String>[];
            mesures.forEach((nom, p) {
              rapport.add('${nom.padRight(8)}'
                  ' ${voulue(p).toStringAsFixed(1).padLeft(6)}'
                  '/${recue(p).toStringAsFixed(1).padLeft(6)}'
                  ' mot=${motLePlusLarge(p).toStringAsFixed(1).padLeft(6)}'
                  ' lignes=${lignesPosees(p)}'
                  ' corps=${(p.text as TextSpan).style?.fontSize?.toStringAsFixed(1) ?? "?"}'
                  ' ${p.didExceedMaxLines ? "COUPÉ peint=\"${peint(p, recue(p))}\"" : "entier"}');
            });

            // ignore: avoid_print
            print('── troncature ${ecran.key}, x$echelle, ${mode.key} ──'
                '\n   ${rapport.join('\n   ')}');

            // 1. AUCUNE LIGNE N'EST TRONQUÉE.
            mesures.forEach((nom, p) {
              expect(p.didExceedMaxLines, isFalse,
                  reason: '$nom TRONQUÉ en ${ecran.key} à l\'échelle $echelle '
                      '(thème ${mode.key}) : ${voulue(p).toStringAsFixed(1)} '
                      'points voulus pour ${recue(p).toStringAsFixed(1)} '
                      'reçus. Il n\'en reste peint que '
                      '« ${peint(p, recue(p))} ».');
            });

            // 2. AUCUN MOT NE DÉBORDE DE SA LIGNE. C'est la troncature que
            //    `didExceedMaxLines` ne voit pas, et que le `Card` coupe sans
            //    rien signaler.
            mesures.forEach((nom, p) {
              expect(motLePlusLarge(p), lessThanOrEqualTo(recue(p) + 0.01),
                  reason: '$nom a un mot de '
                      '${motLePlusLarge(p).toStringAsFixed(1)} points pour '
                      '${recue(p).toStringAsFixed(1)} reçus en ${ecran.key} à '
                      'l\'échelle $echelle : il sera rogné par le `Card` sans '
                      'ellipse, donc en silence.');
            });

            // 3. LE PRIX GARDE SON CORPS DEMANDÉ TANT QU'IL LE PEUT, ET NE
            //    DESCEND JAMAIS SOUS LE PLANCHER DE CONFORT.
            //
            //    Deux colonnes ne laissent au prix que 119,0 points à 320
            //    points d'écran et 139,0 à 360. « 99 999 999 FCFA » en réclame
            //    136,5 au corps nominal de 18,2 à l'échelle 1,3 : la réduction
            //    s'y déclenche déjà à 320 points, et c'est voulu — un prix
            //    rendu plus petit reste VRAI, un prix coupé devient FAUX.
            //
            //    Ce qui est verrouillé est donc l'encadrement, pas le corps
            //    exact : jamais plus que le corps demandé, jamais moins que
            //    celui qu'aurait ce prix sur un téléphone qui n'a rien réglé.
            final corpsPrix =
                (mesures['prix']!.text as TextSpan).style!.fontSize!;
            expect(corpsPrix, lessThanOrEqualTo(14.0 * echelle + 0.05),
                reason: 'Le prix est peint en '
                    '${corpsPrix.toStringAsFixed(1)}, plus GRAND que le corps '
                    'demandé (${(14.0 * echelle).toStringAsFixed(1)}).');
            expect(corpsPrix, greaterThanOrEqualTo(14.0),
                reason: 'Le prix est descendu à '
                    '${corpsPrix.toStringAsFixed(1)} en ${ecran.key} à '
                    'l\'échelle $echelle, sous le corps qu\'il aurait au '
                    'réglage par défaut : le plancher de confort a cédé. On ne '
                    'rend pas le prix plus petit à quelqu\'un qui a grossi ses '
                    'polices.');

            // 4. Aucune bande rayée. Acquis par construction — la rangée n'a
            //    plus de budget vertical imposé d'en haut —, et l'assertion
            //    reste parce que c'est exactement ce qu'un `childAspectRatio`
            //    réintroduirait.
            expect(exception, isNull,
                reason: 'Débordement en ${ecran.key} à l\'échelle $echelle, '
                    'thème ${mode.key}.');
          });
        }
      }
    }
  });

  // ── DEUX PAR RANGÉE, ET C'EST LA DÉCISION DU PROPRIÉTAIRE ─────────────────

  group('Deux colonnes en maçonnerie', () {
    testWidgets('à toutes les largeurs et à toutes les échelles',
        (tester) async {
      // L'ANCIEN SEUIL EST MORT. Il valait 808 points, donc aucun téléphone
      // n'avait deux colonnes : le parc visé — 320 à 430 points — était en
      // colonne unique. Le propriétaire a tranché pour deux par rangée partout,
      // et ce test est la décision rendue vérifiable.
      for (final ecran in ecrans.values) {
        for (final echelle in echelles) {
          await poserPage(tester,
              ecran: ecran,
              echelle: echelle,
              mode: Brightness.light,
              vehicules: List.generate(4, (_) => vehicule()));

          final r = rangs(tester);
          expect(r, isNotEmpty,
              reason: 'Aucune rangée posée en '
                  '${ecran.width.toStringAsFixed(0)} points.');
          for (final rangee in r) {
            expect(rangee.cartes, 2,
                reason: 'Une rangée porte ${rangee.cartes} carte(s) en '
                    '${ecran.width.toStringAsFixed(0)} points à l\'échelle '
                    '$echelle, et quatre véhicules en font deux rangées '
                    'pleines.');
          }
        }
      }
    });

    testWidgets('la dernière annonce d\'une colonne impaire garde sa '
        'demi-largeur', (tester) async {
      // CE QUI LE GARANTIT A CHANGÉ AVEC LA MAÇONNERIE, et c'est pour le mieux :
      // ce n'était qu'un second `Expanded` laissé vide dans la rangée, c'est
      // maintenant la structure elle-même — les deux colonnes SONT les deux
      // `Expanded` du `Row`, donc chacune fait la moitié de la largeur utile
      // quel que soit le nombre de cartes qu'elle porte.
      //
      // L'assertion porte sur TOUTES les cartes et plus seulement sur la
      // dernière : avec un nombre impair, la carte solitaire est celle d'une
      // colonne dont l'index dans l'arbre dépend de l'ordre de parcours, et le
      // test d'avant comparait en fait deux cartes au hasard.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: List.generate(3, (_) => vehicule()));

      final cartes =
          tester.renderObjectList<RenderBox>(find.byType(VehicleCard)).toList();
      expect(cartes.length, 3);

      // La demi-largeur, DÉDUITE de la mise en page et non écrite à la main :
      // 360 d'écran − 24 de `SliverPadding` − 10 d'écart, divisé par deux.
      const demie = (360.0 - 24.0 - 10.0) / 2;
      for (final carte in cartes) {
        expect(carte.size.width, closeTo(demie, 0.01),
            reason: 'Une carte fait ${carte.size.width.toStringAsFixed(1)} '
                'points au lieu de ${demie.toStringAsFixed(1)} : la colonne la '
                'plus courte s\'est étalée sur toute la largeur, et la liste '
                'finit sur une carte deux fois plus large que les autres.');
      }
    });
  });

  // ── LA HAUTEUR INTRINSÈQUE, qui est le mécanisme du lot ───────────────────

  group('Cartes à hauteur intrinsèque', () {
    testWidgets('la hauteur de la rangée suit son contenu', (tester) async {
      // LA PROPRIÉTÉ QUI SUPPRIME LA TRONCATURE DU TITRE. Un
      // `SliverGridDelegateWithFixedCrossAxisCount` impose à toutes les cases la
      // même hauteur, calculée depuis la largeur : le texte ne peut plus se
      // replier, il ne lui reste que l'ellipse. Ici il n'y a plus de budget, donc
      // une annonce pauvre fait une rangée PLUS COURTE.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: List.generate(2, (_) => vehicule()));
      final riche = rangs(tester).first;

      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: List.generate(
              2,
              (_) => vehicule(
                    marque: 'Kia',
                    modele: 'Rio',
                    finition: null,
                    agence: null,
                    ville: null,
                    affaire: null,
                    kilometrage: null,
                    motorisation: null,
                    boite: null,
                    prix: '3200000.00',
                  )));
      final maigre = rangs(tester).first;

      expect(maigre.bas - maigre.haut, lessThan(riche.bas - riche.haut),
          reason: 'Une annonce pauvre fait une rangée de '
              '${(maigre.bas - maigre.haut).toStringAsFixed(1)} points contre '
              '${(riche.bas - riche.haut).toStringAsFixed(1)} pour le pire '
              'contenu : la hauteur est redevenue fixe, et le titre va se '
              'faire ellipser.');
    });

    testWidgets('les deux premières cartes partent du même haut, chacune à sa '
        'hauteur', (tester) async {
      // C'est ce qui remplace `IntrinsicHeight`, refusé par
      // `_RenderLayoutBuilder.computeMaxIntrinsicHeight` — c'est-à-dire par
      // `_PrixAjuste`, qui lit la largeur qu'il reçoit et ne peut donc pas
      // répondre à une question de taille intrinsèque.
      //
      // CE QUI EST VÉRIFIÉ ICI NE VAUT QUE POUR LA PREMIÈRE PAIRE, et c'est la
      // maçonnerie qui l'a réduit à ça : les deux colonnes partent du même haut
      // — c'est le `CrossAxisAlignment.start` du `Row` —, mais dès la troisième
      // annonce elles se décalent, le propriétaire ayant dit que l'alignement
      // n'était pas nécessaire. Deux cartes de contenus INÉGAUX sont posées
      // exprès : c'est le seul cas où le décalage ne peut pas encore se produire,
      // donc le seul où cette assertion a un sens.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [
            vehicule(),
            vehicule(marque: 'Kia', modele: 'Rio', prix: '3200000.00'),
          ]);

      final cartes =
          tester.renderObjectList<RenderBox>(find.byType(VehicleCard)).toList();
      final rangee = rangs(tester).first;
      final plusHaute = cartes
          .map((c) => c.size.height)
          .reduce((a, b) => a > b ? a : b);

      expect(rangee.bas - rangee.haut, closeTo(plusHaute, 0.01));
      expect(cartes[0].localToGlobal(Offset.zero).dy,
          closeTo(cartes[1].localToGlobal(Offset.zero).dy, 0.01),
          reason: 'Les deux cartes d\'une rangée ne sont plus alignées en '
              'haut : la ligne de lecture de la liste est perdue.');
    });

    testWidgets('la photo garde son ratio et s\'aligne entre les colonnes',
        (tester) async {
      // LE RATIO EST FIXE, et c'est ce qui aligne les vignettes : les deux
      // cartes d'une rangée ont la même largeur, donc la même hauteur de photo
      // et le même bord inférieur de photo. La carte du lot précédent étirait sa
      // photo sur toute la hauteur ; deux cartes voisines auraient eu des
      // vignettes de hauteurs différentes dès qu'un titre se replie une ligne de
      // plus que l'autre.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [
            vehicule(),
            vehicule(marque: 'Kia', modele: 'Rio', prix: '3200000.00'),
          ]);

      final photos =
          tester.renderObjectList<RenderBox>(find.byKey(clePhoto)).toList();
      expect(photos.length, 2);

      for (final photo in photos) {
        expect(photo.size.width / photo.size.height, closeTo(16 / 9, 0.01),
            reason: 'La photo est à '
                '${(photo.size.width / photo.size.height).toStringAsFixed(2)} '
                'au lieu de 16:9 : les vignettes ne s\'alignent plus entre '
                'colonnes.');
      }
      expect(photos[0].size.height, closeTo(photos[1].size.height, 0.01));
      expect(photos[0].localToGlobal(Offset(0, photos[0].size.height)).dy,
          closeTo(photos[1].localToGlobal(Offset(0, photos[1].size.height)).dy,
              0.01),
          reason: 'Les deux vignettes d\'une rangée ne finissent plus à la '
              'même hauteur.');
    });
  });

  // ── CE QUE LA CARTE PORTE, ET CE QUI EST PARTI ────────────────────────────

  group('Le contenu de la carte', () {
    testWidgets('titre, caractéristiques et prix — pas la finition, pas la '
        'ville', (tester) async {
      // LA DÉCISION DE CONTENU, TRANCHÉE PAR LA MESURE et pas par le goût.
      //
      // CINQ COMBINAISONS, toutes mesurées sur la page montée dans sa coque,
      // avec la photo en 16:9 du code livré, sur le pire contenu du
      // référentiel. Hauteur de RANGÉE aux échelles 1,0 / 1,3 / 1,5 / 2,0, puis
      // nombre d'annonces ENTIÈRES :
      //
      // CE TABLEAU EST CELUI DU LOT QUI A TRANCHÉ LE CONTENU, et il est donc
      // daté : ses hauteurs de liste — 320,0 / 400,0 / 603,0 — sont celles
      // d'avant la bande de filtres unique, qui en a rendu 40,0 de plus. Les
      // hauteurs de RANGÉE, qui sont ce que la décision de contenu compare,
      // n'ont pas bougé d'un point ; les comptes d'annonces de la colonne de
      // droite, eux, se lisent dans le groupe « Densité » plus bas, remesurés.
      //
      //                              320x640 (320,0 pt de liste)
      //   tout                      299,9 / 375,9 / 441,9 / 785,9 → 0 0 0 0
      //   sans la finition          281,9 / 352,9 / 415,9 / 719,9 → 0 0 0 0
      //   sans finition ni ville    231,9 / 266,9 / 317,9 / 525,9 → 2 2 0 0
      //   titre + prix seuls        197,9 / 222,9 / 267,9 / 427,9 → 2 2 0 0
      //   ville réduite à la ville  249,9 / 310,9 / 367,9 / 623,9 → 2 0 0 0
      //
      //                              360x720 (400,0 pt de liste)
      //   tout                      259,2 / 370,2 / 427,2 / 705,2 → 2 0 0 0
      //   sans la finition          241,2 / 347,2 / 401,2 / 639,2 → 2 2 0 0
      //   sans finition ni ville    207,2 / 282,2 / 303,2 / 509,2 → 2 2 2 0
      //   titre + prix seuls        189,2 / 238,2 / 253,2 / 443,2 → 2 2 2 0
      //   ville réduite à la ville  225,2 / 305,2 / 353,2 / 575,2 → 2 2 0 0
      //
      //                              411x923 (603,0 pt de liste)
      //   tout                      273,5 / 358,5 / 421,5 / 540,5 → 4 2 2 0
      //   sans la finition          255,5 / 335,5 / 395,5 / 506,5 → 4 2 2 2
      //   sans finition ni ville    221,5 / 270,5 / 321,5 / 376,5 → 4 4 2 2
      //   titre + prix seuls        203,5 / 226,5 / 271,5 / 310,5 → 4 4 2 2
      //   ville réduite à la ville  239,5 / 293,5 / 347,5 / 442,5 → 4 2 2 2
      //
      // Garder tout rend ZÉRO annonce entière à 320 points, y compris au
      // réglage de texte PAR DÉFAUT — donc pire que la colonne unique qu'on
      // remplace, qui en montrait une. Et à 320 points et à l'échelle 2,0 la
      // ville y est COUPÉE, pas ellipsée : « Dioulasso » réclame 121 points
      // pour les 105 que sa ligne reçoit, il est donc posé seul sur sa ligne et
      // rogné par le `clipBehavior` du `Card`, sans ellipse et sans exception.
      // C'est la mesure du segment insécable qui l'a vue.
      //
      // « Sans finition ni ville » et « titre + prix seuls » donnent EXACTEMENT
      // le même compte dans les DOUZE cases : les caractéristiques sont
      // gratuites, et elles restent — c'est le premier filtre d'un acheteur.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [vehicule()]);

      expect(find.text('Land Rover Range Rover Sport (2018)'), findsOneWidget);
      // « 246 965 » s'écrit avec une espace fine insécable (U+202F) : la
      // chercher avec une espace ordinaire ne trouve rien, et le test aurait
      // échoué pour la mauvaise raison.
      expect(find.textContaining('km'), findsOneWidget);
      expect(find.textContaining('Électrique'), findsOneWidget);
      expect(find.textContaining('FCFA'), findsOneWidget);
      expect(find.text('Bonne affaire'), findsOneWidget);

      expect(find.text('TRD Off-Road'), findsNothing,
          reason: 'La finition est revenue sur la carte : elle coûte une '
              'annonce entière à 320 points dès le réglage par défaut.');
      expect(find.textContaining('Paspanga'), findsNothing,
          reason: 'La ville est revenue sur la carte : elle coûte une annonce '
              'entière à 320 points dès « Grande police », et « Dioulasso » '
              'est un mot plus large que la ligne à l\'échelle 2,0.');
      expect(find.textContaining('Bobo-Dioulasso'), findsNothing);
    });

    testWidgets('la boîte de vitesses reste hors de la ligne de '
        'caractéristiques', (tester) async {
      // Elle coûte onze signes, donc une ligne de repli, donc de la HAUTEUR —
      // et la hauteur est exactement ce que la seconde colonne rend rare. Elle
      // reste sur la fiche du véhicule, où l'acheteur s'engage.
      await poserPage(tester,
          ecran: const Size(411, 923),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [vehicule()]);

      expect(find.textContaining('Automatique'), findsNothing);
      expect(find.textContaining('Manuelle'), findsNothing);
    });

    testWidgets('le compteur de photos s\'affiche à partir de deux',
        (tester) async {
      // Décision déjà prise et mesurée, à conserver. « 1 photos » est faux, et
      // « 1 photo » n'annoncerait rien de plus que la vignette elle-même.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [vehicule(photos: 3)]);
      expect(find.text('3 photos'), findsOneWidget);

      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [vehicule(photos: 1)]);
      expect(find.textContaining('photo'), findsNothing);
    });

    testWidgets('le compteur de photos tient à 320 points et à l\'échelle 2,0',
        (tester) async {
      // LE CAS OÙ IL DÉBORDAIT. « 12 photos » en corps 20 réclame 92,0 points
      // et l'icône et son espace 14 de plus, pour 107,0 reçus : c'est pour ça
      // qu'il est replié en deux et que son `Positioned` est borné à gauche.
      final exception = await poserPage(tester,
          ecran: const Size(320, 640),
          echelle: 2.0,
          mode: Brightness.light,
          vehicules: [vehicule(photos: 12)]);

      expect(exception, isNull,
          reason: 'Le compteur de photos fait déborder la vignette.');

      final libelle =
          tester.renderObject<RenderParagraph>(find.text('12 photos'));
      expect(libelle.didExceedMaxLines, isFalse,
          reason: '« 12 photos » est coupé : '
              '${voulue(libelle).toStringAsFixed(1)} points voulus pour '
              '${recue(libelle).toStringAsFixed(1)} reçus.');
      expect(motLePlusLarge(libelle), lessThanOrEqualTo(recue(libelle) + 0.01),
          reason: 'Un mot du compteur déborde de sa ligne et sera rogné en '
              'silence.');
    });

    testWidgets('un seul badge sur la photo, et l\'affaire est près du prix',
        (tester) async {
      // Décision déjà prise et mesurée, à conserver : deux badges de teinte
      // identique se superposaient sur un véhicule en location portant une
      // affaire. L'étiquette d'affaire est descendue à côté du prix, qu'elle
      // qualifie.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [vehicule()]);

      final affaire =
          tester.renderObject<RenderBox>(find.text('Bonne affaire'));
      final photo = tester.renderObject<RenderBox>(find.byKey(clePhoto).first);

      // La comparaison est VERTICALE : la photo est en haut de la carte, le
      // texte dessous. Ce qui est vérifié n'a pas changé — l'étiquette n'est
      // PAS posée sur la photo.
      expect(affaire.localToGlobal(Offset.zero).dy,
          greaterThanOrEqualTo(
              photo.localToGlobal(Offset(0, photo.size.height)).dy - 0.01),
          reason: 'L\'étiquette d\'affaire est revenue sur la photo : elle y '
              'faisait doublon de teinte avec le badge de disponibilité.');

      // Et il n'y a QU'UN badge sur la vignette.
      expect(
          find.descendant(
              of: find.byKey(clePhoto).first,
              matching: find.byType(RichText)),
          findsOneWidget,
          reason: 'La vignette porte plus d\'un libellé : le badge de '
              'disponibilité doit y être seul.');
    });

    testWidgets('le retour au toucher est conservé', (tester) async {
      // Décision déjà prise, à conserver.
      await poserPage(tester,
          ecran: const Size(360, 720),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [vehicule()]);

      final echelle = find.descendant(
          of: find.byType(VehicleCard).first,
          matching: find.byType(AnimatedScale));

      expect(tester.widget<AnimatedScale>(echelle.first).scale, 1.0);

      final geste = await tester
          .startGesture(tester.getCenter(find.byType(VehicleCard).first));
      // 300 ms ET NON 50 : la carte vit dans un `Scrollable` doublé d'un
      // `RefreshIndicator`, et le reconnaisseur d'appui de l'`InkWell` ne gagne
      // l'arène des gestes qu'après le délai de rétention. À 50 ms l'appui n'est
      // pas encore reconnu, et le test mesurait une carte au repos.
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<AnimatedScale>(echelle.first).scale, lessThan(1.0),
          reason: 'La carte ne répond plus au doigt.');

      // `cancel` et non `up` : un appui complet ouvre la fiche du véhicule par
      // `context.push`, et il n'y a pas de `GoRouter` dans cet arbre. Ce qui est
      // mesuré ici est le retour VISUEL, pas la navigation.
      await geste.cancel();
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedScale>(echelle.first).scale, 1.0,
          reason: 'La carte reste enfoncée après que le doigt a quitté.');
    });
  });

  // ── Les cas extrêmes, un par un ───────────────────────────────────────────

  group('Cas extrêmes', () {
    /// Chaque cas est éprouvé là où la carte est la plus étroite — 320 points
    /// d'écran, 119,0 points de texte — et aux deux crans qui comptent : le
    /// réglage par défaut, où le défaut d'origine vivait, et l'échelle 2,0, le
    /// dernier cran d'Android.
    Future<void> tenirPartout(
      WidgetTester tester,
      Vehicle v,
      String quoi,
    ) async {
      for (final echelle in [1.0, 2.0]) {
        final exception = await poserPage(tester,
            ecran: const Size(320, 640),
            echelle: echelle,
            mode: Brightness.light,
            vehicules: [v]);

        expect(exception, isNull, reason: '$quoi fait déborder la carte.');

        for (final p in tester.renderObjectList<RenderParagraph>(
            find.descendant(
                of: find.byType(VehicleCard),
                matching: find.byType(RichText)))) {
          final texte = (p.text as TextSpan).toPlainText();
          expect(p.didExceedMaxLines, isFalse,
              reason: '$quoi : « $texte » est coupé à 320 points et à '
                  'l\'échelle $echelle — ${voulue(p).toStringAsFixed(1)} '
                  'voulus pour ${recue(p).toStringAsFixed(1)} reçus, il n\'en '
                  'reste que « ${peint(p, recue(p))} ».');
          expect(motLePlusLarge(p), lessThanOrEqualTo(recue(p) + 0.01),
              reason: '$quoi : un mot de « $texte » fait '
                  '${motLePlusLarge(p).toStringAsFixed(1)} points pour '
                  '${recue(p).toStringAsFixed(1)} reçus à l\'échelle $echelle, '
                  'et sera rogné en silence.');
        }
      }
    }

    testWidgets('« Land Rover Range Rover Sport (2018) »', (tester) async {
      // La plus longue combinaison du référentiel du serveur. Le relecteur a
      // montré qu'à deux colonnes à hauteur fixe elle perdait le MODÈLE :
      // « Land Rover Range Rove… ».
      await tenirPartout(tester, vehicule(), 'Land Rover Range Rover Sport');
    });

    testWidgets('« 99 999 999 FCFA »', (tester) async {
      await tenirPartout(
          tester, vehicule(prix: '99999999.00'), '99 999 999 FCFA');
    });

    testWidgets('« Showroom Paspanga — Bobo-Dioulasso »', (tester) async {
      // La carte ne l'affiche plus, et c'est justement ce qu'on vérifie ici :
      // une annonce qui la porte doit tenir quand même, parce que le champ
      // existe toujours côté serveur et qu'un lot futur pourrait le remettre.
      await tenirPartout(
          tester,
          vehicule(agence: 'Showroom Paspanga', ville: 'Bobo-Dioulasso'),
          'Showroom Paspanga — Bobo-Dioulasso');
    });

    testWidgets('« Vente & Location »', (tester) async {
      await tenirPartout(tester, vehicule(disponibilite: 'both'),
          'Le badge « Vente & Location »');
    });

    testWidgets('une annonce sans finition ni ville', (tester) async {
      await tenirPartout(
          tester,
          vehicule(finition: null, agence: null, ville: null),
          'Une annonce sans finition ni ville');
    });

    testWidgets('« Électrique » et les trois autres carburants',
        (tester) async {
      // Le plus long des quatre libellés de carburant. À 320 points et à
      // l'échelle 1,5, il DISPARAISSAIT entièrement de la ligne de
      // caractéristiques dans la grille d'origine : 171,9 points voulus pour
      // 119,0, et ce qui était peint était « 95 000 km • » — le séparateur,
      // puis rien.
      for (final carburant in ['Essence', 'Diesel', 'Hybride', 'Électrique']) {
        await tenirPartout(tester, vehicule(motorisation: carburant),
            'Le carburant « $carburant »');
      }
    });
  });

  // ── Le badge n'est plus rogné en silence ──────────────────────────────────

  group('Le badge de disponibilité', () {
    testWidgets('sa contrainte de largeur est FINIE', (tester) async {
      // LA MESURE DU DÉFAUT, et elle est binaire. Le badge vit dans un
      // `Positioned` : posé sur `top`/`left` seulement, celui-ci donne à son
      // enfant une contrainte de largeur ILLIMITÉE. Le badge prenait donc sa
      // largeur naturelle, débordait de la vignette, et le
      // `clipBehavior: Clip.antiAlias` du `Card` le coupait au bord — sans
      // ellipse, sans `RenderFlex`, sans exception. Rien ne le signalait.
      await poserPage(tester,
          ecran: const Size(320, 640),
          echelle: 1.0,
          mode: Brightness.light,
          vehicules: [vehicule()]);

      final badge =
          tester.renderObject<RenderParagraph>(find.text('Vente & Location'));

      expect(badge.constraints.maxWidth.isFinite, isTrue,
          reason: 'Le badge reçoit encore une contrainte de largeur illimitée : '
              'il sera rogné par le `Card` sans ellipse, donc en silence.');
    });

    testWidgets('il reste dans la vignette, à toutes les échelles',
        (tester) async {
      // Le rognage se voyait à l'œil et nulle part ailleurs. Ici on compare les
      // bords peints : celui du badge contre celui de la carte.
      for (final echelle in echelles) {
        await poserPage(tester,
            ecran: const Size(320, 640),
            echelle: echelle,
            mode: Brightness.light,
            vehicules: [vehicule()]);

        final carte = tester.renderObject<RenderBox>(find.byType(Card).first);
        // L'ancêtre `Container` du libellé, et non `find.byType(Container)` à un
        // index : la vignette en compte trois — le repli de photo, ce badge et
        // le compteur —, et prendre le premier mesurerait le repli, qui occupe
        // toute la carte et rendrait ce test vide.
        final badge = tester.renderObject<RenderBox>(find
            .ancestor(
                of: find.text('Vente & Location'),
                matching: find.byType(Container))
            .first);

        final droiteCarte = carte.localToGlobal(Offset(carte.size.width, 0)).dx;
        final droiteBadge = badge.localToGlobal(Offset(badge.size.width, 0)).dx;

        expect(droiteBadge, lessThanOrEqualTo(droiteCarte + 0.01),
            reason: 'Le badge dépasse la carte de '
                '${(droiteBadge - droiteCarte).toStringAsFixed(1)} points à '
                'l\'échelle $echelle : il est rogné sans ellipse.');
      }
    });

    testWidgets('et il s\'ellipse plutôt que de se faire couper',
        (tester) async {
      // Non-vacuité : on étouffe le badge dans une case volontairement
      // minuscule — PAS une case que la grille peut produire, et c'est dit pour
      // qu'aucun chiffre du tableau n'en soit tiré — et on vérifie qu'il rend
      // une ellipse au lieu d'un bord net.
      //
      // 60 POINTS ET NON 90, et le chiffre a dû descendre avec ce lot : le badge
      // se replie maintenant sur DEUX lignes, si bien que « Vente & » puis
      // « Location » tiennent encore dans les 54 points qu'une carte de 90 lui
      // laisse. À 60 points de carte il n'en reçoit que 24, moins que son plus
      // court segment, et la troncature redevient inévitable — c'est ce que ce
      // test doit voir.
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: themeAutoParc(Brightness.light),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 60,
                child: VehicleCard(vehicle: vehicule()),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      final badge =
          tester.renderObject<RenderParagraph>(find.text('Vente & Location'));

      expect(badge.didExceedMaxLines, isTrue,
          reason: 'Le badge ne déclare aucune troncature dans une case de 60 '
              'points : son `maxLines`/`overflow` a disparu, et il se fera '
              'rogner en silence comme avant.');
      expect(peint(badge, recue(badge)), isNotEmpty,
          reason: 'Le badge ellipsé ne montre plus rien.');
    });
  });

  // ── `_PrixAjuste` et ses deux planchers ───────────────────────────────────

  group('Réduction du prix', () {
    /// Une case de 143 × 174,4 points, soit 119,0 points de texte.
    ///
    /// C'EST L'ANCIENNE CASE DE LA GRILLE À DEUX COLONNES, à hauteur imposée, et
    /// elle sert ici pour une raison précise : le mécanisme de réduction doit
    /// rester éprouvé sur des prix que le catalogue ne contient pas encore —
    /// dix, puis vingt chiffres —, et une rangée à hauteur intrinsèque les
    /// logerait en se grandissant. AUCUN chiffre du tableau de densité ne sort
    /// de cette case.
    Future<void> poserCaseEtroite(
      WidgetTester tester,
      Vehicle v, {
      required double echelle,
    }) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: themeAutoParc(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(echelle)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 143,
                  child: VehicleCard(vehicle: v),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('AU RÉGLAGE PAR DÉFAUT, un prix trop long rétrécit au lieu de '
        'se couper', (tester) async {
      // LE DÉFAUT (b), ET SA MESURE. L'ancien plancher valait
      // `math.min(nominal, demande)` : à l'échelle 1,0 `demande` vaut exactement
      // `nominal`, donc le plancher valait le corps de départ et la condition
      // `corps > plancher` de la boucle était fausse dès le premier tour. LA
      // RÉDUCTION NE POUVAIT RIEN RÉDUIRE — au réglage par défaut, c'est-à-dire
      // chez tout le monde.
      //
      // Dix chiffres : « 9 999 999 999 FCFA » demande plus que les 119,0 points
      // de la case au corps nominal de 14,0. Huit chiffres n'y suffiraient pas —
      // « 99 999 999 FCFA » n'en demande que 105,3 et tient sans réduction.
      await poserCaseEtroite(tester, vehicule(prix: '9999999999.00'),
          echelle: 1.0);

      final prix = tester
          .renderObject<RenderParagraph>(find.textContaining('FCFA').first);
      final corps = (prix.text as TextSpan).style!.fontSize!;

      expect(prix.didExceedMaxLines, isFalse,
          reason: 'Prix tronqué AU RÉGLAGE PAR DÉFAUT : '
              '${voulue(prix).toStringAsFixed(1)} points voulus pour '
              '${recue(prix).toStringAsFixed(1)} reçus, corps '
              '${corps.toStringAsFixed(1)}. Un prix tronqué est un prix faux.');
      expect(corps, lessThan(14.0),
          reason: 'Le prix n\'a pas rétréci (corps '
              '${corps.toStringAsFixed(1)}) : le plancher vaut encore le corps '
              'nominal à l\'échelle 1,0, et la boucle ne peut rien faire.');
      expect(corps, greaterThanOrEqualTo(11.0),
          reason: 'Le prix est descendu sous le plancher absolu de 11,0 points, '
              'le corps de l\'étiquette d\'affaire peinte à côté.');
    });

    testWidgets('un prix à huit chiffres garde son corps nominal',
        (tester) async {
      // Le cas que la décision nomme. Il tient dans la case étroite : 105,3
      // points pour 119,0. Rien ne justifie de réduire un prix qui tient.
      await poserCaseEtroite(tester, vehicule(prix: '99999999.00'),
          echelle: 1.0);

      final prix = tester
          .renderObject<RenderParagraph>(find.textContaining('FCFA').first);

      expect(prix.didExceedMaxLines, isFalse);
      expect((prix.text as TextSpan).style!.fontSize, 14.0);
    });

    testWidgets('à l\'échelle 1,3 il rétrécit sans descendre sous le corps '
        'd\'un téléphone par défaut', (tester) async {
      // LE PLANCHER DE CONFORT est ce qui est vérifié ici — on ne rend pas le
      // prix plus petit qu'à quelqu'un qui n'a rien réglé, à qui que ce soit qui
      // a grossi ses polices.
      await poserCaseEtroite(tester, vehicule(prix: '9500000.00'),
          echelle: 1.3);

      final prix = tester
          .renderObject<RenderParagraph>(find.textContaining('FCFA').first);
      final corps = (prix.text as TextSpan).style!.fontSize!;

      expect(prix.didExceedMaxLines, isFalse);
      expect(corps, lessThan(14.0 * 1.3),
          reason: 'Le prix devait rétrécir sous les 18,2 points demandés.');
      expect(corps, greaterThanOrEqualTo(14.0),
          reason: 'Et pas sous le corps d\'un téléphone au réglage par défaut : '
              'le plancher de confort n\'a aucune raison de céder ici, le prix '
              'tenant largement au-dessus.');
    });

    testWidgets('le prix d\'une location rétrécit aussi', (tester) async {
      // « /j » allonge la chaîne, et ce chemin-là est un autre appel.
      final json = jsonDecode(jsonEncode(gabarit)) as Map<String, dynamic>;
      final commerce = json['commercial'] as Map<String, dynamic>;
      commerce['availability']      = 'rent';
      commerce['sale_price']        = null;
      commerce['rental_daily_rate'] = '9500000.00';
      json['media'] = <dynamic>[];

      await poserCaseEtroite(tester, Vehicle.fromJson(json), echelle: 1.3);

      final prix = tester
          .renderObject<RenderParagraph>(find.textContaining('FCFA').first);

      expect(prix.didExceedMaxLines, isFalse,
          reason: 'Un loyer tronqué est un loyer faux, comme un prix.');
      expect((prix.text as TextSpan).style!.fontSize!, lessThan(14.0 * 1.3));
    });

    testWidgets('le détecteur voit une troncature qu\'il doit voir',
        (tester) async {
      // NON-VACUITÉ. Vingt chiffres : même au plancher absolu de 11,0 points, ce
      // prix ne peut pas tenir dans 119,0 — il n'y a plus rien à réduire, donc
      // il est coupé, et le détecteur doit le dire. Si cette assertion tombe,
      // c'est que `didExceedMaxLines` ne mesure plus ce qu'on croit, et que les
      // assertions du tableau ne protègent plus rien.
      await poserCaseEtroite(
          tester, vehicule(prix: '99999999999999999999.00'), echelle: 1.0);

      final prix = tester
          .renderObject<RenderParagraph>(find.textContaining('FCFA').first);

      expect(prix.didExceedMaxLines, isTrue,
          reason: 'Le détecteur ne voit pas une troncature qu\'il devrait '
              'voir : ${voulue(prix).toStringAsFixed(1)} points voulus pour '
              '${recue(prix).toStringAsFixed(1)} reçus, corps '
              '${(prix.text as TextSpan).style!.fontSize}.');
    });

    testWidgets('`find.text` passerait sur ce même prix coupé', (tester) async {
      // La démonstration du piège, en deux lignes : le champ `data` porte le
      // prix entier alors que les glyphes sont coupés. C'est exactement ce que
      // le banc précédent assertait sur la ligne de caractéristiques.
      await poserCaseEtroite(
          tester, vehicule(prix: '99999999999999999999.00'), echelle: 1.0);

      final prix = tester
          .renderObject<RenderParagraph>(find.textContaining('FCFA').first);
      // Le texte VOULU, relu dans le paragraphe plutôt qu'écrit en clair : le
      // séparateur de milliers de `NumberFormat` est une espace fine insécable
      // (U+202F), et l'écrire à la main avec des espaces ordinaires ferait
      // échouer ce test pour la mauvaise raison.
      final voulu = (prix.text as TextSpan).toPlainText();

      expect(prix.didExceedMaxLines, isTrue);
      expect(find.text(voulu), findsOneWidget,
          reason: 'Un texte ellipsé passe `find.text` : voilà pourquoi ce '
              'fichier mesure la géométrie.');
    });
  });

  // ── LE TABLEAU DE DENSITÉ, sur la PAGE ENTIÈRE DANS SA COQUE ──────────────

  group('Densité', () {
    /// Ce que la mesure a donné, et ce que ce test interdit de perdre.
    ///
    /// Le compte est le nombre d'annonces ENTIÈREMENT visibles : une carte à
    /// moitié coupée par le pli n'est pas une annonce lue. Il est DÉDUIT de
    /// quatre valeurs toutes mesurées sur la page montée dans sa coque — la
    /// hauteur du `Viewport`, l'ordonnée de la première rangée, la hauteur d'une
    /// rangée et le pas entre deux rangées — et recoupé avec le comptage direct
    /// des cartes posées. Aucune hauteur utile n'est écrite à la main : c'est
    /// exactement le défaut que le relecteur a relevé sur la version précédente,
    /// qui comptait contre 432,0 et 512,0 points là où la liste en a 360,0 et
    /// 440,0.
    ///
    /// ── CE QUE LA BANDE DE FILTRES UNIQUE A RENDU, ET CE QU'ELLE N'A PAS
    ///    RENDU ─────────────────────────────────────────────────────────────
    ///
    /// Le lot de densité des filtres a fusionné les deux rangées de puces de 44
    /// points en une seule de 48 : +40,0 points de liste, aux trois largeurs.
    /// Remesuré ici, case par case, le compte d'annonces ENTIÈRES est le MÊME
    /// dans les DOUZE, et le tableau ci-dessous n'a donc pas changé d'une
    /// valeur. Il faut le dire plutôt que de laisser croire au gain :
    ///
    ///   320x640  x1,0  rangée 231,9  première à 44,0  liste 360,0 (320,0)  2
    ///   320x640  x1,3  rangée 266,9  première à 50,0  liste 360,0 (320,0)  2
    ///   320x640  x1,5  rangée 317,9  première à 54,0  liste 360,0 (320,0)  0
    ///   320x640  x2,0  rangée 525,9  première à 64,0  liste 356,0 (320,0)  0
    ///   360x720  x1,0  rangée 207,2  première à 44,0  liste 440,0 (400,0)  2
    ///   360x720  x1,3  rangée 282,2  première à 50,0  liste 440,0 (400,0)  2
    ///   360x720  x1,5  rangée 303,2  première à 54,0  liste 440,0 (400,0)  2
    ///   360x720  x2,0  rangée 509,2  première à 64,0  liste 436,0 (400,0)  0
    ///   411x923  x1,0  rangée 221,5  première à 44,0  liste 643,0 (603,0)  4
    ///   411x923  x1,3  rangée 270,5  première à 50,0  liste 643,0 (603,0)  4
    ///   411x923  x1,5  rangée 321,5  première à 54,0  liste 643,0 (603,0)  2
    ///   411x923  x2,0  rangée 376,5  première à 64,0  liste 639,0 (603,0)  2
    ///
    /// LA RAISON EST ARITHMÉTIQUE : une rangée mesure de 207 à 526 points, et
    /// 40 points n'en font pas une. Le cas qui s'en approche est 320 × 640 à
    /// l'échelle 1,5 — la deuxième annonce demande 54,0 + 317,9 = 371,9 points
    /// pour 360,0 de liste. Il manque 11,9 points ; il en manquait 51,9 avant
    /// ce lot. CE SONT EXACTEMENT CES 11,9 POINTS QUE LE PLANCHER DE 48 POINTS
    /// DE CIBLE TACTILE COÛTE : une bande de 36 points les rendrait, et la
    /// zone tapable des puces tomberait avec elle. On ne l'a pas fait.
    ///
    /// Ce que les 40 points rendent vraiment est plus modeste et se voit :
    /// 40 points de la rangée suivante qui dépassent du pli, c'est à dire un
    /// « il y en a d'autres en dessous » qui ne se devine plus.
    ///
    /// À l'échelle 2,0 la liste ne gagne que 36,0 points : la bande y mesure
    /// 52,0 au lieu de 48,0 parce qu'elle prend la taille de ses puces plutôt
    /// que de les écraser — ce que les 44 points faisaient dès l'échelle 1,5.
    ///
    /// LES DEUX ÉTATS PRÉCÉDENTS, remesurés dans la même coque pour que la
    /// comparaison veuille dire quelque chose :
    ///
    ///                        carte horizontale    grille 2 colonnes
    ///                        en colonne unique    d'origine
    ///   320x640  x1,0  2            1                   2  (tronquée)
    ///   320x640  x1,3  2            0                   2  (tronquée)
    ///   320x640  x1,5  0            0                   2  (tronquée)
    ///   320x640  x2,0  0            0                   2  (tronquée + bande)
    ///   360x720  x1,0  2            1                   2  (tronquée)
    ///   360x720  x1,3  2            1                   2  (tronquée)
    ///   360x720  x1,5  2            1                   2  (tronquée)
    ///   360x720  x2,0  0            0                   2  (tronquée + bande)
    ///   411x923  x1,0  4            4                   4  (tronquée)
    ///   411x923  x1,3  4            2                   4  (tronquée)
    ///   411x923  x1,5  2            1                   4  (tronquée)
    ///   411x923  x2,0  2            1                   4  (tronquée)
    ///
    /// La première colonne est l'état livré. Il est supérieur ou égal à la
    /// colonne unique dans les DOUZE cases, et strictement supérieur dans huit.
    /// Il est inférieur à la grille d'origine dans cinq — mais celle-là coupait
    /// le titre dans les douze, perdait le carburant dès l'échelle 1,3 et
    /// peignait une bande rayée à l'échelle 2,0 : elle montrait des annonces
    /// qu'on ne pouvait pas lire.
    /// DEUX CASES ONT BAISSÉ quand les carrosseries ont repris leur ligne, et
    /// le chiffre est dit ici plutôt que corrigé en silence : 320 × 1,3 passe
    /// de 2 à ZÉRO annonce entière, et 411 × 1,3 de 4 à 2. Les dix autres ne
    /// bougent pas. La seconde bande reprend 48 points à la liste ; à « Grande
    /// police » sur un petit téléphone, ces 48 points sont ce qui séparait
    /// deux annonces de rien.
    ///
    /// C'est le prix assumé d'avoir les onze carrosseries visibles sans geste.
    /// Si on veut récupérer ces deux cases, le seul levier est de refusionner
    /// les bandes — pas de les amincir : 48 est le plancher de cible tactile,
    /// et les 44 points d'origine l'enfreignaient déjà.
    final attendu = <String, int>{
      '320x640-1.0': 2,
      '320x640-1.3': 0,
      '320x640-1.5': 0,
      '320x640-2.0': 0,
      '360x720-1.0': 2,
      '360x720-1.3': 2,
      '360x720-1.5': 2,
      '360x720-2.0': 0,
      '411x923-1.0': 4,
      '411x923-1.3': 2,
      '411x923-1.5': 2,
      '411x923-2.0': 2,
    };

    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        testWidgets('${ecran.key}, texte x$echelle : la rangée et le compte',
            (tester) async {
          await poserPage(tester,
              ecran: ecran.value,
              echelle: echelle,
              mode: Brightness.light,
              vehicules: List.generate(8, (_) => vehicule()));

          final hauteurListe = utile(tester);
          final r = rangs(tester);
          expect(r, isNotEmpty);

          final hauteurRangee = r.first.bas - r.first.haut;

          // Les huit véhicules sont identiques, donc les rangées posées doivent
          // l'être aussi. L'assertion n'est pas décorative : c'est elle qui
          // autorise à déduire le compte d'une seule hauteur de rangée.
          for (final rangee in r) {
            expect(rangee.bas - rangee.haut, closeTo(hauteurRangee, 0.01),
                reason: 'Deux rangées du même contenu n\'ont pas la même '
                    'hauteur : le compte ci-dessous ne vaut plus rien.');
          }

          // Le pas entre deux rangées, LU quand une seconde rangée est posée.
          // Sinon c'est l'écart du `Padding` de la rangée, qui est une
          // constante du code et non une mesure supposée.
          final ecart = r.length > 1 ? r[1].haut - r[0].bas : 10.0;

          // Combien de rangées tiennent ENTIÈREMENT sous le pli.
          var rangees = 0;
          while (r.first.haut +
                  (rangees + 1) * hauteurRangee +
                  rangees * ecart <=
              hauteurListe + 0.01) {
            rangees++;
          }
          final n = rangees * 2;

          // Recoupement : le comptage direct des cartes entièrement visibles
          // doit donner le même chiffre, tant que le constructeur paresseux en a
          // posé au moins une de plus.
          final direct =
              r.where((x) => x.bas <= hauteurListe + 0.01).length * 2;
          if (r.length * 2 > direct) {
            expect(direct, n,
                reason: 'Le comptage direct ($direct) et la déduction ($n) ne '
                    's\'accordent pas.');
          }

          // ignore: avoid_print
          print('── densité ${ecran.key}, x$echelle : '
              'rangée ${hauteurRangee.toStringAsFixed(1)}, '
              'pas ${(hauteurRangee + ecart).toStringAsFixed(1)}, '
              'première à ${r.first.haut.toStringAsFixed(1)}, '
              'liste ${hauteurListe.toStringAsFixed(1)} → '
              '$n annonce(s) entière(s)');

          expect(n, attendu['${ecran.key}-$echelle'],
              reason: 'La densité a changé en ${ecran.key} à l\'échelle '
                  '$echelle : rangée de ${hauteurRangee.toStringAsFixed(1)} '
                  'points, première à ${r.first.haut.toStringAsFixed(1)}, pour '
                  '${hauteurListe.toStringAsFixed(1)} de liste. C\'est le '
                  'chiffre que ce lot avait pour objet — s\'il baisse, '
                  'dites-le avant de le livrer.');
        });
      }
    }
  });
}

/// Un dépôt qui rend une liste fixée, sans réseau.
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

/// Une session figée, sans Firebase.
///
/// Le vrai `AuthNotifier` s'abonne à Firebase dès son constructeur, ce qu'un
/// test ne peut pas satisfaire. Celui-ci se contente de porter l'état, ce qui
/// suffit : la page ne lit de l'authentification que les capacités.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Charge Roboto et les icônes Material depuis le cache du SDK.
///
/// Lues là plutôt que copiées dans le dépôt : deux fichiers binaires de plus
/// dans l'historique pour des métriques de test ne se justifient pas, et
/// `captures_controle_test.dart` fait déjà ainsi. Si le cache manque, ce fichier
/// ne se tait pas — le premier test mesure la police chargée et dit laquelle il
/// a trouvée.
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
