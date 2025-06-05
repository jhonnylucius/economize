/*tutorial_spotlight.dart
**Parte do plano: 3.2 (2) - Spotlight (Destaque)
**Conteúdo: Implementa o efeito de "buraco" com ClipPath e animação de destaque.*/
import 'package:flutter/material.dart';
import 'package:economize/tutorial/models/tutorial_step.dart';

/// Widget que cria um efeito de destaque (spotlight) em um elemento específico da interface
/// Pode ser usado independentemente ou como parte do TutorialOverlay
class TutorialSpotlight extends StatefulWidget {
  /// Retângulo que define a área a ser destacada
  final Rect targetRect;

  /// Forma do destaque (opcional)
  final ShapeBorder? spotlightShape;

  /// Cor do overlay de fundo
  final Color overlayColor;

  /// Opacidade do overlay
  final double overlayOpacity;

  /// Se deve animar o destaque
  final bool animate;

  /// Cor do brilho ao redor do destaque
  final Color glowColor;

  /// Intensidade do brilho (0.0 a 1.0)
  final double glowIntensity;

  /// Função chamada quando o usuário toca no elemento destacado
  final VoidCallback? onTap;

  const TutorialSpotlight({
    super.key,
    required this.targetRect,
    this.spotlightShape,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.7,
    this.animate = true,
    this.glowColor = Colors.white,
    this.glowIntensity = 0.5,
    this.onTap,
  });

  /// Cria um TutorialSpotlight a partir de um TutorialStep
  factory TutorialSpotlight.fromStep({
    required BuildContext context,
    required TutorialStep step,
    Color overlayColor = Colors.black,
    double overlayOpacity = 0.7,
    bool animate = true,
    Color glowColor = Colors.white,
    double glowIntensity = 0.5,
    VoidCallback? onTap,
  }) {
    final Rect? targetRect = step.getTargetPosition(context);

    if (targetRect == null) {
      // Fallback para um retângulo invisível se não conseguir encontrar o alvo
      return TutorialSpotlight(
        targetRect: Rect.zero,
        overlayColor: Colors.transparent,
        overlayOpacity: 0,
      );
    }

    return TutorialSpotlight(
      targetRect: targetRect,
      spotlightShape: step.spotlightShape,
      overlayColor: overlayColor,
      overlayOpacity: overlayOpacity,
      animate: animate,
      glowColor: glowColor,
      glowIntensity: glowIntensity,
      onTap: onTap,
    );
  }

  @override
  State<TutorialSpotlight> createState() => _TutorialSpotlightState();
}

class _TutorialSpotlightState extends State<TutorialSpotlight>
    with SingleTickerProviderStateMixin {
  /// Controlador para a animação de pulsação
  late AnimationController _animationController;

  /// Animação para o efeito de pulsação
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animação de pulsação
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TutorialSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Atualizar estado da animação quando as propriedades mudarem
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _SpotlightPainter(
              targetRect: widget.targetRect,
              pulseValue: widget.animate ? _pulseAnimation.value : 0.0,
              spotlightShape: widget.spotlightShape,
              overlayColor: widget.overlayColor,
              overlayOpacity: widget.overlayOpacity,
              glowColor: widget.glowColor,
              glowIntensity: widget.glowIntensity,
            ),
          );
        },
      ),
    );
  }
}

/// Customização avançada da aparência do spotlight
class SpotlightDecoration {
  final double borderWidth;
  final Color borderColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const SpotlightDecoration({
    this.borderWidth = 2.0,
    this.borderColor = Colors.white,
    this.borderRadius = 8.0,
    this.boxShadow,
  });
}

/// Painter responsável por desenhar o efeito de spotlight
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double pulseValue;
  final ShapeBorder? spotlightShape;
  final Color overlayColor;
  final double overlayOpacity;
  final Color glowColor;
  final double glowIntensity;

  _SpotlightPainter({
    required this.targetRect,
    required this.pulseValue,
    this.spotlightShape,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.glowColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Se o retângulo for zero, não desenhar nada
    if (targetRect == Rect.zero) return;

    // Criar o path do fundo
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Criar o path do "buraco"
    final Path holePath = _createHolePath();

    // Recortar o "buraco" do fundo
    final Path finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    // Desenhar o fundo semitransparente
    canvas.drawPath(
      finalPath,
      Paint()
        ..color = overlayColor.withAlpha((overlayOpacity * 255).round())
        ..style = PaintingStyle.fill,
    );

    // Desenhar o brilho animado
    _drawGlowEffect(canvas);

    // Desenhar borda ao redor do destaque
    _drawBorder(canvas);
  }

  /// Cria o path para o "buraco" no overlay
  Path _createHolePath() {
    if (spotlightShape != null) {
      // Usar forma personalizada
      return spotlightShape!
          .getOuterPath(targetRect, textDirection: TextDirection.ltr);
    } else {
      // Determinar se usar círculo ou retângulo arredondado
      final double width = targetRect.width;
      final double height = targetRect.height;
      final Path path = Path();

      if ((width - height).abs() < 10) {
        // Elemento aproximadamente quadrado, usar círculo
        final double radius = (width + height) / 4;
        // Usar o radius calculado para criar um círculo de tamanho apropriado
        path.addOval(
          Rect.fromCenter(
            center: targetRect.center,
            width: radius * 2, // Diâmetro = 2 * raio
            height: radius * 2, // Diâmetro = 2 * raio
          ),
        );
      } else {
        // Elemento retangular, usar retângulo arredondado
        path.addRRect(
          RRect.fromRectAndRadius(
            targetRect,
            Radius.circular(8),
          ),
        );
      }

      return path;
    }
  }

  /// Desenha o efeito de brilho pulsante
  void _drawGlowEffect(Canvas canvas) {
    // Não desenhar se a intensidade for zero
    if (glowIntensity <= 0) return;

    // Número de camadas do brilho
    final int layers = 3;

    for (int i = 1; i <= layers; i++) {
      final double spread = pulseValue * i;
      final double opacity =
          (glowIntensity - (i * 0.1 * glowIntensity)).clamp(0.0, 1.0);

      final Paint glowPaint = Paint()
        ..color = glowColor.withAlpha((opacity * 255).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spread);

      if (spotlightShape != null) {
        // Brilho para forma personalizada
        canvas.drawPath(
          spotlightShape!.getOuterPath(targetRect.inflate(spread),
              textDirection: TextDirection.ltr),
          glowPaint,
        );
      } else {
        // Determinar se usar círculo ou retângulo arredondado
        final double width = targetRect.width;
        final double height = targetRect.height;

        if ((width - height).abs() < 10) {
          // Brilho para círculo
          canvas.drawCircle(
            targetRect.center,
            (width + height) / 4 + spread,
            glowPaint,
          );
        } else {
          // Brilho para retângulo arredondado
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              targetRect.inflate(spread),
              Radius.circular(8 + spread * 0.5),
            ),
            glowPaint,
          );
        }
      }
    }
  }

  /// Desenha uma borda ao redor do elemento destacado
  void _drawBorder(Canvas canvas) {
    final Paint borderPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (spotlightShape != null) {
      // Borda para forma personalizada
      canvas.drawPath(
        spotlightShape!
            .getOuterPath(targetRect, textDirection: TextDirection.ltr),
        borderPaint,
      );
    } else {
      // Determinar se usar círculo ou retângulo arredondado
      final double width = targetRect.width;
      final double height = targetRect.height;

      if ((width - height).abs() < 10) {
        // Borda para círculo
        canvas.drawCircle(
          targetRect.center,
          (width + height) / 4,
          borderPaint,
        );
      } else {
        // Borda para retângulo arredondado
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            targetRect,
            Radius.circular(8),
          ),
          borderPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        pulseValue != oldDelegate.pulseValue ||
        spotlightShape != oldDelegate.spotlightShape ||
        overlayColor != oldDelegate.overlayColor ||
        overlayOpacity != oldDelegate.overlayOpacity ||
        glowColor != oldDelegate.glowColor ||
        glowIntensity != oldDelegate.glowIntensity;
  }
}
/*Características Principais do TutorialSpotlight
O TutorialSpotlight é um componente visual mais especializado que oferece:

1. Independência e Reusabilidade
Pode ser usado como parte do sistema de tutorial completo ou de forma independente
Factory method fromStep() permite criar facilmente a partir de um TutorialStep
2. Efeitos Visuais Aprimorados
Brilho Pulsante: Adiciona um efeito de luz pulsante ao redor do elemento destacado
Borda Nítida: Define claramente a área de interesse com uma borda branca
Detecção Inteligente de Formas: Adapta o destaque à forma do elemento (circular ou retangular)
3. Alta Personalização
Controle sobre a cor e opacidade do overlay
Ajuste da intensidade e cor do efeito de brilho
Suporte a formas customizadas através de ShapeBorder
4. Performance Otimizada
Usa CustomPainter para renderização eficiente
Verifica se deve redesenhar através de shouldRepaint
Lida corretamente com casos de falha (como quando o elemento alvo não é encontrado)
5. Animações Suaves
Efeito de pulsação com timing e curvas de animação naturais
Controle para ativar/desativar as animações quando necessário
Este componente trabalha em conjunto com o TutorialOverlay, mas pode ser usado em situações onde você precisa apenas destacar um elemento sem todo o sistema de tutorial, como em casos de "Destaque da semana" ou "Nova funcionalidade".*/
