class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final String country;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.country,
  });

  static const List<Currency> popularCurrencies = [
    Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', flag: '🇻🇳', country: 'Vietnam'),
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸', country: 'United States'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺', country: 'European Union'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳', country: 'China'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵', country: 'Japan'),
    Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷', country: 'South Korea'),
    Currency(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭', country: 'Thailand'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧', country: 'United Kingdom'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺', country: 'Australia'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦', country: 'Canada'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬', country: 'Singapore'),
    Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰', country: 'Hong Kong'),
  ];

  static Currency? getByCode(String code) {
    try {
      return popularCurrencies.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }
}

class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime lastUpdated;
  final String source;

  ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
    this.source = 'API',
  });

  Map<String, dynamic> toJson() {
    return {
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'rate': rate,
      'lastUpdated': lastUpdated.toIso8601String(),
      'source': source,
    };
  }

  static ExchangeRate fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      fromCurrency: json['fromCurrency'] ?? '',
      toCurrency: json['toCurrency'] ?? '',
      rate: json['rate']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      source: json['source'] ?? 'API',
    );
  }
}

class ConversionResult {
  final double amount;
  final Currency fromCurrency;
  final Currency toCurrency;
  final double convertedAmount;
  final double exchangeRate;
  final DateTime timestamp;

  ConversionResult({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'fromCurrencyCode': fromCurrency.code,
      'toCurrencyCode': toCurrency.code,
      'convertedAmount': convertedAmount,
      'exchangeRate': exchangeRate,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static ConversionResult fromJson(Map<String, dynamic> json) {
    return ConversionResult(
      amount: json['amount']?.toDouble() ?? 0.0,
      fromCurrency: Currency.getByCode(json['fromCurrencyCode']) ?? Currency.popularCurrencies.first,
      toCurrency: Currency.getByCode(json['toCurrencyCode']) ?? Currency.popularCurrencies.first,
      convertedAmount: json['convertedAmount']?.toDouble() ?? 0.0,
      exchangeRate: json['exchangeRate']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class CurrencyConverterState {
  final Currency fromCurrency;
  final Currency toCurrency;
  final Map<String, ExchangeRate> exchangeRates;
  final List<ConversionResult> history;
  final bool isLoading;
  final String? error;

  CurrencyConverterState({
    required this.fromCurrency,
    required this.toCurrency,
    this.exchangeRates = const {},
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  CurrencyConverterState copyWith({
    Currency? fromCurrency,
    Currency? toCurrency,
    Map<String, ExchangeRate>? exchangeRates,
    List<ConversionResult>? history,
    bool? isLoading,
    String? error,
  }) {
    return CurrencyConverterState(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}