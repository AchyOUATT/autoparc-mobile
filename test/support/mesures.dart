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
/// ── CE FICHIER EST DÉSORMAIS LA SOURCE UNIQUE, ET C'EST UNE DETTE PAYÉE ─────
///
/// Il l'était pour deux bancs sur trois. `carte_geometrie_test.dart` gardait
/// ses propres copies, avec cette condition écrite ici : « le lot qui ouvrira
/// ce fichier-là pour une autre raison devra les faire passer ici ». La règle
/// des échelles de texte — `echelles.dart` — l'a ouvert, et la migration a donc
/// été faite, avec les deux récits que ses copies portaient en propre et qui
/// sont désormais sur [recue] et sur [pose] :
///
/// — la largeur reçue qui compte les 14 points de l'icône de localisation, et
///   qui condamnait la ligne de ville ;
/// — le `maxLines` retiré de [pose], qui dénonçait « Motorisation non
///   renseignée » comme un mot de 123,5 points dans huit cases et dans les deux
///   langues.
///
/// `polices.dart` raconte ce que quatre copies de la même fonction ont coûté :
/// une publication. Trois copies de six fonctions de mesure étaient le même
/// pari.

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
/// intermédiaires sans qu'on ait à les connaître — celle du `Card`, celle du
/// `Padding` du bloc de texte, et les 14 POINTS QUE L'ICÔNE DE LOCALISATION
/// retirait à la ligne de ville. Ce sont eux qui ont condamné cette ligne :
/// « Dioulasso » réclame 121 points pour 105 reçus à 320 points d'écran et à
/// l'échelle 2,0, et aucun calcul fait depuis la largeur de la carte ne l'aurait
/// vu.
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

/// La largeur du plus long segment INSÉCABLE du paragraphe, À LA LARGEUR REÇUE.
///
/// C'est la mesure qui attrape ce que `didExceedMaxLines` laisse passer : un
/// mot plus large que la ligne est posé seul sur sa ligne et dépasse
/// horizontalement, sans que le paragraphe se déclare tronqué. Le `Card` le
/// rogne alors en silence.
///
/// ELLE A UN ANGLE MORT, et [coupeDansLeMot] existe pour lui.
double motLePlusLarge(RenderParagraph p) => pose(p).minIntrinsicWidth;

/// La largeur du plus long segment insécable, remis en page SANS BORNE.
///
/// C'est la largeur du mot tel qu'il est, indépendamment de la place qu'on lui
/// a donnée. [motLePlusLarge], elle, mesure ce qui reste de ce mot APRÈS que le
/// moteur a éventuellement coupé dedans.
double motLePlusLargeLibre(RenderParagraph p) => (TextPainter(
  text: p.text,
  textDirection: p.textDirection,
  textScaler: p.textScaler,
)..layout()).minIntrinsicWidth;

/// Vrai quand le moteur a coupé DANS un mot, faute de pouvoir faire autrement.
///
/// ── L'ANGLE MORT QUE CETTE FONCTION COMBLE ──────────────────────────────────
///
/// Quand un paragraphe est ENTIÈREMENT fait d'un seul segment insécable plus
/// large que sa ligne — ce qu'est un montant, U+202F entre les milliers et
/// U+00A0 devant la devise —, le moteur n'a plus aucune césure légale et se
/// rabat sur une coupure CARACTÈRE PAR CARACTÈRE : « 109 500 FCFA » devient
/// « 109 500 FCF » puis « A » seul sur la deuxième ligne.
///
/// AUCUN DES DEUX DÉTECTEURS HABITUELS NE LE VOIT, et c'est mesuré :
/// `didExceedMaxLines` reste FAUX — le paragraphe n'a pas de `maxLines`, donc il
/// se replie au lieu de se déclarer tronqué —, et [motLePlusLarge] rend 17,74,
/// c'est-à-dire la largeur d'UN caractère. Une fois le mot cassé, la largeur
/// minimale du paragraphe devient celle d'une lettre, et la comparaison
/// « segment insécable contre largeur reçue » passe au vert sur un prix coupé en
/// deux.
///
/// La lecture qui le voit est la comparaison des deux largeurs minimales : à la
/// largeur reçue contre sans borne. Elles sont égales quand le moteur a trouvé
/// une césure légale ; la première s'effondre quand il a coupé dans le mot.
///
/// C'EST LE DÉTECTEUR DU « FAUX ». Un titre ellipsé est incomplet et l'œil le
/// voit ; un nombre cassé en deux est FAUX et se lit comme un autre nombre. Voir
/// [porteUnNombre] et `echelles.dart` : c'est le seul défaut que l'échelle 2,0
/// ne rachète pas.
bool coupeDansLeMot(RenderParagraph p) =>
    motLePlusLarge(p) < motLePlusLargeLibre(p) - 0.01;

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

/// Vrai quand [texte] porte un CHIFFRE, donc quand une coupure le rend FAUX et
/// non seulement incomplet.
///
/// ── POURQUOI CE PRÉDICAT EXISTE ─────────────────────────────────────────────
///
/// C'est la frontière que `echelles.dart` trace pour l'échelle 2,0 : au-delà de
/// 1,5 on cesse d'exiger l'absence de troncature, mais jamais l'absence de
/// MENSONGE. Les deux ne se ressemblent pas.
///
/// « Land Rover Range Rov… » est incomplet, et l'œil le voit : aucun véhicule
/// ne s'appelle ainsi, l'ellipse est là, on sait qu'il manque quelque chose.
/// « 18 000 FC » est FAUX : c'est un prix entier, plausible, et c'est un AUTRE
/// prix que celui du serveur. Rien ne signale le manque. Le défaut mesuré qui a
/// motivé la distinction est exactement celui-là — le prix d'une carte de pièce
/// replié EN COUPANT DANS LE MOT, « 109 500 FCF » puis « A », parce qu'un
/// montant est un seul segment insécable (U+202F entre les milliers, U+00A0
/// devant la devise) et que le moteur se rabat alors sur une coupure caractère
/// par caractère.
///
/// LE CRITÈRE EST « PORTE UN CHIFFRE » ET NON « EST UN PRIX », et c'est
/// volontaire : « dépassée de 11 jours » rognée en « dépassée de 1… » est du
/// même défaut, et un critère écrit pour les prix seuls l'aurait laissée
/// passer. Un kilométrage, un compte de jours, le « +N » de la ligne de
/// compatibilité tombent tous dessous.
///
/// LE COÛT ASSUMÉ : une phrase qui contient un chiffre par accident est tenue à
/// la règle stricte même à 2,0. C'est le bon sens de l'erreur — on exige trop
/// plutôt que trop peu sur ce qui peut mentir.
bool porteUnNombre(String texte) => RegExp(r'\d').hasMatch(texte);
