import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../tokens/radius_tokens.dart';

/// Biblioteca de microinterações e animações interativas para o Clube de Benefícios.
///
/// Fornece componentes animados que respondem às interações do usuário,
/// criando uma experiência mais dinâmica e envolvente.
class InteractiveAnimations {
  /// Não permite criar instâncias desta classe
  InteractiveAnimations._();

  /// Duração padrão para microinterações
  static const Duration defaultMicroDuration = Duration(milliseconds: 150);

  /// Duração padrão para interações médias
  static const Duration defaultMediumDuration = Duration(milliseconds: 300);

  /// Duração padrão para interações longas
  static const Duration defaultLongDuration = Duration(milliseconds: 500);

  /// Curva padrão para microinterações
  static const Curve defaultMicroCurve = Curves.easeOut;

  /// Curva para efeitos de elasticidade
  static const Curve springCurve = Curves.elasticOut;
}

/// Botão com efeito de onda ao ser pressionado
class RippleButton extends StatefulWidget {
  /// Widget filho dentro do botão
  final Widget child;

  /// Cor do efeito de onda
  final Color? rippleColor;

  /// Cor de fundo do botão
  final Color? backgroundColor;

  /// Raio dos cantos do botão
  final double borderRadius;

  /// Função chamada ao pressionar o botão
  final VoidCallback? onTap;

  /// Duração da animação
  final Duration duration;

  /// Se o botão está desabilitado
  final bool disabled;

  /// Tamanho da onda (1.0 = 100% do botão)
  final double rippleFactor;

  /// Cria um botão com efeito de onda ao ser pressionado
  const RippleButton({
    super.key,
    required this.child,
    this.rippleColor,
    this.backgroundColor,
    this.borderRadius = RadiusTokens.button,
    this.onTap,
    this.duration = const Duration(milliseconds: 600),
    this.disabled = false,
    this.rippleFactor = 1.2,
  });

  @override
  State<RippleButton> createState() => _RippleButtonState();
}

class _RippleButtonState extends State<RippleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset _tapPosition = Offset.zero;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.disabled) return;

    setState(() {
      _tapPosition = details.localPosition;
      _isPressed = true;
    });

    _controller.reset();
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.disabled) return;

    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    if (widget.disabled) return;

    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveRippleColor =
        widget.rippleColor ?? AppColors.primary.withAlpha((0.3 * 255).round());
    final Color effectiveBackgroundColor =
        widget.backgroundColor ?? Colors.transparent;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.disabled ? null : widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            // Fundo e conteúdo do botão
            Container(
              color: effectiveBackgroundColor,
              child: widget.child,
            ),

            // Efeito de onda animado
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RipplePainter(
                      position: _tapPosition,
                      radius: _animation.value *
                          math.max(context.size!.width, context.size!.height) *
                          widget.rippleFactor,
                      color: effectiveRippleColor,
                      show: _isPressed || _animation.value < 1.0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Offset position;
  final double radius;
  final Color color;
  final bool show;

  _RipplePainter({
    required this.position,
    required this.radius,
    required this.color,
    required this.show,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color ||
        oldDelegate.show != show;
  }
}

/// Botão que se transforma em indicador de loading quando pressionado
class LoadingButton extends StatefulWidget {
  /// Texto do botão
  final String text;

  /// Estilo do texto
  final TextStyle? textStyle;

  /// Largura do botão
  final double width;

  /// Altura do botão
  final double height;

  /// Cor do botão
  final Color? color;

  /// Cor do texto
  final Color? textColor;

  /// Função chamada ao pressionar o botão
  final Future<void> Function() onPressed;

  /// Raio dos cantos do botão
  final double borderRadius;

  /// Widget de loading personalizado
  final Widget? loadingWidget;

  /// Cor do indicador de loading
  final Color? loadingColor;

  /// Cria um botão que se transforma em loading quando pressionado
  const LoadingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textStyle,
    this.width = 200,
    this.height = 50,
    this.color,
    this.textColor,
    this.borderRadius = RadiusTokens.button,
    this.loadingWidget,
    this.loadingColor,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<BorderRadius?> _borderAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = Tween<double>(
      begin: widget.width,
      end: widget.height, // Torna o botão quadrado
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _borderAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(widget.borderRadius),
      end: BorderRadius.circular(widget.height / 2),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await _controller.forward();

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        await _controller.reverse();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = widget.color ?? AppColors.primary;
    final Color effectiveTextColor = widget.textColor ?? Colors.white;
    final Color effectiveLoadingColor =
        widget.loadingColor ?? effectiveTextColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isLoading ? null : _handlePress,
          child: Container(
            width: _widthAnimation.value,
            height: widget.height,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: _borderAnimation.value,
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withAlpha((0.3 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? widget.loadingWidget ??
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              effectiveLoadingColor),
                        ),
                      )
                  : Text(
                      widget.text,
                      style: widget.textStyle ??
                          TextStyle(
                            color: effectiveTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Card com efeito de escala ao pressionar
class PressableCard extends StatefulWidget {
  /// Widget filho dentro do card
  final Widget child;

  /// Função chamada ao pressionar o card
  final VoidCallback? onPress;

  /// Fator de escala quando pressionado (0.9 = 90% do tamanho original)
  final double pressedScale;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Decoração do card
  final BoxDecoration? decoration;

  /// Padding interno
  final EdgeInsets padding;

  /// Cria um card que responde a toques com animação de escala
  const PressableCard({
    super.key,
    required this.child,
    this.onPress,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    this.decoration,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final BoxDecoration effectiveDecoration = widget.decoration ??
        BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPress,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: Container(
          decoration: effectiveDecoration,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Widget com efeito de carregamento de cartão de raspar
class ScratchCardReveal extends StatefulWidget {
  /// Widget exibido antes de "raspar" (cobertura)
  final Widget coverWidget;

  /// Widget revelado após raspar
  final Widget revealWidget;

  /// Largura do componente
  final double width;

  /// Altura do componente
  final double height;

  /// Percentual necessário para considerar como revelado (0-1)
  final double thresholdPercent;

  /// Função chamada quando o cartão é revelado
  final VoidCallback? onRevealed;

  /// Tamanho do pincel para raspar
  final double brushSize;

  /// Cria um efeito de cartão de raspar
  const ScratchCardReveal({
    super.key,
    required this.coverWidget,
    required this.revealWidget,
    required this.width,
    required this.height,
    this.thresholdPercent = 0.5,
    this.onRevealed,
    this.brushSize = 40,
  });

  @override
  State<ScratchCardReveal> createState() => _ScratchCardRevealState();
}

class _ScratchCardRevealState extends State<ScratchCardReveal> {
  late Offset _lastPoint;
  double _scratchPercent = 0.0;
  bool _revealed = false;
  final List<Offset> _points = [];

  // Armazena os pontos riscados para calcular área descoberta
  final Set<Offset> _scratchedPoints = {};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Widget revelado (fundo)
          widget.revealWidget,

          // Camada para raspar
          _revealed
              ? const SizedBox() // Se já revelado, não mostra cobertura
              : GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    children: [
                      // Widget de cobertura
                      widget.coverWidget,

                      // Área riscada (transparente)
                      CustomPaint(
                        size: Size(widget.width, widget.height),
                        painter: _ScratchPainter(
                          points: _points,
                          brushSize: widget.brushSize,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _lastPoint = details.localPosition;
    _points.add(_lastPoint);
    _updateScratchArea(_lastPoint);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final currentPoint = details.localPosition;

    // Adiciona pontos intermediários para traço contínuo
    final distance = (_lastPoint - currentPoint).distance;
    if (distance > 0) {
      // Calcule pontos intermediários para traçado uniforme
      final numPoints = (distance / 5).ceil(); // Um ponto a cada 5 pixels
      for (int i = 1; i <= numPoints; i++) {
        final t = i / numPoints;
        final interpolatedPoint = Offset(
          _lastPoint.dx + (currentPoint.dx - _lastPoint.dx) * t,
          _lastPoint.dy + (currentPoint.dy - _lastPoint.dy) * t,
        );
        _points.add(interpolatedPoint);
        _updateScratchArea(interpolatedPoint);
      }
    }

    _lastPoint = currentPoint;
    setState(() {});
    _checkRevealThreshold();
  }

  void _onPanEnd(DragEndDetails details) {
    _checkRevealThreshold();
  }

  void _updateScratchArea(Offset point) {
    // Adiciona todos os pontos em um raio ao redor do ponto atual
    final int radius = widget.brushSize ~/ 2;
    final int radiusSquared = radius * radius;

    for (int y = -radius; y <= radius; y++) {
      for (int x = -radius; x <= radius; x++) {
        if (x * x + y * y <= radiusSquared) {
          final Offset offset = Offset(
            point.dx + x,
            point.dy + y,
          );

          // Verifica se o ponto está dentro dos limites do cartão
          if (offset.dx >= 0 &&
              offset.dx <= widget.width &&
              offset.dy >= 0 &&
              offset.dy <= widget.height) {
            _scratchedPoints.add(offset);
          }
        }
      }
    }
  }

  void _checkRevealThreshold() {
    if (_revealed) return;

    // Calcular a porcentagem da área riscada
    final totalArea = widget.width * widget.height;
    final scratchedArea = _scratchedPoints.length;
    _scratchPercent = scratchedArea / totalArea * 100;

    // Verifica se atingiu o limiar
    if (_scratchPercent >= widget.thresholdPercent * 100) {
      setState(() {
        _revealed = true;
      });
      widget.onRevealed?.call();
    }
  }
}

class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  final double brushSize;

  _ScratchPainter({required this.points, required this.brushSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.transparent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = brushSize
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.clear;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
      canvas.drawCircle(points[i], brushSize / 2, paint);
    }

    if (points.isNotEmpty) {
      canvas.drawCircle(points.last, brushSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ScratchPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

/// Widget que exibe uma animação de pulso infinita
class PulseAnimation extends StatefulWidget {
  /// Widget filho que será animado
  final Widget child;

  /// Duração de um ciclo completo
  final Duration duration;

  /// Escala mínima (0.0-1.0)
  final double minScale;

  /// Escala máxima (acima de 1.0)
  final double maxScale;

  /// Curva da animação
  final Curve curve;

  /// Se a animação deve ser executada automaticamente
  final bool autoPlay;

  /// Cria uma animação de pulso
  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.9,
    this.maxScale = 1.1,
    this.curve = Curves.easeInOut,
    this.autoPlay = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: widget.maxScale),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.maxScale, end: widget.minScale),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.minScale, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.autoPlay) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Inicia a animação de pulso
  void play() {
    _controller.repeat();
  }

  /// Pausa a animação de pulso
  void pause() {
    _controller.stop();
  }

  /// Reseta a animação para o estado inicial
  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Botão com efeito de parallax ao hover/pressionar
class ParallaxButton extends StatefulWidget {
  /// Widget filho a ser exibido
  final Widget child;

  /// Widget de fundo (opcional, permite efeito de profundidade)
  final Widget? background;

  /// Função chamada ao pressionar
  final VoidCallback? onPressed;

  /// Intensidade do efeito de parallax (0-1)
  final double intensity;

  /// Profundidade entre camadas
  final double depth;

  /// Altura do componente
  final double height;

  /// Largura do componente
  final double width;

  /// Cria um botão com efeito de parallax
  const ParallaxButton({
    super.key,
    required this.child,
    this.background,
    this.onPressed,
    this.intensity = 0.05,
    this.depth = 10,
    this.height = 60,
    this.width = 200,
  });

  @override
  State<ParallaxButton> createState() => _ParallaxButtonState();
}

class _ParallaxButtonState extends State<ParallaxButton> {
  bool isPressed = false;
  Offset _localPosition = Offset.zero;

  void _updatePosition(Offset position, Size size) {
    setState(() {
      // Normaliza a posição para valores entre -1 e 1
      _localPosition = Offset(
        (position.dx / size.width) * 2 - 1,
        (position.dy / size.height) * 2 - 1,
      );
    });
  }

  void _resetPosition() {
    setState(() {
      _localPosition = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() => isPressed = true);
        _updatePosition(
            details.localPosition, Size(widget.width, widget.height));
      },
      onTapUp: (details) {
        setState(() => isPressed = false);
        _resetPosition();
      },
      onTapCancel: () {
        setState(() => isPressed = false);
        _resetPosition();
      },
      onTap: widget.onPressed,
      onPanUpdate: (details) {
        _updatePosition(
            details.localPosition, Size(widget.width, widget.height));
      },
      onPanEnd: (details) {
        _resetPosition();
      },
      child: MouseRegion(
        onHover: (event) {
          _updatePosition(
              event.localPosition, Size(widget.width, widget.height));
        },
        onExit: (event) {
          _resetPosition();
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusTokens.button),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.2 * 255).round()),
                blurRadius: 8,
                offset: Offset(
                  _localPosition.dx * widget.intensity * 10,
                  _localPosition.dy * widget.intensity * 10,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RadiusTokens.button),
            child: Stack(
              children: [
                // Fundo (se fornecido)
                if (widget.background != null)
                  Transform.translate(
                    offset: Offset(
                      -_localPosition.dx * widget.intensity * widget.depth,
                      -_localPosition.dy * widget.intensity * widget.depth,
                    ),
                    child: widget.background,
                  ),

                // Conteúdo principal
                Transform.translate(
                  offset: Offset(
                    -_localPosition.dx * widget.intensity * (widget.depth / 2),
                    -_localPosition.dy * widget.intensity * (widget.depth / 2),
                  ),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget que executa uma animação de sucesso (check mark)
class AnimatedCheckmark extends StatefulWidget {
  /// Tamanho do checkmark
  final double size;

  /// Cor do checkmark
  final Color color;

  /// Duração da animação
  final Duration duration;

  /// Largura da linha
  final double strokeWidth;

  /// Se deve animar automaticamente
  final bool animate;

  /// Cria uma animação de checkmark
  const AnimatedCheckmark({
    super.key,
    this.size = 100.0,
    this.color = Colors.green,
    this.duration = const Duration(milliseconds: 600),
    this.strokeWidth = 4.0,
    this.animate = true,
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

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animate && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Inicia a animação
  void play() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckmarkPainter(
            progress: _animation.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    // Pontos para o checkmark
    final double firstPointX = size.width * 0.25;
    final double firstPointY = size.height * 0.5;
    final double secondPointX = size.width * 0.45;
    final double secondPointY = size.height * 0.7;
    final double thirdPointX = size.width * 0.75;
    final double thirdPointY = size.height * 0.3;

    // Calcular o comprimento total e os pontos da animação
    final double totalLength =
        (secondPointX - firstPointX) * (secondPointX - firstPointX) +
            (secondPointY - firstPointY) * (secondPointY - firstPointY) +
            (thirdPointX - secondPointX) * (thirdPointX - secondPointX) +
            (thirdPointY - secondPointY) * (thirdPointY - secondPointY);

    final double firstSegmentLength =
        (secondPointX - firstPointX) * (secondPointX - firstPointX) +
            (secondPointY - firstPointY) * (secondPointY - firstPointY);

    final double firstSegmentPercentage = firstSegmentLength / totalLength;

    if (progress < firstSegmentPercentage) {
      // Primeiro segmento
      final segmentProgress = progress / firstSegmentPercentage;

      path.moveTo(firstPointX, firstPointY);
      path.lineTo(
        firstPointX + (secondPointX - firstPointX) * segmentProgress,
        firstPointY + (secondPointY - firstPointY) * segmentProgress,
      );
    } else {
      // Ambos segmentos, o primeiro completo
      path.moveTo(firstPointX, firstPointY);
      path.lineTo(secondPointX, secondPointY);

      // Calcula o progresso do segundo segmento
      final secondSegmentProgress =
          (progress - firstSegmentPercentage) / (1 - firstSegmentPercentage);

      path.lineTo(
        secondPointX + (thirdPointX - secondPointX) * secondSegmentProgress,
        secondPointY + (thirdPointY - secondPointY) * secondSegmentProgress,
      );
    }

    // Desenhe o caminho
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Widget que realiza uma transformação ao hover/pressionar
class MorphingButton extends StatefulWidget {
  /// Estado normal do botão
  final Widget normalState;

  /// Estado transformado/hover do botão
  final Widget hoverState;

  /// Função chamada ao pressionar
  final VoidCallback? onPressed;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Altura do botão
  final double height;

  /// Largura do botão
  final double width;

  /// Cria um botão que se transforma ao interagir
  const MorphingButton({
    super.key,
    required this.normalState,
    required this.hoverState,
    this.onPressed,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.height = 50,
    this.width = 150,
  });

  @override
  State<MorphingButton> createState() => _MorphingButtonState();
}

class _MorphingButtonState extends State<MorphingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      onHover: (hovered) {
        setState(() {
          _isHovered = hovered;
        });
      },
      onHighlightChanged: (highlighted) {
        if (highlighted) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedCrossFade(
          firstChild: widget.normalState,
          secondChild: widget.hoverState,
          crossFadeState:
              _isHovered ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: widget.duration,
          reverseDuration: widget.duration,
          layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  key: bottomChildKey,
                  child: bottomChild,
                ),
                Positioned(
                  key: topChildKey,
                  child: topChild,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget que realiza uma animação de contador
class AnimatedCounter extends StatefulWidget {
  /// Valor inicial
  final int begin;

  /// Valor final
  final int end;

  /// Duração da animação
  final Duration duration;

  /// Estilo do texto
  final TextStyle? textStyle;

  /// Formato do número
  final String Function(int)? formatter;

  /// Curva da animação
  final Curve curve;

  /// Cria um contador animado
  const AnimatedCounter({
    super.key,
    required this.begin,
    required this.end,
    this.duration = const Duration(milliseconds: 1500),
    this.textStyle,
    this.formatter,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _oldValue;
  late int _newValue;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.begin;
    _newValue = widget.end;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: _oldValue.toDouble(),
      end: _newValue.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.end != _newValue) {
      _oldValue = _newValue;
      _newValue = widget.end;

      _animation = Tween<double>(
        begin: _oldValue.toDouble(),
        end: _newValue.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.round();
        final formattedValue = widget.formatter != null
            ? widget.formatter!(value)
            : value.toString();

        return Text(
          formattedValue,
          style: widget.textStyle,
        );
      },
    );
  }
}

/// Widget que exibe um indicador de escala com animação
class AnimatedGauge extends StatefulWidget {
  /// Valor atual (0.0-1.0)
  final double value;

  /// Cor de fundo
  final Color backgroundColor;

  /// Cor do indicador
  final Color foregroundColor;

  /// Altura do gauge
  final double height;

  /// Largura do gauge
  final double width;

  /// Duração da animação
  final Duration duration;

  /// Rótulo (opcional)
  final Widget? label;

  /// Curva da animação
  final Curve curve;

  /// Cria um indicador de gauge animado
  const AnimatedGauge({
    super.key,
    required this.value,
    this.backgroundColor = Colors.grey,
    this.foregroundColor = Colors.green,
    this.height = 20,
    this.width = 200,
    this.duration = const Duration(milliseconds: 500),
    this.label,
    this.curve = Curves.easeInOut,
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  State<AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<AnimatedGauge> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: widget.label,
          ),
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: widget.duration,
                curve: widget.curve,
                width: widget.width * widget.value,
                decoration: BoxDecoration(
                  color: widget.foregroundColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),
              // Indicador
              AnimatedPositioned(
                duration: widget.duration,
                curve: widget.curve,
                left: widget.width * widget.value - (widget.height * 0.8),
                top: widget.height * 0.1,
                child: Container(
                  width: widget.height * 0.8,
                  height: widget.height * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget que cria uma animação de menu circular
class RadialMenu extends StatefulWidget {
  /// Ícone central do menu
  final IconData centerIcon;

  /// Cor do botão central
  final Color centerColor;

  /// Lista de opções do menu
  final List<RadialMenuOption> options;

  /// Tamanho do botão central
  final double centerButtonSize;

  /// Tamanho dos botões de opção
  final double optionButtonSize;

  /// Distância do centro às opções
  final double radius;

  /// Duração da animação
  final Duration duration;

  /// Cria um menu radial animado
  const RadialMenu({
    super.key,
    required this.centerIcon,
    required this.options,
    this.centerColor = Colors.blue,
    this.centerButtonSize = 60,
    this.optionButtonSize = 50,
    this.radius = 100,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;

      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius * 2 + widget.optionButtonSize,
      height: widget.radius * 2 + widget.optionButtonSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Opções do menu
          ..._buildMenuOptions(),

          // Botão central
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              width: widget.centerButtonSize,
              height: widget.centerButtonSize,
              decoration: BoxDecoration(
                color: widget.centerColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.centerColor.withAlpha((0.5 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0, // 45 graus quando aberto
                duration: widget.duration,
                child: Icon(
                  widget.centerIcon,
                  color: Colors.white,
                  size: widget.centerButtonSize / 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuOptions() {
    final List<Widget> options = [];
    final int optionsCount = widget.options.length;

    for (int i = 0; i < optionsCount; i++) {
      final double angle = (2 * math.pi / optionsCount) * i;

      options.add(
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double x = widget.radius * math.cos(angle) * _animation.value;
            final double y = widget.radius * math.sin(angle) * _animation.value;

            return Positioned(
              left: (widget.radius * 2 + widget.optionButtonSize) / 2 +
                  x -
                  widget.optionButtonSize / 2,
              top: (widget.radius * 2 + widget.optionButtonSize) / 2 +
                  y -
                  widget.optionButtonSize / 2,
              child: Transform.scale(
                scale: _animation.value,
                child: Opacity(
                  opacity: _animation.value,
                  child: GestureDetector(
                    onTap: () {
                      if (_isOpen) {
                        _toggleMenu();
                        widget.options[i].onTap?.call();
                      }
                    },
                    child: Container(
                      width: widget.optionButtonSize,
                      height: widget.optionButtonSize,
                      decoration: BoxDecoration(
                        color: widget.options[i].color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.options[i].color
                                .withAlpha((0.5 * 255).round()),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.options[i].icon,
                        color: Colors.white,
                        size: widget.optionButtonSize / 2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return options;
  }
}

/// Opção para o menu radial
class RadialMenuOption {
  /// Ícone da opção
  final IconData icon;

  /// Cor do botão da opção
  final Color color;

  /// Função chamada ao pressionar
  final VoidCallback? onTap;

  /// Label da opção (opcional)
  final String? label;

  /// Cria uma opção para o menu radial
  const RadialMenuOption({
    required this.icon,
    required this.color,
    this.onTap,
    this.label,
  });
}

/// Widget que cria um efeito ondulante interativo
class WaveButton extends StatefulWidget {
  /// Widget filho
  final Widget child;

  /// Cor das ondas
  final Color waveColor;

  /// Tamanho do componente
  final Size size;

  /// Cor de fundo
  final Color backgroundColor;

  /// Função chamada ao pressionar
  final VoidCallback? onTap;

  /// Se deve mostrar ondas ao tocar
  final bool enableTouchWaves;

  /// Cria um botão com efeito de ondas interativas
  const WaveButton({
    super.key,
    required this.child,
    required this.size,
    this.waveColor = Colors.white,
    this.backgroundColor = Colors.blue,
    this.onTap,
    this.enableTouchWaves = true,
  });

  @override
  State<WaveButton> createState() => _WaveButtonState();
}

class _WaveButtonState extends State<WaveButton> with TickerProviderStateMixin {
  final List<_WaveCircle> _waves = [];
  final List<AnimationController> _controllers = [];

  // Controlador para ondas automáticas
  late AnimationController _autoWaveController;
  late Animation<double> _autoWaveAnimation;

  @override
  void initState() {
    super.initState();

    // Configuração para ondas automáticas
    _autoWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _autoWaveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _autoWaveController, curve: Curves.easeInOut),
    )..addListener(() {
        if (_autoWaveAnimation.value == 1.0) {
          _autoWaveController.reset();
          _autoWaveController.forward();

          // Adiciona uma onda automática
          _addWave(Offset(widget.size.width / 2, widget.size.height / 2), true);
        }
      });

    _autoWaveController.forward();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _autoWaveController.dispose();
    super.dispose();
  }

  void _addWave(Offset position, bool isAutoWave) {
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isAutoWave ? 3000 : 1000),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    final wave = _WaveCircle(
      position: position,
      animation: animation,
      isAutoWave: isAutoWave,
    );

    setState(() {
      _waves.add(wave);
      _controllers.add(controller);
    });

    controller.forward().then((_) {
      setState(() {
        final index = _waves.indexOf(wave);
        if (index != -1) {
          _waves.removeAt(index);
          final removedController = _controllers.removeAt(index);
          removedController.dispose();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enableTouchWaves
          ? (details) {
              _addWave(details.localPosition, false);
            }
          : null,
      onTap: widget.onTap,
      child: Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Ondas
            ..._waves.map((wave) => AnimatedBuilder(
                  animation: wave.animation,
                  builder: (context, _) {
                    final double maxRadius = math.max(
                          widget.size.width,
                          widget.size.height,
                        ) *
                        1.5;

                    final double radius = maxRadius * wave.animation.value;
                    final double opacity = wave.isAutoWave
                        ? 0.3 * (1 - wave.animation.value)
                        : 0.5 * (1 - wave.animation.value);

                    return Positioned(
                      left: wave.position.dx - radius,
                      top: wave.position.dy - radius,
                      width: radius * 2,
                      height: radius * 2,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.waveColor
                              .withAlpha((opacity * 255).round()),
                        ),
                      ),
                    );
                  },
                )),

            // Conteúdo principal
            Center(child: widget.child),
          ],
        ),
      ),
    );
  }
}

/// Definição de um círculo de onda para o WaveButton
class _WaveCircle {
  final Offset position;
  final Animation<double> animation;
  final bool isAutoWave;

  _WaveCircle({
    required this.position,
    required this.animation,
    this.isAutoWave = false,
  });
}

/// Widget que realiza animação ao arrastar para atualizar (pull-to-refresh)
class PullToRefresh extends StatefulWidget {
  /// Widget filho a ser atualizado
  final Widget child;

  /// Função chamada para atualizar
  final Future<void> Function() onRefresh;

  /// Altura máxima do indicador
  final double maxIndicatorHeight;

  /// Resistência ao arrastar
  final double resistance;

  /// Widget personalizado para o indicador
  final Widget Function(double progress)? indicatorBuilder;

  /// Cor do indicador padrão
  final Color indicatorColor;

  /// Cria um componente de pull-to-refresh animado
  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.maxIndicatorHeight = 100.0,
    this.resistance = 0.5,
    this.indicatorBuilder,
    this.indicatorColor = Colors.blue,
  });

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  double _refreshThreshold = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _refreshThreshold = widget.maxIndicatorHeight * 0.7;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        _controller.animateTo(0);
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isRefreshing) return;

    setState(() {
      _dragOffset += details.primaryDelta! * widget.resistance;
      _dragOffset = _dragOffset.clamp(0.0, widget.maxIndicatorHeight);
      _controller.value = _dragOffset / widget.maxIndicatorHeight;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isRefreshing) return;

    if (_dragOffset > _refreshThreshold) {
      _onRefresh();
    } else {
      _controller.animateTo(0);
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Indicador
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: _dragOffset,
            child: Center(
              child: widget.indicatorBuilder != null
                  ? widget.indicatorBuilder!(_controller.value)
                  : _defaultIndicator(),
            ),
          ),
        ),

        // Conteúdo principal
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _dragOffset),
              child: child,
            );
          },
          child: GestureDetector(
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            child: widget.child,
          ),
        ),
      ],
    );
  }

  Widget _defaultIndicator() {
    final bool willRefresh = _dragOffset > _refreshThreshold;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      width: 50,
      child: _isRefreshing
          ? CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(widget.indicatorColor),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _controller.value,
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(widget.indicatorColor),
                ),
                Icon(
                  willRefresh ? Icons.refresh : Icons.arrow_downward,
                  color: widget.indicatorColor,
                  size: 24,
                ),
              ],
            ),
    );
  }
}

/// Widget para barra de navegação com ícones interativos
class InteractiveNavBar extends StatefulWidget {
  /// Itens da barra de navegação
  final List<InteractiveNavItem> items;

  /// Índice selecionado
  final int selectedIndex;

  /// Função chamada ao selecionar item
  final Function(int) onItemSelected;

  /// Cor de fundo
  final Color backgroundColor;

  /// Cor do indicador
  final Color indicatorColor;

  /// Altura da barra
  final double height;

  /// Raio dos cantos (se > 0)
  final double borderRadius;

  /// Duração da animação
  final Duration duration;

  /// Cria uma barra de navegação com ícones interativos
  const InteractiveNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.backgroundColor = Colors.white,
    this.indicatorColor = Colors.blue,
    this.height = 65,
    this.borderRadius = 0,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<InteractiveNavBar> createState() => _InteractiveNavBarState();
}

class _InteractiveNavBarState extends State<InteractiveNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();

    _initControllers();
  }

  @override
  void didUpdateWidget(InteractiveNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se o número de itens mudou, recria os controladores
    if (widget.items.length != oldWidget.items.length) {
      _disposeControllers();
      _initControllers();
    }

    // Anima o item selecionado
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _controllers[oldWidget.selectedIndex].reverse();
      _controllers[widget.selectedIndex].forward();
    }
  }

  void _initControllers() {
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
        value: index == widget.selectedIndex ? 1.0 : 0.0,
      ),
    );
  }

  void _disposeControllers() {
    for (var controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius > 0
            ? BorderRadius.only(
                topLeft: Radius.circular(widget.borderRadius),
                topRight: Radius.circular(widget.borderRadius),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(widget.items.length, (index) {
          return _buildNavItem(index);
        }),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = widget.selectedIndex == index;
    final item = widget.items[index];

    return GestureDetector(
      onTap: () => widget.onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / widget.items.length,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicador animado
            AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Container(
                  width: 30 * _controllers[index].value,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: widget.indicatorColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              },
            ),

            // Ícone com animação
            AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -4 * _controllers[index].value),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: Color.lerp(
                      item.inactiveColor ?? Colors.grey,
                      item.activeColor ?? widget.indicatorColor,
                      _controllers[index].value,
                    ),
                    size: 24 + (4 * _controllers[index].value),
                  ),
                );
              },
            ),

            // Label com fade
            if (item.label != null)
              AnimatedBuilder(
                animation: _controllers[index],
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.5 + (0.5 * _controllers[index].value),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.label!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _controllers[index].value > 0.5
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Color.lerp(
                            item.inactiveColor ?? Colors.grey,
                            item.activeColor ?? widget.indicatorColor,
                            _controllers[index].value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Item para a barra de navegação interativa
class InteractiveNavItem {
  /// Ícone no estado inativo
  final IconData icon;

  /// Ícone no estado ativo
  final IconData activeIcon;

  /// Rótulo (opcional)
  final String? label;

  /// Cor quando ativo
  final Color? activeColor;

  /// Cor quando inativo
  final Color? inactiveColor;

  /// Cria um item para barra de navegação interativa
  const InteractiveNavItem({
    required this.icon,
    IconData? activeIcon,
    this.label,
    this.activeColor,
    this.inactiveColor,
  }) : activeIcon = activeIcon ?? icon;
}

/// Widget de entrada com validação e animação
class AnimatedTextField extends StatefulWidget {
  /// Controlador do texto
  final TextEditingController controller;

  /// Rótulo do campo
  final String label;

  /// Texto de dica
  final String? hint;

  /// Se o campo é de senha
  final bool isPassword;

  /// Ícone prefixo
  final IconData? prefixIcon;

  /// Ícone sufixo
  final IconData? suffixIcon;

  /// Função de validação
  final String? Function(String?)? validator;

  /// Tipo de teclado
  final TextInputType keyboardType;

  /// Ação do teclado
  final TextInputAction textInputAction;

  /// Função ao pressionar sufixo
  final VoidCallback? onSuffixPressed;

  /// Função ao enviar
  final Function(String)? onSubmitted;

  /// Cor da borda
  final Color borderColor;

  /// Cor da borda com foco
  final Color focusedBorderColor;

  /// Cor da borda com erro
  final Color errorBorderColor;

  /// Duração da animação
  final Duration animationDuration;

  /// Cria um campo de texto com animações
  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSuffixPressed,
    this.onSubmitted,
    this.borderColor = Colors.grey,
    this.focusedBorderColor = Colors.blue,
    this.errorBorderColor = Colors.red,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasError = false;
  bool _isPasswordVisible = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _controller.forward();
        } else {
          _controller.reverse();

          // Valida ao perder foco
          if (widget.validator != null) {
            _errorText = widget.validator!(widget.controller.text);
            _hasError = _errorText != null;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: widget.animationDuration,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasError
                  ? widget.errorBorderColor
                  : _isFocused
                      ? widget.focusedBorderColor
                      : widget.borderColor,
              width: _isFocused || _hasError ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Label animado
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    left: 16,
                    top: _isFocused || hasValue ? 10 : 20,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: _isFocused || hasValue ? 12 : 16,
                        color: _hasError
                            ? widget.errorBorderColor
                            : _isFocused
                                ? widget.focusedBorderColor
                                : widget.borderColor,
                        fontWeight: _isFocused || hasValue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),

              // Campo de texto
              Padding(
                padding: EdgeInsets.only(
                  top: _isFocused || hasValue ? 12 : 0,
                  left: widget.prefixIcon != null ? 48 : 16,
                  right: widget.suffixIcon != null ? 48 : 16,
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.isPassword && !_isPasswordVisible,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _isFocused ? widget.hint : null,
                    hintStyle: TextStyle(
                      color: widget.borderColor.withAlpha((0.5 * 255).round()),
                    ),
                  ),
                  onSubmitted: widget.onSubmitted,
                ),
              ),

              // Ícone prefixo
              if (widget.prefixIcon != null)
                Positioned(
                  left: 16,
                  child: Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: _hasError
                        ? widget.errorBorderColor
                        : _isFocused
                            ? widget.focusedBorderColor
                            : widget.borderColor,
                  ),
                ),

              // Ícone sufixo
              if (widget.suffixIcon != null || widget.isPassword)
                Positioned(
                  right: 16,
                  child: GestureDetector(
                    onTap: widget.isPassword
                        ? () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          }
                        : widget.onSuffixPressed,
                    child: Icon(
                      widget.isPassword
                          ? (_isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility)
                          : widget.suffixIcon,
                      size: 20,
                      color: _hasError
                          ? widget.errorBorderColor
                          : _isFocused
                              ? widget.focusedBorderColor
                              : widget.borderColor,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Mensagem de erro
        if (_hasError && _errorText != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _hasError ? 20 : 0,
            margin: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: widget.errorBorderColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget para exibir progresso interativo em etapas
class SteppedProgressIndicator extends StatelessWidget {
  /// Número de etapas
  final int steps;

  /// Índice da etapa atual (começando em 0)
  final int currentStep;

  /// Altura do indicador
  final double height;

  /// Espaçamento entre as etapas
  final double spacing;

  /// Cor das etapas concluídas
  final Color completedColor;

  /// Cor da etapa atual
  final Color currentColor;

  /// Cor das etapas pendentes
  final Color pendingColor;

  /// Duração da animação
  final Duration duration;

  /// Espessura da linha
  final double lineThickness;

  /// Cria um indicador de progresso em etapas
  const SteppedProgressIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    this.height = 50,
    this.spacing = 8.0,
    this.completedColor = Colors.green,
    this.currentColor = Colors.blue,
    this.pendingColor = Colors.grey,
    this.duration = const Duration(milliseconds: 300),
    this.lineThickness = 3.0,
  }) : assert(currentStep >= 0 && currentStep < steps);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(steps * 2 - 1, (index) {
          // Nós alternamos entre círculos e linhas
          final bool isCircle = index % 2 == 0;
          final int stepIndex = isCircle ? index ~/ 2 : (index - 1) ~/ 2;
          final bool isCompleted = stepIndex < currentStep;
          final bool isCurrent = stepIndex == currentStep;

          if (isCircle) {
            // Renderiza um ponto/círculo indicador de etapa
            return _buildStepCircle(
              isCompleted: isCompleted,
              isCurrent: isCurrent,
            );
          } else {
            // Renderiza uma linha conectora entre etapas
            final bool isLineCompleted = stepIndex < currentStep;
            return _buildConnectingLine(isLineCompleted);
          }
        }),
      ),
    );
  }

  Widget _buildStepCircle({
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final Color color = isCompleted
        ? completedColor
        : isCurrent
            ? currentColor
            : pendingColor;

    final double size = isCurrent ? 30.0 : 24.0;

    return AnimatedContainer(
      duration: duration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCompleted ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: size * 0.6,
              )
            : isCurrent
                ? Container(
                    width: size * 0.5,
                    height: size * 0.5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox(),
      ),
    );
  }

  Widget _buildConnectingLine(bool isCompleted) {
    return Expanded(
      child: AnimatedContainer(
        duration: duration,
        height: lineThickness,
        decoration: BoxDecoration(
          color: isCompleted ? completedColor : pendingColor,
          borderRadius: BorderRadius.circular(lineThickness / 2),
        ),
        margin: EdgeInsets.symmetric(horizontal: spacing),
      ),
    );
  }
}

/// Card com efeito 3D ao toque
class TiltCard extends StatefulWidget {
  /// Widget filho
  final Widget child;

  /// Decoração do card
  final BoxDecoration? decoration;

  /// Intensidade do efeito (0-1)
  final double tiltFactor;

  /// Largura do card
  final double width;

  /// Altura do card
  final double height;

  /// Função chamada ao pressionar
  final VoidCallback? onTap;

  /// Cria um card com efeito 3D ao tocar
  const TiltCard({
    super.key,
    required this.child,
    this.decoration,
    this.tiltFactor = 0.1,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _position = Offset.zero;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration effectiveDecoration = widget.decoration ??
        BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        );

    return MouseRegion(
      onHover: (event) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(event.position);

        setState(() {
          _isHovering = true;
          _position = Offset(
            (localPosition.dx / widget.width) * 2 - 1,
            (localPosition.dy / widget.height) * 2 - 1,
          );
        });
      },
      onExit: (event) {
        setState(() {
          _isHovering = false;
          _position = Offset.zero;
        });
      },
      child: GestureDetector(
        onPanUpdate: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);

          setState(() {
            _position = Offset(
              (localPosition.dx / widget.width) * 2 - 1,
              (localPosition.dy / widget.height) * 2 - 1,
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _position = Offset.zero;
          });
        },
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: _isHovering ? 0 : 200),
          width: widget.width,
          height: widget.height,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Adiciona perspectiva
            ..rotateX(_position.dy * widget.tiltFactor)
            ..rotateY(-_position.dx * widget.tiltFactor),
          transformAlignment: Alignment.center,
          decoration: effectiveDecoration,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Botão de switch personalizado com animações
class AnimatedToggleSwitch extends StatefulWidget {
  /// Valor atual (ligado/desligado)
  final bool value;

  /// Função chamada ao mudar estado
  final ValueChanged<bool> onChanged;

  /// Largura do switch
  final double width;

  /// Altura do switch
  final double height;

  /// Cor quando ligado
  final Color activeColor;

  /// Cor quando desligado
  final Color inactiveColor;

  /// Cor do botão deslizante
  final Color thumbColor;

  /// Duração da animação
  final Duration duration;

  /// Ícone quando ligado
  final IconData? activeIcon;

  /// Ícone quando desligado
  final IconData? inactiveIcon;

  /// Cria um switch personalizado com animações
  const AnimatedToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 60,
    this.height = 30,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.thumbColor = Colors.white,
    this.duration = const Duration(milliseconds: 200),
    this.activeIcon,
    this.inactiveIcon,
  });

  @override
  State<AnimatedToggleSwitch> createState() => _AnimatedToggleSwitchState();
}

class _AnimatedToggleSwitchState extends State<AnimatedToggleSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.value ? 1.0 : 0.0,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              color: Color.lerp(
                widget.inactiveColor,
                widget.activeColor,
                _animation.value,
              ),
            ),
            padding: EdgeInsets.all(widget.height * 0.1),
            child: Stack(
              children: [
                // Botão deslizante
                Positioned(
                  left: _animation.value * (widget.width - widget.height * 0.8),
                  child: Container(
                    width: widget.height * 0.8,
                    height: widget.height * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.thumbColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).round()),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _animation.value > 0.5
                          ? widget.activeIcon != null
                              ? Icon(
                                  widget.activeIcon,
                                  color: widget.activeColor,
                                  size: widget.height * 0.5,
                                )
                              : null
                          : widget.inactiveIcon != null
                              ? Icon(
                                  widget.inactiveIcon,
                                  color: widget.inactiveColor,
                                  size: widget.height * 0.5,
                                )
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget de classificação com estrelas interativas
class AnimatedStarRating extends StatefulWidget {
  /// Valor atual (0.0-5.0)
  final double value;

  /// Função chamada ao mudar valor
  final ValueChanged<double>? onChanged;

  /// Número de estrelas
  final int starCount;

  /// Tamanho de cada estrela
  final double size;

  /// Cor das estrelas cheias
  final Color filledColor;

  /// Cor das estrelas vazias
  final Color emptyColor;

  /// Espessura das estrelas
  final double thickness;

  /// Espaço entre estrelas
  final double spacing;

  /// Duração da animação
  final Duration duration;

  /// Se permite valores parciais
  final bool allowHalfRating;

  /// Cria um componente de classificação por estrelas
  const AnimatedStarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.starCount = 5,
    this.size = 30,
    this.filledColor = Colors.amber,
    this.emptyColor = Colors.grey,
    this.thickness = 1.5,
    this.spacing = 4,
    this.duration = const Duration(milliseconds: 200),
    this.allowHalfRating = true,
  });

  @override
  State<AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends State<AnimatedStarRating> {
  double _hoverValue = 0;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.starCount, (index) {
          final double position = index + 1.0;
          double fillPercent = 0.0;

          // Calcula o preenchimento baseado no valor atual ou hover
          final double currentValue = _isHovering ? _hoverValue : widget.value;

          if (position <= currentValue) {
            fillPercent = 1.0;
          } else if (position - 1.0 < currentValue && currentValue < position) {
            fillPercent = currentValue - (position - 1.0);
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
            child: GestureDetector(
              onHorizontalDragUpdate: widget.onChanged == null
                  ? null
                  : (details) {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final double totalWidth = box.size.width;
                      final double position =
                          details.localPosition.dx.clamp(0, totalWidth);

                      final double newValue =
                          widget.starCount * position / totalWidth;
                      final double roundedValue = widget.allowHalfRating
                          ? (newValue * 2).round() / 2
                          : newValue.round().toDouble();

                      setState(() {
                        _isHovering = true;
                        _hoverValue =
                            roundedValue.clamp(0, widget.starCount.toDouble());
                      });
                    },
              onHorizontalDragEnd: widget.onChanged == null
                  ? null
                  : (_) {
                      widget.onChanged!(_hoverValue);
                      setState(() {
                        _isHovering = false;
                      });
                    },
              onTap: widget.onChanged == null
                  ? null
                  : () {
                      double newValue;

                      if (widget.allowHalfRating) {
                        // Se já está na mesma posição inteira, alterna entre x.0 e x.5
                        if (widget.value == position) {
                          newValue = position - 0.5;
                        } else if (widget.value == position - 0.5) {
                          newValue = position - 1.0;
                        } else {
                          newValue = position;
                        }
                      } else {
                        // Alterna entre cheio e vazio
                        newValue = widget.value == position
                            ? position - 1.0
                            : position;
                      }

                      widget.onChanged!(
                          newValue.clamp(0, widget.starCount.toDouble()));
                    },
              child: _buildStar(fillPercent),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStar(double fillPercent) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Estrela vazia (fundo)
          CustomPaint(
            painter: _StarPainter(
              color: widget.emptyColor,
              strokeWidth: widget.thickness,
            ),
            size: Size(widget.size, widget.size),
          ),

          // Estrela preenchida (com clipper para animação)
          ClipRect(
            clipper: _FillClipper(fillPercent: fillPercent),
            child: AnimatedContainer(
              duration: widget.duration,
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _StarPainter(
                  color: widget.filledColor,
                  strokeWidth: widget.thickness,
                  fill: true,
                ),
                size: Size(widget.size, widget.size),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clipper para animar o preenchimento parcial
class _FillClipper extends CustomClipper<Rect> {
  final double fillPercent;

  _FillClipper({required this.fillPercent});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      0,
      0,
      size.width * fillPercent,
      size.height,
    );
  }

  @override
  bool shouldReclip(_FillClipper oldClipper) {
    return oldClipper.fillPercent != fillPercent;
  }
}

/// Painter para desenhar uma estrela
class _StarPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool fill;

  _StarPainter({
    required this.color,
    required this.strokeWidth,
    this.fill = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    final path = Path();
    final double angle = math.pi / 5; // 36 graus

    for (int i = 0; i < 5; i++) {
      final double outerX =
          centerX + radius * math.cos(angle * (2 * i) - math.pi / 2);
      final double outerY =
          centerY + radius * math.sin(angle * (2 * i) - math.pi / 2);

      final double innerRadius = radius * 0.4;
      final double innerX =
          centerX + innerRadius * math.cos(angle * (2 * i + 1) - math.pi / 2);
      final double innerY =
          centerY + innerRadius * math.sin(angle * (2 * i + 1) - math.pi / 2);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }

      path.lineTo(innerX, innerY);
    }

    path.close();

    final Paint paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fill != fill;
  }
}
/*GitHub Copilot
Vamos continuar a implementação do interactive_animations.dart!
Estou muito feliz que você esteja gostando das implementações! Vamos continuar a classe InteractiveNavBar implementando o método _buildNavItem e completar o restante do arquivo:

Com isso, completamos o arquivo interactive_animations.dart com uma incrível coleção de animações interativas que podem ser usadas em todo o aplicativo Clube de Benefícios! Este componente inclui:

Principais Recursos Implementados:
Botões Avançados:

RippleButton: Efeito de onda ao tocar similar ao Material
LoadingButton: Botão que se transforma em indicador de loading
PressableCard: Cards com efeito de escala ao tocar
ParallaxButton: Efeito 3D com parallax ao passar o mouse/tocar
MorphingButton: Transformação entre dois estados
WaveButton: Efeito de ondas concêntricas ao tocar
Feedbacks Visuais:

PulseAnimation: Efeito de pulsação para chamar atenção
AnimatedCheckmark: Checkmark animado para confirmar ações
AnimatedCounter: Animação de contagem para valores
AnimatedGauge: Indicador de progresso com efeito deslizante
Componentes de Interação Complexa:

ScratchCardReveal: Efeito de "raspar" para revelar conteúdo
RadialMenu: Menu circular que expande opções
InteractiveNavBar: Barra de navegação com animações de estado
PullToRefresh: Efeito "puxe para atualizar" personalizado
TiltCard: Card com efeito de inclinação 3D
Componentes de Formulário:

AnimatedTextField: Campo de texto com label animado e validação
AnimatedToggleSwitch: Switch personalizado com animações
AnimatedStarRating: Sistema de avaliação por estrelas
Estas animações interativas trazem vida ao aplicativo, tornando a experiência do usuário muito mais agradável e engajante!*/
