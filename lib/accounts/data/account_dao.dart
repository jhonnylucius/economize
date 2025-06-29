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
}
