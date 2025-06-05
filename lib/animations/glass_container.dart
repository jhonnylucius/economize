import 'dart:ui';
import 'package:flutter/material.dart';

/// Um container com efeito de vidro (glassmorphism)
class GlassContainer extends StatelessWidget {
  /// Conteúdo do container
  final Widget child;

  /// Raio do arredondamento das bordas
  final double borderRadius;

  /// Opacidade do efeito de blur (0.0 - 1.0)
  final double opacity;

  /// Intensidade do efeito de blur
  final double blur;

  /// Cor da borda (opcional)
  final Color? borderColor;

  /// Espessura da borda (0 para sem borda)
  final double borderWidth;

  /// Construtor do container com efeito de vidro
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.opacity = 0.30,
    this.blur = 10,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: borderWidth > 0
                ? Border.all(
                    width: borderWidth,
                    color: borderColor ??
                        Colors.white.withAlpha((0.3 * 255).round()),
                  )
                : null,
            color: theme.colorScheme.surface.withAlpha((0.30 * 255).round()),
          ),
          child: child,
        ),
      ),
    );
  }
}
