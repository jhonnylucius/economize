/* tutorial_overlay.dart
**Parte do plano: 3.2 (1) - Overlay do Tutorial
**Conteúdo: Widget transparente que cobre toda a tela com IgnorePointer seletivo.*/
import 'package:flutter/material.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/tutorial/models/tutorial_step.dart';

/// Widget de sobreposição para o tutorial interativo
/// Cria uma camada semitransparente sobre a tela com um "buraco" para destacar elementos
class TutorialOverlay extends StatefulWidget {
  /// Passo atual do tutorial
  final TutorialStep step;

  /// Função chamada quando o usuário toca no elemento destacado
  final VoidCallback onTargetTap;

  /// Função chamada quando o usuário toca na área de fundo
  final VoidCallback onBackdropTap;

  /// Cor do fundo (overlay)
  final Color overlayColor;

  /// Opacidade do fundo
  final double overlayOpacity;

  /// Se deve animar o destaque
  final bool animateSpotlight;

  /// Widget para exibir como tooltip
  final Widget tooltip;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onTargetTap,
    required this.onBackdropTap,
    required this.tooltip,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.7,
    this.animateSpotlight = true,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  /// Controlador para a animação de pulsação do destaque
  late AnimationController _pulseController;

  /// Animação para o efeito de pulsação
  late Animation<double> _pulseAnimation;

  /// Posição do elemento alvo na tela
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();

    // Configurar animação de pulsação
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 6.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Iniciar ou parar a animação com base na configuração
    if (widget.animateSpotlight) {
      _pulseController.forward();
    } else {
      _pulseController.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obter a posição do elemento alvo na tela
    _targetRect = widget.step.getTargetPosition(context);
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualizar a posição quando o widget for atualizado
    if (oldWidget.step != widget.step) {
      _targetRect = widget.step.getTargetPosition(context);
    }

    // Atualizar o estado da animação
    if (widget.animateSpotlight != oldWidget.animateSpotlight) {
      if (widget.animateSpotlight) {
        _pulseController.forward();
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) {
      // Se não conseguir encontrar o elemento alvo, mostrar apenas o fundo
      return _buildBackdrop(context);
    }

    return Stack(
      children: [
        // Fundo semitransparente
        _buildBackdrop(context),

        // Destaque com efeito de pulsar
        _buildSpotlight(context),

        // Tooltip posicionada corretamente
        Positioned.fill(
          child: FadeAnimation.fadeIn(
            delay: const Duration(milliseconds: 150),
            child: widget.tooltip,
          ),
        ),
      ],
    );
  }

  /// Constrói o fundo semitransparente
  Widget _buildBackdrop(BuildContext context) {
    return GestureDetector(
      onTap: widget.onBackdropTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: widget.overlayColor
            .withAlpha((widget.overlayOpacity * 255).round()),
      ),
    );
  }

  /// Constrói o destaque ao redor do elemento alvo
  Widget _buildSpotlight(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _SpotlightPainter(
            targetRect: _targetRect!,
            pulseValue: widget.animateSpotlight ? _pulseAnimation.value : 2.0,
            spotlightShape: widget.step.spotlightShape,
          ),
        );
      },
    );
  }
}

/// Painter customizado para desenhar o "buraco" no overlay e o efeito de brilho
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double pulseValue;
  final ShapeBorder? spotlightShape;

  _SpotlightPainter({
    required this.targetRect,
    required this.pulseValue,
    this.spotlightShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Criar um path que cobre toda a tela
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Criar o path para o "buraco"
    final Path holePath = _createHolePath();

    // Combinar os paths usando o operador de diferença
    final Path finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    // Pintar o path final
    canvas.drawPath(
      finalPath,
      Paint()..color = Colors.transparent,
    );

    // Desenhar o brilho ao redor do destaque
    _drawGlow(canvas);
  }

  /// Cria o path para o "buraco" no overlay
  Path _createHolePath() {
    if (spotlightShape != null) {
      // Usar uma forma personalizada
      final Path path = Path();
      spotlightShape!
          .getOuterPath(targetRect, textDirection: TextDirection.ltr)
          .addPath(path, Offset.zero);
      return path;
    } else {
      // Forma padrão (círculo ou retângulo arredondado)
      final Path path = Path();

      final double width = targetRect.width;
      final double height = targetRect.height;

      // Usar círculo para elementos quadrados, retângulo arredondado para retangulares
      if ((width - height).abs() < 10) {
        // Elemento aproximadamente quadrado, usar círculo
        final double radius = (width + height) / 2 / 1.5;
        path.addOval(
          Rect.fromCenter(
            center: targetRect.center,
            width: radius * 2,
            height: radius * 2,
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

  /// Desenha o efeito de brilho ao redor do destaque
  void _drawGlow(Canvas canvas) {
    for (int i = 1; i <= 4; i++) {
      final double opacity = (0.7 - (i * 0.1)).clamp(0.0, 1.0);
      final double spreadSize = pulseValue * i;

      final Paint glowPaint = Paint()
        ..color = Colors.white.withAlpha((opacity * 255).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spreadSize);

      if (spotlightShape != null) {
        // Brilho para forma personalizada
        final Path path = Path();
        spotlightShape!
            .getOuterPath(targetRect, textDirection: TextDirection.ltr)
            .addPath(path, Offset.zero);
        canvas.drawPath(path, glowPaint);
      } else {
        // Brilho para forma padrão
        final double width = targetRect.width;
        final double height = targetRect.height;

        if ((width - height).abs() < 10) {
          // Brilho para círculo
          final double radius = (width + height) / 2 / 1.5 + spreadSize;
          canvas.drawCircle(
            targetRect.center,
            radius,
            glowPaint,
          );
        } else {
          // Brilho para retângulo arredondado
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              targetRect.inflate(spreadSize),
              Radius.circular(8 + spreadSize),
            ),
            glowPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        pulseValue != oldDelegate.pulseValue ||
        spotlightShape != oldDelegate.spotlightShape;
  }
}
/*Características do TutorialOverlay
Este componente tem várias características importantes:

1. Design Visual Atrativo
Fundo Semitransparente: Cria uma camada escurecida para focar a atenção do usuário
Destaque Animado: Efeito de pulsação sutil para atrair o olhar para o elemento alvo
Efeito de Brilho: Adiciona um halo luminoso ao redor do elemento destacado
2. Flexibilidade de Exibição
Formas Adaptativas: Detecta automaticamente se deve usar um círculo ou retângulo
Formas Personalizadas: Suporta ShapeBorder personalizado para casos especiais
Posicionamento Automático: Ajusta a posição do tooltip com base no elemento destacado
3. Interatividade Inteligente
Eventos de Toque: Gerencia toques no fundo e no elemento destacado separadamente
Animações Controláveis: Permite ativar/desativar as animações
4. Integração com Animações Existentes
Usa o FadeAnimation existente no seu projeto para transições suaves
Este overlay será a base visual do tutorial interativo, criando um efeito profissional semelhante aos tutoriais encontrados em aplicativos de alta qualidade.*/
