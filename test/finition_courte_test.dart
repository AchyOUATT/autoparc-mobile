// La finition affichée sur une carte, sans sa parenthèse de désambiguïsation.
//
// Les cas viennent du référentiel RÉEL, pas d'exemples inventés : les deux
// véhicules du catalogue de production qui portent une finition sont une BMW
// Série 5 F10 en « 528i (4 cyl. 2011-2016) » et une Toyota Corolla E180 en
// « S ». Le premier est précisément celui qui a motivé ce raccourcissement, le
// second celui qui ne doit surtout pas être touché.

import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/presentation/libelles_vehicule.dart';

void main() {
  group('finitionCourte', () {
    test('coupe la parenthèse de désambiguïsation', () {
      // Le cas réel : les deux 528i de la F10 ne diffèrent que par là.
      expect(finitionCourte('528i (4 cyl. 2011-2016)'), '528i');
      expect(finitionCourte('528i (6 cyl. 2010-2011)'), '528i');

      // Et les deux rendent la MÊME chaîne, ce qui est assumé : sur une carte,
      // « 528i » suffit à l'acheteur. La distinction reste entière sur la
      // fiche détaillée, qui est l'écran où l'on commande une pièce.
      expect(
        finitionCourte('528i (4 cyl. 2011-2016)'),
        finitionCourte('528i (6 cyl. 2010-2011)'),
      );
    });

    test('ne touche pas un nom sans parenthèse', () {
      for (final nom in ['S', 'XLE V6', 'GXR', 'xDrive30d', '330i xDrive', 'Hybrid Limited']) {
        expect(finitionCourte(nom), nom, reason: '« $nom » ne devait pas être modifié.');
      }
    });

    test('une finition absente rend une chaîne vide, jamais « null »', () {
      // Quatre des six véhicules du catalogue n'ont pas de finition. La carte
      // doit alors n'afficher RIEN — pas le mot « null », pas un tiret posé
      // par défaut, que l'appelant ne saurait plus distinguer d'une vraie
      // valeur.
      expect(finitionCourte(null), '');
      expect(finitionCourte(''), '');
      expect(finitionCourte('   '), '');
    });

    test('les espaces autour sont nettoyés', () {
      expect(finitionCourte('  S  '), 'S');
      expect(finitionCourte('528i  (4 cyl.)'), '528i');
    });

    test('une parenthèse collée au nom n\'est PAS coupée', () {
      // La coupure exige « espace puis parenthèse ». Sans cette exigence, une
      // désignation qui porterait une parenthèse collée serait amputée de ce
      // qui la nomme, et on perdrait plus d'information qu'on n'en gagne.
      expect(finitionCourte('528i(4cyl)'), '528i(4cyl)');
    });

    test('un nom qui commence par une parenthèse reste entier', () {
      // Le cas qui rendrait une carte VIDE si la fonction coupait à l'index 0.
      // Mieux vaut un libellé bizarre qu'une finition disparue.
      expect(finitionCourte('(spécial) édition'), '(spécial) édition');
    });
  });
}
