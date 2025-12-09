import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_models.dart';
import 'package:flutter/foundation.dart';

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimeKey = 'exchange_rates_cache_time';
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // Mock exchange rates for demo - you can integrate with real APIs
  final Map<String, double> _mockRates = {
    'USD_VND': 24000.0,
    'EUR_VND': 26000.0,
    'CNY_VND': 3300.0,
    'JPY_VND': 160.0,
    'KRW_VND': 18.0,
    'THB_VND': 680.0,
    'GBP_VND': 30000.0,
    'SGD_VND': 18000.0,
    'HKD_VND': 3100.0,
    'AUD_VND': 16000.0,
    'CAD_VND': 17500.0,
  };

  Future<Map<String, ExchangeRate>> getExchangeRates({String baseCurrency = 'USD'}) async {
    try {
      // Check cache first
      final cachedRates = await _getCachedRates(baseCurrency);
      if (cachedRates != null) {
        return cachedRates;
      }

      // Try to fetch from API
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = <String, ExchangeRate>{};
        
        final ratesData = data['rates'] as Map<String, dynamic>;
        for (final entry in ratesData.entries) {
          rates['${baseCurrency}_${entry.key}'] = ExchangeRate(
            fromCurrency: baseCurrency,
            toCurrency: entry.key,
            rate: entry.value.toDouble(),
            lastUpdated: DateTime.now(),
            source: 'API',
          );
        }

        // Cache the rates
        await _cacheRates(baseCurrency, rates);
        return rates;
      }
    } catch (e) {
      debugPrint('Failed to fetch exchange rates: $e');
    }

    // Fallback to mock rates
    return _generateMockRates();
  }

  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    try {
      final rates = await getExchangeRates(baseCurrency: fromCurrency);
      final key = '${fromCurrency}_$toCurrency';
      
      if (rates.containsKey(key)) {
        return rates[key]!.rate;
      }

      // Try reverse rate
      final reverseKey = '${toCurrency}_$fromCurrency';
      if (rates.containsKey(reverseKey)) {
        return 1.0 / rates[reverseKey]!.rate;
      }

      // Fallback to mock rates
      return _getMockRate(fromCurrency, toCurrency);
    } catch (e) {
      return _getMockRate(fromCurrency, toCurrency);
    }
  }

  Future<ConversionResult> convertCurrency({
    required double amount,
    required Currency fromCurrency,
    required Currency toCurrency,
  }) async {
    final rate = await getExchangeRate(fromCurrency.code, toCurrency.code);
    final convertedAmount = amount * rate;

    return ConversionResult(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      convertedAmount: convertedAmount,
      exchangeRate: rate,
      timestamp: DateTime.now(),
    );
  }

  Map<String, ExchangeRate> _generateMockRates() {
    final rates = <String, ExchangeRate>{};
    final random = Random();
    
    for (final entry in _mockRates.entries) {
      final parts = entry.key.split('_');
      final baseRate = entry.value;
      // Add some random variation (±5%)
      final variation = (random.nextDouble() - 0.5) * 0.1;
      final rate = baseRate * (1 + variation);

      rates[entry.key] = ExchangeRate(
        fromCurrency: parts[0],
        toCurrency: parts[1],
        rate: rate,
        lastUpdated: DateTime.now(),
        source: 'Mock',
      );

      // Add reverse rate
      final reverseKey = '${parts[1]}_${parts[0]}';
      rates[reverseKey] = ExchangeRate(
        fromCurrency: parts[1],
        toCurrency: parts[0],
        rate: 1.0 / rate,
        lastUpdated: DateTime.now(),
        source: 'Mock',
      );
    }

    return rates;
  }

  double _getMockRate(String fromCurrency, String toCurrency) {
    final key = '${fromCurrency}_$toCurrency';
    if (_mockRates.containsKey(key)) {
      return _mockRates[key]!;
    }
    
    final reverseKey = '${toCurrency}_$fromCurrency';
    if (_mockRates.containsKey(reverseKey)) {
      return 1.0 / _mockRates[reverseKey]!;
    }
    
    // Default fallback rate
    return 1.0;
  }

  Future<void> _cacheRates(String baseCurrency, Map<String, ExchangeRate> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = rates.map((key, rate) => MapEntry(key, rate.toJson()));
      await prefs.setString('${_cacheKey}_$baseCurrency', json.encode(ratesJson));
      await prefs.setInt('${_cacheTimeKey}_$baseCurrency', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to cache exchange rates: $e');
    }
  }

  Future<Map<String, ExchangeRate>?> _getCachedRates(String baseCurrency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('${_cacheTimeKey}_$baseCurrency');
      
      if (cacheTime != null) {
        final cachedTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        if (DateTime.now().difference(cachedTime) < _cacheValidDuration) {
          final cachedData = prefs.getString('${_cacheKey}_$baseCurrency');
          if (cachedData != null) {
            final ratesJson = json.decode(cachedData) as Map<String, dynamic>;
            return ratesJson.map((key, value) => 
              MapEntry(key, ExchangeRate.fromJson(value))
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get cached rates: $e');
    }
    
    return null;
  }

  String formatCurrency(double amount, Currency currency) {
    if (currency.code == 'VND' || currency.code == 'JPY' || currency.code == 'KRW') {
      // Currencies without decimal places
      return '${currency.symbol}${amount.toStringAsFixed(0)}';
    } else {
      // Currencies with decimal places
      return '${currency.symbol}${amount.toStringAsFixed(2)}';
    }
  }

  List<Currency> getPopularCurrencies() {
    return Currency.popularCurrencies;
  }

  Currency getDefaultFromCurrency() {
    return Currency.getByCode('VND') ?? Currency.popularCurrencies.first;
  }

  Currency getDefaultToCurrency() {
    return Currency.getByCode('USD') ?? Currency.popularCurrencies[1];
  }
}