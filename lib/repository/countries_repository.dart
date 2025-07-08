import 'package:economize/model/moedas/country_currency.dart';

class CountriesRepository {
  static const List<CountryCurrency> supportedCountries = [
    CountryCurrency(
      countryCode: 'BR',
      countryName: 'Brasil',
      currencyCode: 'BRL',
      currencyName: 'Real',
      currencySymbol: 'R\$',
      flagEmoji: '🇧🇷',
      locale: 'pt_BR',
    ),
    CountryCurrency(
      countryCode: 'PT',
      countryName: 'Portugal',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      currencySymbol: '€',
      flagEmoji: '🇵🇹',
      locale: 'pt_PT',
    ),
    CountryCurrency(
      countryCode: 'AO',
      countryName: 'Angola',
      currencyCode: 'AOA',
      currencyName: 'Kwanza',
      currencySymbol: 'Kz',
      flagEmoji: '🇦🇴',
      locale: 'pt_AO',
    ),
    CountryCurrency(
      countryCode: 'MZ',
      countryName: 'Moçambique',
      currencyCode: 'MZN',
      currencyName: 'Metical',
      currencySymbol: 'MT',
      flagEmoji: '🇲🇿',
      locale: 'pt_MZ',
    ),
    CountryCurrency(
      countryCode: 'CV',
      countryName: 'Cabo Verde',
      currencyCode: 'CVE',
      currencyName: 'Escudo',
      currencySymbol: 'CVE',
      flagEmoji: '🇨🇻',
      locale: 'pt_CV',
    ),
    CountryCurrency(
      countryCode: 'GW',
      countryName: 'Guiné-Bissau',
      currencyCode: 'XOF',
      currencyName: 'Franco CFA',
      currencySymbol: 'CFA',
      flagEmoji: '🇬🇼',
      locale: 'pt_GW',
    ),
  ];

  static CountryCurrency getDefault() =>
      supportedCountries.first; // Brasil como padrão

  static CountryCurrency? findByCountryCode(String countryCode) {
    try {
      return supportedCountries.firstWhere(
        (country) =>
            country.countryCode.toLowerCase() == countryCode.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static CountryCurrency? detectFromLocale(String? localeCode) {
    if (localeCode == null) return getDefault();

    // Extrai o código do país do locale (ex: 'pt_BR' -> 'BR')
    final parts = localeCode.split('_');
    if (parts.length >= 2) {
      return findByCountryCode(parts[1]);
    }

    return getDefault();
  }
}
