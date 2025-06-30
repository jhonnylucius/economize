import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/data/database_helper.dart';

class AccountDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(Account account) async {
    final db = await _databaseHelper.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> findAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  Future<int> update(Account account) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Account?> findById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Account>> findByType(String type) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'type = ?',
      whereArgs: [type],
    );
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  Future<List<Account>> findByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
    );
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  Future<double> getTotalBalance() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      columns: ['SUM(balance) AS total'],
    );
    if (maps.isNotEmpty && maps.first['total'] != null) {
      return maps.first['total'] as double;
    }
    return 0.0; // Retorna 0 se não houver contas
  }

  Future<void> updateBalance(int accountId, double newBalance) async {
    final db = await _databaseHelper.database;
    await db.update(
      'accounts',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }
}
