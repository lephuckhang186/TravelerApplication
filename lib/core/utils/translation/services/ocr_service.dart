import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_ocr_service.dart';

/// Service for Optical Character Recognition (OCR), extracting text from images.
///
/// Manages image selection from the device gallery and coordinates with
/// backend OCR solvers to return machine-readable text for translation.
class OCRService {
  final ImagePicker _imagePicker = ImagePicker();
  final WebOCRService _webOCRService = WebOCRService();

  /// Pick image from camera and extract text
  Future<String?> extractTextFromCamera() async {
    if (kIsWeb) {
      throw Exception(
        'Camera không khả dụng trên web. Vui lòng sử dụng "Chọn từ thư viện" để upload ảnh từ máy tính.',
      );
    }

    throw Exception(
      'Tính năng chụp ảnh chỉ khả dụng trên thiết bị di động (Android/iOS)',
    );
  }

  /// Pick image from gallery and extract text
  Future<String?> extractTextFromGallery({String? languageHint}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Use OCR.space with optimized settings
      final imageBytes = await image.readAsBytes();

      // Pass language hint to OCR service
      final extractedText = await _webOCRService.extractTextFromImageBytes(
        imageBytes,
        languageHint: languageHint,
      );
      return extractedText;
    } catch (e) {
      rethrow;
    }
  }

  /// Clean up resources
  void dispose() {
    // Nothing to dispose
  }
}
