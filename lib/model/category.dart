class Category {
  final String _id;
  final String _name;
  final String _type; // 'receita' ou 'despesa'
  final String _icon;
  final bool _isDefault;
  bool _isEnabled;

  Category({
    required String id,
    required String name,
    required String type,
    required String icon,
    bool isDefault = false,
    bool isEnabled = true,
  })  : _id = id,
        _name = name,
        _type = type,
        _icon = icon,
        _isDefault = isDefault,
        _isEnabled = isEnabled;

  // Getters
  String get id => _id;
  String get name => _name;
  String get type => _type;
  String get icon => _icon;
  bool get isDefault => _isDefault;
  bool get isEnabled => _isEnabled;

  // Setter apenas para isEnabled pois é o único que pode mudar
  set isEnabled(bool value) {
    _isEnabled = value;
  }

  // Clone com modificações
  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    bool? isDefault,
    bool? isEnabled,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
