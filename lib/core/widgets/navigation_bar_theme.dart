import 'package:flutter/material.dart';

/// L'habillage de la barre de navigation du bas.
///
/// Extrait de `main.dart` pour une raison précise : ses couleurs étaient
/// écrites en dur, et en mode nuit la barre devenait illisible.
///
/// Le fond de la barre est `colorScheme.primary`. En thème clair, Material
/// en fait un bleu sombre, sur lequel du blanc et un bleu pâle se lisent très
/// bien. En thème sombre, `primary` devient une teinte **claire** — ici
/// `#91CEF5` — et les mêmes couleurs écrites en dur s'effondrent :
///
/// | | clair | nuit |
/// |---|---|---|
/// | sélectionné, `Colors.white` | 6,42:1 | **1,70:1** |
/// | non sélectionné, `#B0CCDE` | 3,83:1 | **1,02:1** |
///
/// 1,02:1, c'est du bleu clair sur du bleu clair : l'onglet n'était pas
/// « peu lisible », il était absent. Et l'onglet actif ne valait pas mieux.
///
/// Tout dérive maintenant de `onPrimary`, que Material garantit contrasté
/// avec `primary` dans les deux thèmes. L'opacité du non-sélectionné est
/// réglée au plus bas qui tienne encore le seuil AA des petits textes
/// (4,5:1) : [_opaciteInactive]. La différence entre actif et inactif ne
/// repose donc pas sur elle, mais sur la graisse du texte et sur la pastille
/// de l'indicateur — deux signaux francs, qui ne dépendent pas de la finesse
/// de l'œil ni de la luminosité de l'écran.
NavigationBarThemeData barreNavigationTheme(ColorScheme couleurs) {
  return NavigationBarThemeData(
    // 64 au lieu des 80 par defaut de Material 3. Cette barre est presente sur
    // les quatre ecrans principaux : seize points repris, c'est seize points
    // rendus au catalogue, sur chacun d'eux.
    //
    // On ne descend pas plus bas : en dessous de 64, l'etiquette et l'icone ne
    // tiennent plus ensemble des que l'utilisateur agrandit le texte, et
    // labelBehavior vaut alwaysShow.
    height: 64,
    backgroundColor: couleurs.primary,
    indicatorColor: couleurs.onPrimary.withValues(alpha: 0.18),
    iconTheme: WidgetStateProperty.resolveWith(
      (etats) => IconThemeData(
        color: _teinte(couleurs, etats),
        size: 24,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (etats) => TextStyle(
        color: _teinte(couleurs, etats),
        fontSize: 12,
        fontWeight: etats.contains(WidgetState.selected)
            ? FontWeight.w600
            : FontWeight.w400,
      ),
    ),
  );
}

/// L'opacité des onglets inactifs.
///
/// Mesurée, pas choisie à l'œil : 0,75 rendait 4,40:1 en clair et 4,39:1 en
/// nuit, soit juste sous le seuil. 0,80 donne 4,77:1 et 4,93:1.
const double _opaciteInactive = 0.80;

Color _teinte(ColorScheme couleurs, Set<WidgetState> etats) =>
    etats.contains(WidgetState.selected)
        ? couleurs.onPrimary
        : couleurs.onPrimary.withValues(alpha: _opaciteInactive);

/// La barre de navigation du bas, habillée ET bornée en échelle de texte.
///
/// ── LE DÉFAUT MESURÉ ────────────────────────────────────────────────────────
///
/// À 320 points d'écran et à l'échelle de texte 1,3 — le deuxième cran des
/// réglages Android, « Grande police » —, « Accessoires » réclamait 87,7 points
/// pour les 80,0 que sa destination reçoit : le libellé se cassait sur DEUX
/// lignes. Un intitulé de navigation replié se lit comme un bug, et il l'était
/// sur la capture du propriétaire. Les trois autres tenaient : 52,7 pour
/// « Accueil », 70,9 pour « Véhicules », 47,9 pour « Pièces ». À 360 points la
/// destination reçoit 90,0 et « Accessoires » passe.
///
/// ── CE QUI EST BORNÉ, ET CE QUI NE L'EST PAS ────────────────────────────────
///
/// `MediaQuery.withClampedTextScaling` ne borne QUE ce que peint cette barre :
/// le reste de l'application suit le réglage de l'utilisateur, intact. Le
/// plafond vient de la mesure et non du goût — « Accessoires » demande 68,1
/// points à l'échelle 1,0, donc le rapport qui le fait déborder des 80,0 reçus
/// vaut 1,174. [_echelleMaxLibelles] est posée en dessous, avec 1,7 point de
/// marge pour la plus étroite des trois largeurs du parc.
///
/// LE COMPROMIS EST ASSUMÉ : quelqu'un qui a grossi ses polices lit ces quatre
/// intitulés à 13,8 points au lieu de 15,6. C'est le prix d'un libellé entier
/// contre un libellé replié, et il porte sur le texte le MOINS porteur de
/// l'écran — chaque destination a son icône, que cette borne ne touche pas,
/// les icônes tirant leur taille du thème et non de l'échelle de texte.
class BarreNavigationPrincipale extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<NavigationDestination> destinations;

  const BarreNavigationPrincipale({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    this.onDestinationSelected,
  });

  /// Le plafond d'échelle des quatre intitulés — voir l'en-tête de la classe.
  static const double _echelleMaxLibelles = 1.15;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: barreNavigationTheme(Theme.of(context).colorScheme),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _echelleMaxLibelles,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations,
        ),
      ),
    );
  }
}
