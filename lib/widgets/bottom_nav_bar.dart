import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Modern Bottom Navigation Bar - MoMo Style 🔥
class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.support.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                isSelected: widget.currentIndex == 0,
                color: AppColors.accent,
              ),
              _buildNavItem(
                icon: Icons.event_note_outlined,
                activeIcon: Icons.event_note,
                label: 'Plan',
                index: 1,
                isSelected: widget.currentIndex == 1,
                color: AppColors.accent,
              ),
              _buildNavItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                label: 'Analysis',
                index: 2,
                isSelected: widget.currentIndex == 2,
                color: AppColors.accent,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person,
                label: 'Me',
                index: 3,
                isSelected: widget.currentIndex == 3,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        widget.onTap(index);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.currentIndex == index ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon với background gradient khi selected
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color, color.withValues(alpha: 0.7)],
                            )
                          : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? activeIcon : icon,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? AppColors.textOnAccent
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Label với animation - chỉ hiện khi selected
                  SizedBox(
                    height: 14,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: isSelected
                          ? Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
