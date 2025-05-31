import 'package:flutter/material.dart';

/// Implementa animações de fade (aparecimento/desaparecimento) para widgets
///
/// Fornece widgets e extensões para aplicar efeitos de fade de forma padronizada,
/// garantindo consistência nas animações de entrada e saída de elementos.
class FadeAnimation extends StatefulWidget {
  /// Widget filho que receberá a animação
  final Widget child;

  /// Duração da animação
  final Duration duration;

  /// Atraso antes de iniciar a animação
  final Duration delay;

  /// Valor inicial de opacidade (0.0 a 1.0)
  final double fromOpacity;

  /// Valor final de opacidade (0.0 a 1.0)
  final double toOpacity;

  /// Curva de animação a ser aplicada
  final Curve curve;

  /// Se verdadeiro, anima automaticamente quando o widget é construído
  final bool autoPlay;

  /// Função chamada quando a animação é concluída
  final VoidCallback? onComplete;

  /// Cria uma animação de fade para o widget filho
  const FadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.fromOpacity = 0.0,
    this.toOpacity = 1.0,
    this.curve = Curves.easeInOut,
    this.autoPlay = true,
    this.onComplete,
  });

  /// Cria uma animação de fade-in rápida (aparecimento)
  const FadeAnimation.fadeIn({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          fromOpacity: 0.0,
          toOpacity: 1.0,
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação de fade-out rápida (desaparecimento)
  const FadeAnimation.fadeOut({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          fromOpacity: 1.0,
          toOpacity: 0.0,
          curve: curve,
          autoPlay: true,
          onComplete: onComplete,
        );

  /// Cria uma animação que pulsa entre opacidades (efeito de respiração)
  const FadeAnimation.pulse({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    Curve curve = Curves.easeInOut,
  }) : this(
          key: key,
          child: child,
          duration: duration,
          fromOpacity: 0.6,
          toOpacity: 1.0,
          curve: curve,
          autoPlay: true,
        );

  @override
  State<FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(
      begin: widget.fromOpacity,
      end: widget.toOpacity,
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
      animation: _opacityAnimation,
      builder: (context, child) => Opacity(
        opacity: _opacityAnimation.value,
        child: widget.child,
      ),
    );
  }
}

/// Extensões para facilitar o uso de FadeAnimation em qualquer widget
extension FadeAnimationExtension on Widget {
  /// Envolve o widget em uma animação de fade in (aparecimento)
  Widget fadeIn({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) {
    return FadeAnimation.fadeIn(
      key: key,
      duration: duration,
      delay: delay,
      curve: curve,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Envolve o widget em uma animação de fade out (desaparecimento)
  Widget fadeOut({
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeInOut,
    VoidCallback? onComplete,
  }) {
    return FadeAnimation.fadeOut(
      key: key,
      duration: duration,
      delay: delay,
      curve: curve,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Envolve o widget em uma animação de pulso (respiração)
  Widget pulse({
    Key? key,
    Duration duration = const Duration(milliseconds: 1000),
    Curve curve = Curves.easeInOut,
  }) {
    return FadeAnimation.pulse(
      key: key,
      duration: duration,
      curve: curve,
      child: this,
    );
  }
}
