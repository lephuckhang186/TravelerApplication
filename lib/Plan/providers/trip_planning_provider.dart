import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../services/trip_planning_service.dart';
import '../services/trip_storage_service.dart';
import '../services/firebase_trip_service.dart';
import '../services/budget_sync_service.dart';

/// Provider for managing trip planning state
class TripPlanningProvider extends ChangeNotifier {
  final TripPlanningService _apiService = TripPlanningService();
  final TripStorageService _storageService = TripStorageService();
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

  /// Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // First load from local storage for immediate display
      await _loadTripsFromStorage();
      // Then sync with API in background
      await _syncWithAPI();
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
        debugPrint(
          'DEBUG: Attempting to create trip on server: ${trip.name} -> ${trip.destination}',
        );
        createdTrip = await _apiService.createTrip(trip);
        debugPrint(
          'DEBUG: Trip created successfully on server with ID: ${createdTrip.id}',
        );
      } catch (e) {
        debugPrint('DEBUG: API Error creating trip: $e');
        debugPrint(
          'DEBUG: Trip data that failed: name="${trip.name}", dest="${trip.destination}", start=${trip.startDate}, end=${trip.endDate}',
        );
        // If API fails, create locally with temporary ID
        createdTrip = trip.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        );
        debugPrint('DEBUG: Created local trip with ID: ${createdTrip.id}');
      }

      // Add to local list and save to HYBRID storage (local + Firebase)
      _trips.add(createdTrip);
      final savedTrips = await _storageService.saveTrips(_trips);
      _trips = savedTrips; // Update with any Firebase IDs
      debugPrint(
        'DEBUG: HYBRID SAVE - Saved ${_trips.length} trips after creating: ${createdTrip.name}',
      );

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

      // Save to HYBRID storage (local + Firebase) IMMEDIATELY
      final savedTrips = await _storageService.saveTrips(_trips);
      _trips = savedTrips; // Update with any Firebase IDs
      debugPrint(
        'DEBUG: HYBRID SAVE - Saved ${_trips.length} trips after adding: ${trip.name}',
      );

      _clearError();
      notifyListeners();
      debugPrint('DEBUG: Added trip to provider: ${trip.name}');
    } catch (e) {
      debugPrint('DEBUG: Failed to add trip to provider: $e');
      _setError('Failed to add trip: $e');
    }
  }

  /// Delete a trip
  Future<bool> deleteTrip(String tripId) async {
    _setLoading(true);
    try {
      debugPrint('DEBUG: Attempting to delete trip: $tripId');

      // Check if trip exists locally first
      final tripExists = _trips.any((trip) => trip.id == tripId);
      if (!tripExists) {
        debugPrint('DEBUG: Trip $tripId not found locally');
        _setError('Trip not found');
        return false;
      }

      // For local trips, always proceed with deletion
      if (tripId.startsWith('local_')) {
        debugPrint(
          'DEBUG: Local-only trip detected, proceeding with local deletion',
        );
      } else {
        // Try to delete from server for non-local trips
        try {
          debugPrint('DEBUG: Deleting from server...');
          await _apiService.deleteTrip(tripId);
          debugPrint('DEBUG: Server deletion successful');
        } catch (e) {
          debugPrint('DEBUG: Server deletion failed: $e');
          // For network errors or 404, we'll still proceed with local deletion
          if (e.toString().contains('404') ||
              e.toString().contains('Failed to fetch') ||
              e.toString().contains('ClientException')) {
            debugPrint(
              'DEBUG: Network error or 404 - proceeding with local deletion anyway',
            );
          } else {
            // For other server errors, fail the deletion
            debugPrint('DEBUG: Unexpected server error - failing deletion');
            _setError(
              'Failed to delete trip from server. Please check your connection and try again.',
            );
            return false;
          }
        }
      }

      // Proceed with local deletion
      // Remove from local list and hybrid storage
      debugPrint('DEBUG: Removing trip from hybrid storage');
      _trips.removeWhere((trip) => trip.id == tripId);

      // Delete from Firebase if not local-only
      if (!tripId.startsWith('local_')) {
        try {
          final firebaseService = FirebaseTripService();
          await firebaseService.deleteTrip(tripId);
          debugPrint('DEBUG: Deleted trip from Firebase: $tripId');
        } catch (e) {
          debugPrint('DEBUG: Failed to delete from Firebase: $e');
        }
      }

      final savedTrips = await _storageService.saveTrips(_trips);
      _trips = savedTrips;

      if (_currentTrip?.id == tripId) {
        _currentTrip = null;
        debugPrint('DEBUG: Cleared current trip');
      }

      _clearError();
      notifyListeners();
      debugPrint('DEBUG: Trip deletion completed successfully');
      return true;
    } catch (e) {
      debugPrint('DEBUG: Trip deletion failed: $e');
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

      // Save to storage
      await _storageService.saveTrips(_trips);

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
        await _storageService.saveTrips(_trips);

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
  Future<void> _loadTripsFromStorage() async {
    try {
      _trips = await _storageService.loadTrips();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load from storage: $e');
    }
  }

  Future<void> _syncWithAPI() async {
    try {
      debugPrint('DEBUG: Fetched ${_trips.length} cached trips');

      // Try to get trips from API with timeout protection
      List<TripModel> apiTrips = [];

      try {
        apiTrips = await _apiService.getTrips();
        debugPrint(
          'DEBUG: Successfully fetched ${apiTrips.length} trips from API',
        );
      } catch (e) {
        debugPrint('DEBUG: API call failed: $e');
        // CRITICAL: If we have no trips AND API fails, this means fresh start
        // Try to create a simple local trip to maintain user experience
        if (_trips.isEmpty) {
          debugPrint(
            'DEBUG: No trips found and API failed - offering recovery options',
          );
          // Could show user a dialog to manually re-add trips or sync from another source
        }
        debugPrint('DEBUG: Keeping cached trips due to API failure');
        return;
      }

      if (apiTrips.isEmpty && _trips.isNotEmpty) {
        debugPrint(
          'DEBUG: No remote trips received, but have ${_trips.length} cached trips',
        );

        // Check if cached trips are local-only
        final hasLocalOnlyTrips = _trips.any(
          (trip) => trip.id?.startsWith('local_') == true,
        );
        final hasServerTrips = _trips.any(
          (trip) => trip.id?.startsWith('local_') != true,
        );

        if (hasLocalOnlyTrips && !hasServerTrips) {
          debugPrint(
            'DEBUG: Only local trips found, attempting to sync them to server',
          );
          await _syncLocalTripsToServer();
          return;
        } else if (hasServerTrips) {
          debugPrint(
            'DEBUG: Warning: Server returned empty but we have server trips cached',
          );
          debugPrint(
            'DEBUG: This could be a server issue. Keeping cached trips for safety.',
          );
          // KEEP cached trips instead of deleting them
          return;
        }
      }

      // Merge API trips with local trips safely
      final Map<String, TripModel> tripMap = {};

      // First add all cached trips (both local and server)
      for (final trip in _trips) {
        if (trip.id != null) {
          tripMap[trip.id!] = trip;
        }
      }

      // Then add/update with API trips (these override cached server trips)
      for (final trip in apiTrips) {
        if (trip.id != null) {
          debugPrint(
            'DEBUG: Adding/updating API trip: ${trip.name} (${trip.id})',
          );
          tripMap[trip.id!] = trip;
        }
      }

      // CONSERVATIVE: Only remove trips if we're confident they were deleted
      // Don't remove trips just because API returned empty - could be temporary issue
      if (apiTrips.isNotEmpty) {
        // Only remove cached server trips that don't exist in a non-empty API response
        final tripsToRemove = <String>[];
        for (final trip in _trips) {
          if (trip.id != null && !trip.id!.startsWith('local_')) {
            final existsInAPI = apiTrips.any(
              (apiTrip) => apiTrip.id == trip.id,
            );
            if (!existsInAPI) {
              debugPrint(
                'DEBUG: Trip ${trip.name} (${trip.id}) not found in non-empty API response - removing',
              );
              tripsToRemove.add(trip.id!);
            }
          }
        }

        for (final tripId in tripsToRemove) {
          tripMap.remove(tripId);
        }
      }

      _trips = tripMap.values.toList();
      final savedTrips = await _storageService.saveTrips(_trips);
      _trips = savedTrips; // Update with any Firebase IDs
      notifyListeners();
      debugPrint('DEBUG: Final trip count: ${_trips.length}');
    } catch (e) {
      debugPrint('Failed to sync with API: $e');
      // Continue with local data if API fails
      debugPrint('DEBUG: Continuing with ${_trips.length} cached trips');
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

  /// Sync local-only trips to server
  Future<void> _syncLocalTripsToServer() async {
    final localTrips = _trips
        .where((trip) => trip.id?.startsWith('local_') == true)
        .toList();

    for (final localTrip in localTrips) {
      try {
        debugPrint('DEBUG: Syncing local trip to server: ${localTrip.name}');

        // Create a clean trip without the local ID
        final cleanTrip = localTrip.copyWith(id: null);
        final serverTrip = await _apiService.createTrip(cleanTrip);

        // Replace local trip with server trip
        final index = _trips.indexOf(localTrip);
        if (index != -1) {
          _trips[index] = serverTrip;
        }

        debugPrint('DEBUG: Successfully synced trip, new ID: ${serverTrip.id}');
      } catch (e) {
        debugPrint('DEBUG: Failed to sync local trip ${localTrip.name}: $e');
        // Keep the local trip if sync fails
      }
    }

    // Save updated trips to hybrid storage
    final savedTrips = await _storageService.saveTrips(_trips);
    _trips = savedTrips; // Update with any Firebase IDs
    notifyListeners();
  }

  @override
  void dispose() {
    _budgetSyncService.dispose();
    super.dispose();
  }
}
