import 'package:economize/accounts/enum/account_type.dart';
import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/loading_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/theme/app_colors.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen>
    with SingleTickerProviderStateMixin {
  List<Costs> listCosts = [];
  List<Revenues> listRevenues = [];
  double totalCosts = 0.0;
  double totalRevenues = 0.0;
  double averageCosts = 0.0;
  double averageRevenues = 0.0;
  double saldo = 0.0;
  int selectedMonth = DateTime.now().month; // Mês atual como padrão
  bool _isLoading = true;
  bool _showSuccessMessage = false;
  bool _showCharts = false;
  bool _pulseInfo = false;

  late CurrencyService _currencyService;

  // chaves para tutorial

  final GlobalKey _helpKey = GlobalKey();

  // Controladores de animação
  late AnimationController _chartAnimationController;
  final List<GlobalKey> _chartKeys = [GlobalKey(), GlobalKey()];

  String? _selectedAccountId;
  String _selectedTipo = 'receitas'; // receitas ou despesas
  DateTimeRange? _selectedPeriod;
  String? _selectedCategoria; // tipo de receita ou despesa

  List<Account> _accounts = [];
  List<Revenues> _filteredRevenues = [];
  List<Costs> _filteredCosts = [];
  bool _isLoadingCard = false;

  List<String> monthList = [
    'Todas',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _currencyService = context.read<CurrencyService>();
    _loadAccounts();
    _loadFilteredData();
    _loadAccounts();
    _loadFilteredData();

    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    loadData();

    // Inicia animação de entrada dos gráficos após carregar
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _showCharts = true;
      });
    });

    // Inicia animação de pulsar no saldo após 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _pulseInfo = true;
      });
    });
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final accounts = await AccountService().getAllAccounts();
    setState(() {
      _accounts = accounts;
      if (_accounts.isNotEmpty && _selectedAccountId == null) {
        _selectedAccountId = _accounts.first.id?.toString();
      }
    });
  }

  // ✅ TAMBÉM CORRIGIR O MÉTODO _loadFilteredData para garantir que carregue dados:
  Future<void> _loadFilteredData() async {
    setState(() => _isLoadingCard = true);

    try {
      if (_selectedTipo == 'receitas') {
        final revenues = await RevenuesService().getAllRevenues();
        _filteredRevenues = revenues.where((r) {
          // ✅ CORRIGIR: Converter accountId para String para comparação
          final matchAccount = _selectedAccountId == null ||
              (r.accountId != null &&
                  r.accountId.toString() == _selectedAccountId);
          final matchCategoria =
              _selectedCategoria == null || r.tipoReceita == _selectedCategoria;
          final matchPeriodo = _selectedPeriod == null ||
              (r.data.isAfter(_selectedPeriod!.start
                      .subtract(const Duration(days: 1))) &&
                  r.data.isBefore(
                      _selectedPeriod!.end.add(const Duration(days: 1))));
          return matchAccount && matchCategoria && matchPeriodo;
        }).toList();
      } else {
        final costs = await CostsService().getCostsForCalculations();
        _filteredCosts = costs.where((c) {
          // ✅ CORRIGIR: Converter accountId para String para comparação
          final matchAccount = _selectedAccountId == null ||
              (c.accountId != null &&
                  c.accountId.toString() == _selectedAccountId);
          final matchCategoria =
              _selectedCategoria == null || c.tipoDespesa == _selectedCategoria;
          final matchPeriodo = _selectedPeriod == null ||
              (c.data.isAfter(_selectedPeriod!.start
                      .subtract(const Duration(days: 1))) &&
                  c.data.isBefore(
                      _selectedPeriod!.end.add(const Duration(days: 1))));
          return matchAccount && matchCategoria && matchPeriodo;
        }).toList();
      }
    } catch (e) {
      Logger().e('Erro ao carregar dados filtrados: $e');
      // Garantir que as listas não sejam nulas
      if (_selectedTipo == 'receitas') {
        _filteredRevenues = [];
      } else {
        _filteredCosts = [];
      }
    }

    setState(() => _isLoadingCard = false);
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final costsService = CostsService();
      final revenuesService = RevenuesService();

      final costs = await costsService.getCostsForCalculations();
      final revenues = await revenuesService.getAllRevenues();

      if (mounted) {
        setState(() {
          listCosts = costs;
          listRevenues = revenues;

          totalCosts = listCosts.fold(0.0, (sum, item) => sum + item.preco);
          totalRevenues =
              listRevenues.fold(0.0, (sum, item) => sum + item.preco);

          averageCosts =
              listCosts.isNotEmpty ? totalCosts / listCosts.length : 0.0;
          averageRevenues = listRevenues.isNotEmpty
              ? totalRevenues / listRevenues.length
              : 0.0;

          saldo = totalRevenues - totalCosts;

          _isLoading = false;

          // Mostra mensagem de sucesso brevemente
          _showSuccessMessage = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showSuccessMessage = false;
              });
            }
          });
        });
      }
    } catch (e) {
      Logger().e('Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Função para filtrar receitas por mês
  List<Revenues> filterRevenuesByMonth(int month) {
    return listRevenues.where((revenues) {
      // A data já é DateTime, não precisa fazer parse
      return revenues.data.month == month;
    }).toList();
  }

  // Função para filtrar despesas por mês
  List<Costs> _filterCostsByMonth(int month) {
    return listCosts.where((cost) {
      // Agora cost.data já é DateTime, não precisa fazer parse
      return cost.data.month == month;
    }).toList();
  }

  // Modifique o método _filterAllCosts
  List<Costs> _filterAllCosts(int month) {
    if (month == 1) {
      // 1 representa a opção "Todas"
      return listCosts; // Retorna todas as despesas
    } else {
      return _filterCostsByMonth(month); // Usa o filtro por mês existente
    }
  }

  // Função para calcular o total de receitas por tipo
  Map<String, double> _calculateRevenuesByType(List<Revenues> revenues) {
    Map<String, double> revenuesByType = {};
    for (var revenues in revenues) {
      revenuesByType[revenues.tipoReceita] =
          (revenuesByType[revenues.tipoReceita] ?? 0) + revenues.preco;
    }
    return revenuesByType;
  }

  // Função para calcular o total de despesas por tipo
  Map<String, double> _calculateCostsByType(List<Costs> costs) {
    Map<String, double> costsByType = {};
    for (var cost in costs) {
      costsByType[cost.tipoDespesa] =
          (costsByType[cost.tipoDespesa] ?? 0) + cost.preco;
    }
    return costsByType;
  }

  void _refreshDashboard() {
    // Efeito de ondas ao tocar no FAB
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AnimatedCheckmark(size: 24, color: Colors.white),
            const SizedBox(width: 8),
            Text('Atualizando dashboard...',
                style: TextStyle(color: AppColors.textOnPrimary)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    // Esconde os charts para mostrar a animação de entrada novamente
    setState(() {
      _showCharts = false;
    });

    loadData();

    // Mostra charts novamente com animação após carregar
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showCharts = true;
        });
      }
    });
  }

  // Exibe a celebração conforme o saldo
  void _showCelebrationIfNeeded() {
    debugPrint(
        '🎉 Botão celebração clicado! Saldo: $saldo, Total Custos: $totalCosts, Loading: $_isLoading');

    // ✅ CONDIÇÃO MAIS ROBUSTA
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Aguarde o carregamento dos dados...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (saldo > 0) {
      if (totalCosts > 0 && saldo > totalCosts * 0.5) {
        // Preparar controlador de animação antes de mostrar o diálogo
        final AnimationController confettiController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 3),
        );

        // Se o saldo for maior que 50% das despesas, mostra uma celebração maior
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          builder: (context) {
            // Iniciar animação após construir o widget
            WidgetsBinding.instance.addPostFrameCallback((_) {
              confettiController.forward();
            });

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Confetes
                  IgnorePointer(
                    child: ConfettiAnimation(
                      duration: const Duration(seconds: 3),
                      particleCount: 50,
                      colors: [Colors.green, Colors.blue, AppColors.tertiary],
                      direction: ConfettiDirection.down,
                      speed: 1.2,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      animationController: confettiController,
                    ),
                  ),

                  // Card de mensagem
                  ScaleAnimation.bounceIn(
                    child: Card(
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GoldenShineAnimation(
                              intensity: 0.7,
                              child: const Icon(
                                Icons.celebration,
                                size: 64,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Parabéns!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Suas finanças estão equilibradas! Continue assim.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                // Garantir que o controlador seja descartado ao fechar
                                confettiController.dispose();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Fechar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ).then((_) {
          // Garantir que o controlador seja descartado mesmo se o usuário fechar
          // o diálogo clicando fora dele
          if (confettiController.isAnimating) {
            confettiController.stop();
          }
          if (!confettiController.isDismissed) {
            confettiController.dispose();
          }
        });
      } else {
        // Se o saldo for positivo mas não tão expressivo, mostre uma celebração mais simples
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.thumb_up, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Saldo positivo! Continue economizando.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (saldo < 0) {
      // Feedback para saldo negativo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Suas despesas estão maiores que suas receitas. Considere reduzir alguns gastos.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Feedback para quando está carregando ou saldo é zero
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Sem dados financeiros para celebrar ainda.'),
            ],
          ),
          backgroundColor: Colors.blueGrey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = context.watch<ThemeManager>();

    // Substitui Scaffold por ResponsiveScreen
    return ResponsiveScreen(
      appBar: AppBar(
        title: SlideAnimation.fromLeft(
          distance: 0.3,
          duration: const Duration(milliseconds: 600),
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 24),
              const SizedBox(width: 8),
              Text(
                'Dashboard',
                style: TextStyle(
                  color: themeManager.getDashboardHeaderTextColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: themeManager.getDashboardHeaderBackgroundColor(),
        elevation: 0,
        actions: [
          SlideAnimation.fromRight(
            distance: 0.3,
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshDashboard,
              tooltip: 'Atualizar dashboard',
              color: themeManager.getDashboardHeaderIconColor(),
            ),
          ),
          SlideAnimation.fromRight(
            distance: 0.3,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: _helpKey, // Chave para tutorial
              tooltip: 'Ajuda', // Texto do tooltip
              icon: Icon(
                Icons.help_outline, // Ícone de ajuda
                color: themeManager
                    .getDashboardHeaderIconColor(), // ✅ USAR COR DINÂMICA
              ),
              onPressed: () =>
                  _showDashboardHelp(context), // Chama o método de ajuda
            ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: ScaleAnimation.bounceIn(
        delay: const Duration(milliseconds: 800),
        child: FloatingActionButton(
          onPressed: () => _showCelebrationIfNeeded(),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.celebration),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      resizeToAvoidBottomInset: true,
      child: _isLoading
          ? Center(
              child: BrandLoadingAnimation(
                size: 100,
                primaryColor: theme.colorScheme.primary,
                secondaryColor: theme.colorScheme.secondary,
              ),
            )
          : Stack(
              children: [
                // Conteúdo principal
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // Mensagem de sucesso animada
                        if (_showSuccessMessage)
                          SlideAnimation.fromTop(
                            distance: 0.5,
                            child: FadeAnimation(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green
                                      .withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedCheckmark(
                                      size: 24,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Dashboard atualizado com sucesso!',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Card de Informações Animado
                        _pulseInfo
                            ? PulseAnimation(
                                duration: const Duration(seconds: 2),
                                minScale: 0.98,
                                maxScale: 1.02,
                                child: _buildInfoCard(theme),
                              )
                            : ScaleAnimation.bounceIn(
                                delay: const Duration(milliseconds: 300),
                                child: _buildInfoCard(theme),
                              ),

                        // Gráfico de Receitas
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SlideAnimation.fromLeft(
                            distance: 0.3,
                            delay: const Duration(milliseconds: 500),
                            child: FadeAnimation.fadeIn(
                              delay: const Duration(milliseconds: 500),
                              child: Text(
                                'Receitas por tipo x Ano',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Chart 1 com key para animação
                        _showCharts
                            ? SlideAnimation.fromRight(
                                key: _chartKeys[0],
                                distance: 1.0,
                                delay: const Duration(milliseconds: 600),
                                child: _buildPieChart(
                                    listRevenues, 'Receitas Anuais'),
                              )
                            : const SizedBox(height: 228), // Placeholder
                        // Espaço no final
                        const SizedBox(height: 24),

                        // NOVO CARD DE CONTAS COM FILTROS (coloque aqui!)
                        _buildAccountFilterCard(themeManager),

                        // Filtro de meses
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: SlideAnimation.fromLeft(
                            distance: 0.3,
                            delay: const Duration(milliseconds: 700),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tipo despesa x Mês',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PressableCard(
                                  onPress: () {},
                                  pressedScale: 0.95,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 1,
                                      ),
                                    ),
                                    child: DropdownButton<int>(
                                      value: selectedMonth,
                                      underline: Container(),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: theme.colorScheme.primary,
                                      ),
                                      dropdownColor: theme.colorScheme.surface,
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface),
                                      items: monthList
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        return DropdownMenuItem<int>(
                                          value: entry.key + 1,
                                          child: Text(entry.value),
                                        );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedMonth = newValue;

                                            // Esconde momentaneamente o gráfico
                                            _showCharts = false;
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 100), () {
                                              setState(() {
                                                _showCharts = true;
                                              });
                                            });
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Chart 2 com key para animação
                        _showCharts
                            ? SlideAnimation.fromLeft(
                                key: _chartKeys[1],
                                distance: 1.0,
                                delay: const Duration(milliseconds: 800),
                                child: _buildPieChart(
                                  _filterAllCosts(selectedMonth),
                                  selectedMonth == 1
                                      ? 'Todas as Despesas'
                                      : 'Despesas Mensais',
                                ),
                              )
                            : const SizedBox(height: 228), // Placeholder

                        // Espaço no final
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),

                // Overlay para status de saldo
                if (saldo > 0 && !_isLoading)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ScaleAnimation.bounceIn(
                      delay: const Duration(seconds: 1),
                      child: GoldenShineAnimation(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withAlpha((0.2 * 255).round()),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Saldo positivo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Overlay para alerta de saldo negativo
                if (saldo < 0 && !_isLoading)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ScaleAnimation.bounceIn(
                      delay: const Duration(seconds: 1),
                      child: PulseAnimation(
                        minScale: 0.95,
                        maxScale: 1.05,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withAlpha((0.2 * 255).round()),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Atenção: Saldo negativo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
    );
  }

  // Adicione este método na classe DashBoardScreenState
  void _showDashboardHelp(BuildContext context) {
    final themeManager = context.read<ThemeManager>();
    Theme.of(context);

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
                            backgroundColor: themeManager
                                .getDashboardHeaderBackgroundColor(),
                            child: Icon(
                              Icons.analytics_outlined,
                              color: themeManager.getDashboardHeaderTextColor(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dashboard Financeiro",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Visualizando seus dados financeiros",
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

                    // Seção 1: Resumo Financeiro
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Resumo Financeiro",
                        icon: Icons.bar_chart,
                        iconColor:
                            themeManager.getDashboardHeaderBackgroundColor(),
                        content:
                            "O card de resumo apresenta seus dados financeiros gerais:\n\n"
                            "• Receitas: Total de todas as entradas de dinheiro\n\n"
                            "• Despesas: Total de todos os gastos registrados\n\n"
                            "• Médias: Valores médios de receitas e despesas\n\n"
                            "• Saldo: Diferença entre receitas e despesas, destacado em verde (positivo) ou vermelho (negativo)",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Gráfico de Receitas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Gráfico de Receitas",
                        icon: Icons.pie_chart,
                        iconColor: Colors.green,
                        content:
                            "Este gráfico mostra a distribuição de suas receitas por tipo:\n\n"
                            "• Cada fatia representa um tipo diferente de receita\n\n"
                            "• As porcentagens indicam quanto cada tipo representa do total\n\n"
                            "• As cores diferenciam os tipos de receita\n\n"
                            "• Toque no gráfico para ver detalhes completos",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Gráfico de Despesas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Gráfico de Despesas",
                        icon: Icons.pie_chart,
                        iconColor: Colors.red,
                        content:
                            "Este gráfico mostra a distribuição de suas despesas por tipo:\n\n"
                            "• Cada fatia representa um tipo diferente de despesa\n\n"
                            "• As porcentagens indicam quanto cada tipo representa do total\n\n"
                            "• Você pode filtrar por mês usando o seletor acima do gráfico\n\n"
                            "• Toque no gráfico para ver uma análise detalhada",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Filtro de Mês
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Seletor de Mês",
                        icon: Icons.calendar_month,
                        iconColor: Colors.blue,
                        content:
                            "O seletor de mês permite filtrar dados por período:\n\n"
                            "• Selecione 'Todas' para ver despesas de todos os meses\n\n"
                            "• Escolha um mês específico para filtrar as despesas\n\n"
                            "• O gráfico de despesas é atualizado automaticamente\n\n"
                            "• Útil para analisar padrões de gastos mensais",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Atualização e Celebração
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Atualização \ne Celebração",
                        icon: Icons.refresh,
                        iconColor: Colors.teal,
                        content: "Mantenha seus dados atualizados:\n\n"
                            "• Botão de atualização: Recarrega todos os dados financeiros\n\n"
                            "• Botão de celebração: Quando seu saldo é positivo, clique para ver uma animação celebrativa\n\n"
                            "• Se o saldo for muito bom (acima de 50% das despesas), uma celebração especial será mostrada\n\n"
                            "• Indicadores visuais mostram se seu saldo é positivo ou negativo",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Análises Detalhadas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Análises Detalhadas",
                        icon: Icons.analytics,
                        iconColor: Colors.purple,
                        content: "Para obter análises mais profundas:\n\n"
                            "• Toque em qualquer gráfico para ver informações detalhadas\n\n"
                            "• Na visualização detalhada, você verá valores exatos e percentuais\n\n"
                            "• As análises ajudam a identificar onde seu dinheiro está sendo ganho e gasto\n\n"
                            "• Use essas informações para tomar decisões financeiras mais conscientes",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 700),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeManager
                              .getDashboardHeaderBackgroundColor()
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeManager
                                .getDashboardHeaderBackgroundColor()
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
                                  color: themeManager
                                      .getDashboardHeaderBackgroundColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeManager
                                        .getDashboardHeaderBackgroundColor(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Analise os tipos de despesas que representam as maiores fatias do gráfico. Concentre seus esforços de economia nessas áreas para obter o maior impacto no seu orçamento.",
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
                        delay: const Duration(milliseconds: 800),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeManager
                                .getDashboardHeaderBackgroundColor(),
                            foregroundColor:
                                themeManager.getDashboardHeaderTextColor(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: 8),
                              const Text(
                                "Entendi!",
                                style: TextStyle(
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

// Método auxiliar para construir seções de ajuda
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
                style: TextStyle(
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
              style: TextStyle(
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

  Widget _buildAccountFilterCard(ThemeManager themeManager) {
    final isReceita = _selectedTipo == 'receitas';
    final theme = Theme.of(context);

    // Monta lista de categorias conforme tipo selecionado
    final categorias = isReceita
        ? _filteredRevenues.map((r) => r.tipoReceita).toSet().toList()
        : _filteredCosts.map((c) => c.tipoDespesa).toSet().toList();

    // Calcula dados para o gráfico
    Map<String, double> dataByType = isReceita
        ? _calculateRevenuesByType(_filteredRevenues)
        : _calculateCostsByType(_filteredCosts);

    // Cores para o gráfico
    List<Color> colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.red.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.lime.shade600,
      Colors.pink.shade600,
      Colors.amber.shade600,
      Colors.cyan.shade600,
      Colors.indigo.shade600,
      Colors.brown.shade600,
      Colors.grey.shade600,
      Colors.deepOrange.shade600,
      Colors.deepPurple.shade600,
      Colors.lightBlue.shade600,
      Colors.lightGreen.shade600,
    ];

    // Calcula total
    final total = isReceita
        ? _filteredRevenues.fold(0.0, (sum, r) => sum + r.preco)
        : _filteredCosts.fold(0.0, (sum, c) => sum + c.preco);

    return GestureDetector(
      onTap: () => _showAccountFilterDetailDialog(context, dataByType, colors,
          isReceita ? 'Receitas por Conta' : 'Despesas por Conta'),
      child: PressableCard(
        onPress: () => _showAccountFilterDetailDialog(context, dataByType,
            colors, isReceita ? 'Receitas por Conta' : 'Despesas por Conta'),
        pressedScale: 0.98,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withAlpha((0.35 * 255).round()), // ✅ SOMBRA MAIS ESCURA
              blurRadius: 20, // ✅ MAIS BLUR
              spreadRadius: 3, // ✅ MAIS SPREAD
              offset: const Offset(0, 12), // ✅ MUITO MAIS ELEVADO
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // ✅ MAIS PADDING
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (igual aos outros)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resumo por Conta',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: isReceita ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const Divider(),

              // ✅ FILTROS CORRIGIDOS COM DADOS REAIS
              Column(
                children: [
                  // Primeira linha: Conta e Tipo
                  Row(
                    children: [
                      // ✅ Selector de conta CORRIGIDO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conta',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<List<Account>>(
                              future: AccountService().getAllAccounts(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text('Nenhuma conta',
                                          style: TextStyle(fontSize: 14)),
                                    ),
                                  );
                                }

                                final accounts = snapshot.data!;
                                // ✅ Ajustar selectedAccountId se necessário
                                if (_selectedAccountId != null &&
                                    !accounts.any((a) =>
                                        a.id.toString() ==
                                        _selectedAccountId)) {
                                  _selectedAccountId = null;
                                }

                                return DropdownButtonFormField<String>(
                                  value: _selectedAccountId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    ),
                                    isDense: true,
                                  ),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todas as contas',
                                            style: TextStyle(fontSize: 14))),
                                    // ✅ USAR CAMPOS CORRETOS: name e id
                                    ...accounts
                                        .map((account) => DropdownMenuItem(
                                              value: account.id?.toString(),
                                              child: Text(
                                                account.name, // ✅ CAMPO CORRETO
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )),
                                  ],
                                  onChanged: (id) {
                                    setState(() => _selectedAccountId = id);
                                    _loadFilteredData();
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ✅ Selector de tipo CORRIGIDO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedTipo,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                isDense: true,
                              ),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface),
                              items: const [
                                DropdownMenuItem(
                                    value: 'receitas',
                                    child: Text('Receitas',
                                        style: TextStyle(fontSize: 14))),
                                DropdownMenuItem(
                                    value: 'despesas',
                                    child: Text('Despesas',
                                        style: TextStyle(fontSize: 14))),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedTipo = value!;
                                  _selectedCategoria = null;
                                });
                                _loadFilteredData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20), // ✅ MAIS ESPAÇO

                  // Segunda linha: Período e Categoria
                  Row(
                    children: [
                      // Período
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Período',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.date_range, size: 18),
                              label: Text(
                                _selectedPeriod == null
                                    ? 'Selecionar período'
                                    : '${DateFormat('dd/MM').format(_selectedPeriod!.start)} - ${DateFormat('dd/MM').format(_selectedPeriod!.end)}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize:
                                    const Size(0, 44), // ✅ ALTURA MÍNIMA
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2027),
                                  initialDateRange: _selectedPeriod,
                                );
                                if (picked != null) {
                                  setState(() => _selectedPeriod = picked);
                                  _loadFilteredData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ✅ Categoria CORRIGIDA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categoria',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedCategoria,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                isDense: true,
                              ),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface),
                              items: [
                                const DropdownMenuItem(
                                    value: null,
                                    child: Text('Todas',
                                        style: TextStyle(fontSize: 14))),
                                // ✅ USAR categorias CALCULADAS CORRETAMENTE
                                ...categorias.map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedCategoria = value);
                                _loadFilteredData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24), // ✅ MAIS ESPAÇO

              // Gráfico (igual aos outros) ✅ ALTURA AUMENTADA
              if (_isLoadingCard)
                const SizedBox(
                  height: 290, // ✅ MUITO MAIS ALTO
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (dataByType.isNotEmpty)
                SizedBox(
                  height: 290, // ✅ MUITO MAIS ALTO
                  child: _buildChartContentPie(dataByType, colors),
                )
              else
                Container(
                  height: 290, // ✅ MUITO MAIS ALTO
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.multiline_chart,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum dado encontrado\ncom os filtros aplicados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ✅ MAIS ESPAÇO ANTES DO BOTÃO
              const SizedBox(height: 20),

              // Botão "Toque para detalhes" (igual aos outros)
              if (dataByType.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Toque para detalhes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20), // ✅ MAIS ESPAÇO

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: themeManager.getCurrentPrimaryColor(),
                    ),
                  ),
                  Text(
                    _currencyService.formatCurrency(total),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isReceita
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Corrigir o diálogo detalhado (problema de constraints):
  void _showAccountFilterDetailDialog(
    BuildContext context,
    Map<String, double> dataByType,
    List<Color> colors,
    String title,
  ) {
    final theme = Theme.of(context);
    final isRevenue = title.contains('Receitas');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ScaleAnimation.bounceIn(
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.92, // ✅ LARGURA ESPECÍFICA
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 600,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      color: isRevenue ? Colors.green : Colors.red,
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Informações dos filtros aplicados
                    if (_selectedAccountId != null ||
                        _selectedPeriod != null ||
                        _selectedCategoria != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.shade100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtros aplicados:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_selectedAccountId != null)
                                  FutureBuilder<List<Account>>(
                                    future: AccountService().getAllAccounts(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final account =
                                            snapshot.data!.firstWhere(
                                          (a) =>
                                              a.id.toString() ==
                                              _selectedAccountId,
                                          orElse: () => Account(
                                              name: 'Conta desconhecida',
                                              type: AccountType.other,
                                              balance: 0,
                                              icon: Icons
                                                  .account_balance.codePoint),
                                        );
                                        return Chip(
                                          label: Text(
                                            'Conta: ${account.name}', // ✅ CAMPO CORRETO
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: Colors.blue.shade100,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                Chip(
                                  label: Text(
                                    'Tipo: ${_selectedTipo == 'receitas' ? 'Receitas' : 'Despesas'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: isRevenue
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                if (_selectedPeriod != null)
                                  Chip(
                                    label: Text(
                                      'Período: ${DateFormat('dd/MM/yy').format(_selectedPeriod!.start)} - ${DateFormat('dd/MM/yy').format(_selectedPeriod!.end)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.orange.shade100,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (_selectedCategoria != null)
                                  Chip(
                                    label: Text(
                                      'Categoria: $_selectedCategoria',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.purple.shade100,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Conteúdo do gráfico
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildChartContentPieDetailed(
                              dataByType, colors, _currencyService),
                        ),
                      ),
                    ),

                    // Lista de transações filtradas
                    if ((isRevenue ? _filteredRevenues : _filteredCosts)
                        .isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Últimas Transações:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: isRevenue
                                    ? _filteredRevenues.take(5).length
                                    : _filteredCosts.take(5).length,
                                itemBuilder: (context, index) {
                                  if (isRevenue) {
                                    final r = _filteredRevenues[index];
                                    return Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.tipoReceita,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _currencyService
                                                .formatCurrency(r.preco),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(r.data),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    final c = _filteredCosts[index];
                                    return Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.red.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.tipoDespesa,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _currencyService
                                                .formatCurrency(c.preco),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(c.data),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Botão de fechar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isRevenue ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
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

  Widget _buildInfoCard(ThemeData theme) {
    Color saldoColor = saldo >= 0 ? Colors.green : Colors.red;

    return PressableCard(
      onPress: () {
        setState(() {
          _pulseInfo = !_pulseInfo;
        });
      },
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumo Financeiro',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.bar_chart,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const Divider(height: 24),

            // Fila de estatísticas de Receitas e Despesas
            Row(
              children: [
                // Receitas
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.arrow_upward_rounded,
                    Colors.green,
                    'Receitas',
                    _currencyService.formatCurrency(totalRevenues),
                  ),
                ),

                // Separador vertical
                Container(
                  height: 40,
                  width: 1,
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.1 * 255).round()),
                ),

                // Despesas
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.arrow_downward_rounded,
                    Colors.red,
                    'Despesas',
                    _currencyService.formatCurrency(totalCosts),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Médias
            Row(
              children: [
                // Média de Receitas
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.trending_up,
                    Colors.green.withAlpha((0.7 * 255).round()),
                    'Média Receitas',
                    _currencyService.formatCurrency(averageRevenues),
                    fontSize: 13,
                  ),
                ),

                // Separador vertical
                Container(
                  height: 40,
                  width: 1,
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.1 * 255).round()),
                ),

                // Média de Despesas
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.trending_down,
                    Colors.red.withAlpha((0.7 * 255).round()),
                    'Média Despesas',
                    _currencyService.formatCurrency(averageCosts),
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Saldo com animação
            GoldenShineAnimation(
              intensity: saldo > 0 ? 0.7 : 0.0,
              repeat: saldo > 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: saldoColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: saldoColor.withAlpha((0.3 * 255).round()),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Total:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AnimatedCounter(
                      begin: 0,
                      end: saldo.round(),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeOutCubic,
                      formatter: (value) =>
                          _currencyService.formatCurrency(saldo),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        color: saldoColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar um item de estatística
  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    Color iconColor,
    String label,
    String value, {
    double iconSize = 18,
    double fontSize = 14,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                fontSize: fontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: fontSize + 2,
          ),
        ),
      ],
    );
  }

  // Método _buildPieChart melhorado
  Widget _buildPieChart(List<dynamic> items, String title) {
    final theme = Theme.of(context);
    Map<String, double> dataByType;
    if (title.contains('Receitas')) {
      dataByType = _calculateRevenuesByType(items.cast<Revenues>());
    } else {
      dataByType = _calculateCostsByType(items.cast<Costs>());
    }

    // Cores vibrantes para os gráficos
    List<Color> colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.red.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.lime.shade600,
      Colors.pink.shade600,
      Colors.amber.shade600,
      Colors.cyan.shade600,
      Colors.indigo.shade600,
      Colors.brown.shade600,
      Colors.grey.shade600,
      Colors.deepOrange.shade600,
      Colors.deepPurple.shade600,
      Colors.lightBlue.shade600,
      Colors.lightGreen.shade600,
    ];

    return GestureDetector(
      onTap: () => _showDetailDialog(context, dataByType, colors, title),
      child: PressableCard(
        onPress: () => _showDetailDialog(context, dataByType, colors, title),
        pressedScale: 0.98,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black..withAlpha((0.05 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    title.contains('Receitas')
                        ? Icons.attach_money
                        : Icons.money_off,
                    color:
                        title.contains('Receitas') ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const Divider(),
              SizedBox(
                height: 200,
                child: _buildChartContentPie(dataByType, colors),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Toque para detalhes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função para mostrar o diálogo detalhado
  void _showDetailDialog(
    BuildContext context,
    Map<String, double> dataByType,
    List<Color> colors,
    String title,
  ) {
    final theme = Theme.of(context);
    final isRevenue = title.contains('Receitas');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ScaleAnimation.bounceIn(
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 600,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho com cores correspondentes ao tipo de dado
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      color: isRevenue ? Colors.green : Colors.red,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isRevenue
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Conteúdo
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildChartContentPieDetailed(
                              dataByType, colors, _currencyService),
                        ),
                      ),
                    ),

                    // Botão de fechar na parte inferior
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isRevenue ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
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
}

// Função _buildChartContentPie aprimorada
Widget _buildChartContentPie(
  Map<String, double> dataByType,
  List<Color> colors,
) {
  List<PieChartSectionData> pieChartSections = [];
  int colorIndex = 0;
  double totalValue = dataByType.values.fold(0, (sum, value) => sum + value);

  dataByType.forEach((type, value) {
    double percentage = (value / totalValue) * 100;
    pieChartSections.add(
      PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 2,
              color: Colors.black45,
              offset: Offset(0, 1),
            ),
          ],
        ),
        badgeWidget: percentage >= 15
            ? _buildBadge(type, colors[colorIndex % colors.length])
            : null,
        badgePositionPercentageOffset: 1.2,
      ),
    );
    colorIndex++;
  });

  return Row(
    children: [
      // Gráfico
      Expanded(
        child: PieChart(
          PieChartData(
            sections: pieChartSections,
            centerSpaceRadius: 30,
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Implementar a lógica de toque se necessário
              },
            ),
          ),
        ),
      ),

      // Lista resumida lateral (apenas 4 primeiros itens)
      if (dataByType.isNotEmpty)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dataByType.entries.take(4).map((entry) {
              final index = dataByType.keys.toList().indexOf(entry.key);
              final type = entry.key;
              final value = entry.value;
              final percentage = (value / totalValue) * 100;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[index % colors.length],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.length > 12
                                ? '${type.substring(0, 12)}...'
                                : type,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: 'R\$${value.toStringAsFixed(0)} ',
                                ),
                                TextSpan(
                                  text: '(${percentage.toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
    ],
  );
}

// Badge para seções grandes do gráfico
Widget _buildBadge(String title, Color color) {
  String shortTitle = title.length > 6 ? '${title.substring(0, 6)}...' : title;

  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 3,
            spreadRadius: 0.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        shortTitle,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ),
  );
}

// Versão detalhada do gráfico para o diálogo
Widget _buildChartContentPieDetailed(
  Map<String, double> dataByType,
  List<Color> colors,
  CurrencyService currencyService,
) {
  List<PieChartSectionData> pieChartSections = [];
  int colorIndex = 0;
  double totalValue = dataByType.values.fold(0, (sum, value) => sum + value);

  dataByType.forEach((type, value) {
    double percentage = (value / totalValue) * 100;
    pieChartSections.add(
      PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 2,
              color: Colors.black45,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
    colorIndex++;
  });

  return Column(
    children: [
      // Gráfico ampliado
      SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sections: pieChartSections,
            centerSpaceRadius: 40,
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Implementar a lógica de toque se necessário
              },
            ),
          ),
        ),
      ),

      const SizedBox(height: 24),

      // Lista detalhada
      Column(
        children: dataByType.entries.map((entry) {
          final index = dataByType.keys.toList().indexOf(entry.key);
          final type = entry.key;
          final value = entry.value;
          final percentage = (value / totalValue) * 100;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[index % colors.length],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${currencyService.formatCurrency(value)} ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ],
  );
}
