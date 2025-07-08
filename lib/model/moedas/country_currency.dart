class CountryCurrency {
  final String countryCode; // 'BR', 'PT', etc.
  final String countryName; // 'Brasil', 'Portugal'
  final String currencyCode; // 'BRL', 'EUR', etc.
  final String currencyName; // 'Real', 'Euro'
  final String currencySymbol; // 'R$', '€'
  final String flagEmoji; // '🇧🇷', '🇵🇹'
  final String locale; // 'pt_BR', 'pt_PT'

  const CountryCurrency({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    required this.flagEmoji,
    required this.locale,
  });

  Map<String, dynamic> toMap() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'currencyCode': currencyCode,
      'currencyName': currencyName,
      'currencySymbol': currencySymbol,
      'flagEmoji': flagEmoji,
      'locale': locale,
    };
  }

  factory CountryCurrency.fromMap(Map<String, dynamic> map) {
    return CountryCurrency(
      countryCode: map['countryCode'] as String,
      countryName: map['countryName'] as String,
      currencyCode: map['currencyCode'] as String,
      currencyName: map['currencyName'] as String,
      currencySymbol: map['currencySymbol'] as String,
      flagEmoji: map['flagEmoji'] as String,
      locale: map['locale'] as String,
    );
  }
}
