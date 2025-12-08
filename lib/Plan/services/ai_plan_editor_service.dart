import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_models.dart';
import '../models/trip_model.dart';
import 'trip_planning_service.dart';

/// Service for AI-powered plan editing with natural language processing
class AIPlanEditorService {
  final TripPlanningService _tripService = TripPlanningService();

  // For demo purposes, we'll simulate successful operations
  // In production, this would connect to the actual backend API



  /// Parse natural language command and suggest plan update (no automatic execution)
  Future<Map<String, dynamic>> suggestPlanCommand(
    String command,
    String tripId,
  ) async {
    try {
      debugPrint('AI Plan Editor: Processing command suggestion: "$command"');

      // Parse the command to extract action, day, and activity
      final parsedCommand = _parseNaturalLanguageCommand(command);

      if (parsedCommand == null) {
        return {
          'success': false,
          'message': 'Không thể hiểu lệnh. Vui lòng thử lại với định dạng khác.',
          'action': 'unknown',
        };
      }

      debugPrint('AI Plan Editor: Parsed command: $parsedCommand');

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
      debugPrint('AI Plan Editor Error: $e');
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

    // Vietnamese patterns for adding activities
    final addPatterns = [
      RegExp(r'thêm\s+(.+?)\s+vào\s+ngày\s+(\d+)'),
      RegExp(r'thêm\s+(.+?)\s+ngày\s+(\d+)'),
      RegExp(r'add\s+(.+?)\s+to\s+day\s+(\d+)'),
      RegExp(r'add\s+(.+?)\s+on\s+day\s+(\d+)'),
    ];

    // Vietnamese patterns for removing activities
    final removePatterns = [
      RegExp(r'xóa\s+(.+?)\s+trong\s+ngày\s+(\d+)'),
      RegExp(r'xóa\s+(.+?)\s+ngày\s+(\d+)'),
      RegExp(r'xóa\s+(.+?)\s+từ\s+ngày\s+(\d+)'),
      RegExp(r'remove\s+(.+?)\s+from\s+day\s+(\d+)'),
      RegExp(r'delete\s+(.+?)\s+on\s+day\s+(\d+)'),
    ];

    // Vietnamese patterns for updating activities
    final updatePatterns = [
      RegExp(r'thay\s+(.+?)\s+bằng\s+(.+?)\s+trong\s+ngày\s+(\d+)'),
      RegExp(r'đổi\s+(.+?)\s+thành\s+(.+?)\s+ngày\s+(\d+)'),
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
    // Remove common Vietnamese words and normalize
    final cleaned = activity
        .replaceAll(RegExp(r'\b(đi|đến|thăm|tham quan|xem|ăn|chơi)\b'), '')
        .trim();

    // Capitalize first letter of each word
    return cleaned.split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  /// Add activity to plan for specific day
  Future<Map<String, dynamic>> _addActivityToPlan({
    required String tripId,
    required int day,
    required String activity,
  }) async {
    try {
      debugPrint('AI Plan Editor: Adding "$activity" to day $day of trip $tripId');

      // For demo purposes, simulate successful operation
      // In production, this would validate the trip and create the activity

      // Determine activity type based on keywords
      final activityType = _determineActivityType(activity);

      // Create mock activity for response
      final mockActivity = ActivityModel(
        id: 'mock_activity_${DateTime.now().millisecondsSinceEpoch}',
        title: activity,
        activityType: activityType,
        startDate: DateTime.now().add(Duration(days: day - 1)), // Mock date
        tripId: tripId,
      );

      return {
        'success': true,
        'message': 'Đã thêm "$activity" vào ngày $day.',
        'action': 'add',
        'activity': mockActivity,
        'day': day,
      };
    } catch (e) {
      debugPrint('Error adding activity: $e');
      return {
        'success': false,
        'message': 'Không thể thêm hoạt động: $e',
        'action': 'add',
      };
    }
  }

  /// Remove activity from plan for specific day
  Future<Map<String, dynamic>> _removeActivityFromPlan({
    required String tripId,
    required int day,
    required String activity,
  }) async {
    try {
      debugPrint('AI Plan Editor: Removing "$activity" from day $day of trip $tripId');

      // For demo purposes, simulate successful operation
      // In production, this would find and remove the actual activity

      // Create mock activity for response
      final mockActivity = ActivityModel(
        id: 'mock_removed_activity_${DateTime.now().millisecondsSinceEpoch}',
        title: activity,
        activityType: ActivityType.activity,
        startDate: DateTime.now().add(Duration(days: day - 1)), // Mock date
        tripId: tripId,
      );

      return {
        'success': true,
        'message': 'Đã xóa "$activity" khỏi ngày $day.',
        'action': 'remove',
        'activity': mockActivity,
        'day': day,
      };
    } catch (e) {
      debugPrint('Error removing activity: $e');
      return {
        'success': false,
        'message': 'Không thể xóa hoạt động: $e',
        'action': 'remove',
      };
    }
  }

  /// Update activity in plan for specific day
  Future<Map<String, dynamic>> _updateActivityInPlan({
    required String tripId,
    required int day,
    required String oldActivity,
    required String newActivity,
  }) async {
    try {
      debugPrint('AI Plan Editor: Updating "$oldActivity" to "$newActivity" on day $day of trip $tripId');

      // For demo purposes, simulate successful operation
      // In production, this would find and update the actual activity

      // Determine activity type based on keywords
      final activityType = _determineActivityType(newActivity);

      // Create mock updated activity for response
      final mockActivity = ActivityModel(
        id: 'mock_updated_activity_${DateTime.now().millisecondsSinceEpoch}',
        title: newActivity,
        activityType: activityType,
        startDate: DateTime.now().add(Duration(days: day - 1)), // Mock date
        tripId: tripId,
        updatedAt: DateTime.now(),
      );

      return {
        'success': true,
        'message': 'Đã thay đổi "$oldActivity" thành "$newActivity" trong ngày $day.',
        'action': 'update',
        'activity': mockActivity,
        'day': day,
      };
    } catch (e) {
      debugPrint('Error updating activity: $e');
      return {
        'success': false,
        'message': 'Không thể cập nhật hoạt động: $e',
        'action': 'update',
      };
    }
  }

  /// Suggest adding activity to plan for specific day (no execution)
  Map<String, dynamic> _suggestAddActivity({
    required String tripId,
    required int day,
    required String activity,
  }) {
    debugPrint('AI Plan Editor: Suggesting to add "$activity" to day $day of trip $tripId');

    // Determine activity type based on keywords
    final activityType = _determineActivityType(activity);

    return {
      'success': true,
      'message': '💡 **Đề xuất thêm hoạt động:**\n\n'
          '📅 **Ngày $day:** Thêm hoạt động "$activity"\n'
          '🏷️ **Loại:** ${_getActivityTypeName(activityType)}\n\n'
          '⚠️ **Lưu ý:** Đây chỉ là đề xuất. Vui lòng thêm thủ công trong trang kế hoạch.',
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
    debugPrint('AI Plan Editor: Suggesting to remove "$activity" from day $day of trip $tripId');

    return {
      'success': true,
      'message': '💡 **Đề xuất xóa hoạt động:**\n\n'
          '📅 **Ngày $day:** Xóa hoạt động "$activity"\n\n'
          '⚠️ **Lưu ý:** Đây chỉ là đề xuất. Vui lòng xóa thủ công trong trang kế hoạch.',
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
    debugPrint('AI Plan Editor: Suggesting to update "$oldActivity" to "$newActivity" on day $day of trip $tripId');

    // Determine activity type based on keywords
    final activityType = _determineActivityType(newActivity);

    return {
      'success': true,
      'message': '💡 **Đề xuất thay đổi hoạt động:**\n\n'
          '📅 **Ngày $day:**\n'
          '🔄 **Từ:** "$oldActivity"\n'
          '➡️ **Thành:** "$newActivity"\n'
          '🏷️ **Loại mới:** ${_getActivityTypeName(activityType)}\n\n'
          '⚠️ **Lưu ý:** Đây chỉ là đề xuất. Vui lòng chỉnh sửa thủ công trong trang kế hoạch.',
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
        return 'Hoạt động';
      case ActivityType.restaurant:
        return 'Nhà hàng';
      case ActivityType.lodging:
        return 'Lưu trú';
      case ActivityType.flight:
        return 'Chuyến bay';
      case ActivityType.tour:
        return 'Tour tham quan';
      default:
        return 'Hoạt động';
    }
  }

  /// Determine activity type based on keywords
  ActivityType _determineActivityType(String activity) {
    final lowerActivity = activity.toLowerCase();

    if (lowerActivity.contains('biển') ||
        lowerActivity.contains('beach') ||
        lowerActivity.contains('bơi')) {
      return ActivityType.activity;
    } else if (lowerActivity.contains('ăn') ||
               lowerActivity.contains('nhà hàng') ||
               lowerActivity.contains('food') ||
               lowerActivity.contains('restaurant')) {
      return ActivityType.restaurant;
    } else if (lowerActivity.contains('khách sạn') ||
               lowerActivity.contains('hotel') ||
               lowerActivity.contains('lưu trú')) {
      return ActivityType.lodging;
    } else if (lowerActivity.contains('bay') ||
               lowerActivity.contains('máy bay') ||
               lowerActivity.contains('flight')) {
      return ActivityType.flight;
    } else if (lowerActivity.contains('tour') ||
               lowerActivity.contains('tham quan')) {
      return ActivityType.tour;
    } else if (lowerActivity.contains('mua sắm') ||
               lowerActivity.contains('shopping')) {
      return ActivityType.activity;
    }

    return ActivityType.activity; // Default
  }

  /// Get AI suggestions for plan editing commands (manual operation only)
  List<String> getSuggestedCommands(String tripName, int tripDuration) {
    final suggestions = [
      'Gợi ý hoạt động cho ngày 2',
      'Những món ăn nên thử ở đây?',
      'Thời tiết như thế nào vào ngày mai?',
      'Cách di chuyển đến điểm tham quan?',
      'Khách sạn giá rẻ gần trung tâm',
    ];

    // Customize suggestions based on trip duration
    if (tripDuration > 3) {
      suggestions.addAll([
        'Địa điểm mua sắm ở đây?',
        'Tour tham quan nửa ngày',
      ]);
    }

    return suggestions.take(6).toList(); // Limit to 6 suggestions
  }
}
