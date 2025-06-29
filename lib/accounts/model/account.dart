import 'package:economize/accounts/enum/account_type.dart';

class Account {
  final String id;
  final String name;
  final AccountType type;
  double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }
}
