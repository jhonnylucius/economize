import 'package:economize/model/moedas/country_currency.dart';
import 'package:economize/repository/countries_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static const String _storageKey = 'selected_country_currency';

  CountryCurrency _selectedCountry = CountriesRepository.getDefault();
  late NumberFormat _currencyFormatter;
  bool _isInitialized = false;

  // Getters públicos
  CountryCurrency get selectedCountry => _selectedCountry;
  String get currencySymbol => _selectedCountry.currencySymbol;
  String get countryFlag => _selectedCountry.flagEmoji;
  String get countryName => _selectedCountry.countryName;
  String get currencyName => _selectedCountry.currencyName;
  bool get isInitialized => _isInitialized;

  /// Inicializa o serviço carregando configuração salva ou detectando automaticamente
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCountryCode = prefs.getString(_storageKey);

      if (savedCountryCode != null) {
        // Carrega país salvo
        final savedCountry =
            CountriesRepository.findByCountryCode(savedCountryCode);
        if (savedCountry != null) {
          await _updateSelectedCountry(savedCountry, saveToPrefs: false);
        }
      } else {
        // Detecta automaticamente pelo locale do dispositivo
        final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
        final detectedCountry =
            CountriesRepository.detectFromLocale(deviceLocale.toString());
        if (detectedCountry != null) {
          await _updateSelectedCountry(detectedCountry, saveToPrefs: true);
        }
      }

      _isInitialized = true;
      debugPrint(
          '🌍 CurrencyService inicializado: ${_selectedCountry.countryName}');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar CurrencyService: $e');
      _isInitialized = true; // Marca como inicializado mesmo com erro
    }
  }

  /// Atualiza o país/moeda selecionado
  Future<void> setSelectedCountry(CountryCurrency country) async {
    await _updateSelectedCountry(country, saveToPrefs: true);
  }

  /// Método privado para atualizar país e formatter
  Future<void> _updateSelectedCountry(CountryCurrency country,
      {required bool saveToPrefs}) async {
    _selectedCountry = country;
    _updateFormatter();

    if (saveToPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, country.countryCode);
    }

    notifyListeners();
    debugPrint(
        '💰 Moeda alterada para: ${country.currencyName} (${country.currencySymbol})');
  }

  /// Atualiza o formatador de moeda baseado no país selecionado
  void _updateFormatter() {
    try {
      _currencyFormatter = NumberFormat.currency(
        locale: _selectedCountry.locale,
        symbol: _selectedCountry.currencySymbol,
        decimalDigits: 2,
      );
    } catch (e) {
      // Fallback se o locale não for suportado
      debugPrint(
          '⚠️ Locale ${_selectedCountry.locale} não suportado, usando padrão');
      _currencyFormatter = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: _selectedCountry.currencySymbol,
        decimalDigits: 2,
      );
    }
  }

  /// Formata valor monetário de acordo com a moeda selecionada
  String formatCurrency(double value) {
    if (!_isInitialized) {
      // Fallback se não foi inicializado
      return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    }

    try {
      return _currencyFormatter.format(value);
    } catch (e) {
      // Fallback manual se o formatter falhar
      debugPrint('⚠️ Erro ao formatar moeda: $e');
      return '${_selectedCountry.currencySymbol} ${value.toStringAsFixed(2)}';
    }
  }

  // ✅ ADICIONAR ESTE MÉTODO NA CLASSE CurrencyService:

  /// Retorna o separador decimal do locale atual
  String getDecimalSeparator() {
    if (!_isInitialized) {
      return ','; // Fallback para pt_BR
    }

    try {
      return _currencyFormatter.symbols.DECIMAL_SEP;
    } catch (e) {
      // Fallback baseado no locale
      return _selectedCountry.locale.contains('pt_BR') ? ',' : '.';
    }
  }

  /// Retorna o separador de milhares do locale atual
  String getThousandsSeparator() {
    if (!_isInitialized) {
      return '.'; // Fallback para pt_BR
    }

    try {
      return _currencyFormatter.symbols.GROUP_SEP;
    } catch (e) {
      // Fallback baseado no locale
      return _selectedCountry.locale.contains('pt_BR') ? '.' : ',';
    }
  }

  /// Formata valor monetário com emoji da bandeira
  String formatCurrencyWithFlag(double value) {
    return '${_selectedCountry.flagEmoji} ${formatCurrency(value)}';
  }

  /// Detecta país pelo locale do dispositivo
  static CountryCurrency? detectCountryFromDevice() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return CountriesRepository.detectFromLocale(deviceLocale.toString());
  }

  /// Verifica se é primeira execução (não tem país salvo)
  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_storageKey);
  }

  /// Marca que o usuário já configurou o país (remove a necessidade da tela de seleção)
  static Future<void> markAsConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('currency_configured', true);
  }

  /// Verifica se o usuário já configurou a moeda
  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('currency_configured') ?? false;
  }
}
