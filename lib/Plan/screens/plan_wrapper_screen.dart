import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/theme/app_theme.dart';
import '../../Core/providers/app_mode_provider.dart';
import '../providers/collaboration_provider.dart';
import 'plan_screen.dart';
import 'collaboration_plan_screen.dart';

/// Wrapper screen that displays either Private or Collaboration plan screen
/// based on current app mode - COMPLETELY SEPARATE SCREENS AND DATA
class PlanWrapperScreen extends StatefulWidget {
  const PlanWrapperScreen({super.key});

  @override
  State<PlanWrapperScreen> createState() => _PlanWrapperScreenState();
}

class _PlanWrapperScreenState extends State<PlanWrapperScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModeProvider>(
      builder: (context, appModeProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Show the appropriate screen based on mode
              if (appModeProvider.isPrivateMode)
                const PlanScreen() // Original private plan screen
              else
                const CollaborationPlanScreen(), // New collaboration plan screen
              
              // Mode switch button - positioned at top right
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: _buildModeToggleButton(appModeProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggleButton(AppModeProvider appModeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showModeSelectionDialog(appModeProvider),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  appModeProvider.isPrivateMode 
                      ? Icons.person 
                      : Icons.group_work,
                  size: 20,
                  color: appModeProvider.isPrivateMode 
                      ? const Color(0xFF1976D2)
                      : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  appModeProvider.isPrivateMode ? 'Private' : 'Collab',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appModeProvider.isPrivateMode 
                        ? const Color(0xFF1976D2)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModeSelectionDialog(AppModeProvider appModeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Choose Plan Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select how you want to plan your trips:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Private Mode Option
            _buildModeOption(
              icon: Icons.person,
              title: 'Private Mode',
              description: 'Plan trips by yourself with personal data storage',
              color: const Color(0xFF1976D2),
              isSelected: appModeProvider.isPrivateMode,
              onTap: () {
                Navigator.pop(context);
                appModeProvider.switchToPrivateMode();
                // _showModeChangedSnackBar('Private Mode');
              },
            ),
            
            const SizedBox(height: 16),
            
            // Collaboration Mode Option
            _buildModeOption(
              icon: Icons.group_work,
              title: 'Collaboration Mode',
              description: 'Plan trips with others, invite collaborators, real-time sync',
              color: AppColors.primary,
              isSelected: appModeProvider.isCollaborationMode,
              onTap: () {
                Navigator.pop(context);
                appModeProvider.switchToCollaborationMode();
                //_showModeChangedSnackBar('Collaboration Mode');
                
                // Initialize collaboration if needed
                _initializeCollaborationMode();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withValues(alpha:0.1) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 20,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.black,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: color,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _showModeChangedSnackBar(String modeName) {
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Row(
  //           children: [
  //             Icon(
  //               modeName.contains('Private') ? Icons.person : Icons.group_work,
  //               color: Colors.white,
  //               size: 20,
  //             ),
  //             const SizedBox(width: 8),
  //             Text('Switched to $modeName'),
  //           ],
  //         ),
  //         backgroundColor: modeName.contains('Private') 
  //             ? const Color(0xFF1976D2)
  //             : AppColors.primary,
  //         duration: const Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }

  void _initializeCollaborationMode() {
    // Initialize collaboration provider when switching to collaboration mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final collaborationProvider = context.read<CollaborationProvider>();
      // Force re-initialization to ensure fresh data load
      collaborationProvider.initialize().then((_) {
        debugPrint('🔄 MODE_SWITCH: Collaboration mode initialized with ${collaborationProvider.totalSharedTrips} trips');
      }).catchError((e) {
        debugPrint('❌ MODE_SWITCH: Failed to initialize collaboration mode: $e');
      });
    });
  }
}