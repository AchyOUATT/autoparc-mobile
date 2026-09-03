class Manufacturer {
  final int id;
  final String name;

  const Manufacturer({required this.id, required this.name});

  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
    id:   json['id']   as int,
    name: json['name'] as String,
  );

  @override
  String toString() => name;
}
