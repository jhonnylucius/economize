import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/loading_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importação necessária para SystemChrome
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

class TrendChartScreen extends StatefulWidget {
  const TrendChartScreen({super.key});

  @override
  State<TrendChartScreen> createState() => _TrendChartScreenState();
}

class _TrendChartScreenState extends State<TrendChartScreen>
    with TickerProviderStateMixin {
  final CostsService _costsService = CostsService();
  final RevenuesService _revenuesService = RevenuesService();
  late CurrencyService _currencyService;

  bool _isLoading = true;
  bool _showLegend = true;
  bool _showDataLabels = false;
  bool animateChart = true;
  int _selectedPeriod = 0; // 0: mensal, 1: trimestral, 2: semestral
  int _selectedYear = DateTime.now().year;
  int _selectedPointIndex = -1;
  // chaves para tutorial interativo
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

  List<FlSpot> _costSpots = [];
  List<FlSpot> _revenueSpots = [];
  List<FlSpot> _balanceSpots = [];

  Map<int, double> _monthlyTotalsCosts = {};
  Map<int, double> _monthlyTotalsRevenues = {};
  Map<int, double> _monthlyTotalsBalance = {};

  double _maxY = 0;
  double _minY = 0;

  // Controladores de animação
  late AnimationController _chartAnimationController;
  late AnimationController _highlightController;
  late Animation<double> _chartAnimation;
  late Animation<double> highlightAnimation;

  // Dados para os tooltips e detalhes
  String selectedDetail = '';

  // Lista de anos disponíveis
  List<int> _availableYears = [];

  // Índice do mês selecionado para detalhe
  int detailMonth = -1;

  // Estado de orientação
  bool isLandscape = true;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _currencyService = context.read<CurrencyService>();

    // Definir orientação paisagem quando a tela é aberta (Adicionado/Modificado)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Configurar controladores de animação
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    );

    highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    );

    _loadData();
  }

  @override
  void dispose() {
    // Restaurar orientação portrait apenas se não estiver saindo
    if (!_isExiting) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    _chartAnimationController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final costs = await _costsService.getCostsForCalculations();
      final revenues = await _revenuesService.getAllRevenues();

      // Identificar anos disponíveis
      final yearsInCosts = costs.map((cost) => cost.data.year).toSet();
      final yearsInRevenues =
          revenues.map((revenue) => revenue.data.year).toSet();
      _availableYears = {...yearsInCosts, ...yearsInRevenues}.toList()..sort();

      if (_availableYears.isEmpty) {
        _availableYears = [DateTime.now().year];
      }

      if (!_availableYears.contains(_selectedYear)) {
        _selectedYear = _availableYears.last;
      }

      _processData(costs, revenues);

      if (animateChart) {
        _chartAnimationController.forward();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processData(List<Costs> costs, List<Revenues> revenues) {
    // Filtrar por ano selecionado
    final filteredCosts =
        costs.where((cost) => cost.data.year == _selectedYear).toList();
    final filteredRevenues = revenues
        .where((revenue) => revenue.data.year == _selectedYear)
        .toList();

    // Agrupar despesas e receitas por mês
    _monthlyTotalsCosts = {};
    _monthlyTotalsRevenues = {};
    _monthlyTotalsBalance = {};

    // Inicializar todos os meses com zero
    for (int i = 1; i <= 12; i++) {
      _monthlyTotalsCosts[i] = 0;
      _monthlyTotalsRevenues[i] = 0;
      _monthlyTotalsBalance[i] = 0;
    }

    // Somar despesas por mês
    for (var cost in filteredCosts) {
      final month = cost.data.month;
      _monthlyTotalsCosts[month] =
          (_monthlyTotalsCosts[month] ?? 0) + cost.preco;
    }

    // Somar receitas por mês
    for (var revenue in filteredRevenues) {
      final month = revenue.data.month;
      _monthlyTotalsRevenues[month] =
          (_monthlyTotalsRevenues[month] ?? 0) + revenue.preco;
    }

    // Calcular saldo mensal (receitas - despesas)
    for (int month = 1; month <= 12; month++) {
      _monthlyTotalsBalance[month] = (_monthlyTotalsRevenues[month] ?? 0) -
          (_monthlyTotalsCosts[month] ?? 0);
    }

    // Agrupar por período selecionado
    if (_selectedPeriod == 1) {
      // Trimestral
      _groupByQuarter();
    } else if (_selectedPeriod == 2) {
      // Semestral
      _groupBySemester();
    }

    // Criar spots para o gráfico
    _createSpots();

    // Calcular valores máximo e mínimo considerando todas as linhas
    _calculateYRange();
  }

  void _groupByQuarter() {
    final quarterTotalsCosts = <int, double>{};
    final quarterTotalsRevenues = <int, double>{};
    final quarterTotalsBalance = <int, double>{};

    // Inicializar todos os trimestres com zero
    for (int i = 1; i <= 4; i++) {
      quarterTotalsCosts[i] = 0;
      quarterTotalsRevenues[i] = 0;
      quarterTotalsBalance[i] = 0;
    }

    // Agrupar meses em trimestres
    for (int month = 1; month <= 12; month++) {
      int quarter = ((month - 1) ~/ 3) +
          1; // Trimestres: 1 (jan-mar), 2 (abr-jun), 3 (jul-set), 4 (out-dez)
      quarterTotalsCosts[quarter] = (quarterTotalsCosts[quarter] ?? 0) +
          (_monthlyTotalsCosts[month] ?? 0);
      quarterTotalsRevenues[quarter] = (quarterTotalsRevenues[quarter] ?? 0) +
          (_monthlyTotalsRevenues[month] ?? 0);
      quarterTotalsBalance[quarter] = (quarterTotalsBalance[quarter] ?? 0) +
          (_monthlyTotalsBalance[month] ?? 0);
    }

    _monthlyTotalsCosts = quarterTotalsCosts;
    _monthlyTotalsRevenues = quarterTotalsRevenues;
    _monthlyTotalsBalance = quarterTotalsBalance;
  }

  void _groupBySemester() {
    final semesterTotalsCosts = <int, double>{};
    final semesterTotalsRevenues = <int, double>{};
    final semesterTotalsBalance = <int, double>{};

    // Inicializar os semestres com zero
    for (int i = 1; i <= 2; i++) {
      semesterTotalsCosts[i] = 0;
      semesterTotalsRevenues[i] = 0;
      semesterTotalsBalance[i] = 0;
    }

    // Agrupar meses em semestres
    for (int month = 1; month <= 12; month++) {
      int semester =
          ((month - 1) ~/ 6) + 1; // Semestres: 1 (jan-jun), 2 (jul-dez)
      semesterTotalsCosts[semester] = (semesterTotalsCosts[semester] ?? 0) +
          (_monthlyTotalsCosts[month] ?? 0);
      semesterTotalsRevenues[semester] =
          (semesterTotalsRevenues[semester] ?? 0) +
              (_monthlyTotalsRevenues[month] ?? 0);
      semesterTotalsBalance[semester] = (semesterTotalsBalance[semester] ?? 0) +
          (_monthlyTotalsBalance[month] ?? 0);
    }

    _monthlyTotalsCosts = semesterTotalsCosts;
    _monthlyTotalsRevenues = semesterTotalsRevenues;
    _monthlyTotalsBalance = semesterTotalsBalance;
  }

  void _createSpots() {
    // Criar spots para o gráfico de acordo com os dados agrupados
    _costSpots = _monthlyTotalsCosts.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    _revenueSpots = _monthlyTotalsRevenues.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    _balanceSpots = _monthlyTotalsBalance.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  void _calculateYRange() {
    if (_costSpots.isEmpty && _revenueSpots.isEmpty && _balanceSpots.isEmpty) {
      _maxY = 1000;
      _minY = 0;
      return;
    }

    // Combinar todos os spots para encontrar min/max
    final allYValues = [..._costSpots, ..._revenueSpots, ..._balanceSpots]
        .map((spot) => spot.y)
        .toList();

    _maxY = allYValues.fold<double>(
        allYValues.first, (max, value) => value > max ? value : max);
    _minY = allYValues.fold<double>(
        allYValues.first, (min, value) => value < min ? value : min);

    // Adicionar margem
    _maxY = _maxY + (_maxY * 0.2);
    _minY = _minY - (_minY * 0.2);

    // Garantir que valores não sejam zero
    if (_maxY == _minY) {
      if (_maxY == 0) {
        _maxY = 1000;
        _minY = 0;
      } else {
        _maxY += _maxY * 0.2;
        _minY -= _minY * 0.2;
      }
    }
  }

  String _getPeriodTitle() {
    switch (_selectedPeriod) {
      case 0:
        return 'Mensal';
      case 1:
        return 'Trimestral';
      case 2:
        return 'Semestral';
      default:
        return 'Mensal';
    }
  }

  String _getXAxisLabel(double value) {
    final int xValue = value.toInt();

    switch (_selectedPeriod) {
      case 0: // Mensal
        const months = [
          'Jan',
          'Fev',
          'Mar',
          'Abr',
          'Mai',
          'Jun',
          'Jul',
          'Ago',
          'Set',
          'Out',
          'Nov',
          'Dez',
        ];
        if (xValue >= 1 && xValue <= 12) {
          return months[xValue - 1];
        }
        break;

      case 1: // Trimestral
        const quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
        if (xValue >= 1 && xValue <= 4) {
          return quarters[xValue - 1];
        }
        break;

      case 2: // Semestral
        const semesters = ['S1', 'S2'];
        if (xValue >= 1 && xValue <= 2) {
          return semesters[xValue - 1];
        }
        break;
    }

    return '';
  }

  void _updateFilterPeriod(int index) {
    setState(() {
      _selectedPeriod = index;
      // Certifique-se de que getCostsSync e getRevenuesSync existam e retornem List<Cost> e List<Revenue>
      _processData(
          _costsService.getCostsSync(), _revenuesService.getRevenuesSync());

      // Resetar ponto selecionado
      _selectedPointIndex = -1;

      // Reiniciar animação
      if (animateChart) {
        _chartAnimationController.reset();
        _chartAnimationController.forward();
      }
    });
  }

  void _navigateBackSafely() {
    if (_isExiting) return;
    _isExiting = true;

    // Primeiro alteramos a orientação ANTES de qualquer navegação
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Mostramos um overlay para cobrir a transição
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );

    // Aumentamos o delay para dar tempo suficiente ao dispositivo para mudar de orientação
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop(); // Fecha o diálogo
        Navigator.of(context).pop(); // Volta para a tela anterior
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = context.watch<ThemeManager>();
    final screenSize = MediaQuery.of(context).size;

    // Forçar modo paisagem
    isLandscape = screenSize.width > screenSize.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _navigateBackSafely();
      },
      child: Scaffold(
        // AppBar permanece como está
        appBar: AppBar(
          leading: IconButton(
            key: _backButtonKey,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _navigateBackSafely,
          ),
          title: const Text(
            'Tendência de Finanças',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: theme.colorScheme.primary,
          elevation: 0,
          actions: [
            IconButton(
              key: _helpButtonKey,
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'Ajuda',
              onPressed: () =>
                  _showHomeScreenHelp(context), // Chama o método de ajuda
            ),
            // Seletor de ano
            SlideAnimation.fromRight(
              distance: 0.3,
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withAlpha((0.7 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onPrimary
                        .withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onPrimary,
                    ),
                    dropdownColor: theme.colorScheme.primary,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    items: _availableYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && value != _selectedYear) {
                        setState(() {
                          _selectedYear = value;
                          _loadData();
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        // Mova estes parâmetros para dentro do Scaffold, não do AppBar:
        backgroundColor: theme.colorScheme.surface,
        floatingActionButton: ScaleAnimation.bounceIn(
          delay: const Duration(milliseconds: 600),
          child: FloatingActionButton(
            onPressed: () => setState(() => _showDataLabels = !_showDataLabels),
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              _showDataLabels ? Icons.label_off : Icons.label,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        resizeToAvoidBottomInset: true,

        body: _isLoading
            ? Center(
                child: BrandLoadingAnimation(
                  primaryColor: theme.colorScheme.primary,
                  secondaryColor: theme.colorScheme.secondary,
                  size: 80,
                ),
              )
            : (_costSpots.isEmpty &&
                    _revenueSpots.isEmpty &&
                    _balanceSpots.isEmpty)
                ? Center(
                    // ... conteúdo de "nenhum dado disponível" ...
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_chart_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withAlpha((0.5 * 255).round()),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum dado disponível para o período',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _loadData(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    // ... resto do corpo ...
                    children: [
                      // Seletores de período
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: SlideAnimation.fromTop(
                          distance: 0.3,
                          duration: const Duration(milliseconds: 400),
                          delay: const Duration(milliseconds: 200),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Seletores de período
                              Row(
                                children: [
                                  _buildFilterChip('Mensal', 0),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Trimestral', 1),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Semestral', 2),
                                ],
                              ),

                              // Botão de legenda
                              PressableCard(
                                onPress: () {
                                  setState(() {
                                    _showLegend = !_showLegend;
                                  });
                                },
                                pressedScale: 0.95,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface
                                      .withAlpha((0.8 * 255).round()),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withAlpha((0.5 * 255).round()),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showLegend
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Legenda',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Gráfico principal
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                          child: FadeAnimation.fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 300),
                            child: _buildChart(theme, themeManager),
                          ),
                        ),
                      ),

                      // Legenda
                      if (_showLegend)
                        SlideAnimation.fromBottom(
                          distance: 0.3,
                          duration: const Duration(milliseconds: 400),
                          delay: const Duration(milliseconds: 400),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.1 * 255).round()),
                                  blurRadius: 4,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildLegendItem('Receitas', Colors.green),
                                _buildLegendItem('Despesas', Colors.red),
                                _buildLegendItem('Saldo', Colors.blue),
                              ],
                            ),
                          ),
                        ),

                      // Detalhes do ponto selecionado
                      if (_selectedPointIndex >= 0)
                        SlideAnimation.fromBottom(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.1 * 255).round()),
                                  blurRadius: 4,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getDetailPeriodLabel(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _selectedPointIndex = -1;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      iconSize: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDetailItem('Receitas', Colors.green,
                                        _getSelectedRevenue()),
                                    _buildDetailItem('Despesas', Colors.red,
                                        _getSelectedCost()),
                                    _buildDetailItem('Saldo', Colors.blue,
                                        _getSelectedBalance()),
                                  ],
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

  // Adicione este método na classe _TrendChartScreenState
  void _showHomeScreenHelp(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.currentThemeType != ThemeType.light;

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
                            backgroundColor:
                                themeManager.getCurrentPrimaryColor(),
                            child: Icon(
                              Icons.home,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tela Principal",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color.fromARGB(255, 0, 0, 0)
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Centro de controle do seu gerenciamento financeiro",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
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

                    // Seção 1: Barra Superior
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Barra de Navegação Superior",
                        icon: Icons.bar_chart,
                        iconColor: themeManager.getCurrentPrimaryColor(),
                        content:
                            "A barra superior oferece acesso rápido às principais funcionalidades:\n\n"
                            "• Logo do Economize\$: Identidade visual do aplicativo\n\n"
                            "• Botão de Ajuda: Abre este guia de informações\n\n"
                            "• Notificações: Mostra alertas importantes sobre suas finanças\n\n"
                            "• Busca: Encontre rapidamente qualquer funcionalidade no app",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Card Financeiro
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Resumo Financeiro",
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.green,
                        content:
                            "O card colorido no topo apresenta seu resumo financeiro:\n\n"
                            "• Saldo Atual: Total das receitas menos despesas\n\n"
                            "• Indicador de Variação: Mostra se sua situação financeira está melhorando (verde) ou piorando (vermelho)\n\n"
                            "• Barras de Progresso: Visualize seu progresso em metas de economia e controle de gastos\n\n"
                            "• Toque no card para acessar o Dashboard completo",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Categorias
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Filtro de Categorias",
                        icon: Icons.category,
                        iconColor: Colors.blue,
                        content:
                            "Os filtros horizontais organizam as funcionalidades:\n\n"
                            "• Principais: Exibe todas as funcionalidades disponíveis\n\n"
                            "• Financeiro: Mostra apenas controles financeiros como Orçamentos, Despesas e Receitas\n\n"
                            "• Gestão: Ferramentas para gerenciamento de dados e itens\n\n"
                            "• Relatórios: Seção de análises e tendências financeiras",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Grid de Funcionalidades
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Funcionalidades Principais",
                        icon: Icons.apps,
                        iconColor: Colors.purple,
                        content:
                            "O grid central dá acesso a todas as ferramentas:\n\n"
                            "• Orçamentos: Planeje suas finanças definindo limites por categoria\n\n"
                            "• Despesas: Registre e acompanhe todos os seus gastos\n\n"
                            "• Receitas: Cadastre suas fontes de renda\n\n"
                            "• Dashboard: Visualize gráficos e análises detalhadas\n\n"
                            "• Relatórios: Exportação e visualização de dados históricos\n\n"
                            "• Gerenciar Produtos: Cadastre itens frequentes para facilitar registros\n\n"
                            "• Tendências: Analise padrões de gastos ao longo do tempo\n\n"
                            "• Metas: Defina e acompanhe objetivos financeiros",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Alternador de visualização
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Modos de Visualização",
                        icon: Icons.view_list,
                        iconColor: Colors.amber,
                        content:
                            "Personalize como visualizar as funcionalidades:\n\n"
                            "• Modo Grade: Visualização compacta em blocos com ícones grandes\n\n"
                            "• Modo Lista: Formato expandido com descrições detalhadas\n\n"
                            "• Alterne entre os modos tocando no botão no canto superior direito da seção",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Barra inferior
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Barra de Navegação Inferior",
                        icon: Icons.menu,
                        iconColor: Colors.teal,
                        content:
                            "Acesso rápido a funcionalidades essenciais:\n\n"
                            "• Temas: Personalize a aparência do aplicativo (cores e modo claro/escuro)\n\n"
                            "• Metas: Acesse diretamente suas metas financeiras\n\n"
                            "• Botão Central: Atalho para a função mais importante (personalizável)\n\n"
                            "• Saldo: Visualize rapidamente seu saldo atual detalhado\n\n"
                            "• Dicas: Receba conselhos personalizados para melhorar suas finanças",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 7: Painel Flutuante
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 700),
                      child: _buildHelpSection(
                        context: context,
                        title: "7. Dicas Flutuantes",
                        icon: Icons.lightbulb_outline,
                        iconColor: Colors.orange,
                        content:
                            "Painéis que aparecem ocasionalmente para ajudar você:\n\n"
                            "• Dicas personalizadas baseadas no seu uso do aplicativo\n\n"
                            "• Lembretes importantes sobre suas finanças\n\n"
                            "• Sugestões para melhorar seu controle financeiro\n\n"
                            "• Você pode fechá-los a qualquer momento tocando no X",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeManager
                              .getCurrentPrimaryColor()
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeManager
                                .getCurrentPrimaryColor()
                                .withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: themeManager.getCurrentPrimaryColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica profissional",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        themeManager.getCurrentPrimaryColor(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Comece cadastrando todas as suas fontes de receita e despesas recorrentes para ter uma visão real da sua situação financeira. O Economize\$ funcionará melhor com dados completos!",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão para fechar
                    Center(
                      child: ScaleAnimation.bounceIn(
                        delay: const Duration(milliseconds: 900),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                themeManager.getCurrentPrimaryColor(),
                            foregroundColor: theme.colorScheme.onPrimary,
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

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedPeriod == index;
    final theme = Theme.of(context);

    return PressableCard(
      onPress: () => _updateFilterPeriod(index),
      pressedScale: 0.95,
      decoration: BoxDecoration(
        color:
            isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha((0.5 * 255).round()),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color:
                      theme.colorScheme.primary.withAlpha((0.3 * 255).round()),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha((0.4 * 255).round()),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, Color color, double value) {
    final isNegative = value < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _currencyService.formatCurrency(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: label == 'Saldo' && isNegative ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  String _getDetailPeriodLabel() {
    if (_selectedPointIndex < 0) return '';

    final int month = _selectedPointIndex + 1; // Ajusta de 0-index para 1-index

    switch (_selectedPeriod) {
      case 0: // Mensal
        const months = [
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
        // Garante que o índice do mês seja válido
        if (month >= 1 && month <= 12) {
          return '${months[month - 1]} $_selectedYear';
        }
        break;

      case 1: // Trimestral
        const quarters = [
          '1º Trimestre',
          '2º Trimestre',
          '3º Trimestre',
          '4º Trimestre'
        ];
        // Garante que o índice do trimestre seja válido
        if (month >= 1 && month <= 4) {
          return '${quarters[month - 1]} $_selectedYear';
        }
        break;

      case 2: // Semestral
        const semesters = ['1º Semestre', '2º Semestre'];
        // Garante que o índice do semestre seja válido
        if (month >= 1 && month <= 2) {
          return '${semesters[month - 1]} $_selectedYear';
        }
        break;
    }

    return ''; // Retorna vazio se o índice for inválido ou período desconhecido
  }

  // Métodos para obter os valores do ponto selecionado (Index ajustado para 1-based)
  double _getSelectedRevenue() {
    if (_selectedPointIndex < 0) return 0;
    // O índice do mapa é 1-based (mês 1 a 12, trimestre 1 a 4, semestre 1 a 2)
    return _monthlyTotalsRevenues[_selectedPointIndex + 1] ?? 0;
  }

  double _getSelectedCost() {
    if (_selectedPointIndex < 0) return 0;
    // O índice do mapa é 1-based
    return _monthlyTotalsCosts[_selectedPointIndex + 1] ?? 0;
  }

  double _getSelectedBalance() {
    if (_selectedPointIndex < 0) return 0;
    // O índice do mapa é 1-based
    return _monthlyTotalsBalance[_selectedPointIndex + 1] ?? 0;
  }

  Widget _buildChart(ThemeData theme, ThemeManager themeManager) {
    // Calcular valores para labels intermediárias
    int maxItems = _selectedPeriod == 0 ? 12 : (_selectedPeriod == 1 ? 4 : 2);

    // Definir os intervalos dos eixos
    final double horizontalInterval = 1.0;
    // Evita divisão por zero ou intervalo muito pequeno
    final double verticalInterval = (_maxY - (_minY < 0 ? _minY : 0)).abs() / 5;
    final double safeVerticalInterval = verticalInterval > 0.1
        ? verticalInterval
        : 100.0; // Valor mínimo para intervalo

    return GestureDetector(
      onTap: () {
        if (_selectedPointIndex >= 0) {
          setState(() {
            _selectedPointIndex = -1;
          });
        }
      },
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, _) {
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                horizontalInterval:
                    safeVerticalInterval, // Usar intervalo seguro
                verticalInterval: horizontalInterval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withAlpha((0.3 * 255).round()),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  // Desenhar linhas verticais apenas nos centros dos períodos
                  int maxPeriods = _selectedPeriod == 0
                      ? 12
                      : (_selectedPeriod == 1 ? 4 : 2);
                  if (value > 0.5 &&
                      value < maxPeriods + 0.5 &&
                      value % 1 == 0) {
                    // Linhas nos valores inteiros (centros dos períodos)
                    return FlLine(
                      color: theme.dividerColor..withAlpha((0.3 * 255).round()),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  }
                  return const FlLine(
                      strokeWidth: 0); // Não desenha linha em outros lugares
                },
              ),
              titlesData: _buildTitles(theme, themeManager),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(
                    color: theme.dividerColor.withAlpha((0.5 * 255).round()),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: theme.dividerColor.withAlpha((0.5 * 255).round()),
                    width: 1,
                  ),
                  // Remove bordas direita e superior para um visual mais limpo
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
              lineTouchData: _buildTouchData(theme),
              minX: 0.5, // Começa antes do primeiro ponto
              maxX: maxItems + 0.5, // Termina depois do último ponto
              minY: _minY < 0
                  ? _minY * 1.2
                  : 0, // Estende o eixo Y para baixo se houver valores negativos
              maxY: _maxY > 0
                  ? _maxY * 1.2
                  : 1000, // Estende o eixo Y para cima, com mínimo de 1000
              clipData: FlClipData.all(),
              lineBarsData: [
                // Linha de Receitas (Verde)
                _buildLineData(
                  _revenueSpots,
                  Colors.green,
                  theme.cardColor,
                  Colors.green.withAlpha((0.2 * 255).round()),
                ),

                // Linha de Despesas (Vermelho)
                _buildLineData(
                  _costSpots,
                  Colors.red,
                  theme.cardColor,
                  Colors.red.withAlpha((0.2 * 255).round()),
                ),

                // Linha de Saldo (Azul)
                _buildLineData(
                  _balanceSpots,
                  Colors.blue,
                  theme.cardColor,
                  Colors.transparent, // Sem preenchimento abaixo do saldo
                ),
              ],
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  // Linha de zero (para saldo)
                  // Desenha a linha de zero se o range incluir o zero (minY < 0 < maxY)
                  if (_minY < 0 && _maxY > 0)
                    HorizontalLine(
                      y: 0,
                      color: theme.dividerColor.withAlpha(
                          (0.8 * 255).round()), // Um pouco mais visível
                      strokeWidth: 1.5,
                      dashArray: [6, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          bottom: 2,
                        ),
                        style: TextStyle(
                          color:
                              theme.colorScheme.primary, // Cor primária do tema
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (line) => 'zero',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  LineChartBarData _buildLineData(
    List<FlSpot> spots,
    Color color,
    Color dotBackgroundColor,
    Color fillColor,
  ) {
    return LineChartBarData(
      spots: spots.map((spot) {
        // Aplicar animação aos valores Y
        return FlSpot(spot.x, spot.y * _chartAnimation.value);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.25,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        // Mostrar todos os pontos quando showDataLabels está ativo, ou apenas um quando selecionado
        show: _showDataLabels || (_selectedPointIndex != -1),
        checkToShowDot: (spot, barData) {
          // Se showDataLabels está ativo, mostrar todos os pontos
          if (_showDataLabels) return true;
          // Se um ponto está selecionado, mostrar APENAS o ponto selecionado
          if (_selectedPointIndex != -1 &&
              spot.x.toInt() - 1 == _selectedPointIndex) {
            return true;
          }
          return false; // Não mostrar pontos por padrão
        },
        getDotPainter: (spot, percent, barData, index) {
          // Destacar o ponto selecionado com animação
          bool isSelected = index == _selectedPointIndex;
          final radius = isSelected
              ? (5.0 + highlightAnimation.value * 3.0)
              : 3.5; // Anima o raio se selecionado
          final strokeWidth = isSelected
              ? (2.0 + highlightAnimation.value * 1.0)
              : 2.0; // Anima a borda

          return FlDotCirclePainter(
            radius: radius,
            color: color, // Cor do ponto
            strokeWidth: strokeWidth, // Largura da borda
            strokeColor:
                dotBackgroundColor, // Cor da borda (geralmente cor de fundo do card)
          );
        },
      ),
      belowBarData: BarAreaData(
        show: fillColor !=
            Colors
                .transparent, // Mostrar preenchimento apenas se a cor não for transparente
        color: fillColor,
        cutOffY:
            _minY < 0 ? 0 : _minY, // Cortar no zero se houver valores negativos
        applyCutOffY: true,
      ),
    );
  }

  FlTitlesData _buildTitles(ThemeData theme, ThemeManager themeManager) {
    // Calcular o intervalo vertical localmente
    final double verticalInterval = (_maxY - (_minY < 0 ? _minY : 0)).abs() / 5;
    final double safeVerticalInterval = verticalInterval > 0.1
        ? verticalInterval
        : (_maxY > 0 ? _maxY / 5 : 100.0); // Valor mínimo para intervalo

    return FlTitlesData(
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            // Mostrar o título com o período e ano no centro do eixo X
            int maxPeriods =
                _selectedPeriod == 0 ? 12 : (_selectedPeriod == 1 ? 4 : 2);
            // Centraliza o título superior
            if (value == (maxPeriods + 1) / 2) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Visão ${_getPeriodTitle()} - $_selectedYear',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return const SizedBox(); // Não mostra título em outros pontos
          },
          reservedSize: 30,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1, // Intervalo 1 para mostrar todos os labels
          getTitlesWidget: (value, meta) {
            // Mostrar o label apenas nos valores inteiros correspondentes aos períodos
            int maxPeriods =
                _selectedPeriod == 0 ? 12 : (_selectedPeriod == 1 ? 4 : 2);
            if (value >= 1 && value <= maxPeriods && value % 1 == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getXAxisLabel(value),
                  style: TextStyle(
                    color: themeManager
                        .getTipCardTextColor(), // Cor baseada no tema
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const SizedBox(); // Não mostra label em outros pontos
          },
          reservedSize: 30,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: safeVerticalInterval, // Usar intervalo seguro
          reservedSize: 60, // Espaço reservado para os labels do eixo Y
          getTitlesWidget: (value, meta) {
            // Formatar valores grandes com K, M, etc. e R$
            String formattedValue;

            // Formata o número
            if (value.abs() >= 1000000) {
              formattedValue =
                  '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 && value != 0 ? 0 : 1)}M'; // Usa 0 casas decimais se for múltiplo de milhão
            } else if (value.abs() >= 1000) {
              formattedValue =
                  '${(value / 1000).toStringAsFixed(value % 1000 == 0 && value != 0 ? 0 : 1)}K'; // Usa 0 casas decimais se for múltiplo de mil
            } else {
              formattedValue = value.toStringAsFixed(value % 1 == 0
                  ? 0
                  : 1); // Usa 0 casas decimais se for inteiro
            }

            // Adiciona o R$ e sinal se negativo (a formatação acima já lida com o sinal)
            return Text(
              'R\$$formattedValue',
              style: TextStyle(
                color:
                    themeManager.getTipCardTextColor(), // Cor baseada no tema
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            );
          },
        ),
      ),
    );
  }

  LineTouchData _buildTouchData(ThemeData theme) {
    return LineTouchData(
      enabled: true, // Ativar a interatividade
      touchTooltipData: LineTouchTooltipData(
        // Cor do tooltip (fundo)
        getTooltipColor: (_) =>
            theme.colorScheme.surface.withAlpha((0.9 * 255).round()),

        tooltipRoundedRadius: 8, // Bordas arredondadas do tooltip
        tooltipPadding: const EdgeInsets.all(8), // Padding interno do tooltip
        tooltipBorder: BorderSide(
          // Borda do tooltip
          color: theme.colorScheme.primary.withAlpha((0.2 * 255).round()),
        ),
        maxContentWidth: 200, // Largura máxima do conteúdo do tooltip
        // Função para construir os itens do tooltip
        getTooltipItems: (touchedSpots) {
          // Agrupa os spots pelo valor X (período) para mostrar todos os valores daquele ponto
          final Map<double, List<LineBarSpot>> spotsByX = {};
          for (var spot in touchedSpots) {
            spotsByX.putIfAbsent(spot.x, () => []).add(spot);
          }

          // Cria um LineTooltipItem para cada período tocado (geralmente será apenas um)
          return spotsByX.entries.map((entry) {
            final double xValue = entry.key;
            final List<LineBarSpot> spots = entry.value;

            // Ordena os spots para Receitas, Despesas, Saldo (se o índice da barra for consistente)
            spots.sort((a, b) => a.barIndex.compareTo(b.barIndex));

            List<TextSpan> children = [];
            for (var spot in spots) {
              final String label;
              final Color color;

              if (spot.barIndex == 0) {
                // Receitas
                label = 'Receitas';
                color = Colors.green;
              } else if (spot.barIndex == 1) {
                // Despesas
                label = 'Despesas';
                color = Colors.red;
              } else {
                // Saldo
                label = 'Saldo';
                color = Colors.blue;
              }

              children.add(
                TextSpan(
                  text: '$label: ${_currencyService.formatCurrency(spot.y)}\n',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }

            // Adiciona o label do período no final
            children.add(
              TextSpan(
                text: _getXAxisLabel(xValue),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(
                      (0.8 * 255).round()), // Cor do tema com opacidade
                  fontWeight: FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            );

            // Retorna um único LineTooltipItem com todos os TextSpans como filhos
            return LineTooltipItem(
              '', // Texto principal vazio
              const TextStyle(), // Estilo vazio
              children: children, // Usa os TextSpans criados
              textDirection: ui.TextDirection.ltr, // Direção do texto
            );
          }).toList();
        },
      ),
      handleBuiltInTouches:
          true, // Permite que o FlChart lide com os toques padrão
      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
        // Manipula o evento de toque
        if (event is FlTapUpEvent && // Se for um toque para cima (fim do gesto)
            touchResponse != null &&
            touchResponse.lineBarSpots != null &&
            touchResponse.lineBarSpots!.isNotEmpty) {
          // Obter o índice do ponto tocado no eixo X (FlSpot.x é 1-based para meses/trimestres/semestres)
          // Convertemos para 0-based para usar como índice de lista se necessário
          final int pointIndex = touchResponse.lineBarSpots![0].x.toInt() - 1;

          setState(() {
            // Seleciona o ponto se for diferente do atual, ou deseleciona se for o mesmo
            _selectedPointIndex =
                (_selectedPointIndex == pointIndex) ? -1 : pointIndex;
            // Inicia a animação de destaque se um ponto foi selecionado
            if (_selectedPointIndex != -1) {
              _highlightController.forward(from: 0);
            } else {
              _highlightController.stop(); // Para a animação se deselecionou
            }
          });
        } else if (event is FlPanStartEvent ||
            event is FlPanUpdateEvent ||
            event is FlLongPressStart) {
          // Opcional: Se você quer que o ponto selecionado seja atualizado enquanto desliza ou segura
          if (touchResponse != null &&
              touchResponse.lineBarSpots != null &&
              touchResponse.lineBarSpots!.isNotEmpty) {
            final int pointIndex = touchResponse.lineBarSpots![0].x.toInt() - 1;
            if (_selectedPointIndex != pointIndex) {
              setState(() {
                _selectedPointIndex = pointIndex;
                _highlightController.forward(from: 0); // Reinicia a animação
              });
            }
          }
        } else if (event is FlPanEndEvent || event is FlLongPressEnd) {
          // Opcional: Poderia manter o ponto selecionado após o gesto terminar
          // Ou deselecionar após um pequeno atraso se necessário
        } else if (touchResponse == null) {
          // Se o usuário tocou fora de qualquer ponto
          setState(() {
            _selectedPointIndex = -1; // Deseleciona qualquer ponto
            _highlightController.stop(); // Para a animação
          });
        }
      },
      // Mostra indicadores nos pontos tocados
    );
  }
}

// Efeito de radar/ondas para destacar pontos importantes (Original)
class RadarEffect extends CustomPainter {
  final Color color;
  final double progress;

  RadarEffect({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(((1 - progress) * 0.3 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final radius = maxRadius * progress;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Sempre repinta para a animação
  }
}
