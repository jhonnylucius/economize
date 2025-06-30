import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/screen/account_form_screen.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/accounts/widgets/account_card.dart';
import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/loading_animations.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen>
    with TickerProviderStateMixin {
  final AccountService _accountService = AccountService();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  late AnimationController _pulseController;
  late AnimationController _confettiController;

  bool _isLoading = true;
  double _totalBalance = 0.0;
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _loadBalanceData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadBalanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final accounts = await _accountService.getAllAccounts();
      final totalBalance =
          accounts.fold<double>(0.0, (sum, acc) => sum + acc.balance);

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _totalBalance = totalBalance;
          _isLoading = false;
        });

        if (_totalBalance > 1000) {
          // Exemplo de condição para celebrar
          _confettiController.forward(from: 0.0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar saldos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final isPositiveBalance = _totalBalance >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saldos das Contas',
            style: TextStyle(color: Colors.white)),
        backgroundColor: themeManager.getCurrentPrimaryColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBalanceData,
            tooltip: 'Atualizar Saldos',
          ),
        ],
      ),
      backgroundColor: themeManager.currentTheme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: BrandLoadingAnimation(
                size: 120,
                primaryColor: themeManager.getCurrentPrimaryColor(),
              ),
            )
          : Stack(
              children: [
                // Efeito de confete se o saldo for muito positivo
                if (isPositiveBalance && _totalBalance > 1000)
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiAnimation(
                      animationController: _confettiController,
                      particleCount: 40,
                      direction: ConfettiDirection.down,
                      colors: const [Colors.green, Colors.blue, Colors.yellow],
                    ),
                  ),
                // Conteúdo principal
                RefreshIndicator(
                  onRefresh: _loadBalanceData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildTotalBalanceHeader(
                            isPositiveBalance, themeManager),
                      ),
                      _buildAccountsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotalBalanceHeader(
      bool isPositiveBalance, ThemeManager themeManager) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          PulseAnimation(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeManager.currentTheme.cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: (isPositiveBalance ? Colors.green : Colors.red)
                        .withAlpha((0.7 * 255).toInt()),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Saldo Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: themeManager
                            .getDetailCardTextColor()
                            .withAlpha((0.7 * 255).toInt()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(_totalBalance),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isPositiveBalance
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    if (_accounts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Nenhuma conta encontrada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vá para a tela de Contas para adicionar a sua primeira!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final account = _accounts[index];
          return SlideAnimation.fromBottom(
            delay: Duration(milliseconds: 100 * index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: AccountCard(
                account: account,
                onTap: () async {
                  // Abre o formulário de edição e recarrega ao voltar
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountFormScreen(account: account),
                    ),
                  );
                  if (result == true) {
                    _loadBalanceData();
                  }
                },
                onDelete: () async {
                  // Confirmação antes de excluir
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir Conta'),
                      content: const Text(
                          'Tem certeza que deseja excluir esta conta?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _accountService.deleteAccount(account.id!);
                    _loadBalanceData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conta excluída!')),
                      );
                    }
                  }
                },
              ),
            ),
          );
        },
        childCount: _accounts.length,
      ),
    );
  }
}
