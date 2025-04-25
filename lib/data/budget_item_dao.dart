import 'package:economize/data/database_helper.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:sqflite/sqflite.dart';

class BudgetItemDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  static const String tableName = 'budget_items';
  static const String pricesTable = 'prices';

  Future<void> insert(BudgetItem item) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var entry in item.prices.entries) {
        await txn.insert(pricesTable, {
          'item_id': item.id,
          'location_id': entry.key,
          'price': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<BudgetItem>> findByBudgetId(String budgetId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> items = await db.query(
      tableName,
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );

    return Future.wait(
      items.map((item) async {
        final prices = await db.query(
          pricesTable,
          where: 'item_id = ?',
          whereArgs: [item['id']],
        );

        final pricesMap = Map<String, double>.fromEntries(
          prices.map(
            (p) => MapEntry(p['location_id'] as String, p['price'] as double),
          ),
        );

        return BudgetItem.fromMap({...item, 'prices': pricesMap});
      }),
    );
  }

  Future<BudgetItem?> findById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> items = await db.query(
      tableName, // Corrigido: estava usando 'locations'
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (items.isEmpty) return null;

    final prices = await db.query(
      pricesTable,
      where: 'item_id = ?',
      whereArgs: [id],
    );

    final pricesMap = Map<String, double>.fromEntries(
      prices.map(
        (p) => MapEntry(p['location_id'] as String, p['price'] as double),
      ),
    );

    return BudgetItem.fromMap({...items.first, 'prices': pricesMap});
  }

  Future<void> update(BudgetItem item) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        tableName,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      await txn.delete(pricesTable, where: 'item_id = ?', whereArgs: [item.id]);

      for (var entry in item.prices.entries) {
        await txn.insert(pricesTable, {
          'item_id': item.id,
          'location_id': entry.key,
          'price': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete(pricesTable, where: 'item_id = ?', whereArgs: [id]);
      await txn.delete(tableName, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<BudgetItem>> findByCategory(
    String category,
    String budgetId,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> items = await db.query(
      tableName,
      where: 'category = ? AND budget_id = ?',
      whereArgs: [category, budgetId],
    );

    return Future.wait(
      items.map((item) async {
        final prices = await db.query(
          pricesTable,
          where: 'item_id = ?',
          whereArgs: [item['id']],
        );

        final pricesMap = Map<String, double>.fromEntries(
          prices.map(
            (p) => MapEntry(p['location_id'] as String, p['price'] as double),
          ),
        );

        return BudgetItem.fromMap({...item, 'prices': pricesMap});
      }),
    );
  }

  Future<List<String>> getDistinctCategories(String budgetId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      distinct: true,
      columns: ['category'],
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );

    return result.map((map) => map['category'] as String).toList();
  }
}
