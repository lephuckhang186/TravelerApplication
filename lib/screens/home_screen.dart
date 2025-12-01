import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import '../features/trip_planning/screens/trip_list/plan_screen.dart';
import '../features/expense_management/analysis_screen.dart';
import '../core/theme/app_theme.dart';
import '../features/map/screens/map_screen.dart';

/// Home Screen - Travel & Tourism Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  List<Widget> get _screens => [
    const MapScreen(),
    const PlanScreen(),
    const AnalysisScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar - Dynamic Island Style
  Widget _buildBottomNavBar() {
    return Stack(
      children: [
        // Dynamic Island Navigation Bar - floating above content
        Positioned(
          bottom: 15,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 320,
              height: 60,
              decoration: BoxDecoration(
                // Reduced glassmorphism effect
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.03),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDynamicNavItem(
                          iconPath: 'images/home.png',
                          label: 'Home',
                          index: 0,
                          isSelected: _currentIndex == 0,
                        ),
                        _buildDynamicNavItem(
                          iconPath: 'images/blueprint.png',
                          label: 'Plan',
                          index: 1,
                          isSelected: _currentIndex == 1,
                        ),
                        _buildDynamicNavItem(
                          iconPath: 'images/analytics.png',
                          label: 'Analysis',
                          index: 2,
                          isSelected: _currentIndex == 2,
                        ),
                        _buildDynamicNavItem(
                          iconPath: 'images/account.png',
                          label: 'Me',
                          index: 3,
                          isSelected: _currentIndex == 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicNavItem({
    required String iconPath,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          // Màu xanh ngọc bích khi được chọn
          color: isSelected 
              ? const Color(0xFF00CED1).withValues(alpha: 0.2)  // Dark Turquoise với alpha
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isSelected 
              ? Border.all(
                  color: const Color(0xFF00CED1).withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(0, isSelected ? -2 : 0, 0),
              child: Image.asset(
                iconPath,
                width: isSelected ? 22 : 20,
                height: isSelected ? 22 : 20,
                color: isSelected 
                    ? const Color(0xFF00CED1)  // Dark Turquoise - Selected
                    : Colors.white.withValues(alpha: 0.95),  // Brighter unselected
              ),
            ),
            // Label - chỉ hiện khi được chọn hoặc luôn hiện nhưng nhỏ hơn
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isSelected ? 1.0 : 0.9,  // Increased opacity for unselected
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform: Matrix4.translationValues(0, isSelected ? 1 : 3, 0),
                child: Text(
                  label,
                  style: GoogleFonts.quattrocento(
                    fontSize: isSelected ? 9 : 8,
                    color: isSelected 
                        ? const Color(0xFF00CED1)  // Dark Turquoise - Selected
                        : Colors.white.withValues(alpha: 0.9),  // Brighter unselected
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,  // Medium weight for unselected
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
