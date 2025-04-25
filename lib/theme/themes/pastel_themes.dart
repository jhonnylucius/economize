import 'package:flutter/material.dart';

class PastelTheme {
  static ThemeData get theme {
    const primaryColor = Color.fromARGB(255, 43, 3, 138);
    const surfaceColor = Colors.white;
    final unselectedColor = primaryColor.withAlpha((0.6 * 255).toInt());

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: surfaceColor,
        secondary: primaryColor,
        onSecondary: surfaceColor,
        error: Colors.red,
        onError: surfaceColor,
        surface: surfaceColor,
        onSurface: primaryColor,
        tertiary: primaryColor,
        onTertiary: surfaceColor,
        onSurfaceVariant: Colors.white,
        onInverseSurface: Colors.white,
        inverseSurface: primaryColor,
      ),
      scaffoldBackgroundColor: primaryColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: surfaceColor,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color.fromARGB(255, 43, 3, 138), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      unselectedWidgetColor:
          unselectedColor, // Define a cor para widgets inativos (bolinha do radio)
      // Opcional: Definir explicitamente no RadioTheme para garantir
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor; // Cor quando selecionado (já era assim)
          }
          // Cor quando NÃO selecionado
          return unselectedColor;
        }),
      ),

      iconTheme: const IconThemeData(
        color: primaryColor, // Ícones sobre fundo branco (surface)
      ),
      textTheme: const TextTheme().apply(
        bodyColor: primaryColor, // Texto sobre fundo branco (surface)
        displayColor: primaryColor,
      ),
    );
  }
}
