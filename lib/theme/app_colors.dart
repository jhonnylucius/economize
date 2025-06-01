import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';

/// Define as cores semânticas utilizadas no aplicativo, mapeando tokens para propósitos específicos
///
/// Esta classe abstrai os tokens brutos de cores e fornece uma camada semântica
/// para o uso nos componentes e telas, facilitando a manutenção e consistência.
class AppColors {
  // Cores primárias do app
  static const Color primaryDark = ColorTokens.green900;
  static const Color primary = ColorTokens.green800;
  static const Color primaryLight = ColorTokens.green600;
  static const Color primaryVariant = ColorTokens.green400;
  static const Color primarySurface = ColorTokens.green50;

  // Cores secundárias do app
  static const Color secondaryDark = ColorTokens.blue900;
  static const Color secondary = ColorTokens.blue800;
  static const Color secondaryLight = ColorTokens.blue700;
  static const Color secondaryVariant = ColorTokens.blue400;
  static const Color secondarySurface = ColorTokens.blue50;

  // Cores de destaque/terciárias
  static const Color tertiaryDark = ColorTokens.amber900;
  static const Color tertiary = ColorTokens.amber600;
  static const Color tertiaryLight = ColorTokens.amber400;
  static const Color tertiaryVariant = ColorTokens.amber300;
  static const Color tertiarySurface = ColorTokens.amber50;

  // Cores neutras
  static const Color neutralDarkest = ColorTokens.gray900;
  static const Color neutralDark = ColorTokens.gray800;
  static const Color neutral = ColorTokens.gray600;
  static const Color neutralLight = ColorTokens.gray400;
  static const Color neutralLightest = ColorTokens.gray200;
  static const Color neutralSurface = ColorTokens.gray100;

  // Estados de feedback
  static const Color success = ColorTokens.success;
  static const Color error = ColorTokens.error;
  static const Color warning = ColorTokens.warning;
  static const Color info = ColorTokens.info;
  static const Color disabled = ColorTokens.gray300;

  // Cores para fundos
  static const Color background = ColorTokens.white;
  static const Color backgroundVariant = ColorTokens.gray100;
  static const Color backgroundDark = ColorTokens.gray800;

  // Cores para texto
  static const Color textPrimary = ColorTokens.gray900;
  static const Color textSecondary = ColorTokens.gray600;
  static const Color textDisabled = ColorTokens.gray400;
  static const Color textOnPrimary = ColorTokens.white;
  static const Color textOnSecondary = ColorTokens.white;
  static const Color textOnTertiary = ColorTokens.gray900;

  // Cores de borda
  static const Color border = ColorTokens.gray300;
  static const Color borderLight = ColorTokens.gray200;
  static const Color borderDark = ColorTokens.gray500;

  // Cores para planos
  static const Color planBasic = ColorTokens.planBasic;
  static const Color planSilver = ColorTokens.planSilver;
  static const Color planGold = ColorTokens.planGold;
  static const Color planPremium = ColorTokens.planPremium;

  /// Retorna a cor do plano correspondente a um nome de plano
  static Color getPlanColor(String planName) {
    switch (planName.toUpperCase()) {
      case 'BASIC':
        return planBasic;
      case 'SILVER':
        return planSilver;
      case 'GOLD':
        return planGold;
      case 'PREMIUM':
        return planPremium;
      default:
        return planBasic;
    }
  }

  /// Retorna a cor de texto apropriada baseada na cor de fundo (para contraste)
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calcula a luminância da cor - próximo de 0 é escuro, próximo de 1 é claro
    final double luminance = backgroundColor.computeLuminance();
    // Se luminância for maior que 0.5, é uma cor clara e precisa de texto escuro
    return luminance > 0.5 ? textPrimary : ColorTokens.white;
  }
}
