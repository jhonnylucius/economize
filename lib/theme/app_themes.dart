import 'package:economize/theme/themes/light_theme.dart';
import 'package:economize/theme/themes/pastel_themes.dart';
import 'package:flutter/material.dart';

// Enum para tipos de tema
enum ThemeType { light, roxoEscuro }

/// Extension to provide display names for ThemeType
extension ThemeTypeExtension on ThemeType {
  String get displayName {
    switch (this) {
      case ThemeType.light:
        return 'Claro';
      default:
        return 'Roxo Escuro';
    }
  }
}

/// Classe que centraliza todos os temas da aplicação
class AppThemes {
  // Previne a instanciação
  AppThemes();

  // Variável estática para armazenar o tipo de tema atual
  static ThemeType currentThemeType = ThemeType.light;

  // Temas disponíveis
  static ThemeData get light => LightTheme.theme;
  static ThemeData get roxoEscuro => PastelTheme.theme;

  // Método para obter tema por tipo
  static ThemeData getThemeByType(ThemeType type) {
    currentThemeType = type;
    switch (type) {
      case ThemeType.light:
        return light;
      default:
        return roxoEscuro;
    }
  }

  // Adicione estes métodos ao ThemeManager

// ------ Métodos padronizados para Cards ------

  Color getCardBackgroundColor() {
    // Fundo branco para todos os cards independente do tema
    return Colors.white;
  }

  Color getCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCardTitleColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCardIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCardBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black.withAlpha((0.1 * 255).toInt());
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138)
            .withAlpha((0.3 * 255).toInt());
    }
  }

  Color getCardDividerColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black.withAlpha((0.1 * 255).toInt());
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138)
            .withAlpha((0.2 * 255).toInt());
    }
  }

  Color getCardButtonColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCardButtonTextColor() {
    // Sempre branco para contrastar com o botão escuro
    return Colors.white;
  }

  double getCardBorderRadius() {
    // Raio padrão para cards
    return 12.0;
  }

  double getCardElevation() {
    // Elevação padrão para cards
    return 2.0;
  }

// ------ Métodos padronizados para Diálogos ------

  Color getDialogBackgroundColor() {
    // Fundo branco para todos os diálogos independente do tema
    return Colors.white;
  }

  Color getDialogTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDialogTitleColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDialogButtonColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDialogButtonTextColor() {
    // Sempre branco para contrastar com o botão escuro
    return Colors.white;
  }

  Color getDialogCancelButtonColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade200;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade300;
    }
  }

  Color getDialogCancelButtonTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

// ------ Métodos para Campos de Entrada em Diálogos ------

  Color getInputBackgroundColor() {
    // Fundo branco para inputs
    return Colors.white;
  }

  Color getInputTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getInputLabelColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black.withAlpha((0.7 * 255).toInt());
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138)
            .withAlpha((0.8 * 255).toInt());
    }
  }

  Color getInputBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black.withAlpha((0.3 * 255).toInt());
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138)
            .withAlpha((0.5 * 255).toInt());
    }
  }

  Color getInputFocusedBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getInputErrorColor() {
    // Vermelho para erros independente do tema
    return Colors.red;
  }

  Color getInputCursorColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getInputIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

// ------ Métodos para Checkboxes, RadioButtons e Switches ------

  Color getCheckboxActiveColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCheckboxInactiveColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade400;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade400;
    }
  }

  Color getRadioActiveColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getSwitchActiveColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getSwitchTrackColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade300;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade300;
    }
  }

// ------ Métodos para listas e tabelas em Cards/Diálogos ------

  Color getListTileTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getListTileSubtitleColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black.withAlpha((0.6 * 255).toInt());
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138)
            .withAlpha((0.7 * 255).toInt());
    }
  }

  Color getListTileDividerColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade200;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade200;
    }
  }

  Color getTableHeaderBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade100;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade100;
    }
  }

  Color getTableHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getTableCellTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getInputFocusBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.blue; // Cor padrão de foco para tema claro
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(
            255, 43, 3, 138); // Cor roxa para tema escuro
    }
  }

  Color getTableCellBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade300;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade300;
    }
  }

  Color getHighlightColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.yellow.shade100;
      case ThemeType.roxoEscuro:
        return Colors.yellow.shade100;
    }
  }

  // Métodos faltantes para checkboxes
  Color getCheckboxCheckColor() {
    // Cor do ícone de check dentro do checkbox
    return Colors.white; // Sempre branco para contrastar com o fundo colorido
  }

  Color getCheckboxBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black.withAlpha((0.5 * 255).toInt());
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138)
            .withAlpha((0.7 * 255).toInt());
    }
  }

// ------ Métodos auxiliares para tipografia ------

  Color getHintTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade600;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade600;
    }
  }

  Color getDisabledTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade400;
      case ThemeType.roxoEscuro:
        return Colors.grey.shade400;
    }
  }

  TextStyle getDialogTitleStyle() {
    return TextStyle(
      color: getDialogTitleColor(),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle getCardTitleStyle() {
    return TextStyle(
      color: getCardTitleColor(),
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
  }

  InputDecoration getStandardInputDecoration(String label,
      {String? hint, Widget? prefixIcon, IconButton? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: getInputLabelColor()),
      hintText: hint,
      hintStyle: TextStyle(color: getHintTextColor()),
      prefixIcon: prefixIcon != null
          ? IconTheme(
              data: IconThemeData(color: getInputIconColor()),
              child: prefixIcon,
            )
          : null,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: getInputBorderColor()),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: getInputFocusedBorderColor(), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: getInputErrorColor()),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: getInputBackgroundColor(),
    );
  }

  ButtonStyle getStandardButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(getDialogButtonColor()),
      foregroundColor: WidgetStateProperty.all(getDialogButtonTextColor()),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  CardTheme getStandardCardTheme() {
    return CardTheme(
      color: getCardBackgroundColor(),
      elevation: getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getCardBorderRadius()),
        side: BorderSide(color: getCardBorderColor(), width: 0.5),
      ),
    );
  }
}
