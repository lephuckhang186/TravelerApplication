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

  // Store notifications per tripId
  final Map<String, List<SmartNotification>> _notificationsByTrip = {};
  Timer? _periodicTimer;
  Timer? _dailyWeatherTimer;
  final Map<String, bool> _initializedTrips = {};
  final Map<String, DateTime?> _lastWeatherCheckByTrip = {};

  // Get notifications for specific trip
  List<SmartNotification> getNotifications(String tripId) {
    return List.unmodifiable(_notificationsByTrip[tripId] ?? []);
  }
  
  // Get notifications for current trip (backward compatibility)
  List<SmartNotification> get notifications => 
      _notificationsByTrip.values.expand((list) => list).toList();
  
  int getUnreadCount(String tripId) => 
      (_notificationsByTrip[tripId] ?? []).where((n) => !n.isRead).length;
  
  bool hasUnreadForTrip(String tripId) => getUnreadCount(tripId) > 0;
  
  // Global unread count (for backward compatibility)
  int get unreadCount => _notificationsByTrip.values
      .expand((list) => list)
      .where((n) => !n.isRead).length;
  
  bool get hasUnread => unreadCount > 0;

  List<SmartNotification> getRecentNotifications(String tripId) => 
      (_notificationsByTrip[tripId] ?? []).where((n) => !n.isRead).take(3).toList();

  // Backward compatibility
  List<SmartNotification> get recentNotifications => 
      _notificationsByTrip.values.expand((list) => list).where((n) => !n.isRead).take(3).toList();

  Future<void> initialize(String tripId) async {
    if (_initializedTrips[tripId] == true) {
      return;
    }
    
    // Initialize notifications list for this trip if it doesn't exist
    if (_notificationsByTrip[tripId] == null) {
      _notificationsByTrip[tripId] = [];
    }

    try {
      // Load existing notifications with timeout
      try {
        await _loadNotifications(tripId).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
          
          },
        );
      } catch (e) {
        
      }

      // Start periodic timer only if not already running (for all initialized trips)
      if (_periodicTimer == null) {
        
        _periodicTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
          // Check all initialized trips
          for (String tripId in _initializedTrips.keys.where((key) => _initializedTrips[key] == true)) {
            
            _checkForNotifications(tripId);
          }
        });
      }

      // Immediately check for notifications once (with timeout)
      try {
        await _checkForNotifications(tripId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            
          },
        );
      } catch (e) {
        
      }

      // Force weather check on initialization to ensure weather is checked for today's activities
      try {
        await forceWeatherCheck(tripId);
      } catch (e) {
        
      }

      _initializedTrips[tripId] = true;
      
      notifyListeners();
    } catch (e) {
      
      // Mark as initialized even if there were errors, so periodic checks can continue
      _initializedTrips[tripId] = true;
      notifyListeners();
    }
  }

  /// Force check weather for a specific trip (even if not initialized)
  Future<void> checkWeatherForTrip(String tripId) async {
    
    // Initialize notifications list for this trip if it doesn't exist
    if (_notificationsByTrip[tripId] == null) {
      _notificationsByTrip[tripId] = [];
    }
    
    try {
      await forceWeatherCheck(tripId);
      
      notifyListeners();
    } catch (e) {
      
    }
  }

  /// Clear all test notifications (useful for cleaning up old test data)
  Future<void> clearTestNotifications(String tripId) async {
    try {
      if (_notificationsByTrip[tripId] != null) {
        final testNotifications = _notificationsByTrip[tripId]!.where((n) => 
          n.id.startsWith('test_')).toList();
        
        for (final notification in testNotifications) {
          await deleteNotification(notification.id, tripId);
        }
        
      }
    } catch (e) {
      
    }
  }



  Future<void> _loadNotifications(String tripId) async {
    try {
      final notifications = await _notificationService.getNotifications(tripId);
      _notificationsByTrip[tripId] = notifications;
      
      notifyListeners();
    } catch (e) {
      
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
            
            return <ActivityReminder>[];
          },
        );
        
        for (final reminder in reminders) {
          await _addActivityReminderNotification(reminder, tripId);
        }
        
        if (reminders.isNotEmpty) {
          
        }
      } catch (activityError) {
        final errorString = activityError.toString().toLowerCase();
        if (errorString.contains('failed to fetch') || 
            errorString.contains('clientexception') ||
            errorString.contains('socketexception') ||
            errorString.contains('connection')) {
          
        } else {
          
        }
        // Continue without activity reminders if service is down
      }

      // Check for budget warnings (general budget checks)
      try {
        
        final budgetWarnings = await _budgetService.checkTripBudgetStatus(tripId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            
            return <BudgetWarning>[];
          },
        );
        
        for (final warning in budgetWarnings) {
          await _addBudgetWarningNotification(warning, tripId);
        }
        
        if (budgetWarnings.isNotEmpty) {
          
        }
      } catch (budgetError) {
        final errorString = budgetError.toString().toLowerCase();
        if (errorString.contains('failed to fetch') || 
            errorString.contains('clientexception') ||
            errorString.contains('socketexception') ||
            errorString.contains('connection')) {
          
        } else {
          
        }
        // Continue without budget checks if service is down
      }

      notifyListeners();
    } catch (e) {
      
    }
  }

  Future<void> _checkWeatherIfNeeded(String tripId) async {
    final now = DateTime.now();
    
    // Check if we need to check weather (haven't checked today)
    final lastCheck = _lastWeatherCheckByTrip[tripId];
    
    final needsCheck = lastCheck == null || 
        now.difference(lastCheck).inHours >= 24 ||
        !_isSameDay(now, lastCheck);
    
    if (!needsCheck) {
      
      return;
    }
    
    // Backend now handles checking if there are activities today
    // No need to check trip dates on frontend - let backend decide
    
    // Check weather alerts - backend will only return alerts if there are activities today
    try {
      final weatherAlerts = await _weatherService.checkWeatherAlerts(tripId);
      
      for (final alert in weatherAlerts) {
        await _addWeatherNotification(alert, tripId);
      }
      
      if (weatherAlerts.isNotEmpty) {
        
      } else {
        
      }
      
      _lastWeatherCheckByTrip[tripId] = now;
      
    } catch (weatherError) {
      
      // Don't update _lastWeatherCheckByTrip on failure, so it will retry
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> checkBudgetOnActivity(String tripId, String activityId, double actualCost) async {
    try {
      
      final warning = await _budgetService.checkBudgetOverage(activityId, actualCost, tripId: tripId);
      
      if (warning != null) {
        
        await _addBudgetWarningNotification(warning, tripId);
        
      } else {
        
      }
    } catch (e) {
      
    }
  }

  /// Call this method when user checks in to an activity
  /// This will automatically check for budget overages and create notifications
  Future<void> handleActivityCheckIn(String tripId, String activityId, String activityTitle, double actualCost) async {
    try {
      
      // Check for budget overage
      await checkBudgetOnActivity(tripId, activityId, actualCost);
      
      // You could also add other check-in related notifications here
      // like completion confirmations, next activity reminders, etc.
      
    } catch (e) {
      
    }
  }

  /// Force check weather notifications (useful for immediate checks)
  Future<void> forceWeatherCheck(String tripId) async {
    try {
      
      // Reset last check time to force new weather check for this trip
      _lastWeatherCheckByTrip[tripId] = null;
      
      // Check weather
      await _checkWeatherIfNeeded(tripId);
      
      notifyListeners();
    } catch (e) {
      
    }
  }

  /// Force weather check directly without conditions (for debugging)
  Future<void> forceWeatherCheckDirect(String tripId) async {
    try {
      
      final weatherAlerts = await _weatherService.checkWeatherAlerts(tripId);
      
      for (final alert in weatherAlerts) {
        await _addWeatherNotification(alert, tripId);
      }
      
      if (weatherAlerts.isNotEmpty) {
        
        notifyListeners();
      } else {
        
      }
      
    } catch (e) {
      
    }
  }

  /// ============================================
  /// NEW METHOD: Handle expense response with budget_warning
  /// ============================================
  /// Call this method after expense creation with the FULL expense response
  /// The response should contain a 'budget_warning' field if budget is exceeded
  Future<void> handleExpenseCreatedWithResponse(
    String tripId,
    dynamic expense, // Can be Map<String, dynamic> or Expense object
    String? activityId,
  ) async {
    try {
      
      // Extract budget warning from expense object
      Map<String, dynamic>? budgetWarning;
      
      // Handle both Expense object and Map types
      if (expense is Map<String, dynamic>) {
        budgetWarning = expense['budget_warning'] as Map<String, dynamic>?;
      } else {
        // Assume it's an Expense object with budgetWarning property
        try {
          final expenseObj = expense as dynamic;
          budgetWarning = expenseObj.budgetWarning as Map<String, dynamic>?;
        } catch (e) {
          
        }
      }
      
      if (budgetWarning != null) {
        
        // Create notification from budget_warning
        await _createBudgetNotificationFromResponse(budgetWarning, tripId);
        
      } else {
        
      }
      
    } catch (e) {
      
    }
  }

  /// Create budget notification from expense response budget_warning
  Future<void> _createBudgetNotificationFromResponse(
    Map<String, dynamic> budgetWarning,
    String tripId,
  ) async {
    try {
      final type = budgetWarning['type'] as String;
      final message = budgetWarning['message'] as String;
      
      // Determine notification severity and title based on type
      NotificationSeverity severity;
      String title;
      IconData icon;
      Color color;
      
      switch (type) {
        case 'OVER_BUDGET':
          severity = NotificationSeverity.critical;
          title = '🚨 Budget Exceeded!';
          icon = Icons.error;
          color = Colors.red;
          break;
          
        case 'WARNING':
          severity = NotificationSeverity.warning;
          title = '⚠️ Budget Running Low';
          icon = Icons.warning;
          color = Colors.orange;
          break;
          
        case 'NO_BUDGET':
          severity = NotificationSeverity.warning;
          title = '⚠️ No Budget Set';
          icon = Icons.info;
          color = Colors.blue;
          break;
          
        default:
          return;
      }
      
      // Create notification object
      final notification = SmartNotification(
        id: 'budget_${type.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.budget,
        severity: severity,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        icon: icon,
        color: color,
        data: budgetWarning,
      );
      
      // Initialize notifications list for this trip if needed
      if (_notificationsByTrip[tripId] == null) {
        _notificationsByTrip[tripId] = [];
      }
      
      // Add to notifications list
      _notificationsByTrip[tripId]!.insert(0, notification);
      
      // Save to Firebase
      await _notificationService.saveNotification(notification, tripId);
      
      // Update UI
      notifyListeners();
      
    } catch (e) {
      
    }
  }

  /// DEPRECATED: Use handleExpenseCreatedWithResponse instead
  /// This method makes unnecessary API calls
  @Deprecated('Use handleExpenseCreatedWithResponse with full expense response instead')
  Future<void> handleExpenseCreated(String tripId, double expenseAmount, String? activityId) async {
    try {
      
      // If expense is related to an activity, check specific activity budget
      if (activityId != null) {
        await checkBudgetOnActivity(tripId, activityId, expenseAmount);
      }
      
      // Always check general trip budget status
      try {
        final budgetWarnings = await _budgetService.checkTripBudgetStatus(tripId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            
            return <BudgetWarning>[];
          },
        );
        
        for (final warning in budgetWarnings) {
          await _addBudgetWarningNotification(warning, tripId);
        }
        
        if (budgetWarnings.isNotEmpty) {
          
          notifyListeners();
        }
      } catch (budgetError) {
        
      }
      
    } catch (e) {
      
    }
  }

  Future<void> _addWeatherNotification(WeatherAlert alert, String tripId) async {
    final notification = SmartNotification(
      id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.weather,
      severity: _getWeatherSeverity(alert.condition),
      title: 'Weather Alert',
      message: '${alert.description} at ${alert.location}. Temperature: ${alert.temperature.round()}°C',
      createdAt: DateTime.now(),
      icon: _getWeatherIcon(alert.condition),
      color: Colors.blue,
      data: alert.toJson(),
    );

    // Initialize notifications list for this trip if needed
    if (_notificationsByTrip[tripId] == null) {
      _notificationsByTrip[tripId] = [];
    }

    // Check if similar notification already exists (within last hour) for this trip
    final existingNotification = _notificationsByTrip[tripId]!.where((n) => 
      n.type == NotificationType.weather &&
      n.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)))
    ).firstOrNull;

    if (existingNotification == null) {
      _notificationsByTrip[tripId]!.insert(0, notification);
      await _notificationService.saveNotification(notification, tripId);
    }
  }

  Future<void> _addBudgetWarningNotification(BudgetWarning warning, String tripId) async {
    
    final notification = SmartNotification(
      id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.budget,
      severity: warning.overagePercentage > 50 ? NotificationSeverity.critical : NotificationSeverity.warning,
      title: 'Budget Exceeded',
      message: '${warning.activityTitle} has exceeded ${warning.overagePercentage.round()}% of planned budget',
      createdAt: DateTime.now(),
      icon: Icons.warning,
      color: Colors.orange,
      data: warning.toJson(),
    );

    // Initialize notifications list for this trip if needed
    if (_notificationsByTrip[tripId] == null) {
      _notificationsByTrip[tripId] = [];
    }
    
    _notificationsByTrip[tripId]!.insert(0, notification);
    await _notificationService.saveNotification(notification, tripId);
    notifyListeners(); // Force UI update
    
  }

  Future<void> _addActivityReminderNotification(ActivityReminder reminder, String tripId) async {
    final notification = SmartNotification(
      id: 'reminder_${reminder.activityId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.activity,
      severity: NotificationSeverity.info,
      title: 'Upcoming Activity',
      message: '${reminder.activityTitle} will start in ${reminder.minutesUntilStart} minutes at ${reminder.location}',
      createdAt: DateTime.now(),
      icon: Icons.schedule,
      color: Colors.green,
      data: reminder.toJson(),
    );

    // Initialize notifications list for this trip if needed
    if (_notificationsByTrip[tripId] == null) {
      _notificationsByTrip[tripId] = [];
    }

    // Check if reminder for this activity already sent (within last 2 hours) for this trip
    final existingReminder = _notificationsByTrip[tripId]!.where((n) => 
      n.type == NotificationType.activity &&
      n.data != null &&
      n.data!['activityId'] == reminder.activityId &&
      n.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 2)))
    ).firstOrNull;

    if (existingReminder == null) {
      _notificationsByTrip[tripId]!.insert(0, notification);
      await _notificationService.saveNotification(notification, tripId);
    }
  }

  Future<void> markAsRead(String notificationId, String tripId) async {
    if (_notificationsByTrip[tripId] != null) {
      final index = _notificationsByTrip[tripId]!.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notificationsByTrip[tripId]![index] = _notificationsByTrip[tripId]![index].copyWith(isRead: true);
        await _notificationService.markAsRead(notificationId, tripId);
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead(String tripId) async {
    if (_notificationsByTrip[tripId] != null) {
      for (int i = 0; i < _notificationsByTrip[tripId]!.length; i++) {
        if (!_notificationsByTrip[tripId]![i].isRead) {
          _notificationsByTrip[tripId]![i] = _notificationsByTrip[tripId]![i].copyWith(isRead: true);
        }
      }
      await _notificationService.markAllAsRead(tripId);
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId, String tripId) async {
    if (_notificationsByTrip[tripId] != null) {
      _notificationsByTrip[tripId]!.removeWhere((n) => n.id == notificationId);
      await _notificationService.deleteNotification(notificationId, tripId);
      notifyListeners();
    }
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
