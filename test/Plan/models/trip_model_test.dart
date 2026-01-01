import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/Plan/models/trip_model.dart';
import 'package:flutter_application_1/Plan/models/activity_models.dart';

void main() {
  group('TripModel tests', () {
    late TripModel testTrip;

    setUp(() {
      testTrip = TripModel(
        id: 'trip123',
        name: 'Paris Adventure',
        destination: 'Paris, France',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 10),
        description: 'Summer vacation',
        activities: [],
        budget: BudgetModel(estimatedCost: 2000.0),
        collaborators: ['user1', 'user2'],
        createdBy: 'user1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
      );
    });

    test('constructor initializes all fields correctly', () {
      expect(testTrip.id, 'trip123');
      expect(testTrip.name, 'Paris Adventure');
      expect(testTrip.destination, 'Paris, France');
      expect(testTrip.isActive, true);
      expect(testTrip.collaborators.length, 2);
    });

    test('copyWith creates new instance with updated fields', () {
      final updated = testTrip.copyWith(name: 'Updated Trip', isActive: false);

      expect(updated.name, 'Updated Trip');
      expect(updated.isActive, false);
      expect(updated.id, 'trip123'); // Un changed
      expect(updated.destination, 'Paris, France'); // Unchanged
    });

    test('copyWithExpenseUpdate updates budget', () {
      final updated = testTrip.copyWithExpenseUpdate(newActualSpent: 1500.0);

      expect(updated.budget?.actualCost, 1500.0);
      expect(updated.budget?.estimatedCost, 2000.0);
    });

    test('getActivitiesByType filters correctly', () {
      final activities = [
        ActivityModel(title: 'Flight', activityType: ActivityType.flight),
        ActivityModel(title: 'Hotel', activityType: ActivityType.lodging),
        ActivityModel(title: 'Museum', activityType: ActivityType.activity),
      ];

      final tripWithActivities = testTrip.copyWith(activities: activities);
      final flights = tripWithActivities.getActivitiesByType(
        ActivityType.flight,
      );

      expect(flights.length, 1);
      expect(flights.first.title, 'Flight');
    });

    test('getActivitiesByStatus filters correctly', () {
      final activities = [
        ActivityModel(
          title: 'Planned Activity',
          activityType: ActivityType.activity,
          status: ActivityStatus.planned,
        ),
        ActivityModel(
          title: 'Confirmed Activity',
          activityType: ActivityType.activity,
          status: ActivityStatus.confirmed,
        ),
      ];

      final tripWithActivities = testTrip.copyWith(activities: activities);
      final confirmed = tripWithActivities.getActivitiesByStatus(
        ActivityStatus.confirmed,
      );

      expect(confirmed.length, 1);
      expect(confirmed.first.title, 'Confirmed Activity');
    });

    test('getActivitiesForDate filters by date', () {
      final targetDate = DateTime(2024, 6, 5);
      final activities = [
        ActivityModel(
          title: 'Morning Tour',
          activityType: ActivityType.tour,
          startDate: targetDate,
        ),
        ActivityModel(
          title: 'Evening Dinner',
          activityType: ActivityType.restaurant,
          startDate: targetDate,
        ),
        ActivityModel(
          title: 'Different Day',
          activityType: ActivityType.activity,
          startDate: DateTime(2024, 6, 6),
        ),
      ];

      final tripWithActivities = testTrip.copyWith(activities: activities);
      final dayActivities = tripWithActivities.getActivitiesForDate(targetDate);

      expect(dayActivities.length, 2);
    });

    test('toJson serializes correctly', () {
      final json = testTrip.toJson();

      expect(json['id'], 'trip123');
      expect(json['name'], 'Paris Adventure');
      expect(json['destination'], 'Paris, France');
      expect(json['is_active'], true);
      expect(json['collaborators'], isA<List>());
      expect(json['budget'], isA<Map>());
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'trip456',
        'name': 'London Trip',
        'destination': 'London, UK',
        'start_date': '2024-07-01T00:00:00.000',
        'end_date': '2024-07-10T00:00:00.000',
        'description': 'Business trip',
        'activities': [],
        'budget': {
          'estimated_cost': 3000.0,
          'actual_cost': 0.0,
          'currency': 'GBP',
        },
        'collaborators': ['user3'],
        'created_by': 'user3',
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-01T00:00:00.000',
        'is_active': true,
      };

      final trip = TripModel.fromJson(json);

      expect(trip.id, 'trip456');
      expect(trip.name, 'London Trip');
      expect(trip.destination, 'London, UK');
      expect(trip.activities, isEmpty);
    });

    test('toString returns formatted string', () {
      final str = testTrip.toString();
      expect(str, contains('Paris Adventure'));
      expect(str, contains('Paris, France'));
    });
  });
}
