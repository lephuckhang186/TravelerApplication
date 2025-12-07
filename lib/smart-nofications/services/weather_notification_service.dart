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
      debugPrint('WeatherNotificationService: API URL: ${ApiConfig.baseUrl}/weather/alerts/$tripId');
      
      // Get auth token from Firebase Auth
      String? authToken;
      try {
        final FirebaseAuth auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          authToken = await auth.currentUser!.getIdToken();
          debugPrint('WeatherNotificationService: Got auth token');
        }
      } catch (authError) {
        debugPrint('WeatherNotificationService: Auth error: $authError');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };
      
      debugPrint('WeatherNotificationService: Headers: ${headers.keys.toList()}');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/weather/alerts/$tripId'),
        headers: headers,
      );

      debugPrint('WeatherNotificationService: Response status: ${response.statusCode}');
      debugPrint('WeatherNotificationService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> alertsJson = jsonDecode(response.body);
        final alerts = alertsJson.map((json) => WeatherAlert.fromJson(json)).toList();
        debugPrint('WeatherNotificationService: Found ${alerts.length} weather alerts');
        return alerts;
      } else if (response.statusCode == 403) {
        debugPrint('WeatherNotificationService: 403 Forbidden - Auth required');
        return [];
      }
      
      debugPrint('WeatherNotificationService: No alerts found or error response');
      return [];
    } catch (e) {
      debugPrint('WeatherNotificationService: Error checking weather alerts: $e');
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