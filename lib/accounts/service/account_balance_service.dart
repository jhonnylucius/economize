import '../model/account_transaction.dart';
import '../data/account_transaction_dao.dart';

class AccountBalanceService {
  final AccountTransactionDAO _txDao = AccountTransactionDAO();

  Future<double> getBalance(String accountId) async {
    final txs = await _txDao.findByAccount(accountId);
    double balance = 0.0;
    for (final tx in txs) {
      if (tx.type == AccountTransactionType.receita) {
        balance += tx.value;
      } else if (tx.type == AccountTransactionType.despesa) {
        balance -= tx.value;
      }
      // Transferências podem ser tratadas aqui também
    }
    return balance;
  }
}
