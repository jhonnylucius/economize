class ItemTemplate {
  final int? id;
  final String name;
  final String category;
  final String subcategory;
  final List<String> availableUnits;
  final String defaultUnit;

  const ItemTemplate({
    this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.availableUnits,
    required this.defaultUnit,
  });

  factory ItemTemplate.fromMap(Map<String, dynamic> map) {
    return ItemTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      subcategory: map['subcategory'] as String,
      availableUnits: ['un', 'kg', 'L'], // Ajuste temporário
      defaultUnit: map['defaultUnit'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'availableUnits': availableUnits.join(','),
      'defaultUnit': defaultUnit,
    };
  }

  // Método para criar uma cópia com alterações
  ItemTemplate copyWith({
    int? id,
    String? name,
    String? category,
    String? subcategory,
    List<String>? availableUnits,
    String? defaultUnit,
  }) {
    return ItemTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      availableUnits: availableUnits ?? this.availableUnits,
      defaultUnit: defaultUnit ?? this.defaultUnit,
    );
  }
}
