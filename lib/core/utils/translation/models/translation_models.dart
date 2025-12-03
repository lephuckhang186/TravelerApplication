class Language {
  final String code;
  final String name;
  final String flag;
  final String nativeName;

  const Language({
    required this.code,
    required this.name,
    required this.flag,
    required this.nativeName,
  });

  static const List<Language> supportedLanguages = [
    Language(code: 'vi', name: 'Vietnamese', flag: '🇻🇳', nativeName: 'Tiếng Việt'),
    Language(code: 'en', name: 'English', flag: '🇺🇸', nativeName: 'English'),
    Language(code: 'zh', name: 'Chinese', flag: '🇨🇳', nativeName: '中文'),
    Language(code: 'ja', name: 'Japanese', flag: '🇯🇵', nativeName: '日本語'),
    Language(code: 'ko', name: 'Korean', flag: '🇰🇷', nativeName: '한국어'),
    Language(code: 'th', name: 'Thai', flag: '🇹🇭', nativeName: 'ภาษาไทย'),
    Language(code: 'fr', name: 'French', flag: '🇫🇷', nativeName: 'Français'),
    Language(code: 'es', name: 'Spanish', flag: '🇪🇸', nativeName: 'Español'),
    Language(code: 'de', name: 'German', flag: '🇩🇪', nativeName: 'Deutsch'),
  ];

  static Language? getByCode(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
}

class TranslationResult {
  final String originalText;
  final String translatedText;
  final Language sourceLanguage;
  final Language targetLanguage;
  final DateTime timestamp;
  final double confidence;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    this.confidence = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguageCode': sourceLanguage.code,
      'targetLanguageCode': targetLanguage.code,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
    };
  }

  static TranslationResult fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'] ?? '',
      translatedText: json['translatedText'] ?? '',
      sourceLanguage: Language.getByCode(json['sourceLanguageCode']) ?? Language.supportedLanguages.first,
      targetLanguage: Language.getByCode(json['targetLanguageCode']) ?? Language.supportedLanguages.first,
      timestamp: DateTime.parse(json['timestamp']),
      confidence: json['confidence']?.toDouble() ?? 0.0,
    );
  }
}

class TranslationHistory {
  final List<TranslationResult> results;

  TranslationHistory({this.results = const []});

  TranslationHistory copyWith({List<TranslationResult>? results}) {
    return TranslationHistory(results: results ?? this.results);
  }

  TranslationHistory addResult(TranslationResult result) {
    final newResults = [result, ...results];
    // Keep only last 50 translations
    return TranslationHistory(results: newResults.take(50).toList());
  }

  List<Map<String, dynamic>> toJson() {
    return results.map((result) => result.toJson()).toList();
  }

  static TranslationHistory fromJson(List<dynamic> json) {
    final results = json.map((item) => TranslationResult.fromJson(item)).toList();
    return TranslationHistory(results: results);
  }
}