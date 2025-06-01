import 'package:flutter/material.dart';

/// Define os tokens primitivos de sombras do sistema de design
///
/// Estabelece sombras consistentes para criar hierarquia visual,
/// profundidade e elevação em componentes da interface.
class ShadowTokens {
  // Valores básicos de sombras, inspirados no Material Design
  // mas adaptados para o sistema visual do Clube de Benefícios

  /// Sem sombra - para elementos no nível base da superfície
  static const List<BoxShadow> none = [];

  /// Sombra mínima - sutil indicação de elevação (1dp)
  /// Ideal para separação sutil de elementos como cards em listas
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0D000000), // 5% de opacidade
      blurRadius: 1.0,
      offset: Offset(0, 1),
    ),
  ];

  /// Sombra pequena - elevação leve (2dp)
  /// Para cards, barras inferiores e elementos levemente elevados
  static const List<BoxShadow> s = [
    BoxShadow(
      color: Color(0x1A000000), // 10% de opacidade
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  /// Sombra média - elevação moderada (4dp)
  /// Para componentes interativos, cards destacados
  static const List<BoxShadow> m = [
    BoxShadow(
      color: Color(0x24000000), // 14% de opacidade
      blurRadius: 4.0,
      offset: Offset(0, 2),
    ),
  ];

  /// Sombra grande - elevação significativa (8dp)
  /// Para elementos flutuantes, modais, drawers
  static const List<BoxShadow> l = [
    BoxShadow(
      color: Color(0x29000000), // 16% de opacidade
      blurRadius: 8.0,
      offset: Offset(0, 4),
    ),
  ];

  /// Sombra extra-grande - elevação máxima (16dp)
  /// Para diálogos, popovers e elementos de nível superior
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x33000000), // 20% de opacidade
      blurRadius: 16.0,
      offset: Offset(0, 8),
    ),
  ];

  /// Sombra para botões em estado normal
  static const List<BoxShadow> button = s;

  /// Sombra para botões em estado pressionado
  static const List<BoxShadow> buttonPressed = xs;

  /// Sombra para cards padrão
  static const List<BoxShadow> card = s;

  /// Sombra para cards em destaque
  static const List<BoxShadow> cardHighlighted = m;

  /// Sombra para elementos flutuantes (FABs)
  static const List<BoxShadow> floatingAction = l;

  /// Sombra para modais e diálogos
  static const List<BoxShadow> modal = l;

  /// Sombra para drawers laterais
  static const List<BoxShadow> drawer = xl;

  /// Sombra para menus dropdown
  static const List<BoxShadow> dropdown = m;

  /// Sombra para navegação inferior
  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x29000000), // 16% de opacidade
      blurRadius: 8.0,
      offset: Offset(0, -4), // Sombra invertida (superior)
    ),
  ];

  /// Cria uma sombra personalizada com base nos parâmetros fornecidos
  ///
  /// Permite customização controlada enquanto mantém consistência visual
  static List<BoxShadow> custom({
    double opacity = 0.2,
    double blurRadius = 4.0,
    double spreadRadius = 0.0,
    Offset offset = const Offset(0, 2),
  }) {
    // Garantimos que a opacidade esteja no intervalo correto (0-1)
    final safeOpacity = opacity.clamp(0.0, 1.0);
    // Convertemos a opacidade para um valor de alfa hexadecimal
    final alpha = (safeOpacity * 255).round();
    final alphaHex = alpha.toRadixString(16).padLeft(2, '0');

    return [
      BoxShadow(
        color: Color(int.parse('${alphaHex}000000', radix: 16)),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }

  /// Retorna parâmetros para utilizar com o widget InnerShadow
  ///
  /// Como o Flutter não suporta sombras internas nativamente,
  /// esta função retorna os parâmetros para usar com o widget personalizado InnerShadow
  static Map<String, dynamic> innerShadow({
    Color color = const Color(0x29000000),
    double blurRadius = 4.0,
    Offset offset = const Offset(0, 1),
  }) {
    return {
      'color': color,
      'blurRadius': blurRadius,
      'offset': offset,
    };
  }
}
