import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/features/financial_education/data/tips_repository.dart';
import 'package:economize/features/financial_education/models/financial_tip.dart';
import 'package:economize/features/financial_education/widgets/tip_card.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

// Enum para direção das animações de slide
enum SlideDirection { fromLeft, fromRight, fromTop, fromBottom }

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<FinancialTip> _tips = TipsRepository.tips;
  bool _isFirstLoad = true;
  int _previousIndex = 0;
  // chaves para tutorial interativo
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TipCategory.values.length,
      vsync: this,
    );

    // Monitora mudanças de tab para animações
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _previousIndex = _tabController.index;
          _isFirstLoad = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FinancialTip> _getFilteredTips(TipCategory category) {
    return _tips.where((tip) => tip.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<ThemeManager>(); // Para reagir a mudanças de tema

    return Scaffold(
      appBar: AppBar(
        // seta de voltar visível e identificável
        leading: IconButton(
          key: _backButtonKey,
          icon: const Icon(Icons.arrow_back),
          color: theme.colorScheme.onPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: SlideAnimation.fromTop(
          child: Text(
            'Dicas Financeiras',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          // ícone de ajuda em vez de casa
          SlideAnimation.fromRight(
            child: IconButton(
              key: _helpButtonKey,
              icon: const Icon(Icons.help_outline),
              color: theme.colorScheme.onPrimary,
              tooltip: 'Ajuda',
              onPressed: () => _showTipsScreenHelp(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withAlpha(
            (0.7 * 255).toInt(),
          ),
          tabs: TipCategory.values.map((category) {
            return FadeAnimation(
              child: Tab(
                icon: Icon(category.icon),
                text: category.displayName,
              ),
            );
          }).toList(),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Padrão de fundo sutil
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                color: theme.colorScheme.onSurface
                  ..withAlpha((0.3 * 255).toInt()),
              ),
            ),
          ),

          TabBarView(
            controller: _tabController,
            children: TipCategory.values.map((category) {
              final categoryTips = _getFilteredTips(category);
              final int categoryIndex = TipCategory.values.indexOf(category);

              // Define a direção da animação baseada na mudança de tab
              final SlideDirection direction = _isFirstLoad
                  ? SlideDirection.fromBottom
                  : (_previousIndex < categoryIndex)
                      ? SlideDirection.fromRight
                      : SlideDirection.fromLeft;

              return categoryTips.isEmpty
                  ? _buildEmptyState(theme)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: categoryTips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return SlideAnimation(
                            delay: Duration(milliseconds: 100 * index),
                            beginOffset: direction == SlideDirection.fromLeft
                                ? const Offset(-0.1, 0)
                                : direction == SlideDirection.fromRight
                                    ? const Offset(0.1, 0)
                                    : direction == SlideDirection.fromTop
                                        ? const Offset(0, -0.1)
                                        : const Offset(0, 0.1),
                            child: ScaleAnimation(
                              delay: Duration(milliseconds: 100 * index),
                              child: TipCard(tip: categoryTips[index]),
                            ),
                          );
                        },
                      ),
                    );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: ScaleAnimation.bounceIn(
        delay: const Duration(milliseconds: 300),
        child: GlassContainer(
          borderRadius: 24,
          blur: 10,
          opacity: 0.2,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/calculator'),
            icon: Icon(
              Icons.calculate_outlined,
              color: theme.colorScheme.onPrimary,
            ),
            label: Text(
              'Calculadora de Metas',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  // Adicione este método na classe _TipsScreenState
  void _showTipsScreenHelp(BuildContext context) {
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
                              Icons.tips_and_updates,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dicas Financeiras",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Como usar a biblioteca de dicas",
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

                    // Seção 1: Navegação por Categorias
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Navegação por\n Categorias",
                        icon: Icons.category,
                        iconColor: theme.colorScheme.primary,
                        content:
                            "Use as abas na parte superior para navegar entre diferentes categorias de dicas:\n\n"
                            "• Básico: Conceitos financeiros fundamentais para iniciantes\n\n"
                            "• Economia: Estratégias para economizar dinheiro no dia a dia\n\n"
                            "• Investimento: Orientações sobre como fazer seu dinheiro render\n\n"
                            "• Orçamento: Técnicas para controle e planejamento financeiro\n\n"
                            "• Dívidas: Dicas para sair do endividamento e manter as contas em dia",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Cards de Dicas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Cards de Dicas",
                        icon: Icons.info_outline,
                        iconColor: Colors.blue,
                        content:
                            "Cada card contém uma dica financeira completa:\n\n"
                            "• Título: O tema principal da dica\n\n"
                            "• Texto: Explicação detalhada sobre o assunto\n\n"
                            "• Ícone: Identificação visual da categoria\n\n"
                            "• Os cards são coloridos de acordo com a categoria para facilitar a identificação",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Interação com os Cards
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Interação com\n os Cards",
                        icon: Icons.touch_app,
                        iconColor: Colors.green,
                        content:
                            "Você pode interagir com as dicas de várias formas:\n\n"
                            "• Toque para expandir uma dica e ler o texto completo\n\n"
                            "• Deslize para cima e para baixo para percorrer a lista de dicas\n\n"
                            "• Use as abas para alternar entre categorias diferentes\n\n"
                            "• A animação ao mudar de categoria ajuda a identificar a navegação",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Calculadora de Metas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Calculadora \nde Metas",
                        icon: Icons.calculate_outlined,
                        iconColor: Colors.orange,
                        content:
                            "O botão 'Calculadora de Metas' na parte inferior da tela:\n\n"
                            "• Ferramenta para planejar suas economias\n\n"
                            "• Defina o valor total que deseja alcançar\n\n"
                            "• Estabeleça o prazo para atingir sua meta\n\n"
                            "• Calcule quanto precisa economizar mensalmente\n\n"
                            "• Salve seu cálculo e terá sua meta na telas de metas para atualização de seu pregresso\n\n"
                            "• Simule diferentes cenários alterando os valores",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Benefícios das Dicas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Benefícios das\n Dicas",
                        icon: Icons.star_outline,
                        iconColor: Colors.purple,
                        content:
                            "Aproveite ao máximo a biblioteca de dicas financeiras:\n\n"
                            "• Amplie seus conhecimentos sobre finanças pessoais\n\n"
                            "• Aprenda estratégias testadas para controle financeiro\n\n"
                            "• Descubra técnicas para economizar e investir\n\n"
                            "• Aplique os conceitos na prática usando outros recursos do aplicativo",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Conteúdo Atualizado
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Conteúdo \nAtualizado",
                        icon: Icons.update,
                        iconColor: Colors.teal,
                        content:
                            "Nossa biblioteca de dicas é constantemente atualizada:\n\n"
                            "• Novas dicas são adicionadas regularmente\n\n"
                            "• O conteúdo é revisado por especialistas em finanças\n\n"
                            "• Informações adaptadas à realidade econômica brasileira\n\n"
                            "• Visite esta seção regularmente para obter novas orientações",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 700),
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
                              "Reserve alguns minutos por semana para ler novas dicas financeiras. Aplicar apenas um conceito novo por mês já pode trazer grandes benefícios para suas finanças pessoais a longo prazo.",
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 64,
                color: theme.colorScheme.primary.withAlpha((0.5 * 255).toInt()),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma dica disponível\nnesta categoria ainda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.7 * 255).toInt()),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Volta para a primeira tab
                  _tabController.animateTo(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Ver outras categorias'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Padrão de fundo sutil para as dicas financeiras
class _BackgroundPatternPainter extends CustomPainter {
  final Color color;
  final math.Random random =
      math.Random(42); // Seed fixo para padrão consistente

  _BackgroundPatternPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Criar padrão com símbolos financeiros
    final cellSize = size.width / 10;

    for (int i = -1; i < 15; i++) {
      for (int j = -1; j < 30; j++) {
        final x = i * cellSize + random.nextDouble() * (cellSize * 0.5);
        final y = j * cellSize + random.nextDouble() * (cellSize * 0.5);

        final shapeType = (i + j) % 4;
        final shapeSize = cellSize * 0.2;

        switch (shapeType) {
          case 0:
            // Cifrão
            _drawDollar(canvas, paint, x, y, shapeSize);
            break;
          case 1:
            // Círculos para moedas
            canvas.drawCircle(Offset(x, y), shapeSize * 0.5, paint);
            break;
          case 2:
            // Gráfico de barras simplificado
            _drawBarGraph(canvas, paint, x, y, shapeSize);
            break;
          case 3:
            // Porcentagem
            _drawPercent(canvas, paint, x, y, shapeSize);
            break;
        }
      }
    }
  }

  void _drawDollar(
      Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();

    // Linha vertical central
    path.moveTo(x, y - size * 0.6);
    path.lineTo(x, y + size * 0.6);

    // Curva S
    path.moveTo(x - size * 0.3, y - size * 0.3);
    path.quadraticBezierTo(
        x + size * 0.5, y - size * 0.6, x + size * 0.3, y - size * 0.1);
    path.quadraticBezierTo(
        x - size * 0.5, y + size * 0.4, x - size * 0.3, y + size * 0.3);

    canvas.drawPath(path, paint);
  }

  void _drawBarGraph(
      Canvas canvas, Paint paint, double x, double y, double size) {
    // Barra 1
    canvas.drawRect(
      Rect.fromLTWH(x - size * 0.6, y, size * 0.3, -size * 0.5),
      paint,
    );

    // Barra 2
    canvas.drawRect(
      Rect.fromLTWH(x - size * 0.2, y, size * 0.3, -size * 0.8),
      paint,
    );

    // Barra 3
    canvas.drawRect(
      Rect.fromLTWH(x + size * 0.2, y, size * 0.3, -size * 0.3),
      paint,
    );
  }

  void _drawPercent(
      Canvas canvas, Paint paint, double x, double y, double size) {
    // Círculo superior
    canvas.drawCircle(
        Offset(x - size * 0.3, y - size * 0.3), size * 0.2, paint);

    // Círculo inferior
    canvas.drawCircle(
        Offset(x + size * 0.3, y + size * 0.3), size * 0.2, paint);

    // Linha diagonal
    final path = Path();
    path.moveTo(x - size * 0.5, y + size * 0.5);
    path.lineTo(x + size * 0.5, y - size * 0.5);

    canvas.drawPath(
        path,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_BackgroundPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
