import '../models/activity_models.dart';

/// Service for AI-powered plan editing with natural language processing
class AIPlanEditorService {
  // For demo purposes, we'll simulate successful operations
  // In production, this would connect to the actual backend API


  /// Parse natural language command and suggest plan update (no automatic execution)
  Future<Map<String, dynamic>> suggestPlanCommand(
    String command,
    String tripId,
  ) async {
    try {

      // Parse the command to extract action, day, and activity
      final parsedCommand = _parseNaturalLanguageCommand(command);

      if (parsedCommand == null) {
        return {
          'success': false,
          'message': 'Cannot understand the command. Please try again with a different format.',
          'action': 'unknown',
        };
      }


      // Generate suggestion message without executing
      switch (parsedCommand['action']) {
        case 'add':
          return _suggestAddActivity(
            tripId: tripId,
            day: parsedCommand['day'],
            activity: parsedCommand['activity'],
          );

        case 'remove':
          return _suggestRemoveActivity(
            tripId: tripId,
            day: parsedCommand['day'],
            activity: parsedCommand['activity'],
          );

        case 'update':
          return _suggestUpdateActivity(
            tripId: tripId,
            day: parsedCommand['day'],
            oldActivity: parsedCommand['oldActivity'],
            newActivity: parsedCommand['newActivity'],
          );

        default:
          return {
            'success': false,
            'message': 'Hành động không được hỗ trợ.',
            'action': parsedCommand['action'],
          };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Có lỗi xảy ra khi xử lý lệnh: $e',
        'action': 'error',
      };
    }
  }

  /// Parse natural language command into structured data
  Map<String, dynamic>? _parseNaturalLanguageCommand(String command) {
    final normalizedCommand = command.toLowerCase().trim();

    // English patterns for adding activities
    final addPatterns = [
      RegExp(r'add\s+(.+?)\s+to\s+day\s+(\d+)'),
      RegExp(r'add\s+(.+?)\s+on\s+day\s+(\d+)'),
      RegExp(r'include\s+(.+?)\s+in\s+day\s+(\d+)'),
      RegExp(r'put\s+(.+?)\s+on\s+day\s+(\d+)'),
    ];

    // English patterns for removing activities
    final removePatterns = [
      RegExp(r'remove\s+(.+?)\s+from\s+day\s+(\d+)'),
      RegExp(r'delete\s+(.+?)\s+on\s+day\s+(\d+)'),
      RegExp(r'cancel\s+(.+?)\s+on\s+day\s+(\d+)'),
      RegExp(r'drop\s+(.+?)\s+from\s+day\s+(\d+)'),
    ];

    // English patterns for updating activities
    final updatePatterns = [
      RegExp(r'change\s+(.+?)\s+to\s+(.+?)\s+on\s+day\s+(\d+)'),
      RegExp(r'replace\s+(.+?)\s+with\s+(.+?)\s+on\s+day\s+(\d+)'),
      RegExp(r'update\s+(.+?)\s+to\s+(.+?)\s+on\s+day\s+(\d+)'),
    ];

    // Try to match add patterns
    for (final pattern in addPatterns) {
      final match = pattern.firstMatch(normalizedCommand);
      if (match != null) {
        final activity = match.group(1)?.trim();
        final dayStr = match.group(2);
        if (activity != null && dayStr != null) {
          final day = int.tryParse(dayStr);
          if (day != null) {
            return {
              'action': 'add',
              'activity': _cleanActivityName(activity),
              'day': day,
            };
          }
        }
      }
    }

    // Try to match remove patterns
    for (final pattern in removePatterns) {
      final match = pattern.firstMatch(normalizedCommand);
      if (match != null) {
        final activity = match.group(1)?.trim();
        final dayStr = match.group(2);
        if (activity != null && dayStr != null) {
          final day = int.tryParse(dayStr);
          if (day != null) {
            return {
              'action': 'remove',
              'activity': _cleanActivityName(activity),
              'day': day,
            };
          }
        }
      }
    }

    // Try to match update patterns
    for (final pattern in updatePatterns) {
      final match = pattern.firstMatch(normalizedCommand);
      if (match != null) {
        final oldActivity = match.group(1)?.trim();
        final newActivity = match.group(2)?.trim();
        final dayStr = match.group(3);
        if (oldActivity != null && newActivity != null && dayStr != null) {
          final day = int.tryParse(dayStr);
          if (day != null) {
            return {
              'action': 'update',
              'oldActivity': _cleanActivityName(oldActivity),
              'newActivity': _cleanActivityName(newActivity),
              'day': day,
            };
          }
        }
      }
    }

    return null;
  }

  /// Clean and normalize activity name
  String _cleanActivityName(String activity) {
    // Remove common words and normalize
    final cleaned = activity
        .replaceAll(RegExp(r'\b(go|to|visit|see|eat|play|do|the|a|an)\b', caseSensitive: false), '')
        .trim();

    // Capitalize first letter of each word
    return cleaned.split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }


  /// Suggest adding activity to plan for specific day (no execution)
  Map<String, dynamic> _suggestAddActivity({
    required String tripId,
    required int day,
    required String activity,
  }) {

    // Determine activity type based on keywords
    final activityType = _determineActivityType(activity);

    return {
      'success': true,
      'message': '💡 **Activity Suggestion:**\n\n'
          '📅 **Day $day:** Add activity "$activity"\n'
          '🏷️ **Type:** ${_getActivityTypeName(activityType)}\n\n'
          '⚠️ **Note:** This is just a suggestion. Please add manually in the plan page.',
      'action': 'suggest_add',
      'day': day,
      'activity': activity,
      'activityType': activityType,
    };
  }

  /// Suggest removing activity from plan for specific day (no execution)
  Map<String, dynamic> _suggestRemoveActivity({
    required String tripId,
    required int day,
    required String activity,
  }) {

    return {
      'success': true,
      'message': '💡 **Remove Activity Suggestion:**\n\n'
          '📅 **Day $day:** Remove activity "$activity"\n\n'
          '⚠️ **Note:** This is just a suggestion. Please remove manually in the plan page.',
      'action': 'suggest_remove',
      'day': day,
      'activity': activity,
    };
  }

  /// Suggest updating activity in plan for specific day (no execution)
  Map<String, dynamic> _suggestUpdateActivity({
    required String tripId,
    required int day,
    required String oldActivity,
    required String newActivity,
  }) {

    // Determine activity type based on keywords
    final activityType = _determineActivityType(newActivity);

    return {
      'success': true,
      'message': '💡 **Update Activity Suggestion:**\n\n'
          '📅 **Day $day:**\n'
          '🔄 **From:** "$oldActivity"\n'
          '➡️ **To:** "$newActivity"\n'
          '🏷️ **New Type:** ${_getActivityTypeName(activityType)}\n\n'
          '⚠️ **Note:** This is just a suggestion. Please edit manually in the plan page.',
      'action': 'suggest_update',
      'day': day,
      'oldActivity': oldActivity,
      'newActivity': newActivity,
      'activityType': activityType,
    };
  }

  /// Get human-readable name for activity type
  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.activity:
        return 'Activity';
      case ActivityType.restaurant:
        return 'Restaurant';
      case ActivityType.lodging:
        return 'Lodging';
      case ActivityType.flight:
        return 'Flight';
      case ActivityType.tour:
        return 'Tour';
      default:
        return 'Activity';
    }
  }

  /// Determine activity type based on keywords
  ActivityType _determineActivityType(String activity) {
    final lowerActivity = activity.toLowerCase();

    if (lowerActivity.contains('beach') ||
        lowerActivity.contains('sea') ||
        lowerActivity.contains('swim')) {
      return ActivityType.activity;
    } else if (lowerActivity.contains('eat') ||
               lowerActivity.contains('restaurant') ||
               lowerActivity.contains('food') ||
               lowerActivity.contains('dining')) {
      return ActivityType.restaurant;
    } else if (lowerActivity.contains('hotel') ||
               lowerActivity.contains('accommodation') ||
               lowerActivity.contains('lodging')) {
      return ActivityType.lodging;
    } else if (lowerActivity.contains('flight') ||
               lowerActivity.contains('airplane') ||
               lowerActivity.contains('plane')) {
      return ActivityType.flight;
    } else if (lowerActivity.contains('tour') ||
               lowerActivity.contains('sightseeing')) {
      return ActivityType.tour;
    } else if (lowerActivity.contains('shopping') ||
               lowerActivity.contains('market')) {
      return ActivityType.activity;
    }

    return ActivityType.activity; // Default
  }

  /// Get AI suggestions for plan editing commands (manual operation only)
  List<String> getSuggestedCommands(String tripName, int tripDuration) {
    final suggestions = [
      'Suggest activities for day 2',
      'What food should I try here?',
      'What\'s the weather like tomorrow?',
      'How to get to tourist attractions?',
      'Cheap hotels near city center',
    ];

    // Customize suggestions based on trip duration
    if (tripDuration > 3) {
      suggestions.addAll([
        'Shopping places here?',
        'Half-day tour',
      ]);
    }

    return suggestions.take(6).toList(); // Limit to 6 suggestions
  }
}
