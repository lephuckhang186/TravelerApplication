import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../services/trip_planning_service.dart';
import '../services/trip_storage_service.dart';
import '../../expense_management/services/budget_sync_service.dart';

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
        createdTrip = await _apiService.createTrip(trip);
      } catch (e) {
        print('API Error creating trip: $e');
        // If API fails, create locally with temporary ID
        createdTrip = trip.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Add to local list and storage
      _trips.add(createdTrip);
      await _storageService.saveTrips(_trips);

      _clearError();
      return createdTrip;
    } catch (e) {
      _setError('Failed to create trip: $e');
      return null;
    } finally {
      _setLoading(false);
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

      // Try to delete from server only if it's not a local-only trip
      bool serverDeleteSuccessful = false;
      if (!tripId.startsWith('local_')) {
        try {
          debugPrint('DEBUG: Deleting from server...');
          await _apiService.deleteTrip(tripId);
          serverDeleteSuccessful = true;
          debugPrint('DEBUG: Server deletion successful');
        } catch (e) {
          debugPrint('DEBUG: Server deletion failed: $e');
          // For 404 errors, it's actually okay - the trip is already gone from server
          if (e.toString().contains('404')) {
            debugPrint('DEBUG: Trip already deleted from server (404)');
            serverDeleteSuccessful = true;
          } else {
            // For other errors, we might want to show a warning but still delete locally
            debugPrint(
              'DEBUG: Server error: $e - proceeding with local deletion',
            );
          }
        }
      } else {
        debugPrint('DEBUG: Local-only trip, skipping server deletion');
        serverDeleteSuccessful = true;
      }

      // Remove from local list and storage
      debugPrint('DEBUG: Removing trip from local storage');
      _trips.removeWhere((trip) => trip.id == tripId);
      await _storageService.saveTrips(_trips);

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
  Future<bool> updateActivityInTrip(String tripId, ActivityModel updatedActivity) async {
    try {
      final tripIndex = _trips.indexWhere((trip) => trip.id == tripId);
      if (tripIndex == -1) {
        _setError('Trip not found');
        return false;
      }

      final trip = _trips[tripIndex];
      final activityIndex = trip.activities.indexWhere((activity) => activity.id == updatedActivity.id);
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
      final apiTrips = await _apiService.getTrips();
      debugPrint('DEBUG: Fetched ${apiTrips.length} trips from API');

      if (apiTrips.isEmpty && _trips.isNotEmpty) {
        debugPrint(
          'DEBUG: No remote trips received, but have ${_trips.length} cached trips',
        );
        // Check if cached trips are local-only or potentially deleted from server
        final hasLocalOnlyTrips = _trips.any(
          (trip) => trip.id?.startsWith('local_') == true,
        );
        final hasServerTrips = _trips.any(
          (trip) => trip.id?.startsWith('local_') != true,
        );

        if (hasLocalOnlyTrips && !hasServerTrips) {
          debugPrint('DEBUG: Only local trips found, keeping them');
          return;
        } else if (hasServerTrips) {
          debugPrint(
            'DEBUG: Warning: Server trips may have been deleted remotely',
          );
          // Keep trips but log the inconsistency for user awareness
          debugPrint(
            'DEBUG: Keeping cached trips, but they may be out of sync',
          );
          return;
        }
      }

      // Merge API trips with local trips, handling conflicts intelligently
      final Map<String, TripModel> tripMap = {};

      // First add local-only trips (those with local_ prefix)
      for (final trip in _trips) {
        if (trip.id != null && trip.id!.startsWith('local_')) {
          debugPrint('DEBUG: Keeping local-only trip: ${trip.name}');
          tripMap[trip.id!] = trip;
        }
      }

      // Then add API trips (these override any server trips)
      for (final trip in apiTrips) {
        if (trip.id != null) {
          debugPrint('DEBUG: Adding API trip: ${trip.name} (${trip.id})');
          tripMap[trip.id!] = trip;
        }
      }

      // If we have local trips that aren't local-only and aren't in API,
      // they might have been deleted from server - remove them
      for (final trip in _trips) {
        if (trip.id != null && !trip.id!.startsWith('local_')) {
          final existsInAPI = apiTrips.any((apiTrip) => apiTrip.id == trip.id);
          if (!existsInAPI) {
            debugPrint(
              'DEBUG: Trip ${trip.name} (${trip.id}) not found in API - may have been deleted',
            );
            // Remove from map if it was added
            tripMap.remove(trip.id);
          }
        }
      }

      _trips = tripMap.values.toList();
      await _storageService.saveTrips(_trips);
      notifyListeners();
      debugPrint('DEBUG: Final trip count: ${_trips.length}');
    } catch (e) {
      debugPrint('Failed to sync with API: $e');
      // Continue with local data if API fails
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

  @override
  void dispose() {
    _budgetSyncService.dispose();
    super.dispose();
  }
}
