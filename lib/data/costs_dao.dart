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

  // ✅ NOVO: Buscar apenas despesas para cálculos (exclui futuras)
  Future<List<Costs>> findForCalculations() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isLancamentoFuturo = 0 OR (isLancamentoFuturo = 1 AND data <= ?)',
      whereArgs: [now],
      orderBy: 'data DESC',
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // ✅ NOVO: Buscar despesas recorrentes de origem (não futuras)
  Future<List<Costs>> findRecurrentOrigins() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'recorrente = 1 AND isLancamentoFuturo = 0',
      orderBy: 'data DESC',
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // ✅ NOVO: Buscar despesas futuras de uma recorrência específica
  Future<List<Costs>> findFutureByOrigin(String originId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'recorrenciaOrigemId = ? AND isLancamentoFuturo = 1',
      whereArgs: [originId],
      orderBy: 'data ASC',
    );

    return maps.map((map) => Costs.fromMap(map)).toList();
  }

  // ✅ NOVO: Deletar todas as despesas futuras de uma recorrência
  Future<void> deleteFutureByOrigin(String originId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      tableName,
      where: 'recorrenciaOrigemId = ? AND isLancamentoFuturo = 1',
      whereArgs: [originId],
    );
  }

  // ✅ NOVO: Converter despesa futura em real (quando for paga)
  Future<void> convertFutureToReal(String id) async {
    final db = await _databaseHelper.database;
    await db.update(
      tableName,
      {'isLancamentoFuturo': 0, 'pago': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
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

  // ✅ ATUALIZADO: Buscar despesas por período para cálculos (exclui futuras)
  Future<List<Costs>> findByPeriodForCalculations(
      DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where:
          'data BETWEEN ? AND ? AND (isLancamentoFuturo = 0 OR (isLancamentoFuturo = 1 AND data <= ?))',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), now],
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

  // ✅ ATUALIZADO: Calcular total de despesas por período (só as reais)
  Future<double> getTotalByPeriod(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(preco), 0.0) as total
      FROM $tableName
      WHERE data BETWEEN ? AND ? 
      AND (isLancamentoFuturo = 0 OR (isLancamentoFuturo = 1 AND data <= ?))
      ''',
      [start.toIso8601String(), end.toIso8601String(), now],
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // ✅ ATUALIZADO: Calcular total por tipo de despesa (só as reais)
  Future<Map<String, double>> getTotalByTipo(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT tipoDespesa, COALESCE(SUM(preco), 0.0) as total
      FROM $tableName
      WHERE data BETWEEN ? AND ? 
      AND (isLancamentoFuturo = 0 OR (isLancamentoFuturo = 1 AND data <= ?))
      GROUP BY tipoDespesa
      ''',
      [start.toIso8601String(), end.toIso8601String(), now],
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

  // ✅ ATUALIZADO: Obter média mensal por tipo (só as reais)
  Future<Map<String, double>> getMonthlyAverageByTipo(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT 
        tipoDespesa,
        COALESCE(AVG(preco), 0.0) as media
      FROM $tableName
      WHERE data BETWEEN ? AND ? 
      AND (isLancamentoFuturo = 0 OR (isLancamentoFuturo = 1 AND data <= ?))
      GROUP BY tipoDespesa
      ''',
      [start.toIso8601String(), end.toIso8601String(), now],
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

  // ATUALIZAR O MÉTODO createTable:
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
      category TEXT,
      isLancamentoFuturo INTEGER DEFAULT 0,
      recorrenciaOrigemId TEXT,
      quantidadeMesesRecorrentes INTEGER DEFAULT 6,
    )
  ''');
  }

  // ✅ ATUALIZADO: Obter maiores despesas do período (só as reais)
  Future<List<Costs>> getTopExpenses(
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where:
          'data BETWEEN ? AND ? AND (isLancamentoFuturo = 0 OR (isLancamentoFuturo = 1 AND data <= ?))',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), now],
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

  // ✅ ATUALIZADO: Verificar se existe despesa no período (só as reais)
  Future<bool> hasExpensesInPeriod(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final result = await db.query(
      tableName,
      where:
          'data BETWEEN ? AND ? AND (isLancamentoFuturo = 0 OR (isLancamentoFuturo = 1 AND data <= ?))',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), now],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ✅ NOVO: Obter estatísticas de recorrências
  Future<Map<String, dynamic>> getRecurrenceStats() async {
    final db = await _databaseHelper.database;

    final totalRecurrent = await db.rawQuery(
        'SELECT COUNT(*) as total FROM $tableName WHERE recorrente = 1 AND isLancamentoFuturo = 0');

    final totalFuture = await db.rawQuery(
        'SELECT COUNT(*) as total FROM $tableName WHERE isLancamentoFuturo = 1');

    return {
      'totalRecurrent': totalRecurrent.first['total'] as int,
      'totalFuture': totalFuture.first['total'] as int,
    };
  }
}
