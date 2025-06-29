import 'package:economize/accounts/enum/account_type.dart';

class Account {
  int? id;
  String name;
  AccountType type;
  double balance;
  int icon;
  String currency;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    this.currency = 'BRL',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
      'icon': icon,
      'currency': currency,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: AccountType.values[map['type']],
      balance: map['balance'],
      icon: map['icon'],
      currency: map['currency'],
    );
  }
}
