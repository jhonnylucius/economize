enum AccountType {
  checking,
  savings,
  creditCard,
  cash,
  investment,
  other,
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.savings:
        return 'Poupança';
      case AccountType.checking:
        return 'Cheque';
      case AccountType.creditCard:
        return 'Cartão de Crédito';
      case AccountType.cash:
        return 'Dinheiro';
      case AccountType.investment:
        return 'Investimento';
      case AccountType.other:
        return 'Outros';
    }
  }
}

String accountTypeToString(AccountType type) {
  switch (type) {
    case AccountType.checking:
      return 'Cheque';
    case AccountType.savings:
      return 'Poupança';
    case AccountType.creditCard:
      return 'Cartão de Crédito';
    case AccountType.cash:
      return 'Dinheiro';
    case AccountType.investment:
      return 'Investimento';
    case AccountType.other:
      return 'Outros';
  }
}
