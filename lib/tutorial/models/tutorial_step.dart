/*### `tutorial_step.dart`

- **Parte do plano**: 3.1 (2) - Modelo de Passo do Tutorial
- **Conteúdo**: Define a classe `TutorialStep` com propriedades como `globalKey`, `title`, `description`, `position` e `customWidget`.*/
import 'package:flutter/material.dart';

/// Posições possíveis para exibir a tooltip em relação ao elemento destacado
enum TutorialPosition {
  top,
  bottom,
  left,
  right,
  auto,
}

/// Define um passo do tutorial interativo
class TutorialStep {
  /// Chave global do widget que será destacado
  final GlobalKey targetKey;

  /// Título da dica
  final String title;

  /// Descrição detalhada
  final String description;

  /// Posição onde a tooltip será exibida
  final TutorialPosition position;

  /// Widget customizado para casos especiais (opcional)
  final Widget? customWidget;

  /// Tamanho do destaque (opcional, padrão é definido automaticamente)
  final Size? spotlightSize;

  /// Forma do destaque (opcional, padrão é circular)
  final ShapeBorder? spotlightShape;

  /// Margem adicional ao redor do elemento destacado
  final EdgeInsets spotlightPadding;

  /// Se o passo pode ser pulado pelo usuário
  final bool canSkip;

  /// Se este é o último passo do tutorial
  final bool isLastStep;

  /// Ação personalizada ao clicar no elemento destacado (opcional)
  final VoidCallback? onTargetClick;

  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.position = TutorialPosition.auto,
    this.customWidget,
    this.spotlightSize,
    this.spotlightShape,
    this.spotlightPadding = const EdgeInsets.all(8.0),
    this.canSkip = true,
    this.onTargetClick,
    this.isLastStep = false,
  });

  /// Cria uma cópia deste passo com algumas propriedades modificadas
  TutorialStep copyWith({
    GlobalKey? targetKey,
    String? title,
    String? description,
    TutorialPosition? position,
    Widget? customWidget,
    Size? spotlightSize,
    ShapeBorder? spotlightShape,
    EdgeInsets? spotlightPadding,
    bool? canSkip,
    bool? isLastStep,
    VoidCallback? onTargetClick,
  }) {
    return TutorialStep(
      targetKey: targetKey ?? this.targetKey,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
      customWidget: customWidget ?? this.customWidget,
      spotlightSize: spotlightSize ?? this.spotlightSize,
      spotlightShape: spotlightShape ?? this.spotlightShape,
      spotlightPadding: spotlightPadding ?? this.spotlightPadding,
      canSkip: canSkip ?? this.canSkip,
      isLastStep: isLastStep ?? this.isLastStep,
      onTargetClick: onTargetClick ?? this.onTargetClick,
    );
  }

  /// Obtém a posição do widget alvo na tela
  Rect? getTargetPosition(BuildContext context) {
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.hasSize) {
      return null;
    }

    final Size size = spotlightSize ?? renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    // Aplica o padding ao retângulo
    return Rect.fromLTWH(
      offset.dx - spotlightPadding.left,
      offset.dy - spotlightPadding.top,
      size.width + spotlightPadding.left + spotlightPadding.right,
      size.height + spotlightPadding.top + spotlightPadding.bottom,
    );
  }

  /// Determina a melhor posição para a tooltip com base no espaço disponível
  TutorialPosition getBestPosition(BuildContext context, Rect targetRect) {
    if (position != TutorialPosition.auto) {
      return position;
    }

    final Size screenSize = MediaQuery.of(context).size;
    final double topSpace = targetRect.top;
    final double bottomSpace = screenSize.height - targetRect.bottom;
    final double leftSpace = targetRect.left;
    final double rightSpace = screenSize.width - targetRect.right;

    // Encontra o espaço maior disponível
    final Map<TutorialPosition, double> spaces = {
      TutorialPosition.top: topSpace,
      TutorialPosition.bottom: bottomSpace,
      TutorialPosition.left: leftSpace,
      TutorialPosition.right: rightSpace,
    };

    // Retorna a posição com mais espaço disponível
    return spaces.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
/*Características e Funcionalidades
O modelo TutorialStep que acabei de criar tem várias características importantes:

Flexibilidade de Posicionamento:

Define um enum TutorialPosition para controlar onde a tooltip aparece
Inclui uma opção auto que calcula automaticamente a melhor posição
Personalização Visual:

Permite definir tamanho personalizado para o destaque
Suporta formas personalizadas (círculo, retângulo, etc.)
Permite adicionar padding ao redor do elemento destacado
Funcionalidades Avançadas:

Suporte a widgets personalizados para casos especiais
Opção para permitir ou não que o usuário pule um passo
Callback para quando o usuário clica no elemento destacado
Utilitários:

Método getTargetPosition() para obter a posição exata do elemento na tela
Método getBestPosition() para calcular automaticamente onde colocar a tooltip
Padrão copyWith() para facilitar a criação de variações de um passo
Este modelo servirá como a base para todo o sistema de tutorial, definindo exatamente o que será mostrado em cada passo, como será exibido e quais interações serão possíveis.*/
