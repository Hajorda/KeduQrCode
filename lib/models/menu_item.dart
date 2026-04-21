/// A single dish in a daily cafeteria menu.
class MenuItem {
  final String name;

  /// Broad category: 'Çorba', 'Ana Yemek', 'Garnitür', 'Tatlı', etc.
  final String category;

  const MenuItem({required this.name, required this.category});

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Diğer',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
      };

  @override
  String toString() => '$category: $name';
}
