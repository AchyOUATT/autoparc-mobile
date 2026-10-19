import 'package:flutter/material.dart';

/// Le theme de l'application, clair et sombre.
///
/// Les deux ne differaient que par leur Brightness : une fonction evite de
/// repeter chaque reglage de densite dans les deux copies, et surtout evite
/// qu'ils divergent.
///
/// Densite reduite le 2026-10-16. Les reglages par defaut de Material 3 sont
/// genereux — pensés pour des ecrans larges —, et sur un telephone ils
/// mangeaient de la hauteur utile a chaque ecran : une barre de titre de 56
/// points, des icones de 24, un titre de 22.
///
/// SORTI DE `main.dart` le 2026-10-17, et pas par gout du rangement : le banc
/// de geometrie de la carte doit mesurer sous le VRAI theme. Un relecteur a
/// montre qu'une carte posee dans un `MaterialApp` sans theme donne des
/// chiffres differents de la vraie grille — les corps de `titleSmall` et de
/// `bodySmall` viennent du theme, et c'est d'eux que depend chaque largeur
/// mesuree. Importer `main.dart` depuis un test tirerait Firebase et
/// `google_sign_in` dans le banc ; cette fonction seule n'a besoin que de
/// Material.
ThemeData themeAutoParc(Brightness brightness) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8AAFC8), // bleu ardoise pâle — très doux
      brightness: brightness,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      // 48 au lieu des 56 par defaut (kToolbarHeight), et un titre a 18
      // au lieu de 22. On ne descend pas sous 48 : les IconButton de la
      // barre imposent une cible tactile de 48 points, et la barre les
      // rognerait. Le titre est construit a partir de titleLarge et non
      // ecrit de zero — sans cela il perdrait sa couleur, et deviendrait
      // illisible sur les barres colorees.
      toolbarHeight: 48,
      // LES HUIT POINTS DE RIEN QUE LE DÉFAUT DE FLUTTER RÉSERVAIT.
      //
      // `AppBar` prend `leadingWidth ?? _kLeadingWidth`, et `_kLeadingWidth`
      // vaut `kToolbarHeight` — 56 — avec ce commentaire dans app_bar.dart :
      // « So the leading button is square ». Il a cessé d'être vrai le jour où
      // `toolbarHeight` est passé à 48 juste au-dessus : le bouton de
      // navigation est carré de 48 et la barre lui réservait 56. Les 8 points
      // d'écart n'étaient peints par personne, et ils étaient retirés au TITRE.
      //
      // Mesuré à 320 points d'écran : le titre d'une liste du catalogue
      // recevait 120,0 points pour un client — 320 − 56 − trois commandes de
      // 48 — et en reçoit 128,0. La cible tactile du bouton ne bouge pas :
      // l'`IconButton` fait 48 de large et c'est la boîte qui l'entourait qui
      // rétrécit.
      leadingWidth: 48,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      // Cloche, panier, retour : 20 au lieu de 24. iconTheme couvre le
      // bouton de navigation a gauche, actionsIconTheme ceux de droite —
      // les deux sont necessaires, l'un ne retombe pas sur l'autre.
      iconTheme: const IconThemeData(size: 20),
      actionsIconTheme: const IconThemeData(size: 20),
    ),
  );
}
