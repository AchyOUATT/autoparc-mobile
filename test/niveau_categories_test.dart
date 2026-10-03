import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/presentation/widgets/niveau_categories.dart';

/// Quelles catégories méritent une pastille de filtre.
///
/// La barre proposait les 9 racines de l'arbre, en dur. L'arbre compte 89
/// catégories et le catalogue n'en occupe qu'une branche — Moteur → Filtres →
/// Filtre à huile : huit pastilles sur neuf ne renvoyaient rien, et un filtre
/// qui ne renvoie rien se lit comme une panne.
///
/// Élaguer l'arbre côté serveur ne suffisait pas. Il resterait « Moteur »,
/// pastille unique couvrant tout le catalogue : un filtre qui ne divise rien
/// n'est pas un filtre. C'est pourquoi `niveauDiscriminant` descend, et rend
/// une liste vide plutôt qu'une pastille inutile.
///
/// Deux arrêts protègent cette descente, et ce sont eux qui comptent le plus
/// ici : on ne descend pas sous une catégorie qui porte ses propres pièces —
/// aucune pastille de niveau inférieur ne les couvrirait — ni sous une
/// feuille.
void main() {
  PartCategory cat(int id, String nom, {int? parent, bool propres = false}) =>
      PartCategory(id: id, name: nom, parentId: parent, hasOwnParts: propres);

  List<String> nomsDe(List<PartCategory> arbre) =>
      niveauDiscriminant(arbre).map((c) => c.name).toList();

  // ── Le cas du catalogue actuel ───────────────────────────────────────────

  /// Le test qui justifie toute cette fonction.
  ///
  /// Dix filtres à huile dans une seule feuille. Aucun niveau de l'arbre ne
  /// partage le catalogue : chaque niveau n'a qu'un nœud, qui couvre les dix
  /// références. Aucune pastille n'a de sens, et la barre doit disparaître.
  test('une seule branche peuplée ne mérite aucune pastille', () {
    final arbre = [
      cat(1, 'Moteur'),
      cat(2, 'Filtres', parent: 1),
      cat(3, 'Filtre à huile', parent: 2, propres: true),
    ];

    expect(niveauDiscriminant(arbre), isEmpty);
  });

  test('un arbre élagué vide ne rend rien', () {
    expect(niveauDiscriminant(const []), isEmpty);
  });

  // ── Deux branches : les racines suffisent ────────────────────────────────

  test('deux racines peuplées deviennent les pastilles', () {
    final arbre = [
      cat(1, 'Moteur'),
      cat(2, 'Filtres', parent: 1),
      cat(3, 'Filtre à huile', parent: 2, propres: true),
      cat(24, 'Freinage'),
      cat(25, 'Disques', parent: 24),
      cat(26, 'Plaquettes avant', parent: 25, propres: true),
    ];

    expect(nomsDe(arbre), ['Moteur', 'Freinage']);
  });

  // ── Une seule racine : on descend chercher le niveau utile ───────────────

  /// C'est l'apport réel de la descente : une racine unique ne trie rien, mais
  /// ses trois sous-catégories, si.
  test('une racine unique cède la place à ses descendantes', () {
    final arbre = [
      cat(1, 'Moteur'),
      cat(2, 'Filtres', parent: 1, propres: true),
      cat(4, 'Allumage', parent: 1, propres: true),
      cat(5, 'Refroidissement', parent: 1, propres: true),
    ];

    expect(nomsDe(arbre), ['Filtres', 'Allumage', 'Refroidissement']);
  });

  test('la descente traverse autant de niveaux que nécessaire', () {
    final arbre = [
      cat(1, 'Moteur'),
      cat(2, 'Filtres', parent: 1),
      cat(3, 'Filtre à huile', parent: 2, propres: true),
      cat(6, 'Filtre à air', parent: 2, propres: true),
    ];

    // Niveau 1 : {Moteur} — ne trie rien. Niveau 2 : {Filtres} — ne trie rien
    // non plus. Niveau 3 : deux feuilles qui se partagent le catalogue.
    expect(nomsDe(arbre), ['Filtre à huile', 'Filtre à air']);
  });

  // ── Les deux arrêts de la descente ───────────────────────────────────────

  /// Sans cet arrêt, les pièces rangées directement sous « Moteur »
  /// deviendraient injoignables : aucune pastille de niveau inférieur ne les
  /// couvre, et le filtre serveur ne remonte pas vers le parent.
  test('on ne descend pas sous une catégorie qui porte ses propres pièces', () {
    final arbre = [
      cat(1, 'Moteur', propres: true),
      cat(2, 'Filtres', parent: 1, propres: true),
      cat(4, 'Allumage', parent: 1, propres: true),
    ];

    expect(
      niveauDiscriminant(arbre),
      isEmpty,
      reason: 'Descendre perdrait les pièces rangées directement sous Moteur.',
    );
  });

  test('on ne descend pas sous une feuille', () {
    final arbre = [cat(3, 'Filtre à huile', propres: true)];

    expect(niveauDiscriminant(arbre), isEmpty);
  });

  // ── Le drapeau absent de l'arbre complet ─────────────────────────────────

  /// L'arbre complet ne transmet pas `has_own_parts` ; la valeur retombe à
  /// `false`. La descente ne doit pas s'en trouver bloquée, sinon une racine
  /// unique resterait seule pastille — exactement le défaut corrigé.
  test('le drapeau absent de la réponse vaut faux', () {
    final sansDrapeau = PartCategory.fromJson({
      'id': 1,
      'name': 'Moteur',
      'parent_id': null,
    });

    expect(sansDrapeau.hasOwnParts, isFalse);

    final avecDrapeau = PartCategory.fromJson({
      'id': 3,
      'name': 'Filtre à huile',
      'parent_id': 2,
      'has_own_parts': true,
    });

    expect(avecDrapeau.hasOwnParts, isTrue);
  });

  // ── Ce que la fonction ne doit pas faire ─────────────────────────────────

  test('les pastilles sortent toutes du même niveau', () {
    // Moteur mène à une feuille peuplée, Freinage en porte deux. Les pastilles
    // doivent rester les deux racines : mélanger « Moteur » et « Plaquettes
    // avant » proposerait deux granularités dans la même rangée, et deux
    // pastilles dont l'une est contenue dans l'autre.
    final arbre = [
      cat(1, 'Moteur'),
      cat(3, 'Filtre à huile', parent: 1, propres: true),
      cat(24, 'Freinage'),
      cat(26, 'Plaquettes avant', parent: 24, propres: true),
      cat(27, 'Disques avant', parent: 24, propres: true),
    ];

    final noms = nomsDe(arbre);

    expect(noms, ['Moteur', 'Freinage']);
    expect(noms, isNot(contains('Plaquettes avant')));
  });
}
