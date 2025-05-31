import 'package:flutter/material.dart';

/// Implementa animações de escala para widgets
///
/// Fornece widgets e extensões para aplicar efeitos de escala (crescimento/diminuição)
/// de forma padronizada, útil para destacar elementos ou indicar interatividade.
class ScaleAnimation extends StatefulWidget {
  /// Widget filho que receberá a animação
  final Widget child;

  /// Duração da animação
  final Duration duration;

  /// Atraso antes de iniciar a animação
  final Duration delay;

  /// Escala inicial (1.0 é o tamanho normal)
  final double fromScale;

  /// Escala final (1.0 é o tamanho normal)
  final double toScale;

  /// Curva de animação a ser aplicada
  final Curve curve;

  /// Alinhamento da animação de escala (a partir de qual ponto o widget cresce/diminui)
  final Alignment alignment;

  /// Se verdadeiro, anima automaticamente quando o widget é construído
  final bool autoPlay;

  /// Função chamada quando a animação é concluída
  final VoidCallback? onComplete;

  /// Cria uma animação de escala customizada
  const ScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.fromScale = 0.0,
    this.toScale = 1.0,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.autoPlay = true,
    this.onComplete,
  });

  /// Cria uma animação de crescimento a partir de um ponto
  const ScaleAnimation.grow({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double fromScale = 0.0,
    Curve curve = Curves.easeOutBack,
    Alignment alignment = Alignment.center,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          fromScale: fromScale,
          toScale: 1.0,
          curve: curve,
          alignment: alignment,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de diminuição até desaparecer
  const ScaleAnimation.shrink({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double toScale = 0.0,
    Curve curve = Curves.easeInBack,
    Alignment alignment = Alignment.center,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          fromScale: 1.0,
          toScale: toScale,
          curve: curve,
          alignment: alignment,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de pulso (cresce ligeiramente e volta ao normal)
  const ScaleAnimation.pulse({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.elasticInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          fromScale: 1.0,
          toScale: 1.1,
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de aparecimento com bounce (elasticidade)
  const ScaleAnimation.bounceIn({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Alignment alignment = Alignment.center,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          fromScale: 0.3,
          toScale: 1.0,
          curve: Curves.elasticOut,
          alignment: alignment,
          autoPlay: true,
          onComplete: onComplete,
        );

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
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

    _scaleAnimation = Tween<double>(
      begin: widget.fromScale,
      end: widget.toScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Adiciona listener para chamar onComplete quando a animação terminar
    if (widget.onComplete != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete!();
        }
      });
    }

    // Inicia a animação automaticamente após o delay, se autoPlay for verdadeiro
    if (widget.autoPlay) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  /// Inicia a animação manualmente (útil quando autoPlay é falso)
  void play() {
    _controller.forward();
  }

  /// Reverte a animação para o estado inicial
  void reverse() {
    _controller.reverse();
  }

  /// Reinicia a animação do início
  void reset() {
    _controller.reset();
    _controller.forward();
  }

  /// Cria um efeito de pulsação contínua
  void pulseContinuously() {
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        alignment: widget.alignment,
        child: widget.child,
      ),
    );
  }
}

/// Extensões para facilitar o uso de ScaleAnimation em qualquer widget
extension ScaleAnimationExtension on Widget {
  /// Aplica uma animação de crescimento ao widget
  Widget scaleIn({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double fromScale = 0.0,
    Curve curve = Curves.easeOutBack,
    Alignment alignment = Alignment.center,
    VoidCallback? onComplete,
  }) {
    return ScaleAnimation.grow(
      key: key,
      duration: duration,
      delay: delay,
      fromScale: fromScale,
      curve: curve,
      alignment: alignment,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Aplica uma animação de diminuição ao widget
  Widget scaleOut({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double toScale = 0.0,
    Curve curve = Curves.easeInBack,
    Alignment alignment = Alignment.center,
    VoidCallback? onComplete,
  }) {
    return ScaleAnimation.shrink(
      key: key,
      duration: duration,
      delay: delay,
      toScale: toScale,
      curve: curve,
      alignment: alignment,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Aplica uma animação de pulso ao widget
  Widget pulse({
    Key? key,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.elasticInOut,
    VoidCallback? onComplete,
  }) {
    return ScaleAnimation.pulse(
      key: key,
      duration: duration,
      curve: curve,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Aplica um efeito de entrada com elasticidade ao widget
  Widget bounceIn({
    Key? key,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Alignment alignment = Alignment.center,
    VoidCallback? onComplete,
  }) {
    return ScaleAnimation.bounceIn(
      key: key,
      duration: duration,
      delay: delay,
      alignment: alignment,
      onComplete: onComplete,
      child: this,
    );
  }
}
