import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/smart-nofications/models/notification_models.dart';

void main() {
  group('NotificationType enum tests', () {
    test('has correct values', () {
      expect(NotificationType.weather, isNotNull);
      expect(NotificationType.budget, isNotNull);
      expect(NotificationType.activity, isNotNull);
    });
  });

  group('NotificationSeverity enum tests', () {
    test('has correct values', () {
      expect(NotificationSeverity.info, isNotNull);
      expect(NotificationSeverity.warning, isNotNull);
      expect(NotificationSeverity.critical, isNotNull);
    });
  });

  group('SmartNotification model tests', () {
    test('creates notification with required fields', () {
      final notification = SmartNotification(
        id: 'notif1',
        type: NotificationType.weather,
        severity: NotificationSeverity.warning,
        title: 'Weather Alert',
        message: 'Heavy rain expected',
        createdAt: DateTime(2024, 1, 1),
        icon: Icons.cloud,
        color: Colors.blue,
      );

      expect(notification.id, 'notif1');
      expect(notification.type, NotificationType.weather);
      expect(notification.severity, NotificationSeverity.warning);
      expect(notification.title, 'Weather Alert');
      expect(notification.isRead, false); // default
    });

    test('copyWith updates fields correctly', () {
      final notification = SmartNotification(
        id: 'notif1',
        type: NotificationType.weather,
        severity: NotificationSeverity.info,
        title: 'Test',
        message: 'Message',
        createdAt: DateTime(2024, 1, 1),
        icon: Icons.cloud,
        color: Colors.blue,
      );

      final updated = notification.copyWith(
        isRead: true,
        title: 'Updated Title',
      );

      expect(updated.isRead, true);
      expect(updated.title, 'Updated Title');
      expect(updated.id, 'notif1'); // Unchanged
    });

    test('toFirestore serializes correctly', () {
      final notification = SmartNotification(
        id: 'notif1',
        type: NotificationType.budget,
        severity: NotificationSeverity.critical,
        title: 'Budget Warning',
        message: 'Over budget',
        createdAt: DateTime(2024, 1, 1),
        isRead: true,
        icon: Icons.warning,
        color: Colors.orange,
      );

      final firestore = notification.toFirestore();

      expect(firestore['type'], 'budget');
      expect(firestore['severity'], 'critical');
      expect(firestore['title'], 'Budget Warning');
      expect(firestore['isRead'], true);
    });

    test('fromFirestore deserializes correctly', () {
      final data = {
        'type': 'weather',
        'severity': 'warning',
        'title': 'Weather Alert',
        'message': 'Storm coming',
        'createdAt': DateTime(2024, 1, 1),
        'isRead': false,
      };

      final notification = SmartNotification.fromFirestore(data, 'doc123');

      expect(notification.id, 'doc123');
      expect(notification.type, NotificationType.weather);
      expect(notification.severity, NotificationSeverity.warning);
      expect(notification.title, 'Weather Alert');
    });
  });

  group('WeatherAlert model tests', () {
    test('creates weather alert with required fields', () {
      final alert = WeatherAlert(
        condition: 'Rain',
        description: 'Heavy rain expected',
        temperature: 25.5,
        location: 'Hanoi',
        alertTime: DateTime(2024, 1, 1),
      );

      expect(alert.condition, 'Rain');
      expect(alert.temperature, 25.5);
      expect(alert.location, 'Hanoi');
    });

    test('toJson and fromJson work correctly', () {
      final alert = WeatherAlert(
        condition: 'Storm',
        description: 'Thunderstorm',
        temperature: 28.0,
        location: 'HCMC',
        alertTime: DateTime(2024, 6, 1, 10, 0),
      );

      final json = alert.toJson();
      expect(json['condition'], 'Storm');
      expect(json['temperature'], 28.0);

      final decoded = WeatherAlert.fromJson(json);
      expect(decoded.condition, 'Storm');
      expect(decoded.temperature, 28.0);
      expect(decoded.location, 'HCMC');
    });
  });

  group('BudgetWarning model tests', () {
    test('creates budget warning', () {
      final warning = BudgetWarning(
        activityTitle: 'Hotel Booking',
        estimatedCost: 1000.0,
        actualCost: 1200.0,
        overageAmount: 200.0,
        overagePercentage: 20.0,
        currency: 'USD',
      );

      expect(warning.activityTitle, 'Hotel Booking');
      expect(warning.estimatedCost, 1000.0);
      expect(warning.actualCost, 1200.0);
      expect(warning.overageAmount, 200.0);
      expect(warning.overagePercentage, 20.0);
    });

    test('toJson and fromJson work correctly', () {
      final warning = BudgetWarning(
        activityTitle: 'Restaurant',
        estimatedCost: 500.0,
        actualCost: 600.0,
        overageAmount: 100.0,
        overagePercentage: 20.0,
      );

      final json = warning.toJson();
      expect(json['activityTitle'], 'Restaurant');
      expect(json['overageAmount'], 100.0);

      final decoded = BudgetWarning.fromJson(json);
      expect(decoded.activityTitle, 'Restaurant');
      expect(decoded.overagePercentage, 20.0);
    });

    test('uses default currency', () {
      final warning = BudgetWarning(
        activityTitle: 'Test',
        estimatedCost: 100.0,
        actualCost: 120.0,
        overageAmount: 20.0,
        overagePercentage: 20.0,
      );

      expect(warning.currency, 'VND'); // default
    });
  });

  group('ActivityReminder model tests', () {
    test('creates activity reminder', () {
      final reminder = ActivityReminder(
        activityId: 'act123',
        activityTitle: 'Museum Visit',
        location: 'National Museum',
        startTime: DateTime(2024, 6, 1, 10, 0),
        minutesUntilStart: 30,
      );

      expect(reminder.activityId, 'act123');
      expect(reminder.activityTitle, 'Museum Visit');
      expect(reminder.minutesUntilStart, 30);
    });

    test('toJson and fromJson work correctly', () {
      final reminder = ActivityReminder(
        activityId: 'act456',
        activityTitle: 'Flight Departure',
        location: 'Airport',
        startTime: DateTime(2024, 6, 5, 14, 30),
        minutesUntilStart: 120,
      );

      final json = reminder.toJson();
      expect(json['activityId'], 'act456');
      expect(json['minutesUntilStart'], 120);

      final decoded = ActivityReminder.fromJson(json);
      expect(decoded.activityId, 'act456');
      expect(decoded.activityTitle, 'Flight Departure');
      expect(decoded.location, 'Airport');
    });
  });
}
