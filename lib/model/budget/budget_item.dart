import 'package:economize/utils/budget_utils.dart';

class BudgetItem {
  final String id;
  final String budgetId; // Adicionado para referência ao orçamento
  final String name;
  final String category;
  String unit;
  double quantity;
  Map<String, double> prices;
  String bestPriceLocation;
  double bestPrice;

  BudgetItem({
    required this.id,
    required this.budgetId,
    required this.name,
    required this.category,
    this.unit = 'un',
    this.quantity = 1,
    required this.prices,
    required this.bestPriceLocation,
    required this.bestPrice,
  });

  BudgetItem copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? quantity,
    Map<String, double>? prices,
    String? bestPriceLocation,
    double? bestPrice,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      prices: prices ?? Map<String, double>.from(this.prices),
      bestPriceLocation: bestPriceLocation ?? this.bestPriceLocation,
      bestPrice: bestPrice ?? this.bestPrice,
      budgetId: budgetId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_id': budgetId,
      'name': name,
      'category': category,
      'unit': unit,
      'quantity': quantity,
      'best_price_location': bestPriceLocation,
      'best_price': bestPrice,
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      id: map['id'] as String,
      budgetId: map['budget_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      unit: map['unit'] as String? ?? 'un',
      quantity: map['quantity'] as double? ?? 1.0,
      prices: Map<String, double>.from(map['prices'] ?? {}),
      bestPriceLocation: map['best_price_location'] as String? ?? '',
      bestPrice: map['best_price'] as double? ?? 0.0,
    );
  }
  void updateBestPrice() {
    if (prices.isEmpty) {
      bestPrice = 0.0;
      bestPriceLocation = '';
      return;
    }

    var lowestPrice = double.infinity;
    var lowestPriceLocation = '';

    prices.forEach((location, price) {
      if (price < lowestPrice) {
        lowestPrice = price;
        lowestPriceLocation = location;
      }
    });

    bestPrice = lowestPrice;
    bestPriceLocation = lowestPriceLocation;
  }

  // Converte o preço para uma nova unidade
  void convertToUnit(String newUnit, {double? density}) {
    if (newUnit == unit) return;

    // Converter preços
    final newPrices = <String, double>{};
    prices.forEach((location, price) {
      final convertedPrice = BudgetUtils.convertUnit(
        price,
        unit,
        newUnit,
        density: density,
      );
      newPrices[location] = convertedPrice;
    });

    // Atualizar preços e unidade
    prices = newPrices;
    unit = newUnit;
    updateBestPrice();
  }

  // Calcula o preço por unidade base (kg, L ou unidade)
  double getPricePerUnit({String? targetUnit}) {
    if (quantity == 0) return 0;
    final baseUnit = targetUnit ?? unit;

    return BudgetUtils.calculatePricePerUnit(
      bestPrice,
      quantity,
      unit,
      targetUnit: baseUnit,
    );
  }

  // Compara preços entre diferentes apresentações do mesmo produto
  Map<String, dynamic> compareUnitPrices() {
    // Preparar os mapas necessários para o comparePrices
    final priceMap = Map<String, double>.from(prices);
    final unitMap = Map<String, String>.fromIterables(
      prices.keys,
      List.filled(prices.length, unit),
    );
    final quantityMap = Map<String, double>.fromIterables(
      prices.keys,
      List.filled(prices.length, quantity),
    );

    return BudgetUtils.comparePrices(priceMap, unitMap, quantityMap);
  }

  // Calcula a economia em relação ao preço mais alto
  double calculateSavings() {
    if (prices.isEmpty) return 0;

    final highestPrice = prices.values.reduce((a, b) => a > b ? a : b);
    return highestPrice - bestPrice;
  }

  // Calcula o percentual de economia
  double calculateSavingsPercentage() {
    if (prices.isEmpty || bestPrice == 0) return 0;

    final highestPrice = prices.values.reduce((a, b) => a > b ? a : b);
    return ((highestPrice - bestPrice) / highestPrice) * 100;
  }
}
