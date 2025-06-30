// Em lib/accounts/model/account_transaction.dart

enum AccountTransactionType { COST, REVENUE, TRANSFER_IN, TRANSFER_OUT }

class AccountTransaction {
  final String id;
  final int accountId; // <-- MUDAR PARA int
  final double value;
  final DateTime date;
  final AccountTransactionType type;
  final String? description;
  final int? relatedAccountId; // <-- MUDAR PARA int?

  AccountTransaction({
    required this.id,
    required this.accountId,
    required this.value,
    required this.date,
    required this.type,
    this.description,
    this.relatedAccountId,
  });

  // Adicionar métodos toMap e fromMap para facilitar a vida no DAO
  Map<String, dynamic> toMap() => {
        'id': id,
        'accountId': accountId,
        'value': value,
        'date': date.toIso8601String(),
        'type': type.index,
        'description': description,
        'relatedAccountId': relatedAccountId,
      };

  factory AccountTransaction.fromMap(Map<String, dynamic> map) =>
      AccountTransaction(
        id: map['id'],
        accountId: map['accountId'],
        value: map['value'],
        date: DateTime.parse(map['date']),
        type: AccountTransactionType.values[map['type']],
        description: map['description'],
        relatedAccountId: map['relatedAccountId'],
      );
}
