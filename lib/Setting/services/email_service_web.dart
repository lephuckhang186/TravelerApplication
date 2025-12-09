import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;

class EmailService {
  static const String _teamEmail = 'teamtripwise@gmail.com';
  
  /// Gửi feedback qua email - Web compatible version
  static Future<bool> sendFeedbackEmail({
    required int rating,
    required String category,
    required String feedback,
    String? userEmail,
  }) async {
    try {
      if (kIsWeb) {
        // Web platform: Sử dụng mailto link
        return await _openEmailForWeb(rating, category, feedback, userEmail);
      } else {
        // Mobile/Desktop: Sử dụng mailto link đơn giản
        return await _openEmailForMobile(rating, category, feedback, userEmail);
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }
  
  /// Mở email trên web platform
  static Future<bool> _openEmailForWeb(
    int rating, 
    String category, 
    String feedback, 
    String? userEmail,
  ) async {
    try {
      final subject = Uri.encodeComponent('📝 Góp ý từ TripWise - $category');
      final body = Uri.encodeComponent(_buildPlainTextContent(rating, category, feedback, userEmail));
      
      final mailtoUrl = 'mailto:$_teamEmail?subject=$subject&body=$body';
      
      // Sử dụng window.location.href cho web để tránh popup blocker
      html.window.location.href = mailtoUrl;
      return true;
    } catch (e) {
      debugPrint('Error opening email on web: $e');
      // Fallback: copy to clipboard
      return await _copyToClipboard(rating, category, feedback, userEmail);
    }
  }
  
  /// Mở email trên mobile/desktop platform 
  static Future<bool> _openEmailForMobile(
    int rating, 
    String category, 
    String feedback, 
    String? userEmail,
  ) async {
    try {
      final subject = Uri.encodeComponent('📝 Góp ý từ TripWise - $category');
      final body = Uri.encodeComponent(_buildPlainTextContent(rating, category, feedback, userEmail));
      
      final mailtoUrl = 'mailto:$_teamEmail?subject=$subject&body=$body';
      
      // Trên mobile/desktop sử dụng window.open
      html.window.open(mailtoUrl, '_self');
      return true;
    } catch (e) {
      debugPrint('Error opening email on mobile: $e');
      return false;
    }
  }
  
  /// Copy feedback content to clipboard as fallback
  static Future<bool> _copyToClipboard(
    int rating, 
    String category, 
    String feedback, 
    String? userEmail,
  ) async {
    try {
      final content = '''
Gửi email thủ công đến: $_teamEmail

Subject: 📝 Góp ý từ TripWise - $category

${_buildPlainTextContent(rating, category, feedback, userEmail)}
      ''';
      
      await html.window.navigator.clipboard?.writeText(content);
      return true;
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      return false;
    }
  }
  
  /// Xây dựng nội dung email dạng text thuần
  static String _buildPlainTextContent(
    int rating, 
    String category, 
    String feedback, 
    String? userEmail,
  ) {
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];
    final ratingStars = '⭐' * rating + '☆' * (5 - rating);
    
    return '''🎯 GÓP Ý MỚI TỪ TRIPWISE

📅 Thời gian: $timestamp

⭐ Đánh giá: $ratingStars ($rating/5)

🏷️ Loại góp ý: $category

💬 Chi tiết góp ý:
$feedback

📧 Thông tin liên hệ: ${userEmail ?? 'Không có'}

---
📱 Email này được gửi từ ứng dụng TripWise
Vui lòng xem xét và phản hồi nếu cần thiết''';
  }
  
  /// Kiểm tra xem có thể gửi email không
  static Future<bool> canSendEmail() async {
    try {
      // Trên web luôn có thể thử mở mailto
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Hiển thị thông tin email cho user copy thủ công
  static String getManualEmailInfo(
    int rating, 
    String category, 
    String feedback, 
    String? userEmail,
  ) {
    return '''
📧 Thông tin email thủ công:

Gửi đến: $_teamEmail
Tiêu đề: 📝 Góp ý từ TripWise - $category

Nội dung:
${_buildPlainTextContent(rating, category, feedback, userEmail)}
    ''';
  }
}