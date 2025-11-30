import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_user_service.dart';
import '../services/auth_validation_service.dart';
import 'home_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  final bool isSignUp;
  final VoidCallback onBack;

  const EmailAuthScreen({
    super.key,
    required this.isSignUp,
    required this.onBack,
  });

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  int _passwordStrength = 0;

  final AuthService _authService = AuthService();
  final FirestoreUserService _firestoreService = FirestoreUserService();
  final AuthValidationService _validationService = AuthValidationService();

  @override
  void initState() {
    super.initState();
    
    // Lắng nghe thay đổi mật khẩu để tính độ mạnh
    _passwordController.addListener(_updatePasswordStrength);
    
    // Lắng nghe thay đổi email để kiểm tra trùng lặp
    if (widget.isSignUp) {
      _emailController.addListener(_checkEmailAvailability);
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    if (widget.isSignUp) {
      _emailController.removeListener(_checkEmailAvailability);
    }
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    if (widget.isSignUp) {
      setState(() {
        _passwordStrength = _validationService.getPasswordStrength(_passwordController.text);
      });
    }
  }

  Future<void> _checkEmailAvailability() async {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && _validationService.validateEmail(email).isValid) {
      setState(() => _isCheckingEmail = true);
      
      try {
        await Future.delayed(const Duration(milliseconds: 500)); // Debounce
        if (_emailController.text.trim() == email) { // Kiểm tra user chưa thay đổi
          final result = await _authService.checkEmailExists(email);
          if (mounted && _emailController.text.trim() == email) {
            if (result['exists'] == true) {
              _showEmailExistsWarning(result['message'] ?? 'Email đã tồn tại');
            }
          }
        }
      } catch (e) {
        // Ignore errors trong kiểm tra real-time
      } finally {
        if (mounted) {
          setState(() => _isCheckingEmail = false);
        }
      }
    }
  }

  void _showEmailExistsWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isSignUp) {
        // Validation chi tiết cho đăng ký
        final validationResults = await _validationService.validateSignUpForm(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          fullName: _nameController.text.trim(),
          checkEmailExists: true,
        );

        // Kiểm tra có lỗi validation không
        final firstError = _validationService.getFirstError(validationResults);
        if (firstError != null) {
          _showErrorMessage(firstError);
          return;
        }

        // Đăng ký với Firebase Auth
        final userCredential = await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        // Lưu thông tin vào Firestore
        if (userCredential?.user != null) {
          await _firestoreService.createEmailUserProfile(
            uid: userCredential!.user!.uid,
            email: _emailController.text.trim(),
            fullName: _nameController.text.trim(),
            dateOfBirth: DateTime(2000, 1, 1), // Ngày mặc định
          );
        }
        
        _showSuccessMessage('Đăng ký thành công!');
      } else {
        // Validation cơ bản cho đăng nhập
        final emailValidation = _validationService.validateEmail(_emailController.text.trim());
        if (!emailValidation.isValid) {
          _showErrorMessage(emailValidation.message);
          return;
        }

        if (_passwordController.text.isEmpty) {
          _showErrorMessage('Vui lòng nhập mật khẩu');
          return;
        }

        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        _showSuccessMessage('Đăng nhập thành công!');
      }
      
      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF40E0D0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF40E0D0)),
          onPressed: widget.onBack,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // Title
                Text(
                  widget.isSignUp ? 'Tạo tài khoản của bạn' : 'Đăng nhập vào tài khoản của bạn',
                  style: const TextStyle(
                    color: Color(0xFF40E0D0),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Name field (chỉ hiện khi đăng ký)
                if (widget.isSignUp) ...[
                  _buildLabel('Họ và tên'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Nhập họ và tên',
                    validator: (value) {
                      final validation = _validationService.validateFullName(value ?? '');
                      return validation.isValid ? null : validation.message;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Email field
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Nhập email của bạn',
                  keyboardType: TextInputType.emailAddress,
                  suffixIcon: _isCheckingEmail 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                  validator: (value) {
                    final validation = _validationService.validateEmail(value ?? '');
                    return validation.isValid ? null : validation.message;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Password field
                _buildLabel('Mật khẩu'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Nhập mật khẩu',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (widget.isSignUp) {
                      final validation = _validationService.validatePassword(value ?? '');
                      return validation.isValid ? null : validation.message;
                    } else {
                      return (value?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu' : null;
                    }
                  },
                ),
                
                // Password strength indicator (chỉ hiện khi đăng ký)
                if (widget.isSignUp && _passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrengthIndicator(),
                ],
                
                // Confirm password field (chỉ hiện khi đăng ký)
                if (widget.isSignUp) ...[
                  const SizedBox(height: 20),
                  _buildLabel('Xác nhận mật khẩu'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Nhập lại mật khẩu',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    validator: (value) {
                      final validation = _validationService.validatePasswordConfirmation(
                        _passwordController.text, value ?? ''
                      );
                      return validation.isValid ? null : validation.message;
                    },
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF40E0D0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 3,
                      shadowColor: const Color(0xFF40E0D0).withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.isSignUp ? 'Tạo tài khoản' : 'Đăng nhập',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                // Forgot password (chỉ hiện khi đăng nhập)
                if (!widget.isSignUp) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => _handleForgotPassword(),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Color(0xFF40E0D0),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF40E0D0),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF2E8B8B)),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF40E0D0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(color: Color(0xFF40E0D0)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập email để nhận link đặt lại mật khẩu:',
              style: TextStyle(color: Color(0xFF2E8B8B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Color(0xFF2E8B8B)),
              decoration: InputDecoration(
                hintText: 'Email của bạn',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF40E0D0), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_emailController.text.isNotEmpty) {
                try {
                  await _authService.sendPasswordResetEmail(_emailController.text.trim());
                  Navigator.pop(context);
                  _showSuccessMessage('Email đặt lại mật khẩu đã được gửi!');
                } catch (e) {
                  _showErrorMessage(e.toString());
                }
              }
            },
            child: const Text(
              'Gửi',
              style: TextStyle(color: Color(0xFF40E0D0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final color = _validationService.getPasswordStrengthColor(_passwordStrength);
    final text = _validationService.getPasswordStrengthText(_passwordStrength);
    final progress = _passwordStrength / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Độ mạnh mật khẩu: ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${_passwordStrength}%',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
        if (_passwordStrength < 60 && _passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Để tăng độ mạnh mật khẩu:',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ..._getPasswordSuggestions().map((suggestion) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '• $suggestion',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _getPasswordSuggestions() {
    final password = _passwordController.text;
    final suggestions = <String>[];

    if (password.length < 12) {
      suggestions.add('Tăng độ dài (tối thiểu 12 ký tự)');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      suggestions.add('Thêm chữ thường (a-z)');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      suggestions.add('Thêm chữ hoa (A-Z)');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      suggestions.add('Thêm số (0-9)');
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      suggestions.add('Thêm ký tự đặc biệt (!@#\$...)');
    }

    return suggestions.take(3).toList(); // Chỉ hiển thị tối đa 3 gợi ý
  }
}