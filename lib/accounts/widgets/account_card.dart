import 'package:economize/accounts/enum/account_type.dart';
import 'package:flutter/material.dart';
import '../model/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(account.name),
        subtitle: Text(account.type.displayName),
        trailing: Text('R\$ ${account.balance.toStringAsFixed(2)}'),
      ),
    );
  }
}
