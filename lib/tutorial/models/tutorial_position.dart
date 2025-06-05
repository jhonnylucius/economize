/* tutorial_position.dart
**Parte do plano: 3.1 (2) - Modelo de Passo do Tutorial
**Conteúdo: Enum e helpers para posicionamento de tooltips (TOP, BOTTOM, LEFT, RIGHT).*/
import 'package:economize/tutorial/models/tutorial_step.dart';
import 'package:flutter/material.dart';

/// Constantes usadas para posicionamento de tooltips
class TutorialPositionConstants {
  /// Distância padrão entre o elemento destacado e a tooltip
  static const double defaultTooltipMargin = 20.0;

  /// Margem mínima das bordas da tela
  static const double screenEdgeMargin = 16.0;

  /// Tamanho padrão para a seta da tooltip
  static const double arrowSize = 10.0;

  /// Não permitir instanciar esta classe
  TutorialPositionConstants._();
}

/// Extensão para facilitar o trabalho com o enum TutorialPosition
extension TutorialPositionExtension on TutorialPosition {
  /// Verifica se a posição é horizontal (esquerda ou direita)
  bool get isHorizontal =>
      this == TutorialPosition.left || this == TutorialPosition.right;

  /// Verifica se a posição é vertical (topo ou baixo)
  bool get isVertical =>
      this == TutorialPosition.top || this == TutorialPosition.bottom;

  /// Obtém a posição oposta (útil para fallback)
  TutorialPosition get opposite {
    switch (this) {
      case TutorialPosition.top:
        return TutorialPosition.bottom;
      case TutorialPosition.bottom:
        return TutorialPosition.top;
      case TutorialPosition.left:
        return TutorialPosition.right;
      case TutorialPosition.right:
        return TutorialPosition.left;
      case TutorialPosition.auto:
        return TutorialPosition.auto;
    }
  }

  /// Converte a posição para um nome legível
  String get displayName {
    switch (this) {
      case TutorialPosition.top:
        return 'Topo';
      case TutorialPosition.bottom:
        return 'Baixo';
      case TutorialPosition.left:
        return 'Esquerda';
      case TutorialPosition.right:
        return 'Direita';
      case TutorialPosition.auto:
        return 'Automático';
    }
  }
}

/// Classe para calcular posições precisas para tooltips
class TutorialPositionCalculator {
  /// Calcula a posição da tooltip com base no elemento destacado
  static Offset calculateTooltipPosition({
    required Rect targetRect,
    required Size tooltipSize,
    required TutorialPosition position,
    required Size screenSize,
    double margin = TutorialPositionConstants.defaultTooltipMargin,
  }) {
    // Posição inicial baseada na posição solicitada
    Offset initialPosition;

    switch (position) {
      case TutorialPosition.top:
        initialPosition = Offset(
          targetRect.center.dx - (tooltipSize.width / 2),
          targetRect.top - tooltipSize.height - margin,
        );
        break;
      case TutorialPosition.bottom:
        initialPosition = Offset(
          targetRect.center.dx - (tooltipSize.width / 2),
          targetRect.bottom + margin,
        );
        break;
      case TutorialPosition.left:
        initialPosition = Offset(
          targetRect.left - tooltipSize.width - margin,
          targetRect.center.dy - (tooltipSize.height / 2),
        );
        break;
      case TutorialPosition.right:
        initialPosition = Offset(
          targetRect.right + margin,
          targetRect.center.dy - (tooltipSize.height / 2),
        );
        break;
      case TutorialPosition.auto:
        // Este caso não deve ocorrer aqui - a posição deve ser resolvida antes
        return Offset.zero;
    }

    // Ajustar para não sair da tela
    return _constrainToScreen(initialPosition, tooltipSize, screenSize);
  }

  /// Verifica se a tooltip ficaria fora da tela e ajusta se necessário
  static Offset _constrainToScreen(
      Offset position, Size tooltipSize, Size screenSize) {
    final double margin = TutorialPositionConstants.screenEdgeMargin;

    // Limites horizontais
    double x = position.dx;
    if (x < margin) {
      x = margin;
    } else if (x + tooltipSize.width > screenSize.width - margin) {
      x = screenSize.width - tooltipSize.width - margin;
    }

    // Limites verticais
    double y = position.dy;
    if (y < margin) {
      y = margin;
    } else if (y + tooltipSize.height > screenSize.height - margin) {
      y = screenSize.height - tooltipSize.height - margin;
    }

    return Offset(x, y);
  }

  /// Determina a posição da seta da tooltip
  static Offset calculateArrowPosition({
    required Rect targetRect,
    required Offset tooltipPosition,
    required Size tooltipSize,
    required TutorialPosition position,
  }) {
    switch (position) {
      case TutorialPosition.top:
        return Offset(
          targetRect.center.dx - tooltipPosition.dx,
          tooltipSize.height,
        );
      case TutorialPosition.bottom:
        return Offset(
          targetRect.center.dx - tooltipPosition.dx,
          0,
        );
      case TutorialPosition.left:
        return Offset(
          tooltipSize.width,
          targetRect.center.dy - tooltipPosition.dy,
        );
      case TutorialPosition.right:
        return Offset(
          0,
          targetRect.center.dy - tooltipPosition.dy,
        );
      case TutorialPosition.auto:
        return Offset.zero;
    }
  }

  /// Calcula a melhor posição para a tooltip baseada no espaço disponível
  static TutorialPosition calculateOptimalPosition(
    Rect targetRect,
    Size tooltipSize,
    Size screenSize,
  ) {
    // Calcula o espaço disponível em cada direção
    final double topSpace = targetRect.top;
    final double bottomSpace = screenSize.height - targetRect.bottom;
    final double leftSpace = targetRect.left;
    final double rightSpace = screenSize.width - targetRect.right;

    // Verifica se há espaço suficiente em cada direção
    final bool hasTopSpace = topSpace >=
        tooltipSize.height + TutorialPositionConstants.defaultTooltipMargin;
    final bool hasBottomSpace = bottomSpace >=
        tooltipSize.height + TutorialPositionConstants.defaultTooltipMargin;
    final bool hasLeftSpace = leftSpace >=
        tooltipSize.width + TutorialPositionConstants.defaultTooltipMargin;
    final bool hasRightSpace = rightSpace >=
        tooltipSize.width + TutorialPositionConstants.defaultTooltipMargin;

    // Prioriza espaços maiores
    final Map<TutorialPosition, double> availableSpaces = {
      if (hasTopSpace) TutorialPosition.top: topSpace,
      if (hasBottomSpace) TutorialPosition.bottom: bottomSpace,
      if (hasLeftSpace) TutorialPosition.left: leftSpace,
      if (hasRightSpace) TutorialPosition.right: rightSpace,
    };

    // Se não houver espaço em nenhuma direção, usa a posição com mais espaço
    if (availableSpaces.isEmpty) {
      final Map<TutorialPosition, double> allSpaces = {
        TutorialPosition.top: topSpace,
        TutorialPosition.bottom: bottomSpace,
        TutorialPosition.left: leftSpace,
        TutorialPosition.right: rightSpace,
      };
      return allSpaces.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Retorna a posição com mais espaço disponível
    return availableSpaces.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
/*Características e Funcionalidades
Este arquivo tutorial_position.dart complementa o nosso tutorial_step.dart adicionando:

1. Constantes de Posicionamento
Define valores padrão para margens, distâncias e tamanho da seta
Ajuda a manter consistência visual em todo o tutorial
2. Extensão para o Enum TutorialPosition
Adiciona propriedades úteis como isHorizontal e isVertical
Implementa opposite para encontrar a direção contrária
Fornece nomes amigáveis para cada posição
3. Calculadora de Posicionamento
calculateTooltipPosition: determina exatamente onde colocar a tooltip
calculateArrowPosition: posiciona corretamente a seta da tooltip
calculateOptimalPosition: escolhe automaticamente a melhor posição
4. Segurança de Limites
Função _constrainToScreen garante que tooltips nunca fiquem fora da tela
Adiciona margens automáticas para evitar que o conteúdo toque as bordas
Essa implementação oferece posicionamento inteligente e adaptativo para as tooltips do nosso tutorial, funcionando bem mesmo em diferentes tamanhos de tela e orientações.*/
