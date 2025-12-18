import 'package:flutter/material.dart';
import '../../Analysis/screens/analysis_screen.dart';
import '../../Map/screens/map_screen.dart';

/// Helper class for unified navigation between trip detail screens
/// Supports both private trips (TripModel) and collaboration trips (SharedTripModel)
class TripNavigationHelper {
  /// Navigate to Analysis screen
  static void navigateToAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalysisScreen(),
      ),
    );
  }

  /// Navigate to Map screen
  static void navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );
  }

  /// Build navigation buttons for trip detail screens
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
        // Add more navigation buttons here as needed
      ],
    );
  }

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
