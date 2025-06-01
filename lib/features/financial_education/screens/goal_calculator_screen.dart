import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/features/financial_education/models/savings_goal.dart';
import 'package:economize/features/financial_education/widgets/goal_form.dart';
import 'package:economize/features/financial_education/widgets/goal_result_card.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GoalCalculatorScreen extends StatefulWidget {
  const GoalCalculatorScreen({super.key});

  @override
  State<GoalCalculatorScreen> createState() => _GoalCalculatorScreenState();
}

class _GoalCalculatorScreenState extends State<GoalCalculatorScreen>
    with SingleTickerProviderStateMixin {
  SavingsGoal? _currentGoal;
  bool _showResult = false;
  late AnimationController _celebrationController;
  bool _showCelebration = false;

  // Cor roxa para elementos que manteremos roxos
  final Color _primaryPurple = const Color(0xFF6200EE);

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _handleGoalSubmit(SavingsGoal goal) {
    setState(() {
      _currentGoal = goal;
      _showResult = true;
      _showCelebration = true;
    });

    // Inicia a animação de celebração
    _celebrationController.forward(from: 0.0);

    // Esconde a celebração após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCelebration = false;
        });
      }
    });
  }

  void _handleRecalculate() {
    setState(() {
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Aqui usamos o tema apenas para os elementos que queremos roxos
    Theme.of(context);

    return Scaffold(
      // Definindo o fundo como SEMPRE branco, ignorando o tema
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SlideAnimation.fromTop(
          child: const Text(
            'Calculadora de Metas',
            style: TextStyle(
              color: Colors.white, // Texto branco na AppBar
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        elevation: 0,
        // Mantemos a AppBar roxa
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Fundo com padrão sutil (agora mais claro)
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(
                color: Colors.black.withAlpha(
                    (0.3 * 255).round()), // Padrão sutil em cinza claro
              ),
            ),
          ),

          // Conteúdo principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_showResult) ...[
                    SlideAnimation.fromTop(
                      delay: const Duration(milliseconds: 100),
                      child: ScaleAnimation(
                        child: GlassContainer(
                          blur: 5,
                          opacity: 0.1,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeAnimation(
                                  delay: const Duration(milliseconds: 200),
                                  child: Text(
                                    'Defina sua Meta',
                                    style: TextStyle(
                                      color: Colors.black87, // Texto preto
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FadeAnimation(
                                  delay: const Duration(milliseconds: 300),
                                  child: Text(
                                    'Preencha os dados para calcular o tempo necessário ou o valor mensal para atingir seu objetivo.',
                                    style: TextStyle(
                                      color: Colors.black87, // Texto preto
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SlideAnimation.fromBottom(
                                  delay: const Duration(milliseconds: 400),
                                  child: GoalForm(onSave: _handleGoalSubmit),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else if (_currentGoal != null) ...[
                    SlideAnimation.fromRight(
                      child: ScaleAnimation.bounceIn(
                        child: GoalResultCard(
                          goal: _currentGoal!,
                          onRecalculate: _handleRecalculate,
                        ),
                      ),
                    ),

                    // Dicas adicionais que aparecem após o resultado
                    SlideAnimation.fromBottom(
                      delay: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: GlassContainer(
                          blur: 3,
                          opacity: 0.08,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeAnimation(
                                  delay: const Duration(milliseconds: 800),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: _primaryPurple, // Ícone roxo
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Dicas para alcançar sua meta',
                                        style: TextStyle(
                                          color: Colors.black87, // Texto preto
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FadeAnimation(
                                  delay: const Duration(milliseconds: 1000),
                                  child: _buildTipItem(
                                    'Defina metas intermediárias para manter o foco',
                                    Icons.flag,
                                  ),
                                ),
                                FadeAnimation(
                                  delay: const Duration(milliseconds: 1100),
                                  child: _buildTipItem(
                                    'Use contas de poupança ou investimentos específicos',
                                    Icons.savings,
                                  ),
                                ),
                                FadeAnimation(
                                  delay: const Duration(milliseconds: 1200),
                                  child: _buildTipItem(
                                    'Configure transferências automáticas mensais',
                                    Icons.schedule,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Animação de celebração quando o cálculo é feito
          if (_showCelebration && _showResult)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiAnimation(
                  particleCount: 30,
                  direction: ConfettiDirection.down,
                  duration: const Duration(seconds: 3),
                  animationController: _celebrationController,
                  colors: [
                    _primaryPurple,
                    Colors.purple.shade300,
                    Colors.deepPurple,
                    Colors.amber,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: _primaryPurple
                .withAlpha((0.7 * 255).round()), // Ícone roxo claro
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87, // Texto preto
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Padrão de fundo sutil
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Criar padrão de formas geométricas não piscantes
    final random = math.Random(42); // Seed fixo para padrão estático
    final cellSize = size.width / 10; // Torna o padrão mais espaçado

    for (int i = -1; i < 15; i++) {
      for (int j = -1; j < 30; j++) {
        final x = i * cellSize + random.nextDouble() * (cellSize * 0.5);
        final y = j * cellSize + random.nextDouble() * (cellSize * 0.5);

        final shapeType = (i + j) % 3;
        final shapeSize = cellSize * 0.15;

        switch (shapeType) {
          case 0:
            // Círculos para representar moedas
            canvas.drawCircle(Offset(x, y), shapeSize, paint);
            break;
          case 1:
            // Quadrados para representar notas
            canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(x, y),
                  width: shapeSize * 2,
                  height: shapeSize * 2),
              paint,
            );
            break;
          case 2:
            // Símbolo monetário simplificado
            final path = Path();
            path.moveTo(x, y - shapeSize);
            path.lineTo(x, y + shapeSize);
            path.moveTo(x - shapeSize, y - shapeSize * 0.5);
            path.lineTo(x + shapeSize, y - shapeSize * 0.5);
            canvas.drawPath(
                path,
                paint
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => oldDelegate.color != color;
}
