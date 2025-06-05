import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/loading_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:math' as math;

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen>
    with TickerProviderStateMixin {
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();
  final CostsService _costsService = CostsService();
  final RevenuesService _revenuesService = RevenuesService();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Controladores de animação
  late AnimationController _circleController;
  late AnimationController _balanceTextController;
  late AnimationController _waveController;
  late AnimationController _confettiController;
  late AnimationController _expenseAnimController;
  late AnimationController _pulseExpenseController;

  // Animations
  late Animation<double> _circleAnimation;
  late Animation<double> balanceTextAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _expenseProgressAnim;
  late Animation<double> _pulseExpenseAnimation;

  // Estado dos dados
  bool _isLoading = true;
  double _totalRevenues = 0.0;
  double _totalCosts = 0.0;
  double _balance = 0.0;
  double _expensePercentage = 0.0;
  bool _isPositiveBalance = true;
  bool _showConfetti = false;

  // Cores e chaves
  final GlobalKey _circleKey = GlobalKey();
  Color circleColor = Colors.green;
  bool _dangerZone = false;

  // Lista para a animação de raios
  final List<_ExpenseRay> _expenseRays = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Configuração dos controladores de animação
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _balanceTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _expenseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pulseExpenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Configuração das animações
    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.elasticOut,
    );

    balanceTextAnimation = CurvedAnimation(
      parent: _balanceTextController,
      curve: Curves.bounceOut,
    );

    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    _expenseProgressAnim = CurvedAnimation(
      parent: _expenseAnimController,
      curve: Curves.easeInOut,
    );

    _pulseExpenseAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _pulseExpenseController,
      curve: Curves.easeInOut,
    ));

    // Gerar raios para animação das despesas
    _generateExpenseRays();

    // Carrega os dados
    _loadCurrentMonthData();
  }

  void _generateExpenseRays() {
    // Gera raios com diferentes velocidades e ângulos
    for (int i = 0; i < 8; i++) {
      _expenseRays.add(
        _ExpenseRay(
          angle: _random.nextDouble() * math.pi * 2,
          speed: _random.nextDouble() * 0.03 + 0.01,
          length: _random.nextDouble() * 10 + 15,
          thickness: _random.nextDouble() * 2 + 1,
          opacity: _random.nextDouble() * 0.4 + 0.6,
          delay: _random.nextDouble() * 0.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _circleController.dispose();
    _balanceTextController.dispose();
    _waveController.dispose();
    _confettiController.dispose();
    _expenseAnimController.dispose();
    _pulseExpenseController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentMonthData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      final List<Costs> costs = await _costsService.getAllCosts();
      final List<Revenues> revenues = await _revenuesService.getAllRevenues();

      // Filtragem mais simples e robusta usando ano e mês
      final currentMonthCosts = costs.where((cost) {
        return cost.data.year == currentYear && cost.data.month == currentMonth;
      }).toList();

      final currentMonthRevenues = revenues.where((revenue) {
        return revenue.data.year == currentYear &&
            revenue.data.month == currentMonth;
      }).toList();

      // Log para depuração - mantém para verificar se está carregando corretamente
      Logger().e('Mês atual: $currentMonth/$currentYear');
      Logger().e('Total de despesas encontradas: ${costs.length}');
      Logger().e('Despesas do mês atual: ${currentMonthCosts.length}');
      Logger().e('Total de receitas encontradas: ${revenues.length}');
      Logger().e('Receitas do mês atual: ${currentMonthRevenues.length}');

      final totalCosts =
          currentMonthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);
      final totalRevenues = currentMonthRevenues.fold<double>(
          0, (sum, revenue) => sum + revenue.preco);

      final balance = totalRevenues - totalCosts;
      final expensePercentage = totalRevenues > 0
          ? (totalCosts / totalRevenues).clamp(0.0, 1.0)
          : 0.0;

      final isPositive = balance >= 0;
      final dangerZone = expensePercentage > 0.7;

      if (mounted) {
        setState(() {
          _totalCosts = totalCosts;
          _totalRevenues = totalRevenues;
          _balance = balance;
          _expensePercentage = expensePercentage;
          _isPositiveBalance = isPositive;
          _dangerZone = dangerZone;
          _isLoading = false;

          // Atualiza cor baseada no balanço
          circleColor = _isPositiveBalance
              ? (expensePercentage > 0.7 ? Colors.amber : Colors.green)
              : Colors.red;

          // Inicia animações após carregar dados
          _circleController.forward();
          _balanceTextController.forward();
          _expenseAnimController.forward();

          // Mostra confetti se o balanço for positivo e tiver boa margem
          _showConfetti = _isPositiveBalance && expensePercentage < 0.7;
          if (_showConfetti) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _confettiController.forward();
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  // Um efeito shake quando as despesas são altas
  void _shakeCircleIfDangerZone() {
    if (_dangerZone && mounted) {
      _circleController.reset();
      _circleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMonth =
        DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now()).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        // seta de voltar com GlobalKey
        leading: IconButton(
          key: _backButtonKey,
          icon: const Icon(Icons.arrow_back),
          color: theme.colorScheme.onPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saldo Mensal',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // ícone de ajuda para futuro tutorial
          IconButton(
            key: _helpButtonKey,
            icon: const Icon(Icons.help_outline),
            color: theme.colorScheme.onPrimary,
            tooltip: 'Ajuda',
            onPressed: () => _showBalanceScreenHelp(context),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: BrandLoadingAnimation(
                size: 120,
                primaryColor: theme.colorScheme.primary,
                secondaryColor: theme.colorScheme.secondary,
              ),
            )
          : Stack(
              children: [
                // Conteúdo principal
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Mês atual logo abaixo do AppBar
                      SlideAnimation.fromTop(
                        distance: 0.3,
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: FadeAnimation.fadeIn(
                          duration: const Duration(milliseconds: 800),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "Mês atual - $currentMonth",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Botão de atualização - agora posicionado acima do card
                              ScaleAnimation.bounceIn(
                                delay: const Duration(milliseconds: 500),
                                child: FloatingActionButton(
                                  mini: true,
                                  onPressed: () {
                                    _loadCurrentMonthData();
                                    _shakeCircleIfDangerZone();
                                  },
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.colorScheme.primary,
                                  elevation: 4,
                                  child: const Icon(Icons.refresh),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Círculo de saldo com animações
                      ScaleAnimation.bounceIn(
                        duration: const Duration(milliseconds: 1200),
                        child: SizedBox(
                          height: 260,
                          width: 260,
                          child: Stack(
                            key: _circleKey,
                            alignment: Alignment.center,
                            children: [
                              // Animação de ondas ao redor do círculo se finanças estiverem saudáveis
                              if (_isPositiveBalance &&
                                  _expensePercentage < 0.75)
                                AnimatedBuilder(
                                  animation: _waveAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 240 + 20 * _waveAnimation.value,
                                      height: 240 + 20 * _waveAnimation.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.green
                                              .withAlpha((0.2 * 255).toInt()),
                                          width: 3,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // Círculo base (agora VERMELHO completo)
                              AnimatedBuilder(
                                  animation: _circleAnimation,
                                  builder: (context, child) {
                                    // Aplica um efeito shake sutil se estiver em zona perigosa
                                    final shakeOffset = _dangerZone
                                        ? math.sin(_circleAnimation.value *
                                                math.pi *
                                                8) *
                                            3
                                        : 0.0;

                                    return Transform.translate(
                                      offset: Offset(shakeOffset, 0),
                                      child: CircularPercentIndicator(
                                        radius: 120.0,
                                        lineWidth: 24.0,
                                        percent: 1.0,
                                        backgroundColor: Colors.transparent,
                                        progressColor:
                                            Colors.red[500], // Agora vermelho
                                        circularStrokeCap:
                                            CircularStrokeCap.round,
                                        animation: true,
                                        animationDuration: 1000,
                                      ),
                                    );
                                  }),

                              // Efeitos de raios/derretimento quando as despesas aumentam
                              if (_expensePercentage > 0.5 && !_isLoading)
                                AnimatedBuilder(
                                    animation: _expenseAnimController,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        size: const Size(240, 240),
                                        painter: _ExpenseEffectPainter(
                                          rays: _expenseRays,
                                          progress:
                                              _expenseAnimController.value,
                                          expensePercentage: _expensePercentage,
                                        ),
                                      );
                                    }),

                              // Círculo de SAÚDE FINANCEIRA (verde por cima do vermelho)
                              AnimatedBuilder(
                                  animation: _pulseExpenseAnimation,
                                  builder: (context, _) {
                                    final effectiveStroke =
                                        _isPositiveBalance &&
                                                _expensePercentage < 0.3
                                            ? 24.0 *
                                                _pulseExpenseAnimation.value
                                            : 24.0;

                                    return AnimatedBuilder(
                                        animation: _expenseProgressAnim,
                                        builder: (context, _) {
                                          // Invertendo a lógica: quanto menor a despesa, maior a saúde
                                          final healthPercent =
                                              1.0 - _expensePercentage;
                                          final currentProgress =
                                              _expenseProgressAnim.value *
                                                  healthPercent;

                                          return CircularPercentIndicator(
                                            radius: 120.0,
                                            lineWidth: effectiveStroke,
                                            percent: currentProgress,
                                            backgroundColor: Colors.transparent,
                                            progressColor: Colors.green
                                                .withAlpha((0.8 * 255).toInt()),
                                            circularStrokeCap:
                                                CircularStrokeCap.round,
                                          );
                                        });
                                  }),

                              // Valor do saldo com animação
                              ScaleAnimation.bounceIn(
                                duration: const Duration(milliseconds: 900),
                                delay: const Duration(milliseconds: 600),
                                child: GoldenShineAnimation(
                                  intensity: _isPositiveBalance ? 0.7 : 0.0,
                                  repeat: _isPositiveBalance,
                                  child: Text(
                                    _currencyFormat.format(_balance),
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: _balance >= 0
                                          ? Colors.green[500]
                                          : Colors.red[500],
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black
                                              .withAlpha((0.2 * 255).toInt()),
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Indicador de perigo se as despesas estiverem muito altas
                              if (_expensePercentage > 0.90)
                                Positioned(
                                  top: 80,
                                  child: PulseAnimation(
                                    minScale: 0.8,
                                    maxScale: 1.2,
                                    autoPlay: true,
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      size: 40,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Card de informações
                      SlideAnimation.fromBottom(
                        distance: 0.3,
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: PressableCard(
                          onPress: () => _shakeCircleIfDangerZone(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Receitas
                                FadeAnimation.fadeIn(
                                  delay: const Duration(milliseconds: 700),
                                  child: _buildInfoRow(
                                    'Receitas',
                                    _totalRevenues,
                                    Colors.green[700]!,
                                    Colors
                                        .black87, // Corrigido para texto preto
                                  ),
                                ),
                                const Divider(),

                                // Despesas
                                FadeAnimation.fadeIn(
                                  delay: const Duration(milliseconds: 900),
                                  child: _buildInfoRow(
                                    'Despesas',
                                    _totalCosts,
                                    Colors.red[700]!,
                                    Colors
                                        .black87, // Corrigido para texto preto
                                  ),
                                ),
                                const Divider(),

                                // Saldo
                                FadeAnimation.fadeIn(
                                  delay: const Duration(milliseconds: 1100),
                                  child: _buildInfoRow(
                                    'Saldo',
                                    _balance,
                                    _balance >= 0
                                        ? Colors.green[700]!
                                        : Colors.red[700]!,
                                    Colors
                                        .black87, // Corrigido para texto preto
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Mensagem de status
                      SlideAnimation.fromBottom(
                        distance: 0.3,
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 1000),
                        child: _isPositiveBalance
                            ? GoldenShineAnimation(
                                intensity: 0.5,
                                duration: const Duration(seconds: 3),
                                child: Text(
                                  'Suas finanças estão saudáveis!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : PulseAnimation(
                                maxScale: 1.05,
                                duration: const Duration(milliseconds: 800),
                                child: Text(
                                  'Atenção! Suas despesas estão maiores que suas receitas.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),

                      // Dica ou insight personalizado
                      if (_expensePercentage > 0.8 && _isPositiveBalance)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: SlideAnimation.fromBottom(
                            distance: 0.3,
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 1200),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Colors.amber.withAlpha((0.2 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb, color: Colors.amber),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Suas despesas estão altas! Considere reduzir gastos não essenciais neste mês.',
                                      style: TextStyle(
                                        color: Colors.amber[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 50), // Espaço na parte inferior
                    ],
                  ),
                ),

                // Efeitos de celebração
                if (_showConfetti)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ConfettiAnimation(
                        direction: ConfettiDirection.down,
                        colors: [
                          Colors.green.shade300,
                          Colors.green.shade500,
                          Colors.green.shade700,
                          Colors.yellow,
                          Colors.amber,
                          Colors.white,
                        ],
                        particleCount: 30,
                        animationController: _confettiController,
                        repeat: false,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // Adicione este método na classe _BalanceScreenState
  void _showBalanceScreenHelp(BuildContext context) {
    final theme = Theme.of(context);

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
                                  "Saldo Mensal",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Entendendo sua situação financeira",
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

                    // Seção 1: Círculo de Saúde Financeira
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Indicador de Saúde Financeira",
                        icon: Icons.show_chart,
                        iconColor: theme.colorScheme.primary,
                        content:
                            "O círculo central mostra visualmente sua saúde financeira:\n\n"
                            "• Círculo Verde: Quanto maior a área verde, melhor sua situação\n\n"
                            "• Círculo Vermelho: Representa o total de despesas em relação às receitas\n\n"
                            "• Efeitos Visuais: Raios vermelhos aparecem quando as despesas estão muito altas\n\n"
                            "• Valor Central: Mostra seu saldo atual (receitas menos despesas)",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Card de Informações Financeiras
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Detalhes Financeiros",
                        icon: Icons.info_outline,
                        iconColor: Colors.blue,
                        content:
                            "O card de informações mostra o resumo detalhado:\n\n"
                            "• Receitas: Total de entradas financeiras do mês atual\n\n"
                            "• Despesas: Total de saídas financeiras do mês atual\n\n"
                            "• Saldo: Diferença entre receitas e despesas\n\n"
                            "• Os valores são calculados apenas para o mês atual",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Mensagens e Alertas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Mensagens de Status",
                        icon: Icons.message,
                        iconColor: Colors.green,
                        content:
                            "Abaixo do resumo financeiro, você receberá mensagens personalizadas:\n\n"
                            "• Mensagem Verde: Quando seu saldo é positivo\n\n"
                            "• Mensagem Vermelha: Quando as despesas excedem as receitas\n\n"
                            "• Alerta Âmbar: Quando as despesas estão muito próximas das receitas\n\n"
                            "• Dicas Personalizadas: Conselhos financeiros baseados na sua situação atual",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Efeitos Visuais
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Efeitos Visuais",
                        icon: Icons.animation,
                        iconColor: Colors.purple,
                        content:
                            "Os efeitos visuais ajudam a entender sua situação financeira:\n\n"
                            "• Confetes Verdes: Aparecem quando seu saldo é positivo e saudável\n\n"
                            "• Ondas Verdes: Indicam finanças em equilíbrio\n\n"
                            "• Raios Vermelhos: Alertam quando as despesas estão consumindo suas receitas\n\n"
                            "• Pulsação: O círculo central pulsa quando sua situação financeira é crítica",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Botão de Atualização
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Atualizando os Dados",
                        icon: Icons.refresh,
                        iconColor: Colors.teal,
                        content: "Mantenha seus dados atualizados:\n\n"
                            "• Botão Atualizar: Recarrega todos os dados financeiros do mês atual\n\n"
                            "• Use após registrar novas receitas ou despesas\n\n"
                            "• Os dados são filtrados automaticamente para exibir apenas o mês corrente\n\n"
                            "• A tela atualiza animações e alertas conforme sua situação financeira",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary
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
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Para manter suas finanças saudáveis, tente manter suas despesas abaixo de 70% das suas receitas. Isso garante uma margem de segurança e possibilita economias para o futuro.",
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
                        child: ElevatedButton(
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

  Widget _buildInfoRow(
      String label, double value, Color valueColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                label == 'Receitas'
                    ? Icons.arrow_circle_up
                    : label == 'Despesas'
                        ? Icons.arrow_circle_down
                        : Icons.account_balance_wallet,
                color: labelColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ],
          ),
          AnimatedCounter(
            begin: 0,
            end: value.toInt(),
            duration: const Duration(milliseconds: 1500),
            formatter: (value) => _currencyFormat.format(value),
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe para definir os raios que representam as despesas "derretendo" as receitas
class _ExpenseRay {
  final double angle;
  final double speed;
  final double length;
  final double thickness;
  final double opacity;
  final double delay;

  _ExpenseRay({
    required this.angle,
    required this.speed,
    required this.length,
    required this.thickness,
    required this.opacity,
    required this.delay,
  });
}

/// Custompainter que desenha os efeitos visuais para as despesas
class _ExpenseEffectPainter extends CustomPainter {
  final List<_ExpenseRay> rays;
  final double progress;
  final double expensePercentage;

  _ExpenseEffectPainter({
    required this.rays,
    required this.progress,
    required this.expensePercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Só exibe os raios quando as despesas são significativas
    if (expensePercentage < 0.4) return;

    // Efeito mais intenso conforme as despesas aumentam
    final intensity = math.min(1.0, (expensePercentage - 0.4) / 0.6);

    // Desenha os raios que saem do círculo vermelho
    for (final ray in rays) {
      // Calcula o progresso ajustado com atraso para cada raio
      final rayProgress = math.max(0.0, progress - ray.delay);
      if (rayProgress <= 0) continue;

      // O ângulo atual inclui o progresso da animação para movimento
      final currentAngle = ray.angle + rayProgress * ray.speed * 10;

      // Ponto do círculo onde o raio começa
      final startRadius =
          radius * (1.02 - 0.05 * math.sin(rayProgress * math.pi));
      final startPoint = Offset(
          center.dx + math.cos(currentAngle) * startRadius,
          center.dy + math.sin(currentAngle) * startRadius);

      // Ponto final do raio (com comprimento variável)
      final effectiveLength = ray.length *
          intensity *
          (0.6 + 0.4 * math.sin(rayProgress * math.pi * 3));
      final endPoint = Offset(
          startPoint.dx + math.cos(currentAngle) * effectiveLength,
          startPoint.dy + math.sin(currentAngle) * effectiveLength);

      // Desenha o raio
      final paint = Paint()
        ..color = Colors.red.withAlpha((ray.opacity * intensity * 255).toInt())
        ..strokeWidth = ray.thickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(startPoint, endPoint, paint);

      // Adiciona um pequeno brilho no final do raio para efeito de "derretimento"
      final glowPaint = Paint()
        ..color = Colors.orange
            .withAlpha((ray.opacity * 0.7 * intensity * 255).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(endPoint, ray.thickness * 1.5, glowPaint);
    }

    // Adiciona um efeito de "ondas de calor" ao redor do círculo
    if (expensePercentage > 0.7) {
      final heatWavePaint = Paint()
        ..color = Colors.red.withAlpha((0.1 * 255).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < 3; i++) {
        final waveRadius = radius + 10 + i * 8;
        final waveOffset = 4 * math.sin(progress * math.pi * 2 + i * 1.0);

        final waveRect = Rect.fromCenter(
          center: Offset(center.dx + waveOffset, center.dy),
          width: waveRadius * 2,
          height: waveRadius * 2,
        );

        canvas.drawArc(
          waveRect,
          0, // ângulo inicial
          math.pi * 2, // ângulo completo
          false,
          heatWavePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ExpenseEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.expensePercentage != expensePercentage;
  }
}
