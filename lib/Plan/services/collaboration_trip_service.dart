import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/collaboration_models.dart';
import '../models/trip_model.dart';

/// Firebase service for collaboration trips - Separate collections from private trips
class CollaborationTripService {
  // SEPARATE COLLECTIONS FOR COLLABORATION MODE
  static const String _sharedTripsCollection = 'shared_trips'; // Main shared trips collection
  static const String _userSharedTripsCollection = 'user_shared_trips'; // User's shared trips reference
  static const String _invitationsCollection = 'trip_invitations'; // Trip invitations
  static const String _usersCollection = 'users'; // Users collection

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  String? get _userEmail => _auth.currentUser?.email;

  // Public getter for user ID
  String? get currentUserId => _userId;

  /// Get shared trips collection reference
  CollectionReference<Map<String, dynamic>> get _sharedTripsRef =>
      _firestore.collection(_sharedTripsCollection);

  /// Get user's shared trips reference
  CollectionReference<Map<String, dynamic>>? get _userSharedTripsRef {
    if (_userId == null) return null;
    return _firestore
        .collection(_usersCollection)
        .doc(_userId!)
        .collection(_userSharedTripsCollection);
  }

  /// Get invitations collection reference
  CollectionReference<Map<String, dynamic>> get _invitationsRef =>
      _firestore.collection(_invitationsCollection);

  // TRIP MANAGEMENT

  /// Create a new shared trip
  Future<SharedTripModel> createSharedTrip(TripModel trip) async {
    try {
      if (_userId == null || _userEmail == null) {
        throw Exception('User not authenticated');
      }

      final user = _auth.currentUser!;
      final userName = user.displayName ?? user.email?.split('@').first ?? 'Unknown';

      debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - Creating trip: ${trip.name} for user: $_userId ($userName)');

      // Create shared trip document
      final sharedTripRef = _sharedTripsRef.doc();
      final tripId = sharedTripRef.id;

      // Generate shareable link
      final shareableLink = 'https://travelapp.com/trip/$tripId';

      // Create owner as first collaborator
      final owner = Collaborator(
        id: _userId!,
        userId: _userId!,
        email: _userEmail!,
        name: userName,
        role: 'owner',
        addedAt: DateTime.now(),
      );

      final sharedTrip = SharedTripModel.fromTripModel(
        trip.copyWith(id: tripId),
        ownerId: _userId!,
        ownerName: userName,
        ownerEmail: _userEmail!,
        collaborators: [owner],
        shareableLink: shareableLink,
      );

      debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - Preparing to save trip data...');

      // Save to shared trips collection
      await sharedTripRef.set({
        ...sharedTrip.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - Saved to shared_trips collection');

      // Add reference to user's shared trips
      await _userSharedTripsRef!.doc(tripId).set({
        'tripId': tripId,
        'role': 'owner',
        'addedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - Saved to user_shared_trips collection');

      // Verify the trip was created by reading it back
      final verifyDoc = await _sharedTripsRef.doc(tripId).get();
      if (verifyDoc.exists) {
        debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - ✅ Verified trip exists in Firestore');
      } else {
        debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - ❌ Trip not found in Firestore after creation');
      }

      debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - ✅ Successfully created shared trip: $tripId');

      return sharedTrip.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.createSharedTrip() - ❌ Error: $e');
      throw Exception('Failed to create shared trip: $e');
    }
  }

  /// Update shared trip
  Future<SharedTripModel> updateSharedTrip(SharedTripModel trip) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      if (trip.id == null) {
        throw Exception('Trip ID is required for update');
      }

      // Check if user has permission to update
      if (!trip.canUserEdit(_userId!)) {
        throw Exception('User does not have permission to update this trip');
      }

      final user = _auth.currentUser!;
      final userName = user.displayName ?? user.email?.split('@').first ?? 'Unknown';

      final updatedTrip = trip.copyWith(
        updatedAt: DateTime.now(),
        lastActivity: DateTime.now(),
        lastActivityBy: userName,
      );

      await _sharedTripsRef.doc(trip.id).update({
        ...updatedTrip.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'lastActivityBy': userName,
      });

      debugPrint('DEBUG: CollaborationTripService.updateSharedTrip() - Updated trip: ${trip.id}');
      return updatedTrip;
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.updateSharedTrip() - Error: $e');
      throw Exception('Failed to update shared trip: $e');
    }
  }

  /// Delete shared trip (only owner can delete)
  Future<void> deleteSharedTrip(String tripId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Get trip to check ownership
      final tripDoc = await _sharedTripsRef.doc(tripId).get();
      if (!tripDoc.exists) {
        throw Exception('Trip not found');
      }

      final tripData = tripDoc.data()!;
      final ownerId = tripData['ownerId'];

      if (ownerId != _userId) {
        throw Exception('Only trip owner can delete the trip');
      }

      // Get all collaborators to remove their references
      final sharedTrip = SharedTripModel.fromJson({...tripData, 'id': tripId});

      // Remove from all collaborators' user collections
      final batch = _firestore.batch();

      for (final collaborator in sharedTrip.sharedCollaborators) {
        final userTripRef = _firestore
            .collection(_usersCollection)
            .doc(collaborator.userId)
            .collection(_userSharedTripsCollection)
            .doc(tripId);
        batch.delete(userTripRef);
      }

      // Delete main trip document
      batch.delete(_sharedTripsRef.doc(tripId));

      await batch.commit();

      debugPrint('DEBUG: CollaborationTripService.deleteSharedTrip() - Deleted trip: $tripId');
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.deleteSharedTrip() - Error: $e');
      throw Exception('Failed to delete shared trip: $e');
    }
  }

  // TRIP LOADING

  /// Load all shared trips where user is owner or collaborator
  Future<List<SharedTripModel>> loadUserSharedTrips() async {
    try {
      if (_userId == null) {
        debugPrint('DEBUG: CollaborationTripService.loadUserSharedTrips() - User not authenticated');
        return [];
      }

      // Get user's shared trip references
      final userTripsSnapshot = await _userSharedTripsRef!
          .where('isActive', isEqualTo: true)
          .orderBy('addedAt', descending: true)
          .get();

      if (userTripsSnapshot.docs.isEmpty) {
        debugPrint('DEBUG: CollaborationTripService.loadUserSharedTrips() - No shared trips found');
        return [];
      }

      // Get all trip IDs
      final tripIds = userTripsSnapshot.docs.map((doc) => doc.id).toList();

      // Load actual trip documents
      final trips = <SharedTripModel>[];
      for (final tripId in tripIds) {
        final tripDoc = await _sharedTripsRef.doc(tripId).get();
        if (tripDoc.exists) {
          final tripData = tripDoc.data()!;
          tripData['id'] = tripDoc.id;
          trips.add(SharedTripModel.fromJson(tripData));
        }
      }

      debugPrint('DEBUG: CollaborationTripService.loadUserSharedTrips() - Loaded ${trips.length} shared trips');
      return trips;
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.loadUserSharedTrips() - Error: $e');
      throw Exception('Failed to load shared trips: $e');
    }
  }

  /// Load trips owned by current user
  Future<List<SharedTripModel>> loadMySharedTrips() async {
    try {
      if (_userId == null) {
        debugPrint('DEBUG: CollaborationTripService.loadMySharedTrips() - No user authenticated');
        return [];
      }

      debugPrint('DEBUG: CollaborationTripService.loadMySharedTrips() - Loading for user: $_userId');

      final snapshot = await _sharedTripsRef
          .where('ownerId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('DEBUG: CollaborationTripService.loadMySharedTrips() - Firestore returned ${snapshot.docs.length} documents');

      final trips = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('DEBUG: CollaborationTripService.loadMySharedTrips() - Processing trip: ${data['name']} (${doc.id})');
        return SharedTripModel.fromJson(data);
      }).toList();

      debugPrint('DEBUG: CollaborationTripService.loadMySharedTrips() - Final result: ${trips.length} owned trips');

      // Log each trip for debugging
      for (int i = 0; i < trips.length; i++) {
        debugPrint('DEBUG: CollaborationTripService.loadMySharedTrips() - Trip ${i + 1}: ${trips[i].name} (${trips[i].id}) - Owner: ${trips[i].ownerId}');
      }

      return trips;
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.loadMySharedTrips() - Error: $e');
      throw Exception('Failed to load my shared trips: $e');
    }
  }

  /// Load trips where user is collaborator (not owner)
  Future<List<SharedTripModel>> loadSharedWithMeTrips() async {
    try {
      if (_userId == null) {
        return [];
      }

      // Get user's shared trip references where role is not owner
      final userTripsSnapshot = await _userSharedTripsRef!
          .where('isActive', isEqualTo: true)
          .where('role', isNotEqualTo: 'owner')
          .orderBy('addedAt', descending: true)
          .get();

      if (userTripsSnapshot.docs.isEmpty) {
        return [];
      }

      // Get actual trip documents
      final trips = <SharedTripModel>[];
      for (final doc in userTripsSnapshot.docs) {
        final tripDoc = await _sharedTripsRef.doc(doc.id).get();
        if (tripDoc.exists) {
          final tripData = tripDoc.data()!;
          tripData['id'] = doc.id;
          trips.add(SharedTripModel.fromJson(tripData));
        }
      }

      debugPrint('DEBUG: CollaborationTripService.loadSharedWithMeTrips() - Loaded ${trips.length} shared trips');
      return trips;
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.loadSharedWithMeTrips() - Error: $e');
      throw Exception('Failed to load shared trips: $e');
    }
  }

  /// Get single shared trip
  Future<SharedTripModel?> getSharedTrip(String tripId) async {
    try {
      if (_userId == null) {
        return null;
      }

      final doc = await _sharedTripsRef.doc(tripId).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      final trip = SharedTripModel.fromJson(data);

      // Check if user has access
      if (!trip.hasUserAccess(_userId!)) {
        throw Exception('User does not have access to this trip');
      }

      return trip;
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.getSharedTrip() - Error: $e');
      return null;
    }
  }

  // REAL-TIME UPDATES

  /// Watch shared trips for real-time updates
  Stream<List<SharedTripModel>> watchUserSharedTrips() {
    if (_userId == null) {
      debugPrint('❌ WATCH_TRIPS: No user ID, returning empty stream');
      return Stream.value([]);
    }

    debugPrint('🎯 WATCH_TRIPS: Setting up real-time listener for user $_userId');

    return _userSharedTripsRef!
        .where('isActive', isEqualTo: true)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('❌ WATCH_TRIPS_STREAM_ERROR: $error');
        })
        .asyncMap((userTripsSnapshot) async {
      try {
        debugPrint('📡 FIRESTORE_EVENT: Received user trips snapshot with ${userTripsSnapshot.docs.length} docs');

        if (userTripsSnapshot.docs.isEmpty) {
          debugPrint('📭 FIRESTORE_EVENT: No active trips found');
          return <SharedTripModel>[];
        }

        final trips = <SharedTripModel>[];
        for (final doc in userTripsSnapshot.docs) {
          debugPrint('🔍 FIRESTORE_EVENT: Fetching trip ${doc.id}');
          try {
            final tripDoc = await _sharedTripsRef.doc(doc.id).get();
            if (tripDoc.exists) {
              final tripData = tripDoc.data()!;
              tripData['id'] = doc.id;
              final trip = SharedTripModel.fromJson(tripData);
              trips.add(trip);
              debugPrint('✅ FIRESTORE_EVENT: Added trip ${trip.name} (${trip.id})');
            } else {
              debugPrint('⚠️ FIRESTORE_EVENT: Trip ${doc.id} not found in shared_trips');
            }
          } catch (fetchError) {
            debugPrint('❌ FIRESTORE_EVENT_FETCH_ERROR: Failed to fetch trip ${doc.id}: $fetchError');
          }
        }

        debugPrint('🎉 FIRESTORE_EVENT: Returning ${trips.length} trips');
        return trips;
      } catch (e) {
        debugPrint('❌ FIRESTORE_EVENT_PROCESS_ERROR: Failed to process snapshot: $e');
        return <SharedTripModel>[];
      }
    })
        .handleError((error) {
          debugPrint('❌ WATCH_TRIPS_ASYNC_ERROR: $error');
          return <SharedTripModel>[];
        });
  }

  /// Watch single trip for real-time updates
  Stream<SharedTripModel?> watchSharedTrip(String tripId) {
    if (_userId == null) {
      return Stream.value(null);
    }

    return _sharedTripsRef.doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      final trip = SharedTripModel.fromJson(data);

      // Check access
      if (!trip.hasUserAccess(_userId!)) {
        return null;
      }

      return trip;
    });
  }

  // COLLABORATION FEATURES

  /// Send trip invitation with permission level
  Future<TripInvitation> inviteCollaborator(String tripId, String inviteeEmail, {
    String? message,
    String permissionLevel = 'editor', // default to editor
  }) async {
    try {
      if (_userId == null || _userEmail == null) {
        throw Exception('User not authenticated');
      }

      // Get trip to verify ownership
      final trip = await getSharedTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      if (!trip.isOwnerUser(_userId!)) {
        throw Exception('Only trip owner can invite collaborators');
      }

      // Check if user is already a collaborator
      if (trip.sharedCollaborators.any((c) => c.email.toLowerCase() == inviteeEmail.toLowerCase())) {
        throw Exception('User is already a collaborator on this trip');
      }

      // Check if invitation already exists
      final existingInvitation = await _invitationsRef
          .where('tripId', isEqualTo: tripId)
          .where('inviteeEmail', isEqualTo: inviteeEmail.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvitation.docs.isNotEmpty) {
        throw Exception('Invitation already sent to this email');
      }

      final user = _auth.currentUser!;
      final userName = user.displayName ?? user.email?.split('@').first ?? 'Unknown';

      // Create invitation
      final invitationRef = _invitationsRef.doc();
      final invitation = TripInvitation(
        id: invitationRef.id,
        tripId: tripId,
        tripName: trip.name,
        inviterUserId: _userId!,
        inviterName: userName,
        inviterEmail: _userEmail!,
        inviteeEmail: inviteeEmail.toLowerCase(),
        sentAt: DateTime.now(),
        message: message,
        permissionLevel: permissionLevel,
      );

      await invitationRef.set({
        ...invitation.toJson(),
        'sentAt': FieldValue.serverTimestamp(),
      });

      debugPrint('DEBUG: CollaborationTripService.inviteCollaborator() - Sent invitation: ${invitation.id}');
      return invitation;
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.inviteCollaborator() - Error: $e');
      throw Exception('Failed to send invitation: $e');
    }
  }

  /// Get pending invitations for current user
  Future<List<TripInvitation>> getPendingInvitations() async {
    try {
      if (_userEmail == null) {
        return [];
      }

      final snapshot = await _invitationsRef
          .where('inviteeEmail', isEqualTo: _userEmail!.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .orderBy('sentAt', descending: true)
          .get();

      final invitations = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripInvitation.fromJson(data);
      }).toList();

      debugPrint('DEBUG: CollaborationTripService.getPendingInvitations() - Found ${invitations.length} invitations');
      return invitations;
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.getPendingInvitations() - Error: $e');
      return [];
    }
  }

  /// Accept trip invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      if (_userId == null || _userEmail == null) {
        throw Exception('User not authenticated');
      }

      final invitationDoc = await _invitationsRef.doc(invitationId).get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitationData = invitationDoc.data()!;
      final invitation = TripInvitation.fromJson({...invitationData, 'id': invitationId});

      if (invitation.inviteeEmail.toLowerCase() != _userEmail!.toLowerCase()) {
        throw Exception('This invitation is not for you');
      }

      if (invitation.status != 'pending') {
        throw Exception('Invitation is no longer pending');
      }

      final user = _auth.currentUser!;
      final userName = user.displayName ?? user.email?.split('@').first ?? 'Unknown';

      // Create collaborator with the specified permission level
      final collaborator = Collaborator(
        id: _userId!,
        userId: _userId!,
        email: _userEmail!,
        name: userName,
        role: invitation.permissionLevel, // Use the permission level from invitation
        addedAt: DateTime.now(),
      );

      final batch = _firestore.batch();

      // Update invitation status
      batch.update(_invitationsRef.doc(invitationId), {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
        'inviteeUserId': _userId,
      });

      // Add collaborator to trip
      batch.update(_sharedTripsRef.doc(invitation.tripId), {
        'sharedCollaborators': FieldValue.arrayUnion([collaborator.toJson()]),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'lastActivityBy': '$userName joined the trip',
      });

      // Add trip reference to user's collection
      batch.set(
        _userSharedTripsRef!.doc(invitation.tripId),
        {
          'tripId': invitation.tripId,
          'role': invitation.permissionLevel,
          'addedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
      );

      await batch.commit();

      debugPrint('DEBUG: CollaborationTripService.acceptInvitation() - Accepted invitation: $invitationId');
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.acceptInvitation() - Error: $e');
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// Decline trip invitation
  Future<void> declineInvitation(String invitationId) async {
    try {
      if (_userEmail == null) {
        throw Exception('User not authenticated');
      }

      final invitationDoc = await _invitationsRef.doc(invitationId).get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitationData = invitationDoc.data()!;
      final invitation = TripInvitation.fromJson({...invitationData, 'id': invitationId});

      if (invitation.inviteeEmail.toLowerCase() != _userEmail!.toLowerCase()) {
        throw Exception('This invitation is not for you');
      }

      await _invitationsRef.doc(invitationId).update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
        'inviteeUserId': _userId,
      });

      debugPrint('DEBUG: CollaborationTripService.declineInvitation() - Declined invitation: $invitationId');
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.declineInvitation() - Error: $e');
      throw Exception('Failed to decline invitation: $e');
    }
  }

  /// Remove collaborator from trip
  Future<void> removeCollaborator(String tripId, String collaboratorUserId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final trip = await getSharedTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      if (!trip.isOwnerUser(_userId!)) {
        throw Exception('Only trip owner can remove collaborators');
      }

      if (collaboratorUserId == _userId) {
        throw Exception('Owner cannot be removed from trip');
      }

      // Find collaborator to remove
      final collaboratorToRemove = trip.getCollaboratorByUserId(collaboratorUserId);
      if (collaboratorToRemove == null) {
        throw Exception('Collaborator not found');
      }

      final updatedCollaborators = trip.sharedCollaborators
          .where((c) => c.userId != collaboratorUserId)
          .map((c) => c.toJson())
          .toList();

      final batch = _firestore.batch();

      // Update trip collaborators list
      batch.update(_sharedTripsRef.doc(tripId), {
        'sharedCollaborators': updatedCollaborators,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from user's shared trips
      batch.update(
        _firestore
            .collection(_usersCollection)
            .doc(collaboratorUserId)
            .collection(_userSharedTripsCollection)
            .doc(tripId),
        {'isActive': false}
      );

      await batch.commit();

      debugPrint('DEBUG: CollaborationTripService.removeCollaborator() - Removed collaborator: $collaboratorUserId');
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.removeCollaborator() - Error: $e');
      throw Exception('Failed to remove collaborator: $e');
    }
  }

  /// Leave shared trip (collaborator leaves)
  Future<void> leaveSharedTrip(String tripId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final trip = await getSharedTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      if (trip.isOwnerUser(_userId!)) {
        throw Exception('Trip owner cannot leave. Transfer ownership or delete the trip instead.');
      }

      final updatedCollaborators = trip.sharedCollaborators
          .where((c) => c.userId != _userId)
          .map((c) => c.toJson())
          .toList();

      final batch = _firestore.batch();

      // Update trip collaborators list
      batch.update(_sharedTripsRef.doc(tripId), {
        'sharedCollaborators': updatedCollaborators,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from user's shared trips
      batch.update(_userSharedTripsRef!.doc(tripId), {'isActive': false});

      await batch.commit();

      debugPrint('DEBUG: CollaborationTripService.leaveSharedTrip() - Left trip: $tripId');
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.leaveSharedTrip() - Error: $e');
      throw Exception('Failed to leave trip: $e');
    }
  }

  /// Update collaborator permission level
  Future<void> updateCollaboratorPermission(String tripId, String collaboratorUserId, String newRole) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final trip = await getSharedTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      if (!trip.isOwnerUser(_userId!)) {
        throw Exception('Only trip owner can update collaborator permissions');
      }

      if (collaboratorUserId == _userId) {
        throw Exception('Cannot change owner permissions');
      }

      if (newRole != 'editor' && newRole != 'viewer') {
        throw Exception('Invalid permission level. Must be "editor" or "viewer"');
      }

      // Find collaborator to update
      final collaboratorIndex = trip.sharedCollaborators.indexWhere((c) => c.userId == collaboratorUserId);
      if (collaboratorIndex == -1) {
        throw Exception('Collaborator not found');
      }

      // Update the collaborator's role
      final updatedCollaborators = List<Collaborator>.from(trip.sharedCollaborators);
      updatedCollaborators[collaboratorIndex] = updatedCollaborators[collaboratorIndex].copyWith(
        role: newRole,
      );

      await _sharedTripsRef.doc(tripId).update({
        'sharedCollaborators': updatedCollaborators.map((c) => c.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user's shared trips reference
      await _firestore
          .collection(_usersCollection)
          .doc(collaboratorUserId)
          .collection(_userSharedTripsCollection)
          .doc(tripId)
          .update({
        'role': newRole,
      });

      debugPrint('DEBUG: CollaborationTripService.updateCollaboratorPermission() - Updated permission for collaborator: $collaboratorUserId to $newRole');
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.updateCollaboratorPermission() - Error: $e');
      throw Exception('Failed to update collaborator permission: $e');
    }
  }

  /// Generate shareable link for a trip
  String generateShareableLink(String tripId) {
    return 'https://travelapp.com/trip/$tripId';
  }

  /// Get trip by shareable link
  Future<SharedTripModel?> getTripByShareableLink(String link) async {
    try {
      // Extract trip ID from link
      final uri = Uri.parse(link);
      final segments = uri.pathSegments;
      if (segments.length < 2 || segments[0] != 'trip') {
        return null;
      }

      final tripId = segments[1];
      return await getSharedTrip(tripId);
    } catch (e) {
      debugPrint('DEBUG: CollaborationTripService.getTripByShareableLink() - Error: $e');
      return null;
    }
  }

  // REAL-TIME WATCHERS

  /// Watch pending invitations for real-time updates
  Stream<List<TripInvitation>> watchPendingInvitations() {
    if (_userEmail == null) {
      return Stream.value([]);
    }

    return _invitationsRef
        .where('inviteeEmail', isEqualTo: _userEmail!.toLowerCase())
        .where('status', isEqualTo: 'pending')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripInvitation.fromJson(data);
      }).toList();
    });
  }
}
