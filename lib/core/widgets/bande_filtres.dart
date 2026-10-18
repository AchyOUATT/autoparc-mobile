import 'package:flutter/material.dart';

/// La bande de puces de filtre du catalogue, commune aux trois listes.
///
/// ── CE QUI A ÉTÉ MESURÉ AVANT D'ÉCRIRE CECI ─────────────────────────────────
///
/// La page des véhicules portait DEUX bandes superposées, chacune dans un
/// `SizedBox(height: 44)` : « OFFRE / TYPE / VILLE » puis « CARROSSERIE ». Les
/// pièces et les accessoires en portaient UNE, dans un `SizedBox(height: 48)`.
/// Mesuré sur la page montée dans sa coque, à 320, 360 et 411 points d'écran,
/// aux échelles de texte 1,0 et 1,3 — les six cases donnaient la même chose :
///
///   véhicules     bandes 44,0 + 44,0 = 88,0   puce tapable 44,0   peinte 38,0 (x1,0) / 44,0 (x1,3)
///   pièces        bande  48,0                 puce tapable 48,0   peinte 38,0 / 44,0
///   accessoires   bande  48,0                 puce tapable 48,0   peinte 38,0 / 44,0
///
/// Décomposition des 44 points d'une bande de véhicules : la puce PEINTE en
/// prend 38 à l'échelle 1,0 (le libellé mesure 20,0 points de hauteur de
/// ligne, le `padding` par défaut de Material 3 — `EdgeInsets.all(8)` — en
/// ajoute 16, et la bordure 2), le libellé de groupe « OFFRE » n'en prend que
/// 16 et ne décide donc rien, l'espacement entre les deux rangées est NUL —
/// elles sont voisines dans un `Column` —, et la marge du libellé de groupe est
/// purement horizontale. Il ne restait que 6 points de jeu, et ZÉRO à
/// l'échelle 1,3 : à ce cran la puce peinte faisait exactement 44,0, c'est à
/// dire qu'elle était déjà ÉCRASÉE par la bande.
///
/// ── LE PLANCHER DE 48 POINTS, ET POURQUOI IL NE SE CONTOURNE PAS ────────────
///
/// Une puce de filtre est une CIBLE TACTILE. Flutter le traduit dans
/// `RawChip` : avec `MaterialTapTargetSize.padded`, la puce est enveloppée
/// d'une boîte de redirection de pointage dont la contrainte est
/// `minHeight: kMinInteractiveDimension + visualDensity.baseSizeAdjustment.dy`,
/// soit 48 points. Deux pièges s'y cachent, tous deux vérifiés dans le code du
/// SDK plutôt que supposés :
///
/// 1. Cette boîte est un `RenderConstrainedBox`, donc son `minHeight` est
///    `enforce`é par la contrainte REÇUE. Les 44 points de l'ancienne bande
///    RABOTAIENT la cible tactile à 44,0 — mesuré, pas déduit. Le plancher de
///    48 était déjà enfreint avant ce lot, en silence.
/// 2. `visualDensity` est SOUSTRAIT de ce plancher : `VisualDensity.compact`
///    vaut −2, donc −8 points, et donnerait une cible de 40. C'est le procédé
///    employé sur le bandeau de compatibilité des pièces, où il est assumé et
///    commenté ; il est REFUSÉ ici. Ce qui amincit la puce sans toucher à ce
///    qu'on tape, c'est son `padding`, pas sa densité visuelle.
///
/// La bande n'impose donc plus AUCUNE hauteur : elle prend celle de ses puces,
/// et ce sont les puces qui portent le plancher de 48 points. 48 à l'échelle
/// 1,0, 1,3 et 1,5 ; au-delà la bande grandit d'elle-même plutôt que d'écraser
/// le libellé, ce que les 44 points faisaient dès l'échelle 1,5.
///
/// ── CE QUI AMINCIT RÉELLEMENT LA PUCE ───────────────────────────────────────
///
/// [_remplissagePuce] remplace l'`EdgeInsets.all(8)` de Material 3. Vertical à
/// 5, soit 6 points de moins sur la hauteur. Mesuré sur la page montée dans sa
/// coque, le `Material` de la puce passe de 38,0 à 34,0 points à l'échelle 1,0
/// et de 44,0 à 38,0 à l'échelle 1,3. La cible tactile, elle, ne bouge pas :
/// 48,0 dans les deux cas, parce que c'est la boîte de pointage qui la porte et
/// non la puce peinte. C'est exactement la séparation que Material fait entre
/// les deux, et elle passe par le `padding` — jamais par `visualDensity`, qui
/// est soustrait du plancher.
///
/// Les 38,0 d'origine étaient par ailleurs un chiffre de Flutter et non de
/// Material : la spécification donne 32 points de haut à une puce, et c'est la
/// hauteur de ligne de 20,0 points de `labelLarge` qui l'en éloignait.
///
/// ── POURQUOI UN SEUL WIDGET POUR LES TROIS PAGES ────────────────────────────
///
/// La passe de densité précédente a traité les quatre barres de recherche
/// ensemble, avec cette raison écrite dans le code : en laisser deux à
/// l'ancienne taille aurait eu l'air d'un défaut. Même règle. Les trois bandes
/// avaient en plus trois comportements de bord différents — dégradé sur les
/// véhicules, coupe nette sur les pièces et les accessoires — pour un même
/// objet à l'écran.
class BandeFiltres extends StatelessWidget {
  final List<Widget> children;
  const BandeFiltres({super.key, required this.children});

  /// Le remplissage intérieur des puces de la bande.
  ///
  /// Horizontal inchangé : la largeur ne coûte rien ici, la bande défile.
  /// Vertical à 5 au lieu de 8 — voir l'en-tête du fichier pour le compte.
  static const EdgeInsets _remplissagePuce =
      EdgeInsets.symmetric(horizontal: 8, vertical: 5);

  @override
  Widget build(BuildContext context) {
    return ChipTheme(
      // `ChipThemeData` ne porte QUE le remplissage : `RawChip` résout chaque
      // propriété par `widget.x ?? chipTheme.x ?? defauts.x`, donc tout le
      // reste — couleurs, forme, bordure, corps du libellé — continue de venir
      // des défauts Material 3 du thème. Un `copyWith` sur `base.chipTheme`
      // n'apporterait rien : ce champ est vide, les défauts sont calculés à la
      // construction de la puce.
      data: const ChipThemeData(padding: _remplissagePuce),
      child: ShaderMask(
        // Le dégradé sur les bords remplace la coupe nette : une puce à moitié
        // estompée se lit comme « ça continue », pas comme un défaut
        // d'affichage. Les pièces et les accessoires n'en avaient pas.
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, 0.03, 0.92, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        // `SingleChildScrollView` ET NON `ListView`, et c'est le mécanisme du
        // lot : un `ListView` horizontal est un `Viewport`, dont l'étendue
        // transversale vient du parent — il FAUT donc lui donner une hauteur,
        // et c'est ce `SizedBox` écrit à la main qui rabotait la cible tactile.
        // Un `Row` dans un défilement à un seul enfant se dimensionne sur ses
        // enfants : la hauteur de la bande est désormais LUE sur les puces.
        // Le coût est la construction immédiate des puces, et il est nul — la
        // plus longue des trois bandes en compte dix-huit.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: children),
        ),
      ),
    );
  }
}

/// Intitulé d'un groupe de puces — distingue les taxonomies (offre
/// commerciale, type de véhicule, ville, carrosserie) que le style uniforme
/// des puces confondait.
///
/// Sa hauteur ne décide de rien : 16,0 points à l'échelle 1,0 et 21,0 à 1,3,
/// mesurés, contre 48 pour la cible tactile des puces à côté desquelles il est
/// centré.
class LibelleGroupeFiltres extends StatelessWidget {
  final String text;
  const LibelleGroupeFiltres(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    ),
  );
}
