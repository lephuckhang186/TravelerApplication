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
    // Auto detect
    Language(code: 'auto', name: 'Auto Detect', flag: '🌐', nativeName: 'Tự động phát hiện'),
    
    // Popular languages
    Language(code: 'vi', name: 'Vietnamese', flag: '🇻🇳', nativeName: 'Tiếng Việt'),
    Language(code: 'en', name: 'English', flag: '🇺🇸', nativeName: 'English'),
    Language(code: 'zh', name: 'Chinese (Simplified)', flag: '🇨🇳', nativeName: '简体中文'),
    Language(code: 'zh-TW', name: 'Chinese (Traditional)', flag: '🇹🇼', nativeName: '繁體中文'),
    Language(code: 'ja', name: 'Japanese', flag: '🇯🇵', nativeName: '日本語'),
    Language(code: 'ko', name: 'Korean', flag: '🇰🇷', nativeName: '한국어'),
    Language(code: 'th', name: 'Thai', flag: '🇹🇭', nativeName: 'ภาษาไทย'),
    Language(code: 'fr', name: 'French', flag: '🇫🇷', nativeName: 'Français'),
    Language(code: 'es', name: 'Spanish', flag: '🇪🇸', nativeName: 'Español'),
    Language(code: 'de', name: 'German', flag: '🇩🇪', nativeName: 'Deutsch'),
    Language(code: 'it', name: 'Italian', flag: '🇮🇹', nativeName: 'Italiano'),
    Language(code: 'pt', name: 'Portuguese', flag: '🇵🇹', nativeName: 'Português'),
    Language(code: 'ru', name: 'Russian', flag: '🇷🇺', nativeName: 'Русский'),
    Language(code: 'ar', name: 'Arabic', flag: '🇸🇦', nativeName: 'العربية'),
    
    // Asian languages
    Language(code: 'hi', name: 'Hindi', flag: '🇮🇳', nativeName: 'हिन्दी'),
    Language(code: 'id', name: 'Indonesian', flag: '🇮🇩', nativeName: 'Bahasa Indonesia'),
    Language(code: 'tl', name: 'Tagalog', flag: '🇵🇭', nativeName: 'Tagalog'),
    Language(code: 'ms', name: 'Malay', flag: '🇲🇾', nativeName: 'Bahasa Melayu'),
    Language(code: 'bn', name: 'Bengali', flag: '🇧🇩', nativeName: 'বাংলা'),
    Language(code: 'ta', name: 'Tamil', flag: '🇮🇳', nativeName: 'தமிழ்'),
    Language(code: 'te', name: 'Telugu', flag: '🇮🇳', nativeName: 'తెలుగు'),
    Language(code: 'mr', name: 'Marathi', flag: '🇮🇳', nativeName: 'मराठी'),
    Language(code: 'ur', name: 'Urdu', flag: '🇵🇰', nativeName: 'اردو'),
    Language(code: 'gu', name: 'Gujarati', flag: '🇮🇳', nativeName: 'ગુજરાતી'),
    Language(code: 'kn', name: 'Kannada', flag: '🇮🇳', nativeName: 'ಕನ್ನಡ'),
    Language(code: 'ml', name: 'Malayalam', flag: '🇮🇳', nativeName: 'മലയാളം'),
    Language(code: 'pa', name: 'Punjabi', flag: '🇮🇳', nativeName: 'ਪੰਜਾਬੀ'),
    Language(code: 'si', name: 'Sinhala', flag: '🇱🇰', nativeName: 'සිංහල'),
    Language(code: 'ne', name: 'Nepali', flag: '🇳🇵', nativeName: 'नेपाली'),
    Language(code: 'my', name: 'Myanmar', flag: '🇲🇲', nativeName: 'မြန်မာ'),
    Language(code: 'lo', name: 'Lao', flag: '🇱🇦', nativeName: 'ລາວ'),
    Language(code: 'km', name: 'Khmer', flag: '🇰🇭', nativeName: 'ខ្មែរ'),
    Language(code: 'fa', name: 'Persian', flag: '🇮🇷', nativeName: 'فارسی'),
    Language(code: 'he', name: 'Hebrew', flag: '🇮🇱', nativeName: 'עברית'),
    Language(code: 'tr', name: 'Turkish', flag: '🇹🇷', nativeName: 'Türkçe'),
    
    // European languages
    Language(code: 'pl', name: 'Polish', flag: '🇵🇱', nativeName: 'Polski'),
    Language(code: 'nl', name: 'Dutch', flag: '🇳🇱', nativeName: 'Nederlands'),
    Language(code: 'sv', name: 'Swedish', flag: '🇸🇪', nativeName: 'Svenska'),
    Language(code: 'no', name: 'Norwegian', flag: '🇳🇴', nativeName: 'Norsk'),
    Language(code: 'da', name: 'Danish', flag: '🇩🇰', nativeName: 'Dansk'),
    Language(code: 'fi', name: 'Finnish', flag: '🇫🇮', nativeName: 'Suomi'),
    Language(code: 'el', name: 'Greek', flag: '🇬🇷', nativeName: 'Ελληνικά'),
    Language(code: 'hu', name: 'Hungarian', flag: '🇭🇺', nativeName: 'Magyar'),
    Language(code: 'cs', name: 'Czech', flag: '🇨🇿', nativeName: 'Čeština'),
    Language(code: 'sk', name: 'Slovak', flag: '🇸🇰', nativeName: 'Slovenčina'),
    Language(code: 'ro', name: 'Romanian', flag: '🇷🇴', nativeName: 'Română'),
    Language(code: 'bg', name: 'Bulgarian', flag: '🇧🇬', nativeName: 'Български'),
    Language(code: 'hr', name: 'Croatian', flag: '🇭🇷', nativeName: 'Hrvatski'),
    Language(code: 'sr', name: 'Serbian', flag: '🇷🇸', nativeName: 'Српски'),
    Language(code: 'sl', name: 'Slovenian', flag: '🇸🇮', nativeName: 'Slovenščina'),
    Language(code: 'uk', name: 'Ukrainian', flag: '🇺🇦', nativeName: 'Українська'),
    Language(code: 'lt', name: 'Lithuanian', flag: '🇱🇹', nativeName: 'Lietuvių'),
    Language(code: 'lv', name: 'Latvian', flag: '🇱🇻', nativeName: 'Latviešu'),
    Language(code: 'et', name: 'Estonian', flag: '🇪🇪', nativeName: 'Eesti'),
    Language(code: 'mk', name: 'Macedonian', flag: '🇲🇰', nativeName: 'Македонски'),
    Language(code: 'sq', name: 'Albanian', flag: '🇦🇱', nativeName: 'Shqip'),
    Language(code: 'bs', name: 'Bosnian', flag: '🇧🇦', nativeName: 'Bosanski'),
    Language(code: 'is', name: 'Icelandic', flag: '🇮🇸', nativeName: 'Íslenska'),
    Language(code: 'mt', name: 'Maltese', flag: '🇲🇹', nativeName: 'Malti'),
    Language(code: 'ga', name: 'Irish', flag: '🇮🇪', nativeName: 'Gaeilge'),
    Language(code: 'cy', name: 'Welsh', flag: '🏴󐁧󐁢󐁷󐁬󐁳󐁿', nativeName: 'Cymraeg'),
    Language(code: 'eu', name: 'Basque', flag: '🏴', nativeName: 'Euskara'),
    Language(code: 'ca', name: 'Catalan', flag: '🏴', nativeName: 'Català'),
    Language(code: 'gl', name: 'Galician', flag: '🏴', nativeName: 'Galego'),
    
    // African languages
    Language(code: 'af', name: 'Afrikaans', flag: '🇿🇦', nativeName: 'Afrikaans'),
    Language(code: 'sw', name: 'Swahili', flag: '🇰🇪', nativeName: 'Kiswahili'),
    Language(code: 'am', name: 'Amharic', flag: '🇪🇹', nativeName: 'አማርኛ'),
    Language(code: 'zu', name: 'Zulu', flag: '🇿🇦', nativeName: 'isiZulu'),
    Language(code: 'xh', name: 'Xhosa', flag: '🇿🇦', nativeName: 'isiXhosa'),
    
    // Other languages
    Language(code: 'az', name: 'Azerbaijani', flag: '🇦🇿', nativeName: 'Azərbaycan'),
    Language(code: 'kk', name: 'Kazakh', flag: '🇰🇿', nativeName: 'Қазақ'),
    Language(code: 'uz', name: 'Uzbek', flag: '🇺🇿', nativeName: 'Oʻzbek'),
    Language(code: 'hy', name: 'Armenian', flag: '🇦🇲', nativeName: 'Հայերեն'),
    Language(code: 'ka', name: 'Georgian', flag: '🇬🇪', nativeName: 'ქართული'),
    Language(code: 'ht', name: 'Haitian Creole', flag: '🇭🇹', nativeName: 'Kreyòl'),
    Language(code: 'la', name: 'Latin', flag: '🏛️', nativeName: 'Latina'),
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