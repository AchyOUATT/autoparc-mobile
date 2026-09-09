class PartCategory {
  final int id;
  final String name;

  /// Catégorie parente, `null` pour les 9 racines.
  ///
  /// L'arbre compte trois niveaux et 89 entrées : sans ce champ, impossible de
  /// ne proposer que le premier niveau dans les filtres.
  final int? parentId;

  const PartCategory({required this.id, required this.name, this.parentId});

  /// Vrai pour une catégorie de premier niveau.
  bool get isRoot => parentId == null;

  factory PartCategory.fromJson(Map<String, dynamic> json) => PartCategory(
    id:       json['id']   as int,
    name:     json['name'] as String,
    parentId: json['parent_id'] as int?,
  );

  @override
  String toString() => name;
}
