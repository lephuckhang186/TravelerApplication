import '../models/activity_models.dart';

/// Utility class for validating and managing activity scheduling.
///
/// Provides logic to detect time conflicts between activities, sort itineraries,
/// and suggest available time slots based on trip duration and existing events.
class ActivitySchedulingValidator {
  /// Validates if [newActivity] conflicts with any of the [existingActivities].
  ///
  /// Can [excludeActivityId] to skip comparison with the activity being updated.
  /// Returns an [ActivityConflictResult] containing conflict details.
  static ActivityConflictResult validateActivityTime(
    ActivityModel newActivity,
    List<ActivityModel> existingActivities, {
    String? excludeActivityId,
  }) {
    // Skip validation if no start date
    if (newActivity.startDate == null) {
      return ActivityConflictResult.success();
    }

    final newStart = newActivity.startDate!;
    final newEnd =
        newActivity.endDate ??
        newStart.add(Duration(minutes: newActivity.durationMinutes ?? 60));

    final conflicts = <ActivityModel>[];

    for (final activity in existingActivities) {
      // Skip self when updating
      if (excludeActivityId != null && activity.id == excludeActivityId) {
        continue;
      }

      // Skip activities without start date
      if (activity.startDate == null) continue;

      final existingStart = activity.startDate!;
      final existingEnd =
          activity.endDate ??
          existingStart.add(Duration(minutes: activity.durationMinutes ?? 60));

      // Check for time overlap
      if (_hasTimeOverlap(newStart, newEnd, existingStart, existingEnd)) {
        conflicts.add(activity);
      }
    }

    if (conflicts.isNotEmpty) {
      return ActivityConflictResult.conflict(conflicts);
    }

    return ActivityConflictResult.success();
  }

  /// Core logic to determine if two time intervals overlap.
  static bool _hasTimeOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Sorts a list of [activities] chronologically by their start date and time.
  ///
  /// Activities with null start dates are moved to the end of the list.
  static List<ActivityModel> sortActivitiesChronologically(
    List<ActivityModel> activities,
  ) {
    final sortedActivities = List<ActivityModel>.from(activities);

    sortedActivities.sort((a, b) {
      // Activities without dates go to the end
      if (a.startDate == null && b.startDate == null) return 0;
      if (a.startDate == null) return 1;
      if (b.startDate == null) return -1;

      // Sort by date/time
      return a.startDate!.compareTo(b.startDate!);
    });

    return sortedActivities;
  }

  /// Suggests up to 3 available time slots for a new activity.
  ///
  /// Analyzes gaps between [existingActivities] within the trip's date range,
  /// accounting for [activityDurationMinutes] and a required [bufferMinutes].
  static List<DateTime> getSuggestedTimeSlots(
    List<ActivityModel> existingActivities,
    DateTime tripStartDate,
    DateTime tripEndDate, {
    int activityDurationMinutes = 60,
    int bufferMinutes = 30,
  }) {
    final suggestions = <DateTime>[];
    final sortedActivities = sortActivitiesChronologically(
      existingActivities,
    ).where((a) => a.startDate != null).toList();

    // If no activities, suggest common times
    if (sortedActivities.isEmpty) {
      return _getDefaultTimeSlots(tripStartDate, tripEndDate);
    }

    DateTime currentTime = DateTime(
      tripStartDate.year,
      tripStartDate.month,
      tripStartDate.day,
      8,
      0, // Start at 8 AM
    );

    for (int i = 0; i < sortedActivities.length; i++) {
      final activity = sortedActivities[i];
      final activityStart = activity.startDate!;
      final activityEnd =
          activity.endDate ??
          activityStart.add(Duration(minutes: activity.durationMinutes ?? 60));

      // Check if there's a gap before this activity
      final requiredDuration = Duration(
        minutes: activityDurationMinutes + bufferMinutes,
      );
      if (currentTime.add(requiredDuration).isBefore(activityStart)) {
        suggestions.add(currentTime);
      }

      // Move past this activity
      currentTime = activityEnd.add(Duration(minutes: bufferMinutes));
    }

    // Add suggestion after the last activity
    final lastActivity = sortedActivities.last;
    final lastEnd =
        lastActivity.endDate ??
        lastActivity.startDate!.add(
          Duration(minutes: lastActivity.durationMinutes ?? 60),
        );

    final endTime = DateTime(
      tripEndDate.year,
      tripEndDate.month,
      tripEndDate.day,
      22,
      0, // End at 10 PM
    );

    final suggestedTime = lastEnd.add(Duration(minutes: bufferMinutes));
    if (suggestedTime.isBefore(endTime)) {
      suggestions.add(suggestedTime);
    }

    return suggestions.take(3).toList(); // Return max 3 suggestions
  }

  /// Generates default time suggestions (9 AM, 12 PM, 3 PM, 6 PM) for empty itineraries.
  static List<DateTime> _getDefaultTimeSlots(
    DateTime startDate,
    DateTime endDate,
  ) {
    final suggestions = <DateTime>[];
    final currentDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    // Add common time slots
    suggestions.addAll([
      currentDate.add(const Duration(hours: 9)), // 9 AM
      currentDate.add(const Duration(hours: 12)), // 12 PM
      currentDate.add(const Duration(hours: 15)), // 3 PM
      currentDate.add(const Duration(hours: 18)), // 6 PM
    ]);

    return suggestions
        .where((time) => time.isAfter(startDate) && time.isBefore(endDate))
        .toList();
  }

  /// Formats a user-friendly error message describing time conflicts.
  static String formatConflictMessage(List<ActivityModel> conflicts) {
    if (conflicts.isEmpty) return '';

    if (conflicts.length == 1) {
      final activity = conflicts.first;
      final timeStr = _formatActivityTime(activity);
      return 'This time conflicts with "${activity.title}" ($timeStr)';
    } else {
      return 'This time conflicts with ${conflicts.length} other activities';
    }
  }

  /// Formats the start and end time of an activity for display.
  static String _formatActivityTime(ActivityModel activity) {
    if (activity.startDate == null) return '';

    final start = activity.startDate!;
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    if (activity.endDate != null) {
      final end = activity.endDate!;
      final endStr =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      return '$startStr - $endStr';
    }

    return startStr;
  }
}

/// Data class representing the result of a conflict validation check.
class ActivityConflictResult {
  /// Whether any overlapping activities were found.
  final bool hasConflicts;

  /// The list of activities that overlap with the proposed time.
  final List<ActivityModel> conflictingActivities;

  /// Human-readable description of the conflicts.
  final String message;

  ActivityConflictResult._({
    required this.hasConflicts,
    required this.conflictingActivities,
    required this.message,
  });

  /// Creates a result indicating no conflicts were found.
  factory ActivityConflictResult.success() {
    return ActivityConflictResult._(
      hasConflicts: false,
      conflictingActivities: [],
      message: '',
    );
  }

  /// Creates a result indicating specific time conflicts.
  factory ActivityConflictResult.conflict(List<ActivityModel> conflicts) {
    return ActivityConflictResult._(
      hasConflicts: true,
      conflictingActivities: conflicts,
      message: ActivitySchedulingValidator.formatConflictMessage(conflicts),
    );
  }
}
