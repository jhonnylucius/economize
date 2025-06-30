import 'package:economize/accounts/data/account_dao.dart';
import 'package:economize/accounts/data/account_transaction_dao.dart';
import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/model/account_transaction.dart';
import 'package:uuid/uuid.dart';

class AccountService {
  final AccountDAO _accountDAO = AccountDAO();
  final AccountTransactionDAO _transactionDAO = AccountTransactionDAO();
  final Uuid _uuid = const Uuid();

  // --- OPERAÇÕES BÁSICAS (CRUD) ---

  // CORREÇÃO: Mantendo apenas este método como a única fonte da verdade.
  Future<List<Account>> getAllAccounts() async {
    return _accountDAO.findAll();
  }

  Future<Account?> getAccountById(int id) async {
    return _accountDAO.findById(id);
  }

  Future<Account> saveAccount(Account account) async {
    if (account.id == null) {
      final id = await _accountDAO.insert(account);
      // Retorna a conta salva com o id gerado
      return (await _accountDAO.findById(id))!;
    } else {
      await _accountDAO.update(account);
      return (await _accountDAO.findById(account.id!))!;
    }
  }

  Future<void> deleteAccount(int accountId) async {
    await _accountDAO.delete(accountId);
  }

  // --- LÓGICA DE ATUALIZAÇÃO DE SALDO ---

  Future<void> handleNewTransaction({
    required int accountId,
    required double amount,
    required bool isRevenue,
  }) async {
    final account = await _accountDAO.findById(accountId);
    if (account == null) return;

    final newBalance =
        isRevenue ? account.balance + amount : account.balance - amount;
    await _accountDAO.updateBalance(accountId, newBalance);

    _createAndSaveTransactionRecord(
        accountId: accountId,
        amount: isRevenue ? amount : -amount,
        type: isRevenue
            ? AccountTransactionType.REVENUE
            : AccountTransactionType.COST,
        description: isRevenue ? 'Nova receita' : 'Nova despesa');
  }

  Future<void> handleDeletedTransaction({
    required int accountId,
    required double amount,
    required bool isRevenue,
  }) async {
    final account = await _accountDAO.findById(accountId);
    if (account == null) return;

    final newBalance =
        isRevenue ? account.balance - amount : account.balance + amount;
    await _accountDAO.updateBalance(accountId, newBalance);
  }

  Future<void> handleUpdatedTransaction({
    required int oldAccountId,
    required double oldAmount,
    required bool oldIsRevenue,
    required int newAccountId,
    required double newAmount,
    required bool newIsRevenue,
  }) async {
    if (oldAccountId == newAccountId) {
      await handleDeletedTransaction(
          accountId: oldAccountId, amount: oldAmount, isRevenue: oldIsRevenue);
      await handleNewTransaction(
          accountId: newAccountId, amount: newAmount, isRevenue: newIsRevenue);
    } else {
      await handleDeletedTransaction(
          accountId: oldAccountId, amount: oldAmount, isRevenue: oldIsRevenue);
      await handleNewTransaction(
          accountId: newAccountId, amount: newAmount, isRevenue: newIsRevenue);
    }
  }

  // --- LÓGICA DE TRANSFERÊNCIA ---

  Future<void> transfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    String? description,
  }) async {
    if (fromAccountId == toAccountId) {
      throw Exception('A conta de origem e destino não podem ser a mesma.');
    }

    final fromAccount = await _accountDAO.findById(fromAccountId);
    final toAccount = await _accountDAO.findById(toAccountId);

    if (fromAccount == null || toAccount == null) {
      throw Exception('Conta de origem ou destino não encontrada.');
    }
    if (fromAccount.balance < amount) {
      throw Exception('Saldo insuficiente para realizar a transferência.');
    }

    await _accountDAO.updateBalance(
        fromAccountId, fromAccount.balance - amount);
    await _accountDAO.updateBalance(toAccountId, toAccount.balance + amount);

    final commonDescription = description ?? 'Transferência';
    _createAndSaveTransactionRecord(
      accountId: fromAccountId,
      amount: -amount,
      type: AccountTransactionType.TRANSFER_OUT,
      description: '$commonDescription para ${toAccount.name}',
      relatedAccountId: toAccountId,
    );
    _createAndSaveTransactionRecord(
      accountId: toAccountId,
      amount: amount,
      type: AccountTransactionType.TRANSFER_IN,
      description: '$commonDescription de ${fromAccount.name}',
      relatedAccountId: fromAccountId,
    );
  }

  Future<void> _createAndSaveTransactionRecord({
    required int accountId,
    required double amount,
    required AccountTransactionType type,
    String? description,
    int? relatedAccountId,
  }) {
    final transaction = AccountTransaction(
      id: _uuid.v4(),
      accountId: accountId,
      value: amount,
      date: DateTime.now(),
      type: type,
      description: description,
      relatedAccountId: relatedAccountId,
    );
    return _transactionDAO.insert(transaction);
  }
}
