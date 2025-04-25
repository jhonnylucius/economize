import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';

class BudgetCalculator {
  // Calcula totais por localização
  static Map<String, double> calculateTotalsByLocation(Budget budget) {
    final totals = <String, double>{};

    for (var location in budget.locations) {
      double locationTotal = 0;
      for (var item in budget.items) {
        final price = item.prices[location.id] ?? 0;
        final total = price * item.quantity;
        locationTotal += total;
      }
      totals[location.id] = locationTotal;
    }

    return totals;
  }

  // Agrupa itens por melhor preço em cada local
  static Map<String, List<BudgetItem>> getBestPricesByLocation(Budget budget) {
    final bestPrices = <String, List<BudgetItem>>{};

    // Inicializa lista para cada localização
    for (var location in budget.locations) {
      bestPrices[location.id] = [];
    }

    for (var item in budget.items) {
      if (item.bestPriceLocation.isNotEmpty) {
        bestPrices[item.bestPriceLocation]?.add(item);
      }
    }

    // Ordena itens por economia em cada local
    bestPrices.forEach((_, items) {
      items.sort((a, b) {
        final aSavings = _calculateItemSavings(a);
        final bSavings = _calculateItemSavings(b);
        return bSavings.compareTo(aSavings);
      });
    });

    return bestPrices;
  }

  // Calcula economia potencial total
  static double calculatePotentialSavings(Budget budget) {
    return budget.items.fold<double>(
      0,
      (total, item) => total + _calculateItemSavings(item),
    );
  }

  // Calcula economia por categoria
  static Map<String, double> calculateSavingsByCategory(Budget budget) {
    final savings = <String, Map<String, double>>{};

    for (var item in budget.items) {
      if (!savings.containsKey(item.category)) {
        savings[item.category] = {'savings': 0, 'total': 0, 'count': 0};
      }

      final itemSavings = _calculateItemSavings(item);
      final categoryStats = savings[item.category]!;

      categoryStats['savings'] = (categoryStats['savings'] ?? 0) + itemSavings;
      categoryStats['total'] = (categoryStats['total'] ?? 0) + item.bestPrice;
      categoryStats['count'] = (categoryStats['count'] ?? 0) + 1;
    }

    return savings.map((category, stats) {
      return MapEntry(category, stats['savings'] ?? 0);
    });
  }

  // Calcula estatísticas detalhadas por categoria
  static Map<String, Map<String, dynamic>> calculateCategoryStatistics(
    Budget budget,
  ) {
    final stats = <String, Map<String, dynamic>>{};

    for (var item in budget.items) {
      if (!stats.containsKey(item.category)) {
        stats[item.category] = {
          'totalSavings': 0.0,
          'itemCount': 0,
          'averageSaving': 0.0,
          'bestItems': <BudgetItem>[],
          'totalValue': 0.0,
        };
      }

      final categoryStats = stats[item.category]!;
      final itemSavings = _calculateItemSavings(item);

      categoryStats['totalSavings'] += itemSavings;
      categoryStats['itemCount'] += 1;
      categoryStats['totalValue'] += item.bestPrice;

      final bestItems = categoryStats['bestItems'] as List<BudgetItem>;
      if (bestItems.length < 3) {
        bestItems.add(item);
        bestItems.sort(
          (a, b) =>
              _calculateItemSavings(b).compareTo(_calculateItemSavings(a)),
        );
      }
    }

    // Calcula médias
    stats.forEach((_, categoryStats) {
      categoryStats['averageSaving'] =
          categoryStats['totalSavings'] / categoryStats['itemCount'];
    });

    return stats;
  }

  // Método auxiliar para calcular economia por item
  static double _calculateItemSavings(BudgetItem item) {
    if (item.prices.isEmpty) return 0;

    final maxPrice = item.prices.values.reduce((a, b) => a > b ? a : b);
    return (maxPrice - item.bestPrice) * item.quantity;
  }

  // Calcula percentual de economia por localização
  static Map<String, double> calculateSavingsPercentageByLocation(
    Budget budget,
  ) {
    final regularTotals = calculateTotalsByLocation(budget);
    final optimizedTotal = budget.items.fold<double>(
      0,
      (total, item) => total + (item.bestPrice * item.quantity),
    );

    return regularTotals.map((locationId, total) {
      final percentage = ((total - optimizedTotal) / total) * 100;
      return MapEntry(locationId, percentage);
    });
  }
}
