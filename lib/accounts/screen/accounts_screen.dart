import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/screen/account_form_screen.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:flutter/material.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  AccountsScreenState createState() => AccountsScreenState();
}

class AccountsScreenState extends State<AccountsScreen> {
  final AccountService _service = AccountService();
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _service.getAccounts();
  }

  void _refreshAccounts() {
    setState(() {
      _accountsFuture = _service.getAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Contas'),
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma conta encontrada.'));
          } else {
            final accounts = snapshot.data!;
            return ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return ListTile(
                  leading:
                      Icon(IconData(account.icon, fontFamily: 'MaterialIcons')),
                  title: Text(account.name),
                  subtitle: Text(account.type.toString().split('.').last),
                  trailing: Text('R\$ ${account.balance.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AccountFormScreen(account: account),
                          ),
                        )
                        .then((_) => _refreshAccounts());
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const AccountFormScreen(),
                ),
              )
              .then((_) => _refreshAccounts());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
