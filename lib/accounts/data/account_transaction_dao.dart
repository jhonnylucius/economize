import 'package:economize/accounts/model/account_transaction.dart';
import 'package:economize/data/database_helper.dart';

class AccountTransactionDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insert(AccountTransaction tx) async {
    final db = await _databaseHelper.database;
    // O seu modelo precisa de um método toMap()
    // return await db.insert('account_transactions', tx.toMap());
    // Por enquanto, faremos manualmente:
    return await db.insert('account_transactions', {
      'id': tx.id,
      'accountId': tx.accountId,
      'value': tx.value,
      'date': tx.date.toIso8601String(),
      'type': tx.type.index,
      'description': tx.description,
      'relatedAccountId': tx.relatedAccountId
    });
  }

  Future<List<AccountTransaction>> findByAccount(int accountId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );

    // O seu modelo precisa de um método fromMap()
    // return maps.map((map) => AccountTransaction.fromMap(map)).toList();
    // Por enquanto, faremos manualmente:
    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<int> delete(String id) async {
    final db = await _databaseHelper.database;
    return await db
        .delete('account_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos findAll, update, etc. podem ser adicionados aqui se necessário.
  Future<List<AccountTransaction>> findAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<int> update(AccountTransaction tx) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'account_transactions',
      {
        'accountId': tx.accountId,
        'value': tx.value,
        'date': tx.date.toIso8601String(),
        'type': tx.type.index,
        'description': tx.description,
        'relatedAccountId': tx.relatedAccountId
      },
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<List<AccountTransaction>> findByPeriod(
      DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByType(
      AccountTransactionType type) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByTypeAndPeriod(
      AccountTransactionType type, DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'type = ? AND date BETWEEN ? AND ?',
      whereArgs: [type.index, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByRelatedAccount(
      String relatedAccountId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'relatedAccountId = ?',
      whereArgs: [relatedAccountId],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByAccountAndType(
      String accountId, AccountTransactionType type) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'accountId = ? AND type = ?',
      whereArgs: [accountId, type.index],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByAccountAndTypeAndPeriod(
      String accountId,
      AccountTransactionType type,
      DateTime start,
      DateTime end) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'accountId = ? AND type = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        accountId,
        type.index,
        start.toIso8601String(),
        end.toIso8601String()
      ],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByAccountAndRelatedAccount(
      String accountId, String relatedAccountId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'accountId = ? AND relatedAccountId = ?',
      whereArgs: [accountId, relatedAccountId],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByAccountAndRelatedAccountAndPeriod(
      String accountId,
      String relatedAccountId,
      DateTime start,
      DateTime end) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'accountId = ? AND relatedAccountId = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        accountId,
        relatedAccountId,
        start.toIso8601String(),
        end.toIso8601String()
      ],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }

  Future<List<AccountTransaction>> findByAccountAndTypeAndRelatedAccount(
      String accountId,
      AccountTransactionType type,
      String relatedAccountId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_transactions',
      where: 'accountId = ? AND type = ? AND relatedAccountId = ?',
      whereArgs: [accountId, type.index, relatedAccountId],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => AccountTransaction(
              id: map['id'],
              accountId: map['accountId'],
              value: map['value'],
              date: DateTime.parse(map['date']),
              type: AccountTransactionType.values[map['type']],
              description: map['description'],
              relatedAccountId: map['relatedAccountId'],
            ))
        .toList();
  }
}
