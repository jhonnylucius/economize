import 'dart:math';

import 'package:economize/data/default_items.dart';
import 'package:economize/model/budget/budget.dart';

class BudgetUtils {
  // Constantes para conversão
  static const Map<String, double> _conversionFactors = {
    'g_to_kg': 0.001,
    'kg_to_g': 1000,
    'ml_to_L': 0.001,
    'L_to_ml': 1000,
  };

  // Densidades comuns de produtos (g/ml)
  static const Map<String, double> productDensities = {
    'leite': 1.03,
    'agua': 1.0,
    'oleo': 0.92,
    'mel': 1.4,
    'detergente': 1.05,
    'alcool': 0.79,
  };

  // Filtrar itens por categoria com pesquisa mais inteligente
  static List<Map<String, dynamic>> filterByCategory(String category) {
    final categoryLower = category.toLowerCase().trim();
    return defaultItems.where((item) {
      final itemCategory = (item['category'] as String?)?.toLowerCase() ?? '';
      final itemSubcategory =
          (item['subcategory'] as String?)?.toLowerCase() ?? '';

      return itemCategory == categoryLower ||
          itemSubcategory == categoryLower ||
          itemCategory.contains(categoryLower) ||
          itemSubcategory.contains(categoryLower);
    }).toList();
  }

  // Busca aprimorada de produtos
  static List<Map<String, dynamic>> searchProducts(String query) {
    if (query.isEmpty) return [];

    final terms = query.toLowerCase().split(' ');
    return defaultItems.where((item) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      final category = item['category']?.toString().toLowerCase() ?? '';
      final subcategory = item['subcategory']?.toString().toLowerCase() ?? '';

      return terms.every(
        (term) =>
            name.contains(term) ||
            category.contains(term) ||
            subcategory.contains(term),
      );
    }).toList();
  }

  // Conversão entre unidades melhorada
  static double convertUnit(
    double value,
    String fromUnit,
    String toUnit, {
    double? density,
    String? productType,
  }) {
    // Se as unidades são iguais, retorna o valor original
    if (fromUnit == toUnit) return value;

    // Tenta usar densidade do produto se disponível
    final effectiveDensity =
        density ?? (productType != null ? productDensities[productType] : null);

    // Conversões diretas
    final conversionKey = '${fromUnit}_to_$toUnit';
    if (_conversionFactors.containsKey(conversionKey)) {
      return value * _conversionFactors[conversionKey]!;
    }

    // Conversões peso-volume
    if (effectiveDensity != null) {
      if (_isVolume(fromUnit) && _isWeight(toUnit)) {
        final ml = _convertToMl(value, fromUnit);
        final g = ml * effectiveDensity;
        return _convertFromG(g, toUnit);
      }

      if (_isWeight(fromUnit) && _isVolume(toUnit)) {
        final g = _convertToG(value, fromUnit);
        final ml = g / effectiveDensity;
        return _convertFromMl(ml, toUnit);
      }
    }

    return value;
  }

  // Métodos auxiliares para conversão
  static bool _isVolume(String unit) => ['ml', 'L'].contains(unit);
  static bool _isWeight(String unit) => ['g', 'kg'].contains(unit);

  static double _convertToMl(double value, String fromUnit) =>
      fromUnit == 'L' ? value * _conversionFactors['L_to_ml']! : value;

  static double _convertToG(double value, String fromUnit) =>
      fromUnit == 'kg' ? value * _conversionFactors['kg_to_g']! : value;

  static double _convertFromMl(double ml, String toUnit) =>
      toUnit == 'L' ? ml * _conversionFactors['ml_to_L']! : ml;

  static double _convertFromG(double g, String toUnit) =>
      toUnit == 'kg' ? g * _conversionFactors['g_to_kg']! : g;

  // Análise de economia melhorada
  static Map<String, dynamic> analyzeBudgetSavings(Budget budget) {
    final locationTotals = calculateTotalsByLocation(budget);
    if (locationTotals.isEmpty) return {};

    final highestTotal = locationTotals.values.reduce(max);
    final lowestTotal = locationTotals.values.reduce(min);
    final totalSaving = highestTotal - lowestTotal;
    final savingPercentage = (totalSaving / highestTotal) * 100;

    final bestLocationId = findBestOverallLocation(budget);
    final savingsByLocation = calculateSavingsByLocation(budget);
    final savingsPercentage = calculateSavingsPercentageByLocation(budget);

    return {
      'totalSaving': totalSaving,
      'savingPercentage': savingPercentage,
      'bestLocation': bestLocationId,
      'locationSavings': savingsByLocation,
      'locationSavingsPercentage': savingsPercentage,
      'recommendations': _generateRecommendations(budget),
    };
  }

  // Gerar recomendações de compra
  static List<Map<String, dynamic>> _generateRecommendations(Budget budget) {
    final recommendations = <Map<String, dynamic>>[];

    for (var item in budget.items) {
      final prices = item.prices.entries.toList();
      if (prices.length < 2) continue;

      prices.sort((a, b) => a.value.compareTo(b.value));
      final saving = prices.last.value - prices.first.value;
      final savingPercentage = (saving / prices.last.value) * 100;

      if (savingPercentage >= 10) {
        // 10% ou mais de economia
        recommendations.add({
          'item': item.name,
          'bestPrice': prices.first.value,
          'bestLocation': prices.first.key,
          'saving': saving,
          'savingPercentage': savingPercentage,
        });
      }
    }

    recommendations.sort(
      (a, b) => (b['savingPercentage'] as double).compareTo(
        a['savingPercentage'] as double,
      ),
    );

    return recommendations;
  }

  // Calcular comparação de preços por unidade
  static Map<String, dynamic> calculatePriceComparison(
    Map<String, double> prices,
    double quantity,
    String unit,
  ) {
    if (prices.isEmpty) {
      return {
        'bestDeal': null,
        'pricePerUnit': 0.0,
        'potentialSaving': 0.0,
        'savingPercentage': 0.0,
      };
    }

    // Normaliza preços por unidade
    final normalizedPrices =
        prices.entries.map((entry) {
          final pricePerUnit = entry.value / quantity;
          return {
            'locationId': entry.key,
            'original': entry.value,
            'pricePerUnit': pricePerUnit,
          };
        }).toList();

    // Ordena por preço por unidade
    normalizedPrices.sort(
      (a, b) =>
          (a['pricePerUnit'] as double).compareTo(b['pricePerUnit'] as double),
    );

    // Retorna o melhor preço e a economia em relação ao pior
    final cheapest = normalizedPrices.first;
    final mostExpensive = normalizedPrices.last;
    final saving =
        (mostExpensive['pricePerUnit'] as double) -
        (cheapest['pricePerUnit'] as double);

    return {
      'bestDeal': cheapest['original'],
      'pricePerUnit': cheapest['pricePerUnit'],
      'potentialSaving': saving,
      'savingPercentage':
          (saving / (mostExpensive['pricePerUnit'] as double)) * 100,
    };
  }

  static Map<String, double> calculateTotalsByLocation(Budget budget) {
    final totals = <String, double>{};

    for (var location in budget.locations) {
      var locationTotal = 0.0;
      for (var item in budget.items) {
        final price = item.prices[location.id] ?? 0;
        locationTotal += price * item.quantity;
      }
      totals[location.id] = locationTotal;
    }

    return totals;
  }

  // Calcular melhor localização geral
  static String? findBestOverallLocation(Budget budget) {
    final totals = calculateTotalsByLocation(budget);
    if (totals.isEmpty) return null;

    var bestLocationId = totals.entries.first.key;
    var lowestTotal = totals.entries.first.value;

    for (var entry in totals.entries) {
      if (entry.value < lowestTotal) {
        lowestTotal = entry.value;
        bestLocationId = entry.key;
      }
    }

    return bestLocationId;
  }

  // Calcular economia por localização
  static Map<String, double> calculateSavingsByLocation(Budget budget) {
    final totals = calculateTotalsByLocation(budget);
    final savings = <String, double>{};

    if (totals.isEmpty) return savings;

    final highestTotal = totals.values.reduce(max);

    for (var entry in totals.entries) {
      savings[entry.key] = highestTotal - entry.value;
    }

    return savings;
  }

  // Calcular percentual de economia por localização
  static Map<String, double> calculateSavingsPercentageByLocation(
    Budget budget,
  ) {
    final totals = calculateTotalsByLocation(budget);
    final percentages = <String, double>{};

    if (totals.isEmpty) return percentages;

    final highestTotal = totals.values.reduce(max);

    for (var entry in totals.entries) {
      final saving = highestTotal - entry.value;
      percentages[entry.key] = (saving / highestTotal) * 100;
    }

    return percentages;
  }

  static double calculatePricePerUnit(
    double price,
    double quantity,
    String unit, {
    String? targetUnit,
  }) {
    if (quantity <= 0) return 0;

    // Se não houver unidade alvo, retorna preço por unidade atual
    if (targetUnit == null || unit == targetUnit) {
      return price / quantity;
    }

    // Converte para unidade alvo antes de calcular
    final convertedPrice = convertUnit(price, unit, targetUnit);
    return convertedPrice / quantity;
  }

  // Compara preços entre diferentes unidades
  static Map<String, dynamic> comparePrices(
    Map<String, double> prices,
    Map<String, String> units,
    Map<String, double> quantities, {
    String? targetUnit,
  }) {
    if (prices.isEmpty) {
      return {
        'bestPrice': 0.0,
        'bestLocation': '',
        'pricesPerUnit': <String, double>{},
        'savings': 0.0,
        'savingsPercentage': 0.0,
      };
    }

    // Calcula preço por unidade para cada local
    final pricesPerUnit = <String, double>{};

    prices.forEach((location, price) {
      final unit = units[location] ?? 'un';
      final quantity = quantities[location] ?? 1.0;

      pricesPerUnit[location] = calculatePricePerUnit(
        price,
        quantity,
        unit,
        targetUnit: targetUnit,
      );
    });

    // Encontra melhor e pior preço
    var bestLocation = pricesPerUnit.entries.first.key;
    var bestPrice = pricesPerUnit.entries.first.value;
    var worstPrice = bestPrice;

    for (var entry in pricesPerUnit.entries) {
      if (entry.value < bestPrice) {
        bestPrice = entry.value;
        bestLocation = entry.key;
      }
      if (entry.value > worstPrice) {
        worstPrice = entry.value;
      }
    }

    // Calcula economia
    final savings = worstPrice - bestPrice;
    final savingsPercentage = worstPrice > 0 ? (savings / worstPrice) * 100 : 0;

    return {
      'bestPrice': bestPrice,
      'bestLocation': bestLocation,
      'pricesPerUnit': pricesPerUnit,
      'savings': savings,
      'savingsPercentage': savingsPercentage,
    };
  }
}
