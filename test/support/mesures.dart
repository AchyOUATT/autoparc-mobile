import 'package:flutter/rendering.dart';

/// Les outils qui mesurent LES GLYPHES PEINTS, et non le texte voulu.
///
/// ── LA LEÇON, ÉCRITE UNE FOIS POUR TOUTES ───────────────────────────────────
///
/// `find.text` compare le champ `data` du widget `Text` : le texte VOULU. Un
/// texte ellipsé le passe sans broncher, parce que l'ellipse se décide à la
/// mise en page et non à la construction. C'est ainsi que la ligne de
/// caractéristiques du catalogue a été déclarée affichée alors qu'elle était
/// tronquée sur TOUTES les cartes, au réglage de texte par défaut.
///
/// On lit donc trois choses, et pas une :
///
///  1. la largeur DEMANDÉE contre la largeur REÇUE ;
///  2. `RenderParagraph.didExceedMaxLines`, l'état de dépassement que le
///     `TextPainter` a réellement constaté ;
///  3. le plus long segment INSÉCABLE, parce qu'un mot plus large que sa ligne
///     est posé seul et déborde HORIZONTALEMENT sans que le paragraphe se
///     déclare tronqué — le `Card` le rogne alors en silence, et (2) ne voit
///     rien.
///
/// ── POURQUOI CE FICHIER N'EST PAS ENCORE LA SOURCE UNIQUE ───────────────────
///
/// Il l'est pour DEUX bancs sur trois. `bandes_filtres_test.dart` portait ses
/// propres copies de `voulue` et de `lignesPosees` ; le lot de la ligne de
/// compatibilité l'a touché pour une autre raison — il y mesure les cartes du
/// catalogue —, et c'est exactement la condition que ce commentaire posait
/// pour faire la migration. Six sites d'appel chacune, et `lignesPosees` est
/// montée ici avec l'incident qui l'avait fait naître.
///
/// `carte_geometrie_test.dart` garde les siennes. Ce n'est pas de la paresse :
/// ses copies portent chacune le commentaire de l'incident qui l'a créée — la
/// largeur reçue qui compte les 14 points de l'icône de localisation, le
/// `maxLines` retiré de `pose` qui dénonçait « Motorisation non renseignée »
/// comme un mot de 123,5 points —, et les déplacer sans les relire reviendrait
/// à perdre ces récits dans un lot qui ne touche pas aux véhicules. Le lot qui
/// ouvrira ce fichier-là pour une autre raison devra les faire passer ici —
/// `polices.dart` raconte ce que quatre copies de la même fonction ont coûté.

/// La largeur que ce paragraphe DEMANDE, remis en page sans borne et sur une
/// seule ligne.
double voulue(RenderParagraph p) => (TextPainter(
  text: p.text,
  textDirection: p.textDirection,
  textScaler: p.textScaler,
  maxLines: 1,
)..layout()).width;

/// La largeur que ce paragraphe a REÇUE.
///
/// Lue dans la contrainte de l'objet de rendu, et non recalculée depuis la
/// largeur de la case : c'est la seule valeur qui compte toutes les marges
/// intermédiaires sans qu'on ait à les connaître.
double recue(RenderParagraph p) => p.constraints.maxWidth;

/// Le paragraphe remis en page à la largeur qu'il a REÇUE.
///
/// SANS `maxLines`, et c'est une correction payée tout de suite : la première
/// version passait `maxLines: p.maxLines`, par souci de fidélité. Or
/// `minIntrinsicWidth` d'un paragraphe borné à UNE ligne vaut la largeur de
/// TOUT le texte — il ne peut pas se replier —, et [motLePlusLarge] se mettait
/// alors à dénoncer « Motorisation non renseignée » comme un mot de 123,5
/// points. Faux dans huit cases, et faux dans les deux langues, ce qui est le
/// signe qu'il s'agissait de l'outil et non de l'écran.
TextPainter pose(RenderParagraph p) => TextPainter(
  text: p.text,
  textDirection: p.textDirection,
  textScaler: p.textScaler,
)..layout(maxWidth: p.constraints.maxWidth);

/// La largeur du plus long segment INSÉCABLE du paragraphe.
double motLePlusLarge(RenderParagraph p) => pose(p).minIntrinsicWidth;

/// La hauteur d'UNE ligne de ce paragraphe, à son style et à son échelle.
///
/// Sert à juger un `maxLines` sur ce qui est PEINT. [lignesPosees] ne le peut
/// pas : il remet le texte en page SANS `maxLines` — voir [pose] et la
/// correction qu'il raconte —, donc un nom de modèle de 28 signes y rend 4
/// alors que l'écran en peint 2 et une ellipse. Mesuré sur la ligne de
/// compatibilité du catalogue, où l'assertion « deux lignes au plus » tombait
/// sur quatre cases en dénonçant une mise en page que le téléphone ne produit
/// pas.
double hauteurDUneLigne(RenderParagraph p) => (TextPainter(
  text: p.text,
  textDirection: p.textDirection,
  textScaler: p.textScaler,
  maxLines: 1,
)..layout()).height;

/// Combien de lignes le paragraphe occupe réellement à la largeur reçue.
///
/// Venue de `bandes_filtres_test.dart`, qui la portait en propre : c'est elle
/// qui a montré « Accessoires » cassé en deux lignes dans la barre du bas. Elle
/// répond à une question que [motLePlusLarge] et `didExceedMaxLines` ne posent
/// pas — un texte peut se replier sans rien perdre, et c'est la HAUTEUR qui
/// change alors, pas le contenu.
int lignesPosees(RenderParagraph p) => pose(p).computeLineMetrics().length;

/// Le plus long préfixe du texte qui tienne dans [dispo] AVEC son ellipse.
///
/// C'est-à-dire ce que l'œil voit réellement. `didExceedMaxLines` dit QU'IL
/// manque des signes ; ceci dit LESQUELS restent — et c'est cette chaîne qui
/// rend une raison d'échec lisible par quelqu'un qui n'a pas l'écran sous les
/// yeux.
String peint(RenderParagraph p, double dispo) {
  final texte = (p.text as TextSpan).toPlainText();
  if (voulue(p) <= dispo) return texte;
  var garde = '';
  for (var n = 1; n <= texte.length; n++) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${texte.substring(0, n)}…',
        style: (p.text as TextSpan).style,
      ),
      textDirection: p.textDirection,
      textScaler: p.textScaler,
      maxLines: 1,
    )..layout();
    if (tp.width > dispo) break;
    garde = texte.substring(0, n);
  }
  return garde;
}

/// Le texte brut d'un paragraphe.
String texteDe(RenderParagraph p) => (p.text as TextSpan).toPlainText();
