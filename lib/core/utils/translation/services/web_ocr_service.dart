import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class WebOCRService {
  // OCR.space free API key
  static const String _apiKey = 'K87899142388957';
  static const String _apiUrl = 'https://api.ocr.space/parse/image';

  /// Extract text from image bytes (for web)
  Future<String> extractTextFromImageBytes(Uint8List imageBytes, {String? languageHint}) async {
    // If specific language is provided, use it directly with Engine 2 for accuracy
    if (languageHint != null && languageHint.isNotEmpty && languageHint != 'auto') {
      return await _extractWithLanguage(
        imageBytes, 
        _convertLanguageCode(languageHint),
        useEngine2: true,
      );
    }
    
    // For auto-detect, try top languages in priority order
    // English → Thai → Chinese Simplified → Chinese Traditional → Khmer (always try these 5)
    // Then try: Indonesian → Japanese → French → Korean if needed
    final languagesToTry = [
      'eng', // English
      'tha', // Thai
      'chs', // Chinese Simplified
      'cht', // Chinese Traditional
      'khm', // Khmer (Cambodia)
      'ind', // Indonesian
      'jpn', // Japanese
      'fre', // French
      'kor', // Korean
    ];
    
    String? bestResult;
    int maxLength = 0;
    int languagesChecked = 0;
    
    for (var lang in languagesToTry) {
      try {
        final result = await _extractWithLanguage(imageBytes, lang, useEngine2: true);
        languagesChecked++;
        
        if (result.isNotEmpty && result.length > maxLength) {
          bestResult = result;
          maxLength = result.length;
        }
        
        // Always try at least first 5 languages (eng, tha, chs, cht, khm) for multi-language images
        // Then stop if we found substantial text
        if (languagesChecked >= 5 && maxLength > 20) break;
      } catch (e) {
        languagesChecked++;
        continue;
      }
    }
    
    if (bestResult != null && bestResult.isNotEmpty) {
      return bestResult;
    }
    
    throw Exception('Không tìm thấy văn bản trong ảnh. Vui lòng thử chọn ngôn ngữ cụ thể hoặc dùng ảnh rõ hơn.');
  }
  /// Extract text with specific language
  Future<String> _extractWithLanguage(
    Uint8List imageBytes, 
    String languageCode, 
    {bool useEngine2 = false}
  ) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      // Add API key
      request.fields['apikey'] = _apiKey;
      request.fields['language'] = languageCode;
      request.fields['isOverlayRequired'] = 'false';
      request.fields['detectOrientation'] = 'true';
      request.fields['scale'] = 'true';
      // Engine 1 = Faster, Engine 2 = More accurate
      request.fields['OCREngine'] = useEngine2 ? '2' : '1';
      request.fields['isTable'] = 'false';
      request.fields['filetype'] = 'JPG';
      
      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        
        if (jsonResponse['IsErroredOnProcessing'] == true) {
          throw Exception(jsonResponse['ErrorMessage']?[0] ?? 'Lỗi khi xử lý ảnh');
        }
        
        String extractedText = '';
        var parsedResults = jsonResponse['ParsedResults'];
        
        if (parsedResults != null && parsedResults.isNotEmpty) {
          extractedText = parsedResults[0]['ParsedText'] ?? '';
        }
        
        // Clean up the text
        extractedText = extractedText.trim();
        
        return extractedText;
      } else {
        throw Exception('Lỗi kết nối API OCR (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi khi xử lý ảnh: $e');
    }
  }


  /// Convert language code to OCR.space format
  String _convertLanguageCode(String code) {
    // OCR.space language codes - comprehensive mapping
    const languageMap = {
      // Popular languages
      'en': 'eng',
      'vi': 'vie',
      'zh': 'chs',
      'zh-TW': 'cht',
      'ja': 'jpn',
      'ko': 'kor',
      'th': 'tha',
      'fr': 'fre',
      'es': 'spa',
      'de': 'ger',
      'it': 'ita',
      'pt': 'por',
      'ru': 'rus',
      'ar': 'ara',
      
      // Asian languages
      'hi': 'hin',
      'id': 'ind',
      'ms': 'msa',
      'bn': 'ben',
      'ta': 'tam',
      'te': 'tel',
      'mr': 'mar',
      'ur': 'urd',
      'gu': 'guj',
      'kn': 'kan',
      'ml': 'mal',
      'pa': 'pan',
      'si': 'sin',
      'ne': 'nep',
      'my': 'mya',
      'lo': 'lao',
      'km': 'khm',
      'fa': 'fas',
      'he': 'heb',
      'tr': 'tur',
      
      // European languages
      'pl': 'pol',
      'nl': 'dut',
      'sv': 'swe',
      'no': 'nor',
      'da': 'dan',
      'fi': 'fin',
      'el': 'gre',
      'hu': 'hun',
      'cs': 'cze',
      'sk': 'slk',
      'ro': 'ron',
      'bg': 'bul',
      'hr': 'hrv',
      'sr': 'srp',
      'sl': 'slv',
      'uk': 'ukr',
      'lt': 'lit',
      'lv': 'lav',
      'et': 'est',
      'mk': 'mkd',
      'sq': 'sqi',
      'bs': 'bos',
      'is': 'ice',
      'mt': 'mlt',
      'ga': 'gle',
      'cy': 'wel',
      'eu': 'eus',
      'ca': 'cat',
      'gl': 'glg',
      
      // African languages
      'af': 'afr',
      'sw': 'swa',
      'am': 'amh',
      'zu': 'zul',
      'xh': 'xho',
      
      // Other
      'az': 'aze',
      'kk': 'kaz',
      'uz': 'uzb',
      'hy': 'arm',
      'ka': 'geo',
      'ht': 'hat',
      'tl': 'tgl',
    };
    
    return languageMap[code] ?? 'eng';
  }
}
