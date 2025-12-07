import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_models.dart';
import 'package:flutter/foundation.dart';

class SmartNotificationService {
  static const String _notificationsKey = 'smart_notifications';

  Future<List<SmartNotification>> getNotifications(String tripId) async {
    try {
      debugPrint('SmartNotificationService: Loading notifications for trip $tripId');
      final prefs = await SharedPreferences.getInstance();
      final key = '${_notificationsKey}_$tripId';
      final notificationsJson = prefs.getString(key);
      
      debugPrint('SmartNotificationService: Retrieved data: $notificationsJson');
      
      if (notificationsJson == null) {
        debugPrint('SmartNotificationService: No notifications found for trip $tripId');
        return [];
      }

      final List<dynamic> notificationsList = jsonDecode(notificationsJson);
      final notifications = notificationsList
          .map((json) => SmartNotification.fromJson(json))
          .toList();
          
      debugPrint('SmartNotificationService: Loaded ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      debugPrint('SmartNotificationService: Error loading notifications: $e');
      return [];
    }
  }

  Future<void> saveNotification(SmartNotification notification, String tripId) async {
    try {
      debugPrint('SmartNotificationService: Saving notification ${notification.id} for trip $tripId');
      final notifications = await getNotifications(tripId);
      notifications.insert(0, notification);
      
      // Keep only last 50 notifications
      if (notifications.length > 50) {
        notifications.removeRange(50, notifications.length);
      }

      await _saveAllNotifications(notifications, tripId);
      debugPrint('SmartNotificationService: Successfully saved ${notifications.length} notifications');
    } catch (e) {
      debugPrint('SmartNotificationService: Error saving notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // Implementation would depend on specific storage mechanism
    // For now, we'll handle this in the provider
  }

  Future<void> markAllAsRead() async {
    // Implementation would depend on specific storage mechanism
    // For now, we'll handle this in the provider
  }

  Future<void> deleteNotification(String notificationId) async {
    // Implementation would depend on specific storage mechanism
    // For now, we'll handle this in the provider
  }

  Future<void> _saveAllNotifications(List<SmartNotification> notifications, String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_notificationsKey}_$tripId';
      final notificationsJson = jsonEncode(
        notifications.map((n) => n.toJson()).toList(),
      );
      
      debugPrint('SmartNotificationService: Saving to key: $key');
      debugPrint('SmartNotificationService: Data to save: ${notificationsJson.substring(0, notificationsJson.length > 200 ? 200 : notificationsJson.length)}...');
      
      await prefs.setString(key, notificationsJson);
      debugPrint('SmartNotificationService: Successfully saved to SharedPreferences');
    } catch (e) {
      debugPrint('SmartNotificationService: Error saving all notifications: $e');
    }
  }
}