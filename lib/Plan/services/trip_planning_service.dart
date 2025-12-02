import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_models.dart';
import '../models/trip_model.dart';

/// Service for handling API calls related to trips and activities
class TripPlanningService {
  // Dynamic base URL based on platform
  static String get baseUrl {
    // Your computer's actual IP address (based on netstat output showing 172.20.10.4)
    return 'http://172.20.10.4:8000/api/v1';
    
    // Alternative URLs to try if above fails:
    // Android emulator: 'http://10.0.2.2:8000/api/v1'
    // iOS Simulator: 'http://localhost:8000/api/v1'
  }
  
  // Headers for API calls with Firebase authentication
  Future<Map<String, String>> get _headers async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      throw Exception('User not authenticated. Please log in.');
    }
  }

  /// Get a specific trip by ID  
  Future<TripModel?> getTrip(String tripId) async {
    try {
      // For now, use the current trip endpoint since we don't have individual trip endpoints
      final currentTrip = await getCurrentTrip();
      return currentTrip?.id == tripId ? currentTrip : null;
    } catch (e) {
      throw Exception('Error loading trip: $e');
    }
  }

  /// Get all activities for a trip
  Future<List<ActivityModel>> getActivities({String? tripId}) async {
    try {
      final uri = tripId != null 
          ? Uri.parse('$baseUrl/activities?trip_id=$tripId')
          : Uri.parse('$baseUrl/activities');
          
      final headers = await _headers;
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> activitiesJson = data['activities'] ?? [];
        return activitiesJson.map((activity) => ActivityModel.fromJson(activity)).toList();
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading activities: $e');
    }
  }

  /// Get a specific activity by ID
  Future<ActivityModel?> getActivity(String activityId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/$activityId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivityModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading activity: $e');
    }
  }

  /// Create a new activity
  Future<ActivityModel> createActivity(ActivityModel activity) async {
    try {
      debugPrint('DEBUG: Creating activity with data: ${jsonEncode(activity.toJson())}');
      
      final headers = await _headers;
      debugPrint('DEBUG: Request headers: $headers');
      
      final response = await http.post(
        Uri.parse('$baseUrl/activities'),
        headers: headers,
        body: jsonEncode(activity.toJson()),
      );
      
      debugPrint('DEBUG: Create activity response status: ${response.statusCode}');
      debugPrint('DEBUG: Create activity response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ActivityModel.fromJson(data);
      } else {
        throw Exception('Failed to create activity: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DEBUG: Create activity error: $e');
      throw Exception('Error creating activity: $e');
    }
  }

  /// Update an existing activity
  Future<ActivityModel> updateActivity(String activityId, ActivityModel activity) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/activities/$activityId'),
        headers: headers,
        body: jsonEncode(activity.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivityModel.fromJson(data);
      } else {
        throw Exception('Failed to update activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating activity: $e');
    }
  }

  /// Delete an activity
  Future<void> deleteActivity(String activityId) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/activities/$activityId'),
        headers: headers,
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }

  /// Schedule an activity
  Future<ActivityModel> scheduleActivity(
    String activityId,
    DateTime startDate, {
    DateTime? endDate,
    int? durationMinutes,
  }) async {
    try {
      final body = {
        'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      };
      
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/activities/$activityId/schedule'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivityModel.fromJson(data);
      } else {
        throw Exception('Failed to schedule activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error scheduling activity: $e');
    }
  }

  /// Update activity cost
  Future<ActivityModel> updateActivityCost(
    String activityId,
    double actualCost,
    String currency,
  ) async {
    try {
      final body = {
        'actual_cost': actualCost,
        'currency': currency,
      };
      
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/activities/$activityId/cost'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivityModel.fromJson(data);
      } else {
        throw Exception('Failed to update activity cost: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating activity cost: $e');
    }
  }

  /// Check for schedule conflicts
  Future<List<ActivityModel>> checkScheduleConflicts(
    DateTime startDate,
    DateTime endDate, {
    String? tripId,
    String? excludeActivityId,
  }) async {
    try {
      final body = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (tripId != null) 'trip_id': tripId,
        if (excludeActivityId != null) 'exclude_activity_id': excludeActivityId,
      };
      
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/activities/conflicts/check'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((activity) => ActivityModel.fromJson(activity)).toList();
      } else {
        throw Exception('Failed to check conflicts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking conflicts: $e');
    }
  }

  /// Get activity statistics for a trip
  Future<Map<String, dynamic>> getActivityStatistics(String tripId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/statistics/$tripId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading statistics: $e');
    }
  }

  /// Export trip activities
  Future<Map<String, dynamic>> exportTripActivities(String tripId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/export/$tripId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to export activities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting activities: $e');
    }
  }

  /// Setup trip budget for expense tracking
  Future<Map<String, dynamic>> setupTripBudget({
    String? tripId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalBudget,
    String currency = 'VND',
    Map<String, double>? categoryAllocations,
  }) async {
    try {
      final body = {
        'trip_id': tripId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'total_budget': totalBudget,
        'currency': currency,
        if (categoryAllocations != null) 'category_allocations': categoryAllocations,
      };
      
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/activities/trip/budget/setup'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to setup trip budget: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error setting up trip budget: $e');
    }
  }

  /// Get expense summary with activity integration
  Future<Map<String, dynamic>> getExpenseSummary({String? tripId}) async {
    try {
      final uri = tripId != null 
          ? Uri.parse('$baseUrl/activities/expenses/summary?trip_id=$tripId')
          : Uri.parse('$baseUrl/activities/expenses/summary');
          
      final headers = await _headers;
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get expense summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting expense summary: $e');
    }
  }

  /// Force sync all activities with expenses
  Future<Map<String, dynamic>> syncActivitiesWithExpenses({String? tripId}) async {
    try {
      final uri = tripId != null 
          ? Uri.parse('$baseUrl/activities/expenses/sync?trip_id=$tripId')
          : Uri.parse('$baseUrl/activities/expenses/sync');
          
      final headers = await _headers;
      final response = await http.post(uri, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to sync activities with expenses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error syncing activities with expenses: $e');
    }
  }

  /// Get available activity types from backend
  Future<List<Map<String, String>>> getActivityTypes() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/types/list'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, String>>.from(data['activity_types']);
      } else {
        throw Exception('Failed to get activity types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting activity types: $e');
    }
  }

  /// Get available activity statuses from backend
  Future<List<Map<String, String>>> getActivityStatuses() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/statuses/list'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, String>>.from(data['statuses']);
      } else {
        throw Exception('Failed to get activity statuses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting activity statuses: $e');
    }
  }

  /// Get available activity priorities from backend
  Future<List<Map<String, String>>> getActivityPriorities() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/priorities/list'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, String>>.from(data['priorities']);
      } else {
        throw Exception('Failed to get activity priorities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting activity priorities: $e');
    }
  }

  // ===== TRIP MANAGEMENT METHODS =====

  /// Create a new trip with backend integration
  Future<TripModel> createTrip(TripModel trip) async {
    try {
      final body = {
        'name': trip.name,
        'destination': trip.destination,
        'description': trip.description,
        'start_date': trip.startDate.toIso8601String().split('T')[0],
        'end_date': trip.endDate.toIso8601String().split('T')[0],
        'total_budget': trip.budget?.estimatedCost,
        'currency': trip.budget?.currency ?? 'VND',
      };
      
      // Use real endpoint with authentication
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/activities/trips'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Create a new trip with backend response data
        return trip.copyWith(
          id: data['id'],
          isActive: data['is_active'] ?? false,
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
        );
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in to create trips.');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception('Failed to create trip: ${errorData['detail'] ?? response.statusCode}');
        } catch (e) {
          throw Exception('Failed to create trip: HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error creating trip: $e');
    }
  }

  /// Get current trip
  Future<TripModel?> getCurrentTrip() async {
    try {
      final trips = await getTrips();
      if (trips.isNotEmpty) {
        // Return the first active trip
        return trips.firstWhere((trip) => trip.isActive, orElse: () => trips.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting current trip: $e');
    }
  }

  /// Get all trips
  Future<List<TripModel>> getTrips() async {
    try {
      debugPrint('DEBUG: TripService.getTrips() - Making API call to $baseUrl/activities/trips');
      
      // Use real endpoint with authentication
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/trips'),
        headers: headers,
      );
      
      debugPrint('DEBUG: TripService.getTrips() - Response status: ${response.statusCode}');
      debugPrint('DEBUG: TripService.getTrips() - Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('DEBUG: TripService.getTrips() - Parsed ${data.length} trips from API');
        
        final trips = data.map((tripJson) {
          return TripModel(
            id: tripJson['id'],
            name: tripJson['name'],
            destination: tripJson['destination'],
            description: tripJson['description'],
            startDate: DateTime.parse(tripJson['start_date']),
            endDate: DateTime.parse(tripJson['end_date']),
            isActive: tripJson['is_active'] ?? false,
            budget: tripJson['total_budget'] != null ? BudgetModel(
              estimatedCost: tripJson['total_budget'].toDouble(),
              currency: tripJson['currency'] ?? 'VND',
              category: 'trip',
            ) : null,
            createdAt: DateTime.parse(tripJson['created_at']),
            updatedAt: DateTime.parse(tripJson['updated_at']),
          );
        }).toList();
        
        debugPrint('DEBUG: TripService.getTrips() - Returning ${trips.length} trips');
        for (int i = 0; i < trips.length; i++) {
          debugPrint('DEBUG: Trip ${i + 1}: ${trips[i].name} (${trips[i].id})');
        }
        
        return trips;
      } else {
        throw Exception('Failed to get trips: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DEBUG: TripService.getTrips() - Error: $e');
      throw Exception('Error getting trips: $e');
    }
  }

  /// Update trip
  Future<TripModel> updateTrip(String tripId, TripModel trip) async {
    try {
      // For now, since backend doesn't have full trip update endpoint,
      // we'll simulate by updating the trip locally
      return trip.copyWith(
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error updating trip: $e');
    }
  }

  /// Delete trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      debugPrint('DEBUG: TripService.deleteTrip() - Deleting trip: $tripId');
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/activities/trips/$tripId'),
        headers: headers,
      );
      
      debugPrint('DEBUG: TripService.deleteTrip() - Response status: ${response.statusCode}');
      debugPrint('DEBUG: TripService.deleteTrip() - Response body: ${response.body}');
      
      if (response.statusCode == 204) {
        debugPrint('DEBUG: Trip deleted successfully from server');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('DEBUG: Trip not found on server (404) - considering as successful deletion');
        return true; // Trip already doesn't exist, so deletion is "successful"
      } else {
        throw Exception('Failed to delete trip: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DEBUG: TripService.deleteTrip() - Error: $e');
      throw Exception('Error deleting trip: $e');
    }
  }

  /// Create trip with budget setup
  Future<TripModel> createTripWithBudget({
    required TripModel trip,
    required double totalBudget,
    String currency = 'VND',
    Map<String, double>? categoryAllocations,
  }) async {
    try {
      // First create the trip
      final createdTrip = await createTrip(trip);
      
      // Then setup the budget
      await setupTripBudget(
        tripId: createdTrip.id,
        startDate: trip.startDate,
        endDate: trip.endDate,
        totalBudget: totalBudget,
        currency: currency,
        categoryAllocations: categoryAllocations,
      );
      
      // Return trip with budget information
      return createdTrip.copyWith(
        budget: BudgetModel(
          estimatedCost: totalBudget,
          currency: currency,
          category: 'trip',
        ),
      );
    } catch (e) {
      throw Exception('Error creating trip with budget: $e');
    }
  }

  /// Get trip statistics
  Future<Map<String, dynamic>> getTripStatistics(String tripId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/activities/statistics/$tripId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get trip statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting trip statistics: $e');
    }
  }
}