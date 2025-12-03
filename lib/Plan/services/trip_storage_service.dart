import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';

/// Local storage service for trips and activities
class TripStorageService {
  static const String _tripsKey = 'user_trips';
  static const String _userPreferencesKey = 'user_preferences';

  TripModel _ensureTripHasId(TripModel trip) {
    if (trip.id != null && trip.id!.isNotEmpty) {
      return trip;
    }
    return trip.copyWith(id: 'local_${DateTime.now().millisecondsSinceEpoch}');
  }

  /// Save trips to local storage
  Future<void> saveTrips(List<TripModel> trips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = trips.map((trip) => trip.toJson()).toList();
      await prefs.setString(_tripsKey, jsonEncode(tripsJson));
    } catch (e) {
      throw Exception('Error saving trips to local storage: $e');
    }
  }

  /// Load trips from local storage
  Future<List<TripModel>> loadTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsString = prefs.getString(_tripsKey);

      debugPrint('DEBUG: TripStorage.loadTrips() - Raw data length: ${tripsString?.length ?? 0}');

      if (tripsString == null || tripsString.isEmpty) {
        debugPrint('DEBUG: TripStorage.loadTrips() - No trips found in local storage');
        return [];
      }

      final List<dynamic> tripsJson = jsonDecode(tripsString);
      final trips = tripsJson.map((trip) => TripModel.fromJson(trip)).toList();
      
      debugPrint('DEBUG: TripStorage.loadTrips() - Loaded ${trips.length} trips from local storage');
      for (int i = 0; i < trips.length; i++) {
        debugPrint('DEBUG: Local Trip ${i + 1}: ${trips[i].name} (${trips[i].id})');
      }
      
      return trips;
    } catch (e) {
      debugPrint('DEBUG: TripStorage.loadTrips() - Error: $e');
      throw Exception('Error loading trips from local storage: $e');
    }
  }

  /// Save a single trip
  Future<TripModel> saveTrip(TripModel trip) async {
    try {
      final normalizedTrip = _ensureTripHasId(trip);
      final trips = await loadTrips();
      final existingIndex = trips.indexWhere((t) => t.id == normalizedTrip.id);

      if (existingIndex >= 0) {
        trips[existingIndex] = normalizedTrip;
      } else {
        trips.insert(0, normalizedTrip);
      }

      await saveTrips(trips);
      return normalizedTrip;
    } catch (e) {
      throw Exception('Error saving trip to local storage: $e');
    }
  }

  /// Delete a trip from local storage
  Future<void> deleteTrip(String tripId) async {
    try {
      final trips = await loadTrips();
      trips.removeWhere((trip) => trip.id == tripId);
      await saveTrips(trips);
    } catch (e) {
      throw Exception('Error deleting trip from local storage: $e');
    }
  }

  /// Get a specific trip by ID
  Future<TripModel?> getTrip(String tripId) async {
    try {
      final trips = await loadTrips();
      try {
        return trips.firstWhere((t) => t.id == tripId);
      } catch (_) {
        return null;
      }
    } catch (e) {
      throw Exception('Error getting trip from local storage: $e');
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPreferencesKey, jsonEncode(preferences));
    } catch (e) {
      throw Exception('Error saving user preferences: $e');
    }
  }

  /// Load user preferences
  Future<Map<String, dynamic>> loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesString = prefs.getString(_userPreferencesKey);

      if (preferencesString == null || preferencesString.isEmpty) {
        return {};
      }

      return jsonDecode(preferencesString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error loading user preferences: $e');
    }
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tripsKey);
      await prefs.remove(_userPreferencesKey);
    } catch (e) {
      throw Exception('Error clearing local data: $e');
    }
  }

  /// Check if there's any cached data
  Future<bool> hasLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_tripsKey) && prefs.getString(_tripsKey) != null;
    } catch (e) {
      return false;
    }
  }

  /// Get storage usage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trips = await loadTrips();
      final preferences = await loadUserPreferences();

      return {
        'trips_count': trips.length,
        'total_activities': trips.fold<int>(
          0,
          (sum, trip) => sum + trip.activities.length,
        ),
        'has_preferences': preferences.isNotEmpty,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'trips_count': 0,
        'total_activities': 0,
        'has_preferences': false,
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }
}
