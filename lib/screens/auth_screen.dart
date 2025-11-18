/// Import necessary packages for authentication functionality
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'package:bcrypt/bcrypt.dart';

/// AuthScreen - Main authentication screen for the TripWise app
/// 
/// This screen provides both login and registration functionality with:
/// - Form validation
/// - Password security features (bcrypt hashing)
/// - Login attempt limiting (3 attempts with 30s lockout)
/// - Smooth animations and modern UI
/// - Forgot password functionality
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  /// UI state variables
  bool _isLogin = true; /// Toggle between login and registration mode
  bool _isLoading = false; /// Loading state for async operations
  bool _obscurePassword = true; /// Password visibility toggle
  bool _obscureConfirmPassword = true; /// Confirm password visibility toggle
  
  /// Form controllers and validation
  final _formKey = GlobalKey<FormState>(); /// Form validation key
  final _usernameController = TextEditingController(); /// Username input controller
  final _passwordController = TextEditingController(); /// Password input controller
  final _confirmPasswordController = TextEditingController(); /// Confirm password input controller
  
  /// Security features: Login attempt limiting
  int _failCount = 0; /// Number of failed login attempts
  DateTime? _lockUntil; /// Timestamp when login will be unlocked
  
  /// Animation controllers for smooth UI transitions
  late AnimationController _fadeController; /// Controls fade-in animation
  late Animation<double> _fadeAnimation; /// Fade animation definition

  /// Initialize animation controllers and start fade-in animation
  /// when the widget is first created
  @override
  void initState() {
    super.initState();
    /// Setup fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    /// Create smooth fade-in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    /// Start the fade-in animation
    _fadeController.forward();
  }

  /// Clean up resources when the widget is disposed
  /// to prevent memory leaks
  @override
  void dispose() {
    _fadeController.dispose(); /// Dispose animation controller
    _usernameController.dispose(); /// Dispose text controllers
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Main build method that creates the authentication screen UI
  /// with gradient background, fade animation, and responsive layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        /// Purple gradient background for modern look
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7B61FF), /// Primary purple
              Color(0xFF9B7FFF), /// Mid-tone purple
              Color(0xFFE8E0FF), /// Light purple
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation, /// Apply fade-in animation
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  /// App logo, title and subtitle
                  _buildHeader(),
                  
                  const SizedBox(height: 60),
                  
                  /// Main authentication form (login/register)
                  _buildAuthForm(),
                  
                  const SizedBox(height: 30),
                  
                  /// Button to switch between login and register modes
                  _buildToggleButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section with app logo, title, and subtitle
  /// Changes subtitle text based on login/register mode
  Widget _buildHeader() {
    return Column(
      children: [
        /// App logo container with circular design and shadow
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.trending_up, /// Travel/growth icon representing the app's purpose
            size: 40,
            color: Color(0xFF7B61FF),
          ),
        ),
        const SizedBox(height: 24),
        /// App title with custom font styling
        Text(
          'TripWise',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        /// Dynamic subtitle that changes based on current mode
        Text(
          _isLogin ? 'Đăng nhập vào tài khoản' : 'Tạo tài khoản mới',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Builds the main authentication form container
  /// Dynamically shows/hides fields based on login/register mode
  /// Includes validation, password visibility toggles, and submit button
  Widget _buildAuthForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      /// White card container with rounded corners and shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey, /// Form validation key
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Username input field with validation
            _buildTextField(
              controller: _usernameController,
              label: 'Tên đăng nhập',
              icon: Icons.person,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập tên đăng nhập';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            /// Password field with visibility toggle and validation
            _buildTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (value!.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }
                return null;
              },
            ),
            
            /// Confirm password field - only shown in registration mode
            if (!_isLogin) ...[
              const SizedBox(height: 20),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],
            
            const SizedBox(height: 16),
            
            /// Forgot password link - only shown in login mode
            if (_isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: Text(
                    'Quên mật khẩu?',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7B61FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF7B61FF),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            /// Submit button with loading state
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit, /// Disable when loading
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isLogin ? 'Đăng nhập' : 'Đăng ký', /// Dynamic button text
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build consistent styled text input fields
  /// 
  /// [controller] - TextEditingController for the input field
  /// [label] - Display label for the field
  /// [icon] - Prefix icon to display
  /// [obscureText] - Whether to hide text (for passwords)
  /// [suffixIcon] - Optional suffix icon (e.g., visibility toggle)
  /// [validator] - Validation function for form validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
        suffixIcon: suffixIcon,
        /// Default border style
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        /// Focused border style with purple accent
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
        ),
        /// Enabled border style
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        filled: true,
        fillColor: Colors.grey[50], /// Light background fill
      ),
    );
  }

  /// Builds the toggle button that allows switching between login and register modes
  /// Also clears form data and resets security counters when switching
  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// Contextual text based on current mode
        Text(
          _isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        /// Clickable toggle button
        GestureDetector(
          onTap: () => setState(() {
            _isLogin = !_isLogin; /// Switch between login/register
            /// Clear all form fields to prevent data confusion
            _usernameController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            /// Reset security features when switching modes
            _failCount = 0;
            _lockUntil = null;
          }),
          child: Text(
            _isLogin ? 'Đăng ký ngay' : 'Đăng nhập', /// Dynamic button text
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Handles form submission for both login and registration
  /// 
  /// Security features:
  /// - Form validation before processing
  /// - Login attempt limiting (3 attempts with 30s lockout)
  /// - Password hashing for registration using bcrypt
  /// - Raw password for login (server handles bcrypt comparison)
  /// 
  /// Flow:
  /// 1. Validate form inputs
  /// 2. Check for login lockout (if in login mode)
  /// 3. Call appropriate service method (login/register)
  /// 4. Handle success/failure with appropriate UI feedback
  /// 5. Navigate to home screen on success
  void _handleSubmit() async {
    /// Validate form before proceeding
    if (!_formKey.currentState!.validate()) return;

    /// Security: Check if login is temporarily locked due to failed attempts
    if (_isLogin && _lockUntil != null && DateTime.now().isBefore(_lockUntil!)) {
      final remainingSeconds = _lockUntil!.difference(DateTime.now()).inSeconds;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bạn đã nhập sai quá nhiều. Vui lòng thử lại sau $remainingSeconds giây.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    /// Show loading state
    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      bool success;
      String message;

      if (_isLogin) {
        /// LOGIN FLOW: Send raw password - server handles bcrypt comparison
        success = await userService.login(username, password);
        message = success ? 'Đăng nhập thành công!' : 'Tên đăng nhập hoặc mật khẩu không đúng';
        
        if (success) {
          /// Reset security counters on successful login
          _failCount = 0;
          _lockUntil = null;
          /// Load user data after successful login
          await userService.init();
        } else {
          /// Handle failed login attempts with progressive security
          _failCount += 1;
          if (_failCount >= 3) {
            /// Lock login for 30 seconds after 3 failed attempts
            _lockUntil = DateTime.now().add(const Duration(seconds: 30));
            _failCount = 0;
            message = 'Bạn đã nhập sai 3 lần. Hãy thử lại sau 30 giây.';
          } else {
            message = 'Sai mật khẩu. Bạn còn ${3 - _failCount} lần.';
          }
        }
      } else {
        /// REGISTRATION FLOW: Hash password before sending to server
        final hashed = BCrypt.hashpw(password, BCrypt.gensalt());
        success = await userService.register(username, hashed);
        message = success ? 'Đăng ký thành công!' : 'Tên đăng nhập đã tồn tại';
        
        if (success) {
          /// Save user data to local storage
          await userService.saveUserToJson(username, hashed, '');
          
          /// Auto-login after successful registration
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setBool('isLoggedIn', true);
          
          /// Load user data after registration
          await userService.init();
        }
      }

      /// Handle successful authentication
      if (success) {
        if (mounted) {
          /// Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
          
          /// Navigate to main app screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        /// Show error message for failed authentication
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      /// Handle unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra, vui lòng thử lại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      /// Always hide loading state when done
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows a dialog for resetting forgotten passwords
  /// 
  /// Features:
  /// - Form validation for username and new password
  /// - Password confirmation matching
  /// - bcrypt hashing before sending to server
  /// - Loading states and error handling
  /// - Success/failure feedback via SnackBars
  void _showForgotPasswordDialog() {
    /// Local controllers for the dialog form
    final usernameController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Đặt lại mật khẩu',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7B61FF),
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Instructions for the user
                Text(
                  'Nhập tên đăng nhập và mật khẩu mới',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                /// Username input field
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập',
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF7B61FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                /// New password input field
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF7B61FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value!.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                /// Confirm password input field
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7B61FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            /// Cancel button
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            /// Submit button with loading state
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setState(() => isLoading = true);

                try {
                  final userService = UserService();
                  /// Hash the new password before sending to server
                  final hashedNew = BCrypt.hashpw(newPasswordController.text, BCrypt.gensalt());
                  final success = await userService.resetPassword(
                    usernameController.text.trim(),
                    hashedNew,
                  );

                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt lại mật khẩu thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tên đăng nhập không tồn tại'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Có lỗi xảy ra, vui lòng thử lại'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Đặt lại', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}