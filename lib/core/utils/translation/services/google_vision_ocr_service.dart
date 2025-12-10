import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleVisionOCRService {
  // Google Cloud Vision API key
  static const String _apiKey = 'AIzaSyC0ohJjPWJvWIJFyN6vVPCj0gkO8Hzd_RA';
  static const String _apiUrl = 'https://vision.googleapis.com/v1/images:annotate';

  /// Extract text from image bytes using Google Cloud Vision API
  Future<String> extractTextFromImageBytes(Uint8List imageBytes) async {
    try {
      // Convert image to base64
      String base64Image = base64Encode(imageBytes);
      
      // Create request body
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 1,
              }
            ],
            'imageContext': {
              'languageHints': ['en', 'vi', 'th', 'ja', 'ko', 'zh', 'ar'],
            }
          }
        ]
      };

      // Send request
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Check for errors
        if (jsonResponse['responses'] != null && 
            jsonResponse['responses'].isNotEmpty) {
          final firstResponse = jsonResponse['responses'][0];
          
          // Check if there's an error
          if (firstResponse['error'] != null) {
            throw Exception(firstResponse['error']['message'] ?? 'Lỗi từ Google Vision API');
          }
          
          // Get full text annotation
          if (firstResponse['fullTextAnnotation'] != null) {
            String extractedText = firstResponse['fullTextAnnotation']['text'] ?? '';
            
            if (extractedText.isEmpty) {
              throw Exception('Không tìm thấy văn bản trong ảnh');
            }
            
            return extractedText.trim();
          } else if (firstResponse['textAnnotations'] != null && 
                     firstResponse['textAnnotations'].isNotEmpty) {
            // Fallback to textAnnotations
            String extractedText = firstResponse['textAnnotations'][0]['description'] ?? '';
            
            if (extractedText.isEmpty) {
              throw Exception('Không tìm thấy văn bản trong ảnh');
            }
            
            return extractedText.trim();
          } else {
            throw Exception('Không tìm thấy văn bản trong ảnh');
          }
        } else {
          throw Exception('Không nhận được phản hồi từ Google Vision API');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Lỗi API (${response.statusCode}): ${errorBody['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi khi xử lý ảnh: $e');
    }
  }

  /// Extract text with specific language hints
  Future<String> extractTextWithLanguageHints(
    Uint8List imageBytes,
    List<String> languageHints,
  ) async {
    try {
      // Convert image to base64
      String base64Image = base64Encode(imageBytes);
      
      // Create request body with specific language hints
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 1,
              }
            ],
            'imageContext': {
              'languageHints': languageHints,
            }
          }
        ]
      };

      // Send request
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['responses'] != null && 
            jsonResponse['responses'].isNotEmpty) {
          final firstResponse = jsonResponse['responses'][0];
          
          if (firstResponse['error'] != null) {
            throw Exception(firstResponse['error']['message'] ?? 'Lỗi từ Google Vision API');
          }
          
          if (firstResponse['fullTextAnnotation'] != null) {
            String extractedText = firstResponse['fullTextAnnotation']['text'] ?? '';
            
            if (extractedText.isEmpty) {
              throw Exception('Không tìm thấy văn bản trong ảnh');
            }
            
            return extractedText.trim();
          } else if (firstResponse['textAnnotations'] != null && 
                     firstResponse['textAnnotations'].isNotEmpty) {
            String extractedText = firstResponse['textAnnotations'][0]['description'] ?? '';
            
            if (extractedText.isEmpty) {
              throw Exception('Không tìm thấy văn bản trong ảnh');
            }
            
            return extractedText.trim();
          } else {
            throw Exception('Không tìm thấy văn bản trong ảnh');
          }
        } else {
          throw Exception('Không nhận được phản hồi từ Google Vision API');
        }
      } else {
        throw Exception('Lỗi kết nối API (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }
}
