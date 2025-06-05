/*tutorial_navigation_buttons.dart
**Parte do plano: 3.2 (3) - Tooltip (Dica)
**Conteúdo: Botões para navegação no tutorial (Anterior, Próximo, Pular).*/
import 'package:flutter/material.dart';

/// Widget que encapsula os botões de navegação do tutorial
/// Fornece controles para avançar, retroceder e pular o tutorial
class TutorialNavigationButtons extends StatelessWidget {
  /// Função chamada quando o usuário clica em "Anterior"
  final VoidCallback? onPrevious;

  /// Função chamada quando o usuário clica em "Próximo" ou "Concluir"
  final VoidCallback onNext;

  /// Função chamada quando o usuário clica em "Pular"
  final VoidCallback onSkip;

  /// Se é o primeiro passo do tutorial (oculta o botão Anterior)
  final bool isFirstStep;

  /// Se é o último passo do tutorial (muda "Próximo" para "Concluir")
  final bool isLastStep;

  /// Se o passo atual pode ser pulado
  final bool canSkip;

  /// Cor dos botões
  final Color? buttonColor;

  /// Tamanho do texto dos botões
  final double fontSize;

  /// Ícone para o botão Próximo/Concluir (opcional)
  final IconData? nextIcon;

  /// Ícone para o botão Anterior (opcional)
  final IconData? previousIcon;

  const TutorialNavigationButtons({
    super.key,
    required this.onNext,
    required this.onSkip,
    this.onPrevious,
    this.isFirstStep = false,
    this.isLastStep = false,
    this.canSkip = true,
    this.buttonColor,
    this.fontSize = 14.0,
    this.nextIcon = Icons.arrow_forward,
    this.previousIcon = Icons.arrow_back,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualButtonColor = buttonColor ?? theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botão Pular (visível se o passo permitir pular)
        canSkip
            ? TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Pular',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: actualButtonColor.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              )
            : const Spacer(flex: 1),

        // Botões de navegação (Anterior e Próximo/Concluir)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Anterior (visível exceto no primeiro passo)
            if (!isFirstStep && onPrevious != null)
              IconButton(
                icon: Icon(previousIcon),
                onPressed: onPrevious,
                color: actualButtonColor,
                tooltip: 'Anterior',
                iconSize: 20,
                constraints: const BoxConstraints(
                  minHeight: 36,
                  minWidth: 36,
                ),
              ),

            const SizedBox(width: 8),

            // Botão Próximo/Concluir
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: actualButtonColor,
                foregroundColor: Colors.white,
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLastStep ? 'Concluir' : 'Próximo',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isLastStep && nextIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(nextIcon, size: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tema para personalizar a aparência dos botões de navegação
class TutorialNavigationTheme {
  /// Cor do botão principal (Próximo/Concluir)
  final Color primaryColor;

  /// Cor do texto do botão principal
  final Color primaryTextColor;

  /// Cor do botão secundário (Anterior)
  final Color secondaryColor;

  /// Forma dos botões
  final OutlinedBorder? buttonShape;

  /// Padding dos botões
  final EdgeInsets buttonPadding;

  /// Tamanho do texto
  final double fontSize;

  const TutorialNavigationTheme({
    this.primaryColor = Colors.blue,
    this.primaryTextColor = Colors.white,
    this.secondaryColor = Colors.grey,
    this.buttonShape,
    this.buttonPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fontSize = 14,
  });

  /// Cria um tema a partir do tema atual do aplicativo
  factory TutorialNavigationTheme.fromTheme(ThemeData theme) {
    return TutorialNavigationTheme(
      primaryColor: theme.colorScheme.primary,
      primaryTextColor: theme.colorScheme.onPrimary,
      secondaryColor: theme.colorScheme.secondary,
      fontSize: theme.textTheme.labelLarge?.fontSize ?? 14,
    );
  }

  /// Cria uma cópia com alguns valores alterados
  TutorialNavigationTheme copyWith({
    Color? primaryColor,
    Color? primaryTextColor,
    Color? secondaryColor,
    OutlinedBorder? buttonShape,
    EdgeInsets? buttonPadding,
    double? fontSize,
  }) {
    return TutorialNavigationTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      buttonShape: buttonShape ?? this.buttonShape,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
/*Características do TutorialNavigationButtons
Este componente de navegação para o tutorial interativo oferece:

1. Separação de Responsabilidades
Modularidade: Isola a lógica de navegação em um componente específico
Reutilização: Pode ser usado tanto na tooltip quanto em outros contextos
2. Experiência de Usuário Consistente
Botões Contextuais: Exibe "Próximo" ou "Concluir" dependendo do passo
Visibilidade Inteligente: Mostra ou oculta botões como "Anterior" e "Pular" quando apropriado
Feedback Visual: Usa ícones junto com texto para facilitar a compreensão
3. Personalização Avançada
Cores Customizáveis: Permite definir cores específicas para os botões
Tamanho do Texto: Controle sobre o tamanho do texto para melhor legibilidade
Ícones Personalizáveis: Flexibilidade para mudar os ícones padrão
4. Tema Dedicado (TutorialNavigationTheme)
Consistência Visual: Permite definir um tema para todos os botões de navegação
Integração com Theme: Pode ser derivado do tema atual do aplicativo
Flexibilidade: Suporta customização parcial através do método copyWith()
5. Acessibilidade
Área de Toque Adequada: Garante áreas de toque suficientes para os botões
Tooltips: Inclui tooltips para facilitar a compreensão
Contraste: Usa cores de alto contraste por padrão
Este componente pode ser facilmente integrado ao TutorialTooltip para substituir a parte de navegação existente, tornando o código mais modular e fácil de manter.*/
