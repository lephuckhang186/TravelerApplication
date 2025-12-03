import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../services/trip_planning_service.dart';
import '../services/trip_storage_service.dart';

/// Provider for managing trip planning state
class TripPlanningProvider extends ChangeNotifier {
  final TripPlanningService _apiService = TripPlanningService();
  final TripStorageService _storageService = TripStorageService();

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
      
      // Save to storage
      await _storageService.saveTrips(_trips);
      
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
        debugPrint('DEBUG: Local-only trip detected, proceeding with local deletion');
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
            debugPrint('DEBUG: Network error or 404 - proceeding with local deletion anyway');
          } else {
            // For other server errors, fail the deletion
            debugPrint('DEBUG: Unexpected server error - failing deletion');
            _setError('Failed to delete trip from server. Please check your connection and try again.');
            return false;
          }
        }
      }

      // Proceed with local deletion
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
}
