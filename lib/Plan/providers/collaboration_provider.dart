 import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/Plan/models/activity_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/collaboration_models.dart';
import '../models/trip_model.dart';
import '../services/collaboration_trip_service.dart';
import '../services/firebase_trip_service.dart';
import '../utils/activity_scheduling_validator.dart';

/// Provider for collaboration mode - unified with private mode backend
class CollaborationProvider extends ChangeNotifier {
  final CollaborationTripService _collaborationService = CollaborationTripService();
  final FirebaseTripService _firebaseService = FirebaseTripService();

  // Getter to access service (for external access)
  CollaborationTripService get collaborationService => _collaborationService;
  
  // SEPARATE STATE FOR COLLABORATION MODE
  List<SharedTripModel> _mySharedTrips = []; // Trips owned by user
  List<SharedTripModel> _sharedWithMeTrips = []; // Trips shared with user
  List<TripInvitation> _pendingInvitations = [];
  SharedTripModel? _selectedSharedTrip;
  
  bool _isLoading = false;
  String? _error;
  
  // Real-time subscriptions
  StreamSubscription<List<SharedTripModel>>? _myTripsSubscription;
  StreamSubscription<SharedTripModel?>? _selectedTripSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<List<TripInvitation>>? _invitationsSubscription;

  // Getters
  List<SharedTripModel> get mySharedTrips => List.unmodifiable(_mySharedTrips);
  List<SharedTripModel> get sharedWithMeTrips => List.unmodifiable(_sharedWithMeTrips);
  List<SharedTripModel> get allSharedTrips => [..._mySharedTrips, ..._sharedWithMeTrips];
  List<TripInvitation> get pendingInvitations => List.unmodifiable(_pendingInvitations);
  SharedTripModel? get selectedSharedTrip => _selectedSharedTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get hasSharedTrips => _mySharedTrips.isNotEmpty || _sharedWithMeTrips.isNotEmpty;
  bool get hasPendingInvitations => _pendingInvitations.isNotEmpty;
  int get totalSharedTrips => _mySharedTrips.length + _sharedWithMeTrips.length;

  @override
  void dispose() {
    _myTripsSubscription?.cancel();
    _selectedTripSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // LOADING METHODS

  /// Initialize collaboration data (equivalent to private mode initialize)
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Clear any existing data first to ensure fresh load
      clearAllData();

      // Load data from Firestore first, then start real-time listening
      await Future.wait([
        loadMySharedTrips(),
        loadSharedWithMeTrips(),
        loadPendingInvitations(),
      ]);

      // Start real-time listening after initial load
      _startRealTimeListening();
      _startInvitationsListening();
      _startAuthStateListening();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Ensure provider is initialized (lazy initialization)
  Future<void> ensureInitialized() async {
    if (!hasSharedTrips && !_isLoading) {
      await initialize();
    } else if (hasSharedTrips && !_isLoading) {
      // Even if we have trips, ensure real-time listeners are active
      _startRealTimeListening();
      _startInvitationsListening();
    }
  }


  /// Initialize collaboration data (kept for backward compatibility)
  Future<void> initializeCollaboration() async {
    await Future.wait([
      loadMySharedTrips(),
      loadSharedWithMeTrips(),
      loadPendingInvitations(),
    ]);
    _startRealTimeListening();
  }

  /// Load trips owned by current user
  Future<void> loadMySharedTrips() async {
    try {
      final trips = await _collaborationService.loadMySharedTrips();
      _mySharedTrips = trips;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load your shared trips: $e');
      rethrow;
    }
  }

  /// Load trips shared with current user
  Future<void> loadSharedWithMeTrips() async {
    try {
      final trips = await _collaborationService.loadSharedWithMeTrips();
      _sharedWithMeTrips = trips;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load trips shared with you: $e');
      rethrow;
    }
  }

  /// Load pending invitations
  Future<void> loadPendingInvitations() async {
    try {
      final invitations = await _collaborationService.getPendingInvitations();
      _pendingInvitations = invitations;
      notifyListeners();
    } catch (e) {
      // Don't rethrow for invitations as it's not critical
    }
  }

  /// Refresh all collaboration data
  Future<void> refreshCollaborationData() async {
    await initializeCollaboration();
  }

  // TRIP MANAGEMENT

  /// Create a new trip (equivalent to private mode createTrip)
  Future<SharedTripModel?> createTrip({
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

      final createdTrip = await createSharedTrip(trip);
      return createdTrip;
    } catch (e) {
      _setError('Failed to create trip: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Add trip to local state (for compatibility with private mode)
  void addTrip(dynamic trip) {
    if (trip is SharedTripModel) {
      _mySharedTrips.insert(0, trip);
      notifyListeners();
    }
  }

  /// Set current trip (for compatibility with private mode)
  void setCurrentTrip(dynamic trip) {
    if (trip is SharedTripModel) {
      _selectedSharedTrip = trip;
      notifyListeners();
    }
  }

  /// Create new shared trip from regular trip (collaboration-only backend)
  Future<SharedTripModel?> createSharedTrip(TripModel trip) async {
    try {
      _setLoading(true);
      _clearError();

      // For collaboration trips, only save to Firebase (not to TripPlanningProvider)
      final tripForFirebase = trip.copyWith(
        id: trip.id ?? 'collab_${DateTime.now().millisecondsSinceEpoch}',
      );

      await _firebaseService.saveTrip(tripForFirebase);

      // Create shared trip in collaboration service
      final sharedTrip = await _collaborationService.createSharedTrip(tripForFirebase);

      // Add to local state
      _mySharedTrips.insert(0, sharedTrip);
      notifyListeners(); // Immediate UI update

      // Force reload from Firestore to ensure data consistency
      await loadMySharedTrips();

      return sharedTrip;
    } catch (e) {
      _setError('Failed to create shared trip: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update shared trip
  Future<bool> updateSharedTrip(SharedTripModel trip) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedTrip = await _collaborationService.updateSharedTrip(trip);

      // Update in appropriate list
      _updateTripInLists(updatedTrip);

      // Update selected trip if it matches
      if (_selectedSharedTrip?.id == trip.id) {
        _selectedSharedTrip = updatedTrip;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update shared trip: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete shared trip (owner only)
  Future<bool> deleteSharedTrip(String tripId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _collaborationService.deleteSharedTrip(tripId);
      
      // Remove from lists
      _mySharedTrips.removeWhere((trip) => trip.id == tripId);
      _sharedWithMeTrips.removeWhere((trip) => trip.id == tripId);
      
      // Clear selected trip if it was deleted
      if (_selectedSharedTrip?.id == tripId) {
        _selectedSharedTrip = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete shared trip: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Select shared trip for detailed view
  Future<void> selectSharedTrip(String tripId) async {
    try {
      _clearError();
      
      final trip = await _collaborationService.getSharedTrip(tripId);
      _selectedSharedTrip = trip;
      
      // Start listening to real-time updates for selected trip
      _startSelectedTripListening(tripId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load trip details: $e');
    }
  }

  /// Clear selected trip
  void clearSelectedTrip() {
    _selectedSharedTrip = null;
    _selectedTripSubscription?.cancel();
    notifyListeners();
  }

  // COLLABORATION FEATURES

  /// Invite collaborator to trip
  Future<bool> inviteCollaborator(String tripId, String email, {String? message, String permissionLevel = 'editor'}) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _collaborationService.inviteCollaborator(
        tripId, 
        email, 
        message: message,
        permissionLevel: permissionLevel,
      );
      
      return true;
    } catch (e) {
      _setError('Failed to send invitation: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Accept invitation
  Future<bool> acceptInvitation(String invitationId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _collaborationService.acceptInvitation(invitationId);
      
      // Remove from pending invitations
      _pendingInvitations.removeWhere((inv) => inv.id == invitationId);
      
      // Reload shared trips to include new trip
      await loadSharedWithMeTrips();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to accept invitation: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Decline invitation
  Future<bool> declineInvitation(String invitationId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _collaborationService.declineInvitation(invitationId);
      
      // Remove from pending invitations
      _pendingInvitations.removeWhere((inv) => inv.id == invitationId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to decline invitation: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Remove collaborator from trip
  Future<bool> removeCollaborator(String tripId, String collaboratorUserId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _collaborationService.removeCollaborator(tripId, collaboratorUserId);
      
      // Reload trip data to reflect changes
      await selectSharedTrip(tripId);
      
      return true;
    } catch (e) {
      _setError('Failed to remove collaborator: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Leave shared trip
  Future<bool> leaveSharedTrip(String tripId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _collaborationService.leaveSharedTrip(tripId);
      
      // Remove from shared with me trips
      _sharedWithMeTrips.removeWhere((trip) => trip.id == tripId);
      
      // Clear selected trip if it was the one we left
      if (_selectedSharedTrip?.id == tripId) {
        _selectedSharedTrip = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to leave trip: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // REAL-TIME FEATURES

  /// Start listening to real-time updates
  void _startRealTimeListening() {
    // Cancel existing subscription first
    _myTripsSubscription?.cancel();

    // Listen to user's shared trips
    _myTripsSubscription = _collaborationService.watchUserSharedTrips().listen(
      (trips) {
        // Separate owned trips from collaborated trips
        final myTrips = <SharedTripModel>[];
        final sharedTrips = <SharedTripModel>[];

        final userId = _collaborationService.currentUserId;

        if (userId != null) {
          for (final trip in trips) {
            if (trip.isOwnerUser(userId)) {
              myTrips.add(trip);
            } else {
              sharedTrips.add(trip);
            }
          }
        }

        // Update state - CORRECTLY SEPARATE OWNED VS SHARED

        // Clear and rebuild lists from Firestore data
        final newMyTrips = <SharedTripModel>[];
        final newSharedTrips = <SharedTripModel>[];

        // Separate trips correctly based on ownership
        for (final trip in trips) {
          // Sort activities chronologically for consistent display
          final sortedTrip = trip.copyWith(
            activities: ActivitySchedulingValidator.sortActivitiesChronologically(trip.activities),
          );

          final isOwner = sortedTrip.isOwnerUser(userId!);

          if (isOwner) {
            newMyTrips.add(sortedTrip);
          } else {
            newSharedTrips.add(sortedTrip);
          }
        }

        // Update state with correctly separated data
        _mySharedTrips = newMyTrips;
        _sharedWithMeTrips = newSharedTrips;

        // CRITICAL: Force UI refresh with logging and timestamp
        notifyListeners();

        // Check for new invitations
        _checkForNewInvitations();
      },
      onError: (error) {
        _setError('Real-time sync error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Start listening to selected trip updates
  void _startSelectedTripListening(String tripId) {
    _selectedTripSubscription?.cancel();
    _selectedTripSubscription = _collaborationService.watchSharedTrip(tripId).listen(
      (trip) {
        if (trip != null) {
          // Sort activities chronologically for consistent display
          final sortedTrip = trip.copyWith(
            activities: ActivitySchedulingValidator.sortActivitiesChronologically(trip.activities),
          );
          _selectedSharedTrip = sortedTrip;
          _updateTripInLists(sortedTrip); // Also update in main lists
          notifyListeners();
        } else {
        }
      },
      onError: (error) {
      },
      cancelOnError: false,
    );
  }

  /// Start listening to Firebase auth state changes
  void _startAuthStateListening() {
    _authStateSubscription?.cancel();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (user != null) {
          // User is signed in, refresh collaboration data for this user
          refreshCollaborationData();
        } else {
          // User is signed out, clear all data
          clearAllData();
        }
      },
      onError: (error) {
      },
    );
  }

  /// Start listening to invitation updates
  void _startInvitationsListening() {
    _invitationsSubscription?.cancel();
    _invitationsSubscription = _collaborationService.watchPendingInvitations().listen(
      (invitations) {
        _pendingInvitations = invitations;

        // Force UI refresh
        notifyListeners();
      },
      onError: (error) {
      },
      cancelOnError: false,
    );
  }

  /// Stop real-time listening
  void stopRealTimeListening() {
    _myTripsSubscription?.cancel();
    _selectedTripSubscription?.cancel();
    _authStateSubscription?.cancel();
    _invitationsSubscription?.cancel();
  }

  // HELPER METHODS

  void _updateTripInLists(SharedTripModel updatedTrip) {
    final userId = _collaborationService.currentUserId;
    if (userId == null) return;

    // Update in owned trips
    final myTripIndex = _mySharedTrips.indexWhere((trip) => trip.id == updatedTrip.id);
    if (myTripIndex != -1 && updatedTrip.isOwnerUser(userId)) {
      _mySharedTrips[myTripIndex] = updatedTrip;
    }

    // Update in shared trips
    final sharedTripIndex = _sharedWithMeTrips.indexWhere((trip) => trip.id == updatedTrip.id);
    if (sharedTripIndex != -1 && !updatedTrip.isOwnerUser(userId)) {
      _sharedWithMeTrips[sharedTripIndex] = updatedTrip;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // UTILITY METHODS

  /// Get trip by ID from all lists
  SharedTripModel? getTripById(String tripId) {
    try {
      return allSharedTrips.firstWhere((trip) => trip.id == tripId);
    } catch (e) {
      return null;
    }
  }

  /// Check if user owns a trip
  bool isUserOwnerOfTrip(String tripId) {
    return _mySharedTrips.any((trip) => trip.id == tripId);
  }

  /// Check if user is collaborator on a trip
  bool isUserCollaboratorOnTrip(String tripId) {
    return _sharedWithMeTrips.any((trip) => trip.id == tripId);
  }

  /// Get invitation by ID
  TripInvitation? getInvitationById(String invitationId) {
    try {
      return _pendingInvitations.firstWhere((inv) => inv.id == invitationId);
    } catch (e) {
      return null;
    }
  }

  /// Check for new invitations when trips are updated
  void _checkForNewInvitations() {
    // Load pending invitations in background
    loadPendingInvitations();
  }

  /// Clear all data (for logout)
  void clearAllData() {
    _mySharedTrips.clear();
    _sharedWithMeTrips.clear();
    _pendingInvitations.clear();
    _selectedSharedTrip = null;
    _error = null;
    _isLoading = false;

    stopRealTimeListening();
    notifyListeners();
  }

  /// Respond to invitation (accept or decline)
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    if (accept) {
      await acceptInvitation(invitationId);
    } else {
      await declineInvitation(invitationId);
    }
  }

  /// Update collaborator permission level
  Future<bool> updateCollaboratorPermission(String tripId, String collaboratorUserId, String newRole) async {
    try {
      _setLoading(true);
      _clearError();

      await _collaborationService.updateCollaboratorPermission(tripId, collaboratorUserId, newRole);

      // Reload trip data to reflect permission changes
      await selectSharedTrip(tripId);

      return true;
    } catch (e) {
      _setError('Failed to update permission: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
