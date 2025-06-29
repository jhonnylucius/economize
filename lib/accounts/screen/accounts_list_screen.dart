import 'package:flutter/material.dart';
import '../model/account.dart';
import '../service/account_service.dart';
import '../widgets/account_card.dart';

class AccountsListScreen extends StatelessWidget {
  final AccountService _service = AccountService();

  AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Contas')),
      body: FutureBuilder<List<Account>>(
        future: _service.getAllAccounts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data!;
          return ListView(
            children: accounts.map((acc) => AccountCard(account: acc)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para tela de cadastro de conta
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
