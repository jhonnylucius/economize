import 'package:economize/accounts/data/account_dao.dart';
import 'package:economize/accounts/model/account_model.dart';

class AccountService {
  final AccountDAO _dao = AccountDAO();

  Future<List<Account>> getAccounts() {
    return _dao.findAll();
  }

  Future<int> saveAccount(Account account) {
    if (account.id == null) {
      return _dao.insert(account);
    } else {
      return _dao.update(account);
    }
  }

  Future<int> deleteAccount(int id) {
    return _dao.delete(id);
  }

  // Futuramente, podemos adicionar o método de transferência aqui
  // Future<void> transfer(Account from, Account to, double amount) async {
  //   // Lógica de transferência
  // }
  Future<List<Account>> getAllAccounts() async {
    return await _dao.findAll();
  }
}
