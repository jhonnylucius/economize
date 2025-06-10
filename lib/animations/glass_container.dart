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

  /// Se true, usa efeito fosco (melhor legibilidade)
  /// Se false, usa efeito translúcido original
  final bool frostedEffect;

  /// Construtor do container com efeito de vidro
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.opacity = 0.40,
    this.blur = 10,
    this.borderColor,
    this.borderWidth = 1.5,
    this.frostedEffect = false, // ✅ NOVO PARÂMETRO
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ EFEITO FOSCO/JATEADO (melhor legibilidade)
    if (frostedEffect) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
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
            // 🎯 VIDRO FOSCO: Fundo mais opaco + gradiente sutil
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // Cor base mais opaca para legibilidade
                theme.colorScheme.surface.withAlpha((0.85 * 255).round()),
                theme.colorScheme.surface.withAlpha((0.75 * 255).round()),
              ],
            ),
            // ✨ EFEITO JATEADO: Sombra interna sutil
            boxShadow: [
              BoxShadow(
                color: Colors.white.withAlpha((0.1 * 255).round()),
                offset: const Offset(0, 1),
                blurRadius: 0,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).round()),
                offset: const Offset(0, -1),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            // 🔍 TEXTURA FOSCA: Overlay com ruído sutil
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha((0.1 * 255).round()),
                  Colors.transparent,
                  Colors.black.withAlpha((0.05 * 255).round()),
                ],
              ),
            ),
            child: child,
          ),
        ),
      );
    }

    // 🔄 EFEITO TRANSLÚCIDO ORIGINAL (mantém compatibilidade)
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
                        const Color.fromARGB(255, 245, 0, 135)
                            .withAlpha((0.35 * 255).round()),
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
