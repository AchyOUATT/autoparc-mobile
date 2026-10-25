import 'package:auto/features/partner_accounts/data/lecture_json.dart' as json;
import 'package:flutter_test/flutter_test.dart';

/// Le lecteur tolérant de l'espace partenaire.
///
/// Il existe parce que les écrans partenaire lisaient leurs champs en casts
/// nus, et qu'un `TypeError` levé dans un `build()` donne un écran rouge que
/// `messageFor()` ne rattrape pas. Ces tests fixent le comportement attendu
/// forme par forme — c'est la variété des formes que PHP produit qui fait tout
/// l'intérêt du fichier, et une seule oubliée suffit à ramener la panne.
void main() {
  group('entier', () {
    test('lit un entier, un flottant et les deux écritures en texte', () {
      expect(json.entier(12), 12);
      expect(json.entier(12.0), 12);
      expect(json.entier('12'), 12);
      // `int.tryParse` refuse « 12.0 », que PHP produit dès qu'une valeur a
      // croisé un cast flottant. C'est exactement la forme qui avait fait
      // tomber le catalogue entier.
      expect(json.entier('12.0'), 12);
      expect(json.entier(' 12 '), 12);
    });

    test('rend null sur ce qui n\'est pas un nombre', () {
      expect(json.entier(null), isNull);
      expect(json.entier(''), isNull);
      expect(json.entier('   '), isNull);
      expect(json.entier('abc'), isNull);
      expect(json.entier(['12']), isNull);
      expect(json.entier({'id': 12}), isNull);
    });

    test('un négatif et un zéro restent lisibles', () {
      // `?? 0` chez l'appelant confondrait zéro et illisible : le lecteur doit
      // distinguer les deux.
      expect(json.entier(0), 0);
      expect(json.entier('0'), 0);
      expect(json.entier(-3), -3);
    });
  });

  group('texte', () {
    test('une chaîne vide ou blanche vaut une chaîne absente', () {
      // Le serveur rend `""` quand un champ facultatif n'a pas été renseigné.
      // Afficher une ligne blanche vaudrait moins que le repli de l'appelant.
      expect(json.texte(''), isNull);
      expect(json.texte('   '), isNull);
      expect(json.texte(null), isNull);
    });

    test('rend le texte élagué, et sait lire un nombre', () {
      expect(json.texte('  Garage Kossodo  '), 'Garage Kossodo');
      expect(json.texte(12), '12');
      expect(json.texte(true), 'true');
    });
  });

  group('listeDeMaps', () {
    test('rend une liste vide sur ce qui n\'est pas une liste', () {
      for (final valeur in [null, 'texte', 12, {'data': []}]) {
        expect(json.listeDeMaps(valeur), isEmpty, reason: 'pour $valeur');
      }
    });

    test('écarte les éléments qui ne sont pas des maps, un par un', () {
      // Mieux vaut une candidature manquante qu'un écran rouge.
      final lu = json.listeDeMaps(['pas une map', {'id': 1}, 42, {'id': 2}]);

      expect(lu.map((e) => e['id']), [1, 2]);
    });

    test('convertit une map faiblement typée en Map<String, dynamic>', () {
      // Dio rend des `Map<dynamic, dynamic>` selon le chemin de décodage ;
      // `Map<String, dynamic>.from` est ce qui évite un cast plus loin.
      final lu = json.listeDeMaps([<dynamic, dynamic>{'id': 1}]);

      expect(lu.single, isA<Map<String, dynamic>>());
      expect(lu.single['id'], 1);
    });
  });

  group('map', () {
    test('rend une map vide plutôt qu\'une exception', () {
      expect(json.map(null), isEmpty);
      expect(json.map('texte'), isEmpty);
      expect(json.map([1, 2]), isEmpty);
    });

    test('lit une map et la retype', () {
      final lu = json.map(<dynamic, dynamic>{'email': 'a@b.test'});

      expect(lu['email'], 'a@b.test');
    });
  });
}
