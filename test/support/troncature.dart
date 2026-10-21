/// L'ASSERTION « RIEN NE SE COUPE », partagée par les bancs qui montent un
/// écran traduit.
///
/// ── POURQUOI ELLE A QUITTÉ `accueil_langues_test.dart` ──────────────────────
///
/// Elle y était née, locale à ce fichier, et elle y suffisait tant qu'UN SEUL
/// banc montait des écrans traduits. La vague 2 a traduit les trois listes du
/// catalogue, et le banc qui les monte déjà dans les deux langues avec leurs
/// données est `bandes_filtres_test.dart` — un deuxième appelant, donc.
///
/// La copier était le pari que `polices.dart` et `mesures.dart` racontent tous
/// les deux, et qui a coûté une publication à ce dépôt : quatre copies d'une
/// même fonction de banc, dont trois abandonnaient en silence. Une deuxième
/// copie de CELLE-CI aurait divergé sur la liste des exemptions, et c'est
/// précisément cette liste qui décide ce qui tombe.
///
/// Elle est donc ici, à côté de `echelles.dart` qui décide de sa sévérité et de
/// `mesures.dart` qui lui donne ses mesures — NEUF depuis que `coupeDansLeMot`
/// et les deux lectures dont il a besoin, `motLePlusLargeLibre` et
/// `lignesPosees`, sont entrés dans l'assertion : `texteDe`, `voulue`, `recue`,
/// `motLePlusLarge`, `motLePlusLargeLibre`, `coupeDansLeMot`, `lignesPosees`,
/// `peint`, `porteUnNombre`.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'echelles.dart';
import 'mesures.dart';

/// Tous les paragraphes peints sous [racine], chacun contrôlé sur les TROIS
/// coupures que `mesures.dart` sait lire : celle que le `TextPainter` déclare
/// ([RenderParagraph.didExceedMaxLines]), celle qu'il ne déclare pas
/// ([motLePlusLarge] contre [recue]), et celle que ni l'une ni l'autre ne
/// voit ([coupeDansLeMot]).
///
/// ── POURQUOI LE TROISIÈME DÉTECTEUR A MANQUÉ, ET CE QUE ÇA A COÛTÉ ─────────
///
/// Il manquait, et `mesures.dart` prévenait pourtant en toutes lettres que les
/// deux premiers sont AVEUGLES à la coupure dans le mot : une fois le mot
/// cassé, `minIntrinsicWidth` à la largeur reçue s'effondre à la largeur d'un
/// caractère, donc `motLePlusLarge <= recue` passe au vert PARCE QUE le défaut
/// existe. Mesuré sur `LoginPage` seule, 320 × 640, texte × 1,5, locale fr :
///
///   « Se connecter » — 124,6 voulus pour 94,0 reçus, 3 LIGNES posées,
///   `motLePlusLarge` 24,1 contre 95,1 sans borne. `didExceedMaxLines` =
///   false, 24,1 <= 94,0 : LES DEUX ASSERTIONS PASSENT sur un libellé de
///   bouton coupé en plein milieu de « connecter ».
///
/// Idem « S'inscrire » à 2,0 (15,1 contre 116,1) et « VH-WHVQKVHM » de la
/// fiche véhicule à 320 × 1,5 (158,0 / 148,0, mot 123,1). Les cas de la
/// vague 2 dépendaient tous de ce détecteur et aucun ne l'appelait.
///
/// ── CE QUE LE DÉTECTEUR VOIT EXACTEMENT, ET SA LIMITE MESURÉE ──────────────
///
/// Il compare les deux largeurs minimales — à la largeur reçue contre sans
/// borne — et dénonce donc TOUTE cassure du plus long segment insécable, sous
/// DEUX formes que la mesure distingue :
///
///  — la coupure CARACTÈRE PAR CARACTÈRE, quand le moteur n'a aucune césure
///    légale : « Se connecter » retombe à 24,1 pour 95,1, « Motorisation » à
///    13,6 pour 140,7, « 18 000 FCFA » à 32,3 pour 267,4. La largeur d'un ou
///    deux signes : c'est la signature de ce cas.
///  — la coupure AU TRAIT D'UNION, qui est une césure légale et que
///    `minIntrinsicWidth` compte quand même : « Bobo-Dioulasso » retombe de
///    157,7 à 99,2 à 150,0 reçus, c'est-à-dire exactement « Dioulasso ».
///    « VH-WHVQKVHM » tombait de même, de 158,0 à 123,1.
///
/// LE DÉTECTEUR NE LES SÉPARE PAS, et c'est assumé dans ce sens-là : les deux
/// posent une chaîne sur deux lignes là où la mise en page en promettait une,
/// et aucun des deux autres détecteurs ne les voit. Mais la seconde forme n'est
/// pas un MENSONGE — « Dioulasso » reste « Dioulasso » —, donc le relevé et la
/// raison d'échec ne prétendent pas que le moteur a coupé caractère par
/// caractère : ils donnent les deux largeurs et le nombre de lignes, et laissent
/// lire laquelle des deux formes c'est.
///
/// ── LA RÈGLE, ET SON UNIQUE EXCEPTION ──────────────────────────────────────
///
/// UNE CHAÎNE DE L'APPLICATION NE DOIT JAMAIS SE COUPER. C'est nous qui
/// l'écrivons, nous qui la traduisons, et sa longueur est donc notre
/// responsabilité : « Mettre à jour le kilométrage » tronqué en « Mettre à
/// jour le kilo… » est un défaut, pas un compromis.
///
/// UNE VALEUR SANS BORNE, elle, a le droit de s'ellipser, et plusieurs le
/// font par construction (`maxLines: 1, overflow: ellipsis` écrit dans
/// `_SectionTitle`, `_VehicleCard`, `_PartTile`, `_DealTile`) : le surnom
/// qu'un propriétaire tape, un nom de modèle ou de pièce que le serveur
/// envoie. Aucune largeur d'écran ne peut les garantir, et les refuser
/// voudrait dire replier des cartes sur quatre lignes pour un nom de
/// fantaisie.
///
/// [valeursSansBorne] porte donc ces valeurs, nommément, telles que la
/// fixture les pose. Un texte qui en CONTIENT une est exempté ; tous les
/// autres sont tenus à la règle. C'est volontairement une liste à tenir à
/// jour plutôt qu'un assouplissement général : le jour où une chaîne de
/// l'application se coupe, il faut qu'elle tombe, et non qu'elle glisse dans
/// une exception écrite pour quelqu'un d'autre.
/// ── ET CE QUE L'ÉCHELLE CHANGE ─────────────────────────────────────────────
///
/// [echelle] décide de la SÉVÉRITÉ, pas de ce qui est mesuré : tout est
/// mesuré à toutes les échelles, et le relevé des défauts est IMPRIMÉ dans
/// tous les cas. Jusqu'à 1,5 un défaut fait tomber le test. À 2,0 il ne fait
/// plus tomber que s'il rend une information FAUSSE — voir [porteUnNombre] et
/// `support/echelles.dart` pour la raison de cette frontière-là.
void aucuneTroncature(
  WidgetTester tester, {
  required Finder racine,
  required String ou,
  required double echelle,
  Set<String> valeursSansBorne = const {},
}) {
  final paragraphes = tester
      .renderObjectList<RenderParagraph>(
        find.descendant(of: racine, matching: find.byType(RichText)),
      )
      .toList();

  expect(
    paragraphes,
    isNotEmpty,
    reason:
        'Aucun paragraphe peint sous $ou : la page est restée sur son '
        'indicateur de chargement, et ce test ne mesure rien.',
  );

  // Le relevé, construit pour TOUTES les échelles et imprimé dès qu'il n'est
  // pas vide. C'est lui qui remplace l'assertion à 2,0 : on ne compte plus
  // ces défauts comme des échecs, on continue de les voir.
  final releve = <String>[];

  for (final p in paragraphes) {
    final texte = texteDe(p);
    // Les valeurs sans borne sont écartées AVANT tout le reste, y compris
    // avant la règle du chiffre : un nom de pièce qui porte une référence
    // — « Filtre à huile moteur cartouche 04152-YZZA1 » — contient des
    // chiffres sans être un nombre, et sa longueur n'est pas la nôtre.
    if (valeursSansBorne.any(texte.contains)) continue;

    final coupe = p.didExceedMaxLines;
    final deborde = motLePlusLarge(p) > recue(p) + 0.01;
    // LE TROISIÈME DÉTECTEUR, AU MÊME RANG QUE LES DEUX AUTRES. Il n'est ni en
    // dernier recours ni réservé aux nombres : un libellé de bouton cassé en
    // « conne / cter » est du même défaut qu'un prix cassé, et il ne se
    // déclare nulle part ailleurs.
    final dansLeMot = coupeDansLeMot(p);
    if (!coupe && !deborde && !dansLeMot) continue;

    releve.add(
      '«$texte» '
      '${voulue(p).toStringAsFixed(1)} voulus / '
      '${recue(p).toStringAsFixed(1)} reçus, '
      'mot ${motLePlusLarge(p).toStringAsFixed(1)}'
      '${coupe ? ", COUPÉ peint «${peint(p, recue(p))}»" : ""}'
      '${deborde ? ", DÉBORDE sans ellipse" : ""}'
      '${dansLeMot ? ", SEGMENT INSÉCABLE CASSÉ (${motLePlusLargeLibre(p).toStringAsFixed(1)} sans borne, ${lignesPosees(p)} lignes)" : ""}'
      '${porteUnNombre(texte) ? ", PORTE UN CHIFFRE" : ""}',
    );

    // Un paragraphe qui porte un chiffre est tenu à la règle stricte À TOUTE
    // ÉCHELLE : « 18 000 FC » se lit comme un prix entier, et comme un autre
    // prix que celui du serveur. C'est le seul défaut que 2,0 ne rachète pas.
    //
    // UNE EXCEPTION EXISTE, ET IL FAUT LA NOMMER ICI PLUTÔT QUE DE LA LAISSER
    // SE DÉCOUVRIR : le prix des cartes de pièce et d'accessoire se replie à
    // 2,0, et le groupe « le prix tient sur une ligne tant qu'on l'exige » de
    // `bandes_filtres_test.dart` classe ce repli en dégradation acceptée. Les
    // deux doctrines ne se heurtaient pas tant que les listes AVEC DONNÉES ne
    // passaient par `aucuneTroncature` nulle part — seul l'écran VIDE y
    // passait. Mesuré alors : six cas porteraient un prix cassé ET un chiffre
    // (« 109 500 FCFA » 162,8 pour 129,0 reçus à 320 × 2,0, et cinq voisins),
    // et la règle ci-dessous les ferait tomber.
    //
    // CE PARAGRAPHE DEMANDAIT UN ARBITRAGE « le jour où quelqu'un branche une
    // matrice à données sur cette fonction ». Le lot des grilles responsives
    // l'a branchée, aux largeurs de tablette. L'arbitrage est donc dû, et le
    // voici — avec la raison pour laquelle il ne coûte rien.
    //
    // LE CONFLIT NE SE DÉCLENCHE PAS, ET CE N'EST PAS UN HASARD. Le prix se
    // casse quand sa colonne est ÉTROITE : les six cas mesurés le sont à
    // 129,0 points reçus, sur un téléphone de 320. Or la règle responsive
    // maintient la colonne autour de 190 points à toutes les largeurs —
    // 175,4 à 1280 points d'écran, 192,0 à 1024. Les largeurs de tablette
    // donnent donc des colonnes PLUS LARGES que celles où le prix se replie,
    // jamais plus étroites. Une matrice à données sur tablette ne rencontre
    // pas le cas que ces deux doctrines se disputent.
    //
    // La contradiction subsiste donc en droit et pas en fait, et elle
    // redeviendra réelle si quelqu'un abaisse le plancher de deux colonnes ou
    // branche cette fonction sur une matrice à données de TÉLÉPHONE à 2,0.
    // Ce jour-là, trancher : soit exempter nommément le prix des cartes, soit
    // durcir le groupe du prix. Hors sujet pour la règle du propriétaire — on
    // tient jusqu'à 1,5, et à 1,5 aucun prix ne se replie dans aucune des
    // deux langues, à aucune largeur.
    if (tenue(echelle) || porteUnNombre(texte)) {
      expect(
        coupe,
        isFalse,
        reason:
            '$ou : « $texte » est COUPÉ — '
            '${voulue(p).toStringAsFixed(1)} points voulus pour '
            '${recue(p).toStringAsFixed(1)} reçus, et il n\'en reste peint '
            'que « ${peint(p, recue(p))} ».'
            '${tenue(echelle) ? "" : " Ce paragraphe porte un CHIFFRE : la "
                "règle de l’échelle 2,0 ne l’exempte pas, parce qu’un "
                "nombre coupé est FAUX et non seulement incomplet."}',
      );

      expect(
        motLePlusLarge(p),
        lessThanOrEqualTo(recue(p) + 0.01),
        reason:
            '$ou : un mot de « $texte » fait '
            '${motLePlusLarge(p).toStringAsFixed(1)} points pour '
            '${recue(p).toStringAsFixed(1)} reçus. Il sera rogné sans '
            'ellipse, donc en silence : `didExceedMaxLines` ne voit pas ce '
            'cas.',
      );

      expect(
        dansLeMot,
        isFalse,
        reason:
            '$ou : le plus long segment insécable de « $texte » est CASSÉ — '
            '${voulue(p).toStringAsFixed(1)} points voulus pour '
            '${recue(p).toStringAsFixed(1)} reçus, et ce segment tombe de '
            '${motLePlusLargeLibre(p).toStringAsFixed(1)} sans borne à '
            '${motLePlusLarge(p).toStringAsFixed(1)} à la largeur reçue, sur '
            '${lignesPosees(p)} lignes. Une largeur d\'arrivée de l\'ordre '
            'd\'un ou deux signes dit que le moteur n\'avait AUCUNE césure '
            'légale et a coupé caractère par caractère ; une largeur de mot '
            'entier dit qu\'il a cassé à un trait d\'union. Ni '
            '`didExceedMaxLines` ni la comparaison « segment insécable contre '
            'largeur reçue » ne voient ni l\'un ni l\'autre — voir '
            '[coupeDansLeMot] dans support/mesures.dart.',
      );
    }
  }

  if (releve.isNotEmpty) {
    // ignore: avoid_print
    print(
      '@@RELEVÉ $ou — ${releve.length} paragraphe(s) en défaut sur '
      '${paragraphes.length}'
      '${tenue(echelle) ? " (ÉCHELLE ASSERTÉE : le test tombe)" : " (échelle 2,0 : dégradation acceptée, voir support/echelles.dart)"}'
      '\n   ${releve.join('\n   ')}',
    );
  }
}
