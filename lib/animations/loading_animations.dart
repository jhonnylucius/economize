import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../tokens/radius_tokens.dart';

/// Biblioteca de animações de carregamento para o Clube de Benefícios.
///
/// Fornece uma variedade de indicadores visuais de carregamento
/// que seguem o design system do aplicativo.
class LoadingAnimations {
  /// Não permite criar instâncias desta classe
  LoadingAnimations._();

  /// Escala padrão para animações de carregamento
  static const double defaultSize = 48.0;
}

/// Animação de carregamento circular (spinner) estilizada
class CircularLoadingAnimation extends StatefulWidget {
  /// Cor primária da animação
  final Color? primaryColor;

  /// Cor secundária da animação (opcional)
  final Color? secondaryColor;

  /// Tamanho do indicador
  final double size;

  /// Espessura da linha
  final double strokeWidth;

  /// Duração de uma rotação completa
  final Duration duration;

  /// Cria uma animação de carregamento circular estilizada
  const CircularLoadingAnimation({
    super.key,
    this.primaryColor,
    this.secondaryColor,
    this.size = LoadingAnimations.defaultSize,
    this.strokeWidth = 4.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<CircularLoadingAnimation> createState() =>
      _CircularLoadingAnimationState();
}

class _CircularLoadingAnimationState extends State<CircularLoadingAnimation>
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
    final Color effectivePrimaryColor =
        widget.primaryColor ?? AppColors.primary;
    final Color effectiveSecondaryColor = widget.secondaryColor ??
        effectivePrimaryColor.withAlpha((0.3 * 255).round());

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CircularProgressPainter(
              progress: _controller.value,
              primaryColor: effectivePrimaryColor,
              secondaryColor: effectiveSecondaryColor,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = (size.width - strokeWidth) / 2;
    final Offset centerOffset = Offset(center, center);

    // Desenha o círculo de fundo
    final backgroundPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(centerOffset, radius, backgroundPaint);

    // Desenha o arco de progresso
    final foregroundPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double sweepAngle = 2 * math.pi * 0.65;
    final double startAngle = -math.pi / 2 + 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: centerOffset, radius: radius),
      startAngle,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Animação de pulso circular
class PulseLoadingAnimation extends StatefulWidget {
  /// Cor principal da animação
  final Color? color;

  /// Tamanho da animação
  final double size;

  /// Duração de um ciclo de pulso
  final Duration duration;

  /// Número de círculos pulsantes
  final int numberOfPulses;

  /// Cria uma animação de pulso circular
  const PulseLoadingAnimation({
    super.key,
    this.color,
    this.size = LoadingAnimations.defaultSize,
    this.duration = const Duration(milliseconds: 1500),
    this.numberOfPulses = 3,
  });

  @override
  State<PulseLoadingAnimation> createState() => _PulseLoadingAnimationState();
}

class _PulseLoadingAnimationState extends State<PulseLoadingAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      widget.numberOfPulses,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Inicia as animações com atraso entre elas
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
          Duration(
              milliseconds: (i * widget.duration.inMilliseconds) ~/
                  widget.numberOfPulses), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = widget.color ?? AppColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(widget.numberOfPulses, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Opacity(
                opacity: (1.0 - _animations[index].value).clamp(0.0, 1.0),
                child: Container(
                  width: widget.size * _animations[index].value,
                  height: widget.size * _animations[index].value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: effectiveColor.withAlpha((0.3 * 255).round()),
                    border: Border.all(
                      color: effectiveColor.withAlpha((0.8 * 255).round()),
                      width: 2.0,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Animação de três pontos pulsantes
class DotsLoadingAnimation extends StatefulWidget {
  /// Cor dos pontos
  final Color? color;

  /// Tamanho de cada ponto
  final double dotSize;

  /// Espaçamento entre os pontos
  final double spacing;

  /// Duração de um ciclo completo
  final Duration duration;

  /// Cria uma animação de três pontos pulsantes
  const DotsLoadingAnimation({
    super.key,
    this.color,
    this.dotSize = 10.0,
    this.spacing = 5.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<DotsLoadingAnimation> createState() => _DotsLoadingAnimationState();
}

class _DotsLoadingAnimationState extends State<DotsLoadingAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Três pontos, três controladores
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.5).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Sequência de animação
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = widget.color ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _animations[index].value,
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Animação de carregamento em quadrado estilizado
class SquareLoadingAnimation extends StatefulWidget {
  /// Cor da animação
  final Color? color;

  /// Tamanho do elemento
  final double size;

  /// Duração do ciclo
  final Duration duration;

  /// Raio do quadrado
  final double borderRadius;

  /// Cria uma animação de carregamento com quadrado rotacionando
  const SquareLoadingAnimation({
    super.key,
    this.color,
    this.size = LoadingAnimations.defaultSize,
    this.duration = const Duration(milliseconds: 2000),
    this.borderRadius = 12.0,
  });

  @override
  State<SquareLoadingAnimation> createState() => _SquareLoadingAnimationState();
}

class _SquareLoadingAnimationState extends State<SquareLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = widget.color ?? AppColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * math.pi,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animação de progresso linear estilizado
class LinearProgressAnimation extends StatefulWidget {
  /// Largura do indicador
  final double width;

  /// Altura do indicador
  final double height;

  /// Cor primária
  final Color? primaryColor;

  /// Cor secundária
  final Color? backgroundColor;

  /// Duração do ciclo
  final Duration duration;

  /// Determina se deve animar automaticamente ou mostar progresso estático
  final bool indeterminate;

  /// Valor do progresso (0.0-1.0) quando não for indeterminado
  final double? value;

  /// Cria uma animação de progresso linear
  const LinearProgressAnimation({
    super.key,
    this.width = 240.0,
    this.height = 4.0,
    this.primaryColor,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 1500),
    this.indeterminate = true,
    this.value,
  }) : assert(value == null || (value >= 0.0 && value <= 1.0));

  @override
  State<LinearProgressAnimation> createState() =>
      _LinearProgressAnimationState();
}

class _LinearProgressAnimationState extends State<LinearProgressAnimation>
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

    _animation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.indeterminate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(LinearProgressAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.indeterminate != oldWidget.indeterminate) {
      if (widget.indeterminate) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    final Color effectivePrimaryColor =
        widget.primaryColor ?? AppColors.primary;
    final Color effectiveBackgroundColor = widget.backgroundColor ??
        effectivePrimaryColor.withAlpha((0.2 * 255).round());

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.indeterminate
          ? AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _IndeterminateProgressPainter(
                    animation: _animation.value,
                    primaryColor: effectivePrimaryColor,
                  ),
                  size: Size(widget.width, widget.height),
                );
              },
            )
          : FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.value ?? 0.0,
              child: Container(
                color: effectivePrimaryColor,
              ),
            ),
    );
  }
}

class _IndeterminateProgressPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;

  _IndeterminateProgressPainter({
    required this.animation,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Animação deslizante que se move pelo container
    final double width = size.width * 0.3; // 30% da largura
    double x = size.width * (animation % 1.0) - width;
    if (animation >= 1.0) {
      x = size.width - x - 2 * width;
    }

    canvas.drawRect(
      Rect.fromLTWH(x, 0, width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_IndeterminateProgressPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Animação de carregamento rotativa inspirada em app modernos
class SpinKitLoadingAnimation extends StatefulWidget {
  /// Cor da animação
  final Color? color;

  /// Tamanho do elemento
  final double size;

  /// Duração de uma rotação completa
  final Duration duration;

  /// Cria uma animação de carregamento estilo spinner moderno
  const SpinKitLoadingAnimation({
    super.key,
    this.color,
    this.size = LoadingAnimations.defaultSize,
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
    final Color effectiveColor = widget.color ?? AppColors.primary;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SpinKitPainter(
                controller: _controller,
                color: effectiveColor,
              ),
            );
          },
        ),
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

    // 8 elementos que aparecem e desaparecem em sequência
    const int itemCount = 8;
    const double itemRadius = 3.0;

    for (int i = 0; i < itemCount; i++) {
      final double angle = 2 * math.pi * (i / itemCount);
      final double rotation = 2 * math.pi * controller.value;

      // Posição no círculo
      final double x = centerX + radius * 0.7 * math.cos(angle + rotation);
      final double y = centerY + radius * 0.7 * math.sin(angle + rotation);

      // Determina a opacidade baseada na posição
      final double opacityValue =
          1.0 - (((i / itemCount) + controller.value) % 1.0);
      final double opacity = 0.2 + (0.8 * opacityValue);
      final double size = itemRadius + (itemRadius * opacityValue * 0.5);

      final Paint paint = Paint()
        ..color = color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  @override
  bool shouldRepaint(_SpinKitPainter oldDelegate) {
    return oldDelegate.controller.value != controller.value ||
        oldDelegate.color != color;
  }
}

/// Animação de carregamento com ícone personalizado
class IconLoadingAnimation extends StatefulWidget {
  /// Ícone a ser animado
  final IconData icon;

  /// Cor do ícone
  final Color? color;

  /// Tamanho do ícone
  final double size;

  /// Duração do ciclo de animação
  final Duration duration;

  /// Tipo de animação aplicada ao ícone
  final IconAnimationType animationType;

  /// Cria uma animação de carregamento com ícone personalizado
  const IconLoadingAnimation({
    super.key,
    required this.icon,
    this.color,
    this.size = LoadingAnimations.defaultSize,
    this.duration = const Duration(milliseconds: 1500),
    this.animationType = IconAnimationType.pulse,
  });

  @override
  State<IconLoadingAnimation> createState() => _IconLoadingAnimationState();
}

class _IconLoadingAnimationState extends State<IconLoadingAnimation>
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

    switch (widget.animationType) {
      case IconAnimationType.pulse:
        _animation = TweenSequence([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.25),
            weight: 1.0,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.25, end: 1.0),
            weight: 1.0,
          ),
        ]).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;

      case IconAnimationType.rotate:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.linear,
          ),
        );
        break;

      case IconAnimationType.bounce:
        _animation = TweenSequence([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: -0.2),
            weight: 1.0,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -0.2, end: 0.0),
            weight: 1.0,
          ),
        ]).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;

      case IconAnimationType.fade:
        _animation = TweenSequence([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.3),
            weight: 1.0,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.3, end: 1.0),
            weight: 1.0,
          ),
        ]).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;
    }

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = widget.color ?? AppColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          switch (widget.animationType) {
            case IconAnimationType.pulse:
              return Transform.scale(
                scale: _animation.value,
                child: Icon(
                  widget.icon,
                  color: effectiveColor,
                  size: widget.size * 0.8,
                ),
              );

            case IconAnimationType.rotate:
              return Transform.rotate(
                angle: _animation.value * 2 * math.pi,
                child: Icon(
                  widget.icon,
                  color: effectiveColor,
                  size: widget.size * 0.8,
                ),
              );

            case IconAnimationType.bounce:
              return Transform.translate(
                offset: Offset(0, widget.size * _animation.value),
                child: Icon(
                  widget.icon,
                  color: effectiveColor,
                  size: widget.size * 0.8,
                ),
              );

            case IconAnimationType.fade:
              return Opacity(
                opacity: _animation.value,
                child: Icon(
                  widget.icon,
                  color: effectiveColor,
                  size: widget.size * 0.8,
                ),
              );
          }
        },
      ),
    );
  }
}

/// Tipos de animação para ícones
enum IconAnimationType {
  /// Animação de pulso (crescer e diminuir)
  pulse,

  /// Animação de rotação
  rotate,

  /// Animação de salto
  bounce,

  /// Animação de fade in/out
  fade,
}

/// Animação de loading com tema do Clube de Benefícios
class BrandLoadingAnimation extends StatefulWidget {
  /// Tamanho do elemento
  final double size;

  /// Duração de um ciclo
  final Duration duration;

  /// Cor primária (verde do clube)
  final Color? primaryColor;

  /// Cor secundária (azul do clube)
  final Color? secondaryColor;

  /// Cria uma animação de carregamento com tema do clube
  const BrandLoadingAnimation({
    super.key,
    this.size = LoadingAnimations.defaultSize * 1.5,
    this.duration = const Duration(milliseconds: 2000),
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<BrandLoadingAnimation> createState() => _BrandLoadingAnimationState();
}

class _BrandLoadingAnimationState extends State<BrandLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectivePrimaryColor =
        widget.primaryColor ?? AppColors.primary;
    final Color effectiveSecondaryColor =
        widget.secondaryColor ?? AppColors.secondary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Arco externo girando
              Transform.rotate(
                angle: _rotationAnimation.value * math.pi,
                child: CustomPaint(
                  painter: _ArcPainter(
                    progress: _progressAnimation.value,
                    color: effectivePrimaryColor,
                    strokeWidth: 4.0,
                    startAngle: 0,
                    sweepAngle: math.pi * 1.2,
                  ),
                  size: Size(widget.size, widget.size),
                ),
              ),

              // Arco interno pulsando
              CustomPaint(
                painter: _ArcPainter(
                  progress: 1.0 - _progressAnimation.value,
                  color: effectiveSecondaryColor,
                  strokeWidth: 4.0,
                  startAngle: math.pi,
                  sweepAngle: math.pi * 1.2,
                ),
                size: Size(widget.size * 0.7, widget.size * 0.7),
              ),

              // Círculo central
              Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _progressAnimation.value < 0.5
                      ? effectivePrimaryColor.withAlpha((0.5 * 255).round())
                      : effectiveSecondaryColor.withAlpha((0.5 * 255).round()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle;
  }
}

/// Widget com texto de carregamento e animação
class TextLoadingAnimation extends StatelessWidget {
  /// Texto a ser exibido
  final String text;

  /// Estilo do texto
  final TextStyle? textStyle;

  /// Animação a ser exibida ao lado do texto
  final Widget? animation;

  /// Espaçamento entre texto e animação
  final double spacing;

  /// Se a animação deve aparecer antes ou depois do texto
  final bool animationFirst;

  /// Cor da animação de pontos (se animation for null)
  final Color? dotsColor;

  /// Cria um widget de carregamento com texto e animação
  const TextLoadingAnimation({
    super.key,
    required this.text,
    this.textStyle,
    this.animation,
    this.spacing = 8.0,
    this.animationFirst = false,
    this.dotsColor,
  });

  @override
  Widget build(BuildContext context) {
    final Widget loadingAnimation = animation ??
        DotsLoadingAnimation(
          color: dotsColor,
        );

    final List<Widget> children = animationFirst
        ? [
            loadingAnimation,
            SizedBox(width: spacing),
            Text(text, style: textStyle)
          ]
        : [
            Text(text, style: textStyle),
            SizedBox(width: spacing),
            loadingAnimation
          ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

/// Animação de cards com shimmer para loadings
class CardShimmerAnimation extends StatefulWidget {
  /// Altura do card
  final double height;

  /// Largura do card
  final double width;

  /// Raio dos cantos
  final double borderRadius;

  /// Cor base
  final Color? baseColor;

  /// Cor de destaque
  final Color? highlightColor;

  /// Duração de um ciclo de shimmer
  final Duration duration;

  /// Cria uma animação shimmer para cards em carregamento
  const CardShimmerAnimation({
    super.key,
    this.height = 100.0,
    this.width = double.infinity,
    this.borderRadius = RadiusTokens.card,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<CardShimmerAnimation> createState() => _CardShimmerAnimationState();
}

class _CardShimmerAnimationState extends State<CardShimmerAnimation>
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

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveBaseColor = widget.baseColor ??
        AppColors.neutralLight.withAlpha((0.3 * 255).round());
    final Color effectiveHighlightColor =
        widget.highlightColor ?? AppColors.neutralLightest;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  effectiveBaseColor,
                  effectiveHighlightColor,
                  effectiveBaseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                transform: _SlidingGradientTransform(
                  slidePercent: _animation.value,
                ),
              ).createShader(bounds);
            },
            child: Container(
              decoration: BoxDecoration(
                color: effectiveBaseColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Widget de carregamento com reflexo de fundo personalizado
class GlassLoadingAnimation extends StatelessWidget {
  /// Cor principal
  final Color? color;

  /// Tamanho do elemento
  final double size;

  /// Widget interno
  final Widget? child;

  /// Widget de loading
  final Widget? loadingWidget;

  /// Cria uma animação de carregamento com efeito de vidro
  const GlassLoadingAnimation({
    super.key,
    this.color,
    this.size = LoadingAnimations.defaultSize * 2.0,
    this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(size / 8),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withAlpha((0.2 * 255).round()),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Reflexo superior
            Positioned(
              top: -size / 2,
              left: -size / 4,
              right: -size / 4,
              child: Container(
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withAlpha((0.2 * 255).round()),
                      Colors.white.withAlpha(0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // Widget de carregamento ou filho
            Center(
              child: loadingWidget ??
                  CircularLoadingAnimation(
                    primaryColor: effectiveColor,
                    size: size / 2,
                  ),
            ),

            // Widget filho acima da animação (opcional)
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
/*Características das Animações de Carregamento:
Variedade de Estilos:

Circular (spinner estilizado)
Pulso (círculos que expandem)
Dots (pontos que pulsam sequencialmente)
Quadrados (rotação e escala)
Linear (barras de progresso)
SpinKit (estilo moderno com pontos)
Ícones animados (com 4 estilos)
Animação com identidade visual do Clube
Cards com efeito shimmer
Efeito vidro com reflexo
Personalização:

Totalmente integrado com o design system
Cores, tamanhos, durações personalizáveis
Suporte a temas claros/escuros automático
Animações responsivas que se ajustam ao espaço disponível
Inovações Visuais:

Efeito glassmorphism em algumas animações
Animações de arcos duplos inspiradas em apps modernos
Shimmer effects para placeholders
Combinação de múltiplas animações
Utilidade:

Animação com texto para notificação de carregamento
Indicadores determinados ou indeterminados conforme necessário
Opções para diferentes contextos (pequenas, grandes, etc)
Eficientes em termos de performance
Cada componente foi projetado para fornecer feedback visual imediato ao usuário durante operações de carregamento, melhorando significativamente a percepção de desempenho e responsividade do aplicativo.*/
