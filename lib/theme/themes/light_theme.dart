import 'package:flutter/material.dart';

class LightTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          tertiary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          onTertiary: Colors.black,
          onSurfaceVariant: Colors.black,
          onInverseSurface: Colors.black,
          inverseSurface: Colors.black,
        ),

        scaffoldBackgroundColor: Colors.white,

        // Cards brancos com borda preta
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2, // Adicionada elevação apenas no tema light
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
        ),

        // Textos pretos
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
          titleLarge: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          labelLarge: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
