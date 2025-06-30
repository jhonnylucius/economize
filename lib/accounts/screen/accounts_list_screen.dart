import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/screen/account_form_screen.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/accounts/widgets/account_card.dart';
import 'package:economize/animations/loading_animations.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  final AccountService _service = AccountService();
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      _accountsFuture = _service.getAllAccounts();
    });
  }

  void _navigateAndRefresh(BuildContext context, {Account? account}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountFormScreen()),
    );
    if (result == true) {
      _loadAccounts(); // recarrega as contas
      // Aqui, se quiser, pode chamar um callback para atualizar a home também!
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Contas'),
        backgroundColor: themeManager.getCurrentPrimaryColor(),
        foregroundColor: Colors.white,
      ),
      backgroundColor: themeManager.currentTheme.scaffoldBackgroundColor,
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: BrandLoadingAnimation(
                size: 80,
                primaryColor: themeManager.getAppBarTextColor(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar contas: ${snapshot.error}',
                style: TextStyle(
                    color: themeManager.currentTheme.colorScheme.error),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context, themeManager);
          }

          final accounts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadAccounts(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  8, 8, 8, 120), // padding extra no final
              itemCount: accounts.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return SlideAnimation.fromBottom(
                  delay: Duration(milliseconds: 100 * (index % 10)),
                  child: AccountCard(
                    account: account,
                    onTap: () => _navigateAndRefresh(context, account: account),
                    onDelete: () async {
                      await _service.deleteAccount(account.id!);
                      _loadAccounts();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conta excluída!')),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Conta'),
        backgroundColor: themeManager.getCurrentPrimaryColor(),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeManager themeManager) {
    final textColor = Colors.black;
    return Container(
      color: Colors.white, // <-- Garante fundo branco em qualquer tema
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon_removedbg.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 16),
                Text(
                  'Vamos começar?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Crie sua primeira conta para começar a organizar suas finanças.',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withAlpha((0.7 * 255).toInt()),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _navigateAndRefresh(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Criar Primeira Conta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 216, 78, 196),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
