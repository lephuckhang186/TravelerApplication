import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';
import 'auth_screen.dart';
import '../services/user_service.dart';

/// Modern Loading Screen - Gen Z Vibes 🚀
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _rotationController.repeat();

    // Navigate after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () async {
      if (mounted) {
        final userService = UserService();
        final isLoggedIn = await userService.isLoggedIn();
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                isLoggedIn ? const HomeScreen() : const AuthScreen(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Modern gradient: Purple to Pink (Gen Z vibes) 
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF7A00), // Orange strong
              Color(0xFFFF8A00), // Orange
              Color(0xFFFFA726), // Amber
              Color(0xFFFFE0B2), // Light peach
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating orbs background
            _buildFloatingOrbs(),
            
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Modern logo with rotation
                          _buildModernLogo(),
                          
                          const SizedBox(height: 40),
                          
                          // App name with modern typography
                          Text(
                            'MoneyFlow',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Tagline with gradient text effect
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Colors.white70],
                            ).createShader(bounds),
                            child: Text(
                              'Your Smart Finance Companion 🚀',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Modern loading indicator
                          _buildModernLoader(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Bottom branding
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Powered by AI',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Track expenses • Plan travels • Live freely',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern floating orbs background
  Widget _buildFloatingOrbs() {
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: 50,
          child: _buildOrb(60, Colors.white.withOpacity(0.1)),
        ),
        Positioned(
          top: 200,
          right: 30,
          child: _buildOrb(80, Colors.white.withOpacity(0.05)),
        ),
        Positioned(
          bottom: 150,
          left: 30,
          child: _buildOrb(40, Colors.white.withOpacity(0.08)),
        ),
        Positioned(
          bottom: 300,
          right: 60,
          child: _buildOrb(70, Colors.white.withOpacity(0.06)),
        ),
      ],
    );
  }

  Widget _buildOrb(double size, Color color) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (0.1 * _rotationAnimation.value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  /// Modern logo with rotation effect
  Widget _buildModernLogo() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Colors.white70],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.trending_up,
              size: 50,
              color: Color(0xFFFF5A00),
            ),
          ),
        );
      },
    );
  }

  /// Modern loading indicator with pulsing effect
  Widget _buildModernLoader() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Column(
          children: [
            // Pulsing dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8 + (4 * _rotationAnimation.value),
                  height: 8 + (4 * _rotationAnimation.value),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7 + (0.3 * _rotationAnimation.value)),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Loading text with fade effect
            AnimatedOpacity(
              opacity: 0.5 + (0.5 * _rotationAnimation.value),
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Loading your financial journey...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  height: 1.0, // Line spacing = 5px (tương đương height: 1.0 cho font size 14)
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
