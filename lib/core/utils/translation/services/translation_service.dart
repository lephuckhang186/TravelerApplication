import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/translation_models.dart';

/// Service for translating text between multiple languages and detecting source language.
///
/// Uses the MyMemory API for live translations and includes a local rule-based
/// fallback for language detection and basic common travel phrases.
class TranslationService {
  static const String _baseUrl = 'https://api.mymemory.translated.net';

  // Mock translation for demo - you can integrate with real APIs like Google Translate
  Future<TranslationResult> translateText({
    required String text,
    required Language sourceLanguage,
    required Language targetLanguage,
  }) async {
    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    try {
      // Using MyMemory API as a free alternative
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/get?q=${Uri.encodeComponent(text)}&langpair=${sourceLanguage.code}|${targetLanguage.code}',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['responseData']['translatedText'] ?? text;
        final confidence = (data['responseData']['match'] ?? 0.0).toDouble();

        return TranslationResult(
          originalText: text,
          translatedText: translatedText,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          timestamp: DateTime.now(),
          confidence: confidence,
        );
      } else {
        throw Exception('Translation failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock translation for demo
      return _mockTranslation(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }
  }

  Future<Language> detectLanguage(String text) async {
    if (text.trim().isEmpty) {
      return Language.supportedLanguages.first;
    }

    try {
      // Simple language detection based on character patterns
      if (_containsVietnamese(text)) {
        return Language.getByCode('vi') ?? Language.supportedLanguages.first;
      } else if (_containsChinese(text)) {
        return Language.getByCode('zh') ?? Language.supportedLanguages.first;
      } else if (_containsJapanese(text)) {
        return Language.getByCode('ja') ?? Language.supportedLanguages.first;
      } else if (_containsKorean(text)) {
        return Language.getByCode('ko') ?? Language.supportedLanguages.first;
      } else if (_containsThai(text)) {
        return Language.getByCode('th') ?? Language.supportedLanguages.first;
      }

      // Default to English for Latin scripts
      return Language.getByCode('en') ?? Language.supportedLanguages.first;
    } catch (e) {
      return Language.supportedLanguages.first;
    }
  }

  TranslationResult _mockTranslation({
    required String text,
    required Language sourceLanguage,
    required Language targetLanguage,
  }) {
    // Mock translations for demo purposes
    Map<String, Map<String, String>> mockTranslations = {
      'vi': {
        'en': _translateVietnameseToEnglish(text),
        'zh': _translateVietnameseToChinese(text),
      },
      'en': {
        'vi': _translateEnglishToVietnamese(text),
        'zh': _translateEnglishToChinese(text),
      },
    };

    String translatedText = text;
    if (mockTranslations.containsKey(sourceLanguage.code)) {
      translatedText =
          mockTranslations[sourceLanguage.code]![targetLanguage.code] ?? text;
    }

    return TranslationResult(
      originalText: text,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      timestamp: DateTime.now(),
      confidence: 0.85,
    );
  }

  String _translateVietnameseToEnglish(String text) {
    final translations = {
      'xin chào': 'hello',
      'cảm ơn': 'thank you',
      'tạm biệt': 'goodbye',
      'du lịch': 'travel',
      'khách sạn': 'hotel',
      'nhà hàng': 'restaurant',
      'sân bay': 'airport',
      'taxi': 'taxi',
      'bãi biển': 'beach',
      'núi': 'mountain',
    };

    String result = text.toLowerCase();
    translations.forEach((vi, en) {
      result = result.replaceAll(vi, en);
    });
    return result;
  }

  String _translateEnglishToVietnamese(String text) {
    final translations = {
      'hello': 'xin chào',
      'thank you': 'cảm ơn',
      'goodbye': 'tạm biệt',
      'travel': 'du lịch',
      'hotel': 'khách sạn',
      'restaurant': 'nhà hàng',
      'airport': 'sân bay',
      'taxi': 'taxi',
      'beach': 'bãi biển',
      'mountain': 'núi',
    };

    String result = text.toLowerCase();
    translations.forEach((en, vi) {
      result = result.replaceAll(en, vi);
    });
    return result;
  }

  String _translateVietnameseToChinese(String text) {
    final translations = {
      'xin chào': '你好',
      'cảm ơn': '谢谢',
      'tạm biệt': '再见',
      'du lịch': '旅游',
      'khách sạn': '酒店',
    };

    String result = text.toLowerCase();
    translations.forEach((vi, zh) {
      result = result.replaceAll(vi, zh);
    });
    return result;
  }

  String _translateEnglishToChinese(String text) {
    final translations = {
      'hello': '你好',
      'thank you': '谢谢',
      'goodbye': '再见',
      'travel': '旅游',
      'hotel': '酒店',
    };

    String result = text.toLowerCase();
    translations.forEach((en, zh) {
      result = result.replaceAll(en, zh);
    });
    return result;
  }

  bool _containsVietnamese(String text) {
    return RegExp(
      r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
    ).hasMatch(text);
  }

  bool _containsChinese(String text) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  bool _containsJapanese(String text) {
    return RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text);
  }

  bool _containsKorean(String text) {
    return RegExp(r'[\uac00-\ud7af]').hasMatch(text);
  }

  bool _containsThai(String text) {
    return RegExp(r'[\u0e00-\u0e7f]').hasMatch(text);
  }
}
