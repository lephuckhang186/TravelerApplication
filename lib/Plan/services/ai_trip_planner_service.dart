import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import 'trip_planning_service.dart';

/// Service for AI-powered trip planning with natural language processing
class AITripPlannerService {
  final TripPlanningService _tripService = TripPlanningService();

  // Dynamic base URL based on platform
  static String get baseUrl {
    // Use localhost for development
    return 'http://localhost:5000';
  }

  /// Generate a complete trip plan based on natural language prompt
  Future<Map<String, dynamic>> generateTripPlan(String prompt) async {
    try {

      final response = await http.post(
        Uri.parse('$baseUrl/generate-trip-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final tripPlan = responseData['trip_plan'];

          // Convert the AI-generated plan to actual trip data
          final trip = await _convertPlanToTrip(tripPlan);

          return {
            'success': true,
            'message': 'Đã tạo kế hoạch du lịch thành công!',
            'trip': trip,
            'plan_data': tripPlan,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Không thể tạo kế hoạch du lịch.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối đến AI service: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Có lỗi xảy ra khi tạo kế hoạch: $e',
      };
    }
  }

  /// Convert AI-generated plan to TripModel with activities
  Future<TripModel> _convertPlanToTrip(Map<String, dynamic> tripPlan) async {
    final tripInfo = tripPlan['trip_info'];
    final dailyPlans = tripPlan['daily_plans'] as List;

    // Parse dates
    final startDate = DateTime.parse(tripInfo['start_date']);
    final endDate = DateTime.parse(tripInfo['end_date']);

    // Create budget model
    BudgetModel? budget;
    if (tripInfo['total_budget'] != null) {
      budget = BudgetModel(
        estimatedCost: tripInfo['total_budget'].toDouble(),
        currency: tripInfo['currency'] ?? 'VND',
      );
    }

    // Create trip model
    final trip = TripModel(
      id: 'ai_trip_${DateTime.now().millisecondsSinceEpoch}',
      name: tripInfo['name'],
      destination: tripInfo['destination'],
      startDate: startDate,
      endDate: endDate,
      budget: budget,
      description: 'Kế hoạch được tạo bởi AI',
      activities: [],
    );

    // Convert daily plans to activities
    final List<ActivityModel> activities = [];

    for (final dailyPlan in dailyPlans) {
      final day = dailyPlan['day'] as int;
      final dayActivities = dailyPlan['activities'] as List;

      for (final activityData in dayActivities) {
        // Calculate activity date
        final activityDate = startDate.add(Duration(days: day - 1));

        // Parse start time
        DateTime startDateTime = activityDate;
        if (activityData['start_time'] != null) {
          final timeParts = (activityData['start_time'] as String).split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]) ?? 9;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            startDateTime = DateTime(
              activityDate.year,
              activityDate.month,
              activityDate.day,
              hour,
              minute,
            );
          }
        }

        // Determine activity type
        final activityType = _parseActivityType(activityData['activity_type']);

        // Create budget for activity
        BudgetModel? activityBudget;
        if (activityData['estimated_cost'] != null) {
          activityBudget = BudgetModel(
            estimatedCost: (activityData['estimated_cost'] as num).toDouble(),
            currency: tripInfo['currency'] ?? 'VND',
          );
        }

        // Parse location data from AI response
        LocationModel? location;
        if (activityData['location'] != null || activityData['address'] != null) {
          // Parse coordinates if provided
          double? latitude, longitude;
          if (activityData['coordinates'] != null) {
            try {
              final coords = (activityData['coordinates'] as String).split(',');
              if (coords.length == 2) {
                latitude = double.tryParse(coords[0].trim());
                longitude = double.tryParse(coords[1].trim());
              }
            } catch (e) {
              //
            }
          }

          location = LocationModel(
            name: activityData['location'] ?? activityData['title'] ?? 'Unknown Location',
            address: activityData['address'],
            latitude: latitude,
            longitude: longitude,
          );
        }

        // Create activity
        final activity = ActivityModel(
          id: 'ai_activity_${DateTime.now().millisecondsSinceEpoch}_${activities.length}',
          title: activityData['title'],
          description: activityData['description'],
          activityType: activityType,
          startDate: startDateTime,
          tripId: trip.id,
          budget: activityBudget,
          location: location,
        );

        activities.add(activity);
      }
    }

    // Update trip with activities
    return trip.copyWith(activities: activities);
  }

  /// Parse activity type from string
  ActivityType _parseActivityType(String? typeString) {
    if (typeString == null) return ActivityType.activity;

    switch (typeString.toLowerCase()) {
      case 'restaurant':
        return ActivityType.restaurant;
      case 'lodging':
        return ActivityType.lodging;
      case 'flight':
        return ActivityType.flight;
      case 'tour':
        return ActivityType.tour;
      case 'activity':
      default:
        return ActivityType.activity;
    }
  }

  /// Save generated trip to backend
  Future<TripModel> saveGeneratedTrip(TripModel trip) async {
    try {
      // Create trip on backend (this will still use backend API for trips)
      final createdTrip = await _tripService.createTrip(trip);

      // Activities are already included in the trip, no need to create them separately
      // They will be saved to Firestore as part of the trip document
      
      return createdTrip.copyWith(activities: trip.activities);
    } catch (e) {
      rethrow;
    }
  }
}
