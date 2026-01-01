import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_user_service.dart';
import '../../Home/screens/home_screen.dart';
import '../../Core/theme/app_theme.dart';

/// Screen displayed after a user signs in with Google for the first time.
///
/// Requires the user to confirm or enter their full name to complete the registration.
/// Creates the user's profile in Firestore upon completion.
class GoogleSignupCompletionScreen extends StatefulWidget {
  /// The Firebase user object returned from Google Sign-In.
  final User user;

  const GoogleSignupCompletionScreen({super.key, required this.user});

  @override
  State<GoogleSignupCompletionScreen> createState() =>
      _GoogleSignupCompletionScreenState();
}

class _GoogleSignupCompletionScreenState
    extends State<GoogleSignupCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  final FirestoreUserService _firestoreService = FirestoreUserService();

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google account if available
    _fullNameController.text = widget.user.displayName ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  /// Handles the completion of the signup process.
  ///
  /// Validates the form, creates a Firestore profile, and navigates to [HomeScreen].
  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user profile in Firestore
      await _firestoreService.createGoogleUserProfile(
        uid: widget.user.uid,
        email: widget.user.email ?? '',
        fullName: _fullNameController.text.trim(),
        dateOfBirth: DateTime(2000, 1, 1), // Default date, can be updated later
      );

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.steelBlue, // #87CEEB - Sky Blue (top)
              AppColors.surface, // #F0F8FF - Alice Blue (bottom)
            ],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 150),
                      // Header
                      const Text(
                        'Registration completed.',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please enter your full name to complete your account.',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      // Full Name Input
                      const Text(
                        'Full name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Urbanist-Regular',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your first and last name',
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
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your first and last name.';
                          }
                          if (value.trim().length < 2) {
                            return 'Full names must have at least two characters.';
                          }
                          return null;
                        },
                      ),

                      // Email (readonly)
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.user.email ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Urbanist-Regular',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Complete Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeSignup,
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.9,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ).copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.hovered,
                                      )) {
                                        return const Color(
                                          0xFF87CEEB,
                                        ); // AppColors.skyBlue
                                      }
                                      if (states.contains(
                                        WidgetState.pressed,
                                      )) {
                                        return const Color(
                                          0xFF4682B4,
                                        ); // AppColors.steelBlue
                                      }
                                      return Colors.white.withValues(
                                        alpha: 0.9,
                                      );
                                    }),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                            WidgetState.hovered,
                                          ) ||
                                          states.contains(
                                            WidgetState.pressed,
                                          )) {
                                        return Colors.white;
                                      }
                                      return const Color(
                                        0xFF1E90FF,
                                      ); // AppColors.primary
                                    }),
                              ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1E90FF),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Registration completed.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Urbanist-Regular',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
