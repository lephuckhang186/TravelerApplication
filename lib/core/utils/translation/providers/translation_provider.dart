import 'package:flutter/foundation.dart';
import '../models/translation_models.dart';
import '../services/translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  
  Language _sourceLanguage = Language.supportedLanguages[1]; // English
  Language _targetLanguage = Language.supportedLanguages[0]; // Vietnamese
  String _sourceText = '';
  String _targetText = '';
  bool _isLoading = false;
  String? _error;
  TranslationResult? _currentResult;
  List<TranslationResult> _history = [];

  // Getters
  Language get sourceLanguage => _sourceLanguage;
  Language get targetLanguage => _targetLanguage;
  String get sourceText => _sourceText;
  String get targetText => _targetText;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TranslationResult? get currentResult => _currentResult;
  List<TranslationResult> get history => List.unmodifiable(_history);

  // Setters
  void setSourceLanguage(Language language) {
    _sourceLanguage = language;
    notifyListeners();
  }

  void setTargetLanguage(Language language) {
    _targetLanguage = language;
    notifyListeners();
  }

  void setSourceText(String text) {
    _sourceText = text;
    if (text.isNotEmpty) {
      _autoDetectLanguage(text);
    }
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    
    final tempText = _sourceText;
    _sourceText = _targetText;
    _targetText = tempText;
    
    notifyListeners();
  }

  void clearText() {
    _sourceText = '';
    _targetText = '';
    _currentResult = null;
    _error = null;
    notifyListeners();
  }

  Future<void> translateText() async {
    if (_sourceText.trim().isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _translationService.translateText(
        text: _sourceText,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );

      _currentResult = result;
      _targetText = result.translatedText;
      _addToHistory(result);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _autoDetectLanguage(String text) async {
    try {
      final detectedLanguage = await _translationService.detectLanguage(text);
      if (detectedLanguage != _sourceLanguage) {
        _sourceLanguage = detectedLanguage;
        notifyListeners();
      }
    } catch (e) {
      // Silent fail for auto-detection
    }
  }

  void _addToHistory(TranslationResult result) {
    _history = [result, ..._history.take(19)];
    notifyListeners();
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
}