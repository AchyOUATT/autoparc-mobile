class PartCategory {
  final int id;
  final String name;

  const PartCategory({required this.id, required this.name});

  factory PartCategory.fromJson(Map<String, dynamic> json) => PartCategory(
    id:   json['id']   as int,
    name: json['name'] as String,
  );

  @override
  String toString() => name;
}
