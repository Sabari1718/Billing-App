class CategoryGroup {
  final int id;
  final String name;

  CategoryGroup({
    required this.id,
    required this.name,
  });

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    return CategoryGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}