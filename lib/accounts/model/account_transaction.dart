enum AccountTransactionType { receita, despesa, transferencia }

class AccountTransaction {
  final String id;
  final String accountId;
  final double value;
  final DateTime date;
  final AccountTransactionType type;
  final String? description;
  final String? relatedAccountId; // Para transferências

  AccountTransaction({
    required this.id,
    required this.accountId,
    required this.value,
    required this.date,
    required this.type,
    this.description,
    this.relatedAccountId,
  });
}
