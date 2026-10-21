import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/widgets/grille_maconnerie.dart';

/// LA RÈGLE DU NOMBRE DE COLONNES, ÉPROUVÉE SANS ARBRE DE WIDGETS.
///
/// ── POURQUOI UN BANC À PART, ET POURQUOI IL EST LE PREMIER À LIRE ───────────
///
/// `carte_geometrie_test.dart` et `bandes_filtres_test.dart` comparent la
/// grille RENDUE à `nombreDeColonnes`. C'est la bonne assertion — elle dit que
/// les trois listes obéissent à la règle —, mais elle ne dit RIEN de la règle
/// elle-même : si elle rendait 2 partout, les deux bancs resteraient verts et
/// la tablette resterait cassée. C'est exactement le défaut que ce lot ferme,
/// et un banc écrit de la même façon le laisserait rouvert.
///
/// Ici, donc, aucune lecture de la production : des largeurs et des comptes
/// ÉCRITS À LA MAIN, qui tombent si la règle change.
void main() {
  group('Le plancher de deux colonnes', () {
    // LA CONTRAINTE DU PROPRIÉTAIRE, et elle prime sur tout le reste : « non,
    // je veux 2 annonces par lignes ». Deux colonnes à TOUTES les largeurs de
    // téléphone, et la frontière est posée à 420 points d'écran.
    //
    // Les largeurs ci-dessous sont des largeurs DISPONIBLES, c'est-à-dire ce
    // que la maçonnerie reçoit une fois les marges de page retirées. La plus
    // grande, 420,0, est le pire cas possible : une page future SANS AUCUNE
    // MARGE à la frontière exacte. Les trois listes d'aujourd'hui en retirent
    // 24 (véhicules) ou 16 (pièces et accessoires), donc elles sont encore
    // plus loin du seuil.
    const largeursDeTelephone = <double>[
      // 320, 360 et 411 points d'écran, sur la liste des véhicules…
      296.0, 336.0, 387.0,
      // …puis sur celles des pièces et des accessoires.
      304.0, 344.0, 395.0,
      // La frontière des 420 points, dans les trois montages.
      396.0, 404.0, 420.0,
    ];

    for (final largeur in largeursDeTelephone) {
      test('$largeur points disponibles rendent 2 colonnes', () {
        expect(
          nombreDeColonnes(largeur),
          2,
          reason:
              'À $largeur points disponibles la grille passerait à '
              '${nombreDeColonnes(largeur)} colonnes. La mise en page du '
              'téléphone a bougé, et c\'est la seule chose que ce lot '
              'n\'avait pas le droit de faire.',
        );
      });
    }

    test('une largeur minuscule ou absurde rend quand même 2 colonnes', () {
      // Une colonne unique n'est plus une mise en page de ce dépôt, et un
      // `LayoutBuilder` peut recevoir zéro — ou l'infini — pendant une
      // transition. Aucun de ces cas ne doit rendre 0, 1 ni une exception.
      expect(nombreDeColonnes(0), 2);
      expect(nombreDeColonnes(1), 2);
      expect(nombreDeColonnes(-50), 2);
      expect(nombreDeColonnes(double.infinity), 2);
      expect(nombreDeColonnes(double.nan), 2);
    });
  });

  group('La troisième colonne, et où elle commence', () {
    test('elle n\'arrive pas avant 475 points disponibles', () {
      // NON-VACUITÉ DU PLANCHER : si la règle rendait 2 partout, tout le
      // groupe précédent serait vert sans rien garantir. Ce test dit que la
      // règle sait compter au-delà de 2, et le seuil est écrit ici en clair.
      expect(nombreDeColonnes(474.0), 2);
      expect(nombreDeColonnes(475.0), 3);
    });

    test('475 points disponibles valent 491 points d\'écran au moins', () {
      // La traduction du seuil en largeur d'ÉCRAN, pour que la marge avec les
      // 420 points de la contrainte soit lisible : les pièces et les
      // accessoires retirent 16 points de marge, les véhicules 24.
      expect(nombreDeColonnes(490.0 - 16), 2, reason: '490 points d\'écran');
      expect(nombreDeColonnes(491.0 - 16), 3, reason: '491 points d\'écran');
      expect(nombreDeColonnes(498.0 - 24), 2, reason: '498 points d\'écran');
      expect(nombreDeColonnes(499.0 - 24), 3, reason: '499 points d\'écran');
    });
  });

  group('La grille suit la largeur, et les deux orientations avec', () {
    // LA MÊME TABLETTE, DEUX FOIS. 800 points en portrait, 1280 en paysage :
    // la règle ne connaît ni l'une ni l'autre, elle ne voit que deux largeurs,
    // et c'est ce qui fait que l'orientation est traitée sans être nommée.
    //
    // Les largeurs sont celles des véhicules (écran − 24) ; les comptes sont
    // ceux que la page rend réellement, et `carte_geometrie_test.dart` les
    // remesure sur l'arbre.
    const attendu = <(double, int)>[
      (576.0, 3), // 600 d'écran, tablette 7 pouces en portrait
      (776.0, 4), // 800, tablette 10 pouces en portrait
      (936.0, 5), // 960, la même en paysage
      (1000.0, 5), // 1024
      (1256.0, 7), // 1280
    ];

    for (final (largeur, colonnes) in attendu) {
      test('$largeur points disponibles rendent $colonnes colonnes', () {
        expect(nombreDeColonnes(largeur), colonnes);
      });
    }

    test('la carte reste autour de la largeur visée', () {
      // CE QUE LA RÈGLE PROMET VRAIMENT, et c'est par là qu'elle a été
      // choisie : la carte ne s'éloigne jamais beaucoup de 190 points.
      //
      // La borne vient de l'arrondi : `N = round(W / 190)` donne une carte
      // dans `[(2N−1)/(2N), (2N+1)/(2N)] × 190`, soit 142,5 à 237,5 points à
      // deux colonnes — l'intervalle le plus large, puisqu'il se resserre
      // quand N grandit. Avec l'écart de 6 points entre colonnes, le pire cas
      // réel est `(475 − 6) / 2 = 234,5` juste avant le passage à trois.
      //
      // ELLE ÉTAIT À 254,0, issue d'un intervalle écrit à l'envers dans la
      // doc de `largeurCarteVisee` (« 152 à 253 »). Dix-neuf points et demi de
      // mou : le banc ne pouvait pas attraper un dérapage de la règle, il ne
      // gardait que contre un effondrement. Resserrée sur la vraie borne.
      //
      // Le plancher de deux colonnes sous 420 points est ce qui fait descendre
      // la carte PLUS BAS que 142,5 sur téléphone, et c'est voulu : c'est la
      // décision du propriétaire, pas l'arithmétique.
      for (var largeur = 100.0; largeur <= 2000.0; largeur += 1.0) {
        final colonnes = nombreDeColonnes(largeur);
        final carte = largeurDUneColonne(largeur, colonnes, ecart: 6);
        if (largeur < 420) continue; // le plancher du téléphone décide ici
        expect(
          carte,
          lessThan(235.0),
          reason:
              '$largeur points disponibles donnent $colonnes colonnes de '
              '${carte.toStringAsFixed(1)} points : la carte géante est de '
              'retour.',
        );
        expect(
          carte,
          greaterThan(140.0),
          reason:
              '$largeur points disponibles donnent $colonnes colonnes de '
              '${carte.toStringAsFixed(1)} points, plus étroites que la '
              'carte du plus petit téléphone.',
        );
      }
    });
  });

  group('La hauteur de vignette', () {
    test('elle ne bouge pas d\'un point sous 420 points d\'écran', () {
      // LA PREUVE QUE LE PLANCHER TIENT. Les largeurs sont celles d'UNE
      // COLONNE sur les listes de pièces et d'accessoires : (écran − 16 − 6)/2.
      for (final ecran in <double>[320, 360, 411, 419, 419.99]) {
        final colonne = (ecran - 16 - 6) / 2;
        expect(
          hauteurVignetteCatalogue(colonne),
          hauteurVignettePlancher,
          reason:
              'À $ecran points d\'écran la colonne fait '
              '${colonne.toStringAsFixed(2)} points et la vignette '
              '${hauteurVignetteCatalogue(colonne).toStringAsFixed(2)} au '
              'lieu de $hauteurVignettePlancher.',
        );
      }
    });

    test('elle grandit quand la colonne dépasse celle du téléphone', () {
      // NON-VACUITÉ DU RAPPORT : sans ce test, `hauteurVignetteCatalogue`
      // pourrait rendre 140 partout et le test précédent resterait vert.
      //
      // 234,5 points est la colonne la plus large que la règle puisse
      // produire : juste sous le seuil des trois colonnes, sur la liste des
      // pièces. 0,70 × 234,5 = 164,2.
      expect(hauteurVignetteCatalogue(234.5), closeTo(164.15, 0.01));
      expect(
        hauteurVignetteCatalogue(234.5),
        greaterThan(hauteurVignettePlancher),
      );
    });

    test('la vignette reste moins haute que large', () {
      // LE CRITÈRE QUI AVAIT PORTÉ 118 À 140 : « le cadre approche le carré ».
      // Il doit rester vrai aux largeurs que la nouvelle règle produit.
      //
      // LE CADRE FAIT TOUTE LA LARGEUR DE COLONNE. Ce test soustrayait
      // d'abord « les 8 points de marge de `Card` » : cette marge existe bien
      // — `part_list_page.dart:478` et `accessory_list_page.dart:458` — mais
      // elle est `EdgeInsets.only(bottom: 8)`, donc BASSE SEULEMENT. Rien
      // n'est retiré sur les côtés, et le cadre vaut 149,00 et non 141,00 sur
      // le plus petit téléphone.
      //
      // Ce n'est pas un détail d'arrondi : la conclusion qu'on en tirait —
      // « à 149,0 la vignette est à 0,99 de son cadre, la marge est NULLE, un
      // écran plus étroit que 320 points la ferait basculer » — était une
      // alarme sur un chiffre fantôme. Le vrai rapport à 149,0 est
      // 140 / 149,0 = 0,94, et la bascule n'arrive qu'à 140,0 de colonne.
      //
      // LE BALAYAGE PART DONC DE 140,0, qui est la vraie frontière :
      // `hauteurVignetteCatalogue` rend `max(140, 0,70 × largeur)`, donc le
      // rapport atteint 1,0 exactement quand la colonne tombe à 140 points.
      // Partir de 149,0 laissait hors du balayage les neuf points où la règle
      // est le plus tendue.
      for (var largeur = 140.0; largeur <= 260.0; largeur += 0.5) {
        final cadre = largeur;
        final hauteur = hauteurVignetteCatalogue(largeur);
        expect(
          hauteur / cadre,
          lessThanOrEqualTo(1.0),
          reason:
              'À ${largeur.toStringAsFixed(1)} points de colonne la vignette '
              'est plus haute que large.',
        );
        // `greaterThanOrEqualTo` ET NON `greaterThan`, et le passage de l'un
        // à l'autre est la conséquence directe du cadre corrigé.
        //
        // `hauteurVignetteCatalogue` rend `max(140, 0,70 × largeur)` : dans le
        // régime proportionnel le rapport VAUT exactement 0,70, il ne peut pas
        // le dépasser. L'assertion stricte ne passait que grâce aux huit
        // points de marge fantôme, qui gonflaient artificiellement le rapport
        // — 140 / 192 = 0,729 au lieu de 140 / 200 = 0,700.
        //
        // Ce n'est donc pas un affaiblissement : c'est la borne réelle. Elle
        // garde ce qu'elle doit garder — qu'on ne revienne jamais à une
        // vignette en boîte aux lettres, ce que 0,70 exclut — et elle cesse
        // de prétendre une marge que la règle n'a jamais eue.
        // LA TOLÉRANCE N'EST PAS UN ARRONDI DE CONFORT. Le rapport vaut
        // exactement le facteur de la règle dans le régime proportionnel,
        // mais `0,70 × 202 / 202` ne rend pas 0,7 en virgule flottante : il
        // rend 0.6999999999999998, un ULP en dessous. Mesuré, pas supposé —
        // c'est la valeur que ce banc a affichée avant cette ligne.
        //
        // Comparer à `0.70` tout court ferait donc échouer le test sur une
        // propriété de la représentation des nombres et non sur la mise en
        // page. L'epsilon est de l'ordre de l'erreur machine, mille fois plus
        // petit que le moindre écart visible à l'œil.
        expect(
          hauteur / cadre,
          greaterThanOrEqualTo(0.70 - 1e-9),
          reason:
              'À ${largeur.toStringAsFixed(1)} points de colonne la vignette '
              'fait ${(hauteur / cadre).toStringAsFixed(2)} de son cadre : '
              'elle redevient la boîte aux lettres que 140 produisait sur '
              'une carte de 629 points.',
        );
      }
    });
  });
}
