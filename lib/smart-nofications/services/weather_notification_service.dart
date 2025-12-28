import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_models.dart';
import '../../Core/config/api_config.dart';

class WeatherNotificationService {
  Future<List<WeatherAlert>> checkWeatherAlerts(String tripId) async {
    try {
      return await _fetchFromBackendAPI(tripId);
    } catch (e) {
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
        //
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
          //
        }
        return alerts;
      } else if (response.statusCode == 403) {
        return [];
      } else if (response.statusCode >= 500) {
        throw Exception('Server error');
      }
      
      return [];
    } catch (e) {
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
      return null;
    }
  }
}