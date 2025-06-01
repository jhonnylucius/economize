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
          SlideAnimation.fromRight(
            child: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              tooltip: 'Ir para Home',
              color: theme.colorScheme.onPrimary,
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
