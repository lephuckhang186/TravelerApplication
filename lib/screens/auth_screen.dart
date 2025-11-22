import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'email_auth_screen.dart';
import 'home_screen.dart';

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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 3),
              
              // Logo Spotify
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  size: 40,
                  color: Colors.black,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Slogan
              const Text(
                'Chuyến đi của bạn,',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'kế hoạch của TripWise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không chỉ là du lịch, là hành trình của chúng ta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(flex: 3),
              
              // Nút Đăng ký miễn phí
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ED760), // Spotify green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Bắt đầu hành trình',
                    style: TextStyle(
                      color: Colors.black,
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
                    side: BorderSide(color: Colors.white.withOpacity(0.8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: Colors.white,
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

  const SignUpScreen({
    super.key,
    required this.onBack,
    required this.onLogin,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);
    
    try {
      switch (provider) {
        case 'Google':
          await _authService.signInWithGoogle();
          break;
      }
      
      if (mounted) {
        _showSuccessMessage('Đăng ký thành công!');
        Navigator.of(context).pushReplacementNamed('/home');
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
        backgroundColor: const Color(0xFF1ED760),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  size: 30,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Tiêu đề
              const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'TripWise',
                style: TextStyle(
                  color: Colors.white,
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
                const Color(0xFF1ED760),
                Colors.black,
                onPressed: _navigateToEmailSignUp,
              ),
              
              const SizedBox(height: 16),
              
              
              // Nút đăng ký bằng Google
              _buildSignUpButton(
                'Tiếp tục bằng Google',
                Icons.g_mobiledata_rounded,
                Colors.transparent,
                Colors.white,
                borderColor: Colors.white.withOpacity(0.8),
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
                      color: Colors.white.withOpacity(0.7),
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
                        color: Colors.white,
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

  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onSignUp,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);
    
    try {
      switch (provider) {
        case 'Google':
          await _authService.signInWithGoogle();
          break;
      }
      
      if (mounted) {
        _showSuccessMessage('Đăng nhập thành công!');
        Navigator.of(context).pushReplacementNamed('/home');
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
        backgroundColor: const Color(0xFF1ED760),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  size: 30,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Tiêu đề
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'TripWise',
                style: TextStyle(
                  color: Colors.white,
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
                const Color(0xFF1ED760),
                Colors.black,
                onPressed: _navigateToEmailLogin,
              ),
              
              const SizedBox(height: 16),
              
              
              // Nút đăng nhập bằng Google
              _buildLoginButton(
                'Tiếp tục bằng Google',
                Icons.g_mobiledata_rounded,
                Colors.transparent,
                Colors.white,
                borderColor: Colors.white.withOpacity(0.8),
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
                      color: Colors.white.withOpacity(0.7),
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
                        color: Colors.white,
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