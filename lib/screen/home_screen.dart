import 'dart:async';

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
import 'package:url_launcher/url_launcher.dart';

// Importar o serviço de notificações e o modelo de notificação (Adicionado)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final GlobalKey<_HomeScreenState> _homeKey =
      GlobalKey<_HomeScreenState>();

  static void refreshHomeData() {
    try {
      final homeState = _homeKey.currentState; // ✅ CORRIGIDO
      if (homeState != null && homeState.mounted) {
        homeState._loadFinancialData();
        debugPrint('✅ HomeScreen atualizada via método estático');
      } else {
        debugPrint('⚠️ HomeScreen não está disponível para atualização');
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar HomeScreen: $e');
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _gridController = ScrollController();
  static const String _lastTipShownKey = 'last_tip_shown_date';

  // Adicionar estes novos elementos
  StreamSubscription<String>? _updateSubscription;
  Timer? _periodicTimer;

  // Returns the route for each functionality index
  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/accounts';
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
      case 9:
        return '/budget/list';
      default:
        return '';
    }
  }

  // Returns the label for each functionality index
  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Contas';
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
      case 9:
        return 'Orçamentos';
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

  bool isLoadingFinancialData = false;

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

    // Configurar a UI do sistema para melhor compatibilidade
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Inicializar o serviço de notificações
    _notificationService.initialize();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
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

    _setupUpdateListeners();

    // NOVO: Timer periódico para atualizações automáticas (opcional)
    _setupPeriodicUpdates();
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

  void _setupUpdateListeners() {
    // Listener para mudanças via SharedPreferences
    _updateSubscription = _watchForUpdates().listen((_) {
      if (mounted) {
        _loadFinancialData();
      }
    });
  }

  // NOVO: Stream que monitora mudanças
  Stream<String> _watchForUpdates() async* {
    String lastUpdate = '';
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentUpdate = prefs.getString('last_finance_update') ?? '';
        if (currentUpdate != lastUpdate && currentUpdate.isNotEmpty) {
          lastUpdate = currentUpdate;
          yield currentUpdate;
        }
      } catch (e) {
        debugPrint('Erro ao verificar atualizações: $e');
      }
    }
  }

  // NOVO: Timer periódico (backup)
  void _setupPeriodicUpdates() {
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 2), // Atualiza a cada 5minutos
      (timer) {
        if (mounted && !isLoadingFinancialData) {
          // ✅ ADICIONAR !isLoadingFinancialData
          debugPrint('⏰ Atualização periódica automática');
          _loadFinancialData();
        }
      },
    );
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

  // MODIFICAR: Método _loadFinancialData para incluir mais logs
  Future<void> _loadFinancialData() async {
    // Evitar múltiplas execuções simultâneas
    if (isLoadingFinancialData) {
      debugPrint('⚠️ Carregamento já em andamento, ignorando nova solicitação');
      return;
    }

    if (mounted) {
      setState(() {
        isLoadingFinancialData = true;
      });
    }

    try {
      debugPrint('🔄 Atualizando dados financeiros...');

      // Obter receitas e despesas
      final costs = await _costsService.getAllCosts();
      final revenues = await _revenuesService.getAllRevenues();

      debugPrint('💰 Receitas encontradas: ${revenues.length}');
      debugPrint('💸 Despesas encontradas: ${costs.length}');

      // Calcular saldo total
      final totalCosts = costs.fold<double>(0, (sum, cost) => sum + cost.preco);
      final totalRevenues =
          revenues.fold<double>(0, (sum, revenue) => sum + revenue.preco);

      debugPrint('💰 Total receitas: R\$ ${totalRevenues.toStringAsFixed(2)}');
      debugPrint('💸 Total despesas: R\$ ${totalCosts.toStringAsFixed(2)}');

      // Armazenar o saldo anterior
      _previousBalance = _currentBalance;
      final newBalance = totalRevenues - totalCosts;

      // Calcular variação percentual
      if (_previousBalance != 0) {
      } else if (newBalance > 0) {}

      // Calcular progresso de metas
      final savingsGoal = totalRevenues * 0.3;
      final currentSavings = newBalance > 0 ? newBalance : 0; // ✅ CORRIGIDO
      final expensesBudget = totalRevenues * 0.7;

      if (mounted) {
        setState(() {
          _currentBalance = newBalance;

          _savingsGoalProgress = savingsGoal > 0
              ? (currentSavings / savingsGoal).clamp(0.0, 1.0)
              : 0.0;

          _expensesBudgetProgress = expensesBudget > 0
              ? (totalCosts / expensesBudget).clamp(0.0, 1.0)
              : 0.0;
        });

        debugPrint(
            '✅ Dados atualizados - Saldo: R\$ ${newBalance.toStringAsFixed(2)}');
        debugPrint(
            '📊 Progresso economia: ${(_savingsGoalProgress * 100).toStringAsFixed(1)}%');
        debugPrint(
            '📊 Progresso despesas: ${(_expensesBudgetProgress * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados financeiros: $e');
      if (mounted) {
        setState(() {
          _currentBalance = 0.0;
          _savingsGoalProgress = 0.0;
          _expensesBudgetProgress = 0.0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFinancialData = false; // ✅ SEMPRE limpar loading
        });
      }
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
// <-- só aqui!
      });
    } catch (e) {
      debugPrint('Erro ao carregar saldo anterior: $e');
      _previousBalance = _currentBalance * 0.95;
// <-- aqui!
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _periodicTimer?.cancel();
    _pageController.dispose();
    _scrollProgress.dispose();
    _showFloatingPanel.dispose();
    _controller.dispose();
    _gridController.dispose();
    super.dispose();
  }

  // NOVO: Método para forçar atualização (chamado pelos botões)
  void _forceRefresh() {
    debugPrint('🔄 Atualização forçada solicitada');
    _loadFinancialData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = context.watch<ThemeManager>();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding; // ✅ ADICIONAR ESTA LINHA

    // Determinar se estamos no tema escuro para ajustar detalhes visuais
    final isDarkMode = themeManager.currentThemeType != ThemeType.light;

    return ResponsiveScreen(
      key: HomeScreen._homeKey,
      backgroundColor: themeManager.getDashboardHeaderBackgroundColor(),
      appBar: _buildAppBar(theme, isDarkMode, themeManager),
      bottomNavigationBar: buildBottomNavBar(theme, padding),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo decorativo suave (sem animações piscantes)
          Positioned.fill(
            child: _buildSafeFundoGradiente(themeManager),
          ),

          // Conteúdo principal
          // Conteúdo principal com SafeArea apropriado
          Positioned.fill(
            child: SafeArea(
              top: true,
              bottom: false,
              left: true,
              right: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Painel de boas-vindas e resumo financeiro
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    DateTime? lastUpdateTime;
    // Verificar se voltou de outra tela
    // Só atualizar se não estiver já carregando e for necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isLoadingFinancialData && mounted) {
        // Verificar se realmente precisa atualizar
        final now = DateTime.now();
        if (lastUpdateTime == null ||
            now.difference(lastUpdateTime!).inSeconds > 5) {
          lastUpdateTime = now;
          _loadFinancialData();
        }
      }
    });
  }

  DateTime? lastUpdateTime;
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
  // Barra de navegação inferior
  Widget buildBottomNavBar(ThemeData theme, EdgeInsets padding) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
                child: Icon(Icons.palette, color: theme.colorScheme.primary),
              ),
              label: 'Temas',
            ),
            BottomNavigationBarItem(
              icon: ScaleAnimation.bounceIn(
                child: Icon(Icons.flag, color: theme.colorScheme.primary),
              ),
              label: 'Metas',
            ),
            // BOTÃO CENTRAL ÉPICO! 🎯
            BottomNavigationBarItem(
              icon: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ScaleAnimation.bounceIn(
                  child: Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: ScaleAnimation.bounceIn(
                child: Icon(Icons.account_balance,
                    color: theme.colorScheme.primary),
              ),
              label: 'Saldo',
            ),
            BottomNavigationBarItem(
              icon: ScaleAnimation.bounceIn(
                child:
                    Icon(Icons.emoji_events, color: theme.colorScheme.primary),
              ),
              label: 'Conquistas',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                _showThemeSelector(context);
                break;
              case 1:
                Navigator.pushNamed(context, '/goals');
                break;
              case 2:
                // 🎭 MENU ÉPICO!
                _showCentralMenu(context);
                break;
              case 3:
                Navigator.pushNamed(context, '/balance');
                break;
              case 4:
                // 🏆 GALERIA DE CONQUISTAS!
                Navigator.pushNamed(context, '/achievements');
                break;
            }
          },
        ),
      ),
    );
  }

  void _showCentralMenu(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = context.read<ThemeManager>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CentralMenuBottomSheet(
        theme: theme,
        themeManager: themeManager,
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // ADICIONA ESTA LINHA
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom, // ADICIONA ESTE PADDING
        ),
        child: const ThemeSelector(),
      ),
    );
  }

  // Fundo com gradiente suave e padrão discreto
  Widget _buildSafeFundoGradiente(ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return Stack(
      children: [
        // Gradiente base - CORRIGIDO PARA USAR AS CORES CORRETAS
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      // ROXO: Gradiente roxo com branco (igual ao preto com branco)
                      themeManager
                          .getDashboardHeaderBackgroundColor(), // Roxo puro
                      themeManager
                          .getDashboardHeaderBackgroundColor()
                          .withAlpha((0.7 * 255).round()), // Roxo mais claro
                      Colors.white
                          .withAlpha((0.05 * 255).round()), // Branco bem suave
                      Colors.white.withAlpha(
                          (0.02 * 255).round()), // Branco quase invisível
                    ]
                  : [
                      // CLARO: Manter como está (funcionando)
                      themeManager
                          .getCurrentPrimaryColor()
                          .withAlpha((0.05 * 255).round()),
                      Colors.white,
                      themeManager
                          .getCurrentPrimaryColor()
                          .withAlpha((0.02 * 255).round()),
                    ],
            ),
          ),
        ),

        // Padrão de formas geométricas com animação MAIS LENTA
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SafeBackgroundPatternPainter(
                primaryColor: themeManager.getCurrentPrimaryColor(),
                isDark: isDark,
                animationValue: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
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
                              Row(
                                children: [
                                  const Text(
                                    'Seu saldo atual',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  // ADICIONAR: Indicador de loading pequeno
                                  if (isLoadingFinancialData) ...[
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white70),
                                      ),
                                    ),
                                  ],
                                ],
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
                      const SizedBox(height: 8),
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
                            child: Icon(
                              _currentBalance >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: _currentBalance >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProgressIndicator(
                              'Meta de Economia',
                              _savingsGoalProgress,
                              Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProgressIndicator(
                              'Gastos do Orçamento',
                              _expensesBudgetProgress,
                              Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ✅ NOVOS BOTÕES NO TOPO DIREITO
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔄 BOTÃO DE REFRESH
                      PressableCard(
                        onPress: () {
                          debugPrint('🔄 Refresh manual do card financeiro');
                          _forceRefresh();

                          // Feedback visual
                          HapticFeedback.lightImpact();

                          // Mostrar SnackBar de confirmação
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '🔄 Atualizando dados...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              backgroundColor:
                                  themeManager.getCurrentPrimaryColor(),
                              duration: const Duration(milliseconds: 1500),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        pressedScale: 0.85,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: AnimatedRotation(
                          turns: isLoadingFinancialData ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8), // Espaço entre os botões

                      // ❓ BOTÃO DE AJUDA (já existia)
                      PressableCard(
                        onPress: () => _showFinancialCardHelp(context),
                        pressedScale: 0.85,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // ADICIONAR: Overlay de loading para o card inteiro (opcional)
                if (isLoadingFinancialData)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.9 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    themeManager.getCurrentPrimaryColor(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Atualizando...',
                                style: TextStyle(
                                  color: themeManager.getCurrentPrimaryColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
      filteredIndices = List.generate(10, (index) => index);
    } else if (selectedCategoryTab == 1) {
      filteredIndices = [0, 1, 2, 9]; // <-- ADICIONE O 9 AQUI
    } else if (selectedCategoryTab == 2) {
      // Gestão
      filteredIndices = [3, 4, 5, 8];
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
            itemCount: 10,
            itemBuilder: (context, index) {
              // Filtrar por categoria selecionada
              if (selectedCategoryTab != 0) {
                if (selectedCategoryTab == 1 && ![0, 1, 2, 9].contains(index)) {
                  return const SizedBox.shrink();
                } else if (selectedCategoryTab == 2 &&
                    ![3, 4, 5, 8].contains(index)) {
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
        return 'Gerencie suas contas bancárias e cartões de crédito.';
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
      case 9:
        return 'Gerencie seus orçamentos mensais de forma eficiente.';
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
            frostedEffect: true,
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
        return Icons.account_balance_wallet_outlined; //contas
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
      case 8:
        return Icons.flag; // Metas
      case 9: // <-- NOVO ITEM
        return Icons.account_balance_wallet; // Orçamento
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
    'Metas Financeiras',
    'Contas', // <-- NOVO ITEM
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
      case 'contas': // <-- NOVO CASE
        return '/accounts';
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
      case 'orçamentos':
        return '/budget/list';
      default:
        return '/home'; // Rota padrão
    }
  }
}

// Painter para o fundo com padrão geométrico suave e não piscante
class _SafeBackgroundPatternPainter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;
  final double animationValue; // NOVO: valor da animação
  final math.Random random = math.Random(42); // Seed fixo para padrão estático

  _SafeBackgroundPatternPainter({
    required this.primaryColor,
    required this.isDark,
    required this.animationValue, // NOVO: recebe valor da animação
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shapePaint = Paint()
      ..color = isDark
          ? Colors.white.withAlpha((0.03 * 255).round()) // MAIS SUTIL ainda!
          : primaryColor.withAlpha((0.02 * 255).round()) // MAIS SUTIL ainda!
      ..style = PaintingStyle.fill;

    // Criar padrão de formas geométricas com movimento MUITO mais lento
    final cellSize = size.width / 8;

    for (int i = -1; i < 12; i++) {
      for (int j = -1; j < 25; j++) {
        // Movimento MUITO mais sutil e lento
        final slowMovement = math.sin(animationValue * 2 * math.pi) *
            2.0; // Só 2 pixels de movimento!
        final x = i * cellSize +
            random.nextDouble() * (cellSize * 0.2) +
            slowMovement;
        final y = j * cellSize +
            random.nextDouble() * (cellSize * 0.2) +
            slowMovement * 0.5;

        final shapeType = (i + j) % 4; // Mais variedade de formas

        // Opacidade que varia SUTILMENTE com a animação
        final baseOpacity = isDark ? 0.02 : 0.015;
        final animatedOpacity =
            baseOpacity + (math.sin(animationValue * 2 * math.pi) * 0.005);

        shapePaint.color = isDark
            ? Colors.white.withAlpha((animatedOpacity * 255).round())
            : primaryColor.withAlpha((animatedOpacity * 255).round());

        switch (shapeType) {
          case 0:
            // Círculos menores e mais suaves
            canvas.drawCircle(
              Offset(x, y),
              random.nextDouble() * 3 + 1, // Tamanho reduzido
              shapePaint,
            );
            break;
          case 1:
            // Quadrados menores
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(x, y),
                width: random.nextDouble() * 4 + 2,
                height: random.nextDouble() * 4 + 2,
              ),
              shapePaint,
            );
            break;
          case 2:
            // Triângulos menores
            final path = Path();
            final size = random.nextDouble() * 3 + 1;
            path.moveTo(x, y - size);
            path.lineTo(x - size, y + size);
            path.lineTo(x + size, y + size);
            path.close();
            canvas.drawPath(path, shapePaint);
            break;
          case 3:
            // Linhas curtas e sutis
            canvas.drawLine(
              Offset(x - 2, y),
              Offset(x + 2, y),
              shapePaint..strokeWidth = 0.5,
            );
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SafeBackgroundPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.animationValue !=
          animationValue; // NOVO: repinta quando animação muda
}

extension GlassContainerExtension on GlassContainer {
  static GlassContainer create({
    required Widget child,
    double borderRadius = 16,
    double opacity = 0.1,
    Color? borderColor,
  }) {
    return GlassContainer(
      frostedEffect: true,
      borderRadius: borderRadius,
      opacity: opacity,
      borderColor: borderColor,
      child: child,
    );
  }
}

class _CentralMenuBottomSheet extends StatefulWidget {
  final ThemeData theme;
  final ThemeManager themeManager;

  const _CentralMenuBottomSheet({
    required this.theme,
    required this.themeManager,
  });

  @override
  State<_CentralMenuBottomSheet> createState() =>
      _CentralMenuBottomSheetState();
}

class _CentralMenuBottomSheetState extends State<_CentralMenuBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _murphyController; // 👻 MURPHY NO MENU!

  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _murphyBounce;

  bool _murphyModeActive = false;
  int _murphyTapCount = 0;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _murphyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _murphyBounce = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _murphyController,
      curve: Curves.elasticInOut,
    ));

    _slideController.forward();
    _bounceController.forward();
  }

  void _activateMurphyMode() {
    _murphyTapCount++;

    if (_murphyTapCount >= 5) {
      setState(() => _murphyModeActive = true);
      _murphyController.repeat(reverse: true);

      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('👻 MURPHY INVADIU O MENU! 💀'),
          backgroundColor: Colors.purple,
          action: SnackBarAction(
            label: '🥜 3 Paçocas',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _murphyModeActive = false;
                _murphyTapCount = 0;
              });
              _murphyController.stop();
              _murphyController.reset();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeManager.currentThemeType != ThemeType.light;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          // ✅ SEMPRE BRANCO (igual tema claro)
          color: Colors
              .white, // Removeu o isDark ? Color(0xFF1A1A1A) : Colors.white
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuHeader(),
            Expanded(child: _buildMenuContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuHeader() {
    final isDark = widget.themeManager.currentThemeType != ThemeType.light;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.theme.colorScheme.primary,
            widget.theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Ícone animado
          ScaleAnimation.bounceIn(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apps,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Título
          Expanded(
            child: SlideAnimation.fromLeft(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menu Principal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Acesse todas as funcionalidades',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 👻 MURPHY SECRETO (Easter Egg)
          GestureDetector(
            onTap: _activateMurphyMode,
            child: AnimatedBuilder(
              animation: _murphyBounce,
              builder: (context, child) {
                return Transform.scale(
                  scale: _murphyModeActive ? _murphyBounce.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _murphyModeActive
                          ? Colors.purple.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _murphyModeActive ? '👻💃' : '🔥',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),

          // Botão fechar
          SlideAnimation.fromRight(
            delay: const Duration(milliseconds: 300),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🎖️ SEÇÃO CONQUISTAS
            _buildMenuSection(
              title: '🏆 Conquistas & Gamificação',
              items: [
                _MenuItemData(
                  icon: Icons.emoji_events,
                  title: 'Galeria de Conquistas',
                  subtitle: 'Veja suas conquistas desbloqueadas',
                  route: '/achievements',
                  color: Colors.amber,
                ),
                _MenuItemData(
                  icon: Icons.flag,
                  title: 'Metas Financeiras',
                  subtitle: 'Defina e acompanhe suas metas',
                  route: '/goals',
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 📱 SEÇÃO APP
            _buildMenuSection(
              title: '📱 Sobre & Suporte',
              items: [
                _MenuItemData(
                  icon: Icons.info_outline,
                  title: 'Sobre o App',
                  subtitle: 'Informações e versão',
                  onTap: () => _showAboutDialog(),
                  color: Colors.blue,
                ),
                _MenuItemData(
                  icon: Icons.star_rate,
                  title: 'Avalie o App',
                  subtitle: 'Deixe sua avaliação na loja',
                  onTap: () => _rateApp(),
                  color: Colors.orange,
                ),
                _MenuItemData(
                  icon: Icons.coffee,
                  title: '🥜 Me pague uma Paçoca',
                  subtitle: 'Apoie o desenvolvedor a continuar seus projetos',
                  onTap: () => _showPacoca(),
                  color: Colors.brown,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItemData> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        SlideAnimation.fromLeft(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.theme.colorScheme.primary,
              ),
            ),
          ),
        ),

        // Items da seção
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return SlideAnimation.fromRight(
            delay: Duration(milliseconds: 200 + (index * 100)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildMenuItem(item),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItemData item) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              if (item.route != null) {
                Navigator.pushNamed(context, item.route!);
              } else if (item.onTap != null) {
                item.onTap!();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.05), // ✅ SEMPRE 0.05
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Ícone
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87, // ✅ SEMPRE PRETO
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600, // ✅ SEMPRE CINZA
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Seta
                  Icon(
                    Icons.chevron_right,
                    color: item.color,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🎭 MÉTODOS DE AÇÃO
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Sobre o Economize'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Versão: 1.0.100'),
            const SizedBox(height: 8),
            const Text('Desenvolvido com ❤️ para ajudar você a economizar!'),
            const SizedBox(height: 8),
            const Text(
                'Agradecimentos especiais aos Testers e usuários que contribuíram com feedback!'),
            const SizedBox(height: 16),
            // Links das políticas
            TextButton.icon(
              icon: const Icon(Icons.privacy_tip, size: 18),
              label: const Text('Política de Privacidade'),
              onPressed: () async {
                const url = 'https://union.dev.br/politica-de-privacidade.html';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('Política de Coleta de Dados'),
              onPressed: () async {
                const url =
                    'https://union.dev.br/politica-de-coleta-de-dados.html';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    const String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.lucianoribeiro.economize';

    try {
      // Tentar abrir a Play Store diretamente (se instalada)
      const String playStoreAppUrl =
          'market://details?id=com.lucianoribeiro.economize';

      if (await canLaunchUrl(Uri.parse(playStoreAppUrl))) {
        await launchUrl(
          Uri.parse(playStoreAppUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback para o navegador
        if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
          await launchUrl(
            Uri.parse(playStoreUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Não foi possível abrir a Play Store';
        }
      }

      // Mostrar feedback de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.open_in_new, color: Colors.white),
                SizedBox(width: 8),
                Text('⭐ Abrindo Play Store...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Fallback: copiar link para clipboard
      await _copyLinkToClipboard(playStoreUrl);
    }
  }

// ✅ MÉTODO AUXILIAR PARA COPIAR LINK
  Future<void> _copyLinkToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.content_copy, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      '📋 Link copiado! Cole no navegador para avaliar o app'),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erro ao copiar link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPacoca() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Text('🥜 Me Pague \numa Paçoquinha'),
            const Spacer(),
            // Easter egg: contador de paçocas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.brown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💰 PIX',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone animado da paçoca
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '🥜',
                style: TextStyle(fontSize: 48),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Adoro paçocas e cafezinhos!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Apoie o desenvolvimento do app com qualquer valor! 🚀',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              '(Cada paçoca nos motiva a continuar!)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Container com o PIX
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.pix, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'PIX:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    'lucianofloripa@outlook.com',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Aviso divertido
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ('I love paçocas, mas não sou rico! Qualquer valor é bem-vindo! 🥜'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('🚪 Sair sem pagar'),
          ),
          ElevatedButton.icon(
            onPressed: () => _copyPixToClipboard(),
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('📋 Copiar PIX'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

// ✅ MÉTODO PARA COPIAR O PIX (ADICIONAR APÓS _showPacoca):
  Future<void> _copyPixToClipboard() async {
    const String pixKey = 'lucianofloripa@outlook.com';

    try {
      await Clipboard.setData(const ClipboardData(text: pixKey));

      // Fechar o dialog primeiro
      Navigator.pop(context);

      // Mostrar confirmação com estilo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🥜', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 PIX copiado com sucesso!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Cole no seu app de pagamentos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.brown,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: '🥜 Valeu!',
              textColor: Colors.white,
              onPressed: () {
                // Fechar o SnackBar
              },
            ),
          ),
        );
      }

      // Vibração de sucesso
      HapticFeedback.lightImpact();
    } catch (e) {
      // Em caso de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('❌ Erro ao copiar PIX'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    _murphyController.dispose();
    super.dispose();
  }
}

// 📋 CLASSE DE DADOS PARA ITEMS DO MENU
class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  final VoidCallback? onTap;
  final Color color;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.onTap,
    required this.color,
  });
}
