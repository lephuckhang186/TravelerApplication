import 'package:flutter/material.dart';
import '../../Analysis/screens/analysis_screen.dart';
import '../../Map/screens/map_screen.dart';

/// Helper class for unified navigation between trip detail screens.
///
/// Provides static methods to navigate to Analysis and Map modules,
/// and builds shared UI components for trip-related navigation.
/// Supports both private trips and collaboration trips.
class TripNavigationHelper {
  /// Navigates the user to the [AnalysisScreen].
  static void navigateToAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisScreen()),
    );
  }

  /// Navigates the user to the [MapScreen].
  static void navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  /// Builds a row of navigation buttons for trip detail screens.
  ///
  /// Currently includes buttons for 'Analysis' and 'Map'.
  static Widget buildNavigationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavigationButton(
          context: context,
          icon: Icons.analytics_outlined,
          label: 'Analysis',
          onPressed: () => navigateToAnalysis(context),
        ),
        _buildNavigationButton(
          context: context,
          icon: Icons.map_outlined,
          label: 'Map',
          onPressed: () => navigateToMap(context),
        ),
      ],
    );
  }

  /// Internal helper to construct a standardized elevated button with an icon.
  static Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
