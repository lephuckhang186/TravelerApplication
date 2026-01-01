import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/Expense/models/expense_models.dart';

void main() {
  group('ExpenseCategory enum tests', () {
    test('fromString returns correct category', () {
      expect(
        ExpenseCategoryExtension.fromString('flight'),
        ExpenseCategory.flight,
      );
      expect(
        ExpenseCategoryExtension.fromString('restaurant'),
        ExpenseCategory.restaurant,
      );
      expect(
        ExpenseCategoryExtension.fromString('lodging'),
        ExpenseCategory.lodging,
      );
    });

    test('returns default for invalid category', () {
      expect(
        ExpenseCategoryExtension.fromString('invalid'),
        ExpenseCategory.miscellaneous,
      );
    });

    test('value getter returns correct string', () {
      expect(ExpenseCategory.flight.value, 'flight');
      expect(ExpenseCategory.restaurant.value, 'restaurant');
    });

    test('displayName returns formatted names', () {
      expect(ExpenseCategory.flight.displayName, 'Flight');
      expect(ExpenseCategory.carRental.displayName, 'Car Rental');
    });
  });

  group('Expense model tests', () {
    test('constructor initializes fields correctly', () {
      final expense = Expense(
        id: 'exp123',
        amount: 150.0,
        category: ExpenseCategory.restaurant,
        date: DateTime(2024, 1, 15),
        description: 'Dinner',
        currency: 'USD',
      );

      expect(expense.id, 'exp123');
      expect(expense.amount, 150.0);
      expect(expense.category, ExpenseCategory.restaurant);
      expect(expense.isValid, true);
    });

    test('validates expense amount', () {
      final validExpense = Expense(
        id: '1',
        amount: 100.0,
        category: ExpenseCategory.flight,
        date: DateTime.now(),
      );
      expect(validExpense.isValid, true);

      final invalidExpense = Expense(
        id: '2',
        amount: -50.0,
        category: ExpenseCategory.flight,
        date: DateTime.now(),
      );
      expect(invalidExpense.isValid, false);
    });

    test('toJson serializes correctly', () {
      final expense = Expense(
        id: 'exp456',
        amount: 200.0,
        category: ExpenseCategory.lodging,
        date: DateTime(2024, 2, 1),
        description: 'Hotel',
        currency: 'EUR',
        tripId: 'trip123',
      );

      final json = expense.toJson();
      expect(json['id'], 'exp456');
      expect(json['amount'], 200.0);
      expect(json['category'], 'lodging');
      expect(json['planner_id'], 'trip123');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'exp789',
        'amount': 300.0,
        'category': 'flight',
        'expense_date': '2024-03-01T00:00:00.00',
        'description': 'Plane ticket',
        'currency': 'USD',
        'planner_id': 'trip456',
      };

      final expense = Expense.fromJson(json);
      expect(expense.id, 'exp789');
      expect(expense.amount, 300.0);
      expect(expense.category, ExpenseCategory.flight);
      expect(expense.tripId, 'trip456');
    });

    test('expenseDate getter works', () {
      final date = DateTime(2024, 1, 15);
      final expense = Expense(
        id: '1',
        amount: 100.0,
        category: ExpenseCategory.activity,
        date: date,
      );
      expect(expense.expenseDate, date);
    });
  });

  group('ExpenseCreateRequest tests', () {
    test('validates request data', () {
      final validRequest = ExpenseCreateRequest(
        amount: 100.0,
        category: ExpenseCategory.restaurant,
      );
      expect(validRequest.isValid, true);

      final invalidRequest = ExpenseCreateRequest(
        amount: 0.0,
        category: ExpenseCategory.restaurant,
      );
      expect(invalidRequest.isValid, false);
    });

    test('toJson serializes correctly', () {
      final request = ExpenseCreateRequest(
        amount: 150.0,
        category: ExpenseCategory.shopping,
        description: 'Souvenirs',
        tripId: 'trip123',
      );

      final json = request.toJson();
      expect(json['amount'], 150.0);
      expect(json['category'], 'shopping');
      expect(json['description'], 'Souvenirs');
      expect(json['planner_id'], 'trip123');
    });
  });

  group('Budget model tests', () {
    test('constructor and validation', () {
      final budget = Budget(totalBudget: 1000.0);
      expect(budget.isValid, true);

      final invalidBudget = Budget(totalBudget: -100.0);
      expect(invalidBudget.isValid, false);
    });

    test('calculates total allocated correctly', () {
      final budget = Budget(
        totalBudget: 1000.0,
        categoryAllocations: {
          'food': 300.0,
          'transport': 200.0,
          'accommodation': 400.0,
        },
      );

      expect(budget.totalAllocated, 900.0);
      expect(budget.unallocated, 100.0);
    });

    test('toJson and fromJson work correctly', () {
      final budget = Budget(
        totalBudget: 2000.0,
        dailyLimit: 100.0,
        categoryAllocations: {'food': 500.0},
      );

      final json = budget.toJson();
      final decoded = Budget.fromJson(json);

      expect(decoded.totalBudget, 2000.0);
      expect(decoded.dailyLimit, 100.0);
    });
  });

  group('Trip model tests', () {
    test('calculates trip duration correctly', () {
      final trip = Trip(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
        name: 'Test Trip',
        destination: 'Paris',
      );

      expect(trip.totalDays, 5);
    });

    test('determines active status', () {
      final now = DateTime.now();
      final activeTrip = Trip(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        name: 'Active Trip',
        destination: 'London',
      );

      expect(activeTrip.isActive, true);
    });

    test('toJson and fromJson work', () {
      final trip = Trip(
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 10),
        name: 'Summer Trip',
        destination: 'Rome',
      );

      final json = trip.toJson();
      final decoded = Trip.fromJson(json);

      expect(decoded.name, 'Summer Trip');
      expect(decoded.destination, 'Rome');
    });
  });

  group('CategoryBudget tests', () {
    test('calculates remaining budget', () {
      final catBudget = CategoryBudget(
        allocatedAmount: 500.0,
        spentAmount: 300.0,
      );

      expect(catBudget.remaining, 200.0);
      expect(catBudget.percentageUsed, 60.0);
      expect(catBudget.isOverBudget, false);
    });

    test('detects over budget', () {
      final catBudget = CategoryBudget(
        allocatedAmount: 100.0,
        spentAmount: 150.0,
      );

      expect(catBudget.isOverBudget, true);
    });
  });

  group('BurnRateStatus enum tests', () {
    test('fromString parses correctly', () {
      expect(
        BurnRateStatusExtension.fromString('COMPLETED'),
        BurnRateStatus.completed,
      );
      expect(
        BurnRateStatusExtension.fromString('HIGH_BURN'),
        BurnRateStatus.highBurn,
      );
      expect(
        BurnRateStatusExtension.fromString('ON_TRACK'),
        BurnRateStatus.onTrack,
      );
    });

    test('value getter works', () {
      expect(BurnRateStatus.completed.value, 'COMPLETED');
      expect(BurnRateStatus.highBurn.value, 'HIGH_BURN');
    });
  });

  group('CategoryStatusType enum tests', () {
    test('fromString parses correctly', () {
      expect(
        CategoryStatusTypeExtension.fromString('OVER_BUDGET'),
        CategoryStatusType.overBudget,
      );
      expect(
        CategoryStatusTypeExtension.fromString('WARNING'),
        CategoryStatusType.warning,
      );
      expect(
        CategoryStatusTypeExtension.fromString('OK'),
        CategoryStatusType.ok,
      );
    });
  });

  group('SpendingTrendType enum tests', () {
    test('fromString parses correctly', () {
      expect(
        SpendingTrendTypeExtension.fromString('INCREASING'),
        SpendingTrendType.increasing,
      );
      expect(
        SpendingTrendTypeExtension.fromString('STABLE'),
        SpendingTrendType.stable,
      );
    });
  });
}
