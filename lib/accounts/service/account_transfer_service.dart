import 'package:flutter/material.dart';

import '../model/account_transaction.dart';
import '../data/account_transaction_dao.dart';

class AccountTransferService {
  final AccountTransactionDAO _txDao = AccountTransactionDAO();

  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double value,
    required DateTime date,
    String? description,
  }) async {
    // Saída da conta origem
    await _txDao.insert(AccountTransaction(
      id: UniqueKey().toString(),
      accountId: fromAccountId,
      value: value,
      date: date,
      type: AccountTransactionType.transferencia,
      description: description,
      relatedAccountId: toAccountId,
    ));
    // Entrada na conta destino
    await _txDao.insert(AccountTransaction(
      id: UniqueKey().toString(),
      accountId: toAccountId,
      value: value,
      date: date,
      type: AccountTransactionType.transferencia,
      description: description,
      relatedAccountId: fromAccountId,
    ));
  }
}
