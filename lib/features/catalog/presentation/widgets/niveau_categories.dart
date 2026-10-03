import '../../data/models/part_category.dart';

/// Le niveau de l'arbre des catégories qui sépare vraiment le catalogue.
///
/// La barre de filtres proposait les 9 racines, en dur. C'était juste pour un
/// catalogue garni, et trompeur pour celui-ci : l'arbre compte 89 catégories,
/// et une seule branche est occupée — Moteur → Filtres → Filtre à huile. Huit
/// pastilles sur neuf ne renvoyaient rien.
///
/// Élaguer l'arbre ne suffit pas. Il resterait « Moteur », seule pastille, qui
/// couvre tout le catalogue : un filtre qui ne divise rien n'est pas un filtre,
/// c'est un bouton qui a l'air cassé. D'où la règle appliquée ici.
///
/// On part des racines et l'on descend tant qu'un seul nœud subsiste au niveau
/// courant — puisqu'il couvre alors tout ce qui est affiché. On s'arrête dès
/// que deux nœuds au moins coexistent : ceux-là partagent le catalogue, et ce
/// sont eux qui deviennent les pastilles.
///
/// Deux arrêts protègent de la descente :
///
/// `hasOwnParts` — on ne descend pas sous une catégorie qui porte ses propres
/// pièces. Aucune pastille de niveau inférieur ne les couvrirait, et elles
/// deviendraient injoignables.
///
/// L'absence de descendante — on ne descend pas sous une feuille.
///
/// Et si la descente s'achève sur un nœud unique, il n'y a aucune pastille à
/// proposer : c'est le cas du catalogue actuel, dix filtres à huile dans une
/// seule catégorie. Mieux vaut pas de barre qu'une barre qui ne trie rien.
List<PartCategory> niveauDiscriminant(List<PartCategory> arbreElague) {
  List<PartCategory> enfantsDe(int id) =>
      arbreElague.where((c) => c.parentId == id).toList();

  var niveau = arbreElague.where((c) => c.isRoot).toList();

  while (niveau.length == 1 && !niveau.single.hasOwnParts) {
    final descendantes = enfantsDe(niveau.single.id);
    if (descendantes.isEmpty) break;
    niveau = descendantes;
  }

  return niveau.length >= 2 ? niveau : const <PartCategory>[];
}
