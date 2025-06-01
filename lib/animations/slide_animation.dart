import 'package:flutter/material.dart';

/// Implementa animações de deslizamento (slide) para entrada e saída de widgets
///
/// Oferece animações de deslizamento padronizadas em diferentes direções,
/// úteis para transições entre telas e entrada/saída de elementos na interface.
class SlideAnimation extends StatefulWidget {
  /// Widget filho que receberá a animação
  final Widget child;

  /// Duração da animação
  final Duration duration;

  /// Atraso antes de iniciar a animação
  final Duration delay;

  /// Posição inicial do slide em offset
  final Offset beginOffset;

  /// Posição final do slide em offset
  final Offset endOffset;

  /// Curva de animação a ser aplicada
  final Curve curve;

  /// Se verdadeiro, anima automaticamente quando o widget é construído
  final bool autoPlay;

  /// Função chamada quando a animação é concluída
  final VoidCallback? onComplete;

  /// Cria uma animação de deslizamento com controle total dos parâmetros
  const SlideAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    required this.beginOffset,
    this.endOffset = const Offset(0.0, 0.0),
    this.curve = Curves.easeInOut,
    this.autoPlay = true,
    this.onComplete,
  }) : super(key: key);

  /// Cria uma animação de entrada deslizando da direita
  SlideAnimation.fromRight({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          beginOffset: Offset(distance, 0.0),
          endOffset: const Offset(0.0, 0.0),
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de entrada deslizando da esquerda
  SlideAnimation.fromLeft({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          beginOffset: Offset(-distance, 0.0),
          endOffset: const Offset(0.0, 0.0),
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de entrada deslizando de cima
  SlideAnimation.fromTop({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          beginOffset: Offset(0.0, -distance),
          endOffset: const Offset(0.0, 0.0),
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de entrada deslizando de baixo
  SlideAnimation.fromBottom({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          beginOffset: Offset(0.0, distance),
          endOffset: const Offset(0.0, 0.0),
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de saída deslizando para a direita
  SlideAnimation.toRight({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          beginOffset: const Offset(0.0, 0.0),
          endOffset: Offset(distance, 0.0),
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de saída deslizando para a esquerda
  SlideAnimation.toLeft({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          beginOffset: const Offset(0.0, 0.0),
          endOffset: Offset(-distance, 0.0),
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: widget.endOffset,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) => FractionalTranslation(
        translation: _slideAnimation.value,
        child: widget.child,
      ),
    );
  }
}

/// Extensões para facilitar o uso de SlideAnimation em qualquer widget
extension SlideAnimationExtension on Widget {
  /// Desliza o widget da direita para a posição atual
  Widget slideFromRight({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) {
    return SlideAnimation.fromRight(
      key: key,
      duration: duration,
      delay: delay,
      distance: distance,
      curve: curve,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Desliza o widget da esquerda para a posição atual
  Widget slideFromLeft({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) {
    return SlideAnimation.fromLeft(
      key: key,
      duration: duration,
      delay: delay,
      distance: distance,
      curve: curve,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Desliza o widget de cima para a posição atual
  Widget slideFromTop({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) {
    return SlideAnimation.fromTop(
      key: key,
      duration: duration,
      delay: delay,
      distance: distance,
      curve: curve,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Desliza o widget de baixo para a posição atual
  Widget slideFromBottom({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    double distance = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) {
    return SlideAnimation.fromBottom(
      key: key,
      duration: duration,
      delay: delay,
      distance: distance,
      curve: curve,
      onComplete: onComplete,
      child: this,
    );
  }
}
