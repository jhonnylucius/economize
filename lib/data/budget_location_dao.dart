import 'package:economize/data/database_helper.dart';
import 'package:economize/model/budget/budget_location.dart';
import 'package:sqflite/sqflite.dart';

class BudgetLocationDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Inserir novo local
  Future<void> insert(BudgetLocation location) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'locations',
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(
    Transaction txn,
    String budgetId,
    String locationId,
  ) async {
    await txn.delete(
      'locations',
      where: 'budget_id = ? AND id = ?',
      whereArgs: [budgetId, locationId],
    );
  }

  // Buscar todos os locais de um orçamento
  Future<List<BudgetLocation>> findByBudgetId(String budgetId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => BudgetLocation.fromMap(map)).toList();
  }

  // Buscar local por ID
  Future<BudgetLocation?> findById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BudgetLocation.fromMap(maps.first);
  }

  // Atualizar local
  Future<void> update(BudgetLocation location) async {
    final db = await _databaseHelper.database;
    await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  // Buscar locais por nome
  Future<List<BudgetLocation>> searchByName(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => BudgetLocation.fromMap(map)).toList();
  }

  // Verificar se um local está em uso
  Future<bool> isLocationInUse(String id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'prices',
      where: 'location_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<List<BudgetLocation>> findAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      orderBy: 'name ASC',
    );

    return maps.map((map) => BudgetLocation.fromMap(map)).toList();
  }

  // Limpar locais não utilizados
  Future<void> cleanUnusedLocations() async {
    final db = await _databaseHelper.database;
    await db.delete(
      'locations',
      where: 'id NOT IN (SELECT DISTINCT location_id FROM prices)',
    );
  }
}
