import 'package:economize/data/database_helper.dart';
import 'package:economize/model/costs.dart';
import 'package:sqflite/sqflite.dart';

class CostsDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  static const String tableName = 'costs';

  // Inserir nova despesa
  Future<void> insert(Costs cost) async {
    final db = await _databaseHelper.database;
    await db.insert(
      tableName,
      cost.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Buscar todas as despesas
  Future<List<Costs>> findAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'data DESC',
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // Buscar despesa por ID
  Future<Costs?> findById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Costs.fromMap(maps.first);
  }

  // Buscar despesas por período
  Future<List<Costs>> findByPeriod(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'costs',
      where: 'data BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'data DESC',
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // Buscar despesas por tipo
  Future<List<Costs>> findByTipo(String tipo) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'tipoDespesa = ?',
      whereArgs: [tipo],
      orderBy: 'data DESC',
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // Buscar por tipo e período
  Future<List<Costs>> findByTipoAndPeriod(
    String tipo,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'tipoDespesa = ? AND data BETWEEN ? AND ?',
      whereArgs: [tipo, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'data DESC',
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // Atualizar despesa
  Future<void> update(Costs cost) async {
    final db = await _databaseHelper.database;
    await db.update(
      tableName,
      cost.toMap(),
      where: 'id = ?',
      whereArgs: [cost.id],
    );
  }

  // Deletar despesa
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Calcular total de despesas por período
  Future<double> getTotalByPeriod(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(preco), 0.0) as total
      FROM $tableName
      WHERE data BETWEEN ? AND ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // Calcular total por tipo de despesa
  Future<Map<String, double>> getTotalByTipo(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT tipoDespesa, COALESCE(SUM(preco), 0.0) as total
      FROM $tableName
      WHERE data BETWEEN ? AND ?
      GROUP BY tipoDespesa
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return Map.fromEntries(
      result.map(
        (row) => MapEntry(
          row['tipoDespesa'] as String,
          row['total'] as double? ?? 0.0,
        ),
      ),
    );
  }

  // Obter média mensal por tipo
  Future<Map<String, double>> getMonthlyAverageByTipo(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT 
        tipoDespesa,
        COALESCE(AVG(preco), 0.0) as media
      FROM $tableName
      WHERE data BETWEEN ? AND ?
      GROUP BY tipoDespesa
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return Map.fromEntries(
      result.map(
        (row) => MapEntry(
          row['tipoDespesa'] as String,
          row['media'] as double? ?? 0.0,
        ),
      ),
    );
  }

  Future<void> createTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      accountId INTEGER,
      data TEXT NOT NULL,
      preco REAL NOT NULL,
      descricaoDaDespesa TEXT NOT NULL,
      tipoDespesa TEXT NOT NULL,
      recorrente INTEGER DEFAULT 0,
      pago INTEGER DEFAULT 0,
      category TEXT
    )
  ''');
  }

  // Obter maiores despesas do período
  Future<List<Costs>> getTopExpenses(
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'data BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'preco DESC',
      limit: limit,
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // Limpar dados antigos
  Future<void> cleanOldData(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate =
        DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

    await db.delete(tableName, where: 'data < ?', whereArgs: [cutoffDate]);
  }

  // Verificar se existe despesa no período
  Future<bool> hasExpensesInPeriod(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      tableName,
      where: 'data BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}
