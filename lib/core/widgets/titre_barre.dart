import 'package:flutter/material.dart';

/// LE TITRE D'UNE BARRE DE CATALOGUE, ET LES TROIS FORMES QU'IL PREND.
///
/// ── LE DÉFAUT MESURÉ, ET POURQUOI AUCUN BANC NE LE VOYAIT ──────────────────
///
/// La barre des trois listes du catalogue ne porte pas les mêmes commandes
/// selon le rôle : sous `if (!isStaff)`, la liste des pièces et celle des
/// accessoires ajoutent le bouton du besoin et celui du panier, soit DEUX
/// cibles tactiles de 48 points de plus. Relevé à 320 points d'écran, sur la
/// largeur que le titre reçoit réellement :
///
///              personnel   client
///   véhicules     224,0     176,0   (deux commandes)
///   pièces        224,0     128,0   (trois commandes)
///   accessoires   224,0     128,0   (trois commandes)
///
/// Le modèle est exact : 320 − 48 de `leading` − 48 par commande, les trois
/// pages posant `titleSpacing: 0`. Ce tableau a d'abord été écrit avec un
/// `leading` de 56, ce qui le faussait de huit points sur ses six entrées et
/// le mettait en contradiction avec les 128,0 que ce même fichier emploie
/// trente lignes plus bas — la faute exacte qui avait fait renvoyer le
/// premier lot de cette vague. Les écarts entre rôles, eux, étaient justes
/// dès le début : 48 points par commande ajoutée. Et le rôle
/// que ces écrans servent le plus — le client est le seul à voir le panier —
/// était le seul qu'aucun banc ne montait, `poserPage` posant le personnel par
/// défaut. Ce que ça cachait, dans les DEUX langues :
///
///   « Accessoires »      129,3 à 1,3 et 133,3 à 1,5 pour 128,0 reçus
///   « Accessories »      129,5          133,5
///   « Pièces détachées » 142,7 DÈS 1,0, 185,6 à 1,3, 191,3 à 1,5
///   « Spare parts »      121,7 à 1,3,   125,4 à 1,5
///
/// « Pièces détachées » tombe au RÉGLAGE PAR DÉFAUT, c'est-à-dire pour tout
/// client sur un petit écran : il n'en reste peint que « Pièces d ».
///
/// ── LA BARRE EST CLAMPÉE À 1,34 PAR FLUTTER, ET C'EST MESURÉ ───────────────
///
/// `AppBar` enveloppe son titre dans `MediaQuery.withClampedTextScaling(
/// maxScaleFactor: _kMaxTitleTextScaleFactor)`, qui vaut 1,34 — d'où les mêmes
/// 133,3 points à 1,5 et à 2,0, et le `scaler=linear (1.34x)` lu sur l'objet de
/// rendu. CE FICHIER NE RECOPIE PAS CE NOMBRE : toutes ses mesures sont prises
/// À L'INTÉRIEUR du titre, là où `MediaQuery.textScalerOf` rend déjà l'échelle
/// clampée. Un calcul fait en dehors mesurerait une échelle que la barre ne
/// peindra jamais.
///
/// ── LES TROIS FORMES, DANS CET ORDRE ───────────────────────────────────────
///
///  1. UNE LIGNE AU CORPS PLEIN, quand le titre entier tient. C'est le cas de
///     toutes les cases du personnel, de « Véhicules » partout, et du défaut
///     par lequel presque tout le monde passe.
///  2. DEUX LIGNES AU CORPS PLEIN, quand le titre a une césure légale et que
///     deux lignes tiennent dans la hauteur de la barre. « Pièces détachées »
///     à l'échelle 1,0 : deux lignes de 22,0 points dans les 48,0 de la barre,
///     et le plus long mot — « détachées », 83,8 points — tient dans 128,0.
///  3. LE PLUS GRAND CORPS QUI TIENNE, sur une ligne ou sur deux, quand aucune
///     des deux formes précédentes ne passe. « Accessoires » est UN SEUL mot de
///     133,3 points : aucune largeur de barre ne le replie, et à 320 points un
///     client ne peut pas lui en donner plus de 128,0.
///
/// ── POURQUOI RÉDUIRE LE CORPS, ET PAS AUTRE CHOSE ──────────────────────────
///
/// Les autres leviers ont été mesurés et écartés :
///
/// — RETIRER UNE COMMANDE rendrait 48 points, mais la cloche porte le compte
///   des non-lus et le panier est le geste d'achat : aucun des trois ne peut
///   descendre dans un menu débordant sans décision du propriétaire.
/// — RÉTRÉCIR LES COMMANDES à 44 points rendrait 12 points et ramènerait la
///   cible tactile sous les 48 que ce dépôt tient — c'est l'assertion n° 1 de
///   `bandes_filtres_test.dart`.
/// — GRANDIR LA BARRE pour y poser deux lignes à toute échelle coûterait 8
///   points de hauteur à 1,3 et 38 à 2,0, à TOUT LE MONDE et sur TOUS les
///   écrans, y compris ceux où le titre tient déjà sur une ligne.
/// — `BoxFit.scaleDown`, qui est l'arbitrage du dépôt pour les prix, rend le
///   même résultat visuel mais SORT LE PARAGRAPHE DE LA MESURE : un enfant de
///   `FittedBox` reçoit une contrainte non bornée, donc `recue` vaut
///   `Infinity` et les trois détecteurs de `test/support/mesures.dart` passent
///   tous au vert sans rien regarder. Mesuré. Le corps réduit à la main rend le
///   même pixel et laisse le banc faire son travail.
///
/// CE N'EST PAS UNE BORNE SUR L'ÉCHELLE DE TEXTE au sens de
/// `test/support/echelles.dart` : le titre GRANDIT toujours avec le réglage de
/// l'utilisateur, seulement moins vite. « Pièces détachées » pour un client à
/// 320 points est peint à 18,0 points de corps à l'échelle 1,0 et à 20,0 à
/// partir de 1,3 ; « Accessoires » à 18,0 puis 23,1. Aucune case ne descend
/// sous le corps non grossi, et c'est la propriété qu'il faut tenir.
class TitreBarre extends StatelessWidget {
  const TitreBarre(this.titre, {super.key});

  final String titre;

  /// Le nombre de lignes que la forme 2 et la forme 3 s'autorisent.
  ///
  /// Deux, et pas trois : au-delà, un titre de barre cesse d'être un titre. Si
  /// un libellé futur demandait une troisième ligne, le facteur calculé ici ne
  /// suffirait pas et le banc le dirait — `aucuneTroncature` mesure ce titre
  /// comme n'importe quel autre paragraphe, ce qui est exactement ce que
  /// `FittedBox` aurait empêché.
  static const int _lignesMax = 2;

  /// La marge laissée sur la largeur reçue, en points.
  ///
  /// Un demi-point. Il ne corrige pas une erreur de calcul mais l'ARRONDI du
  /// moteur : donner au titre exactement la largeur qu'il réclame le laisse à
  /// égalité avec sa contrainte, et un dixième de point de différence entre la
  /// mise en page sèche et la mise en page réelle rouvrirait le défaut. On se
  /// trompe du côté qui ne coupe rien.
  static const double _marge = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        // LE STYLE AMBIANT EST CELUI DE LA BARRE, posé par `AppBar` dans un
        // `DefaultTextStyle` — d'où la famille de police ET le corps de 18
        // points que `themeAutoParc` écrit. Un `TextPainter` construit sur un
        // style nu mesurerait la police de repli, presque deux fois plus large :
        // voir test/support/polices.dart pour ce que cette confusion a coûté.
        final ambiant = DefaultTextStyle.of(context);
        final style = ambiant.style;
        final sens = Directionality.of(context);

        // DÉJÀ CLAMPÉE À 1,34 par `AppBar`, parce que ce `build` s'exécute sous
        // son `MediaQuery.withClampedTextScaling`.
        final echelle = MediaQuery.textScalerOf(context);

        final hauteurBarre =
            Theme.of(context).appBarTheme.toolbarHeight ?? kToolbarHeight;
        final dispo = contraintes.maxWidth - _marge;

        TextPainter poser({double facteur = 1.0, double? largeur}) =>
            TextPainter(
              text: TextSpan(
                text: titre,
                style: facteur == 1.0
                    ? style
                    : style.copyWith(fontSize: (style.fontSize ?? 18) * facteur),
              ),
              textDirection: sens,
              textScaler: echelle,
            )..layout(maxWidth: largeur ?? double.infinity);

        // La largeur du titre ENTIER sur une ligne, et celle de son plus long
        // segment insécable. La seconde est prise SANS BORNE : bornée, le
        // moteur a déjà cassé le mot et `minIntrinsicWidth` est retombé à la
        // largeur d'un caractère — c'est l'angle mort que `coupeDansLeMot`
        // comble dans test/support/mesures.dart.
        final uneLigne = poser();
        final voulue = uneLigne.width;
        final mot = uneLigne.minIntrinsicWidth;
        final hauteurLigne = uneLigne.height;

        // ── Forme 1 ───────────────────────────────────────────────────────
        if (voulue <= dispo) {
          return Text(titre, maxLines: 1);
        }

        final deuxLignesTiennent =
            hauteurLigne * _lignesMax <= hauteurBarre;

        // ── Forme 2 ───────────────────────────────────────────────────────
        if (mot <= dispo && deuxLignesTiennent) {
          return Text(titre, maxLines: _lignesMax, softWrap: true);
        }

        // ── Forme 3 ───────────────────────────────────────────────────────
        //
        // Deux candidats, et on garde le PLUS GRAND corps des deux : replier
        // sur deux lignes n'est pas toujours moins coûteux qu'une ligne un peu
        // plus petite. « Pièces détachées » à 1,34 et 320 points client : une
        // ligne demanderait 0,667 du corps, deux lignes 0,828 — ce sont les
        // deux lignes qui gagnent. « Accessoires », un seul mot, n'a que le
        // premier candidat : 0,956.
        final surUneLigne = dispo / voulue;
        final surDeuxLignes = mot <= 0
            ? 0.0
            : [
                dispo / mot,
                hauteurBarre / (hauteurLigne * _lignesMax),
                1.0,
              ].reduce((a, b) => a < b ? a : b);

        final facteur = surUneLigne > surDeuxLignes
            ? surUneLigne
            : surDeuxLignes;

        return Text(
          titre,
          maxLines: _lignesMax,
          softWrap: true,
          style: style.copyWith(
            fontSize: (style.fontSize ?? 18) * facteur,
          ),
        );
      },
    );
  }
}
