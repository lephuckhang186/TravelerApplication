import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Login/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Model for real-time user travel statistics from Firestore
class UserTravelStats {
  final int totalActivities;
  final int completedTrips;
  final int checkedInLocations;
  final double totalExpenses;
  final int totalPlans;
  final int ongoingTrips;
  final int upcomingTrips;
  final Map<String, double> monthlyExpenses;
  final double averageExpensePerTrip;
  final int totalDays;
  final double totalDistance;
  
  // Stats for 2025 only
  final int totalActivities2025;
  final int completedTrips2025;
  final int checkedInLocations2025;
  final int totalPlans2025;
  final int totalDays2025;

  UserTravelStats({
    required this.totalActivities,
    required this.completedTrips,
    required this.checkedInLocations,
    required this.totalExpenses,
    required this.totalPlans,
    required this.ongoingTrips,
    required this.upcomingTrips,
    required this.monthlyExpenses,
    required this.averageExpensePerTrip,
    required this.totalDays,
    required this.totalDistance,
    required this.totalActivities2025,
    required this.completedTrips2025,
    required this.checkedInLocations2025,
    required this.totalPlans2025,
    required this.totalDays2025,
  });

  factory UserTravelStats.empty() {
    return UserTravelStats(
      totalActivities: 0,
      completedTrips: 0,
      checkedInLocations: 0,
      totalExpenses: 0.0,
      totalPlans: 0,
      ongoingTrips: 0,
      upcomingTrips: 0,
      monthlyExpenses: {},
      averageExpensePerTrip: 0.0,
      totalDays: 0,
      totalDistance: 0.0,
      totalActivities2025: 0,
      completedTrips2025: 0,
      checkedInLocations2025: 0,
      totalPlans2025: 0,
      totalDays2025: 0,
    );
  }

  UserTravelStats copyWith({
    int? totalActivities,
    int? completedTrips,
    int? checkedInLocations,
    double? totalExpenses,
    int? totalPlans,
    int? ongoingTrips,
    int? upcomingTrips,
    Map<String, double>? monthlyExpenses,
    double? averageExpensePerTrip,
    int? totalDays,
    double? totalDistance,
    int? totalActivities2025,
    int? completedTrips2025,
    int? checkedInLocations2025,
    int? totalPlans2025,
    int? totalDays2025,
  }) {
    return UserTravelStats(
      totalActivities: totalActivities ?? this.totalActivities,
      completedTrips: completedTrips ?? this.completedTrips,
      checkedInLocations: checkedInLocations ?? this.checkedInLocations,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalPlans: totalPlans ?? this.totalPlans,
      ongoingTrips: ongoingTrips ?? this.ongoingTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      averageExpensePerTrip: averageExpensePerTrip ?? this.averageExpensePerTrip,
      totalDays: totalDays ?? this.totalDays,
      totalDistance: totalDistance ?? this.totalDistance,
      totalActivities2025: totalActivities2025 ?? this.totalActivities2025,
      completedTrips2025: completedTrips2025 ?? this.completedTrips2025,
      checkedInLocations2025: checkedInLocations2025 ?? this.checkedInLocations2025,
      totalPlans2025: totalPlans2025 ?? this.totalPlans2025,
      totalDays2025: totalDays2025 ?? this.totalDays2025,
    );
  }
}

/// Service for getting real-time statistics from Firestore
class FirestoreStatisticsService {
  static final FirestoreStatisticsService _instance = FirestoreStatisticsService._internal();
  factory FirestoreStatisticsService() => _instance;
  FirestoreStatisticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  StreamController<UserTravelStats>? _statsController;
  StreamSubscription<QuerySnapshot>? _tripsSubscription;
  StreamSubscription<QuerySnapshot>? _expensesSubscription;

  /// Get real-time statistics stream
  Stream<UserTravelStats> getUserStatisticsStream() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value(UserTravelStats.empty());
    }

    _statsController?.close();
    _statsController = StreamController<UserTravelStats>.broadcast();

    _listenToTripsAndExpenses(currentUser.uid);
    
    return _statsController!.stream;
  }

  /// Listen to trips and expenses changes
  void _listenToTripsAndExpenses(String userId) {
    UserTravelStats currentStats = UserTravelStats.empty();
    bool tripsLoaded = false;
    bool expensesLoaded = false;

    // Emit empty stats immediately to show UI quickly
    _statsController?.add(currentStats);

    // Listen to trips changes - filter for private trips in processing
    _tripsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('trips')
        .snapshots()
        .listen((tripsSnapshot) {
      final tripsStats = _calculateTripsStatistics(tripsSnapshot);
      currentStats = currentStats.copyWith(
        totalActivities: tripsStats['totalActivities'],
        completedTrips: tripsStats['completedTrips'],
        ongoingTrips: tripsStats['ongoingTrips'],
        upcomingTrips: tripsStats['upcomingTrips'],
        totalPlans: tripsStats['totalPlans'],
        checkedInLocations: tripsStats['checkedInLocations'],
        totalDays: tripsStats['totalDays'],
        totalDistance: tripsStats['totalDistance'],
        totalActivities2025: tripsStats['totalActivities2025'],
        completedTrips2025: tripsStats['completedTrips2025'],
        totalPlans2025: tripsStats['totalPlans2025'],
        checkedInLocations2025: tripsStats['checkedInLocations2025'],
        totalDays2025: tripsStats['totalDays2025'],
      );
      
      tripsLoaded = true;
      // Emit stats immediately when trips are loaded, don't wait for expenses
      _statsController?.add(currentStats);
    }, onError: (error) {
      debugPrint('Error loading trips: $error');
      tripsLoaded = true;
      _statsController?.add(currentStats);
    });

    // Listen to expenses changes
    _expensesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .snapshots()
        .listen((expensesSnapshot) {
      final expensesStats = _calculateExpensesStatistics(expensesSnapshot);
      
      // Calculate average expense per trip if we have completed trips
      final completedTrips = currentStats.completedTrips > 0 ? currentStats.completedTrips : 1;
      final averageExpensePerTrip = expensesStats['totalExpenses'] / completedTrips;
      
      currentStats = currentStats.copyWith(
        totalExpenses: expensesStats['totalExpenses'],
        monthlyExpenses: expensesStats['monthlyExpenses'],
        averageExpensePerTrip: averageExpensePerTrip,
      );
      
      expensesLoaded = true;
      // Always emit updated stats when expenses are loaded
      _statsController?.add(currentStats);
    }, onError: (error) {
      debugPrint('Error loading expenses: $error');
      expensesLoaded = true;
      // Continue without expenses data
      _statsController?.add(currentStats);
    });
  }

  /// Calculate statistics from trips
  Map<String, dynamic> _calculateTripsStatistics(QuerySnapshot snapshot) {
    int totalActivities = 0;
    int completedTrips = 0;
    int ongoingTrips = 0;
    int upcomingTrips = 0;
    int totalPlans = 0; // Will count only private plans
    int checkedInLocations = 0;
    int totalDays = 0;
    double totalDistance = 0.0;

    // Stats for 2025 only
    int totalActivities2025 = 0;
    int completedTrips2025 = 0;
    int totalPlans2025 = 0;
    int checkedInLocations2025 = 0;
    int totalDays2025 = 0;

    final now = DateTime.now();
    final year2025Start = DateTime(2025, 1, 1);
    final year2025End = DateTime(2025, 12, 31, 23, 59, 59);

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Only count private trips (trips with no collaborators)
      final collaborators = data['collaborators'] as List<dynamic>? ?? [];
      if (collaborators.isNotEmpty) {
        continue; // Skip shared/collaborative trips
      }
      
      // Count this as a private plan
      totalPlans++;
      
      // Parse dates
      final startDate = _parseDate(data['startDate']);
      final endDate = _parseDate(data['endDate']);
      final createdAt = _parseDate(data['createdAt']) ?? _parseDate(data['created_at']);

      // Check if trip/plan is created in 2025 or overlaps with 2025
      bool isIn2025 = false;
      if (startDate != null && endDate != null) {
        // Check if trip overlaps with 2025 (starts before 2026 and ends after 2024)
        isIn2025 = endDate.isAfter(year2025Start.subtract(Duration(days: 1))) && 
                   startDate.isBefore(year2025End.add(Duration(days: 1)));
      } else if (createdAt != null) {
        // Fallback: check creation date
        isIn2025 = createdAt.year == 2025;
      }

      // Count activities
      final activities = data['activities'] as List<dynamic>? ?? [];
      totalActivities += activities.length;
      if (isIn2025) {
        totalActivities2025 += activities.length;
        totalPlans2025++;
      }

      // Count check-ins (locations visited where user actually went) and analyze trip completion
      List<Map<String, dynamic>> locationBasedActivities = [];
      int checkedInActivitiesInTrip = 0;
      
      for (final activity in activities) {
        if (activity is Map<String, dynamic>) {
          final activityType = activity['activityType'] ?? activity['activity_type'] ?? '';
          final isLocationBased = _isLocationBasedActivity(activityType);
          
          if (isLocationBased) {
            locationBasedActivities.add(activity);
            
            // Check if activity is checked-in OR completed
            final isCheckedIn = activity['checkIn'] == true || activity['check_in'] == true;
            final isCompleted = activity['status'] == 'completed';
            
            if (isCheckedIn || isCompleted) {
              checkedInLocations++;
              checkedInActivitiesInTrip++;
              if (isIn2025) {
                checkedInLocations2025++;
              }
            }
          }
        }
      }

      // Check if trip is completed based on check-ins
      // A trip is completed only when ALL location-based activities are checked-in
      bool isTripCompleted = locationBasedActivities.isNotEmpty && 
                           checkedInActivitiesInTrip == locationBasedActivities.length;

      // Categorize trips by completion status (not by date)
      if (startDate != null && endDate != null) {
        // Calculate trip duration in days  
        final duration = endDate.difference(startDate).inDays + 1;
        
        if (isTripCompleted) {
          // Trip is completed (all locations checked in)
          completedTrips++;
          if (isIn2025) {
            completedTrips2025++;
          }
        } else if (startDate.isAfter(now)) {
          upcomingTrips++;
        } else if (endDate.isBefore(now)) {
          // Trip date passed but not all activities checked in - still counts as incomplete
          // Don't count as completed trip
        } else {
          // Trip is ongoing
          ongoingTrips++;
        }

        // Estimate distance based on trip duration (example: 100km per day)
        totalDistance += duration * 100.0;
      }
    }

    return {
      'totalActivities': totalActivities,
      'completedTrips': completedTrips,
      'ongoingTrips': ongoingTrips,
      'upcomingTrips': upcomingTrips,
      'totalPlans': totalPlans,
      'checkedInLocations': checkedInLocations,
      'totalDays': totalDays,
      'totalDistance': totalDistance,
      'totalActivities2025': totalActivities2025,
      'completedTrips2025': completedTrips2025,
      'totalPlans2025': totalPlans2025,
      'checkedInLocations2025': checkedInLocations2025,
      'totalDays2025': totalDays2025,
    };
  }

  /// Check if activity type represents a location that can be visited
  bool _isLocationBasedActivity(String activityType) {
    const locationBasedTypes = {
      'activity',
      'lodging', 
      'restaurant',
      'tour',
      'concert',
      'theater',
      'meeting',
      'parking'
    };
    return locationBasedTypes.contains(activityType);
  }

  /// Calculate statistics from expenses
  Map<String, dynamic> _calculateExpensesStatistics(QuerySnapshot snapshot) {
    double totalExpenses = 0.0;
    Map<String, double> monthlyExpenses = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      final actualAmount = (data['actual_amount'] ?? data['actualAmount'] ?? 0).toDouble();
      totalExpenses += actualAmount;

      // Group by month
      final createdAt = _parseDate(data['created_at'] ?? data['createdAt']);
      if (createdAt != null) {
        final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + actualAmount;
      }
    }

    // Calculate average expense per trip (will be updated when trips data is available)
    double averageExpensePerTrip = 0.0;

    return {
      'totalExpenses': totalExpenses,
      'monthlyExpenses': monthlyExpenses,
      'averageExpensePerTrip': averageExpensePerTrip,
    };
  }

  /// Parse date from various formats
  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    
    try {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.parse(date);
      } else if (date is DateTime) {
        return date;
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    
    return null;
  }

  /// Get statistics once (not real-time)
  Future<UserTravelStats> getUserStatistics() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return UserTravelStats.empty();
    }

    try {
      // Get trips - filter for private trips in processing
      final tripsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('trips')
          .get();

      // Get expenses
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('expenses')
          .get();

      final tripsStats = _calculateTripsStatistics(tripsSnapshot);
      final expensesStats = _calculateExpensesStatistics(expensesSnapshot);

      // Calculate average expense per trip
      final averageExpensePerTrip = tripsStats['completedTrips'] > 0
          ? expensesStats['totalExpenses'] / tripsStats['completedTrips']
          : 0.0;

      return UserTravelStats(
        totalActivities: tripsStats['totalActivities'],
        completedTrips: tripsStats['completedTrips'],
        ongoingTrips: tripsStats['ongoingTrips'],
        upcomingTrips: tripsStats['upcomingTrips'],
        totalPlans: tripsStats['totalPlans'],
        checkedInLocations: tripsStats['checkedInLocations'],
        totalDays: tripsStats['totalDays'],
        totalDistance: tripsStats['totalDistance'],
        totalExpenses: expensesStats['totalExpenses'],
        monthlyExpenses: expensesStats['monthlyExpenses'],
        averageExpensePerTrip: averageExpensePerTrip,
        totalActivities2025: tripsStats['totalActivities2025'],
        completedTrips2025: tripsStats['completedTrips2025'],
        totalPlans2025: tripsStats['totalPlans2025'],
        checkedInLocations2025: tripsStats['checkedInLocations2025'],
        totalDays2025: tripsStats['totalDays2025'],
      );
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return UserTravelStats.empty();
    }
  }

  /// Dispose resources
  void dispose() {
    _tripsSubscription?.cancel();
    _expensesSubscription?.cancel();
    _statsController?.close();
  }
}