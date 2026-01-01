import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/Plan/utils/activity_scheduling_validator.dart';
import 'package:flutter_application_1/Plan/models/activity_models.dart';

void main() {
  group('ActivitySchedulingValidator tests', () {
    test('validates non-overlapping activities', () {
      final activity1 = ActivityModel(
        id: 'act1',
        title: 'Morning Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 9, 0),
        endDate: DateTime(2024, 6, 1, 11, 0),
      );

      final activity2 = ActivityModel(
        id: 'act2',
        title: 'Afternoon Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 14, 0),
        endDate: DateTime(2024, 6, 1, 16, 0),
      );

      // These activities don't overlap
      final result = ActivitySchedulingValidator.validateActivityTime(
        activity2,
        [activity1],
      );

      expect(result.hasConflicts, false);
      expect(result.conflictingActivities, isEmpty);
    });

    test('detects overlapping activities', () {
      final activity1 = ActivityModel(
        id: 'act1',
        title: 'Morning Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 9, 0),
        endDate: DateTime(2024, 6, 1, 12, 0),
      );

      final activity2 = ActivityModel(
        id: 'act2',
        title: 'Overlapping Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 11, 0),
        endDate: DateTime(2024, 6, 1, 14, 0),
      );

      // These activities overlap (11:00-12:00)
      final result = ActivitySchedulingValidator.validateActivityTime(
        activity2,
        [activity1],
      );

      expect(result.hasConflicts, true);
      expect(result.conflictingActivities.length, 1);
      expect(result.message, isNotEmpty);
    });

    test('handles activities with null dates', () {
      final activity1 = ActivityModel(
        id: 'act1',
        title: 'No Date Activity',
        activityType: ActivityType.activity,
      );

      final activity2 = ActivityModel(
        id: 'act2',
        title: 'Another Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 10, 0),
        endDate: DateTime(2024, 6, 1, 12, 0),
      );

      // Should handle null dates gracefully
      final result = ActivitySchedulingValidator.validateActivityTime(
        activity1,
        [activity2],
      );

      expect(result.hasConflicts, false);
    });

    test('excludes activity when updating itself', () {
      final activity1 = ActivityModel(
        id: 'act1',
        title: 'Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 9, 0),
        endDate: DateTime(2024, 6, 1, 11, 0),
      );

      // Updating the same activity should not conflict with itself
      final result = ActivitySchedulingValidator.validateActivityTime(
        activity1,
        [activity1],
        excludeActivityId: 'act1',
      );

      expect(result.hasConflicts, false);
    });

    test('sorts activities chronologically', () {
      final activity1 = ActivityModel(
        id: 'act1',
        title: 'Later Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 14, 0),
      );

      final activity2 = ActivityModel(
        id: 'act2',
        title: 'Earlier Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 9, 0),
      );

      final sorted = ActivitySchedulingValidator.sortActivitiesChronologically([
        activity1,
        activity2,
      ]);

      expect(sorted.first.id, 'act2');
      expect(sorted.last.id, 'act1');
    });

    test('sorts activities with null dates to end', () {
      final activity1 = ActivityModel(
        id: 'act1',
        title: 'Activity with date',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 9, 0),
      );

      final activity2 = ActivityModel(
        id: 'act2',
        title: 'Activity without date',
        activityType: ActivityType.activity,
      );

      final sorted = ActivitySchedulingValidator.sortActivitiesChronologically([
        activity2,
        activity1,
      ]);

      expect(sorted.first.id, 'act1'); // With date comes first
      expect(sorted.last.id, 'act2'); // Without date goes to end
    });

    test('formatConflictMessage returns empty for no conflicts', () {
      final message = ActivitySchedulingValidator.formatConflictMessage([]);
      expect(message, isEmpty);
    });

    test('formatConflictMessage returns message for single conflict', () {
      final activity = ActivityModel(
        id: 'act1',
        title: 'Test Activity',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 10, 0),
        endDate: DateTime(2024, 6, 1, 12, 0),
      );

      final message = ActivitySchedulingValidator.formatConflictMessage([
        activity,
      ]);
      expect(message, contains('Test Activity'));
      expect(message, isNotEmpty);
    });

    test('formatConflictMessage handles multiple conflicts', () {
      final activities = [
        ActivityModel(
          id: 'act1',
          title: 'Activity 1',
          activityType: ActivityType.activity,
          startDate: DateTime(2024, 6, 1, 10, 0),
        ),
        ActivityModel(
          id: 'act2',
          title: 'Activity 2',
          activityType: ActivityType.activity,
          startDate: DateTime(2024, 6, 1, 11, 0),
        ),
      ];

      final message = ActivitySchedulingValidator.formatConflictMessage(
        activities,
      );
      expect(message, contains('2'));
      expect(message, isNotEmpty);
    });
  });

  group('ActivityConflictResult tests', () {
    test('success factory creates valid result', () {
      final result = ActivityConflictResult.success();

      expect(result.hasConflicts, false);
      expect(result.conflictingActivities, isEmpty);
      expect(result.message, isEmpty);
    });

    test('conflict factory creates valid result', () {
      final activity = ActivityModel(
        id: 'act1',
        title: 'Test',
        activityType: ActivityType.activity,
        startDate: DateTime(2024, 6, 1, 10, 0),
      );

      final result = ActivityConflictResult.conflict([activity]);

      expect(result.hasConflicts, true);
      expect(result.conflictingActivities.length, 1);
      expect(result.message, isNotEmpty);
    });
  });
}
