import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/screen/account_form_screen.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/accounts/widgets/account_card.dart';
import 'package:economize/animations/loading_animations.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      // CORREÇÃO: Chamando o método com o nome correto 'getAllAccounts'
      _accountsFuture = _service.getAllAccounts();
    });
  }

  void _navigateAndRefresh(BuildContext context, {Account? account}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: account),
      ),
    );

    if (result == true && mounted) {
      _loadAccounts();
    }
  }

  void _showDeleteConfirmation(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza de que deseja excluir a conta "${account.name}"? Esta ação não pode ser desfeita e todas as transações associadas a ela perderão o vínculo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (account.id != null) {
                await _service.deleteAccount(account.id!);
                _loadAccounts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conta excluída!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.all(8),
              itemCount: accounts.length,
              physics:
                  const AlwaysScrollableScrollPhysics(), // <-- Adicione esta linha
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
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone grande centralizado
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
