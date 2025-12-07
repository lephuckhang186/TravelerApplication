import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_models.dart';
import 'package:flutter/foundation.dart';

/// Smart Notification Service - Firebase Only
/// All notifications are stored in Firebase Firestore
/// No local storage or JSON files are used
class SmartNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<SmartNotification>> getNotifications(String tripId) async {
    try {
      debugPrint('SmartNotificationService: Loading notifications for trip $tripId');
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('SmartNotificationService: No authenticated user');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(100) // Limit to last 100 notifications
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => SmartNotification.fromFirestore(doc.data(), doc.id))
          .toList();
          
      debugPrint('SmartNotificationService: Loaded ${notifications.length} notifications from Firebase');
      return notifications;
    } catch (e) {
      debugPrint('SmartNotificationService: Error loading notifications: $e');
      return [];
    }
  }

  Future<void> saveNotification(SmartNotification notification, String tripId) async {
    try {
      debugPrint('SmartNotificationService: Saving notification ${notification.id} for trip $tripId');
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('SmartNotificationService: No authenticated user');
        return;
      }

      final notificationData = notification.toFirestore();
      notificationData['tripId'] = tripId;
      notificationData['userId'] = user.uid;
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .doc(notification.id)
          .set(notificationData);
          
      debugPrint('SmartNotificationService: Successfully saved notification to Firebase');
      
      // Clean up old notifications (keep only last 100)
      await _cleanupOldNotifications(tripId, user.uid);
    } catch (e) {
      debugPrint('SmartNotificationService: Error saving notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId, String tripId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
          
      debugPrint('SmartNotificationService: Marked notification $notificationId as read');
    } catch (e) {
      debugPrint('SmartNotificationService: Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String tripId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      debugPrint('SmartNotificationService: Marked all notifications as read');
    } catch (e) {
      debugPrint('SmartNotificationService: Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId, String tripId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
          
      debugPrint('SmartNotificationService: Deleted notification $notificationId');
    } catch (e) {
      debugPrint('SmartNotificationService: Error deleting notification: $e');
    }
  }

  /// Clear all notifications for a specific trip
  Future<void> clearAllNotifications(String tripId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('SmartNotificationService: Cleared all ${querySnapshot.docs.length} notifications for trip $tripId');
    } catch (e) {
      debugPrint('SmartNotificationService: Error clearing all notifications: $e');
    }
  }

  Future<void> _cleanupOldNotifications(String tripId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      if (querySnapshot.docs.length > 100) {
        final batch = _firestore.batch();
        final docsToDelete = querySnapshot.docs.skip(100);
        
        for (final doc in docsToDelete) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        debugPrint('SmartNotificationService: Cleaned up ${docsToDelete.length} old notifications');
      }
    } catch (e) {
      debugPrint('SmartNotificationService: Error cleaning up old notifications: $e');
    }
  }
}