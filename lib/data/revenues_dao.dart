import 'package:economize/data/database_helper.dart';
import 'package:economize/model/revenues.dart';
import 'package:sqflite/sqflite.dart';

class RevenuesDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Inserir nova receita
  Future<void> insert(Revenues revenue) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'revenues',
      revenue.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Buscar todas as receitas
  Future<List<Revenues>> findAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'revenues',
      orderBy: 'data DESC',
    );

    return maps.map((map) => Revenues.fromMap(map)).toList();
  }

  // Buscar receita por ID
  Future<Revenues?> findById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'revenues',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Revenues.fromMap(maps.first);
  }

  // Buscar receitas por período
  Future<List<Revenues>> findByPeriod(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final startStr =
        "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}";
    final endStr =
        "${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}";

    final List<Map<String, dynamic>> maps = await db.query(
      'revenues',
      where: 'data BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'data DESC',
    );

    return maps.map((map) => Revenues.fromMap(map)).toList();
  }

  // Buscar receitas por tipo
  Future<List<Revenues>> findByTipo(String tipo) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'revenues',
      where: 'tipoReceita = ?',
      whereArgs: [tipo],
      orderBy: 'data DESC',
    );

    return maps.map((map) => Revenues.fromMap(map)).toList();
  }

  // Atualizar receita
  Future<void> update(Revenues revenue) async {
    final db = await _databaseHelper.database;
    await db.update(
      'revenues',
      revenue.toMap(),
      where: 'id = ?',
      whereArgs: [revenue.id],
    );
  }

  // Deletar receita
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('revenues', where: 'id = ?', whereArgs: [id]);
  }

  // Calcular total de receitas por período
  Future<double> getTotalByPeriod(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(preco) as total
      FROM revenues
      WHERE data BETWEEN ? AND ?
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // Calcular total por tipo de receita
  Future<Map<String, double>> getTotalByTipo(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT tipoReceita, SUM(preco) as total
      FROM revenues
      WHERE data BETWEEN ? AND ?
      GROUP BY tipoReceita
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return Map.fromEntries(
      result.map(
        (row) => MapEntry(row['tipoReceita'] as String, row['total'] as double),
      ),
    );
  }

  // Limpar receitas antigas
  Future<void> cleanOldData(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await db.delete(
      'revenues',
      where: 'data < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
}
