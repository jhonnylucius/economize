import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/data/goal_dao.dart';
import 'package:economize/features/financial_education/models/savings_goal.dart';
import 'package:economize/features/financial_education/utils/goal_calculator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class GoalResultCard extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback onRecalculate;

  const GoalResultCard(
      {super.key, required this.goal, required this.onRecalculate});

  @override
  State<GoalResultCard> createState() => _GoalResultCardState();
}

class _GoalResultCardState extends State<GoalResultCard>
    with SingleTickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  late AnimationController _controller;
  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Iniciar animação quando o card é construído
    _controller.forward();

    // Esconder confetti após alguns segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Card principal com efeito de glass
        ScaleAnimation.bounceIn(
          child: GlassContainer(
            borderRadius: 20,
            blur: 8,
            opacity: 0.1,
            borderColor:
                theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1),
                  ),

                  // Informação principal com animação de slide
                  SlideAnimation.fromLeft(
                    delay: const Duration(milliseconds: 200),
                    child: _buildMainInfo(theme),
                  ),

                  const SizedBox(height: 24),

                  // Informações de economia com animação de slide
                  SlideAnimation.fromRight(
                    delay: const Duration(milliseconds: 400),
                    child: _buildSavingsInfo(theme),
                  ),

                  const SizedBox(height: 24),

                  // Recomendação com fade animation
                  FadeAnimation(
                    delay: const Duration(milliseconds: 600),
                    child: _buildRecommendation(theme),
                  ),

                  const SizedBox(height: 24),

                  // Botões com animação de escala
                  ScaleAnimation(
                    delay: const Duration(milliseconds: 800),
                    fromScale: 0.8,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            theme,
                            'Recalcular',
                            Icons.refresh,
                            widget.onRecalculate,
                            outlined: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            theme,
                            'Salvar Meta',
                            Icons.save,
                            () => _saveGoal(context),
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

        // Fundo de padrão sutil
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ResultBackgroundPainter(
                color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
              ),
            ),
          ),
        ),

        // Efeito de confetti no topo
        if (_showConfetti)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: IgnorePointer(
              child: ConfettiAnimation(
                particleCount: 30,
                direction: ConfettiDirection.down,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                  Colors.amber,
                ],
                animationController: _controller,
                duration: const Duration(seconds: 3),
              ),
            ),
          ),
      ],
    );
  }

  // Método para salvar a meta
  void _saveGoal(BuildContext context) async {
    final goalsDAO = GoalsDAO();
    final messenger = ScaffoldMessenger.of(context);

    // Converter SavingsGoal para Goal
    final goalToSave = Goal(
      name: widget.goal.title,
      targetValue: widget.goal.targetValue,
      currentValue: 0.0, // Começa em zero
      createdAt: DateTime.now(), // Data atual como criação
    );

    try {
      await goalsDAO.save(goalToSave);

      // Animação de sucesso e feedback visual
      _controller.forward(from: 0.0);

      // Mostrar feedback positivo animado
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              AnimatedCheckmark(
                color: Colors.white,
                size: 24,
                duration: const Duration(milliseconds: 500),
              ),
              const SizedBox(width: 12),
              const Text(
                'Meta salva com sucesso!',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );

      // Navegar após mostrar o SnackBar
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/goals');
        }
      });
    } catch (e) {
      // Mostrar feedback de erro
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar meta: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    if (outlined) {
      return PressableCard(
        pressedScale: 0.95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        padding: EdgeInsets.zero,
        onPress: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return PressableCard(
        pressedScale: 0.95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary,
        ),
        padding: EdgeInsets.zero,
        onPress: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.onPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.flag_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlideAnimation.fromRight(
                child: Text(
                  widget.goal.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SlideAnimation.fromRight(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Meta: ${_currencyFormat.format(widget.goal.targetValue)}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withAlpha((0.7 * 255).toInt()),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo(ThemeData theme) {
    final Widget content;

    if (widget.goal.type == CalculationType.byMonthlyValue) {
      final months = widget.goal.calculateTimeNeeded();
      content = _buildInfoRow(
        theme,
        'Tempo p/ alcançar:',
        GoalCalculator.formatTimeToReach(months),
        icon: Icons.timelapse,
        iconAnimation: PulseAnimation(
          minScale: 0.8,
          maxScale: 1.2,
          duration: const Duration(seconds: 2),
          child: Icon(Icons.timelapse, color: theme.colorScheme.primary),
        ),
      );
    } else {
      final monthlyValue = widget.goal.calculateMonthlyNeeded();
      content = _buildInfoRow(
        theme,
        'Valor mensal necessário:',
        _currencyFormat.format(monthlyValue),
        icon: Icons.savings,
        iconAnimation: PulseAnimation(
          minScale: 0.8,
          maxScale: 1.2,
          duration: const Duration(seconds: 2),
          child: Icon(Icons.savings, color: theme.colorScheme.primary),
        ),
      );
    }

    return GlassContainer(
      blur: 1,
      opacity: 0.05,
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: content,
      ),
    );
  }

  Widget _buildSavingsInfo(ThemeData theme) {
    if (widget.goal.cashDiscount == null) return const SizedBox.shrink();

    final savings = widget.goal.calculateTotalSavings();
    final finalValue = widget.goal.calculateFinalValue();

    return GlassContainer(
      blur: 1,
      opacity: 0.05,
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              theme,
              'Economia à vista:',
              _currencyFormat.format(savings),
              icon: Icons.discount,
              valueColor: theme.colorScheme.primary,
              animate: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1),
            ),
            _buildInfoRow(
              theme,
              'Valor final:',
              _currencyFormat.format(finalValue),
              icon: Icons.attach_money,
              valueColor: theme.colorScheme.primary,
              animate: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(ThemeData theme) {
    if (widget.goal.type != CalculationType.byMonthlyValue) {
      return const SizedBox.shrink();
    }

    final isReasonable = widget.goal.isReasonableGoal();
    final suggestedValue = widget.goal.getSuggestedMonthlyValue();

    if (isReasonable) return const SizedBox.shrink();

    return GlassContainer(
      blur: 3,
      opacity: 0.05,
      borderRadius: 12,
      borderColor: theme.colorScheme.error..withAlpha((0.3 * 255).toInt()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withAlpha((0.1 * 255).toInt()),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PulseAnimation(
                  minScale: 0.8,
                  maxScale: 1.2,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sugestão de Ajuste',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Para alcançar sua meta em até 2 anos, considere economizar ${_currencyFormat.format(suggestedValue)} por mês.',
              style:
                  TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    bool animate = false,
    Widget? iconAnimation,
  }) {
    final valueText = Text(
      value,
      style: TextStyle(
        color: valueColor ?? theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );

    return Row(
      children: [
        if (iconAnimation != null)
          iconAnimation
        else if (icon != null) ...[
          Icon(icon, color: theme.colorScheme.primary, size: 22),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
          ),
        ),
        animate
            ? AnimatedCounter(
                begin: 0,
                end: int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                formatter: (_) => value,
                textStyle: TextStyle(
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : valueText,
      ],
    );
  }
}

// Padrão de fundo sutil
class _ResultBackgroundPainter extends CustomPainter {
  final Color color;
  final math.Random random = math.Random(42); // Seed fixo para padrão estático

  _ResultBackgroundPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Criar padrão de formas geométricas não piscantes
    final cellSize = size.width / 10; // Ajustado para mais densidade

    for (int i = -1; i < 15; i++) {
      for (int j = -1; j < 30; j++) {
        final x = i * cellSize + random.nextDouble() * (cellSize * 0.5);
        final y = j * cellSize + random.nextDouble() * (cellSize * 0.5);

        final shapeType = (i + j) % 4;
        final shapeSize = cellSize * 0.15;

        switch (shapeType) {
          case 0:
            // Símbolos financeiros - cifrão
            _drawDollarSign(canvas, paint, x, y, shapeSize);
            break;
          case 1:
            // Círculos para moedas
            canvas.drawCircle(Offset(x, y), shapeSize, paint);
            break;
          case 2:
            // Símbolo de meta - bandeira
            _drawFlag(canvas, paint, x, y, shapeSize * 1.2);
            break;
          case 3:
            // Símbolo de crescimento - seta para cima
            _drawArrow(canvas, paint, x, y, shapeSize * 1.2);
            break;
        }
      }
    }
  }

  void _drawDollarSign(
      Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    // Linha vertical
    path.moveTo(x, y - size);
    path.lineTo(x, y + size);

    // Curvas S do símbolo
    path.moveTo(x - size * 0.6, y - size * 0.3);
    path.quadraticBezierTo(x + size * 0.6, y - size * 0.8, x + size * 0.3, y);
    path.quadraticBezierTo(
        x - size * 0.6, y + size * 0.8, x - size * 0.6, y + size * 0.3);

    canvas.drawPath(path, paint);
  }

  void _drawFlag(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    // Mastro
    path.moveTo(x, y - size);
    path.lineTo(x, y + size);

    // Bandeira
    path.moveTo(x, y - size);
    path.lineTo(x + size, y - size * 0.5);
    path.lineTo(x, y);

    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    // Linha vertical
    path.moveTo(x, y - size);
    path.lineTo(x, y + size);

    // Ponta da seta
    path.moveTo(x - size * 0.6, y - size * 0.4);
    path.lineTo(x, y - size);
    path.lineTo(x + size * 0.6, y - size * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ResultBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
