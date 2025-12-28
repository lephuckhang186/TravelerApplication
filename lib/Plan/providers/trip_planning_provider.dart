import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../services/trip_planning_service.dart';
import '../services/firebase_trip_service.dart';
import '../services/budget_sync_service.dart';

/// Provider for managing trip planning state (Firestore-only version)
class TripPlanningProvider extends ChangeNotifier {
  final TripPlanningService _apiService = TripPlanningService();
  final FirebaseTripService _firebaseService = FirebaseTripService();
  final BudgetSyncService _budgetSyncService = BudgetSyncService();

  List<TripModel> _trips = [];
  TripModel? _currentTrip;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TripModel> get trips => _trips;
  TripModel? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTrips => _trips.isNotEmpty;

  /// Initialize the provider - Load directly from Firestore
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadTripsFromFirestore();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new trip
  Future<TripModel?> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    double? budget,
  }) async {
    _setLoading(true);
    try {
      final trip = TripModel(
        name: name,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        budget: budget != null
            ? BudgetModel(estimatedCost: budget, currency: 'VND')
            : null,
      );

      // Try to create on server first
      TripModel? createdTrip;
      try {
        createdTrip = await _apiService.createTrip(trip);
      } catch (e) {
        // If API fails, create locally with temporary ID
        createdTrip = trip.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Add to local list and save to Firestore only
      _trips.add(createdTrip);
      await _firebaseService.saveTrip(createdTrip);

      _clearError();
      notifyListeners();
      return createdTrip;
    } catch (e) {
      _setError('Failed to create trip: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Add an existing trip to the provider
  Future<void> addTrip(TripModel trip) async {
    try {
      // Check if trip already exists
      final existingIndex = _trips.indexWhere((t) => t.id == trip.id);
      if (existingIndex >= 0) {
        // Update existing trip
        _trips[existingIndex] = trip;
      } else {
        // Add new trip
        _trips.add(trip);
      }

      // Save to Firestore only
      await _firebaseService.saveTrip(trip);

      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add trip: $e');
    }
  }

  /// Delete a trip
  Future<bool> deleteTrip(String tripId) async {
    _setLoading(true);
    try {
      // Check if trip exists locally first
      final tripExists = _trips.any((trip) => trip.id == tripId);
      if (!tripExists) {
        _setError('Trip not found');
        return false;
      }

      // For local trips, always proceed with deletion
      if (tripId.startsWith('local_')) {
      } else {
        // Try to delete from server for non-local trips
        try {
          await _apiService.deleteTrip(tripId);
        } catch (e) {
          // For network errors or 404, we'll still proceed with local deletion
          if (e.toString().contains('404') ||
              e.toString().contains('Failed to fetch') ||
              e.toString().contains('ClientException')) {
          } else {
            // For other server errors, fail the deletion
            _setError(
              'Failed to delete trip from server. Please check your connection and try again.',
            );
            return false;
          }
        }
      }

      // Proceed with deletion - Remove from Firestore only
      _trips.removeWhere((trip) => trip.id == tripId);

      // Delete from Firebase
      try {
        await _firebaseService.deleteTrip(tripId);
      } catch (e) {
        //
      }

      if (_currentTrip?.id == tripId) {
        _currentTrip = null;
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete trip: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set current trip
  void setCurrentTrip(TripModel trip) {
    _currentTrip = trip;
    notifyListeners();
  }

  /// Get trip by ID
  TripModel? getTripById(String tripId) {
    try {
      return _trips.firstWhere((trip) => trip.id == tripId);
    } catch (e) {
      return null;
    }
  }

  /// Update an activity in a specific trip
  Future<bool> updateActivityInTrip(
    String tripId,
    ActivityModel updatedActivity,
  ) async {
    try {
      final tripIndex = _trips.indexWhere((trip) => trip.id == tripId);
      if (tripIndex == -1) {
        _setError('Trip not found');
        return false;
      }

      final trip = _trips[tripIndex];
      final activityIndex = trip.activities.indexWhere(
        (activity) => activity.id == updatedActivity.id,
      );
      if (activityIndex == -1) {
        _setError('Activity not found in trip');
        return false;
      }

      // Update the activity in the trip
      final updatedActivities = List<ActivityModel>.from(trip.activities);
      updatedActivities[activityIndex] = updatedActivity;

      // Create updated trip with new activities
      final updatedTrip = trip.copyWith(activities: updatedActivities);
      _trips[tripIndex] = updatedTrip;

      // Save to Firestore
      await _firebaseService.saveTrip(updatedTrip);

      // Update current trip if it's the same
      if (_currentTrip?.id == tripId) {
        _currentTrip = updatedTrip;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update activity: $e');
      return false;
    }
  }

  /// Sync trip budget status with expense data
  Future<TripModel?> syncTripBudgetStatus(String tripId) async {
    try {
      final trip = getTripById(tripId);
      if (trip == null) {
        _setError('Trip not found');
        return null;
      }

      // Use budget sync service to update trip budget
      final syncedTrip = await _budgetSyncService.syncTripBudgetStatus(trip);

      // Update the trip in the list
      final tripIndex = _trips.indexWhere((t) => t.id == tripId);
      if (tripIndex != -1) {
        _trips[tripIndex] = syncedTrip;
        await _firebaseService.saveTrip(syncedTrip);

        // Update current trip if it's the same
        if (_currentTrip?.id == tripId) {
          _currentTrip = syncedTrip;
        }

        notifyListeners();
      }

      return syncedTrip;
    } catch (e) {
      _setError('Failed to sync budget status: $e');
      return null;
    }
  }

  /// Create expense from activity and sync budget
  Future<bool> createExpenseFromActivity({
    required ActivityModel activity,
    required TripModel trip,
    required double actualCost,
    String? description,
  }) async {
    try {
      await _budgetSyncService.createExpenseFromActivity(
        activity: activity,
        trip: trip,
        actualCost: actualCost,
        description: description,
        tripProvider: this,
      );

      // Sync the trip budget status after creating expense
      await syncTripBudgetStatus(trip.id!);

      return true;
    } catch (e) {
      _setError('Failed to create expense from activity: $e');
      return false;
    }
  }

  /// Get budget status for a trip
  Future<Map<String, dynamic>?> getTripBudgetStatus(String tripId) async {
    try {
      final trip = getTripById(tripId);
      if (trip == null) {
        return null;
      }

      return await _budgetSyncService.getTripBudgetStatus(trip);
    } catch (e) {
      _setError('Failed to get budget status: $e');
      return null;
    }
  }

  /// Search trips
  List<TripModel> searchTrips(String query) {
    if (query.isEmpty) return _trips;

    final lowercaseQuery = query.toLowerCase();
    return _trips.where((trip) {
      return trip.name.toLowerCase().contains(lowercaseQuery) ||
          trip.destination.toLowerCase().contains(lowercaseQuery) ||
          (trip.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Private methods
  Future<void> _loadTripsFromFirestore() async {
    try {
      _trips = await _firebaseService.loadTrips();
      notifyListeners();
    } catch (e) {
      _trips = [];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
