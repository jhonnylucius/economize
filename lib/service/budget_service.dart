import 'package:economize/data/budget_dao.dart';
import 'package:economize/data/budget_location_dao.dart';
import 'package:economize/data/budget_summary_dao.dart';
import 'package:economize/data/database_helper.dart';
import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:economize/model/budget/budget_location.dart';
import 'package:economize/model/budget/budget_summary.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/foundation.dart';

class BudgetService {
  final BudgetDAO _budgetDAO = BudgetDAO();

  // Removido método duplicado getAllBudgets para evitar conflito de nomes.

  Future<Budget?> getBudgetByCategory(String category) async {
    try {
      return await _budgetDAO.findByCategory(category);
    } catch (e) {
      debugPrint('Erro ao buscar orçamento por categoria: $e');
      return null;
    }
  }

  final BudgetLocationDAO _locationDAO = BudgetLocationDAO();

  Future<Budget> createBudget(String title) async {
    try {
      final budget = Budget(
        id: const Uuid().v4(),
        title: title,
        date: DateTime.now(),
        locations: [],
        items: [],
        summary: BudgetSummary(
          totalOriginal: 0,
          totalOptimized: 0,
          savings: 0,
          totalByLocation: {},
        ),
      );

      await _budgetDAO.insert(budget); // Corrigido: save -> insert
      return budget;
    } catch (e) {
      throw Exception('Erro ao criar orçamento: $e');
    }
  }

  Future<List<Budget>> getAllBudgets() async {
    try {
      return await _budgetDAO.findAll();
    } catch (e) {
      throw Exception('Erro ao buscar orçamentos: $e');
    }
  }

  Future<Budget?> getBudget(String budgetId) async {
    try {
      return await _budgetDAO.findById(budgetId);
    } catch (e) {
      throw Exception('Erro ao buscar orçamento: $e');
    }
  }

  Future<void> addLocation(String budgetId, BudgetLocation location) async {
    try {
      final budget = await getBudget(budgetId);
      if (budget == null) throw Exception('Orçamento não encontrado');

      budget.locations.add(location);
      await _budgetDAO.insert(budget); // Corrigido: save -> insert
    } catch (e) {
      throw Exception('Erro ao adicionar localização: $e');
    }
  }

  Future<void> addItem(String budgetId, BudgetItem item) async {
    try {
      final budget = await getBudget(budgetId);
      if (budget == null) throw Exception('Orçamento não encontrado');

      budget.items.add(item);
      budget.summary.calculateSummary(budget.items);
      await _budgetDAO.insert(budget); // Corrigido: save -> insert
    } catch (e) {
      throw Exception('Erro ao adicionar item: $e');
    }
  }

  Future<void> updateItemPrice(
    String budgetId,
    String itemId,
    Map<String, double> prices,
    double quantity,
    String unit,
  ) async {
    try {
      final budget = await getBudget(budgetId);
      if (budget == null) throw Exception('Orçamento não encontrado');

      final item = budget.items.firstWhere((i) => i.id == itemId);
      item.prices = prices;
      item.quantity = quantity;
      item.unit = unit;
      item.updateBestPrice();

      budget.summary.calculateSummary(budget.items);
      await _budgetDAO.insert(budget); // Corrigido: save -> insert
    } catch (e) {
      throw Exception('Erro ao atualizar preço: $e');
    }
  }

  Future<void> removeLocation(String budgetId, String locationId) async {
    // Busque o orçamento antes de iniciar a transação
    final budget = await _budgetDAO.findById(budgetId);
    if (budget == null) throw Exception('Orçamento não encontrado');

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Remove o local usando o DAO de local (todos os acessos aqui usam 'txn')
      await _locationDAO.delete(txn, budgetId, locationId);

      // Remove os preços associados a este local
      await txn.delete(
        'prices',
        where: 'location_id = ?',
        whereArgs: [locationId],
      );

      // Atualiza o orçamento em memória removendo o local
      budget.locations.removeWhere((loc) => loc.id == locationId);

      // Para cada item, remova os preços para este local e atualize o melhor preço
      for (var item in budget.items) {
        if (item.prices.containsKey(locationId)) {
          item.prices.remove(locationId);
          item.updateBestPrice();
        }
      }

      // Recalcula o sumário com os itens atualizados
      budget.summary.calculateSummary(budget.items);

      // Atualiza o orçamento no banco usando o mesmo objeto de transação
      await _budgetDAO.insertWithTransaction(txn, budget);
    });
  }

  Future<void> removeItem(String budgetId, String itemId) async {
    // Busque o orçamento fora da transação para que não use o database global internamente
    final budget = await _budgetDAO.findById(budgetId);
    if (budget == null) throw Exception('Orçamento não encontrado');

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      try {
        // Remove o item e preços associados usando o objeto da transação 'txn'
        await txn.delete(
          'budget_items',
          where: 'budget_id = ? AND id = ?',
          whereArgs: [budgetId, itemId],
        );

        await txn.delete('prices', where: 'item_id = ?', whereArgs: [itemId]);

        // Atualize o orçamento em memória sem chamar métodos que acessem o banco
        budget.items.removeWhere((item) => item.id == itemId);
        budget.summary.calculateSummary(budget.items);

        // Salve as alterações usando o objeto da transação
        await _budgetDAO.insertWithTransaction(txn, budget);
      } catch (e) {
        throw Exception('Erro ao remover item: $e');
      }
    });
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _budgetDAO.delete(budgetId);
    } catch (e) {
      throw Exception('Erro ao excluir orçamento: $e');
    }
  }

  Future<Map<String, dynamic>> generateSavingsReport(String budgetId) async {
    try {
      final budget = await getBudget(budgetId);
      if (budget == null) throw Exception('Orçamento não encontrado');

      return {
        'totalOriginal': budget.summary.totalOriginal,
        'totalOptimized': budget.summary.totalOptimized,
        'savings': budget.summary.savings,
        'savingsPercentage': budget.summary.getSavingsPercentage(),
        'bestPricesByItem': budget.items.map((item) {
          final location = budget.locations.firstWhere(
            (loc) => loc.id == item.bestPriceLocation,
            orElse: () => BudgetLocation(
              id: '',
              budgetId: budgetId,
              name: 'Desconhecido',
              address: '',
              priceDate: DateTime.now(),
            ),
          );

          return {
            'name': item.name,
            'bestPrice': item.bestPrice,
            'bestLocation': location.name,
            'potentialSavings': item.prices.values.isNotEmpty
                ? item.prices.values.reduce((a, b) => a > b ? a : b) -
                    (item.bestPrice)
                : 0.0,
          };
        }).toList(),
      };
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  Future<void> updateSummary(String budgetId, BudgetSummary summary) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await BudgetSummaryDAO().save(txn, budgetId, summary);
    });
  }
}
