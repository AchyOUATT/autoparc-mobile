import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Le bouton flottant du catalogue, qui s'efface quand on descend la liste.
///
/// ── LE DÉFAUT MESURÉ ────────────────────────────────────────────────────────
///
/// Le bouton « Ajouter » est un `FloatingActionButton.extended` : 114,4 × 56,0
/// points à l'échelle 1,0, 128,1 × 56,0 à l'échelle 1,3, posé par le `Scaffold`
/// à 16 points du bas du corps. Mesuré sur la page montée dans sa coque, il
/// RECOUVRE une carte de la liste dans les six cases éprouvées, et à 320 points
/// et à l'échelle 1,3 c'est la DEUXIÈME carte — celle de droite de la seule
/// rangée qui tienne à l'écran : il mord sur ses 28 derniers points, là où est
/// le prix.
///
/// ── CE QUI EST FAIT, ET CE QUI NE PEUT PAS L'ÊTRE ───────────────────────────
///
/// Le bouton s'efface dès que le doigt descend la liste et revient dès qu'il
/// remonte. C'est ce qui rend le prix lisible sans rien coûter à la densité.
///
/// L'AUTRE VOIE A ÉTÉ CHIFFRÉE ET ÉCARTÉE : creuser la liste de la hauteur du
/// bouton coûterait 56 + 16 + 16 = 88 points de hauteur utile, soit plus du
/// double des 40 points que ce lot vient de rendre en fusionnant les deux
/// bandes de filtres. On ne paie pas une gêne au défilement par deux fois le
/// gain du lot.
///
/// IL RESTE UN RECOUVREMENT AU REPOS, et il est dit plutôt que caché : avant
/// tout geste, le bouton couvre encore le bas de la rangée visible. Le faire
/// disparaître aussi dans cet état-là demanderait de sortir l'action du bouton
/// flottant — un bouton « + » dans la barre de titre, par exemple —, c'est à
/// dire de changer le rang d'une action principale. Cette décision n'est pas
/// celle de ce lot.
///
/// La liste garde en plus son dégagement de 88 points en bas, qui est ce qui
/// libère la DERNIÈRE rangée : les deux mécanismes ne se remplacent pas.
class BoutonFlottantEffacable extends StatefulWidget {
  /// Le contrôleur de la liste au-dessus de laquelle le bouton flotte.
  final ScrollController controleur;
  final Widget enfant;

  const BoutonFlottantEffacable({
    super.key,
    required this.controleur,
    required this.enfant,
  });

  @override
  State<BoutonFlottantEffacable> createState() =>
      _BoutonFlottantEffacableState();
}

class _BoutonFlottantEffacableState extends State<BoutonFlottantEffacable> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    widget.controleur.addListener(_auDefilement);
  }

  @override
  void dispose() {
    widget.controleur.removeListener(_auDefilement);
    super.dispose();
  }

  void _auDefilement() {
    // `userScrollDirection` et non le signe du déplacement : il vaut `idle`
    // tant que l'utilisateur n'a rien fait, donc un rebond d'élasticité ou un
    // `jumpTo` de rafraîchissement ne fait pas clignoter le bouton.
    if (!widget.controleur.hasClients) return;
    final sens = widget.controleur.position.userScrollDirection;
    if (sens == ScrollDirection.reverse && _visible) {
      setState(() => _visible = false);
    } else if (sens == ScrollDirection.forward && !_visible) {
      setState(() => _visible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Même égard que la pulsation de la puce « Bonne affaire » : quand le
    // système demande moins d'animations, le bouton apparaît et disparaît d'un
    // coup au lieu de ne jamais le faire.
    final duree = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedScale(
      scale: _visible ? 1.0 : 0.0,
      duration: duree,
      curve: Curves.easeOut,
      // `IgnorePointer` est nécessaire : une échelle nulle ne retire pas la
      // boîte du pointage, et un bouton invisible qui ouvre quand même le
      // formulaire d'ajout serait pire que le recouvrement qu'on corrige.
      child: IgnorePointer(ignoring: !_visible, child: widget.enfant),
    );
  }
}
