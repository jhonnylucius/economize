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
        return 'Savings';
      case AccountType.checking:
        return 'Checking';
      // add other cases as needed
      default:
        return toString();
    }
  }
}

String accountTypeToString(AccountType type) {
  switch (type) {
    case AccountType.checking:
      return 'Checking';
    case AccountType.savings:
      return 'Savings';
    case AccountType.creditCard:
      return 'Credit Card';
    case AccountType.cash:
      return 'Cash';
    case AccountType.investment:
      return 'Investment';
    case AccountType.other:
      return 'Other';
  }
}
