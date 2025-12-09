import 'package:flutter/foundation.dart';
import '../models/currency_models.dart';
import '../services/currency_service.dart';

class CurrencyProvider extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();
  
  Currency _fromCurrency = Currency.popularCurrencies[0]; // VND
  Currency _toCurrency = Currency.popularCurrencies[1]; // USD
  double _amount = 0.0;
  double _convertedAmount = 0.0;
  double _exchangeRate = 0.0;
  bool _isLoading = false;
  String? _error;
  final Map<String, ExchangeRate> _exchangeRates = {};
  List<ConversionResult> _history = [];

  // Getters
  Currency get fromCurrency => _fromCurrency;
  Currency get toCurrency => _toCurrency;
  double get amount => _amount;
  double get convertedAmount => _convertedAmount;
  double get exchangeRate => _exchangeRate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, ExchangeRate> get exchangeRates => Map.unmodifiable(_exchangeRates);
  List<ConversionResult> get history => List.unmodifiable(_history);

  // Setters
  void setFromCurrency(Currency currency) {
    _fromCurrency = currency;
    _loadExchangeRates();
    notifyListeners();
  }

  void setToCurrency(Currency currency) {
    _toCurrency = currency;
    _loadExchangeRates();
    notifyListeners();
  }

  void setAmount(double amount) {
    _amount = amount;
    _convertCurrency();
    notifyListeners();
  }

  void swapCurrencies() {
    final temp = _fromCurrency;
    _fromCurrency = _toCurrency;
    _toCurrency = temp;
    _loadExchangeRates();
    notifyListeners();
  }

  void clearAmount() {
    _amount = 0.0;
    _convertedAmount = 0.0;
    notifyListeners();
  }

  Future<void> _loadExchangeRates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rate = await _currencyService.getExchangeRate(
        _fromCurrency.code,
        _toCurrency.code,
      );
      
      _exchangeRate = rate;
      _convertCurrency();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _convertCurrency() async {
    if (_amount <= 0 || _exchangeRate <= 0) {
      _convertedAmount = 0.0;
      return;
    }

    try {
      final result = await _currencyService.convertCurrency(
        amount: _amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
      );

      _convertedAmount = result.convertedAmount;
      _exchangeRate = result.exchangeRate;
      _addToHistory(result);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _addToHistory(ConversionResult result) {
    // Only add if amount > 0
    if (result.amount > 0) {
      _history = [result, ..._history.take(19)];
      notifyListeners();
    }
  }

  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  String formatCurrency(double amount, Currency currency) {
    return _currencyService.formatCurrency(amount, currency);
  }

  Future<void> refreshRates() async {
    await _loadExchangeRates();
  }

  // Initialize with default rates
  Future<void> initialize() async {
    await _loadExchangeRates();
  }
}