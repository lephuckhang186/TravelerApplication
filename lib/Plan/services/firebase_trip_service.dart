import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';

/// Firebase Firestore service for trips - Real cloud persistence
class FirebaseTripService {
  static const String _tripsCollection = 'trips';
  static const String _usersCollection = 'users';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
  /// Get user's trips collection reference
  CollectionReference<Map<String, dynamic>>? get _userTripsCollection {
    if (_userId == null) return null;
    return _firestore
        .collection(_usersCollection)
        .doc(_userId!)
        .collection(_tripsCollection);
  }
  
  /// Save trip to Firebase Firestore
  Future<TripModel> saveTrip(TripModel trip) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }
      
      final collection = _userTripsCollection!;
      final tripData = trip.toJson();
      
      // Remove null id for new trips
      if (trip.id == null || trip.id!.startsWith('local_')) {
        tripData.remove('id');
        
        // Add new trip
        final docRef = await collection.add({
          ...tripData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': _userId,
        });
        
        final savedTrip = trip.copyWith(
          id: docRef.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        debugPrint('DEBUG: FirebaseTripService.saveTrip() - Created new trip: ${docRef.id}');
        return savedTrip;
      } else {
        // Update existing trip
        await collection.doc(trip.id).set({
          ...tripData,
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': _userId,
        }, SetOptions(merge: true));
        
        final updatedTrip = trip.copyWith(updatedAt: DateTime.now());
        debugPrint('DEBUG: FirebaseTripService.saveTrip() - Updated trip: ${trip.id}');
        return updatedTrip;
      }
    } catch (e) {
      debugPrint('DEBUG: FirebaseTripService.saveTrip() - Error: $e');
      throw Exception('Failed to save trip to Firebase: $e');
    }
  }
  
  /// Load all trips for current user from Firebase
  Future<List<TripModel>> loadTrips() async {
    try {
      if (_userId == null) {
        debugPrint('DEBUG: FirebaseTripService.loadTrips() - User not authenticated');
        return [];
      }
      
      final collection = _userTripsCollection!;
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .get();
      
      final trips = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is set
        return TripModel.fromJson(data);
      }).toList();
      
      debugPrint('DEBUG: FirebaseTripService.loadTrips() - Loaded ${trips.length} trips from Firebase');
      for (int i = 0; i < trips.length; i++) {
        debugPrint('DEBUG: Firebase Trip ${i + 1}: ${trips[i].name} (${trips[i].id})');
      }
      
      return trips;
    } catch (e) {
      debugPrint('DEBUG: FirebaseTripService.loadTrips() - Error: $e');
      throw Exception('Failed to load trips from Firebase: $e');
    }
  }
  
  /// Delete trip from Firebase
  Future<void> deleteTrip(String tripId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }
      
      final collection = _userTripsCollection!;
      await collection.doc(tripId).delete();
      
      debugPrint('DEBUG: FirebaseTripService.deleteTrip() - Deleted trip: $tripId');
    } catch (e) {
      debugPrint('DEBUG: FirebaseTripService.deleteTrip() - Error: $e');
      throw Exception('Failed to delete trip from Firebase: $e');
    }
  }
  
  /// Listen to real-time updates for user's trips
  Stream<List<TripModel>> watchTrips() {
    if (_userId == null) {
      return Stream.value([]);
    }
    
    final collection = _userTripsCollection!;
    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripModel.fromJson(data);
      }).toList();
    });
  }
  
  /// Sync local trip to Firebase (for offline trips)
  Future<TripModel> syncLocalTrip(TripModel localTrip) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Create clean trip without local ID
      final cleanTrip = localTrip.copyWith(id: null);
      final cloudTrip = await saveTrip(cleanTrip);
      
      debugPrint('DEBUG: FirebaseTripService.syncLocalTrip() - Synced local trip ${localTrip.id} → ${cloudTrip.id}');
      return cloudTrip;
    } catch (e) {
      debugPrint('DEBUG: FirebaseTripService.syncLocalTrip() - Error: $e');
      throw Exception('Failed to sync local trip: $e');
    }
  }
  
  /// Batch sync multiple local trips
  Future<List<TripModel>> syncLocalTrips(List<TripModel> localTrips) async {
    final syncedTrips = <TripModel>[];
    
    for (final trip in localTrips) {
      try {
        if (trip.id?.startsWith('local_') == true) {
          final syncedTrip = await syncLocalTrip(trip);
          syncedTrips.add(syncedTrip);
        } else {
          syncedTrips.add(trip);
        }
      } catch (e) {
        debugPrint('DEBUG: FirebaseTripService.syncLocalTrips() - Failed to sync ${trip.name}: $e');
        // Keep original trip if sync fails
        syncedTrips.add(trip);
      }
    }
    
    debugPrint('DEBUG: FirebaseTripService.syncLocalTrips() - Synced ${syncedTrips.length} trips');
    return syncedTrips;
  }
  
  /// Check if user has Firebase connectivity
  Future<bool> checkConnectivity() async {
    try {
      if (_userId == null) return false;
      
      // Try a simple read to check connectivity
      await _firestore
          .collection('connectivity_test')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      
      return true;
    } catch (e) {
      debugPrint('DEBUG: FirebaseTripService.checkConnectivity() - No Firebase connectivity: $e');
      return false;
    }
  }
}