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
