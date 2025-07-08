import 'package:economize/service/moedas/currency_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final CurrencyService _currencyService = CurrencyService();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se o campo estiver vazio, retorna vazio
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove todos os caracteres não numéricos
    String numericString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Se não há números, retorna vazio
    if (numericString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Converte para double (dividindo por 100 para considerar centavos)
    double value = double.parse(numericString) / 100;

    // Formata o valor
    String formatted = _currencyService.formatCurrency(value);

    // Remove o símbolo da moeda que foi adicionado pelo formatter
    String symbol = _currencyService.currencySymbol;
    formatted = formatted.replaceAll(symbol, '').trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyParser {
  static final CurrencyService _currencyService = CurrencyService();

  static double parse(String formattedValue) {
    if (formattedValue.isEmpty) return 0.0;

    // Remove símbolo da moeda atual
    String symbol = _currencyService.currencySymbol;
    String cleanValue = formattedValue.replaceAll(symbol, '');

    // Remove espaços e outros caracteres
    cleanValue = cleanValue.replaceAll(RegExp(r'[^\d,.]'), '');

    // ✅ USAR O MÉTODO CORRETO:
    String decimalSeparator = _currencyService.getDecimalSeparator();

    // Se usar vírgula como decimal, converte para ponto
    if (decimalSeparator == ',') {
      // Remove separadores de milhares (pontos) primeiro
      cleanValue = cleanValue.replaceAll('.', '');
      // Converte vírgula decimal para ponto
      cleanValue = cleanValue.replaceAll(',', '.');
    } else {
      // Se usar ponto como decimal, remove vírgulas de milhares
      cleanValue = cleanValue.replaceAll(',', '');
    }

    return double.tryParse(cleanValue) ?? 0.0;
  }

  static String format(double value) {
    String formatted = _currencyService.formatCurrency(value);
    String symbol = _currencyService.currencySymbol;
    return formatted.replaceAll(symbol, '').trim();
  }
}
