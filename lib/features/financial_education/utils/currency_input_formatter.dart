import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

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
    String formatted = _formatter.format(value);

    // Remove o símbolo da moeda que foi adicionado pelo formatter
    formatted = formatted.replaceAll('R\$', '').trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyParser {
  static double parse(String formattedValue) {
    if (formattedValue.isEmpty) return 0.0;

    // Remove todos os caracteres exceto números e vírgula
    String numericString = formattedValue.replaceAll(RegExp(r'[^\d,]'), '');

    // Substitui vírgula por ponto para conversão
    numericString = numericString.replaceAll(',', '.');

    return double.tryParse(numericString) ?? 0.0;
  }

  static String format(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }
}
