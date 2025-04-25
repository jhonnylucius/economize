import 'package:economize/model/budget/budget_item.dart';

class BudgetSummary {
  double totalOriginal;
  double totalOptimized;
  double savings;
  Map<String, double> totalByLocation;

  BudgetSummary({
    required this.totalOriginal,
    required this.totalOptimized,
    required this.savings,
    required this.totalByLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalOriginal': totalOriginal,
      'totalOptimized': totalOptimized,
      'savings': savings,
      'totalByLocation': totalByLocation.map((k, v) => MapEntry(k, v)),
    };
  }

  factory BudgetSummary.fromMap(Map<String, dynamic> map) {
    return BudgetSummary(
      totalOriginal: map['totalOriginal']?.toDouble() ?? 0.0,
      totalOptimized: map['totalOptimized']?.toDouble() ?? 0.0,
      savings: map['savings']?.toDouble() ?? 0.0,
      totalByLocation: Map<String, double>.from(map['totalByLocation'] ?? {}),
    );
  }

  void calculateSummary(List<BudgetItem> items) {
    totalByLocation = {};
    totalOriginal = 0.0;
    totalOptimized = 0.0;

    for (var item in items) {
      // Calcula total por localização
      item.prices.forEach((locationId, price) {
        totalByLocation[locationId] =
            (totalByLocation[locationId] ?? 0.0) + (price * item.quantity);
      });

      // Correção: Usar o maior preço como preço original
      if (item.prices.isNotEmpty) {
        double originalPrice = item.prices.values.reduce(
          (max, price) => price > max ? price : max,
        );
        totalOriginal += originalPrice * item.quantity;
      }

      // Usa o melhor preço para o total otimizado
      if (item.bestPrice > 0) {
        totalOptimized += item.bestPrice * item.quantity;
      }
    }

    // Calcula a economia
    savings = totalOriginal - totalOptimized;
  }

  // Método para calcular percentual de economia
  double getSavingsPercentage() {
    if (totalOriginal == 0) return 0;
    return (savings / totalOriginal) * 100;
  }

  // Método para obter local mais econômico
  String? getMostEconomicalLocation() {
    if (totalByLocation.isEmpty) return null;

    var minEntry = totalByLocation.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    return minEntry.key;
  }

  // Método para obter local mais caro
  String? getMostExpensiveLocation() {
    if (totalByLocation.isEmpty) return null;

    var maxEntry = totalByLocation.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }
}
