import 'package:economize/accounts/enum/account_type.dart';
import 'package:economize/accounts/model/account_model.dart';
import 'package:flutter/material.dart';

class AccountSelector extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const AccountSelector({
    super.key,
    required this.accounts,
    required this.onChanged,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedId,
      items: accounts
          .map((acc) => DropdownMenuItem(
                value: acc.id.toString(),
                child: Text('${acc.name} (${acc.type.displayName})'),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      hint: const Text('Selecione a conta'),
    );
  }
}
