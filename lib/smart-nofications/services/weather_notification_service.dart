import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_models.dart';
import '../../core/config/api_config.dart';

class WeatherNotificationService {
  Future<List<WeatherAlert>> checkWeatherAlerts(String tripId) async {
    try {
      // First try to connect to the backend API
      final apiAlerts = await _fetchFromBackendAPI(tripId);
      if (apiAlerts.isNotEmpty) {
        return apiAlerts;
      }
      
      // If API fails, fall back to a simple check based on general weather conditions
      return await _getFallbackWeatherAlert();
      
    } catch (e) {
      debugPrint('WeatherNotificationService: Error checking weather alerts: $e');
      return [];
    }
  }

  Future<List<WeatherAlert>> _fetchFromBackendAPI(String tripId) async {
    try {
      // Get auth token from Firebase Auth
      String? authToken;
      try {
        final FirebaseAuth auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          authToken = await auth.currentUser!.getIdToken();
        }
      } catch (authError) {
        debugPrint('WeatherNotificationService: Auth error: $authError');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/weather/alerts/$tripId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        final List<dynamic> alertsJson = jsonDecode(response.body);
        final alerts = alertsJson.map((json) => WeatherAlert.fromJson(json)).toList();
        if (alerts.isNotEmpty) {
          debugPrint('WeatherNotificationService: Found ${alerts.length} weather alerts');
        }
        return alerts;
      } else if (response.statusCode == 403) {
        return [];
      } else if (response.statusCode >= 500) {
        throw Exception('Server error');
      }
      
      return [];
    } catch (e) {
      throw e; // Re-throw to trigger fallback
    }
  }

  Future<List<WeatherAlert>> _getFallbackWeatherAlert() async {
    try {
      // Simple fallback: create a general weather reminder for today
      final now = DateTime.now();
      final hour = now.hour;
      
      // Create a weather reminder during certain conditions
      if (hour >= 6 && hour <= 9) { // Morning weather check
        return [
          WeatherAlert(
            condition: 'general',
            description: 'Hãy kiểm tra thời tiết hôm nay trước khi bắt đầu các hoạt động',
            temperature: 28.0, // Default temperature
            location: 'Khu vực hiện tại',
            alertTime: now,
          )
        ];
      } else if (hour >= 17 && hour <= 19) { // Evening weather check
        return [
          WeatherAlert(
            condition: 'evening',
            description: 'Kiểm tra thời tiết cho hoạt động buổi tối',
            temperature: 26.0,
            location: 'Khu vực hiện tại', 
            alertTime: now,
          )
        ];
      }
      
      return []; // No fallback alert needed at this time
    } catch (e) {
      debugPrint('WeatherNotificationService: Error creating fallback alert: $e');
      return [];
    }
  }

  Future<WeatherAlert?> getCurrentWeatherAlert(String location) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/weather/current-alert'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasAlert'] == true) {
          return WeatherAlert.fromJson(data['alert']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting current weather alert: $e');
      return null;
    }
  }

  bool _shouldAlertForWeather(Map<String, dynamic> weather) {
    final condition = weather['condition']?.toString().toLowerCase() ?? '';
    final temperature = weather['temperature'] ?? 0.0;
    
    // Alert conditions
    final dangerousConditions = ['thunderstorm', 'storm', 'heavy rain', 'snow'];
    final extremeTemperature = temperature > 40 || temperature < 5;
    
    return dangerousConditions.any((c) => condition.contains(c)) || extremeTemperature;
  }
}