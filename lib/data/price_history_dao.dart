import 'package:economize/data/database_helper.dart';
import 'package:economize/model/budget/price_history.dart';
import 'package:sqflite/sqflite.dart';

class PriceHistoryDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  static const String tableName = 'price_history';

  Future<void> insert(PriceHistory priceHistory) async {
    final db = await _databaseHelper.database;
    await db.insert(
      tableName,
      priceHistory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PriceHistory>> findByItem(String itemId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'item_id = ?', // Corrigido: snake_case
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => PriceHistory.fromMap(maps[i]));
  }

  Future<List<PriceHistory>> findByLocation(String locationId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'location_id = ?', // Corrigido: snake_case
      whereArgs: [locationId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => PriceHistory.fromMap(maps[i]));
  }

  Future<List<PriceHistory>> findByItemAndLocation(
    String itemId,
    String locationId,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'item_id = ? AND location_id = ?', // Corrigido: snake_case
      whereArgs: [itemId, locationId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => PriceHistory.fromMap(maps[i]));
  }

  Future<PriceHistory?> getLastPrice(String itemId, String locationId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'item_id = ? AND location_id = ?', // Corrigido: snake_case
      whereArgs: [itemId, locationId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PriceHistory.fromMap(maps.first);
  }

  Future<double> calculatePriceVariation(
    String itemId,
    String locationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> prices = await db.query(
      tableName,
      where:
          'item_id = ? AND location_id = ? AND date BETWEEN ? AND ?', // Corrigido: snake_case
      whereArgs: [
        itemId,
        locationId,
        startDate.millisecondsSinceEpoch, // Corrigido: formato numérico
        endDate.millisecondsSinceEpoch, // Corrigido: formato numérico
      ],
      orderBy: 'date ASC',
    );

    if (prices.length < 2) return 0;

    final firstPrice = PriceHistory.fromMap(prices.first).price;
    final lastPrice = PriceHistory.fromMap(prices.last).price;

    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }

  Future<List<String>> getDistinctLocations() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      distinct: true,
      columns: ['location_id'], // Corrigido: snake_case
    );

    return result.map((map) => map['location_id'] as String).toList();
  }

  Future<List<String>> getDistinctItemsByLocation(String locationId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      distinct: true,
      columns: ['item_id'], // Corrigido: snake_case
      where: 'location_id = ?', // Corrigido: snake_case
      whereArgs: [locationId],
    );

    return result.map((map) => map['item_id'] as String).toList();
  }

  Future<void> cleanOldHistory(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate =
        DateTime.now()
            .subtract(Duration(days: daysToKeep))
            .millisecondsSinceEpoch; // Corrigido: formato numérico

    await db.delete(tableName, where: 'date < ?', whereArgs: [cutoffDate]);
  }
}
