import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service for validating authentication inputs like email and password.
///
/// Provides methods to validate email format, password strength, and check for
/// duplicate accounts via Firebase.
class AuthValidationService {
  static final AuthValidationService _instance =
      AuthValidationService._internal();

  /// Factory constructor for singleton instance.
  factory AuthValidationService() => _instance;

  AuthValidationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validates an email address.
  ///
  /// Checks for:
  /// - Non-empty input
  /// - Standard email regex format
  /// - Temporary/disposable email domains
  ///
  /// Returns a [ValidationResult] indicating validity and error message.
  ValidationResult validateEmail(String email) {
    if (email.trim().isEmpty) {
      return ValidationResult(false, 'Vui lòng nhập email');
    }

    // Basic email regex check
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult(false, 'Email không đúng định dạng');
    }

    // Check for temporary email domains
    final emailParts = email.trim().split('@');
    if (emailParts.length == 2) {
      final domain = emailParts[1].toLowerCase();
      final blockedDomains = [
        'tempmail.com',
        '10minutemail.com',
        'guerrillamail.com',
      ];
      if (blockedDomains.contains(domain)) {
        return ValidationResult(
          false,
          'Email tạm thời không được phép sử dụng',
        );
      }
    }

    return ValidationResult(true, '');
  }

  /// Validates password strength and requirements.
  ///
  /// Checks for:
  /// - Minimum length (8 chars)
  /// - Maximum length (128 chars)
  /// - Character variety (lowercase, uppercase, numbers, special chars)
  /// - Common/weak password patterns
  ///
  /// Returns a [ValidationResult] with specific error messages for missing requirements.
  ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, 'Vui lòng nhập mật khẩu');
    }

    // Check minimum length
    if (password.length < 8) {
      return ValidationResult(false, 'Mật khẩu phải có ít nhất 8 ký tự');
    }

    // Check maximum length
    if (password.length > 128) {
      return ValidationResult(false, 'Mật khẩu không được quá 128 ký tự');
    }

    // List of missing requirements
    final requirements = <String>[];

    // Check for lowercase
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      requirements.add('chữ thường (a-z)');
    }

    // Check for uppercase
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      requirements.add('chữ hoa (A-Z)');
    }

    // Check for digits
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      requirements.add('số (0-9)');
    }

    // Check for special characters
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      requirements.add('ký tự đặc biệt (!@#\$%^&*)');
    }

    // Check against common weak passwords
    final commonPasswords = [
      'password',
      '123456789',
      'qwertyuiop',
      'abc123456',
      'password123',
      '123456780',
      'admin123',
      'user123',
      'welcome123',
      'changeme123',
    ];

    if (commonPasswords.contains(password.toLowerCase())) {
      return ValidationResult(false, 'Mật khẩu này quá phổ biến và dễ đoán');
    }

    if (requirements.isNotEmpty) {
      return ValidationResult(
        false,
        'Mật khẩu cần có: ${requirements.join(', ')}',
      );
    }

    return ValidationResult(true, '');
  }

  /// Calculates a password strength score (0-100).
  ///
  /// Points are awarded for length, character variety, and penalized for repetitive patterns.
  int getPasswordStrength(String password) {
    int score = 0;

    // Length score
    if (password.length >= 8) {
      score += 20;
    }
    if (password.length >= 12) {
      score += 10;
    }
    if (password.length >= 16) {
      score += 10;
    }

    // Character type score
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 10;
    }
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 10;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) {
      score += 10;
    }
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score += 15;
    }

    // Variety score
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= 6) {
      score += 10;
    }
    if (uniqueChars >= 10) {
      score += 5;
    }

    // Penalties for patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      score -= 10; // aaa, 111
    }
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) {
      score -= 5;
    }
    if (RegExp(
      r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)',
    ).hasMatch(password.toLowerCase())) {
      score -= 5;
    }

    return score.clamp(0, 100);
  }

  /// Returns a color representing the password strength.
  Color getPasswordStrengthColor(int strength) {
    if (strength < 30) return Colors.red;
    if (strength < 60) return Colors.orange;
    if (strength < 80) return Colors.yellow;
    return Colors.green;
  }

  /// Returns a text description of the password strength.
  String getPasswordStrengthText(int strength) {
    if (strength < 30) return 'Yếu';
    if (strength < 60) return 'Trung bình';
    if (strength < 80) return 'Khá';
    return 'Mạnh';
  }

  /// Checks if an email is already registered in Firebase.
  ///
  /// This is a workaround method that attempts a sign-in with a dummy password.
  /// If the error is 'wrong-password', the user exists.
  ///
  /// Returns [ValidationResult] (false if email is taken).
  Future<ValidationResult> checkEmailExists(String email) async {
    try {
      // Try to sign in with invalid password to check if user exists
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: 'invalid_password_for_check_123456',
      );

      // If login successful (unlikely), sign out immediately
      await _auth.signOut();
      return ValidationResult(false, 'Email này đã được sử dụng');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        // Wrong password means user exists
        return ValidationResult(false, 'Email này đã được sử dụng');
      } else if (e.code == 'user-not-found') {
        // User not found means email is available
        return ValidationResult(true, 'Email có thể sử dụng');
      } else if (e.code == 'invalid-email') {
        return ValidationResult(false, 'Email không hợp lệ');
      } else if (e.code == 'too-many-requests') {
        // Too many requests, allow proceeding to avoid blocking
        return ValidationResult(true, '');
      }
      // Other errors, allow proceeding
      return ValidationResult(true, '');
    } catch (e) {
      // Network errors, allow proceeding
      return ValidationResult(true, '');
    }
  }

  /// Validates that the confirmation password matches the original.
  ValidationResult validatePasswordConfirmation(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return ValidationResult(false, 'Vui lòng xác nhận mật khẩu');
    }

    if (password != confirmPassword) {
      return ValidationResult(false, 'Mật khẩu xác nhận không khớp');
    }

    return ValidationResult(true, '');
  }

  /// Validates the user's full name.
  ///
  /// Checks length (2-50 chars) and allows only valid characters (letters, spaces, basic punctuation).
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

    // Check for invalid characters (letters, spaces, specific punctuation allowed)
    if (!RegExp(
      r"^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵýỷỹ\s\-'.]+$",
    ).hasMatch(name)) {
      return ValidationResult(
        false,
        'Họ tên chỉ được chứa chữ cái và dấu cách',
      );
    }

    return ValidationResult(true, '');
  }

  /// Validates the entire sign-up form.
  ///
  /// Aggregates results from individual field validations.
  /// Optionally performs an async email existence check.
  Future<List<ValidationResult>> validateSignUpForm({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    bool checkEmailExists = true,
  }) async {
    final results = <ValidationResult>[];

    // Validate fields
    results.add(validateFullName(fullName));
    results.add(validateEmail(email));
    results.add(validatePassword(password));
    results.add(validatePasswordConfirmation(password, confirmPassword));

    // Check if email exists
    if (checkEmailExists && validateEmail(email).isValid) {
      results.add(await this.checkEmailExists(email));
    }

    return results;
  }

  /// Returns the first error message from a list of validation results.
  String? getFirstError(List<ValidationResult> results) {
    for (final result in results) {
      if (!result.isValid) {
        return result.message;
      }
    }
    return null;
  }
}

/// Helper class to store validation success status and error messages.
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);
}
