/// LE NOMBRE DE COLONNES DES TROIS LISTES DU CATALOGUE, DÉCIDÉ UNE SEULE FOIS.
///
/// ── LE DÉFAUT QUE CE FICHIER EXISTE POUR FERMER ─────────────────────────────
///
/// Les trois listes figeaient DEUX colonnes, chacune par un mécanisme
/// différent : `_Colonne(depart: 0)` et `_Colonne(depart: 1)` dans un `Row`
/// avec un pas de 2 en dur pour les véhicules, une répartition sur `i.isEven`
/// pour les pièces, la même recopiée pour les accessoires. Trois écritures
/// d'une même décision, donc trois endroits où la corriger — et c'est
/// exactement pourquoi le défaut a pu exister en triple.
///
/// Ce qu'il donnait, MESURÉ sur les trois listes avant ce lot, à l'échelle de
/// texte 1,0 :
///
///   écran    véhicules            pièces et accessoires
///   320      2 col, carte 143,0   2 col, carte 149,0
///   360      2 col, carte 163,0   2 col, carte 169,0
///   411      2 col, carte 188,5   2 col, carte 194,5
///   800      2 col, carte 383,0   2 col, carte 389,0
///   1280     2 col, carte 623,0   2 col, carte 629,0
///
/// Une carte de 629 points de large, c'est quatre articles sur une page de
/// tablette en paysage. C'est le « les objets sont très gros » du
/// propriétaire, et c'est la même phrase que « deux lignes en portrait comme
/// en paysage » : un seul défaut, pas deux.
///
/// ── LE CRITÈRE EST LA LARGEUR, PAS L'ORIENTATION NI UN DRAPEAU « TABLETTE » ──
///
/// Une tablette en portrait et un grand téléphone en paysage ont la même
/// largeur et méritent la même grille ; un drapeau d'appareil les séparerait
/// sans raison, et une condition sur l'orientation rendrait la même largeur
/// deux fois différemment. En décidant sur la largeur SEULE, l'orientation se
/// trouve traitée sans jamais être nommée — une rotation change la largeur,
/// donc change la grille, et il n'y a rien d'autre à écrire.
///
/// [nombreDeColonnes] lit la largeur RÉELLEMENT DISPONIBLE pour la rangée de
/// colonnes, c'est-à-dire la contrainte que la maçonnerie reçoit une fois les
/// marges de la page retirées. Pas la largeur de l'écran : une page qui
/// changerait ses marges, ou qu'un panneau latéral rétrécirait, doit voir sa
/// grille suivre, et `MediaQuery` ne le dirait pas.
library;

import 'package:flutter/material.dart';

/// La largeur de carte VISÉE, en points.
///
/// ── D'OÙ VIENT CE 190, ET POURQUOI PAS UNE LISTE D'APPAREILS ────────────────
///
/// Partir des appareils aurait demandé de les énumérer, donc de les tenir à
/// jour, donc de se tromper. On part de la carte : elle a été dessinée,
/// mesurée et tranchée sur l'émulateur de référence — un Pixel de 411 points —,
/// où elle fait 188,5 points de large pour les véhicules et 194,5 pour les
/// pièces et les accessoires. C'est à CETTE largeur que `carte_geometrie_test`
/// a établi que rien ne se coupe, que le titre se replie en deux lignes et que
/// le prix garde son corps nominal. 190 points est donc la largeur dont on
/// SAIT qu'elle va à cette carte ; toutes les autres sont des paris.
///
/// La grille cherche ensuite le nombre de colonnes qui approche le plus cette
/// largeur — un ARRONDI et non un plancher ni un plafond.
///
/// L'ARITHMÉTIQUE, refaite et non recopiée. `N = round(W / 190)` signifie que
/// `N` règne sur `(N − 0,5) × 190 ≤ W < (N + 0,5) × 190`, donc que la carte,
/// qui vaut `W / N`, vit dans :
///
///     [ (2N − 1)/(2N) , (2N + 1)/(2N) ] × 190
///
/// soit **142,5 à 237,5** points à deux colonnes et **158,3 à 221,7** à trois.
/// L'intervalle se resserre quand `N` grandit : c'est à deux colonnes que la
/// carte peut le plus s'écarter de la cible, et c'est donc là que la borne du
/// banc doit être prise.
///
/// CETTE DOC A D'ABORD ÉCRIT L'INVERSE — `[2N/(2N+1), 2N/(2N−1)] × 190`, soit
/// « 152 à 253 » —, et c'est noté parce que l'erreur n'était pas inoffensive :
/// c'est cet intervalle qui ARGUMENTE le choix de l'arrondi contre `ceil` et
/// `floor`, et les bornes du banc permanent en descendaient. Elles laissaient
/// 19,5 points de mou, c'est-à-dire qu'elles ne mordaient pas là où la règle
/// peut réellement déraper.
///
/// Un plafond (`ceil`) est écarté par son PIRE cas et non par un cas moyen : à
/// 190 points disponibles il rend déjà 2 colonnes, donc une carte de 95,0
/// points — les deux tiers du plus petit téléphone. Un plancher (`floor`)
/// laisserait la carte doubler avant d'ajouter une colonne.
const double largeurCarteVisee = 190.0;

/// Le plancher : DEUX colonnes, toujours, et c'est une décision du
/// propriétaire et non un calcul.
///
/// « Non, je veux 2 annonces par lignes. » À 320 points de large une carte ne
/// fait que 143 points, bien en dessous de la largeur visée, et l'arithmétique
/// ci-dessous rendrait 1. Elle est donc bornée par le bas et ne l'est pas par
/// le haut : une colonne unique n'est plus une mise en page de ce dépôt.
const int colonnesMinimum = 2;

/// Combien de colonnes pour [largeurDisponible] points de large.
///
/// [largeurDisponible] est la largeur que la rangée de colonnes reçoit, écarts
/// compris et marges de page déjà retirées.
///
/// ── LA CONTRAINTE DURE, ET SA VÉRIFICATION ──────────────────────────────────
///
/// DEUX COLONNES PARTOUT EN DESSOUS DE 420 POINTS D'ÉCRAN. Ce n'est pas un
/// effet de bord espéré, c'est vérifiable ici : la troisième colonne
/// n'apparaît qu'à partir de `2,5 × 190 = 475` points DISPONIBLES. Les trois
/// listes retirent 24 points de marge (véhicules) ou 16 (pièces et
/// accessoires), donc 475 points disponibles valent 499 ou 491 points d'écran.
/// Et même une page future SANS AUCUNE MARGE resterait à deux colonnes jusqu'à
/// 475 points d'écran. La marge au-dessus de 420 est de 55 points au pire.
int nombreDeColonnes(double largeurDisponible) {
  if (!largeurDisponible.isFinite || largeurDisponible <= 0) {
    return colonnesMinimum;
  }
  final vise = (largeurDisponible / largeurCarteVisee).round();
  return vise < colonnesMinimum ? colonnesMinimum : vise;
}

/// La largeur d'UNE colonne, une fois les [ecart] points retirés entre elles.
double largeurDUneColonne(
  double largeurDisponible,
  int colonnes, {
  required double ecart,
}) => (largeurDisponible - ecart * (colonnes - 1)) / colonnes;

/// Le PLANCHER de la vignette des pièces et des accessoires.
///
/// C'est l'ancienne constante `_imgHeight`, qui vivait en double — une copie
/// dans `part_list_page.dart`, une dans `accessory_list_page.dart`, avec pour
/// seule garantie d'égalité un commentaire qui le demandait. Sa raison, reprise
/// telle quelle de la page des pièces :
///
///   « Hauteur unique : des vignettes de tailles différentes décalaient les
///   deux colonnes, si bien que les prix ne s'alignaient jamais d'une carte à
///   l'autre. Sur un catalogue où l'on compare des prix, c'est une gêne, pas un
///   effet. 140 et non 118 depuis le 2026-10-16 : sur deux colonnes une carte
///   fait environ 170 points de large, et à 118 l'image tenait dans un cadre
///   nettement plus large que haut, ce qui rogne en hauteur des photos de
///   pièces presque toujours cadrées droit. À 140 le cadre approche le carré. »
///
/// L'alignement dont parle ce texte vaut TOUJOURS, et c'est pourquoi la hauteur
/// se calcule depuis la largeur de COLONNE et non depuis le contenu : deux
/// cartes voisines ont la même largeur de colonne, donc la même vignette, donc
/// le même bord inférieur d'image.
const double hauteurVignettePlancher = 140.0;

/// La hauteur de la vignette d'une carte de PIÈCE ou d'ACCESSOIRE.
///
/// ── POURQUOI UNE HAUTEUR D'IMAGE DOIT BOUGER AVEC LA COLONNE ────────────────
///
/// Elle était la constante [hauteurVignettePlancher], seule et fixe.
/// Une constante dans une colonne qui grandit devient une boîte aux lettres :
/// mesuré avant ce lot, à 1280 points de large la carte faisait 629 points et
/// l'image restait à 140, soit un cadre quatre fois plus large que haut. Le
/// commentaire qui avait porté 118 à 140 disait déjà le critère — « à 140 le
/// cadre approche le carré et la pièce occupe davantage de la vignette » — et
/// une constante ne sait pas le tenir à deux largeurs différentes.
///
/// ── LE RAPPORT 0,70, ET POURQUOI IL NE TOUCHE PAS AU TÉLÉPHONE ──────────────
///
/// Le plancher de 140 est ce qui garantit que RIEN NE BOUGE sous 420 points.
/// La colonne la plus large qu'une grille à deux colonnes puisse produire
/// juste sous cette frontière vaut `(420 − 16 − 6) / 2 = 199,0` points sur les
/// listes de pièces et d'accessoires. Le rapport est donc choisi pour que le
/// produit y reste SOUS le plancher : `140 / 199,0 = 0,7035`, arrondi par le
/// BAS à 0,70, ce qui donne 139,3 points — le plancher gagne, et les trois
/// téléphones de référence gardent leurs 140,0 exacts.
///
/// 0,70 n'est pas non plus une proportion inventée : la carte du Pixel porte
/// déjà `140 / 194,5 = 0,72`. Au-dessus de la frontière, la vignette continue
/// donc la forme que le téléphone a déjà, au lieu de s'aplatir.
///
/// EN PRATIQUE le plancher l'emporte presque partout, parce que la règle des
/// colonnes ramène elle-même la carte autour de 190 points : à 800 comme à
/// 1280 points d'écran la vignette fait 140,0. Le rapport ne mord que dans la
/// bande où la grille reste à deux colonnes avec une carte large — entre 420 et
/// 491 points d'écran —, et c'est précisément la bande que la règle des
/// colonnes ne peut pas corriger sans violer la contrainte du propriétaire.
double hauteurVignetteCatalogue(double largeurColonne) {
  const rapport = 0.70;
  final proportionnelle = largeurColonne * rapport;
  return proportionnelle > hauteurVignettePlancher
      ? proportionnelle
      : hauteurVignettePlancher;
}

/// La maçonnerie à N colonnes, partagée par les trois listes du catalogue.
///
/// ── CE QUE LA MAÇONNERIE EST, ET CE QU'ELLE N'EST PAS ───────────────────────
///
/// La carte `i` va dans la colonne `i % N`, et chaque colonne empile ses cartes
/// à LEUR hauteur. Rien n'aligne deux cartes voisines, et c'est le point : le
/// propriétaire a dit que l'alignement n'était pas nécessaire, et c'est ce qui
/// permet à chaque carte de se replier au lieu de s'ellipser.
///
/// ── LES TROIS MONTAGES DÉJÀ ESSAYÉS ET RETIRÉS, pour qu'on ne les refasse pas ─
///
/// 1. `SliverGrid` à `childAspectRatio` : il impose à toutes les cases la
///    hauteur de la plus grande, donc un budget vertical au texte, donc
///    l'ellipse. C'est la cause de toutes les troncatures de titre que
///    `carte_geometrie_test` a mesurées.
/// 2. `SliverList` de `Row` : 238 objets de rendu contre une vingtaine, mesuré
///    à 360 × 720 — mais il rendait 8 cartes quand la maçonnerie en rend
///    autant que la page en a chargé. Le détail du calcul est resté dans
///    `vehicle_list_page.dart`, qui porte le coût.
/// 3. `IntrinsicHeight` + `CrossAxisAlignment.stretch` : refusé net par le
///    banc, « LayoutBuilder does not support returning intrinsic dimensions »
///    — le `LayoutBuilder` en question est `_PrixAjuste`, qui lit la largeur
///    qu'il reçoit pour décider du corps du prix et ne peut donc répondre à
///    aucune question de dimension intrinsèque. La maçonnerie rend la question
///    sans objet : plus rien ne demande à deux cartes d'avoir la même hauteur.
///
/// ── POURQUOI LE `LayoutBuilder` D'ICI EST SANS DANGER, LUI ──────────────────
///
/// Le point 3 interdit de DEMANDER une dimension intrinsèque à travers un
/// `LayoutBuilder` ; il n'interdit pas d'en poser un. Celui-ci vit sous un
/// `SliverToBoxAdapter`, qui donne une largeur tendue et une hauteur illimitée
/// et ne pose aucune question intrinsèque à son enfant. Rien au-dessus de la
/// maçonnerie n'en pose non plus — c'est ce que vérifie le banc de géométrie,
/// qui tomberait sur l'exception ci-dessus au premier rendu.
class MaconnerieColonnes extends StatelessWidget {
  /// Le nombre de cartes à répartir.
  final int nombre;

  /// L'écart horizontal entre deux colonnes.
  final double ecartHorizontal;

  /// L'écart vertical entre deux cartes d'une même colonne.
  ///
  /// Zéro quand la carte porte déjà sa propre marge basse, ce qui est le cas
  /// des pièces et des accessoires : ajouter un écart leur en donnerait deux.
  final double ecartVertical;

  /// Construit la carte d'indice [index], à qui l'on passe la largeur de la
  /// colonne — les cartes de pièce et d'accessoire en déduisent la hauteur de
  /// leur vignette par [hauteurVignetteCatalogue].
  final Widget Function(BuildContext context, int index, double largeurColonne)
  carte;

  const MaconnerieColonnes({
    super.key,
    required this.nombre,
    required this.carte,
    required this.ecartHorizontal,
    this.ecartVertical = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final colonnes = nombreDeColonnes(contraintes.maxWidth);
        final largeur = largeurDUneColonne(
          contraintes.maxWidth,
          colonnes,
          ecart: ecartHorizontal,
        );
        return Row(
          // `start` ET NON `stretch` : `stretch` demanderait aux colonnes une
          // hauteur tendue, qu'un sliver ne donne pas — il laisse la hauteur
          // ILLIMITÉE —, et la borner réclamerait la mesure intrinsèque que
          // `_PrixAjuste` ne sait pas rendre. En `start`, le `Row` prend la
          // hauteur de sa plus longue colonne et toutes partent du même haut.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < colonnes; c++) ...[
              if (c > 0) SizedBox(width: ecartHorizontal),
              Expanded(
                child: Column(
                  // `stretch` ici, et il est SANS DANGER contrairement à celui
                  // d'un `Row` : l'axe transversal d'une `Column` est
                  // l'horizontale, donc il tend les cartes à la largeur de
                  // l'`Expanded` — une contrainte que la colonne REÇOIT, pas
                  // une mesure intrinsèque qu'elle réclame. Sans lui, chaque
                  // carte se réduirait à sa largeur naturelle et la colonne se
                  // dépeuplerait par la droite.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = c; i < nombre; i += colonnes) ...[
                      // L'écart vit ENTRE les cartes et jamais après la
                      // dernière : un séparateur posé en suffixe laisserait, en
                      // bas de la colonne courte, un vide de plus que celui que
                      // la maçonnerie vient de chasser.
                      if (i > c && ecartVertical > 0)
                        SizedBox(height: ecartVertical),
                      carte(context, i, largeur),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
