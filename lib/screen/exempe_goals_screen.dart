import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/model/goal.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:math' as math;

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

  // Método _loadGoals original (sem alterações)
  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _goalsDAO.findAll();

      // Log para depuração
      Logger().e('Metas carregadas: ${goals.length}');
      for (var goal in goals) {
        Logger().e(
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
      Logger().e('Erro ao carregar metas: $e');
      if (mounted) {
        _showError('Erro ao carregar metas: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              icon: const Icon(Icons.calculate),
              onPressed: () => Navigator.pushNamed(context, '/calculator'),
              tooltip: 'Calculadora de Metas',
            ),
          ),
          SlideAnimation.fromTop(
            delay: const Duration(milliseconds: 100),
            child: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              tooltip: 'Ir para Home',
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white, // Sempre fundo branco
      floatingActionButton: ScaleAnimation.bounceIn(
        delay: const Duration(milliseconds: 300),
        child: GlassContainer(
          borderRadius: 24,
          blur: 10,
          opacity: 0.2,
          child: FloatingActionButton.extended(
            onPressed: _addNewGoal,
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Nova Meta',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GoalsBackgroundPainter(
                    color: theme.colorScheme.primary
                        .withAlpha((0.3 * 255).toInt()),
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
                  particleCount: 30,
                  direction: ConfettiDirection.down,
                  duration: const Duration(seconds: 3),
                  animationController: _celebrationController,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    Colors.amber,
                    Colors.green,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Método _buildEmptyState com o novo botão ADICIONADO
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: FadeAnimation(
        child: ScaleAnimation(
          child: GlassContainer(
            blur: 5,
            opacity: 0.1,
            borderRadius: 20,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 80,
                    color: theme.colorScheme.primary
                        .withAlpha((0.7 * 255).toInt()),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhuma meta definida ainda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Defina objetivos financeiros e acompanhe seu progresso rumo à conquista.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          vertical: 12, horizontal: 20),
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
                  // Botão adicional para calculadora de metas (ADICIONADO AQUI)
                  const SizedBox(height: 16), // Espaço entre os botões
                  PressableCard(
                    onPress: () => Navigator.pushNamed(context, '/calculator'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber, // Cor amarela conforme seu snippet
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
                          vertical: 12, horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calculate,
                            color: Colors.white, // Ícone branco
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Usar calculadora de metas',
                            style: TextStyle(
                              color: Colors.white, // Texto branco
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
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra padding for FAB
      itemBuilder: (context, index) {
        final goal = _goals[index];
        final percentComplete = goal.percentComplete.clamp(0.0, 1.0);
        final isCompleted = percentComplete >= 1.0;

        return SlideAnimation.fromRight(
          delay: Duration(milliseconds: 100 * index),
          child: _buildGoalCard(goal, index, theme),
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
        borderRadius: 20,
        blur: 5,
        opacity: 0.08,
        borderColor: isCompleted
            ? Colors.green.withAlpha((0.3 * 255).toInt())
            : theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isCompleted)
                                  PulseAnimation(
                                    child: Container(
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

              const SizedBox(height: 20),

              // Progress section
              Row(
                children: [
                  // Progress circular indicator
                  CircularPercentIndicator(
                    radius: 50,
                    lineWidth: 10,
                    percent: percentComplete,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedCounter(
                          begin: 0,
                          end: (percentComplete * 100).toInt(),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutCubic,
                          formatter: (value) => '$value%',
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                    progressColor: progressColor,
                    backgroundColor:
                        progressColor.withAlpha((0.15 * 255).toInt()),
                    animation: true,
                    animationDuration: 2000,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),

                  const SizedBox(width: 20),

                  // Goal values
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Update Progress Button (faded if complete)
                  Opacity(
                    opacity: isCompleted ? 0.5 : 1.0,
                    child: PressableCard(
                      onPress: isCompleted ? null : () => _updateProgress(goal),
                      pressedScale: 0.95,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: theme.colorScheme.primary
                            .withAlpha((0.1 * 255).toInt()),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
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
          'R\$${value.toStringAsFixed(2)}',
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
                                'R\$${goal.currentValue.toStringAsFixed(2)} / R\$${goal.targetValue.toStringAsFixed(2)}',
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
                        value: 'R\$${goal.remainingValue.toStringAsFixed(2)}',
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
                              onPressed: () {
                                Navigator.pop(context);
                                _updateProgress(goal);
                              },
                              color: Colors.green,
                            ),
                          ),
                        ],
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
    required VoidCallback onPressed,
    required Color color,
  }) {
    return PressableCard(
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
    );
  }

  String formatElapsedDays(int days) {
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

  String _formatDate(DateTime date) {
    // Returns date in dd/MM/yyyy format
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showGoalOptions(Goal goal, int index) {
    final theme = Theme.of(context);

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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SlideAnimation.fromBottom(
              delay: const Duration(milliseconds: 100),
              child: _buildOptionItem(
                label: 'Atualizar progresso',
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
            if (goal.percentComplete >= 1.0)
              SlideAnimation.fromBottom(
                delay: const Duration(milliseconds: 200),
                child: _buildOptionItem(
                  label: 'Comemorar conquista',
                  icon: Icons.celebration,
                  color: Colors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    _celebrateGoal(index);
                  },
                ),
              ),
            SlideAnimation.fromBottom(
              delay: const Duration(milliseconds: 250),
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
    setState(() {
      _celebratingGoalIndex = index;
      _showCelebration = true;
    });

    _celebrationController.forward(from: 0.0);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCelebration = false;
        });
      }
    });
  }

  // Método _addNewGoal com diálogo melhorado
  void _addNewGoal() async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => _GoalDialog(),
    );

    if (result != null) {
      try {
        // Verificar o ID antes de salvar
        Logger().e('ID da nova meta: ${result.id}');
        Logger().e('Nome da meta: ${result.name}');
        Logger().e('Valor alvo: ${result.targetValue}');

        if (result.id == null || result.id!.isEmpty) {
          // O ID está faltando ou é vazio, precisamos gerar um
          // Não faça isso na produção, apenas para diagnosticar
          final newGoal = Goal(
            id: const Uuid().v4(), // Garante um ID válido
            name: result.name,
            targetValue: result.targetValue,
            currentValue: result.currentValue,
            createdAt: result.createdAt,
          );

          await _goalsDAO.save(newGoal);
        } else {
          await _goalsDAO.save(result);
        }

        await _loadGoals();
        if (mounted) {
          _showSuccess('Meta adicionada com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao adicionar meta: $e');
          Logger().e('Erro detalhado: $e'); // Log para depuração
        }
      }
    }
  }

  // Método _editGoal original (sem alterações)
  void _editGoal(Goal goal) async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => _GoalDialog(goal: goal),
    );

    if (result != null) {
      try {
        await _goalsDAO.update(result);
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

  // Método _updateProgress modificado
  void _updateProgress(Goal goal) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
    if (goalIndex == -1) return;
    Logger().e('Atualizando meta com ID: ${goal.id}');
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

        // Usar copyWith para criar uma nova instância com o valor atualizado
        final updatedGoal = goal.copyWith(currentValue: result);

        await _goalsDAO.update(updatedGoal);

        // Atualizar a lista local com a nova instância
        setState(() {
          _goals[goalIndex] = updatedGoal;
        });

        // Log para depuração
        Logger().d(
            'Meta atualizada: ${updatedGoal.name}, Progresso: ${updatedGoal.currentValue}/${updatedGoal.targetValue}');
        Logger().d('Percentual: ${updatedGoal.percentComplete}');

        // Para garantir, recarregar tudo
        await _loadGoals();

        if (oldValue < goal.targetValue && result >= goal.targetValue) {
          _celebrateGoal(goalIndex);
        }

        _showSuccess('Progresso atualizado com sucesso!');
      } catch (e) {
        Logger().e('Erro ao atualizar progresso: $e');
        _showError('Erro ao atualizar progresso: $e');
      }
    }
  }

  // Método _deleteGoal with modern confirmation dialog
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

    if (confirm == true) {
      try {
        await _goalsDAO.delete(goal.id!);
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
            AnimatedCheckmark(
              color: Colors.white,
              size: 24,
              duration: const Duration(milliseconds: 500),
            ),
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

// Background painter for goals screen
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

// Animated checkmark for snackbar
class AnimatedCheckmark extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const AnimatedCheckmark({
    super.key,
    this.color = Colors.white,
    this.size = 24,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint);
    _controller.forward();
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
      child: CustomPaint(
        painter: _CheckmarkPainter(
          animation: _animation,
          color: widget.color,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _CheckmarkPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final path = Path();
    // Start of the checkmark
    final double startX = size.width * 0.15;
    final double startY = size.height * 0.5;

    // Middle point of the checkmark
    final double midX = size.width * 0.4;
    final double midY = size.height * 0.75;

    // End point of the checkmark
    final double endX = size.width * 0.85;
    final double endY = size.height * 0.25;

    // Animate the path drawing
    if (animation.value < 0.5) {
      // Draw the first part
      final currentMidX = startX + (midX - startX) * (animation.value / 0.5);
      final currentMidY = startY + (midY - startY) * (animation.value / 0.5);
      path.moveTo(startX, startY);
      path.lineTo(currentMidX, currentMidY);
    } else {
      // Draw the first part fully
      path.moveTo(startX, startY);
      path.lineTo(midX, midY);
      // Draw the second part
      final currentEndX =
          midX + (endX - midX) * ((animation.value - 0.5) / 0.5);
      final currentEndY =
          midY + (endY - midY) * ((animation.value - 0.5) / 0.5);
      path.lineTo(currentEndX, currentEndY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
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
      _valueController.text = widget.goal!.targetValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.goal != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.flag,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Editar Meta' : 'Nova Meta',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome da Meta',
                hintText: 'Ex: Viagem para a praia',
                prefixIcon: const Icon(Icons.bookmark_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Valor da Meta (R\$)',
                hintText: 'Ex: 1000',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Valor é obrigatório';
                }
                final number = double.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Digite um valor válido maior que zero';
                }
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
                  isEditing ? Icons.check : Icons.add,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Salvar' : 'Criar Meta',
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
      final name = _nameController.text;
      final value = double.tryParse(_valueController.text) ?? 0;

      final goal = Goal(
        id: widget.goal?.id,
        name: name,
        targetValue: value,
        currentValue: widget.goal?.currentValue ?? 0,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
      );

      Navigator.pop(context, goal);
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
    _valueController.text = widget.currentValue.toString();
    _sliderValue = widget.currentValue;

    // Add listener to update slider when text changes
    _valueController.addListener(_updateSliderFromText);
  }

  @override
  void dispose() {
    _valueController.removeListener(_updateSliderFromText);
    _valueController.dispose();
    super.dispose();
  }

  void _updateSliderFromText() {
    final value = double.tryParse(_valueController.text) ?? 0.0;
    setState(() {
      _sliderValue = value.clamp(0.0, widget.targetValue);
    });
  }

  void _updateTextFromSlider(double value) {
    _valueController.text = value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    (widget.currentValue / widget.targetValue).clamp(0.0, 1.0);
    final newPercent = (_sliderValue / widget.targetValue).clamp(0.0, 1.0);

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
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Atualizar Progresso',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
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
                  'R\$0',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'R\$${widget.targetValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor:
                    theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                thumbColor: theme.colorScheme.primary,
                overlayColor:
                    theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                valueIndicatorColor: theme.colorScheme.primary,
                valueIndicatorTextStyle: TextStyle(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              child: Slider(
                min: 0,
                max: widget.targetValue,
                value: _sliderValue,
                divisions: 100,
                label: 'R\$${_sliderValue.toStringAsFixed(2)}',
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    _updateTextFromSlider(value);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Valor Atual (R\$)',
                hintText: 'Ex: 500',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '/ R\$${widget.targetValue.toStringAsFixed(2)}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Valor é obrigatório';
                }
                final number = double.tryParse(value);
                if (number == null || number < 0) {
                  return 'Digite um valor válido maior ou igual a zero';
                }
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
      final value = double.tryParse(_valueController.text) ?? 0;
      Navigator.pop(context, value);
    }
  }
}
