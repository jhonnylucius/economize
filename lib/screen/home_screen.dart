import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/model/notification_type.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/notification_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/widgets/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

// Importar o serviço de notificações e o modelo de notificação (Adicionado)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _gridController = ScrollController();
  static const String _lastTipShownKey = 'last_tip_shown_date';
  // Returns the route for each functionality index
  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/budget/list';
      case 1:
        return '/costs';
      case 2:
        return '/revenues';
      case 3:
        return '/dashboard';
      case 4:
        return '/report';
      case 5:
        return '/items/manage';
      case 6:
        return '/tips';
      case 7:
        return '/trend';
      case 8:
        return '/goals';
      default:
        return '';
    }
  }

  // Returns the label for each functionality index
  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Orçamentos';
      case 1:
        return 'Despesas';
      case 2:
        return 'Receitas';
      case 3:
        return 'Dashboard';
      case 4:
        return 'Relatórios';
      case 5:
        return 'Gerenciar Produtos';
      case 6:
        return 'Dicas';
      case 7:
        return 'Tendências';
      case 8:
        return 'Metas';
      default:
        return '';
    }
  }

  bool _isAnimating = false;
  int? selectedIndex;
  final PageController _pageController = PageController();
  final ValueNotifier<double> _scrollProgress = ValueNotifier<double>(0);
  final ValueNotifier<bool> _showFloatingPanel = ValueNotifier<bool>(false);

  // Controlador para animações gerais
  late AnimationController _controller;
  late Animation<double> _logoAnimation;

  // Serviços para dados financeiros reais
  final CostsService _costsService = CostsService();
  final RevenuesService _revenuesService = RevenuesService();
  // Adicione o serviço de notificações (Adicionado)
  final NotificationService _notificationService = NotificationService();

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Estados para interações
  int selectedCategoryTab = 0;
  bool expandedViewMode = false;

  // Para dados do usuário
  String _greeting = "Olá";
  double _currentBalance = 0.0;
  double _savingsGoalProgress = 0.0;
  double _expensesBudgetProgress = 0.0;

  // Adicione estas variáveis na classe _HomeScreenState
  double _previousBalance = 0.0;
  double _balanceVariationPercent = 0.0;

  // Categorias de funcionalidades
  final List<String> _categories = [
    "Principais",
    "Financeiro",
    "Gestão",
    "Relatórios"
  ];

  @override
  void initState() {
    super.initState();
    // Garantir orientação portrait ao iniciar/inicializar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Inicializar o serviço de notificações (Adicionado)
    _notificationService.initialize();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();

    _checkIfTipShouldBeShown();
    _updateGreeting();

    loadPreviousBalance();
    _loadFinancialData();
  }

  Future<void> _checkIfTipShouldBeShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastShownDate = prefs.getString(_lastTipShownKey);

      // Obtém a data atual no formato YYYY-MM-DD
      final today = DateTime.now().toString().split(' ')[0];

      if (lastShownDate != today) {
        // Se a data for diferente ou não existir, mostrar a dica
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _showFloatingPanel.value = true;
              // Salvar a data atual
              prefs.setString(_lastTipShownKey, today);
            }
          });
        }
      } else {
        // Já mostrou hoje, não mostrar novamente
        _showFloatingPanel.value = false;
      }
    } catch (e) {
      debugPrint('Erro ao verificar data da última dica: $e');
      // Em caso de erro, não mostrar a dica
      _showFloatingPanel.value = false;
    }
  }

  void scrollToTop() {
    if (_gridController.hasClients) {
      _gridController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = "Bom dia";
    } else if (hour < 18) {
      _greeting = "Boa tarde";
    } else {
      _greeting = "Boa noite";
    }
  }

  Future<void> _loadFinancialData() async {
    try {
      // Obter receitas e despesas (código existente)
      final costs = await _costsService.getAllCosts();
      final revenues = await _revenuesService.getAllRevenues();

      // Calcular saldo total (todas as receitas - todas as despesas) (código existente)
      final totalCosts = costs.fold<double>(0, (sum, cost) => sum + cost.preco);
      final totalRevenues =
          revenues.fold<double>(0, (sum, revenue) => sum + revenue.preco);

      // Armazenar o saldo atual como saldo anterior para a próxima comparação
      // Certifique-se de que _previousBalance é uma variável de estado (e.g., double _previousBalance = 0.0;)
      // Este passo deve vir antes que _currentBalance seja atualizado para o 'newBalance'
      _previousBalance = _currentBalance;

      // Calcular o novo saldo (será atribuído a _currentBalance no setState)
      final newBalance = totalRevenues - totalCosts;

      // Novo código: calcular variação percentual
      double variationPercent = 0.0;
      if (_previousBalance != 0) {
        // Calcula a variação baseada no saldo anterior
        variationPercent =
            ((newBalance - _previousBalance) / _previousBalance.abs()) * 100;
      } else if (newBalance > 0) {
        // Se o saldo anterior era zero e o novo é positivo, é um aumento de 100%
        variationPercent = 100.0;
      }
      // Se _previousBalance for 0 e newBalance for 0 ou negativo, variationPercent permanece 0.0

      // Calcular progresso de metas (exemplos) (código existente)
      // Suponha que a meta de economia seja 30% da receita total
      final savingsGoal = totalRevenues * 0.3;
      final currentSavings = newBalance; // currentSavings é o newBalance

      // Suponha que o orçamento de gastos seja 70% da receita total
      final expensesBudget = totalRevenues * 0.7;

      setState(() {
        _currentBalance = newBalance; // Atualiza o saldo atual
        _balanceVariationPercent =
            variationPercent; // Adiciona a nova variável de variação

        // Limitar o progresso entre 0 e 1 (código existente)
        _savingsGoalProgress = savingsGoal > 0
            ? (currentSavings / savingsGoal).clamp(0.0, 1.0)
            : 0.0;

        _expensesBudgetProgress = expensesBudget > 0
            ? (totalCosts / expensesBudget).clamp(0.0, 1.0)
            : 0.0;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados financeiros: $e');
      // Em caso de erro, manter os valores padrão (código existente)
      setState(() {
        _currentBalance = 0.0;
        _savingsGoalProgress = 0.0;
        _expensesBudgetProgress = 0.0;
        _balanceVariationPercent =
            0.0; // Também reseta a variação em caso de erro
      });
    }
  }

  // Método para carregar o saldo anterior (mês passado ou período anterior)
  Future<void> loadPreviousBalance() async {
    try {
      // Obter o mês anterior
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);

      // Buscar despesas do mês anterior
      final lastMonthCosts =
          await _costsService.getCostsByDateRange(lastMonth, endOfLastMonth);

      // Buscar receitas do mês anterior
      final lastMonthRevenues = await _revenuesService.getRevenuesByDateRange(
          lastMonth, endOfLastMonth);

      // Calcular saldo anterior
      final lastMonthTotalCosts =
          lastMonthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);
      final lastMonthTotalRevenues = lastMonthRevenues.fold<double>(
          0, (sum, revenue) => sum + revenue.preco);

      setState(() {
        _previousBalance = lastMonthTotalRevenues - lastMonthTotalCosts;
      });
    } catch (e) {
      debugPrint('Erro ao carregar saldo anterior: $e');
      // Em caso de erro, usar saldo ligeiramente diferente do atual para demonstração
      _previousBalance =
          _currentBalance * 0.95; // 5% menor que o atual por padrão
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollProgress.dispose();
    _showFloatingPanel.dispose();
    _controller.dispose();
    _gridController.dispose();
    // Não dispose _notificationService aqui se ele for um singleton global
    // ou gerenciado por Provider ou GetIt. Se ele for local a este widget, dispose.
    // Assumindo que é um singleton ou gerenciado globalmente.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = context.watch<ThemeManager>();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    // Determinar se estamos no tema escuro para ajustar detalhes visuais
    final isDarkMode = themeManager.currentThemeType != ThemeType.light;

    return ResponsiveScreen(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Use o novo _buildAppBar
      appBar: _buildAppBar(theme, isDarkMode, themeManager),
      bottomNavigationBar: _buildBottomNavBar(theme, padding),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .endDocked, // or another suitable location
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo decorativo suave (sem animações piscantes)
          Positioned.fill(
            child: _buildSafeFundoGradiente(themeManager),
          ),

          // Conteúdo principal
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Painel de boas-vindas e resumo financeiro (agora com botão de ajuda)
                  _buildWelcomePanel(themeManager, screenSize),

                  // Abas de categorias
                  _buildCategoryTabs(theme, themeManager),

                  // Grid de funções
                  Expanded(
                    child: expandedViewMode
                        ? _buildExpandedView(screenSize, themeManager)
                        : _buildGridView(screenSize, themeManager),
                  ),
                ],
              ),
            ),
          ),

          // Painel flutuante de dica
          _buildFloatingTipPanel(theme, themeManager),

          // Overlay para animação de transição
          _isAnimating
              ? AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isAnimating ? 1.0 : 0.0,
                  child: Container(
                    color: Colors.black54,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  // Appbar personalizado com animações e CONTADOR DE NOTIFICAÇÕES (Substituído)
  AppBar _buildAppBar(
      ThemeData theme, bool isDarkMode, ThemeManager themeManager) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.6 + (_logoAnimation.value * 0.4),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? Colors.black26 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary
                        .withAlpha((0.3 * 255).round()),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Hero(
                tag: 'app_logo',
                child: Image.asset('assets/icon_removedbg.png',
                    height: 40, width: 40),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FadeAnimation.fadeIn(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Economize\$',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Botão de ajuda (NOVO)
        SlideAnimation.fromRight(
          delay: const Duration(milliseconds: 300),
          child: IconButton(
            icon: Icon(
              Icons.help_outline,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: () => _showHomeScreenHelp(context),
            tooltip: 'Ajuda',
          ),
        ),

        SlideAnimation.fromRight(
          delay: const Duration(milliseconds: 400),
          child: ValueListenableBuilder<int>(
              valueListenable: _notificationService.unreadCount,
              builder: (context, unreadCount, _) {
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        _showNotificationOverlay(context);
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: ScaleAnimation.bounceIn(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
        ),
        SlideAnimation.fromRight(
          delay: const Duration(milliseconds: 500),
          child: IconButton(
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: () {
              showSearch(context: context, delegate: AppSearchDelegate());
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
    );
  }

  // Barra de navegação inferior
  Widget _buildBottomNavBar(ThemeData theme, EdgeInsets padding) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.5 * 255).round()),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor:
              theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
                icon: ScaleAnimation.bounceIn(
                  delay: const Duration(milliseconds: 800),
                  child: Icon(Icons.palette, color: theme.colorScheme.primary),
                ),
                label: 'Temas'),
            BottomNavigationBarItem(
                icon: ScaleAnimation.bounceIn(
                  delay: const Duration(milliseconds: 900),
                  child: Icon(Icons.flag,
                      color: theme
                          .colorScheme.primary), // Alterado para ícone de flag
                ),
                label: 'Metas'),
            BottomNavigationBarItem(
                icon: const SizedBox(width: 20, height: 20), label: ''),
            BottomNavigationBarItem(
                icon: ScaleAnimation.bounceIn(
                  delay: const Duration(milliseconds: 1000),
                  child: Icon(Icons.account_balance_wallet,
                      color: theme.colorScheme.primary),
                ),
                label: 'Saldo'),
            BottomNavigationBarItem(
                icon: ScaleAnimation.bounceIn(
                  delay: const Duration(milliseconds: 1100),
                  child: Icon(Icons.emoji_objects,
                      color: theme.colorScheme.primary),
                ),
                label: 'Dicas'),
          ],
          onTap: (index) {
            // Ajuste para o botão central invisível
            if (index == 2) return;

            switch (index) {
              case 0:
                showThemeSelector(context);
                break;
              case 1:
                Navigator.pushNamed(context, '/goals');
                break;
              case 3:
                Navigator.pushNamed(context, '/balance');
                break;
              case 4:
                Navigator.pushNamed(context, '/tips');
                break;
            }
          },
        ),
      ),
    );
  }

  // Fundo com gradiente suave e padrão discreto
  Widget _buildSafeFundoGradiente(ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return Stack(
      children: [
        // Gradiente base
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color.fromARGB(255, 33, 3, 107),
                      const Color.fromARGB(255, 50, 10, 142),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade100,
                    ],
            ),
          ),
        ),

        // Padrão de formas geométricas estáticas (não animadas)
        CustomPaint(
          painter: _SafeBackgroundPatternPainter(
            primaryColor: themeManager.getCurrentPrimaryColor(),
            isDark: isDark,
          ),
          child: Container(),
        )
      ],
    );
  }

  // Painel de boas-vindas com resumo financeiro (COM BOTÃO DE AJUDA)
  Widget _buildWelcomePanel(ThemeManager themeManager, Size screenSize) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SlideAnimation.fromTop(
        distance: 0.3,
        delay: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/dashboard');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeManager.getCurrentPrimaryColor(),
                  themeManager.getCurrentSecondaryColor(),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).round()),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Conteúdo original do card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_greeting!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Seu saldo atual',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormat.format(_currentBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(
                          height: 8), // Espaço entre saldo e variação
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withAlpha((0.15 * 255).round()),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  // O problema está aqui: a condição estava verificando apenas _balanceVariationPercent,
                                  // mas deveria verificar o valor atual do saldo também
                                  _currentBalance >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  // Cor baseada na direção do saldo, não da variação
                                  color: _currentBalance >= 0
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  // Mantém o sinal + ou - da variação percentual
                                  _balanceVariationPercent >= 0
                                      ? '+${_balanceVariationPercent.toStringAsFixed(1)}%'
                                      : '${_balanceVariationPercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    // Cor baseada na direção do saldo, não da variação
                                    color: _currentBalance >= 0
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                          height: 16), // Espaço antes das barras de progresso
                      Row(
                        children: [
                          Expanded(
                            child: _buildProgressIndicator(
                              'Meta de Economia', // Ajuste o label se necessário
                              _savingsGoalProgress,
                              Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProgressIndicator(
                              'Gastos do Orçamento', // Ajuste o label se necessário
                              _expensesBudgetProgress,
                              Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botão de ajuda (posição absoluta na stack)
                Positioned(
                  top: 10,
                  right: 10,
                  child: PressableCard(
                    onPress: () => _showFinancialCardHelp(context),
                    pressedScale: 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors
                          .white, // Mantendo a cor branca no card para contraste
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Indicador de progresso para o painel
  Widget _buildProgressIndicator(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '100%',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Abas de categorias
  // Abas de categorias
  Widget _buildCategoryTabs(ThemeData theme, ThemeManager themeManager) {
    final bool isDark = themeManager.currentThemeType != ThemeType.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SlideAnimation.fromLeft(
        delay: const Duration(milliseconds: 500),
        child: SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final isSelected = selectedCategoryTab == index;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedCategoryTab = index);
                  // Rola para o topo imediatamente quando um filtro é selecionado
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_gridController.hasClients) {
                      _gridController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isDark
                            ? Colors.white
                            : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(102),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                    border: isSelected
                        ? null
                        : Border.all(color: theme.dividerColor, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isDark
                              ? themeManager.getCurrentPrimaryColor()
                              : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Vista em grade
  Widget _buildGridView(Size screenSize, ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    // Filtrar os índices com base na categoria selecionada
    List<int> filteredIndices = [];

    if (selectedCategoryTab == 0) {
      // Se for "Principais", mostrar todos os itens
      filteredIndices = List.generate(8, (index) => index);
    } else if (selectedCategoryTab == 1) {
      // Financeiro
      filteredIndices = [0, 1, 2, 3];
    } else if (selectedCategoryTab == 2) {
      // Gestão
      filteredIndices = [4, 5];
    } else if (selectedCategoryTab == 3) {
      // Relatórios
      filteredIndices = [6, 7];
    }

    return Column(
      children: [
        // Alternador de modos de visualização
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FadeAnimation.fadeIn(
                delay: const Duration(milliseconds: 600),
                child: Text(
                  'Funcionalidades',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              FadeAnimation.fadeIn(
                delay: const Duration(milliseconds: 700),
                child: PressableCard(
                  onPress: () {
                    setState(() {
                      expandedViewMode = !expandedViewMode;
                    });
                  },
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    expandedViewMode ? Icons.grid_view : Icons.view_list,
                    size: 20,
                    color: themeManager.getCurrentPrimaryColor(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grade de funcionalidades com NotificationListener para detectar rolagem
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              // Atualiza o progresso da rolagem para possíveis usos futuros
              if (_gridController.hasClients) {
                _scrollProgress.value = _gridController.offset /
                    (_gridController.position.maxScrollExtent + 0.0001);
              }
              return false;
            },
            child: GridView.builder(
              key: ValueKey<int>(
                  selectedCategoryTab), // Mantém a chave para reconstrução
              controller: _gridController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount:
                  filteredIndices.length, // Usa o comprimento da lista filtrada
              itemBuilder: (context, index) {
                // Pega o índice real do item a partir da lista filtrada
                final realIndex = filteredIndices[index];

                return FadeAnimation.fadeIn(
                  delay: Duration(milliseconds: 700 + (index * 100)),
                  child: _buildGridItemWithAnimation(
                    index: realIndex,
                    icon: _getIconForIndex(realIndex),
                    label: _getLabelForIndex(realIndex),
                    route: _getRouteForIndex(realIndex),
                    themeManager: themeManager,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Vista expandida em lista
  Widget _buildExpandedView(Size screenSize, ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return Column(
      children: [
        // Título e alternador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Funcionalidades',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              PressableCard(
                onPress: () {
                  setState(() {
                    expandedViewMode = !expandedViewMode;
                  });
                },
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  expandedViewMode ? Icons.grid_view : Icons.view_list,
                  size: 20,
                  color: themeManager.getCurrentPrimaryColor(),
                ),
              ),
            ],
          ),
        ),

        // Lista de funcionalidades
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: 8,
            itemBuilder: (context, index) {
              // Filtrar por categoria selecionada
              if (selectedCategoryTab != 0) {
                if (selectedCategoryTab == 1 && ![0, 1, 2, 3].contains(index)) {
                  return const SizedBox.shrink();
                } else if (selectedCategoryTab == 2 &&
                    ![4, 5].contains(index)) {
                  return const SizedBox.shrink();
                } else if (selectedCategoryTab == 3 &&
                    ![6, 7].contains(index)) {
                  return const SizedBox.shrink();
                }
              }

              return SlideAnimation.fromRight(
                delay: Duration(milliseconds: 300 + (index * 50)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildListItem(
                    index: index,
                    icon: _getIconForIndex(index),
                    label: _getLabelForIndex(index),
                    route: _getRouteForIndex(index),
                    themeManager: themeManager,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Item de lista para vista expandida
  Widget _buildListItem({
    required int index,
    required IconData icon,
    required String label,
    required String route,
    required ThemeManager themeManager,
  }) {
    final theme = Theme.of(context);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return PressableCard(
      onPress: () => _handleItemTap(index, route),
      decoration: BoxDecoration(
        color: isDark ? Colors.white : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.5 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: themeManager
              .getCurrentPrimaryColor()
              .withAlpha((0.2 * 255).round()),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeManager
                  .getCurrentPrimaryColor()
                  .withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: themeManager.getCurrentPrimaryColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeManager.getCurrentPrimaryColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDescriptionForIndex(index),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? themeManager
                            .getCurrentPrimaryColor()
                            .withAlpha((0.7 * 255).round())
                        : theme.colorScheme.onSurface
                            .withAlpha((0.7 * 255).round()),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: themeManager.getCurrentPrimaryColor(),
          ),
        ],
      ),
    );
  }

  // Adicionado: método para fornecer descrições para cada funcionalidade
  String _getDescriptionForIndex(int index) {
    switch (index) {
      case 0:
        return 'Gerencie seus orçamentos mensais de forma eficiente.';
      case 1:
        return 'Registre e acompanhe todas as suas despesas.';
      case 2:
        return 'Adicione e visualize suas receitas facilmente.';
      case 3:
        return 'Veja um resumo completo do seu desempenho financeiro.';
      case 4:
        return 'Acesse relatórios detalhados de suas finanças.';
      case 5:
        return 'Gerencie seus produtos e itens cadastrados.';
      case 6:
        return 'Receba dicas importantes para economizar mais.';
      case 7:
        return 'Descubra tendências e insights sobre seus gastos.';
      case 8:
        return 'Cadastre suas metas e objetivos financeiros.';
      default:
        return '';
    }
  }

  // Painel flutuante com dica
  Widget _buildFloatingTipPanel(ThemeData theme, ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return ValueListenableBuilder<bool>(
      valueListenable: _showFloatingPanel,
      builder: (context, show, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          bottom: show ? 85 : -100,
          right: 16,
          left: 16,
          child: GlassContainer(
            borderRadius: 16,
            opacity: isDark ? 0.15 : 0.1, // Ajustado para melhor visibilidade
            borderColor:
                isDark ? Colors.white.withAlpha((0.2 * 255).round()) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeManager
                          .getCurrentPrimaryColor()
                          .withAlpha((0.2 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: PulseAnimation(
                      minScale: 0.9,
                      maxScale: 1.1,
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: themeManager.getCurrentPrimaryColor(),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Se precisar de ajuda, toque no simbolo de interrogação(?) no canto superior direito de cada tela.',
                      style: TextStyle(
                        fontSize: 14,
                        // Usar a cor primária para texto no modo escuro
                        color: isDark
                            ? themeManager.getCurrentPrimaryColor()
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight
                            .w500, // Aumentado para melhor legibilidade
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      // Usar a cor primária para o ícone de fechar no modo escuro
                      color: isDark
                          ? themeManager.getCurrentPrimaryColor()
                          : theme.colorScheme.onSurface
                              .withAlpha((0.7 * 255).round()),
                      size: 18,
                    ),
                    onPressed: () {
                      _showFloatingPanel.value = false;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget de item de grade animado
  Widget _buildGridItemWithAnimation({
    required int index,
    required IconData icon,
    required String label,
    required String route,
    required ThemeManager themeManager,
  }) {
    return _buildGridItem(
      icon: icon,
      label: label,
      onTap: () => _handleItemTap(index, route),
      themeManager: themeManager,
    );
  }

  // Método para tratar o toque nos itens de grid/lista
  void _handleItemTap(int index, String route) {
    setState(() {
      selectedIndex = index;
      _isAnimating = true;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _isAnimating = false;
      });
      if (route.isNotEmpty) {
        Navigator.pushNamed(context, route);
      }
    });
  }

  // Widget de item de grade
  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeManager themeManager,
  }) {
    final theme = Theme.of(context);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return PressableCard(
      onPress: onTap,
      pressedScale: 0.95,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.5 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: themeManager
              .getCurrentPrimaryColor()
              .withAlpha((0.2 * 255).round()),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeManager
                  .getCurrentPrimaryColor()
                  .withAlpha((0.3 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: themeManager.getCurrentPrimaryColor(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: themeManager.getCurrentPrimaryColor(),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Overlay de notificações (Substituído)
  // Sinaliza que este método substitui o da classe pai (State)
  void _showNotificationOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    // Marcar todas as notificações como lidas quando abrir o painel
    _notificationService.markAllAsRead();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withAlpha((0.3 * 255).round()),
            child: Stack(
              children: [
                // GestureDetector para fechar o dialog ao tocar fora do painel
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child:
                      Container(), // Container vazio para preencher a área tocável
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  // Largura do painel de notificações (85% da tela)
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height,
                  child: SlideAnimation.fromRight(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF1A1A1A) : theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.2 * 255).round()),
                            blurRadius: 15,
                            offset: const Offset(-5, 0), // Sombra à esquerda
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabeçalho do painel de notificações
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Notificações',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Botão limpar todas (aparece apenas se houver notificações)
                                    ValueListenableBuilder<
                                        List<NotificationItem>>(
                                      valueListenable:
                                          _notificationService.notifications,
                                      builder: (context, notifications, _) {
                                        if (notifications.isNotEmpty) {
                                          return IconButton(
                                            icon: Icon(
                                              Icons
                                                  .delete_sweep_outlined, // Ícone de lixeira
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey,
                                              size:
                                                  24, // Tamanho um pouco maior
                                            ),
                                            tooltip: 'Limpar todas',
                                            onPressed: () {
                                              // Mostra um diálogo de confirmação antes de limpar
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  backgroundColor: isDark
                                                      ? const Color(0xFF1A1A1A)
                                                      : theme
                                                          .cardColor, // Cor de fundo do AlertDialog
                                                  title: Text(
                                                      'Limpar notificações',
                                                      style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : theme
                                                                  .colorScheme
                                                                  .onSurface)),
                                                  content: Text(
                                                      'Deseja realmente apagar todas as notificações?',
                                                      style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white70
                                                              : theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withAlpha((0.8 *
                                                                          255)
                                                                      .round()))),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context), // Fecha o AlertDialog
                                                      child: Text('Cancelar',
                                                          style: TextStyle(
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        _notificationService
                                                            .clearAllNotifications(); // Chama o serviço para limpar
                                                        Navigator.pop(
                                                            context); // Fecha o AlertDialog
                                                      },
                                                      child: Text('Confirmar',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                  ],
                                                  shape: RoundedRectangleBorder(
                                                      // Borda arredondada
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16)),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                        return const SizedBox
                                            .shrink(); // Não mostra o botão se a lista estiver vazia
                                      },
                                    ),
                                    // Botão fechar o painel de notificações
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Lista de notificações (atualizada para usar o ValueListenableBuilder)
                          Expanded(
                            child:
                                ValueListenableBuilder<List<NotificationItem>>(
                              valueListenable:
                                  _notificationService.notifications,
                              builder: (context, notifications, _) {
                                // Mensagem se a lista de notificações estiver vazia
                                if (notifications.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_off_outlined,
                                            size: 64,
                                            color: isDark
                                                ? Colors.white.withAlpha(
                                                    (0.3 * 255).round())
                                                : Colors.grey.withAlpha(
                                                    (0.5 * 255).round())),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Nenhuma notificação',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isDark
                                                ? Colors.white.withAlpha(
                                                    (0.7 * 255).round())
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'As notificações sobre sua atividade financeira\naparecerão aqui.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white.withAlpha(
                                                    (0.5 * 255).round())
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // Botão para simular verificação (para fins de demonstração/teste)
                                        // Em uma aplicação real, a verificação seria feita em segundo plano
                                        // Este botão pode ser removido em produção.
                                        TextButton.icon(
                                          onPressed: () {
                                            // _notificationService.checkForNewNotifications(); // Supondo que este método existe para simular novas nots
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Verificando atividades recentes...'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.refresh),
                                          label: const Text(
                                              'Verificar atividades'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Constrói a lista de notificações
                                return ListView.builder(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 24),
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    // Usa o novo método para construir cada item de notificação
                                    return _buildRealNotificationItem(
                                      notification: notification,
                                      themeManager: themeManager,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Método para construir um item de notificação real (Novo Método)
  Widget _buildRealNotificationItem({
    required NotificationItem notification,
    required ThemeManager themeManager,
  }) {
    final theme = Theme.of(context);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return Dismissible(
      key: Key(notification.id), // Chave única para o Dismissible
      direction: DismissDirection
          .endToStart, // Permite deslizar para a esquerda para remover
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red, // Cor de fundo vermelha ao deslizar
        child:
            const Icon(Icons.delete, color: Colors.white), // Ícone de lixeira
      ),
      onDismissed: (_) {
        _notificationService.removeNotification(
            notification.id); // Remove a notificação ao dispensar
        // Opcional: mostrar um SnackBar de "Desfeito" para desfazer a remoção
      },
      child: Container(
        margin:
            const EdgeInsets.fromLTRB(16, 0, 16, 12), // Margem entre os itens
        decoration: BoxDecoration(
          // Cor de fundo baseada no status de leitura e no modo escuro/claro
          color: notification.isRead
              ? isDark
                  ? const Color(
                      0xFF242424) // Cor mais escura para lidas no modo escuro
                  : theme.cardColor // Cor padrão para lidas no modo claro
              : isDark
                  ? notification.color.withAlpha((0.2 * 255)
                      .round()) // Cor com opacidade para não lidas no escuro
                  : notification.color.withAlpha((0.1 * 255)
                      .round()), // Cor com opacidade para não lidas no claro
          borderRadius: BorderRadius.circular(16), // Borda arredondada
          border: Border.all(
            // Borda sutil ou destacada
            color: notification.isRead
                ? isDark
                    ? Colors.white.withAlpha(
                        (0.1 * 255).round()) // Borda sutil para lidas no escuro
                    : theme.dividerColor.withAlpha(
                        (0.5 * 255).round()) // Borda padrão para lidas no claro
                : notification.color.withAlpha(
                    (0.5 * 255).round()), // Borda mais visível para não lidas
            width: notification.isRead ? 0.5 : 1.0, // Largura da borda
          ),
        ),
        child: InkWell(
          // Torna o item inteiro clicável com feedback visual (efeito ripple)
          onTap: () {
            _handleNotificationTap(
                notification); // Chama o método para manipular o toque
          },
          borderRadius:
              BorderRadius.circular(16), // Aplica o border radius ao InkWell
          child: Padding(
            padding: const EdgeInsets.all(12), // Padding interno do item
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone da notificação
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.color.withAlpha((0.2 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color:
                        notification.color, // Usa a cor definida na notificação
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12), // Espaço entre ícone e texto
                Expanded(
                  // Garante que o texto ocupe o espaço restante
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            // Garante que o título não empurre o indicador de lida para fora
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          // Indicador de notificação não lida (ponto)
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification
                                    .color, // Usa a cor da notificação
                                shape: BoxShape.circle,
                              ),
                              margin: const EdgeInsets.only(
                                  left: 8), // Espaço à esquerda do ponto
                            )
                        ],
                      ),
                      const SizedBox(
                          height: 4), // Espaço entre título e descrição
                      Text(
                        notification.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withAlpha((0.7 * 255)
                                  .round()) // Cor para descrição no modo escuro
                              : theme.colorScheme.onSurface.withAlpha((0.7 *
                                      255)
                                  .round()), // Cor para descrição no modo claro
                        ),
                        maxLines: 3, // Limita o número de linhas da descrição
                        overflow: TextOverflow
                            .ellipsis, // Adiciona reticências se exceder
                      ),
                      const SizedBox(
                          height: 8), // Espaço entre descrição e hora
                      Text(
                        notification
                            .relativeTime, // Ex: "agora", "2 horas atrás" (precisa ser calculado no NotificationItem)
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withAlpha((0.5 * 255)
                                  .round()) // Cor para hora no modo escuro
                              : theme.colorScheme.onSurface.withAlpha(
                                  (0.5 * 255)
                                      .round()), // Cor para hora no modo claro
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método para manipular toques em notificações (Novo Método)
  void _handleNotificationTap(NotificationItem notification) {
    // Primeiro marca como lida (o ValueListenableBuilder reconstruirá a lista)
    _notificationService.markAsRead(notification.id);

    // Fecha o overlay antes de navegar para evitar problemas de contexto
    Navigator.pop(context);

    // Em seguida, direciona o usuário com base no tipo de notificação ou dados específicos
    switch (notification.type) {
      case NotificationType.report:
        // Exemplo: Ir para o relatório do mês específico
        // Assume que o campo 'data' na notificação tem 'month' e 'year'
        if (notification.data.containsKey('month') &&
            notification.data.containsKey('year')) {
          Navigator.of(context).pushNamed(
            '/report', // Substitua pela rota correta do seu relatório
            arguments: {
              'month': notification.data['month'],
              'year': notification.data['year'],
            },
          );
        } else {
          // Fallback para a tela geral de relatórios se faltarem dados
          Navigator.of(context).pushNamed('/report');
        }
        break;

      case NotificationType.warning:
      case NotificationType.alert:
        // Exemplo: Se for alerta de orçamento, vai para a tela de orçamentos
        if (notification.id.startsWith('budget_')) {
          Navigator.of(context).pushNamed(
              '/budget/list'); // Substitua pela rota correta de orçamentos
        } else {
          // Fallback para o dashboard ou outra tela relevante para alertas
          Navigator.of(context).pushNamed('/dashboard');
        }
        break;

      case NotificationType.achievement:
        // Exemplo: Mostrar um diálogo com detalhes da conquista
        _showAchievementDetails(notification);
        break;

      case NotificationType.success:
        // Exemplo: Se for meta atingida, ir para tela de metas
        if (notification.id.startsWith('goal_complete_')) {
          Navigator.of(context)
              .pushNamed('/goals'); // Substitua pela rota correta de metas
        } else {
          Navigator.of(context).pushNamed('/dashboard'); // Fallback
        }
        break;

      case NotificationType.reminder:
        // Exemplo: Se for pagamento próximo, ir para despesas
        if (notification.id.startsWith('payment_due_')) {
          Navigator.of(context)
              .pushNamed('/costs'); // Substitua pela rota correta de despesas
        } else {
          Navigator.of(context).pushNamed('/dashboard'); // Fallback
        }
        break;

      case NotificationType.tip:
        // Exemplo: Ir para tela de dicas
        Navigator.of(context)
            .pushNamed('/tips'); // Substitua pela rota correta de dicas
        break;

      default:
        // Por padrão, vai para o dashboard se o tipo não for reconhecido ou não tiver ação específica
        Navigator.of(context).pushNamed('/dashboard');
        break;
    }
  }

  // Método para mostrar detalhes de uma conquista (Novo Método)
  void _showAchievementDetails(NotificationItem notification) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark; // Verifica o brilho do tema atual

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1A1A1A)
              : theme.cardColor, // Cor de fundo
          title: Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: notification.color ??
                    Colors.amber, // Usa a cor da notificação ou âmbar padrão
              ),
              const SizedBox(width: 8),
              Expanded(
                // Garante que o texto não exceda
                child: Text(
                  'Conquista Desbloqueada!', // Título mais genérico para o diálogo
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow
                      .ellipsis, // Adiciona reticências se o título for longo
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Alinha conteúdo à esquerda
            children: [
              // Título específico da conquista (do NotificationItem)
              Text(
                notification.title,
                style: TextStyle(
                  fontSize:
                      16, // Tamanho um pouco menor que o título do diálogo
                  fontWeight: FontWeight.w600, // Peso da fonte
                  color: isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurface
                          .withAlpha((0.9 * 255).round()),
                ),
              ),
              const SizedBox(
                  height: 12), // Espaço entre título e descrição da conquista
              // Descrição da conquista (do NotificationItem)
              Text(
                notification.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white54
                      : theme.colorScheme.onSurface
                          .withAlpha((0.7 * 255).round()),
                ),
              ),
              // Aqui você pode adicionar mais detalhes baseados em notification.data, se necessário
              if (notification.data.containsKey('value'))
                Text('Valor: R\$${notification.data['value']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Fechar',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            // Borda arredondada
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // Adicione este método na classe _HomeScreenState
  void _showHomeScreenHelp(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
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
                    SlideAnimation.fromTop(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6200EE),
                            child: Icon(
                              Icons.help_outline,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Guia da Tela Principal",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Conhecendo todas as funcionalidades",
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
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção 1: Barra Superior de Notificações
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        title: "1. Barra de Navegação Superior",
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.deepPurple,
                        content:
                            "Na parte superior do aplicativo você encontra:\n\n"
                            "• Ícone de Notificações: Mostra alertas importantes sobre suas finanças\n\n"
                            "• Botão de Busca: Encontre rapidamente qualquer funcionalidade",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Categorias
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        title: "2. Categorias",
                        icon: Icons.category,
                        iconColor: const Color.fromARGB(255, 15, 111, 201),
                        content:
                            "As categorias ajudam a filtrar as funcionalidades disponíveis:\n\n"
                            "• Principais: Mostra todas as funcionalidades\n"
                            "• Financeiro: Filtra por opções de controle financeiro\n"
                            "• Gestão: Mostra opções para gerenciar seus dados\n"
                            "• Relatórios: Exibe opções de relatórios e análises",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Grid de Funcionalidades
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        title: "3. Funcionalidades",
                        icon: Icons.apps,
                        iconColor: Colors.orange,
                        content:
                            "O grid central mostra todas as funcionalidades disponíveis:\n\n"
                            "• Orçamentos: Gerencie seus orçamentos mensais\n"
                            "• Despesas: Registre e controle seus gastos\n"
                            "• Receitas: Adicione suas fontes de renda\n"
                            "• Dashboard: Visualize seu panorama financeiro\n"
                            "• Relatórios: Acesse relatórios detalhados\n"
                            "• Produtos: Gerencie seus itens cadastrados\n"
                            "• Dicas: Receba conselhos financeiros\n"
                            "• Tendências: Analise padrões de gastos e receitas",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Alternador de Visualização
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        title: "4. Modo de Visualização",
                        icon: Icons.view_list,
                        iconColor: Colors.teal,
                        content:
                            "Você pode alternar entre dois modos de visualização:\n\n"
                            "• Grade (ícone de grade): Visualização compacta em blocos\n\n"
                            "• Lista (ícone de lista): Visualização detalhada em formato de lista, com descrições",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Barra de Navegação Inferior
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        title: "5. Barra de Navegação Inferior",
                        icon: Icons.menu,
                        iconColor: Colors.indigo,
                        content:
                            "Acesso rápido a funcionalidades essenciais:\n\n"
                            "• Temas: Personalize a aparência do aplicativo\n"
                            "• Metas: Acesse suas metas financeiras\n"
                            "• Saldo: Visualize seu saldo atual detalhado\n"
                            "• Dicas: Receba conselhos financeiros úteis",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6200EE)
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6200EE)
                                .withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: const Color(0xFF6200EE),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6200EE),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Clique no ícone de ajuda em cada tela para obter guias detalhados de como usar cada funcionalidade!",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão para fechar
                    Center(
                      child: ScaleAnimation.bounceIn(
                        delay: const Duration(milliseconds: 700),
                        child: PressableCard(
                          onPress: () => Navigator.pop(context),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6200EE),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Entendi!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  // Método para exibir a ajuda do card financeiro com animações
  void _showFinancialCardHelp(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
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
                    SlideAnimation.fromTop(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6200EE),
                            child: Icon(
                              Icons.insights,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Entendendo seu Resumo Financeiro",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Um guia simples para entender seus números",
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
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Explicação do Saldo Atual
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        title: "1. Saldo Atual",
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.green,
                        content:
                            "É o valor total que você possui atualmente.\n\n"
                            "Calculado como: Receitas totais - Despesas totais.\n\n"
                            "Este valor mostra rapidamente se você está no positivo ou negativo.",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Explicação da Variação Percentual
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        title: "2. Variação Percentual",
                        icon: Icons.trending_up,
                        iconColor: Colors.blue,
                        content:
                            "O número com seta (ex: +12.5%) mostra como seu saldo está mudando.\n\n"
                            "• Seta VERDE para cima: sua situação está melhorando\n"
                            "• Seta VERMELHA para baixo: precisa de atenção\n\n"
                            "É calculada comparando seu saldo atual com o do período anterior.",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Explicação das Barras de Progresso
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        title: "3. Barras de Progresso",
                        icon: Icons.bar_chart,
                        iconColor: Colors.orange,
                        content:
                            "As barras mostram o andamento dos seus gastos e economias.\n\n"
                            "• Meta de Economia: quanto você já alcançou da meta de economia (30% da receita total)\n\n"
                            "• Gastos do Orçamento: quanto você já gastou do orçamento planejado (70% da receita total)",
                      ),
                    ),

                    const SizedBox(height: 20),

                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        title: "4. Funcionalidade",
                        icon: Icons.bar_chart,
                        iconColor: const Color.fromARGB(255, 231, 16, 177),
                        content:
                            "•A tela pode ser vista em gri ou lista basta clicar no icone do lado direito acima dos filtros.\n\n"
                            "• Você pode optar por usar filtros para ver apenas as funcionalidades que você que no momento\n\n"
                            "• No rodapé da pagina você tem 4 icones, explore e se precisar de ajuda pra enteder clique no simbólo de INTERROGAÇÃO no topo da tela",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6200EE)
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6200EE)
                                .withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: const Color(0xFF6200EE),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6200EE),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Toque no card de resumo financeiro para ver mais detalhes no Dashboard completo!",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão para fechar
                    Center(
                      child: ScaleAnimation.bounceIn(
                        delay: const Duration(milliseconds: 600),
                        child: PressableCard(
                          onPress: () => Navigator.pop(context),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6200EE),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Entendi!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  // Widget para cada seção da ajuda
  Widget _buildHelpSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.05 * 255).round()),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Retorna o ícone apropriado para cada índice de funcionalidade
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.account_balance_wallet; // Orçamento
      case 1:
        return Icons.money_off; // Despesas
      case 2:
        return Icons.attach_money; // Receitas
      case 3:
        return Icons.dashboard; // Dashboard
      case 4:
        return Icons.bar_chart; // Relatórios
      case 5:
        return Icons.inventory_2; // Gerenciar Produtos
      case 6:
        return Icons.lightbulb_outline; // Dicas
      case 7:
        return Icons.trending_up; // Tendências
      default:
        return Icons.apps;
    }
  }
}

// Delegado de busca
class AppSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        border: InputBorder.none, // Remove a borda padrão
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            themeManager.getCurrentPrimaryColor(), // Usa a cor primária do tema
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        titleTextStyle: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold),
      ),
      // Adiciona a cor de fundo do Scaffold para a tela de busca
      scaffoldBackgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
    );
  }

  final List<String> _searchItems = [
    'Orçamentos',
    'Despesas',
    'Receitas',
    'Dashboard',
    'Relatórios',
    'Gerenciar Produtos',
    'Dicas Importantes',
    'Tendências',
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return [
      IconButton(
        icon:
            Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.black54),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return IconButton(
      icon: Icon(Icons.arrow_back,
          color: isDark ? Colors.white70 : Colors.black54),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchItems
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _buildSearchResults(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.currentThemeType != ThemeType.light;
    final suggestionColor = isDark ? Colors.white70 : Colors.black87;

    if (query.isEmpty) {
      // Pode retornar pesquisas recentes aqui, se houver
      return ListView(
        children: [
          ListTile(
            leading: Icon(Icons.search,
                color: isDark ? Colors.white54 : Colors.black45),
            title: Text('Digite sua busca',
                style: TextStyle(color: suggestionColor)),
          )
        ],
      );
    }

    final results = _searchItems
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _buildSearchResults(context, results);
  }

  Widget _buildSearchResults(BuildContext context, List<String> results) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64,
                color: themeManager
                    .getCurrentPrimaryColor()
                    .withAlpha((0.5 * 255).round())),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? Colors.white.withAlpha((0.7 * 255).round())
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha((0.7 * 255).round())),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(
            Icons.search,
            color: isDark
                ? Colors.white70
                : themeManager
                    .getCurrentPrimaryColor()
                    .withAlpha((0.7 * 255).round()),
          ),
          title: Text(
            results[index],
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onTap: () {
            Navigator.pop(context); // Fecha a busca
            Navigator.pushNamed(
              context,
              _getRouteFromSearchResult(results[index]),
            );
          },
        );
      },
    );
  }

  String _getRouteFromSearchResult(String result) {
    // Mapeia os resultados de busca para rotas
    switch (result.toLowerCase()) {
      case 'orçamentos':
        return '/budget/list';
      case 'despesas':
        return '/costs';
      case 'receitas':
        return '/revenues';
      case 'dashboard':
        return '/dashboard';
      case 'relatórios':
        return '/report';
      case 'gerenciar produtos':
        return '/items/manage';
      case 'dicas importantes':
        return '/tips';
      case 'tendências':
        return '/trend';
      case 'metas financeiras':
        return '/goals';
      default:
        return '/home'; // Rota padrão
    }
  }
}

// Painter para o fundo com padrão geométrico suave e não piscante
class _SafeBackgroundPatternPainter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;
  final math.Random random = math.Random(42); // Seed fixo para padrão estático

  _SafeBackgroundPatternPainter({
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shapePaint = Paint()
      ..color = isDark
          ? Colors.white
              .withAlpha((0.05 * 255).round()) // Mais sutil no dark mode
          : primaryColor
              .withAlpha((0.05 * 255).round()) // Mais sutil no light mode
      ..style = PaintingStyle.fill;

    // Criar padrão de formas geométricas não piscantes
    // Triângulos, círculos e quadrados suaves

    // Grade de formas de fundo fixa (não animada)
    final cellSize = size.width / 7;

    for (int i = -1; i < 10; i++) {
      for (int j = -1; j < 20; j++) {
        final x = i * cellSize + random.nextDouble() * (cellSize * 0.3);
        final y = j * cellSize + random.nextDouble() * (cellSize * 0.3);

        final shapeType = (i + j) % 3;

        switch (shapeType) {
          case 0:
            // Círculo
            final radius = cellSize * (0.1 + random.nextDouble() * 0.1);
            canvas.drawCircle(Offset(x, y), radius, shapePaint);
            break;
          case 1:
            // Retângulo
            final rect = Rect.fromCenter(
              center: Offset(x, y),
              width: cellSize * (0.1 + random.nextDouble() * 0.15),
              height: cellSize * (0.1 + random.nextDouble() * 0.15),
            );
            canvas.drawRect(rect, shapePaint);
            break;
          case 2:
            // Linha diagonal
            final path = Path();
            path.moveTo(x - cellSize * 0.1, y - cellSize * 0.1);
            path.lineTo(x + cellSize * 0.1, y + cellSize * 0.1);
            canvas.drawPath(path, shapePaint..strokeWidth = 2);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SafeBackgroundPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.primaryColor != primaryColor;
}

extension GlassContainerExtension on GlassContainer {
  static GlassContainer create({
    required Widget child,
    double borderRadius = 16,
    double opacity = 0.1,
    Color? borderColor,
  }) {
    return GlassContainer(
      borderRadius: borderRadius,
      opacity: opacity,
      borderColor: borderColor,
      child: child,
    );
  }
}
