import '../model/account_transaction.dart';

class AccountTransactionDAO {
  // CRUD para transações (receita, despesa, transferência)
  Future<void> insert(AccountTransaction tx) async {}
  Future<List<AccountTransaction>> findByAccount(String accountId) async => [];
  Future<List<AccountTransaction>> findAll() async => [];
  Future<void> update(AccountTransaction tx) async {}
  Future<void> delete(String id) async {}
  Future<List<AccountTransaction>> findByType(
      AccountTransactionType type) async {
    return [];
  }
}
