import 'package:economize/model/budget/budget_summary.dart';
import 'package:sqflite/sqflite.dart';

class BudgetSummaryDAO {
  Future<void> save(
    Transaction txn,
    String budgetId,
    BudgetSummary summary,
  ) async {
    // Salva os totais por localização
    for (var entry in summary.totalByLocation.entries) {
      await txn.insert('location_totals', {
        'budget_id': budgetId,
        'location_id': entry.key,
        'total': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Salva o sumário geral
    await txn.insert('budget_summaries', {
      'budget_id': budgetId,
      'total_original': summary.totalOriginal,
      'total_optimized': summary.totalOptimized,
      'savings': summary.savings,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<BudgetSummary?> load(Database db, String budgetId) async {
    final summaryMap = await db.query(
      'budget_summaries',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
      limit: 1,
    );

    if (summaryMap.isEmpty) return null;

    final locationTotals = await db.query(
      'location_totals',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );

    final totalByLocation = Map<String, double>.fromEntries(
      locationTotals.map(
        (lt) => MapEntry(lt['location_id'] as String, lt['total'] as double),
      ),
    );

    return BudgetSummary(
      totalOriginal: summaryMap.first['total_original'] as double,
      totalOptimized: summaryMap.first['total_optimized'] as double,
      savings: summaryMap.first['savings'] as double,
      totalByLocation: totalByLocation,
    );
  }

  Future<void> delete(Transaction txn, String budgetId) async {
    await txn.delete(
      'budget_summaries',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );

    await txn.delete(
      'location_totals',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );
  }
}
