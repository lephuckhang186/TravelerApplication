import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/Plan/models/activity_models.dart';

/// Simplified activity models test focused on code coverage
void main() {
  group('ActivityType enum tests', () {
    test('fromString returns correct ActivityType for valid values', () {
      expect(ActivityType.fromString('flight'), ActivityType.flight);
      expect(ActivityType.fromString('activity'), ActivityType.activity);
      expect(ActivityType.fromString('lodging'), ActivityType.lodging);
      expect(ActivityType.fromString('restaurant'), ActivityType.restaurant);
    });

    test('fromString returns default for invalid value', () {
      expect(ActivityType.fromString('invalid'), ActivityType.activity);
    });

    test('value property returns correct string', () {
      expect(ActivityType.flight.value, 'flight');
      expect(ActivityType.restaurant.value, 'restaurant');
    });
  });

  group('ActivityStatus enum tests', () {
    test('fromString returns correct ActivityStatus', () {
      expect(ActivityStatus.fromString('planned'), ActivityStatus.planned);
      expect(ActivityStatus.fromString('confirmed'), ActivityStatus.confirmed);
      expect(
        ActivityStatus.fromString('in_progress'),
        ActivityStatus.inProgress,
      );
    });

    test('value property works correctly', () {
      expect(ActivityStatus.planned.value, 'planned');
      expect(ActivityStatus.inProgress.value, 'in_progress');
    });
  });

  group('Priority enum tests', () {
    test('fromString returns correct Priority', () {
      expect(Priority.fromString('low'), Priority.low);
      expect(Priority.fromString('high'), Priority.high);
    });
  });

  group('LocationModel tests', () {
    test('constructor and toJson work correctly', () {
      final location = LocationModel(
        name: 'Test Place',
        address: '123 Main St',
        latitude: 10.0,
        longitude: 105.0,
      );

      expect(location.name, 'Test Place');

      final json = location.toJson();
      expect(json['name'], 'Test Place');
      expect(json['latitude'], 10.0);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'name': 'Place',
        'address': '456 St',
        'latitude': 20.5,
        'longitude': 105.3,
      };

      final location = LocationModel.fromJson(json);
      expect(location.name, 'Place');
      expect(location.latitude, 20.5);
    });
  });

  group('BudgetModel tests', () {
    test('constructor initializes correctly', () {
      final budget = BudgetModel(
        estimatedCost: 1000.0,
        actualCost: 500.0,
        currency: 'USD',
      );

      expect(budget.estimatedCost, 1000.0);
      expect(budget.actualCost, 500.0);
    });

    test('copyWithActualCost updates cost', () {
      final budget = BudgetModel(estimatedCost: 1000.0);
      final updated = budget.copyWithActualCost(750.0);

      expect(updated.actualCost, 750.0);
      expect(updated.estimatedCost, 1000.0);
    });

    test('budget calculations work correctly', () {
      final budget = BudgetModel(estimatedCost: 1000.0, actualCost: 700.0);

      expect(budget.remainingBudget, 300.0);
      expect(budget.usagePercentage, 70.0);
      expect(budget.isOverBudget, false);
    });

    test('detects over budget', () {
      final budget = BudgetModel(estimatedCost: 100.0, actualCost: 150.0);

      expect(budget.isOverBudget, true);
      expect(budget.budgetStatus, 'Over Budget');
    });

    test('toJson and fromJson work correctly', () {
      final budget = BudgetModel(
        estimatedCost: 2000.0,
        actualCost: 1500.0,
        currency: 'EUR',
      );

      final json = budget.toJson();
      expect(json['estimated_cost'], 2000.0);

      final decoded = BudgetModel.fromJson(json);
      expect(decoded.estimatedCost, 2000.0);
      expect(decoded.actualCost, 1500.0);
    });
  });

  group('ContactModel tests', () {
    test('toJson and fromJson round trip', () {
      final contact = ContactModel(
        name: 'Hotel',
        phone: '+123',
        email: 'test@hotel.com',
      );

      final json = contact.toJson();
      final decoded = ContactModel.fromJson(json);

      expect(decoded.name, 'Hotel');
      expect(decoded.phone, '+123');
    });
  });

  group('ExpenseInfo tests', () {
    test('copyWith updates fields', () {
      final info = ExpenseInfo();
      final updated = info.copyWith(expenseId: 'exp123', hasExpense: true);

      expect(updated.expenseId, 'exp123');
      expect(updated.hasExpense, true);
    });

    test('toJson and fromJson work', () {
      final info = ExpenseInfo(
        expenseId: 'exp123',
        hasExpense: true,
        expenseCategory: 'flight',
      );

      final json = info.toJson();
      final decoded = ExpenseInfo.fromJson(json);

      expect(decoded.expenseId, 'exp123');
      expect(decoded.hasExpense, true);
    });
  });

  group('ActivityModel tests', () {
    test('constructor works correctly', () {
      final activity = ActivityModel(
        id: 'act123',
        title: 'Museum Visit',
        activityType: ActivityType.activity,
      );

      expect(activity.id, 'act123');
      expect(activity.title, 'Museum Visit');
      expect(activity.status, ActivityStatus.planned); // default
    });

    test('copyWith updates fields', () {
      final activity = ActivityModel(
        title: 'Original',
        activityType: ActivityType.activity,
      );

      final updated = activity.copyWith(title: 'Updated', checkIn: true);

      expect(updated.title, 'Updated');
      expect(updated.checkIn, true);
    });

    test('toJson serializes correctly', () {
      final activity = ActivityModel(
        id: 'act123',
        title: 'Visit',
        activityType: ActivityType.flight,
        status: ActivityStatus.confirmed,
        priority: Priority.high,
      );

      final json = activity.toJson();
      expect(json['id'], 'act123');
      expect(json['title'], 'Visit');
      expect(json['activity_type'], 'flight');
      expect(json['status'], 'confirmed');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'act456',
        'title': 'Tower Visit',
        'activity_type': 'activity',
        'status': 'planned',
        'priority': 'medium',
        'tags': ['culture'],
        'attachments': [],
      };

      final activity = ActivityModel.fromJson(json);
      expect(activity.id, 'act456');
      expect(activity.title, 'Tower Visit');
      expect(activity.activityType, ActivityType.activity);
      expect(activity.tags, ['culture']);
    });
  });
}
