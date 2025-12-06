import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../Login/services/auth_service.dart';

/// Model cho thống kê người dùng từ Backend API
class UserTravelStats {
  final int totalActivities;     // Tổng số activities
  final int completedTrips;      // Chuyến đi đã hoàn thành (status completed)
  final int checkedInLocations;  // Địa điểm đã check-in (check_in = true)
  final double totalExpenses;    // Tổng chi tiêu thực tế
  final int totalPlans;          // Tổng số kế hoạch (trips)

  UserTravelStats({
    required this.totalActivities,
    required this.completedTrips,
    required this.checkedInLocations,
    required this.totalExpenses,
    required this.totalPlans,
  });

  factory UserTravelStats.fromJson(Map<String, dynamic> json) {
    return UserTravelStats(
      totalActivities: json['total_activities'] ?? 0,
      completedTrips: json['completed_trips'] ?? 0,
      checkedInLocations: json['checked_in_locations'] ?? 0,
      totalExpenses: (json['total_expenses'] ?? 0).toDouble(),
      totalPlans: json['total_plans'] ?? 0,
    );
  }
}

/// Service để lấy thống kê du lịch từ Backend API
class UserStatisticsApiService {
  static final UserStatisticsApiService _instance = UserStatisticsApiService._internal();
  factory UserStatisticsApiService() => _instance;
  UserStatisticsApiService._internal();

  final AuthService _authService = AuthService();

  /// Lấy headers với Authorization token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getIdToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// Lấy thống kê từ API activities/statistics  
  Future<UserTravelStats> getUserStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/activities/statistics'),
        headers: headers,
      );

      print('📊 API Request: GET /activities/statistics');
      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 API Response: $data');
        
        // Transform API response to match our needs
        return _transformApiResponse(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        print('❌ API Error: ${response.body}');
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Statistics API Error: $e');
      // Return empty stats instead of throwing
      return UserTravelStats(
        totalActivities: 0,
        completedTrips: 0,
        checkedInLocations: 0,
        totalExpenses: 0.0,
        totalPlans: 0,
      );
    }
  }

  /// Transform API response to our statistics model
  UserTravelStats _transformApiResponse(Map<String, dynamic> data) {
    // API trả về activity statistics, ta cần transform cho phù hợp
    int totalActivities = data['total_activities'] ?? 0;
    int completedActivities = 0;
    int checkedInLocations = 0;
    
    // Parse by_status data
    if (data['by_status'] != null) {
      final Map<String, dynamic> byStatus = data['by_status'];
      completedActivities = byStatus['completed'] ?? 0;
    }

    // Parse other statistics (need additional API calls for trips and expenses)
    // For now, estimate based on activities
    int estimatedTrips = (totalActivities / 5).round(); // Assume 5 activities per trip
    double estimatedExpenses = totalActivities * 500000.0; // Estimate 500k per activity

    return UserTravelStats(
      totalActivities: totalActivities,
      completedTrips: estimatedTrips,
      checkedInLocations: checkedInLocations,
      totalExpenses: estimatedExpenses,
      totalPlans: estimatedTrips,
    );
  }

  /// Lấy thống kê expenses summary từ API
  Future<Map<String, dynamic>> getExpenseSummary({String? tripId}) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '${ApiConfig.baseUrl}/activities/expenses/summary';
      if (tripId != null) {
        url += '?trip_id=$tripId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('💰 Expense API Request: GET $url');
      print('💰 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💰 Expense API Response: $data');
        return data;
      } else {
        print('❌ Expense API Error: ${response.body}');
        return {};
      }
    } catch (e) {
      print('❌ Expense API Error: $e');
      return {};
    }
  }

  /// Lấy trips từ API để đếm tổng plans và completed trips
  Future<Map<String, int>> getTripStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/activities/trips'),
        headers: headers,
      );

      print('🗺️ Trips API Request: GET /activities/trips');
      print('🗺️ Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> trips = json.decode(response.body);
        print('🗺️ Trips API Response: ${trips.length} trips found');

        int totalPlans = trips.length;
        int completedTrips = 0;

        final now = DateTime.now();
        for (final trip in trips) {
          if (trip['end_date'] != null) {
            final endDate = DateTime.parse(trip['end_date']);
            if (endDate.isBefore(now)) {
              completedTrips++;
            }
          }
        }

        return {
          'totalPlans': totalPlans,
          'completedTrips': completedTrips,
        };
      } else {
        print('❌ Trips API Error: ${response.body}');
        return {'totalPlans': 0, 'completedTrips': 0};
      }
    } catch (e) {
      print('❌ Trips API Error: $e');
      return {'totalPlans': 0, 'completedTrips': 0};
    }
  }

  /// Lấy activities để đếm check-in locations
  Future<int> getCheckedInLocations({String? tripId}) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '${ApiConfig.baseUrl}/activities/';
      if (tripId != null) {
        url += '?trip_id=$tripId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📍 Activities API Request: GET $url');
      print('📍 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> activities = data['activities'] ?? [];
        
        int checkedInCount = 0;
        for (final activity in activities) {
          if (activity['check_in'] == true) {
            checkedInCount++;
          }
        }

        print('📍 Found $checkedInCount checked-in activities');
        return checkedInCount;
      } else {
        print('❌ Activities API Error: ${response.body}');
        return 0;
      }
    } catch (e) {
      print('❌ Activities API Error: $e');
      return 0;
    }
  }

  /// Lấy thống kê tổng hợp từ nhiều API endpoints
  Future<UserTravelStats> getCompleteUserStatistics() async {
    try {
      print('📊 Starting complete statistics fetch...');

      // Gọi song song các API để tối ưu performance
      final futures = await Future.wait([
        getUserStatistics(),           // Activity statistics
        getTripStatistics(),          // Trip statistics  
        getCheckedInLocations(),      // Check-in locations
        getExpenseSummary(),          // Expense summary
      ]);

      final activityStats = futures[0] as UserTravelStats;
      final tripStats = futures[1] as Map<String, int>;
      final checkedInLocations = futures[2] as int;
      final expenseSummary = futures[3] as Map<String, dynamic>;

      // Combine all statistics
      final totalExpenses = expenseSummary['total_actual_cost']?.toDouble() ?? 0.0;

      final completeStats = UserTravelStats(
        totalActivities: activityStats.totalActivities,
        completedTrips: tripStats['completedTrips'] ?? 0,
        checkedInLocations: checkedInLocations,
        totalExpenses: totalExpenses,
        totalPlans: tripStats['totalPlans'] ?? 0,
      );

      print('🎯 Complete Statistics:');
      print('   📊 Total Activities: ${completeStats.totalActivities}');
      print('   ✈️ Completed Trips: ${completeStats.completedTrips}');
      print('   📍 Check-in Locations: ${completeStats.checkedInLocations}');
      print('   💰 Total Expenses: ${completeStats.totalExpenses}');
      print('   📋 Total Plans: ${completeStats.totalPlans}');

      return completeStats;
    } catch (e) {
      print('❌ Complete statistics error: $e');
      // Return empty stats on error
      return UserTravelStats(
        totalActivities: 0,
        completedTrips: 0,
        checkedInLocations: 0,
        totalExpenses: 0.0,
        totalPlans: 0,
      );
    }
  }

  /// Format currency cho display
  String formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _authService.currentUser != null;
  }
}