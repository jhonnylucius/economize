import 'package:economize/data/price_history_dao.dart';
import 'package:economize/model/budget/price_history.dart';
import 'package:logger/logger.dart';

class PriceHistoryService {
  final PriceHistoryDAO _priceHistoryDAO = PriceHistoryDAO();

  // Configurações
  static const double defaultThreshold = 5.0; // Variação mínima em %
  static const int defaultHistoryDays = 30; // Período padrão de análise

  // Registrar novo preço
  Future<void> registerPrice(PriceHistory priceHistory) async {
    try {
      // Busca último preço para calcular variação
      final lastPrice = await _priceHistoryDAO.getLastPrice(
        priceHistory.itemId,
        priceHistory.locationId,
      );

      // Cria registro com variação calculada
      final historyWithVariation = PriceHistory.withCalculatedVariation(
        id: priceHistory.id,
        itemId: priceHistory.itemId,
        locationId: priceHistory.locationId,
        price: priceHistory.price,
        date: priceHistory.date,
        lastPrice: lastPrice?.price,
      );

      await _priceHistoryDAO.insert(historyWithVariation);
    } catch (e) {
      throw Exception('Erro ao registrar preço: $e');
    }
  }

  // Buscar histórico de preços de um item
  Future<List<PriceHistory>> getItemPriceHistory(String itemId) async {
    try {
      return await _priceHistoryDAO.findByItem(itemId);
    } catch (e) {
      throw Exception('Erro ao buscar histórico: $e');
    }
  }

  // Calcular variação de preço
  Future<double> calculatePriceVariation(
    String itemId,
    String locationId,
    double newPrice,
  ) async {
    try {
      final lastPrice = await _priceHistoryDAO.getLastPrice(itemId, locationId);
      if (lastPrice == null || lastPrice.price == 0) return 0;

      final variation = ((newPrice - lastPrice.price) / lastPrice.price) * 100;

      Logger().e('DEBUG - Cálculo de variação:');
      Logger().e('Preço anterior: ${lastPrice.price}');
      Logger().e('Novo preço: $newPrice');
      Logger().e('Variação: $variation%');

      return variation;
    } catch (e) {
      Logger().e('Erro ao calcular variação: $e');
      return 0;
    }
  }

  // Buscar itens com variação significativa
  Future<List<PriceHistory>> getSignificantVariations({
    double threshold = defaultThreshold,
    int days = defaultHistoryDays,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final List<PriceHistory> significantVariations = [];
      final locations = await _priceHistoryDAO.getDistinctLocations();

      for (var locationId in locations) {
        final items = await _priceHistoryDAO.getDistinctItemsByLocation(
          locationId,
        );

        for (var itemId in items) {
          final variation = await _priceHistoryDAO.calculatePriceVariation(
            itemId,
            locationId,
            startDate,
            endDate,
          );

          if (variation.abs() >= threshold) {
            final lastPrice = await _priceHistoryDAO.getLastPrice(
              itemId,
              locationId,
            );
            if (lastPrice != null) {
              significantVariations.add(lastPrice);
            }
          }
        }
      }

      return significantVariations;
    } catch (e) {
      throw Exception('Erro ao buscar variações significativas: $e');
    }
  }

  // Limpar histórico antigo
  Future<void> cleanOldHistory(int daysToKeep) async {
    try {
      await _priceHistoryDAO.cleanOldHistory(daysToKeep);
    } catch (e) {
      throw Exception('Erro ao limpar histórico antigo: $e');
    }
  }

  // Obter estatísticas de variação
  Future<Map<String, dynamic>> getPriceStatistics(
    String itemId,
    String locationId,
    int days,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final history = await _priceHistoryDAO.findByItemAndLocation(
        itemId,
        locationId,
      );

      if (history.isEmpty) {
        return {
          'avgPrice': 0.0,
          'minPrice': 0.0,
          'maxPrice': 0.0,
          'totalVariation': 0.0,
        };
      }

      final prices = history.map((h) => h.price).toList();
      final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);
      final totalVariation = await _priceHistoryDAO.calculatePriceVariation(
        itemId,
        locationId,
        startDate,
        endDate,
      );

      return {
        'avgPrice': avgPrice,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'totalVariation': totalVariation,
      };
    } catch (e) {
      throw Exception('Erro ao obter estatísticas: $e');
    }
  }
}
