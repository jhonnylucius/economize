// Salve este conteúdo em: lib/accounts/model/account_model.dart
import 'package:economize/accounts/enum/account_type.dart';

class Account {
  final int? id; // O ID pode ser nulo ANTES de ser salvo no banco
  final String name;
  final AccountType type;
  double balance;
  final int icon;
  final String currency;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    this.currency = 'BRL',
  });

  // Método para criar uma cópia (boa prática)
  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? balance,
    int? icon,
    String? currency,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      currency: currency ?? this.currency,
    );
  }

  // Métodos para conversão, essenciais para o DAO
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index, // Armazena o enum como um inteiro
      'balance': balance,
      'icon': icon,
      'currency': currency,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: AccountType
          .values[map['type']], // Converte o inteiro de volta para enum
      balance: map['balance'],
      icon: map['icon'],
      currency: map['currency'],
    );
  }
}
