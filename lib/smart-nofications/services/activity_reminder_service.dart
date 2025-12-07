import '../models/notification_models.dart';
import '../../Plan/models/activity_models.dart';
import '../../Plan/services/trip_planning_service.dart';

class ActivityReminderService {
  final TripPlanningService _tripService = TripPlanningService();

  Future<List<ActivityReminder>> checkUpcomingActivities(String tripId) async {
    try {
      final activities = await _tripService.getActivities(tripId: tripId);
      final now = DateTime.now();
      final reminders = <ActivityReminder>[];

      for (final activity in activities) {
        if (activity.startDate != null && !activity.checkIn) {
          final timeDiff = activity.startDate!.difference(now);
          final minutesUntilStart = timeDiff.inMinutes;

          // Send reminder 60 minutes before activity starts
          if (minutesUntilStart > 0 && minutesUntilStart <= 60) {
            reminders.add(ActivityReminder(
              activityId: activity.id ?? '',
              activityTitle: activity.title,
              location: activity.location?.name ?? 'Chưa xác định',
              startTime: activity.startDate!,
              minutesUntilStart: minutesUntilStart,
            ));
          }
        }
      }

      return reminders;
    } catch (e) {
      print('Error checking upcoming activities: $e');
      return [];
    }
  }

  Future<List<ActivityReminder>> getTodayActivities(String tripId) async {
    try {
      final activities = await _tripService.getActivities(tripId: tripId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final reminders = <ActivityReminder>[];

      for (final activity in activities) {
        if (activity.startDate != null) {
          final activityDate = DateTime(
            activity.startDate!.year,
            activity.startDate!.month,
            activity.startDate!.day,
          );

          // Check if activity is today
          if (activityDate.isAtSameMomentAs(today) ||
              (activityDate.isAfter(today) && activityDate.isBefore(tomorrow))) {
            final timeDiff = activity.startDate!.difference(now);
            
            reminders.add(ActivityReminder(
              activityId: activity.id ?? '',
              activityTitle: activity.title,
              location: activity.location?.name ?? 'Chưa xác định',
              startTime: activity.startDate!,
              minutesUntilStart: timeDiff.inMinutes,
            ));
          }
        }
      }

      // Sort by start time
      reminders.sort((a, b) => a.startTime.compareTo(b.startTime));

      return reminders;
    } catch (e) {
      print('Error getting today activities: $e');
      return [];
    }
  }

  Future<ActivityModel?> getNextActivity(String tripId) async {
    try {
      final activities = await _tripService.getActivities(tripId: tripId);
      final now = DateTime.now();
      
      ActivityModel? nextActivity;
      Duration? shortestDuration;

      for (final activity in activities) {
        if (activity.startDate != null && 
            activity.startDate!.isAfter(now) && 
            !activity.checkIn) {
          
          final timeDiff = activity.startDate!.difference(now);
          
          if (shortestDuration == null || timeDiff < shortestDuration) {
            shortestDuration = timeDiff;
            nextActivity = activity;
          }
        }
      }

      return nextActivity;
    } catch (e) {
      print('Error getting next activity: $e');
      return null;
    }
  }

  String formatTimeUntilActivity(DateTime activityTime) {
    final now = DateTime.now();
    final difference = activityTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày ${difference.inHours % 24} giờ';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ ${difference.inMinutes % 60} phút';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút';
    } else {
      return 'Sắp bắt đầu';
    }
  }

  bool shouldSendReminder(DateTime activityTime, DateTime lastReminderSent) {
    final now = DateTime.now();
    final timeSinceLastReminder = now.difference(lastReminderSent);
    final timeUntilActivity = activityTime.difference(now);

    // Don't send reminders more than once every 30 minutes
    if (timeSinceLastReminder.inMinutes < 30) {
      return false;
    }

    // Send reminder if activity is within 1 hour
    return timeUntilActivity.inMinutes <= 60 && timeUntilActivity.inMinutes > 0;
  }
}