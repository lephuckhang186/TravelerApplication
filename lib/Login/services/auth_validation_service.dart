import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthValidationService {
  static final AuthValidationService _instance = AuthValidationService._internal();
  factory AuthValidationService() => _instance;
  AuthValidationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kiểm tra tính hợp lệ của email
  ValidationResult validateEmail(String email) {
    if (email.trim().isEmpty) {
      return ValidationResult(false, 'Vui lòng nhập email');
    }

    // Kiểm tra format email cơ bản
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult(false, 'Email không đúng định dạng');
    }

    // Kiểm tra các domain email tạm thời
    final emailParts = email.trim().split('@');
    if (emailParts.length == 2) {
      final domain = emailParts[1].toLowerCase();
      final blockedDomains = ['tempmail.com', '10minutemail.com', 'guerrillamail.com'];
      if (blockedDomains.contains(domain)) {
        return ValidationResult(false, 'Email tạm thời không được phép sử dụng');
      }
    }

    return ValidationResult(true, '');
  }

  /// Kiểm tra độ mạnh của mật khẩu
  ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, 'Vui lòng nhập mật khẩu');
    }

    // Kiểm tra độ dài tối thiểu
    if (password.length < 8) {
      return ValidationResult(false, 'Mật khẩu phải có ít nhất 8 ký tự');
    }

    // Kiểm tra độ dài tối đa
    if (password.length > 128) {
      return ValidationResult(false, 'Mật khẩu không được quá 128 ký tự');
    }

    // Danh sách các yêu cầu
    final requirements = <String>[];
    
    // Kiểm tra có chứa chữ thường
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      requirements.add('chữ thường (a-z)');
    }

    // Kiểm tra có chứa chữ hoa
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      requirements.add('chữ hoa (A-Z)');
    }

    // Kiểm tra có chứa số
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      requirements.add('số (0-9)');
    }

    // Kiểm tra có chứa ký tự đặc biệt
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      requirements.add('ký tự đặc biệt (!@#\$%^&*)');
    }

    // Kiểm tra mật khẩu phổ biến và yếu
    final commonPasswords = [
      'password', '123456789', 'qwertyuiop', 'abc123456', 
      'password123', '123456780', 'admin123', 'user123',
      'welcome123', 'changeme123'
    ];
    
    if (commonPasswords.contains(password.toLowerCase())) {
      return ValidationResult(false, 'Mật khẩu này quá phổ biến và dễ đoán');
    }

    if (requirements.isNotEmpty) {
      return ValidationResult(false, 
        'Mật khẩu cần có: ${requirements.join(', ')}');
    }

    return ValidationResult(true, '');
  }

  /// Tính điểm độ mạnh của mật khẩu (0-100)
  int getPasswordStrength(String password) {
    int score = 0;

    // Điểm cho độ dài
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    // Điểm cho các loại ký tự
    if (RegExp(r'[a-z]').hasMatch(password)) score += 10;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 10;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 10;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 15;

    // Điểm cho sự đa dạng
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= 6) score += 10;
    if (uniqueChars >= 10) score += 5;

    // Trừ điểm cho mẫu lặp
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score -= 10; // aaa, 111
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) score -= 5;
    if (RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)').hasMatch(password.toLowerCase())) score -= 5;

    return score.clamp(0, 100);
  }

  /// Lấy màu cho thanh độ mạnh mật khẩu
  Color getPasswordStrengthColor(int strength) {
    if (strength < 30) return Colors.red;
    if (strength < 60) return Colors.orange;
    if (strength < 80) return Colors.yellow;
    return Colors.green;
  }

  /// Lấy text mô tả độ mạnh
  String getPasswordStrengthText(int strength) {
    if (strength < 30) return 'Yếu';
    if (strength < 60) return 'Trung bình';
    if (strength < 80) return 'Khá';
    return 'Mạnh';
  }

  /// Kiểm tra email có tồn tại trong Firebase không (check duplicate)
  Future<ValidationResult> checkEmailExists(String email) async {
    try {
      // Thử đăng nhập với email và mật khẩu sai để kiểm tra email có tồn tại không
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: 'invalid_password_for_check_123456',
      );
      
      // Nếu đăng nhập thành công (không nên xảy ra), đăng xuất ngay
      await _auth.signOut();
      return ValidationResult(false, 'Email này đã được sử dụng');
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        // Mật khẩu sai nghĩa là email đã tồn tại
        return ValidationResult(false, 'Email này đã được sử dụng');
      } else if (e.code == 'user-not-found') {
        // Email chưa được đăng ký
        return ValidationResult(true, 'Email có thể sử dụng');
      } else if (e.code == 'invalid-email') {
        return ValidationResult(false, 'Email không hợp lệ');
      } else if (e.code == 'too-many-requests') {
        // Quá nhiều request, cho phép tiếp tục
        return ValidationResult(true, '');
      }
      // Các lỗi khác, cho phép tiếp tục để không block user
      return ValidationResult(true, '');
    } catch (e) {
      // Nếu có lỗi network, cho phép tiếp tục
      return ValidationResult(true, '');
    }
  }

  /// Kiểm tra xác nhận mật khẩu
  ValidationResult validatePasswordConfirmation(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return ValidationResult(false, 'Vui lòng xác nhận mật khẩu');
    }

    if (password != confirmPassword) {
      return ValidationResult(false, 'Mật khẩu xác nhận không khớp');
    }

    return ValidationResult(true, '');
  }

  /// Kiểm tra họ tên
  ValidationResult validateFullName(String name) {
    if (name.trim().isEmpty) {
      return ValidationResult(false, 'Vui lòng nhập họ và tên');
    }

    if (name.trim().length < 2) {
      return ValidationResult(false, 'Họ tên phải có ít nhất 2 ký tự');
    }

    if (name.trim().length > 50) {
      return ValidationResult(false, 'Họ tên không được quá 50 ký tự');
    }

    // Kiểm tra ký tự không hợp lệ (chỉ cho phép chữ cái, space, và một số ký tự đặc biệt)
    if (!RegExp(r"^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵýỷỹ\s\-'.]+$").hasMatch(name)) {
      return ValidationResult(false, 'Họ tên chỉ được chứa chữ cái và dấu cách');
    }

    return ValidationResult(true, '');
  }

  /// Kiểm tra toàn bộ form đăng ký
  Future<List<ValidationResult>> validateSignUpForm({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    bool checkEmailExists = true,
  }) async {
    final results = <ValidationResult>[];

    // Kiểm tra từng trường
    results.add(validateFullName(fullName));
    results.add(validateEmail(email));
    results.add(validatePassword(password));
    results.add(validatePasswordConfirmation(password, confirmPassword));

    // Kiểm tra email có tồn tại không (nếu cần)
    if (checkEmailExists && validateEmail(email).isValid) {
      results.add(await this.checkEmailExists(email));
    }

    return results;
  }

  /// Lấy thông báo lỗi đầu tiên từ danh sách validation results
  String? getFirstError(List<ValidationResult> results) {
    for (final result in results) {
      if (!result.isValid) {
        return result.message;
      }
    }
    return null;
  }
}

/// Class để lưu kết quả validation
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);
}