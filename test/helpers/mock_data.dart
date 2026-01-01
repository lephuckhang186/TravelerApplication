import 'package:flutter_application_1/Plan/models/trip_model.dart';
import 'package:flutter_application_1/Plan/models/activity_models.dart';
import 'package:flutter_application_1/Expense/models/expense_models.dart';

/// Mock data for testing
class MockData {
  // Sample Location
  static LocationModel sampleLocation = LocationModel(
    name: 'Test Place',
    address: '123 Test Street, Test City',
    latitude: 10.762622,
    longitude: 106.660172,
    city: 'Test City',
    country: 'Test Country',
    postalCode: '12345',
  );

  // Sample Budget
  static BudgetModel sampleBudget = BudgetModel(
    estimatedCost: 800.0,
    actualCost: 500.0,
    currency: 'USD',
    category: 'travel',
  );

  // Sample Activity
  static ActivityModel sampleActivity = ActivityModel(
    id: 'activity_001',
    title: 'Visit Museum',
    description: 'Explore the city museum',
    activityType: ActivityType.activity,
    status: ActivityStatus.planned,
    priority: Priority.medium,
    startDate: DateTime(2024, 1, 15, 10, 0),
    endDate: DateTime(2024, 1, 15, 12, 0),
    durationMinutes: 120,
    location: sampleLocation,
    budget: sampleBudget,
    notes: 'Remember to bring camera',
    tags: ['culture', 'museum'],
    attachments: [],
    tripId: 'trip_001',
    checkIn: false,
    createdBy: 'user_001',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    expenseInfo: ExpenseInfo(
      expenseId: null,
      hasExpense: false,
      expenseCategory: null,
      autoSynced: false,
      expenseSynced: false,
    ),
  );

  // Sample Trip
  static TripModel sampleTrip = TripModel(
    id: 'trip_001',
    name: 'European Adventure',
    destination: 'Paris, France',
    startDate: DateTime(2024, 1, 15),
    endDate: DateTime(2024, 1, 20),
    description: 'A wonderful trip to Europe',
    activities: [sampleActivity],
    budget: BudgetModel(
      estimatedCost: 4500.0,
      actualCost: 0.0,
      currency: 'USD',
    ),
    collaborators: ['user_001', 'user_002'],
    coverImage: null,
    createdBy: 'user_001',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    isActive: true,
    preferences: {},
  );

  // Sample Expense
  static Expense sampleExpense = Expense(
    id: 'expense_001',
    amount: 150.0,
    category: ExpenseCategory.restaurant,
    date: DateTime(2024, 1, 15),
    description: 'Dinner at local restaurant',
    currency: 'USD',
    tripId: 'trip_001',
  );

  // Multiple activities for testing filters
  static List<ActivityModel> multipleActivities = [
    sampleActivity,
    ActivityModel(
      id: 'activity_002',
      title: 'Eiffel Tower Visit',
      description: 'Visit the iconic Eiffel Tower',
      activityType: ActivityType.activity,
      status: ActivityStatus.confirmed,
      priority: Priority.high,
      startDate: DateTime(2024, 1, 16, 14, 0),
      endDate: DateTime(2024, 1, 16, 16, 0),
      durationMinutes: 120,
      location: LocationModel(
        name: 'Eiffel Tower',
        address: 'Champ de Mars, Paris',
        latitude: 48.8584,
        longitude: 2.2945,
        city: 'Paris',
        country: 'France',
      ),
      budget: BudgetModel(
        estimatedCost: 200.0,
        actualCost: 0.0,
        currency: 'EUR',
      ),
      notes: null,
      tags: ['landmark', 'must-see'],
      attachments: [],
      tripId: 'trip_001',
      checkIn: false,
      createdBy: 'user_001',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      expenseInfo: ExpenseInfo(
        expenseId: null,
        hasExpense: false,
        expenseCategory: null,
        autoSynced: false,
        expenseSynced: false,
      ),
    ),
    ActivityModel(
      id: 'activity_003',
      title: 'Flight to Paris',
      description: 'Direct flight',
      activityType: ActivityType.flight,
      status: ActivityStatus.completed,
      priority: Priority.urgent,
      startDate: DateTime(2024, 1, 15, 8, 0),
      endDate: DateTime(2024, 1, 15, 10, 0),
      durationMinutes: 120,
      location: null,
      budget: BudgetModel(
        estimatedCost: 500.0,
        actualCost: 500.0,
        currency: 'USD',
      ),
      notes: 'Seat 12A',
      tags: ['flight'],
      attachments: [],
      tripId: 'trip_001',
      checkIn: true,
      createdBy: 'user_001',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
      expenseInfo: ExpenseInfo(
        expenseId: 'expense_002',
        hasExpense: true,
        expenseCategory: 'flight',
        autoSynced: true,
        expenseSynced: true,
      ),
    ),
  ];
}
