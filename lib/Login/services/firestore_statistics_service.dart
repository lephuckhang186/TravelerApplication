import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Login/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Model cho thống kê người dùng real-time từ Firestore
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

/// Service để lấy thống kê thời gian thực từ Firestore
class FirestoreStatisticsService {
  static final FirestoreStatisticsService _instance = FirestoreStatisticsService._internal();
  factory FirestoreStatisticsService() => _instance;
  FirestoreStatisticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  StreamController<UserTravelStats>? _statsController;
  StreamSubscription<QuerySnapshot>? _tripsSubscription;
  StreamSubscription<QuerySnapshot>? _expensesSubscription;

  /// Lấy stream thống kê thời gian thực
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

  /// Lắng nghe thay đổi của trips và expenses
  void _listenToTripsAndExpenses(String userId) {
    UserTravelStats currentStats = UserTravelStats.empty();
    bool tripsLoaded = false;
    bool expensesLoaded = false;

    // Listen to trips changes
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
      if (expensesLoaded) {
        _statsController?.add(currentStats);
      }
    });

    // Listen to expenses changes
    _expensesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .snapshots()
        .listen((expensesSnapshot) {
      final expensesStats = _calculateExpensesStatistics(expensesSnapshot);
      currentStats = currentStats.copyWith(
        totalExpenses: expensesStats['totalExpenses'],
        monthlyExpenses: expensesStats['monthlyExpenses'],
        averageExpensePerTrip: expensesStats['averageExpensePerTrip'],
      );
      
      expensesLoaded = true;
      if (tripsLoaded) {
        _statsController?.add(currentStats);
      }
    });
  }

  /// Tính toán thống kê từ trips
  Map<String, dynamic> _calculateTripsStatistics(QuerySnapshot snapshot) {
    int totalActivities = 0;
    int completedTrips = 0;
    int ongoingTrips = 0;
    int upcomingTrips = 0;
    int totalPlans = snapshot.docs.length;
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

      // Count check-ins (locations visited where user actually went)
      for (final activity in activities) {
        if (activity is Map) {
          // Check if activity is checked-in OR completed
          final isCheckedIn = activity['checkIn'] == true || activity['check_in'] == true;
          final isCompleted = activity['status'] == 'completed';
          
          // Filter by location-based activity types
          final activityType = activity['activityType'] ?? activity['activity_type'] ?? '';
          final isLocationBased = _isLocationBasedActivity(activityType);
          
          if ((isCheckedIn || isCompleted) && isLocationBased) {
            checkedInLocations++;
            if (isIn2025) {
              checkedInLocations2025++;
            }
          }
        }
      }

      // Categorize trips by date and calculate total days
      if (startDate != null && endDate != null) {
        // Calculate trip duration in days
        final duration = endDate.difference(startDate).inDays + 1;
        
        if (endDate.isBefore(now)) {
          // Trip is completed
          completedTrips++;
          totalDays += duration; // Only count days for completed trips
          if (isIn2025) {
            completedTrips2025++;
            totalDays2025 += duration;
          }
        } else if (startDate.isAfter(now)) {
          upcomingTrips++;
        } else {
          // Trip is ongoing
          ongoingTrips++;
          // For ongoing trips, count days from start to now
          final daysElapsed = now.difference(startDate).inDays + 1;
          totalDays += daysElapsed;
          if (isIn2025) {
            totalDays2025 += daysElapsed;
          }
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

  /// Tính toán thống kê từ expenses
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

  /// Parse date từ nhiều format khác nhau
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

  /// Lấy thống kê một lần (không real-time)
  Future<UserTravelStats> getUserStatistics() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return UserTravelStats.empty();
    }

    try {
      // Get trips
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