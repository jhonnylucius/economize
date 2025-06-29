import 'package:economize/accounts/enum/account_type.dart';
import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:flutter/material.dart';

class AccountFormScreen extends StatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  AccountFormScreenState createState() => AccountFormScreenState();
}

class AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _selectedType = AccountType.checking;
  int _selectedIcon = Icons.account_balance.codePoint;

  final AccountService _service = AccountService();

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedIcon = widget.account!.icon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Nova Conta' : 'Editar Conta'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Conta'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Saldo Inicial'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um saldo';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, insira um número válido';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Tipo de Conta'),
              ),
              // TODO: Adicionar um seletor de ícones
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAccount,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final balance = double.parse(_balanceController.text);

      final account = Account(
        id: widget.account?.id,
        name: name,
        balance: balance,
        type: _selectedType,
        icon: _selectedIcon,
      );

      await _service.saveAccount(account);

      Navigator.of(context).pop();
    }
  }
}
