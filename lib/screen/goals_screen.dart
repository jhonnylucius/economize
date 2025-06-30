import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/data/goal_dao.dart'; // Importante usar o correto
import 'package:economize/features/financial_education/utils/currency_input_formatter.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/gamification/achievement_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:math' as math;
import 'package:economize/theme/theme_manager.dart';

import 'package:uuid/uuid.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with TickerProviderStateMixin {
  final GoalsDAO _goalsDAO = GoalsDAO();
  List<Goal> _goals = [];
  bool _isLoading = true;
  late AnimationController _backgroundController;
  late AnimationController _celebrationController;
  bool _showCelebration = false;
  int? _celebratingGoalIndex;
  final Logger logger = Logger();
  // chaves para tutorial interativo
  final GlobalKey _helpButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: false);

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _loadGoals();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _goalsDAO.findAll();

      // Log para depuração
      logger.d('Metas carregadas: ${goals.length}');
      for (var goal in goals) {
        logger.d(
            'Meta: ${goal.name}, Progresso: ${goal.currentValue}/${goal.targetValue}');
      }

      // A linha abaixo é crucial: ela cria uma nova lista de Goal
      if (mounted) {
        setState(() {
          _goals = List<Goal>.from(goals); // Cria uma nova lista
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Erro ao carregar metas: $e');
      if (mounted) {
        _showError('Erro ao carregar metas: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = ThemeManager();

    return ResponsiveScreen(
      appBar: AppBar(
        title: SlideAnimation.fromTop(
          child: const Text(
            'Minhas Metas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          SlideAnimation.fromTop(
            child: IconButton(
              icon: const Icon(Icons.calculate_outlined),
              tooltip: 'Calculadora de Metas',
              onPressed: () {
                Navigator.pushNamed(context, '/calculator');
              },
            ),
          ),
          SlideAnimation.fromTop(
            delay: const Duration(milliseconds: 200),
            child: IconButton(
              key: _helpButtonKey, // Chave para tutorial
              tooltip: 'Ajuda', // Texto do tooltip
              icon: const Icon(
                Icons.help_outline, // Ícone de ajuda
                color: Colors.white,
              ),
              onPressed: () =>
                  _showGoalsScreenHelp(context), // Chama o método de ajuda
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white, // Sempre fundo branco
      floatingActionButton: ScaleAnimation.bounceIn(
        delay: const Duration(milliseconds: 300),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: themeManager.getHomeButtonIconColor(), // ✅ COR DE FUNDO
            borderRadius: BorderRadius.circular(12), // ✅ QUADRADO ARREDONDADO
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _addNewGoal,
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                Icons.add, // ✅ ÍCONE + SIMPLES
                color:
                    themeManager.getTipCardBackgroundColor(), // ✅ COR DO ÍCONE
                size: 28,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GoalsBackgroundPainter(
                    color: theme.colorScheme.primary,
                    progress: _backgroundController.value,
                  ),
                );
              },
            ),
          ),

          // Conteúdo principal
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitLoadingAnimation(
                        color: theme.colorScheme.primary,
                        size: 60,
                        duration: const Duration(seconds: 1),
                      ),
                      const SizedBox(height: 16),
                      FadeAnimation(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'Carregando suas metas...',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _goals.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildGoalsList(theme),

          // Confetti animation for goal celebration
          if (_showCelebration && _celebratingGoalIndex != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiAnimation(
                  particleCount: 100, // ✅ DOBREI AS PARTÍCULAS
                  direction: ConfettiDirection.down,
                  duration: const Duration(seconds: 4), // ✅ MAIS DURAÇÃO
                  animationController: _celebrationController,
                  colors: [
                    Colors.amber, // ✅ CORES MAIS VIBRANTES
                    Colors.orange,
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.cyan, // ✅ CORES EXTRAS
                    Colors.lime,
                    Colors.indigo,
                    Colors.teal,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Adicione este método na classe _GoalsScreenState
  void _showGoalsScreenHelp(BuildContext context) {
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
                    SlideAnimation.fromTop(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.flag,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Minhas Metas",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Como gerenciar seus objetivos financeiros",
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

                    // Seção 1: Cards de Meta
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Cards de Metas",
                        icon: Icons.credit_card,
                        iconColor: theme.colorScheme.primary,
                        content:
                            "Cada card representa uma meta financeira que você está perseguindo:\n\n"
                            "• Nome da Meta: Descrição do seu objetivo financeiro\n\n"
                            "• Ícone de Status: Bandeira (em andamento) ou Troféu (completa)\n\n"
                            "• Indicador Circular: Mostra visualmente seu progresso percentual\n\n"
                            "• Valores: Meta total, valor economizado e quanto falta",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Atualizar Progresso
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Atualização de\n Progresso",
                        icon: Icons.update,
                        iconColor: Colors.green,
                        content: "Para registrar seu progresso em uma meta:\n\n"
                            "• Clique no botão 'Atualizar' em um card de meta\n\n"
                            "• Use o controle deslizante ou digite o valor atual economizado\n\n"
                            "• O indicador de progresso será atualizado automaticamente\n\n"
                            "• Quando você atingir 100%, a meta será marcada como completa",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Opções de Meta
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Opções de Meta",
                        icon: Icons.more_vert,
                        iconColor: Colors.blue,
                        content:
                            "Clique no ícone de três pontos para ver as opções disponíveis:\n\n"
                            "• Atualizar Progresso: Registre quanto você economizou\n\n"
                            "• Editar Meta: Modifique o nome ou valor da meta\n\n"
                            "• Ver Detalhes: Exibe informações detalhadas sobre a meta\n\n"
                            "• Comemorar Conquista: Celebre quando a meta for concluída\n\n"
                            "• Excluir Meta: Remove a meta permanentemente",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Detalhes da Meta
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Detalhes da Meta",
                        icon: Icons.visibility,
                        iconColor: Colors.purple,
                        content:
                            "Toque em um card para ver informações detalhadas:\n\n"
                            "• Progresso Visual: Gráfico ampliado com seu percentual\n\n"
                            "• Valor Faltante: Quanto ainda precisa ser economizado\n\n"
                            "• Data de Criação: Quando você estabeleceu esta meta\n\n"
                            "• Status Atual: Se a meta está em andamento ou concluída\n\n"
                            "• Botões de Ação: Editar, Atualizar ou Excluir a meta",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Criando Novas Metas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Criando Novas\n Metas",
                        icon: Icons.add_circle_outline,
                        iconColor: Colors.amber,
                        content: "Para criar uma nova meta financeira:\n\n"
                            "• Toque no botão flutuante 'Nova Meta'\n\n"
                            "• Dê um nome descritivo para sua meta\n\n"
                            "• Defina o valor total que deseja alcançar\n\n"
                            "• Comece com valor zero e vá atualizando seu progresso",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Calculadora de Metas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Calculadora \nde Metas",
                        icon: Icons.calculate_outlined,
                        iconColor: Colors.teal,
                        content:
                            "Use a calculadora de metas para planejar melhor:\n\n"
                            "• Clique no ícone de calculadora na barra superior\n\n"
                            "• Defina valores como valor alvo, taxa de juros e prazo\n\n"
                            "• Veja quanto precisa economizar mensalmente\n\n"
                            "• Use esta ferramenta para planejar melhor suas economias",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 7: Celebrando Conquistas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 700),
                      child: _buildHelpSection(
                        context: context,
                        title: "7. Celebrando \nConquistas",
                        icon: Icons.celebration,
                        iconColor: Colors.orange,
                        content: "Quando você atinge uma meta:\n\n"
                            "• O card mudará para exibir um troféu\n\n"
                            "• Uma animação de confetes será exibida automaticamente\n\n"
                            "• Você pode acionar a comemoração novamente através das opções da meta\n\n"
                            "• Reconheça e celebre seu progresso financeiro!",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 800),
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
                              "Defina metas SMART: Específicas, Mensuráveis, Alcançáveis, Relevantes e com Prazo definido. Estipule pequenas metas intermediárias para manter sua motivação alta durante o processo.",
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
                        delay: const Duration(milliseconds: 900),
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: FadeAnimation(
        child: ScaleAnimation(
          child: GlassContainer(
            frostedEffect: true,
            blur: 5,
            opacity: 0.1,
            borderRadius: 20,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 60,
                    color: theme.colorScheme.primary
                        .withAlpha((0.7 * 255).toInt()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma meta definida ainda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Defina objetivos financeiros e acompanhe seu progresso rumo à conquista.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PressableCard(
                    onPress: _addNewGoal,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withAlpha((0.3 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Criar minha primeira meta',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botão adicional para calculadora de metas
                  const SizedBox(height: 12),
                  PressableCard(
                    onPress: () => Navigator.pushNamed(context, '/calculator'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withAlpha((0.3 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calculate,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Usar calculadora de metas',
                            style: TextStyle(
                              color: Colors.white,
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
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList(ThemeData theme) {
    return ListView.builder(
      itemCount: _goals.length,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return SlideAnimation.fromRight(
          delay: Duration(milliseconds: 100 * index),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildGoalCard(goal, index, theme),
          ),
        );
      },
    );
  }

  Widget _buildGoalCard(Goal goal, int index, ThemeData theme) {
    final percentComplete = goal.percentComplete.clamp(0.0, 1.0);
    final isCompleted = percentComplete >= 1.0;
    final progressColor =
        isCompleted ? Colors.green.shade600 : theme.colorScheme.primary;
    final daysElapsed =
        DateTime.now().difference(goal.createdAt ?? DateTime.now()).inDays;

    return PressableCard(
      onPress: () => _showGoalDetails(goal),
      pressedScale: 0.98,
      child: GlassContainer(
        frostedEffect: true,
        borderRadius: 20,
        blur: 5,
        opacity: 0.08,
        borderColor: isCompleted
            ? Colors.green.withAlpha((0.3 * 255).toInt())
            : theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Goal header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: progressColor.withAlpha((0.15 * 255).toInt()),
                        ),
                        child: Icon(
                          isCompleted ? Icons.emoji_events : Icons.flag,
                          color: progressColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                goal.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (isCompleted)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green
                                        .withAlpha((0.15 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Completa',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Meta criada ${_formatElapsedDays(daysElapsed)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: Colors.black54,
                    onPressed: () => _showGoalOptions(goal, index),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // LAYOUT MODIFICADO: Progress section with button to the right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Progress circular indicator
                  CircularPercentIndicator(
                    radius: 50,
                    lineWidth: 10,
                    percent: percentComplete,
                    center: Text(
                      '${(percentComplete * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    progressColor: progressColor,
                    backgroundColor:
                        progressColor.withAlpha((0.15 * 255).toInt()),
                    animation: true,
                    animationDuration: 1500,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),

                  const SizedBox(width: 20),

                  // BOTÃO ATUALIZAR (movido para a direita do círculo)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Update Progress Button (faded if complete)
                        Opacity(
                          opacity: isCompleted ? 0.5 : 1.0,
                          child: PressableCard(
                            onPress: isCompleted
                                ? null
                                : () => _updateProgress(goal),
                            pressedScale: 0.95,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: theme.colorScheme.primary
                                  .withAlpha((0.1 * 255).toInt()),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Atualizar',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // VALORES MOVIDOS PARA BAIXO DO CÍRCULO
              const SizedBox(height: 16),

              // Goal values
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withAlpha((0.05 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildValueRow(
                      label: 'Meta',
                      value: goal.targetValue,
                      icon: Icons.flag,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildValueRow(
                      label: 'Economizado',
                      value: goal.currentValue,
                      icon: Icons.savings,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 8),
                    _buildValueRow(
                      label: 'Faltam',
                      value: goal.remainingValue,
                      icon: Icons.update,
                      color: Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueRow({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    // ADICIONAR: Formatador brasileiro
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatElapsedDays(int days) {
    if (days == 0) return 'hoje';
    if (days == 1) return 'há 1 dia';
    if (days < 30) return 'há $days dias';

    final months = (days / 30).floor();
    if (months == 1) return 'há 1 mês';
    if (months < 12) return 'há $months meses';

    final years = (months / 12).floor();
    if (years == 1) return 'há 1 ano';
    return 'há $years anos';
  }

  void _showGoalDetails(Goal goal) {
    final theme = Theme.of(context);
    final percentComplete = goal.percentComplete.clamp(0.0, 1.0);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeAnimation(
                      child: Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Large progress indicator
                    FadeAnimation(
                      delay: const Duration(milliseconds: 200),
                      child: Center(
                        child: CircularPercentIndicator(
                          radius: 120,
                          lineWidth: 15,
                          percent: percentComplete,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Progresso',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(percentComplete * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                '${currencyFormat.format(goal.currentValue)} / ${currencyFormat.format(goal.targetValue)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          progressColor: percentComplete >= 1.0
                              ? Colors.green
                              : theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.primary.withAlpha(
                            (0.15 * 255).toInt(),
                          ),
                          animation: true,
                          animationDuration: 2000,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Details cards
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 400),
                      child: _buildDetailCard(
                        title: 'Faltam',
                        value: currencyFormat.format(goal.remainingValue),
                        icon: Icons.timeline,
                        color: Colors.orange,
                        theme: theme,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 500),
                      child: _buildDetailCard(
                        title: 'Meta criada em',
                        value: _formatDate(goal.createdAt ?? DateTime.now()),
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                        theme: theme,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 600),
                      child: _buildDetailCard(
                        title: 'Status',
                        value: percentComplete >= 1.0
                            ? 'Meta alcançada'
                            : 'Em andamento',
                        icon: percentComplete >= 1.0
                            ? Icons.emoji_events
                            : Icons.hourglass_bottom,
                        color: percentComplete >= 1.0
                            ? Colors.green
                            : Colors.amber,
                        theme: theme,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Actions
                    ScaleAnimation(
                      delay: const Duration(milliseconds: 700),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Editar',
                              icon: Icons.edit,
                              onPressed: () {
                                Navigator.pop(context);
                                _editGoal(goal);
                              },
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Atualizar',
                              icon: Icons.update,
                              onPressed: percentComplete >= 1.0
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _updateProgress(goal);
                                    },
                              color: Colors.green,
                              isDisabled: percentComplete >= 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScaleAnimation(
                      delay: const Duration(milliseconds: 800),
                      child: _buildActionButton(
                        label: 'Excluir Meta',
                        icon: Icons.delete,
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteGoal(goal);
                        },
                        color: theme.colorScheme.error,
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

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return GlassContainer(
      frostedEffect: true,
      blur: 3,
      opacity: 0.05,
      borderRadius: 16,
      borderColor: color.withAlpha((0.3 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: PressableCard(
        onPress: onPressed,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((0.3 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showGoalOptions(Goal goal, int index) {
    final theme = Theme.of(context);
    final isCompleted = goal.percentComplete >= 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeAnimation(
              child: Text(
                goal.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isCompleted)
              SlideAnimation.fromBottom(
                delay: const Duration(milliseconds: 100),
                child: _buildOptionItem(
                  label: 'Atualizars progresso',
                  icon: Icons.update,
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _updateProgress(goal);
                  },
                ),
              ),
            SlideAnimation.fromBottom(
              delay: const Duration(milliseconds: 150),
              child: _buildOptionItem(
                label: 'Editar meta',
                icon: Icons.edit,
                color: theme.colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _editGoal(goal);
                },
              ),
            ),
            SlideAnimation.fromBottom(
              delay: const Duration(milliseconds: 200),
              child: _buildOptionItem(
                label: 'Ver detalhes',
                icon: Icons.visibility_outlined,
                color: theme.colorScheme.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _showGoalDetails(goal);
                },
              ),
            ),
            if (isCompleted)
              SlideAnimation.fromBottom(
                delay: const Duration(milliseconds: 250),
                child: _buildOptionItem(
                  label: 'Comemorar conquista',
                  icon: Icons.celebration,
                  color: Colors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    // ✅ ENCONTRAR O ÍNDICE CORRETO DA META
                    final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
                    if (goalIndex >= 0) {
                      _celebrateGoal(goalIndex);
                    } else {
                      Logger().e('❌ Meta não encontrada para comemoração');
                    }
                  },
                ),
              ),
            SlideAnimation.fromBottom(
              delay: const Duration(milliseconds: 300),
              child: _buildOptionItem(
                label: 'Excluir meta',
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _deleteGoal(goal);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).toInt()),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  void _celebrateGoal(int index) {
    // ✅ VERIFICAR SE O ÍNDICE É VÁLIDO
    if (index < 0 || index >= _goals.length) {
      Logger().e('❌ Índice inválido para comemoração: $index');
      return;
    }

    // ✅ RESETAR E GARANTIR QUE ESTÁ LIMPO
    _celebrationController.stop();
    _celebrationController.reset();

    setState(() {
      _celebratingGoalIndex = index;
      _showCelebration = true;
    });

    Logger()
        .e('🎉 Iniciando SUPER comemoração para meta ${_goals[index].name}');

    // ✅ SUPER CONFETTI MÚLTIPLO!
    _startSuperConfetti();

    // ✅ SUPER HAPTIC FEEDBACK
    _superHapticShow();

    // ✅ MÚLTIPLAS MENSAGENS DE PARABÉNS
    _showMultipleCelebrationMessages(_goals[index].name);

    // ✅ ESCONDER APÓS 10 SEGUNDOS (dobrei o tempo)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showCelebration = false;
          _celebratingGoalIndex = null;
        });
        _celebrationController.stop();
        Logger().e('🎊 SUPER comemoração finalizada');
      }
    });
  }

// 🎆 MÉTODO SUPER CONFETTI
  void _startSuperConfetti() async {
    // Primeira onda de confetti
    _celebrationController.forward(from: 0.0);

    // Segunda onda após 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _showCelebration) {
      _celebrationController.reset();
      _celebrationController.forward(from: 0.0);
    }

    // Terceira onda após 4 segundos
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _showCelebration) {
      _celebrationController.reset();
      _celebrationController.forward(from: 0.0);
    }

    Logger().e('🎆 TRIPLO confetti executado!');
  }

// 📳 SUPER HAPTIC FEEDBACK
  void _superHapticShow() async {
    // Primeira vibração forte
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 500));
    HapticFeedback.heavyImpact();

    Logger().e('📳 SUPER vibração executada!');
  }

// 🎊 MÚLTIPLAS MENSAGENS DE COMEMORAÇÃO
  void _showMultipleCelebrationMessages(String goalName) {
    final superMessages = [
      '🎉 INCRÍVEL! Meta "$goalName" CONQUISTADA!',
      '🏆 PARABÉNS! Você é DEMAIS!',
      '🎊 SUCESSO TOTAL! Meta "$goalName" 100% COMPLETA!',
      '🚀 VOCÊ CONSEGUIU! OBJETIVO ALCANÇADO!',
      '💪 FORÇA TOTAL! Meta "$goalName" DOMINADA!',
      '⭐ ESTRELA! Você brilhou nesta conquista!',
      '🎯 CERTEIRO! Meta "$goalName" no alvo!',
      '🔥 FOGO! Que conquista incrível!',
    ];

    // Primeira mensagem imediata
    _showSingleCelebrationMessage(superMessages[0]);

    // Segunda mensagem após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _showSingleCelebrationMessage(superMessages[1]);
      }
    });

    // Terceira mensagem após 6 segundos
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _showSingleCelebrationMessage(superMessages[2]);
      }
    });
  }

  void _showSingleCelebrationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎆', style: TextStyle(fontSize: 24)), // ✅ ÍCONE MAIOR
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // ✅ TEXTO MAIOR
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration:
            const Duration(seconds: 3), // ✅ DURAÇÃO MENOR PRA NÃO SOBREPOR
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // ✅ MAIS ARREDONDADO
        ),
        action: SnackBarAction(
          label: '🎉 MAIS!',
          textColor: Colors.white,
          onPressed: () {
            // Confete EXTRA manual!
            HapticFeedback.heavyImpact();
            if (_showCelebration) {
              _celebrationController.reset();
              _celebrationController.forward();
            }
          },
        ),
      ),
    );
  }

  // MÉTODOS CORRIGIDOS PARA FUNCIONAREM CORRETAMENTE

  void _addNewGoal() async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => _GoalDialog(),
    );

    if (result != null) {
      try {
        // Verificar o ID antes de salvar
        logger.d('ID da nova meta: ${result.id}');
        logger.d('Nome da meta: ${result.name}');
        logger.d('Valor alvo: ${result.targetValue}');

        // Sempre garantir que há um ID válido
        final goalToSave = (result.id == null || result.id!.isEmpty)
            ? Goal(
                id: const Uuid().v4(),
                name: result.name,
                targetValue: result.targetValue,
                currentValue: result.currentValue,
                createdAt: result.createdAt,
              )
            : result;

        await _goalsDAO.save(goalToSave);

        // ✅ VERIFICAR CONQUISTAS AUTOMÁTICAS!
        await AchievementChecker.checkAllAchievements();

        await _loadGoals();

        if (mounted) {
          _showSuccess('Meta adicionada com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao adicionar meta: $e');
          logger.e('Erro detalhado: $e'); // Log para depuração
        }
      }
    }
  }

  void _editGoal(Goal goal) async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => _GoalDialog(goal: goal),
    );

    if (result != null) {
      try {
        // Mantenha o ID original para a meta editada
        final updatedGoal = Goal(
          id: goal.id,
          name: result.name,
          targetValue: result.targetValue,
          currentValue: result.currentValue,
          createdAt: result.createdAt,
        );

        await _goalsDAO.update(updatedGoal);

        // ✅ VERIFICAR CONQUISTAS AUTOMÁTICAS!
        await AchievementChecker.checkAllAchievements();

        await _loadGoals();

        if (mounted) {
          _showSuccess('Meta atualizada com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao atualizar meta: $e');
        }
      }
    }
  }

  void _updateProgress(Goal goal) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
    if (goalIndex == -1) return;

    logger.d('Atualizando meta com ID: ${goal.id}');

    final result = await showDialog<double>(
      context: context,
      builder: (context) => _UpdateProgressDialog(
        currentValue: goal.currentValue,
        targetValue: goal.targetValue,
      ),
    );

    if (result != null) {
      try {
        final oldValue = goal.currentValue;

        // Criar uma nova instância de meta com o valor atualizado
        final updatedGoal = Goal(
          id: goal.id,
          name: goal.name,
          targetValue: goal.targetValue,
          currentValue: result,
          createdAt: goal.createdAt,
        );

        // Atualizar no banco de dados
        await _goalsDAO.update(updatedGoal);

        // ✅ VERIFICAR CONQUISTAS AUTOMÁTICAS!
        await AchievementChecker.checkAllAchievements();

        // Atualizar na lista local
        setState(() {
          _goals[goalIndex] = updatedGoal;
        });

        // Log para depuração
        logger.d(
            'Meta atualizada: ${updatedGoal.name}, Progresso: ${updatedGoal.currentValue}/${updatedGoal.targetValue}');
        logger.d('Percentual: ${updatedGoal.percentComplete}');

        // Para garantir sincronização com o banco de dados
        await _loadGoals();

        // Celebrar a conclusão da meta se foi atingida agora
        if (oldValue < goal.targetValue && result >= goal.targetValue) {
          _celebrateGoal(goalIndex);
        }

        _showSuccess('Progresso atualizado com sucesso!');
      } catch (e) {
        logger.e('Erro ao atualizar progresso: $e');
        _showError('Erro ao atualizar progresso: $e');
      }
    }
  }

  void _deleteGoal(Goal goal) async {
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Excluir Meta',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir esta meta?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goal.name,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Esta ação não poderá ser desfeita.',
              style: TextStyle(
                color: theme.colorScheme.error.withAlpha((0.8 * 255).toInt()),
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
          PressableCard(
            onPress: () => Navigator.pop(context, true),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.error,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: theme.colorScheme.onError,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Excluir',
                    style: TextStyle(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && goal.id != null) {
      // Verificar se há um ID
      try {
        await _goalsDAO.delete(goal.id!);

        // ✅ VERIFICAR CONQUISTAS AUTOMÁTICAS APÓS EXCLUSÃO!
        await AchievementChecker.checkAllAchievements();

        await _loadGoals();

        if (mounted) {
          _showSuccess('Meta excluída com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao excluir meta: $e');
        }
      }
    }
  }

  // Enhanced success snackbar
  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Enhanced error snackbar
  void _showError(String message) {
    if (!mounted) return;

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _GoalsBackgroundPainter extends CustomPainter {
  final Color color;
  final double progress;

  _GoalsBackgroundPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 15;
    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = -1; i < 20; i++) {
      for (int j = -1; j < 40; j++) {
        final x = i * cellSize + random.nextDouble() * (cellSize * 0.5);
        final y = j * cellSize + random.nextDouble() * (cellSize * 0.5);

        final shapeType = (i + j) % 4;
        final shapeSize = cellSize * (0.1 + random.nextDouble() * 0.1);

        switch (shapeType) {
          case 0:
            // Flag for goals
            _drawFlag(canvas, paint, x, y, shapeSize);
            break;
          case 1:
            // Dollar sign for savings
            _drawDollar(canvas, paint, x, y, shapeSize);
            break;
          case 2:
            // Circle for coins
            canvas.drawCircle(Offset(x, y), shapeSize * 0.5, paint);
            break;
          case 3:
            // Chart icon for progress
            _drawChart(canvas, paint, x, y, shapeSize);
            break;
        }
      }
    }
  }

  void _drawFlag(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();

    // Pole
    path.moveTo(x - size * 0.2, y - size);
    path.lineTo(x - size * 0.2, y + size);

    // Flag part
    path.moveTo(x - size * 0.2, y - size * 0.8);
    path.lineTo(x + size * 0.8, y - size * 0.4);
    path.lineTo(x - size * 0.2, y);

    canvas.drawPath(path, paint);
  }

  void _drawDollar(
      Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();

    // Vertical line
    path.moveTo(x, y - size);
    path.lineTo(x, y + size);

    // S part
    path.moveTo(x + size * 0.6, y - size * 0.6);
    path.quadraticBezierTo(x - size * 0.6, y - size * 0.3, x - size * 0.5, y);
    path.quadraticBezierTo(
        x + size * 0.6, y + size * 0.3, x + size * 0.5, y + size * 0.6);

    canvas.drawPath(path, paint);
  }

  void _drawChart(Canvas canvas, Paint paint, double x, double y, double size) {
    // Simple bar chart
    canvas.drawRect(Rect.fromLTWH(x - size, y, size * 0.4, -size * 0.5), paint);
    canvas.drawRect(
        Rect.fromLTWH(x - size * 0.4, y, size * 0.4, -size * 0.8), paint);
    canvas.drawRect(
        Rect.fromLTWH(x + size * 0.2, y, size * 0.4, -size * 0.3), paint);
  }

  @override
  bool shouldRepaint(_GoalsBackgroundPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

// Loading animation to use in the screen
class SpinKitLoadingAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const SpinKitLoadingAnimation({
    super.key,
    required this.color,
    this.size = 50.0,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<SpinKitLoadingAnimation> createState() =>
      _SpinKitLoadingAnimationState();
}

class _SpinKitLoadingAnimationState extends State<SpinKitLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SpinKitPainter(
              controller: _controller,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _SpinKitPainter extends CustomPainter {
  final AnimationController controller;
  final Color color;

  _SpinKitPainter({
    required this.controller,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    const int itemCount = 8;
    const double itemRadius = 3.0;

    for (int i = 0; i < itemCount; i++) {
      final double angle = 2 * math.pi * (i / itemCount);
      final double rotation = 2 * math.pi * controller.value;

      // Position on the circle
      final double x = centerX + radius * 0.7 * math.cos(angle + rotation);
      final double y = centerY + radius * 0.7 * math.sin(angle + rotation);

      // Determine opacity based on position
      final double opacityValue =
          1.0 - (((i / itemCount) + controller.value) % 1.0);
      final double opacity = 0.2 + (0.8 * opacityValue);
      final double itemSize = itemRadius + (itemRadius * opacityValue * 0.5);

      final paint = Paint()
        ..color = color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), itemSize, paint);
    }
  }

  @override
  bool shouldRepaint(_SpinKitPainter oldDelegate) {
    return oldDelegate.controller.value != controller.value ||
        oldDelegate.color != color;
  }
}

// Enhanced version of the GoalDialog
class _GoalDialog extends StatefulWidget {
  final Goal? goal;

  const _GoalDialog({this.goal});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      // FORMATAR O VALOR EXISTENTE
      _valueController.text = CurrencyParser.format(widget.goal!.targetValue);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.goal != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20), // REDUZIR PADDING
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // REDUZIR PADDING DO ÍCONE
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.flag,
              color: theme.colorScheme.primary,
              size: 20, // REDUZIR TAMANHO DO ÍCONE
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Editar Meta' : 'Nova Meta',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18, // REDUZIR TAMANHO DO TÍTULO
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black87), // COR DO TEXTO
                decoration: InputDecoration(
                  labelText: 'Nome da Meta',
                  labelStyle: TextStyle(
                      color: theme.colorScheme.primary), // COR DA LABEL
                  hintText: 'Ex: Viagem para a praia',
                  hintStyle:
                      const TextStyle(color: Colors.black54), // COR DO HINT
                  prefixIcon: Icon(Icons.bookmark_outline,
                      color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome da meta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                style: const TextStyle(color: Colors.black87), // COR DO TEXTO
                decoration: InputDecoration(
                  labelText: 'Valor da Meta',
                  labelStyle: TextStyle(
                      color: theme.colorScheme.primary), // COR DA LABEL
                  hintText: 'Ex: 5.000,00',
                  hintStyle:
                      const TextStyle(color: Colors.black54), // COR DO HINT
                  prefixIcon: Icon(Icons.attach_money,
                      color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o valor da meta';
                  }
                  try {
                    final number = CurrencyParser.parse(value);
                    if (number <= 0) return 'Valor deve ser maior que zero';
                  } catch (e) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        // BOTÃO CANCELAR MAIS FINO
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8), // PADDING MENOR
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14, // TEXTO MENOR
            ),
          ),
        ),
        // BOTÃO CRIAR/SALVAR MAIS FINO
        ElevatedButton.icon(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8), // PADDING MENOR
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(Icons.save, size: 16), // ÍCONE MENOR
          label: Text(
            isEditing ? 'Salvar' : 'Criar',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14, // TEXTO MENOR
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final name = _nameController.text.trim();

        // LINHA 2091 - DEVE ESTAR ASSIM (ERRADO):
        // final value = double.parse(_valueController.text.replaceAll(',', '.')); ❌

        // CORRIGIR PARA:
        final valueText = _valueController.text.trim();
        final value = CurrencyParser.parse(valueText);

        final goal = Goal(
          id: widget.goal?.id ?? const Uuid().v4(),
          name: name,
          targetValue: value,
          currentValue: widget.goal?.currentValue ?? 0.0,
          createdAt: widget.goal?.createdAt ?? DateTime.now(),
        );

        Navigator.pop(context, goal);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar valor: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Enhanced update progress dialog
class _UpdateProgressDialog extends StatefulWidget {
  final double currentValue;
  final double targetValue;

  const _UpdateProgressDialog({
    required this.currentValue,
    required this.targetValue,
  });

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    // FORMATAR O VALOR INICIAL
    _valueController.text = CurrencyParser.format(widget.currentValue);
    _sliderValue = widget.currentValue;

    _valueController.addListener(_updateSliderFromText);
  }

  @override
  void dispose() {
    _valueController.removeListener(_updateSliderFromText);
    _valueController.dispose();
    super.dispose();
  }

  void _updateSliderFromText() {
    final value = CurrencyParser.parse(_valueController.text); // USAR PARSER
    setState(() {
      _sliderValue = value.clamp(0.0, widget.targetValue);
    });
  }

  void _updateTextFromSlider(double value) {
    _valueController.text = CurrencyParser.format(value); // USAR FORMATAÇÃO
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newPercent = (_sliderValue / widget.targetValue).clamp(0.0, 1.0);

    // ADICIONAR: Formatador brasileiro
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.update,
              color: Colors.green,
              size: 18, // Reduzir o tamanho do ícone
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Atualizar Progresso',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16, // Aumentar o tamanho do texto
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularPercentIndicator(
              radius: 60,
              lineWidth: 12,
              percent: newPercent,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(newPercent * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              progressColor:
                  newPercent >= 1.0 ? Colors.green : theme.colorScheme.primary,
              backgroundColor:
                  theme.colorScheme.primary.withAlpha((0.15 * 255).toInt()),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(0),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withAlpha((0.7 * 255).toInt()),
                    fontSize: 12,
                  ),
                ),
                Text(
                  currencyFormat.format(widget.targetValue),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withAlpha((0.7 * 255).toInt()),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: newPercent >= 1.0
                    ? Colors.green
                    : theme.colorScheme.primary,
                inactiveTrackColor:
                    theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
                thumbColor: newPercent >= 1.0
                    ? Colors.green
                    : theme.colorScheme.primary,
                overlayColor:
                    theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
              ),
              child: Slider(
                value: _sliderValue,
                max: widget.targetValue,
                min: 0.0,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                  _updateTextFromSlider(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Valor Atual',
                hintText: 'Ex: 1.500,00',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()], // NOVA FORMATAÇÃO
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o valor atual';
                }
                final number = CurrencyParser.parse(value); // USAR PARSER
                if (number < 0) return 'Valor não pode ser negativo';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        PressableCard(
          onPress: _submitForm,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.primary,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Atualizar',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // REMOVER ESTA LINHA (ela não existe neste dialog):
        // final name = _nameController.text.trim(); ❌

        // CORRIGIR: Este dialog só lida com valor, não nome
        final valueText = _valueController.text.trim();
        final value = CurrencyParser.parse(valueText);

        // RETORNAR APENAS O VALOR, NÃO UM GOAL:
        Navigator.pop(context, value); // ✅ Retorna double, não Goal
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar valor: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CurrencyParser {
  static double parse(String value) {
    if (value.isEmpty) return 0.0;

    // Remove R$, espaços e outros caracteres não numéricos (exceto . e ,)
    String cleanValue = value.replaceAll(RegExp(r'[R$\s]'), '');

    Logger().e('🔍 Valor original: "$value"');
    Logger().e('🧹 Após limpeza inicial: "$cleanValue"');

    // LÓGICA BRASILEIRA: 1.234.567,89
    if (cleanValue.contains(',')) {
      // Formato brasileiro: separadores de milhares (.) + decimal (,)
      List<String> parts = cleanValue.split(',');

      if (parts.length == 2) {
        // Parte inteira: remove TODOS os pontos (são separadores de milhares)
        String integerPart = parts[0].replaceAll('.', '');
        // Parte decimal: pega só os 2 primeiros dígitos
        String decimalPart =
            parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];

        cleanValue = '$integerPart.$decimalPart';
        Logger().e('🇧🇷 Formato brasileiro: "$cleanValue"');
      } else {
        // Mais de uma vírgula? Remove todas e fica só com números
        cleanValue = cleanValue.replaceAll(RegExp(r'[,.]'), '');
        Logger().e('⚠️ Múltiplas vírgulas, usando só números: "$cleanValue"');
      }
    }
    // LÓGICA AMERICANA/INTERNACIONAL: 1,234,567.89
    else if (cleanValue.contains('.')) {
      List<String> parts = cleanValue.split('.');

      if (parts.length >= 2) {
        String lastPart = parts.last;

        // Se a última parte tem 1-2 dígitos, é decimal
        if (lastPart.length <= 2) {
          // Remove pontos intermediários (separadores), mantém o último como decimal
          String integerPart = parts.sublist(0, parts.length - 1).join('');
          cleanValue = '$integerPart.$lastPart';
          Logger().e('🇺🇸 Formato americano: "$cleanValue"');
        } else {
          // Todos os pontos são separadores de milhares
          cleanValue = parts.join('');
          Logger().e('📊 Só separadores de milhares: "$cleanValue"');
        }
      }
    }

    try {
      final result = double.parse(cleanValue);
      Logger().e('✅ Resultado final: $result');
      return result;
    } catch (e) {
      Logger().e('❌ Erro no parsing: "$value" → "$cleanValue" → $e');
      return 0.0;
    }
  }

  static String format(double value) {
    // NOVO: Usar formatador brasileiro completo
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return currencyFormat.format(value);
  }
}
