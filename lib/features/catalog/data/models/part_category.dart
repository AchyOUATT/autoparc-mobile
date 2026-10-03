class PartCategory {
  final int id;
  final String name;

  /// Catégorie parente, `null` pour les 9 racines.
  ///
  /// L'arbre compte trois niveaux et 89 entrées : sans ce champ, impossible de
  /// ne proposer que le premier niveau dans les filtres.
  final int? parentId;

  /// La catégorie porte elle-même des pièces, plutôt que de seulement mener à
  /// ses descendantes.
  ///
  /// Renseigné uniquement par l'arbre élagué (`?non_empty=1`). L'arbre complet
  /// ne le transmet pas et la valeur reste `false` : c'est sans conséquence,
  /// seul le choix du niveau de pastilles s'en sert, et il ne travaille que sur
  /// l'arbre élagué.
  final bool hasOwnParts;

  const PartCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.hasOwnParts = false,
  });

  /// Vrai pour une catégorie de premier niveau.
  bool get isRoot => parentId == null;

  factory PartCategory.fromJson(Map<String, dynamic> json) => PartCategory(
    id:          json['id']   as int,
    name:        json['name'] as String,
    parentId:    json['parent_id'] as int?,
    hasOwnParts: json['has_own_parts'] as bool? ?? false,
  );

  @override
  String toString() => name;
}
