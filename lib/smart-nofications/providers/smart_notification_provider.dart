import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_models.dart';
import '../services/smart_notification_service.dart';
import '../services/weather_notification_service.dart';
import '../services/budget_notification_service.dart';
import '../services/activity_reminder_service.dart';

class SmartNotificationProvider extends ChangeNotifier {
  final SmartNotificationService _notificationService = SmartNotificationService();
  final WeatherNotificationService _weatherService = WeatherNotificationService();
  final BudgetNotificationService _budgetService = BudgetNotificationService();
  final ActivityReminderService _reminderService = ActivityReminderService();

  List<SmartNotification> _notifications = [];
  Timer? _periodicTimer;
  Timer? _dailyWeatherTimer;
  bool _isInitialized = false;
  DateTime? _lastWeatherCheck;

  List<SmartNotification> get notifications => List.unmodifiable(_notifications);
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  bool get hasUnread => unreadCount > 0;

  List<SmartNotification> get recentNotifications => 
      _notifications.where((n) => !n.isRead).take(3).toList();

  Future<void> initialize(String tripId) async {
    if (_isInitialized) {
      debugPrint('SmartNotificationProvider: Already initialized');
      return;
    }

    debugPrint('SmartNotificationProvider: Initializing for trip $tripId');

    try {
      // Load existing notifications with timeout
      try {
        await _loadNotifications(tripId).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('SmartNotificationProvider: Loading notifications timed out - continuing with empty list');
          },
        );
      } catch (e) {
        debugPrint('SmartNotificationProvider: Loading notifications failed: $e');
      }

      // Start periodic checks every 5 minutes for activity reminders and budget checks
      _periodicTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _checkForNotifications(tripId);
      });

      // Immediately check for notifications once (with timeout)
      try {
        await _checkForNotifications(tripId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('SmartNotificationProvider: Initial notification check timed out - will retry in periodic timer');
          },
        );
      } catch (e) {
        debugPrint('SmartNotificationProvider: Initial notification check failed: $e');
      }

      _isInitialized = true;
      debugPrint('SmartNotificationProvider: Initialization completed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error during initialization: $e');
      // Mark as initialized even if there were errors, so periodic checks can continue
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Clear all test notifications (useful for cleaning up old test data)
  Future<void> clearTestNotifications(String tripId) async {
    try {
      final testNotifications = _notifications.where((n) => 
        n.id.startsWith('test_')).toList();
      
      for (final notification in testNotifications) {
        await deleteNotification(notification.id, tripId);
      }
      
      debugPrint('SmartNotificationProvider: Cleared ${testNotifications.length} test notifications');
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error clearing test notifications: $e');
    }
  }



  Future<void> _loadNotifications(String tripId) async {
    try {
      _notifications = await _notificationService.getNotifications(tripId);
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error loading notifications: $e');
    }
  }

  Future<void> _checkForNotifications(String tripId) async {
    try {
      // Check weather only once per day when there are activities
      await _checkWeatherIfNeeded(tripId);

      // Check for activity reminders (with enhanced error handling)
      try {
        final reminders = await _reminderService.checkUpcomingActivities(tripId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('SmartNotificationProvider: Activity service timeout');
            return <ActivityReminder>[];
          },
        );
        
        for (final reminder in reminders) {
          await _addActivityReminderNotification(reminder, tripId);
        }
        
        if (reminders.isNotEmpty) {
          debugPrint('SmartNotificationProvider: Added ${reminders.length} activity reminders');
        }
      } catch (activityError) {
        final errorString = activityError.toString().toLowerCase();
        if (errorString.contains('failed to fetch') || 
            errorString.contains('clientexception') ||
            errorString.contains('socketexception') ||
            errorString.contains('connection')) {
          debugPrint('SmartNotificationProvider: Network unavailable for activity reminders - will retry later');
        } else {
          debugPrint('SmartNotificationProvider: Activity service error: $activityError');
        }
        // Continue without activity reminders if service is down
      }

      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error checking notifications: $e');
    }
  }

  Future<void> _checkWeatherIfNeeded(String tripId) async {
    final now = DateTime.now();
    
    // Only check if we haven't checked today
    if (_lastWeatherCheck == null || 
        now.difference(_lastWeatherCheck!).inHours >= 24 ||
        !_isSameDay(now, _lastWeatherCheck!)) {
      
      // First, check if there are activities today
      try {
        final todayActivities = await _reminderService.getTodayActivities(tripId);
        
        // Only check weather if there are activities scheduled for today
        if (todayActivities.isNotEmpty) {
          debugPrint('SmartNotificationProvider: Checking weather for ${todayActivities.length} activities today');
          
          final weatherAlerts = await _weatherService.checkWeatherAlerts(tripId);
          
          for (final alert in weatherAlerts) {
            await _addWeatherNotification(alert, tripId);
          }
          
          if (weatherAlerts.isNotEmpty) {
            debugPrint('SmartNotificationProvider: Added ${weatherAlerts.length} weather notifications');
          }
        }
        
        _lastWeatherCheck = now;
      } catch (activityServiceError) {
        debugPrint('SmartNotificationProvider: Cannot check activities, assuming there might be activities today');
        // If activity service is down, still do a weather check as fallback
        try {
          final weatherAlerts = await _weatherService.checkWeatherAlerts(tripId);
          
          for (final alert in weatherAlerts) {
            await _addWeatherNotification(alert, tripId);
          }
          
          _lastWeatherCheck = now; // Update even if activities couldn't be checked
        } catch (weatherError) {
          debugPrint('SmartNotificationProvider: Weather check also failed: $weatherError');
          // Don't update _lastWeatherCheck on failure, so it will retry
        }
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> checkBudgetOnActivity(String tripId, String activityId, double actualCost) async {
    try {
      debugPrint('SmartNotificationProvider: Checking budget for activity $activityId, cost: $actualCost');
      
      final warning = await _budgetService.checkBudgetOverage(activityId, actualCost);
      
      if (warning != null) {
        debugPrint('SmartNotificationProvider: Budget warning detected, creating notification');
        await _addBudgetWarningNotification(warning, tripId);
        debugPrint('SmartNotificationProvider: Budget notification created successfully');
      } else {
        debugPrint('SmartNotificationProvider: No budget warning needed');
      }
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error checking budget: $e');
    }
  }

  /// Call this method when user checks in to an activity
  /// This will automatically check for budget overages and create notifications
  Future<void> handleActivityCheckIn(String tripId, String activityId, String activityTitle, double actualCost) async {
    try {
      debugPrint('SmartNotificationProvider: Handling check-in for activity: $activityTitle');
      
      // Check for budget overage
      await checkBudgetOnActivity(tripId, activityId, actualCost);
      
      // You could also add other check-in related notifications here
      // like completion confirmations, next activity reminders, etc.
      
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error handling activity check-in: $e');
    }
  }

  Future<void> _addWeatherNotification(WeatherAlert alert, String tripId) async {
    final notification = SmartNotification(
      id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.weather,
      severity: _getWeatherSeverity(alert.condition),
      title: 'Cảnh báo thời tiết',
      message: '${alert.description} tại ${alert.location}. Nhiệt độ: ${alert.temperature.toInt()}°C',
      createdAt: DateTime.now(),
      icon: _getWeatherIcon(alert.condition),
      color: Colors.blue,
      data: alert.toJson(),
    );

    // Check if similar notification already exists (within last hour)
    final existingNotification = _notifications.where((n) => 
      n.type == NotificationType.weather &&
      n.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)))
    ).firstOrNull;

    if (existingNotification == null) {
      _notifications.insert(0, notification);
      await _notificationService.saveNotification(notification, tripId);
    }
  }

  Future<void> _addBudgetWarningNotification(BudgetWarning warning, String tripId) async {
    debugPrint('SmartNotificationProvider: Adding budget warning notification for ${warning.activityTitle}');
    
    final notification = SmartNotification(
      id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.budget,
      severity: warning.overagePercentage > 50 ? NotificationSeverity.critical : NotificationSeverity.warning,
      title: 'Vượt ngân sách',
      message: '${warning.activityTitle} đã vượt ${warning.overagePercentage.toInt()}% ngân sách dự kiến',
      createdAt: DateTime.now(),
      icon: Icons.warning,
      color: Colors.orange,
      data: warning.toJson(),
    );

    _notifications.insert(0, notification);
    await _notificationService.saveNotification(notification, tripId);
    notifyListeners(); // Force UI update
    
    debugPrint('SmartNotificationProvider: Budget warning notification added. Total notifications: ${_notifications.length}');
  }

  Future<void> _addActivityReminderNotification(ActivityReminder reminder, String tripId) async {
    final notification = SmartNotification(
      id: 'reminder_${reminder.activityId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.activity,
      severity: NotificationSeverity.info,
      title: 'Sắp đến hoạt động',
      message: '${reminder.activityTitle} sẽ bắt đầu trong ${reminder.minutesUntilStart} phút tại ${reminder.location}',
      createdAt: DateTime.now(),
      icon: Icons.schedule,
      color: Colors.green,
      data: reminder.toJson(),
    );

    // Check if reminder for this activity already sent (within last 2 hours)
    final existingReminder = _notifications.where((n) => 
      n.type == NotificationType.activity &&
      n.data != null &&
      n.data!['activityId'] == reminder.activityId &&
      n.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 2)))
    ).firstOrNull;

    if (existingReminder == null) {
      _notifications.insert(0, notification);
      await _notificationService.saveNotification(notification, tripId);
    }
  }

  Future<void> markAsRead(String notificationId, String tripId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _notificationService.markAsRead(notificationId, tripId);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String tripId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _notificationService.markAllAsRead(tripId);
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId, String tripId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _notificationService.deleteNotification(notificationId, tripId);
    notifyListeners();
  }

  NotificationSeverity _getWeatherSeverity(String condition) {
    final dangerousConditions = ['thunderstorm', 'storm', 'heavy rain', 'snow'];
    if (dangerousConditions.any((c) => condition.toLowerCase().contains(c))) {
      return NotificationSeverity.critical;
    }
    
    final warningConditions = ['rain', 'cloudy', 'overcast'];
    if (warningConditions.any((c) => condition.toLowerCase().contains(c))) {
      return NotificationSeverity.warning;
    }
    
    return NotificationSeverity.info;
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.toLowerCase().contains('rain')) return Icons.umbrella;
    if (condition.toLowerCase().contains('storm')) return Icons.flash_on;
    if (condition.toLowerCase().contains('snow')) return Icons.ac_unit;
    if (condition.toLowerCase().contains('cloud')) return Icons.cloud;
    if (condition.toLowerCase().contains('sun')) return Icons.wb_sunny;
    return Icons.wb_cloudy;
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _dailyWeatherTimer?.cancel();
    super.dispose();
  }
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}