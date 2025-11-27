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
      // Try to delete from server
      try {
        await _apiService.deleteTrip(tripId);
      } catch (e) {
        debugPrint('Failed to delete from server: $e');
      }

      // Remove from local list and storage
      _trips.removeWhere((trip) => trip.id == tripId);
      await _storageService.saveTrips(_trips);
      
      if (_currentTrip?.id == tripId) {
        _currentTrip = null;
      }

      _clearError();
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
      final apiTrips = await _apiService.getTrips();
      // Merge API trips with local trips, prioritizing API data
      final Map<String, TripModel> tripMap = {};
      
      // First add local trips
      for (final trip in _trips) {
        if (trip.id != null) {
          tripMap[trip.id!] = trip;
        }
      }
      
      // Then add/override with API trips
      for (final trip in apiTrips) {
        if (trip.id != null) {
          tripMap[trip.id!] = trip;
        }
      }
      
      _trips = tripMap.values.toList();
      await _storageService.saveTrips(_trips);
      notifyListeners();
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
