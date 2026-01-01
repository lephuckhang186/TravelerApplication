import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../services/trip_planning_service.dart';
import '../services/firebase_trip_service.dart';
import '../services/budget_sync_service.dart';

/// Provider for managing trip planning state in a cloud-synced environment.
///
/// This provider handles the lifecycle of trips, including creation, update,
/// and deletion, primarily interacting with Firebase Firestore for persistence.
/// It also manages budget synchronization with the Expense module.
class TripPlanningProvider extends ChangeNotifier {
  final TripPlanningService _apiService = TripPlanningService();
  final FirebaseTripService _firebaseService = FirebaseTripService();
  final BudgetSyncService _budgetSyncService = BudgetSyncService();

  List<TripModel> _trips = [];
  TripModel? _currentTrip;
  bool _isLoading = false;
  String? _error;

  // Getters

  /// Sorted list of all trips loaded for the current user.
  List<TripModel> get trips => _trips;

  /// The trip currently being viewed or edited in the UI.
  TripModel? get currentTrip => _currentTrip;

  /// Whether a data operation is currently in progress.
  bool get isLoading => _isLoading;

  /// Most recent error encountered during trip operations.
  String? get error => _error;

  /// Whether any trips have been loaded.
  bool get hasTrips => _trips.isNotEmpty;

  /// Initialize the provider by loading all trips from Firestore.
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

  /// Create a new trip with the given details, syncing across API and Firestore.
  ///
  /// Falls back to local/temporary IDs if the server API is unavailable.
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

      // Add to local list and save to Firestore
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

  /// Add an existing trip to the provider or update it if the ID already exists.
  Future<void> addTrip(TripModel trip) async {
    try {
      final existingIndex = _trips.indexWhere((t) => t.id == trip.id);
      if (existingIndex >= 0) {
        _trips[existingIndex] = trip;
      } else {
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

  /// Delete a trip by ID from both the server (if applicable) and Firestore.
  Future<bool> deleteTrip(String tripId) async {
    _setLoading(true);
    try {
      final tripExists = _trips.any((trip) => trip.id == tripId);
      if (!tripExists) {
        _setError('Trip not found');
        return false;
      }

      if (tripId.startsWith('local_')) {
        // Local trips don't need server deletion
      } else {
        try {
          await _apiService.deleteTrip(tripId);
        } catch (e) {
          // Handle specific non-blocking errors
          if (e.toString().contains('404') ||
              e.toString().contains('Failed to fetch') ||
              e.toString().contains('ClientException')) {
            // Proceed anyway
          } else {
            _setError('Failed to delete trip from server.');
            return false;
          }
        }
      }

      // Remove from local list and Firestore
      _trips.removeWhere((trip) => trip.id == tripId);
      try {
        await _firebaseService.deleteTrip(tripId);
      } catch (e) {
        // Log or handle error if needed
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

  /// Set the [trip] as the current active trip in the UI.
  void setCurrentTrip(TripModel trip) {
    _currentTrip = trip;
    notifyListeners();
  }

  /// Locate a trip in the local state by its unique [tripId].
  TripModel? getTripById(String tripId) {
    try {
      return _trips.firstWhere((trip) => trip.id == tripId);
    } catch (e) {
      return null;
    }
  }

  /// Update an individual activity within a trip and sync with Firestore.
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

      final updatedTrip = trip.copyWith(activities: updatedActivities);
      _trips[tripIndex] = updatedTrip;

      // Save to Firestore
      await _firebaseService.saveTrip(updatedTrip);

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

  /// Integrate the trip's budget with external expense data via [BudgetSyncService].
  Future<TripModel?> syncTripBudgetStatus(String tripId) async {
    try {
      final trip = getTripById(tripId);
      if (trip == null) {
        _setError('Trip not found');
        return null;
      }

      final syncedTrip = await _budgetSyncService.syncTripBudgetStatus(trip);

      final tripIndex = _trips.indexWhere((t) => t.id == tripId);
      if (tripIndex != -1) {
        _trips[tripIndex] = syncedTrip;
        await _firebaseService.saveTrip(syncedTrip);

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

  /// Create a tracked expense linked to a specific activity and update budget status.
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

      await syncTripBudgetStatus(trip.id!);
      return true;
    } catch (e) {
      _setError('Failed to create expense from activity: $e');
      return false;
    }
  }

  /// Fetch the current budget utilization and status for a trip.
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

  /// Filter the loaded trips by name, destination, or description.
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
