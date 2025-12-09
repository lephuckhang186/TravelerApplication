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
  Map<String, List<SmartNotification>> _notificationsByTrip = {};
  Timer? _periodicTimer;
  Timer? _dailyWeatherTimer;
  Map<String, bool> _initializedTrips = {};
  Map<String, DateTime?> _lastWeatherCheckByTrip = {};

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
      debugPrint('SmartNotificationProvider: Already initialized for trip $tripId');
      return;
    }

    debugPrint('SmartNotificationProvider: Initializing for trip $tripId');
    
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
            debugPrint('SmartNotificationProvider: Loading notifications timed out - continuing with empty list');
          },
        );
      } catch (e) {
        debugPrint('SmartNotificationProvider: Loading notifications failed: $e');
      }

      // Start periodic timer only if not already running (for all initialized trips)
      if (_periodicTimer == null) {
        debugPrint('SmartNotificationProvider: Starting periodic timer for all trips');
        _periodicTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
          // Check all initialized trips
          for (String tripId in _initializedTrips.keys.where((key) => _initializedTrips[key] == true)) {
            debugPrint('SmartNotificationProvider: Periodic check for trip $tripId');
            _checkForNotifications(tripId);
          }
        });
      }

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

      // Force weather check on initialization to ensure weather is checked for today's activities
      try {
        await forceWeatherCheck(tripId);
      } catch (e) {
        debugPrint('SmartNotificationProvider: Initial weather check failed: $e');
      }

      _initializedTrips[tripId] = true;
      debugPrint('SmartNotificationProvider: Initialization completed successfully for trip $tripId');
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error during initialization for trip $tripId: $e');
      // Mark as initialized even if there were errors, so periodic checks can continue
      _initializedTrips[tripId] = true;
      notifyListeners();
    }
  }

  /// Force check weather for a specific trip (even if not initialized)
  Future<void> checkWeatherForTrip(String tripId) async {
    debugPrint('SmartNotificationProvider: Manual weather check requested for trip $tripId');
    
    // Initialize notifications list for this trip if it doesn't exist
    if (_notificationsByTrip[tripId] == null) {
      _notificationsByTrip[tripId] = [];
    }
    
    try {
      await forceWeatherCheck(tripId);
      debugPrint('SmartNotificationProvider: Manual weather check completed for trip $tripId');
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Manual weather check failed for trip $tripId: $e');
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
        
        debugPrint('SmartNotificationProvider: Cleared ${testNotifications.length} test notifications for trip $tripId');
      }
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error clearing test notifications for trip $tripId: $e');
    }
  }



  Future<void> _loadNotifications(String tripId) async {
    try {
      final notifications = await _notificationService.getNotifications(tripId);
      _notificationsByTrip[tripId] = notifications;
      debugPrint('SmartNotificationProvider: Loaded ${notifications.length} notifications for trip $tripId');
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error loading notifications for trip $tripId: $e');
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

      // Check for budget warnings (general budget checks)
      try {
        debugPrint('SmartNotificationProvider: Checking general budget status');
        final budgetWarnings = await _budgetService.checkTripBudgetStatus(tripId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('SmartNotificationProvider: Budget service timeout');
            return <BudgetWarning>[];
          },
        );
        
        for (final warning in budgetWarnings) {
          await _addBudgetWarningNotification(warning, tripId);
        }
        
        if (budgetWarnings.isNotEmpty) {
          debugPrint('SmartNotificationProvider: Added ${budgetWarnings.length} budget warnings');
        }
      } catch (budgetError) {
        final errorString = budgetError.toString().toLowerCase();
        if (errorString.contains('failed to fetch') || 
            errorString.contains('clientexception') ||
            errorString.contains('socketexception') ||
            errorString.contains('connection')) {
          debugPrint('SmartNotificationProvider: Network unavailable for budget checks - will retry later');
        } else {
          debugPrint('SmartNotificationProvider: Budget service error: $budgetError');
        }
        // Continue without budget checks if service is down
      }

      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error checking notifications: $e');
    }
  }

  Future<void> _checkWeatherIfNeeded(String tripId) async {
    final now = DateTime.now();
    
    debugPrint('SmartNotificationProvider: Weather check started for trip $tripId');
    
    // Check if we need to check weather (haven't checked today)
    final lastCheck = _lastWeatherCheckByTrip[tripId];
    debugPrint('SmartNotificationProvider: Last weather check for trip $tripId: $lastCheck');
    
    final needsCheck = lastCheck == null || 
        now.difference(lastCheck).inHours >= 24 ||
        !_isSameDay(now, lastCheck);
    
    if (!needsCheck) {
      debugPrint('SmartNotificationProvider: Weather already checked today - skipping');
      return;
    }
    
    // Backend now handles checking if there are activities today
    // No need to check trip dates on frontend - let backend decide
    debugPrint('SmartNotificationProvider: Calling backend to check weather (backend will verify activities today)');
    
    // Check weather alerts - backend will only return alerts if there are activities today
    try {
      final weatherAlerts = await _weatherService.checkWeatherAlerts(tripId);
      
      for (final alert in weatherAlerts) {
        await _addWeatherNotification(alert, tripId);
      }
      
      if (weatherAlerts.isNotEmpty) {
        debugPrint('SmartNotificationProvider: Added ${weatherAlerts.length} weather notifications');
      } else {
        debugPrint('SmartNotificationProvider: No weather alerts generated (either good weather or no activities today)');
      }
      
      _lastWeatherCheckByTrip[tripId] = now;
      debugPrint('SmartNotificationProvider: Weather check completed successfully for trip $tripId');
    } catch (weatherError) {
      debugPrint('SmartNotificationProvider: Weather check failed for trip $tripId: $weatherError');
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
      debugPrint('SmartNotificationProvider: Checking budget for activity $activityId, cost: $actualCost');
      
      final warning = await _budgetService.checkBudgetOverage(activityId, actualCost, tripId: tripId);
      
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

  /// Force check weather notifications (useful for immediate checks)
  Future<void> forceWeatherCheck(String tripId) async {
    try {
      debugPrint('SmartNotificationProvider: Force checking weather for trip $tripId');
      
      // Reset last check time to force new weather check for this trip
      _lastWeatherCheckByTrip[tripId] = null;
      
      // Check weather
      await _checkWeatherIfNeeded(tripId);
      
      debugPrint('SmartNotificationProvider: Force weather check completed for trip $tripId');
      notifyListeners();
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error in force weather check for trip $tripId: $e');
    }
  }

  /// Force weather check directly without conditions (for debugging)
  Future<void> forceWeatherCheckDirect(String tripId) async {
    try {
      debugPrint('SmartNotificationProvider: Direct weather check for trip $tripId');
      
      final weatherAlerts = await _weatherService.checkWeatherAlerts(tripId);
      
      for (final alert in weatherAlerts) {
        await _addWeatherNotification(alert, tripId);
      }
      
      if (weatherAlerts.isNotEmpty) {
        debugPrint('SmartNotificationProvider: Added ${weatherAlerts.length} weather notifications (direct)');
        notifyListeners();
      } else {
        debugPrint('SmartNotificationProvider: No weather alerts from direct check');
      }
      
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error in direct weather check: $e');
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
      debugPrint('SmartNotificationProvider: Expense creation notification triggered');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Activity ID: $activityId');
      
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
          debugPrint('SmartNotificationProvider: Could not extract budget warning from expense object: $e');
        }
      }
      
      if (budgetWarning != null) {
        debugPrint('⚠️ BUDGET WARNING FOUND IN EXPENSE RESPONSE!');
        debugPrint('   Type: ${budgetWarning['type']}');
        debugPrint('   Message: ${budgetWarning['message']}');
        
        // Create notification from budget_warning
        await _createBudgetNotificationFromResponse(budgetWarning, tripId);
        
      } else {
        debugPrint('SmartNotificationProvider: No budget warning - spending is within budget');
      }
      
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error handling expense creation: $e');
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
          title = '🚨 Vượt ngân sách!';
          icon = Icons.error;
          color = Colors.red;
          debugPrint('⚠️ CREATING OVER_BUDGET NOTIFICATION');
          break;
          
        case 'WARNING':
          severity = NotificationSeverity.warning;
          title = '⚠️ Sắp hết ngân sách';
          icon = Icons.warning;
          color = Colors.orange;
          debugPrint('⚠️ CREATING WARNING NOTIFICATION');
          break;
          
        case 'NO_BUDGET':
          severity = NotificationSeverity.warning;
          title = '⚠️ Chưa đặt ngân sách';
          icon = Icons.info;
          color = Colors.blue;
          debugPrint('⚠️ CREATING NO_BUDGET NOTIFICATION');
          break;
          
        default:
          debugPrint('SmartNotificationProvider: Unknown budget warning type: $type');
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
      
      debugPrint('✅ Budget notification created successfully from expense response!');
      debugPrint('   ID: ${notification.id}');
      debugPrint('   Title: $title');
      debugPrint('   Message: $message');
      debugPrint('   Total notifications for trip $tripId: ${_notificationsByTrip[tripId]?.length ?? 0}');
      
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error creating budget notification from response: $e');
    }
  }

  /// DEPRECATED: Use handleExpenseCreatedWithResponse instead
  /// This method makes unnecessary API calls
  @Deprecated('Use handleExpenseCreatedWithResponse with full expense response instead')
  Future<void> handleExpenseCreated(String tripId, double expenseAmount, String? activityId) async {
    try {
      debugPrint('SmartNotificationProvider: Handling expense creation (DEPRECATED method) - Amount: $expenseAmount, TripId: $tripId, ActivityId: $activityId');
      
      // If expense is related to an activity, check specific activity budget
      if (activityId != null) {
        await checkBudgetOnActivity(tripId, activityId, expenseAmount);
      }
      
      // Always check general trip budget status
      debugPrint('SmartNotificationProvider: Checking trip budget after expense creation');
      try {
        final budgetWarnings = await _budgetService.checkTripBudgetStatus(tripId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('SmartNotificationProvider: Budget check timeout after expense creation');
            return <BudgetWarning>[];
          },
        );
        
        for (final warning in budgetWarnings) {
          await _addBudgetWarningNotification(warning, tripId);
        }
        
        if (budgetWarnings.isNotEmpty) {
          debugPrint('SmartNotificationProvider: Created ${budgetWarnings.length} budget notifications after expense');
          notifyListeners();
        }
      } catch (budgetError) {
        debugPrint('SmartNotificationProvider: Error checking trip budget after expense: $budgetError');
      }
      
    } catch (e) {
      debugPrint('SmartNotificationProvider: Error handling expense creation: $e');
    }
  }

  Future<void> _addWeatherNotification(WeatherAlert alert, String tripId) async {
    final notification = SmartNotification(
      id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.weather,
      severity: _getWeatherSeverity(alert.condition),
      title: 'Cảnh báo thời tiết',
      message: '${alert.description} tại ${alert.location}. Nhiệt độ: ${alert.temperature.round()}°C',
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
    debugPrint('SmartNotificationProvider: Adding budget warning notification for ${warning.activityTitle}');
    
    final notification = SmartNotification(
      id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.budget,
      severity: warning.overagePercentage > 50 ? NotificationSeverity.critical : NotificationSeverity.warning,
      title: 'Vượt ngân sách',
      message: '${warning.activityTitle} đã vượt ${warning.overagePercentage.round()}% ngân sách dự kiến',
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
    
    debugPrint('SmartNotificationProvider: Budget warning notification added. Total notifications for trip $tripId: ${_notificationsByTrip[tripId]?.length ?? 0}');
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
