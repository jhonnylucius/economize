import 'package:economize/data/budget_summary_dao.dart';
import 'package:economize/data/database_helper.dart';
import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:economize/model/budget/budget_location.dart';
import 'package:economize/model/budget/budget_summary.dart';
import 'package:sqflite/sqflite.dart';

class BudgetDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final BudgetSummaryDAO _summaryDAO =
      BudgetSummaryDAO(); // Instancia o DAO do Summary
  static const String tableName = 'budgets'; //Nome da tabela de orçamentos
  static const String locationsTable =
      'locations'; //Nome da tabela de localizações
  static const String itemsTable =
      'budget_items'; //Nome da tabela de itens do orçamento
  static const String pricesTable = 'prices'; //Nome da tabela de preços

  Future<void> insert(Budget budget) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // 1. Insere o orçamento básico
      await txn.insert(
          tableName,
          {
            'id': budget.id,
            'title': budget.title,
            'date': budget.date.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Insere os locais
      for (var location in budget.locations) {
        await txn.insert(
            locationsTable,
            {
              'id': location.id,
              'budget_id': budget.id,
              'name': location.name,
              'address': location.address,
              'price_date': location.priceDate.millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 3. Insere os itens
      for (var item in budget.items) {
        await txn.insert(
            itemsTable,
            {
              'id': item.id,
              'budget_id': budget.id,
              'name': item.name,
              'category': item.category,
              'unit': item.unit,
              'quantity': item.quantity,
              'best_price_location': item.bestPriceLocation,
              'best_price': item.bestPrice,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);

        // 4. Insere os preços de cada item
        for (var entry in item.prices.entries) {
          await txn.insert(
              pricesTable,
              {
                'item_id': item.id,
                'location_id': entry.key,
                'price': entry.value,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 4. Salva o summary
      budget.summary.calculateSummary(budget.items);
      await _summaryDAO.save(
        txn,
        budget.id,
        budget.summary,
      ); // Passa a transação (txn)
    });
  }

  Future<Budget?> findByCategory(String category) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      tableName,
      where: 'category = ?',
      whereArgs: [category],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return _loadBudgetComplete(db, result.first);
    }
    return null;
  }

  Future<List<Budget>> findAll() async {
    final db = await _databaseHelper.database;
    final budgets = await db.query(tableName);

    return Future.wait(budgets.map((b) => _loadBudgetComplete(db, b)).toList());
  }

  Future<BudgetItem?> findByTemplateId(
    int defaultItemId,
    String budgetId,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> items = await db.query(
      itemsTable,
      where: 'default_item_id = ? AND budget_id = ?',
      whereArgs: [defaultItemId, budgetId],
      limit: 1,
    );

    if (items.isEmpty) return null;

    final prices = await db.query(
      pricesTable,
      where: 'item_id = ?',
      whereArgs: [items.first['id']],
    );

    final pricesMap = Map<String, double>.fromEntries(
      prices.map(
        (p) => MapEntry(p['location_id'] as String, p['price'] as double),
      ),
    );

    return BudgetItem.fromMap({...items.first, 'prices': pricesMap});
  }

  // Método para atualizar referência do template
  Future<void> updateTemplateReference(
    String itemId,
    int? defaultItemId,
  ) async {
    final db = await _databaseHelper.database;
    await db.update(
      itemsTable,
      {'default_item_id': defaultItemId},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<Budget> _loadBudgetComplete(
    Database db,
    Map<String, dynamic> budgetMap,
  ) async {
    // 1. Carrega locais
    final locations = await db.query(
      locationsTable,
      where: 'budget_id = ?',
      whereArgs: [budgetMap['id']],
    );

    final locationsList = locations
        .map(
          (l) => BudgetLocation(
            id: l['id'] as String,
            name: l['name'] as String,
            address: l['address'] as String,
            priceDate: DateTime.fromMillisecondsSinceEpoch(
              l['price_date'] as int,
            ),
            budgetId:
                budgetMap['id'] as String, // Corrigido: era 'id' hardcoded
          ),
        )
        .toList();

    // 2. Carrega itens com seus preços
    final items = await db.query(
      itemsTable,
      where: 'budget_id = ?',
      whereArgs: [budgetMap['id']],
    );

    final itemsList = await Future.wait(
      items.map((item) async {
        // Carrega preços do item
        final prices = await db.query(
          pricesTable,
          where: 'item_id = ?',
          whereArgs: [item['id']],
        );

        Map<String, double> pricesMap = {};
        for (var price in prices) {
          pricesMap[price['location_id'] as String] = price['price'] as double;
        }

        return BudgetItem(
          id: item['id'] as String,
          name: item['name'] as String,
          category: item['category'] as String,
          unit: item['unit'] as String,
          quantity: item['quantity'] as double,
          prices: pricesMap,
          bestPriceLocation: item['best_price_location'] as String,
          bestPrice: item['best_price'] as double,
          budgetId: budgetMap['id'] as String,
        );
      }),
    );

    // Carrega o summary
    final summary = await _summaryDAO.load(db, budgetMap['id']) ?? // Passa o db
        BudgetSummary(
          totalOriginal: 0,
          totalOptimized: 0,
          savings: 0,
          totalByLocation: {},
        )
      ..calculateSummary(itemsList);

    // 3. Cria o objeto Budget completo
    return Budget(
      id: budgetMap['id'] as String,
      title: budgetMap['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(budgetMap['date'] as int),
      locations: locationsList,
      items: itemsList,
      summary: summary,
    );
  }

  // Atualizar orçamento
  Future<void> update(Budget budget) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        tableName,
        {'title': budget.title, 'date': budget.date.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [budget.id],
      );

      // Atualiza locais e itens chamando os métodos específicos
      await _updateLocations(txn, budget);
      await _updateItems(txn, budget);

      // Atualiza o Summary
      budget.summary.calculateSummary(budget.items);
      await _summaryDAO.save(
        txn,
        budget.id,
        budget.summary,
      ); // Passa a transação
    });
  }

  // Deletar orçamento
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // Corrigido: nome da tabela de 'items' para 'budget_items'
      await txn.delete(
        pricesTable,
        where: 'item_id IN (SELECT id FROM $itemsTable WHERE budget_id = ?)',
        whereArgs: [id],
      );
      await txn.delete(itemsTable, where: 'budget_id = ?', whereArgs: [id]);
      await txn.delete(locationsTable, where: 'budget_id = ?', whereArgs: [id]);
      await txn.delete(tableName, where: 'id = ?', whereArgs: [id]);

      // Deleta o summary
      await _summaryDAO.delete(txn, id); // Passa a transação
    });
  }

  // Métodos auxiliares para atualização
  Future<void> _updateLocations(Transaction txn, Budget budget) async {
    await txn.delete(
      locationsTable,
      where: 'budget_id = ?',
      whereArgs: [budget.id],
    );
    for (var location in budget.locations) {
      await txn.insert(locationsTable, {
        'id': location.id,
        'budget_id': budget.id,
        'name': location.name,
        'address': location.address,
        'price_date': location.priceDate.millisecondsSinceEpoch,
      });
    }
  }

  Future<void> cleanOldData(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final oldBudgets = await txn.query(
        tableName,
        where: 'date < ?',
        whereArgs: [cutoffDate],
      );

      for (var budget in oldBudgets) {
        await _deleteBudget(txn, budget['id'] as String);
      }
    });
  }

  Future<void> _deleteBudget(Transaction txn, String budgetId) async {
    await txn.delete(
      pricesTable,
      where: 'item_id IN (SELECT id FROM $itemsTable WHERE budget_id = ?)',
      whereArgs: [budgetId],
    );
    await txn.delete(itemsTable, where: 'budget_id = ?', whereArgs: [budgetId]);
    await txn.delete(
      locationsTable,
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );
    await txn.delete(tableName, where: 'id = ?', whereArgs: [budgetId]);

    // Deleta o summary
    await _summaryDAO.delete(txn, budgetId); // Passa a transação
  }

  Future<void> _updateItems(Transaction txn, Budget budget) async {
    // Corrigido: nome da tabela de 'items' para 'budget_items'
    await txn.delete(
      pricesTable,
      where: 'item_id IN (SELECT id FROM $itemsTable WHERE budget_id = ?)',
      whereArgs: [budget.id],
    );
    // Corrigido: nome da tabela
    await txn.delete(
      itemsTable,
      where: 'budget_id = ?',
      whereArgs: [budget.id],
    );

    // Insere novos itens e preços
    for (var item in budget.items) {
      // Corrigido: nome da tabela
      await txn.insert(itemsTable, {
        'id': item.id,
        'budget_id': budget.id,
        'name': item.name,
        'category': item.category,
        'unit': item.unit,
        'quantity': item.quantity,
        'best_price_location': item.bestPriceLocation,
        'best_price': item.bestPrice,
      });

      for (var entry in item.prices.entries) {
        await txn.insert(pricesTable, {
          'item_id': item.id,
          'location_id': entry.key,
          'price': entry.value,
        });
      }
    }
  }

  // Buscar orçamentos por período
  Future<List<Budget>> findByDateRange(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final budgets = await db.query(
      tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );

    return Future.wait(budgets.map((b) => _loadBudgetComplete(db, b)).toList());
  }

  // Buscar total de orçamentos
  Future<int> getCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Buscar último orçamento
  Future<Budget?> getLastBudget() async {
    final db = await _databaseHelper.database;
    final budgets = await db.query(tableName, orderBy: 'date DESC', limit: 1);

    if (budgets.isEmpty) return null;
    return _loadBudgetComplete(db, budgets.first);
  }

  Future<Budget?> findById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> budgets = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (budgets.isEmpty) return null;
    return _loadBudgetComplete(db, budgets.first);
  }

  Future<void> insertWithTransaction(Transaction txn, Budget budget) async {
    // Usa as constantes definidas no topo da classe
    await txn.insert(
        tableName,
        {
          'id': budget.id,
          'title': budget.title,
          'date': budget.date.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Usa locationsTable em vez de 'budget_locations'
    for (var location in budget.locations) {
      await txn.insert(
          locationsTable,
          {
            'id': location.id,
            'budget_id': budget.id,
            'name': location.name,
            'address': location.address,
            'price_date':
                location.priceDate.millisecondsSinceEpoch, // Adicionado
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Usa itemsTable em vez de 'budget_items'
    for (var item in budget.items) {
      await txn.insert(
          itemsTable,
          {
            'id': item.id,
            'budget_id': budget.id,
            'name': item.name,
            'category': item.category,
            'quantity': item.quantity,
            'unit': item.unit,
            'best_price': item.bestPrice,
            'best_price_location': item.bestPriceLocation,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      // Usa pricesTable em vez de 'prices'
      for (var entry in item.prices.entries) {
        await txn.insert(
            pricesTable,
            {
              'item_id': item.id,
              'location_id': entry.key,
              'price': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await _summaryDAO.save(txn, budget.id, budget.summary);
  }
}
