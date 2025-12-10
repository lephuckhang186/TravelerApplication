import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_models.dart';
import '../../core/config/api_config.dart';

class WeatherNotificationService {
  Future<List<WeatherAlert>> checkWeatherAlerts(String tripId) async {
    try {
      debugPrint('WeatherNotificationService: Checking weather alerts for trip $tripId');
      return await _fetchFromBackendAPI(tripId);
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
      debugPrint('WeatherNotificationService: Backend API error: $e');
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
      debugPrint('WeatherNotificationService: Error getting current weather alert: $e');
      return null;
    }
  }
}