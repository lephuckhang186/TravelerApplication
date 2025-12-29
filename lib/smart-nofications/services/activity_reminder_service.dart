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

          // Send reminder 2 hours before activity starts
          if (minutesUntilStart > 0 && minutesUntilStart <= 120) {
            reminders.add(ActivityReminder(
              activityId: activity.id ?? '',
              activityTitle: activity.title,
              location: activity.location?.name ?? 'Not specified',
              startTime: activity.startDate!,
              minutesUntilStart: minutesUntilStart,
            ));
          }
        }
      }

      return reminders;
    } catch (e) {
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
              location: activity.location?.name ?? 'Not specified',
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
      return null;
    }
  }

  String formatTimeUntilActivity(DateTime activityTime) {
    final now = DateTime.now();
    final difference = activityTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ${difference.inHours % 24} hours';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ${difference.inMinutes % 60} minutes';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes';
    } else {
      return 'Starting soon';
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

  /// Check if today is within the trip date range
  Future<bool> isTodayWithinTrip(String tripId) async {
    try {
      final trip = await _tripService.getTrip(tripId);
      if (trip == null) {
        return false;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Get trip start and end dates
      final startDate = trip.startDate;
      final endDate = trip.endDate;
      final tripStartDay = DateTime(startDate.year, startDate.month, startDate.day);
      final tripEndDay = DateTime(endDate.year, endDate.month, endDate.day);
      
      // Check if today is within the trip date range (inclusive of both start and end dates)
      final isWithinTrip = (today.isAtSameMomentAs(tripStartDay) || today.isAfter(tripStartDay)) &&
                           (today.isAtSameMomentAs(tripEndDay) || today.isBefore(tripEndDay));
      
      
      return isWithinTrip;
    } catch (e) {
      return false;
    }
  }
}