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
  bool _isInitialized = false;

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
      // Load existing notifications
      await _loadNotifications(tripId);

      // Start periodic checks every 30 seconds for testing (change to 5 minutes in production)
      _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkForNotifications(tripId);
      });

      // Immediately check for notifications once
      debugPrint('SmartNotificationProvider: Running initial notification check...');
      await _checkForNotifications(tripId);

      // Add some test notifications for demo
      await _addTestNotifications(tripId);

      _isInitialized = true;
      notifyListeners();
      debugPrint('SmartNotificationProvider: Initialization complete. Notifications count: ${_notifications.length}');
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error during initialization: $e');
    }
  }

  Future<void> _addTestNotifications(String tripId) async {
    try {
      debugPrint('SmartNotificationProvider: Creating test notifications for trip $tripId');
      
      // Add test weather notification
      final weatherNotification = SmartNotification(
        id: 'test_weather_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.weather,
        severity: NotificationSeverity.warning,
        title: 'Cảnh báo thời tiết',
        message: 'Dự báo có mưa vào chiều nay tại điểm đến của bạn',
        createdAt: DateTime.now(),
        icon: Icons.wb_cloudy,
        color: Colors.blue,
      );

      // Add test activity reminder
      final activityNotification = SmartNotification(
        id: 'test_activity_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.activity,
        severity: NotificationSeverity.info,
        title: 'Sắp đến hoạt động',
        message: 'Hoạt động "Tham quan chùa" sẽ bắt đầu trong 45 phút',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        icon: Icons.schedule,
        color: Colors.green,
      );

      // Add test budget notification
      final budgetNotification = SmartNotification(
        id: 'test_budget_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.budget,
        severity: NotificationSeverity.warning,
        title: 'Vượt ngân sách',
        message: 'Chi phí thực tế cao hơn dự kiến 25%',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        icon: Icons.warning,
        color: Colors.orange,
      );

      _notifications.addAll([weatherNotification, activityNotification, budgetNotification]);
      
      debugPrint('SmartNotificationProvider: Added ${_notifications.length} test notifications to memory');
      
      // Save each notification
      for (final notification in [weatherNotification, activityNotification, budgetNotification]) {
        await _notificationService.saveNotification(notification, tripId);
      }

      debugPrint('SmartNotificationProvider: Test notifications saved to storage');
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error adding test notifications: $e');
    }
  }

  Future<void> _loadNotifications(String tripId) async {
    try {
      _notifications = await _notificationService.getNotifications(tripId);
      debugPrint('SmartNotificationProvider: Loaded ${_notifications.length} notifications');
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error loading notifications: $e');
    }
  }

  Future<void> _checkForNotifications(String tripId) async {
    try {
      debugPrint('SmartNotificationProvider: Checking for notifications for trip $tripId');
      
      // Check for weather alerts
      debugPrint('SmartNotificationProvider: Checking weather alerts...');
      final weatherAlerts = await _weatherService.checkWeatherAlerts(tripId);
      debugPrint('SmartNotificationProvider: Found ${weatherAlerts.length} weather alerts');
      
      for (final alert in weatherAlerts) {
        await _addWeatherNotification(alert, tripId);
      }

      // Check for activity reminders
      debugPrint('SmartNotificationProvider: Checking activity reminders...');
      final reminders = await _reminderService.checkUpcomingActivities(tripId);
      debugPrint('SmartNotificationProvider: Found ${reminders.length} activity reminders');
      
      for (final reminder in reminders) {
        await _addActivityReminderNotification(reminder, tripId);
      }

      notifyListeners();
      debugPrint('SmartNotificationProvider: Notification check complete. Total notifications: ${_notifications.length}');
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error checking notifications: $e');
    }
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

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _notificationService.markAsRead(notificationId);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _notificationService.markAllAsRead();
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _notificationService.deleteNotification(notificationId);
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