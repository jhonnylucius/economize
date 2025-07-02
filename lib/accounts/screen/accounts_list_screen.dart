import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/screen/account_form_screen.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/accounts/widgets/account_card.dart';
import 'package:economize/animations/glass_container.dart';
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
      MaterialPageRoute(builder: (_) => AccountFormScreen(account: account)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: () => _showAccountsHelp(context),
          ),
        ],
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

  void _showAccountsHelp(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
            frostedEffect: true,
            blur: 10,
            opacity: 0.2,
            borderRadius: 24,
            borderColor: Colors.white.withAlpha((0.3 * 255).round()),
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Minhas Contas",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Como gerenciar suas contas bancárias e carteiras",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção 1: Cards de Conta
                    _buildHelpSection(
                      context: context,
                      title: "1. Cards de Conta",
                      icon: Icons.credit_card,
                      iconColor: theme.colorScheme.primary,
                      content:
                          "Cada card representa uma conta bancária, carteira ou outro local onde você guarda dinheiro.\n\n"
                          "• Nome da Conta: Identifique facilmente cada conta\n"
                          "• Saldo: Veja quanto há disponível\n"
                          "• Ícone: Ajuda a diferenciar visualmente suas contas\n"
                          "• Toque para editar ou ver detalhes",
                    ),
                    const SizedBox(height: 20),

                    // Seção 2: Adicionar Conta
                    _buildHelpSection(
                      context: context,
                      title: "2. Adicionar Nova Conta",
                      icon: Icons.add_circle_outline,
                      iconColor: Colors.green,
                      content:
                          "Toque no botão '+' para adicionar uma nova conta.\n\n"
                          "• Dê um nome para a conta (ex: Carteira, Banco X)\n"
                          "• Escolha um ícone e tipo\n"
                          "• Informe o saldo inicial (opcional)\n"
                          "• Salve para começar a usar",
                    ),
                    const SizedBox(height: 20),

                    // Seção 3: Editar ou Excluir Conta
                    _buildHelpSection(
                      context: context,
                      title: "3. Editar ou Excluir",
                      icon: Icons.edit,
                      iconColor: Colors.blue,
                      content: "Toque em uma conta para editar seus dados.\n\n"
                          "Para excluir, use o ícone de lixeira no card da conta.\n\n"
                          "Atenção: Excluir uma conta remove todos os dados associados a ela.",
                    ),
                    const SizedBox(height: 20),

                    // Seção 4: Dicas
                    _buildHelpSection(
                      context: context,
                      title: "4. Dicas",
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.amber,
                      content:
                          "• Mantenha suas contas organizadas para melhor controle financeiro.\n"
                          "• Atualize os saldos sempre que fizer movimentações fora do app, lançando a despesa ou receita no app.\n"
                          "• Use nomes e ícones que facilitem sua identificação.",
                    ),
                    const SizedBox(height: 24),

                    // Botão para fechar
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          "Entendi!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: iconColor.withAlpha((0.2 * 255).round()),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
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
