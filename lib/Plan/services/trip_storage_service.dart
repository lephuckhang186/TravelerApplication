import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import 'firebase_trip_service.dart';
import 'dart:html' as html;

/// Hybrid storage service for trips - Local + Firebase Cloud persistence
class TripStorageService {
  final FirebaseTripService _firebaseService = FirebaseTripService();

  /// Get user-specific storage key for trips
  String _getUserTripsKey() {
    // Get current user ID from Firebase Auth or return default
    final userId = _getCurrentUserId();
    return 'user_trips_$userId';
  }

  /// Get user-specific storage key for preferences
  String _getUserPreferencesKey() {
    final userId = _getCurrentUserId();
    return 'user_preferences_$userId';
  }

  /// Get current user ID safely
  String _getCurrentUserId() {
    try {
      // Try to get Firebase Auth user ID
      final user = FirebaseAuth.instance.currentUser;
      return user?.uid ?? 'default_user';
    } catch (e) {
      // Fallback to default if Firebase not available
      return 'default_user';
    }
  }

  TripModel _ensureTripHasId(TripModel trip) {
    if (trip.id != null && trip.id!.isNotEmpty) {
      return trip;
    }
    return trip.copyWith(id: 'local_${DateTime.now().millisecondsSinceEpoch}');
  }

  /// Save trips to hybrid storage (Local + Firebase Cloud)
  Future<List<TripModel>> saveTrips(List<TripModel> trips) async {
    List<TripModel> finalTrips = trips;

    try {
      // PHASE 1: Save to LOCAL storage first (immediate backup)
      await _saveToLocalStorage(trips);

      // PHASE 2: Save to FIREBASE (cloud persistence)
      try {
        final hasConnectivity = await _firebaseService.checkConnectivity();
        if (hasConnectivity) {
          debugPrint(
            'DEBUG: TripStorage.saveTrips() - Firebase connectivity OK, syncing to cloud...',
          );

          // Sync local trips to Firebase
          final cloudTrips = <TripModel>[];
          for (final trip in trips) {
            try {
              final cloudTrip = await _firebaseService.saveTrip(trip);
              cloudTrips.add(cloudTrip);
              debugPrint(
                'DEBUG: TripStorage.saveTrips() - Synced trip to Firebase: ${trip.name} → ${cloudTrip.id}',
              );
            } catch (e) {
              debugPrint(
                'DEBUG: TripStorage.saveTrips() - Failed to sync ${trip.name}: $e',
              );
              cloudTrips.add(trip); // Keep original if sync fails
            }
          }

          finalTrips = cloudTrips;
          // Update local storage with Firebase IDs
          await _saveToLocalStorage(finalTrips);

          debugPrint(
            'DEBUG: TripStorage.saveTrips() - CLOUD SAVE COMPLETED: ${finalTrips.length} trips synced',
          );
        } else {
          debugPrint(
            'DEBUG: TripStorage.saveTrips() - No Firebase connectivity, keeping local trips',
          );
        }
      } catch (e) {
        debugPrint('DEBUG: TripStorage.saveTrips() - Firebase sync failed: $e');
        debugPrint('DEBUG: TripStorage.saveTrips() - Trips saved locally only');
      }

      return finalTrips;
    } catch (e) {
      throw Exception('Error saving trips: $e');
    }
  }

  /// Save trips to local storage only
  Future<void> _saveToLocalStorage(List<TripModel> trips) async {
    try {
      final tripsJson = trips.map((trip) => trip.toJson()).toList();
      final userKey = _getUserTripsKey();
      final jsonString = jsonEncode(tripsJson);

      // Primary save: SharedPreferences (may be unreliable on web)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userKey, jsonString);
        debugPrint(
          'DEBUG: TripStorage._saveToLocalStorage() - Saved ${trips.length} trips to SharedPreferences',
        );
      } catch (e) {
        debugPrint(
          'DEBUG: TripStorage._saveToLocalStorage() - SharedPreferences failed: $e',
        );
      }

      // MAIN SAVE: Browser localStorage (web only) - More reliable than SharedPrefs
      if (kIsWeb) {
        try {
          html.window.localStorage[userKey] = jsonString;
          debugPrint(
            'DEBUG: TripStorage._saveToLocalStorage() - PRIMARY saved to localStorage for key: $userKey',
          );

          // Backup: sessionStorage
          html.window.sessionStorage['${userKey}_backup'] = jsonString;
          debugPrint(
            'DEBUG: TripStorage._saveToLocalStorage() - BACKUP saved to sessionStorage',
          );

          // Additional backup: localStorage with different key
          html.window.localStorage['${userKey}_backup2'] = jsonString;
          debugPrint(
            'DEBUG: TripStorage._saveToLocalStorage() - BACKUP2 saved to localStorage',
          );
        } catch (e) {
          debugPrint(
            'DEBUG: TripStorage._saveToLocalStorage() - Web storage failed: $e',
          );
          throw Exception('Failed to save to web storage: $e');
        }
      } else {
        debugPrint(
          'DEBUG: TripStorage._saveToLocalStorage() - Saved ${trips.length} trips for key: $userKey',
        );
      }
    } catch (e) {
      throw Exception('Error saving trips to local storage: $e');
    }
  }

  /// Load trips from hybrid storage (Firebase Cloud + Local backup)
  Future<List<TripModel>> loadTrips() async {
    try {
      final userKey = _getUserTripsKey();

      debugPrint('DEBUG: TripStorage.loadTrips() - Using key: $userKey');

      // PHASE 1: Try to load from FIREBASE CLOUD first (most up-to-date)
      try {
        final hasConnectivity = await _firebaseService.checkConnectivity();
        if (hasConnectivity) {
          debugPrint(
            'DEBUG: TripStorage.loadTrips() - Firebase connectivity OK, loading from cloud...',
          );

          final cloudTrips = await _firebaseService.loadTrips();
          if (cloudTrips.isNotEmpty) {
            debugPrint(
              'DEBUG: TripStorage.loadTrips() - CLOUD LOAD SUCCESS: ${cloudTrips.length} trips from Firebase',
            );

            // Update local storage with cloud data
            await _saveToLocalStorage(cloudTrips);
            return cloudTrips;
          } else {
            debugPrint(
              'DEBUG: TripStorage.loadTrips() - No trips found in Firebase, checking local storage...',
            );
          }
        } else {
          debugPrint(
            'DEBUG: TripStorage.loadTrips() - No Firebase connectivity, falling back to local storage',
          );
        }
      } catch (e) {
        debugPrint(
          'DEBUG: TripStorage.loadTrips() - Firebase load failed: $e, falling back to local storage',
        );
      }

      // PHASE 2: Fallback to LOCAL STORAGE
      return await _loadFromLocalStorage(userKey);
    } catch (e) {
      debugPrint('DEBUG: TripStorage.loadTrips() - Error: $e');
      throw Exception('Error loading trips: $e');
    }
  }

  /// Load trips from local storage only
  Future<List<TripModel>> _loadFromLocalStorage(String userKey) async {
    String? tripsString;

    // For web: Try localStorage FIRST (most reliable)
    if (kIsWeb) {
      try {
        // Debug all available storage keys
        final localStorageKeys = html.window.localStorage.keys.toList();
        final sessionStorageKeys = html.window.sessionStorage.keys.toList();
        debugPrint('DEBUG: Available localStorage keys: $localStorageKeys');
        debugPrint('DEBUG: Available sessionStorage keys: $sessionStorageKeys');

        // Primary: localStorage
        tripsString = html.window.localStorage[userKey];
        debugPrint(
          'DEBUG: localStorage[$userKey] = ${tripsString?.substring(0, 50) ?? "null"}...',
        );

        if (tripsString != null && tripsString.isNotEmpty) {
          debugPrint(
            'DEBUG: TripStorage._loadFromLocalStorage() - Loaded from localStorage: ${tripsString.length} chars',
          );
        } else {
          // Backup 1: sessionStorage
          tripsString = html.window.sessionStorage['${userKey}_backup'];
          debugPrint(
            'DEBUG: sessionStorage[${userKey}_backup] = ${tripsString?.substring(0, 50) ?? "null"}...',
          );

          if (tripsString != null && tripsString.isNotEmpty) {
            debugPrint(
              'DEBUG: TripStorage._loadFromLocalStorage() - Recovered from sessionStorage: ${tripsString.length} chars',
            );
          } else {
            // Backup 2: localStorage backup2
            tripsString = html.window.localStorage['${userKey}_backup2'];
            debugPrint(
              'DEBUG: localStorage[${userKey}_backup2] = ${tripsString?.substring(0, 50) ?? "null"}...',
            );

            if (tripsString != null && tripsString.isNotEmpty) {
              debugPrint(
                'DEBUG: TripStorage._loadFromLocalStorage() - Recovered from localStorage backup2: ${tripsString.length} chars',
              );
            } else {
              // Last resort: SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              tripsString = prefs.getString(userKey);
              debugPrint(
                'DEBUG: SharedPreferences[$userKey] = ${tripsString?.substring(0, 50) ?? "null"}...',
              );

              if (tripsString != null && tripsString.isNotEmpty) {
                debugPrint(
                  'DEBUG: TripStorage._loadFromLocalStorage() - Recovered from SharedPreferences: ${tripsString.length} chars',
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint(
          'DEBUG: TripStorage._loadFromLocalStorage() - Web storage access failed: $e',
        );
      }
    } else {
      // For mobile: Use SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      tripsString = prefs.getString(userKey);
      debugPrint(
        'DEBUG: TripStorage._loadFromLocalStorage() - SharedPreferences length: ${tripsString?.length ?? 0}',
      );
    }

    if (tripsString == null || tripsString.isEmpty) {
      debugPrint(
        'DEBUG: TripStorage._loadFromLocalStorage() - No trips found in any local storage',
      );
      return [];
    }

    final List<dynamic> tripsJson = jsonDecode(tripsString);
    final trips = tripsJson.map((trip) => TripModel.fromJson(trip)).toList();

    debugPrint(
      'DEBUG: TripStorage._loadFromLocalStorage() - Loaded ${trips.length} trips from local storage',
    );
    for (int i = 0; i < trips.length; i++) {
      debugPrint(
        'DEBUG: Local Trip ${i + 1}: ${trips[i].name} (${trips[i].id})',
      );
    }

    return trips;
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

  /// Save user preferences (local only - lightweight data)
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserPreferencesKey();
      await prefs.setString(userKey, jsonEncode(preferences));
      debugPrint(
        'DEBUG: TripStorage.saveUserPreferences() - Saved preferences for user',
      );
    } catch (e) {
      throw Exception('Error saving user preferences: $e');
    }
  }

  /// Load user preferences (local only)
  Future<Map<String, dynamic>> loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserPreferencesKey();
      final preferencesString = prefs.getString(userKey);

      if (preferencesString == null || preferencesString.isEmpty) {
        debugPrint(
          'DEBUG: TripStorage.loadUserPreferences() - No preferences found, using defaults',
        );
        return {};
      }

      final preferences = jsonDecode(preferencesString) as Map<String, dynamic>;
      debugPrint(
        'DEBUG: TripStorage.loadUserPreferences() - Loaded ${preferences.length} preferences',
      );
      return preferences;
    } catch (e) {
      throw Exception('Error loading user preferences: $e');
    }
  }

  /// Clear all data for current user (Local + Firebase)
  Future<void> clearAllData() async {
    try {
      // Clear Firebase data
      try {
        final firebaseTrips = await _firebaseService.loadTrips();
        for (final trip in firebaseTrips) {
          if (trip.id != null) {
            await _firebaseService.deleteTrip(trip.id!);
          }
        }
        debugPrint(
          'DEBUG: TripStorage.clearAllData() - Cleared ${firebaseTrips.length} trips from Firebase',
        );
      } catch (e) {
        debugPrint(
          'DEBUG: TripStorage.clearAllData() - Firebase clear failed: $e',
        );
      }

      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      final userTripsKey = _getUserTripsKey();
      final userPreferencesKey = _getUserPreferencesKey();
      await prefs.remove(userTripsKey);
      await prefs.remove(userPreferencesKey);

      // Clear browser storage
      if (kIsWeb) {
        try {
          html.window.localStorage.remove(userTripsKey);
          html.window.localStorage.remove('${userTripsKey}_backup2');
          html.window.sessionStorage.remove('${userTripsKey}_backup');
        } catch (e) {
          debugPrint(
            'DEBUG: TripStorage.clearAllData() - Browser storage clear failed: $e',
          );
        }
      }

      debugPrint(
        'DEBUG: TripStorage.clearAllData() - Cleared all data for user',
      );
    } catch (e) {
      throw Exception('Error clearing data: $e');
    }
  }

  /// Check if there's any data for current user (Firebase or Local)
  Future<bool> hasData() async {
    try {
      // Check Firebase first
      try {
        final hasConnectivity = await _firebaseService.checkConnectivity();
        if (hasConnectivity) {
          final firebaseTrips = await _firebaseService.loadTrips();
          if (firebaseTrips.isNotEmpty) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('DEBUG: TripStorage.hasData() - Firebase check failed: $e');
      }

      // Check local storage
      final prefs = await SharedPreferences.getInstance();
      final userTripsKey = _getUserTripsKey();
      final hasLocalData =
          prefs.containsKey(userTripsKey) &&
          prefs.getString(userTripsKey) != null;

      if (kIsWeb && !hasLocalData) {
        // Check browser storage
        final hasWebData =
            html.window.localStorage[userTripsKey] != null ||
            html.window.sessionStorage['${userTripsKey}_backup'] != null;
        return hasWebData;
      }

      return hasLocalData;
    } catch (e) {
      return false;
    }
  }

  /// Get storage usage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
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
