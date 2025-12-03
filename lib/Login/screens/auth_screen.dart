import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_user_service.dart';
import 'email_auth_screen.dart';
import 'google_signup_completion_screen.dart';
import '../../Home/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _currentScreen = 'welcome'; // welcome, signup, login

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 'signup':
        return SignUpScreen(
          onBack: () => setState(() => _currentScreen = 'welcome'),
          onLogin: () => setState(() => _currentScreen = 'login'),
        );
      case 'login':
        return LoginScreen(
          onBack: () => setState(() => _currentScreen = 'welcome'),
          onSignUp: () => setState(() => _currentScreen = 'signup'),
        );
      default:
        return WelcomeScreen(
          onSignUp: () => setState(() => _currentScreen = 'signup'),
          onLogin: () => setState(() => _currentScreen = 'login'),
        );
    }
  }
}

// Màn hình chào mừng
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  const WelcomeScreen({
    super.key,
    required this.onSignUp,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'images/logo.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Color(0xFF40E0D0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          size: 80,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Slogan
              const Text(
                'Chuyến đi của bạn,',
                style: TextStyle(
                  color: Color(0xFF40E0D0), // Turquoise text
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'kế hoạch của TripWise',
                style: TextStyle(
                  color: Color(0xFF40E0D0), // Turquoise text
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // const Text(
              //   'Không chỉ là du lịch, là hành trình của chúng ta',
              //   style: TextStyle(
              //     color: Color(0xFF2E8B8B), // Darker turquoise for subtitle
              //     fontSize: 18,
              //     fontWeight: FontWeight.w400,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              const Spacer(flex: 3),

              // Nút Đăng ký miễn phí
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40E0D0), // Turquoise
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 3,
                    shadowColor: const Color(0xFF40E0D0).withOpacity(0.3),
                  ),
                  child: const Text(
                    'Bắt đầu hành trình',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nút Đăng nhập
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF40E0D0), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: Color(0xFF40E0D0),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogin;

  const SignUpScreen({super.key, required this.onBack, required this.onLogin});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final FirestoreUserService _firestoreService = FirestoreUserService();
  bool _isLoading = false;

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);

    try {
      switch (provider) {
        case 'Google':
          final userCredential = await _authService.signInWithGoogle();
          if (userCredential?.user != null) {
            // Kiểm tra xem người dùng đã có profile trong Firestore chưa
            final hasProfile = await _firestoreService.hasUserProfile(
              userCredential!.user!.uid,
            );

            if (mounted) {
              if (!hasProfile) {
                // Người dùng mới - chuyển đến màn hình bổ sung
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GoogleSignupCompletionScreen(
                      user: userCredential.user!,
                    ),
                  ),
                );
              } else {
                // Người dùng cũ - chuyển trực tiếp đến home
                _showSuccessMessage('Đăng nhập thành công!');
                Navigator.of(context).pushReplacementNamed('/home');
              }
            }
          }
          break;
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

  void _navigateToEmailSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailAuthScreen(
          isSignUp: true,
          onBack: () => Navigator.pop(context),
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFF40E0D0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Tiêu đề
              const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  color: Color(0xFF40E0D0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'TripWise',
                style: TextStyle(
                  color: Color(0xFF40E0D0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Nút đăng ký bằng email
              _buildSignUpButton(
                'Tiếp tục bằng email',
                Icons.email_outlined,
                const Color(0xFF40E0D0),
                Colors.white,
                onPressed: _navigateToEmailSignUp,
              ),

              const SizedBox(height: 16),

              // Nút đăng ký bằng Google
              _buildSignUpButton(
                'Tiếp tục bằng Google',
                Icons.g_mobiledata_rounded,
                Colors.transparent,
                const Color(0xFF40E0D0),
                borderColor: const Color(0xFF40E0D0),
                onPressed: () => _handleSocialAuth('Google'),
              ),

              const SizedBox(height: 16),

              const Spacer(),

              // Text "Bạn đã có tài khoản?"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bạn đã có tài khoản? ',
                    style: TextStyle(
                      color: const Color(0xFF2E8B8B).withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onLogin,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: Color(0xFF40E0D0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sẽ được cập nhật sớm!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSignUpButton(
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor, {
    Color? borderColor,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, color: textColor, size: 20),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSignUp;

  const LoginScreen({super.key, required this.onBack, required this.onSignUp});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirestoreUserService _firestoreService = FirestoreUserService();
  bool _isLoading = false;

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);

    try {
      switch (provider) {
        case 'Google':
          final userCredential = await _authService.signInWithGoogle();
          if (userCredential?.user != null) {
            // Kiểm tra xem người dùng đã có profile trong Firestore chưa
            final hasProfile = await _firestoreService.hasUserProfile(
              userCredential!.user!.uid,
            );

            if (mounted) {
              if (!hasProfile) {
                // Người dùng mới - chuyển đến màn hình bổ sung
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GoogleSignupCompletionScreen(
                      user: userCredential.user!,
                    ),
                  ),
                );
              } else {
                // Người dùng cũ - chuyển trực tiếp đến home
                _showSuccessMessage('Đăng nhập thành công!');
                Navigator.of(context).pushReplacementNamed('/home');
              }
            }
          }
          break;
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

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sẽ được cập nhật sớm!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToEmailLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailAuthScreen(
          isSignUp: false,
          onBack: () => Navigator.pop(context),
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFF40E0D0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Tiêu đề
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  color: Color(0xFF40E0D0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'TripWise',
                style: TextStyle(
                  color: Color(0xFF40E0D0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Nút đăng nhập bằng email
              _buildLoginButton(
                'Tiếp tục bằng email',
                Icons.email_outlined,
                const Color(0xFF40E0D0),
                Colors.white,
                onPressed: _navigateToEmailLogin,
              ),

              const SizedBox(height: 16),

              // Nút đăng nhập bằng Google
              _buildLoginButton(
                'Tiếp tục bằng Google',
                Icons.g_mobiledata_rounded,
                Colors.transparent,
                const Color(0xFF40E0D0),
                borderColor: const Color(0xFF40E0D0),
                onPressed: () => _handleSocialAuth('Google'),
              ),

              const SizedBox(height: 16),

              const Spacer(),

              // Text "Bạn chưa có tài khoản?"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bạn chưa có tài khoản? ',
                    style: TextStyle(
                      color: const Color(0xFF2E8B8B).withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onSignUp,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        color: Color(0xFF40E0D0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor, {
    Color? borderColor,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, color: textColor, size: 20),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
