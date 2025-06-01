import 'package:flutter/material.dart';

/// Define os tokens primitivos de cores do sistema de design
///
/// Os tokens são organizados por paletas funcionais e semânticas,
/// fornecendo valores consistentes para todo o sistema.
class ColorTokens {
  // Cores primárias - verde
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32); // Cor primária principal
  static const Color green900 = Color(0xFF1B5E20);

  // Cores secundárias - azul
  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue100 = Color(0xFFBBDEFB);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue300 = Color(0xFF64B5F6);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color blue500 = Color(0xFF2196F3);
  static const Color blue600 = Color(0xFF1E88E5);
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0); // Cor secundária principal
  static const Color blue900 = Color(0xFF0D47A1);

  // Cores terciárias - âmbar (destaque)
  static const Color amber50 = Color(0xFFFFF8E1);
  static const Color amber100 = Color(0xFFFFECB3);
  static const Color amber200 = Color(0xFFFFE082);
  static const Color amber300 = Color(0xFFFFD54F);
  static const Color amber400 = Color(0xFFFFCA28);
  static const Color amber500 = Color(0xFFFFC107);
  static const Color amber600 = Color(0xFFFFB300); // Cor terciária principal
  static const Color amber700 = Color(0xFFFFA000);
  static const Color amber800 = Color(0xFFFF8F00);
  static const Color amber900 = Color(0xFFFF6F00);

  // Neutros - cinza
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575); // Cor neutra principal
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Estados de feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF29B6F6);

  // Cores especiais para planos
  static const Color planBasic = Color(0xFF78909C); // Azul acinzentado
  static const Color planSilver = Color(0xFFBDBDBD); // Cinza prateado
  static const Color planGold = Color(0xFFFFD54F); // Âmbar dourado
  static const Color planPremium = Color(0xFF7B1FA2); // Roxo premium

  // Cores básicas constantes
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}
