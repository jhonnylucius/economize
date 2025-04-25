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
  AppThemes._();

  // Temas disponíveis
  static ThemeData get light => LightTheme.theme;
  static ThemeData get roxoEscuro => PastelTheme.theme;

  // Método para obter tema por tipo
  static ThemeData getThemeByType(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return light;
      default:
        return roxoEscuro;
    }
  }
}
