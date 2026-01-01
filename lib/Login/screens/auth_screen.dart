import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_user_service.dart';
import '../services/auth_validation_service.dart';
import 'google_signup_completion_screen.dart';

/// The main authentication entry point controller.
///
/// Manages navigation between the [WelcomeScreen] (skipped), [LoginScreen], and [SignUpScreen].
/// Maintains the current screen state.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Directly start with logic since Welcome screen is currently bypassed in logic
  String _currentScreen = 'login';

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 'signup':
        return SignUpScreen(
          onBack: () => setState(() => _currentScreen = 'login'),
          onLogin: () => setState(() => _currentScreen = 'login'),
        );
      case 'login':
      default:
        return LoginScreen(
          onBack: () => Navigator.pop(context), // Go back to previous screen
          onSignUp: () => setState(() => _currentScreen = 'signup'),
        );
    }
  }
}

/// A welcome screen displaying the app logo and entry options.
///
/// Currently not active in the main flow but preserved for potential use.
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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
                        color: Colors.black.withValues(alpha: 0.1),
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

                const SizedBox(height: 16),

                const Spacer(flex: 3),

                // Sign Up Button
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
                      shadowColor: const Color(
                        0xFF40E0D0,
                      ).withValues(alpha: 0.3),
                    ),
                    child: const Text(
                      'Begin the journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onLogin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF40E0D0),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: const Text(
                      'Log in',
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
      ),
    );
  }
}

/// The screen for new user registration.
///
/// Handles email/password sign-up with validation for:
/// - Username (non-empty)
/// - Email format
/// - Password strength
/// - Password confirmation
class SignUpScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogin;

  const SignUpScreen({super.key, required this.onBack, required this.onLogin});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  final bool _isCheckingEmail = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;

  final AuthService _authService = AuthService();
  final FirestoreUserService _firestoreService = FirestoreUserService();
  final AuthValidationService _validationService = AuthValidationService();

  @override
  void initState() {
    super.initState();
    // Listen to password changes to calculate strength
    _passwordController.addListener(_updatePasswordStrength);
    // Email checking is currently disabled for debug purposes
    // _emailController.addListener(_checkEmailAvailability);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = _validationService.getPasswordStrength(
        _passwordController.text,
      );
    });
  }

  /// Handles the email sign-up process.
  ///
  /// Validates input, creates Auth user, creates Firestore profile, and navigates home.
  Future<void> _handleEmailSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() => _isLoading = true);
    try {
      // Validate username
      if (username.isEmpty) {
        _showErrorMessage('Please enter your username');
        return;
      }

      // Advanced validation using validation service
      final validationResults = await _validationService.validateSignUpForm(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: username, // Use username from form
        checkEmailExists: true,
      );

      // Check for validation errors
      final firstError = _validationService.getFirstError(validationResults);
      if (firstError != null) {
        _showErrorMessage(firstError);
        return;
      }

      // Sign up with Firebase Auth
      final userCredential = await _authService.signUpWithEmail(
        email,
        password,
      );

      // Save user profile to Firestore
      if (userCredential?.user != null) {
        try {
          await _firestoreService.createEmailUserProfile(
            uid: userCredential!.user!.uid,
            email: email,
            fullName: username, // Use username from form
            dateOfBirth: DateTime(2000, 1, 1), // Default date
          );
        } catch (firestoreError) {
          // Allow use of app even if profile sync fails, notify user
          _showErrorMessage(
            'Account created but profile sync failed. You can update it later.',
          );
        }

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Clean up error message
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }

      _showErrorMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Title
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),

                const SizedBox(height: 10),

                // Username input
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Urbanist-Regular',
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                // Email input
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Urbanist-Regular',
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      suffixIcon: _isCheckingEmail
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                // Password input
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Urbanist-Regular',
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                // Re-enter Password input
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Re-enter Password',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Urbanist-Regular',
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                // Password strength indicator
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrengthIndicator(),
                ],

                const SizedBox(height: 20),
                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailSignUp,
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.hovered)) {
                              // Bluebird + Clear Skies gradient effect on hover
                              return const Color(
                                0xFF87CEEB,
                              ); // AppColors.skyBlue
                            }
                            if (states.contains(WidgetState.pressed)) {
                              return const Color(
                                0xFF4682B4,
                              ); // AppColors.steelBlue
                            }
                            return Colors.white.withValues(alpha: 0.9);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.hovered) ||
                                states.contains(WidgetState.pressed)) {
                              return Colors
                                  .white; // White text on blue background
                            }
                            return Colors.black87; // Default black text
                          }),
                        ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.blue)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Urbanist-Regular',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // Text "Already have an account?"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontFamily: 'Urbanist-Regular',
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onLogin,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontFamily: 'Urbanist-Regular',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final color = _validationService.getPasswordStrengthColor(
      _passwordStrength,
    );
    final text = _validationService.getPasswordStrengthText(_passwordStrength);
    final progress = _passwordStrength / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontFamily: 'Urbanist-Regular',
              ),
            ),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Urbanist-Regular',
              ),
            ),
            const Spacer(),
            Text(
              '$_passwordStrength%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontFamily: 'Urbanist-Regular',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }
}

/// The screen for existing user login.
///
/// Supports email/password login and social login (Google).
/// Includes Forgot Password functionality.
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
  final AuthValidationService _validationService = AuthValidationService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  bool _hasEmailError = false;
  bool _obscurePassword = true;

  /// Handles social login methods.
  ///
  /// Currently supports Google.
  /// Checks if the user needs to complete profile registration.
  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);

    try {
      switch (provider) {
        case 'Google':
          final userCredential = await _authService.signInWithGoogle();
          if (userCredential?.user != null) {
            // Check if user has a profile in Firestore
            final hasProfile = await _firestoreService.hasUserProfile(
              userCredential!.user!.uid,
            );

            if (mounted) {
              if (!hasProfile) {
                // New user - redirect to completion screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GoogleSignupCompletionScreen(
                      user: userCredential.user!,
                    ),
                  ),
                );
              } else {
                // Existing user - redirect to home
                Navigator.of(context).pushReplacementNamed('/home');
              }
            }
          }
          // User cancelled - do nothing
          break;
      }
    } catch (e) {
      // Only show error if not popup_closed (user cancelled)
      if (!e.toString().contains('popup_closed')) {
        _showErrorMessage(e.toString());
      }
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handles email/password login.
  ///
  /// Validates inputs and interacts with Firebase Auth.
  /// Handles various auth errors (user not found, wrong password, etc.).
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Enhanced validation using validation service
    final emailValidation = _validationService.validateEmail(email);
    if (!emailValidation.isValid) {
      _showErrorMessage(emailValidation.message);
      return;
    }

    if (password.isEmpty) {
      _showErrorMessage('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // First try to login
      final userCredential = await _authService.signInWithEmail(
        email,
        password,
      );

      if (userCredential?.user != null && mounted) {
        // No success message needed, just navigate
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Clean up error message
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }

      // Handle specific errors with inline display
      if (errorMessage.contains('user-not-found') ||
          errorMessage.contains('invalid-credential') ||
          errorMessage.contains('wrong-password') ||
          errorMessage.contains('invalid-password') ||
          errorMessage.contains('invalid-email')) {
        setState(() {
          _emailError = 'Invalid email or password';
          _hasEmailError = true;
        });
      } else {
        // Other errors use SnackBar
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows the Forgot Password dialog.
  ///
  /// Allows submitting an email to receive a password reset link.
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF87CEEB), // AppColors.skyBlue
                Color(0xFF4682B4), // AppColors.steelBlue
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Forgot Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Urbanist-Regular',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your email to receive a password reset link:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Urbanist-Regular',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Urbanist-Regular',
                ),
                decoration: InputDecoration(
                  hintText: 'Your email',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontFamily: 'Urbanist-Regular',
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Urbanist-Regular',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_emailController.text.isNotEmpty) {
                          try {
                            await _authService.sendPasswordResetEmail(
                              _emailController.text.trim(),
                            );
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                            _showSuccessMessage('Password reset email sent!');
                          } catch (e) {
                            if (!mounted) return;
                            _showErrorMessage(e.toString());
                          }
                        } else {
                          _showErrorMessage('Please enter your email');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4682B4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: 'Urbanist-Regular',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Title
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),

                const SizedBox(height: 10),

                // Email input
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Urbanist-Regular',
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasEmailError
                              ? Colors.red
                              : Colors.white.withValues(alpha: 0.3),
                          width: _hasEmailError ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasEmailError
                              ? Colors.red
                              : Colors.white.withValues(alpha: 0.3),
                          width: _hasEmailError ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasEmailError ? Colors.red : Colors.white,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                // Email error message
                if (_hasEmailError && _emailError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      _emailError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'Urbanist-Regular',
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),
                // Password input
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Urbanist-Regular',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Urbanist-Regular',
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Urbanist-Regular',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sign In button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailLogin,
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.hovered)) {
                              // Bluebird + Clear Skies gradient effect on hover
                              return const Color(
                                0xFF87CEEB,
                              ); // AppColors.skyBlue
                            }
                            if (states.contains(WidgetState.pressed)) {
                              return const Color(
                                0xFF4682B4,
                              ); // AppColors.steelBlue
                            }
                            return Colors.white.withValues(alpha: 0.9);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.hovered) ||
                                states.contains(WidgetState.pressed)) {
                              return Colors
                                  .white; // White text on blue background
                            }
                            return Colors.black87; // Default black text
                          }),
                        ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.blue)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Urbanist-Regular',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                // OR divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Social login icons
                Center(
                  child: GestureDetector(
                    onTap: () => _handleSocialAuth('Google'),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'images/google_login.png',
                        width: 30,
                        height: 30,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.g_mobiledata,
                            size: 30,
                            color: Colors.red,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Text "Don't have an account?"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontFamily: 'Urbanist-Regular',
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onSignUp,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontFamily: 'Urbanist-Regular',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
