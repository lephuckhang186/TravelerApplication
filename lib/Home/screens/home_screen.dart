import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../Setting/screens/settings_screen.dart';
import '../../Plan/screens/plan_wrapper_screen.dart';
import '../../Analysis/screens/analysis_screen.dart';
import '../../Map/screens/map_screen.dart';
import '../../Core/theme/app_theme.dart';
import '../../Core/providers/app_mode_provider.dart';
import '../../Plan/providers/collaboration_provider.dart';

/// Home Screen - Travel & Tourism Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize collaboration data only once when dependencies are ready
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeCollaborationData();
    }
  }

  /// Initialize collaboration data in background
  Future<void> _initializeCollaborationData() async {
    try {
      final collaborationProvider = context.read<CollaborationProvider>();
      await collaborationProvider.initialize();
      debugPrint('DEBUG: HomeScreen - Collaboration data initialized successfully');
    } catch (e) {
      debugPrint('DEBUG: HomeScreen - Failed to initialize collaboration data: $e');
    }
  }

  List<Widget> get _screens => [
    const PlanWrapperScreen(), // Uses plan wrapper to switch between private/collaboration
    const AnalysisScreen(),
    const MapScreen(),
    const SettingsScreen(), // Used for Me
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [_screens[_currentIndex], _buildBottomNavBar()]),
    );
  }

  Widget _buildBottomNavBar() {
    return Consumer<AppModeProvider>(
      builder: (context, modeProvider, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(20),
            height: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    // Bluebird + Clear skies gradient
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.skyBlue.withValues(alpha: 0.9),
                        AppColors.steelBlue.withValues(alpha: 0.8),
                        AppColors.dodgerBlue.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDynamicNavItem(
                        iconPath: 'images/blueprint.png',
                        label: 'Plan',
                        index: 0,
                        isSelected: _currentIndex == 0,
                      ),
                      _buildDynamicNavItem(
                        iconPath: 'images/analytics.png',
                        label: 'Analysis',
                        index: 1,
                        isSelected: _currentIndex == 1,
                      ),
                      _buildDynamicNavItem(
                        iconPath: 'images/compass.png',
                        label: 'Map',
                        index: 2,
                        isSelected: _currentIndex == 2,
                      ),
                      // Show Me only in Private mode
                      if (!modeProvider.isCollaborationMode)
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
        );
      },
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? AppColors.navyBlue
                      : Colors.white.withValues(alpha: 0.9),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    color: AppColors.navyBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
