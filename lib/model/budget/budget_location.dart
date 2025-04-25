class BudgetLocation {
  final String id;
  final String name;
  final String address;
  final DateTime priceDate;
  final String budgetId; // Adicionado para referência ao orçamento

  const BudgetLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.priceDate,
    required this.budgetId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_id': budgetId,
      'name': name,
      'address': address,
      'price_date':
          priceDate.millisecondsSinceEpoch, // Corrigido: usar milliseconds
    };
  }

  factory BudgetLocation.fromMap(Map<String, dynamic> map) {
    return BudgetLocation(
      id: map['id'] as String,
      budgetId: map['budget_id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      priceDate: DateTime.fromMillisecondsSinceEpoch(
        map['price_date'] as int,
      ), // Corrigido: ler milliseconds
    );
  }

  // Método para criar uma cópia com alterações
  BudgetLocation copyWith({
    String? id,
    String? budgetId,
    String? name,
    String? address,
    DateTime? priceDate,
  }) {
    return BudgetLocation(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      name: name ?? this.name,
      address: address ?? this.address,
      priceDate: priceDate ?? this.priceDate,
    );
  }

  @override
  String toString() {
    return 'BudgetLocation(id: $id, budgetId: $budgetId, name: $name, address: $address, priceDate: $priceDate)';
  }
}
