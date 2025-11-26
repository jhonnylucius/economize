import 'package:economize/accounts/data/account_dao.dart';
import 'package:economize/accounts/data/account_transaction_dao.dart';
import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/model/account_transaction.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:uuid/uuid.dart';

class AccountService {
  final AccountDAO _accountDAO = AccountDAO();
  final AccountTransactionDAO _transactionDAO = AccountTransactionDAO();
  final Uuid _uuid = const Uuid();
  // Instancie os services (ajuste se já usar injeção de dependência)
  final CostsService _costsService = CostsService();
  final RevenuesService _revenuesService = RevenuesService();

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

  Future<void> transferBetweenAccountsWithServices({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    if (fromAccountId == toAccountId) {
      throw Exception('A conta de origem e destino não podem ser a mesma.');
    }

    // Buscar os nomes das contas
    final fromAccount = await _accountDAO.findById(fromAccountId);
    final toAccount = await _accountDAO.findById(toAccountId);

    final fromName = fromAccount?.name ?? 'Conta origem';
    final toName = toAccount?.name ?? 'Conta destino';

    // 1. Lança despesa na conta de origem
    final cost = Costs(
      id: const Uuid().v4(),
      accountId: fromAccountId,
      data: date,
      preco: amount,
      descricaoDaDespesa:
          'Transferência para $toName${description != null && description.isNotEmpty ? ': $description' : ''}',
      tipoDespesa: 'Transferência',
      recorrente: false,
      pago: true,
      category: 'Transferência',
    );
    await _costsService.saveCost(cost, this);

    // 2. Lança receita na conta de destino
    final revenue = Revenues(
      id: const Uuid().v4(),
      accountId: toAccountId,
      data: date,
      preco: amount,
      descricaoDaReceita:
          'Transferência recebida de $fromName${description != null && description.isNotEmpty ? ': $description' : ''}',
      tipoReceita: 'Transferência',
    );
    await _revenuesService.saveRevenue(revenue, this);
  }

  Future<void> deleteAccount(int accountId) async {
    await _accountDAO.delete(accountId);
  }

  // --- LÓGICA DE ATUALIZAÇÃO DE SALDO ---

  Future<void> handleNewTransaction({
    required int accountId,
    required double amount,
    required bool isRevenue,
    required DateTime date, // <-- adicione este parâmetro
  }) async {
    final account = await _accountDAO.findById(accountId);
    if (account == null) return;

    final newBalance =
        isRevenue ? account.balance + amount : account.balance - amount;
    await _accountDAO.updateBalance(accountId, newBalance);

    await _createAndSaveTransactionRecord(
      accountId: accountId,
      amount: isRevenue ? amount : -amount,
      type: isRevenue
          ? AccountTransactionType.REVENUE
          : AccountTransactionType.COST,
      description: isRevenue ? 'Nova receita' : 'Nova despesa', // Poderia ser melhorado para receber a descrição real
      date: date, // <-- passe a data aqui
    );
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
    required DateTime date, // <-- adicione este parâmetro
  }) async {
    if (oldAccountId == newAccountId) {
      await handleDeletedTransaction(
          accountId: oldAccountId, amount: oldAmount, isRevenue: oldIsRevenue);
      await handleNewTransaction(
          accountId: newAccountId,
          amount: newAmount,
          isRevenue: newIsRevenue,
          date: date);
    } else {
      await handleDeletedTransaction(
          accountId: oldAccountId, amount: oldAmount, isRevenue: oldIsRevenue);
      await handleNewTransaction(
          accountId: newAccountId,
          amount: newAmount,
          isRevenue: newIsRevenue,
          date: date);
    }
  }

  // --- LÓGICA DE TRANSFERÊNCIA ---

  Future<void> transfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    String? description,
    required DateTime date, // <-- adicione aqui
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
    await _createAndSaveTransactionRecord(
      accountId: fromAccountId,
      amount: -amount,
      type: AccountTransactionType.TRANSFER_OUT,
      description: '$commonDescription para ${toAccount.name}',
      relatedAccountId: toAccountId,
      date: date, // <-- passe a data aqui
    );
    await _createAndSaveTransactionRecord(
      accountId: toAccountId,
      amount: amount,
      type: AccountTransactionType.TRANSFER_IN,
      description: '$commonDescription de ${fromAccount.name}',
      relatedAccountId: fromAccountId,
      date: date, // <-- passe a data aqui
    );
  }

  Future<void> transferBetweenAccounts({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    String? description,
    required DateTime date, // <-- adicione aqui
  }) {
    return transfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      description: description,
      date: date, // <-- passe a data aqui
    );
  }

  Future<void> _createAndSaveTransactionRecord({
    required int accountId,
    required double amount,
    required AccountTransactionType type,
    String? description,
    int? relatedAccountId,
    required DateTime date, // <-- adicione aqui
  }) {
    final transaction = AccountTransaction(
      id: _uuid.v4(),
      accountId: accountId,
      value: amount,
      date: date, // <-- use a data recebida
      type: type,
      description: description,
      relatedAccountId: relatedAccountId,
    );
    return _transactionDAO.insert(transaction);
  }
}
