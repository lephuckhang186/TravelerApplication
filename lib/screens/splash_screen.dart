import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Tạo animation controller cho fade in
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Tạo animation fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Bắt đầu animation
    _fadeController.forward();

    // Tự động chuyển màn hình sau 3 giây
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToMain();
      }
    });
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
            image: AssetImage('images/loading.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                // Overlay mờ để text dễ đọc
                // Loại bỏ overlay đen để giữ hình ảnh sáng
                child: Positioned.fill(
                  child: Align(
                    alignment: Alignment(0.0, 0.4),
                    child: Transform.scale(
                      scale: 1.5, // Tăng kích thước lên 1.5 lần
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 4, // Cũng tăng độ dày của vòng tròn
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
