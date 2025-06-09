import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/features/financial_education/models/savings_goal.dart';
import 'package:economize/features/financial_education/widgets/goal_form.dart';
import 'package:economize/features/financial_education/widgets/goal_result_card.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:provider/provider.dart';

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
  // chaves para tutorial interativo
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

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
    // ✅ USAR O ThemeManager CORRETAMENTE
    final themeManager = Provider.of<ThemeManager>(context);
    final isRoxoEscuro = themeManager.currentThemeType == ThemeType.roxoEscuro;

    // ✅ LÓGICA CORRETA: roxo no roxoEscuro, preto no light
    final headerColor =
        isRoxoEscuro ? const Color.fromARGB(255, 43, 3, 138) : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          key: _backButtonKey,
          icon: const Icon(Icons.arrow_back),
          color: Colors.white, // ✅ SEMPRE BRANCO
          onPressed: () => Navigator.pop(context),
        ),
        title: SlideAnimation.fromTop(
          child: const Text(
            'Calculadora de Metas',
            style: TextStyle(
              color: Colors.white, // ✅ SEMPRE BRANCO
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: headerColor, // ✅ AGORA SIM VAI FUNCIONAR!
        elevation: 0,
        actions: [
          IconButton(
            key: _helpButtonKey,
            icon: const Icon(Icons.help_outline),
            color: Colors.white, // ✅ SEMPRE BRANCO
            tooltip: 'Ajuda',
            onPressed: () => _showGoalCalculatorHelp(context),
          ),
        ],
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

  // Adicione este método na classe _GoalCalculatorScreenState, logo acima do método build()
  void _showGoalCalculatorHelp(BuildContext context) {
    Theme.of(context);

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
                            backgroundColor: _primaryPurple,
                            child: Icon(
                              Icons.calculate,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Calculadora de Metas",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Como planejar suas\n metas financeiras",
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

                    // Seção 1: Formulário de Metas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Definindo Sua Meta",
                        icon: Icons.edit_outlined,
                        iconColor: _primaryPurple,
                        content:
                            "Use o formulário para definir sua meta financeira:\n\n"
                            "• Nome da Meta: Identifique claramente seu objetivo (ex: 'Comprar um carro')\n\n"
                            "• Valor Total: Quanto dinheiro você precisa juntar\n\n"
                            "• Você Já Possui: Caso já tenha economizado parte do valor\n\n",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Opções de Cálculo
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Tipos de Cálculo",
                        icon: Icons.sync_alt,
                        iconColor: Colors.blue,
                        content: "Escolha entre dois tipos de cálculo:\n\n"
                            "• Por Tempo: Você define quanto pode economizar por mês, e descobre em quanto tempo atingirá a meta\n\n"
                            "• Por Valor Mensal: Você define em quanto tempo quer atingir a meta, e descobre quanto deverá economizar por mês\n\n"
                            "• Selecione o botão correspondente ao tipo de cálculo desejado",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Resultado do Cálculo
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Resultado",
                        icon: Icons.check_circle_outline,
                        iconColor: Colors.green,
                        content:
                            "Após clicar em 'Calcular', você verá um resumo detalhado:\n\n"
                            "• Nome e valor total da meta\n\n"
                            "• Valor mensal necessário ou tempo total para alcançar o objetivo\n\n"
                            "• Total acumulado considerando os juros\n\n"
                            "• Gráfico visual do progresso estimado mês a mês\n\n"
                            "• Uma animação de celebração aparecerá brevemente quando o cálculo for concluído",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Dicas Adicionais
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Dicas para \nAlcançar Sua Meta",
                        icon: Icons.lightbulb_outline,
                        iconColor: Colors.amber,
                        content:
                            "Após o resultado, você receberá dicas personalizadas:\n\n"
                            "• Estabeleça metas intermediárias para manter o foco\n\n"
                            "• Use contas específicas para separar o dinheiro da meta\n\n"
                            "• Configure transferências automáticas para garantir disciplina\n\n"
                            "• Estas dicas ajudam a transformar o planejamento em realidade\n\n"
                            "• Salve seu cálculo e terá sua meta na telas de metas para atualização de seu pregresso",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Recalcular
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Recalculando \nSua Meta",
                        icon: Icons.refresh,
                        iconColor: Colors.purple,
                        content:
                            "Você pode ajustar seus planos a qualquer momento:\n\n"
                            "• Clique no botão 'Recalcular' para voltar ao formulário\n\n"
                            "• Altere os parâmetros conforme necessário\n\n"
                            "• Teste diferentes cenários (valores, prazos ou taxas de dscontos)\n\n"
                            "• Compare os resultados para encontrar o plano ideal para você\n\n"
                            "• Salve seu cálculo e terá sua meta na telas de metas para atualização de seu pregresso",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Integrando com outras funcionalidades
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Integração com\n o Aplicativo",
                        icon: Icons.integration_instructions,
                        iconColor: _primaryPurple,
                        content:
                            "Use a calculadora junto com outras funções do aplicativo:\n\n"
                            "• Após calcular, crie uma meta na seção 'Minhas Metas' para acompanhar seu progresso\n\n"
                            "• Controle receitas e despesas para garantir que consiga economizar o valor mensal necessário\n\n"
                            "• Consulte a seção de Dicas Financeiras para estratégias de economia e investimento",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 700),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _primaryPurple.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _primaryPurple.withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: _primaryPurple,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Para metas de longo prazo, considere investimentos com rendimentos maiores que a poupança. Mesmo um pequeno aumento na taxa de juros pode reduzir significativamente o tempo ou o valor mensal necessário.",
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
                            backgroundColor: _primaryPurple,
                            foregroundColor: Colors.white,
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
