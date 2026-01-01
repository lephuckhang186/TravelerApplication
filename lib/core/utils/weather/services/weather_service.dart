import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

/// Service for retrieving weather information based on city name or geographic coordinates.
///
/// Integrates with the OpenWeatherMap API and provides search capabilities for
/// locations globally.
class WeatherService {
  static const String _apiKey = '824729decee2bb89c586721174755ae5';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';

  // Get weather by city name
  Future<WeatherData> getWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Không tìm thấy thành phố "$cityName"');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // Get weather by coordinates
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Không thể lấy thông tin thời tiết');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // Search locations by name
  Future<List<LocationData>> searchLocations(String query) async {
    try {
      final url = Uri.parse('$_geoUrl/direct?q=$query&limit=5&appid=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationData.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tìm kiếm địa điểm');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // Get current location weather (placeholder for GPS integration)
  Future<WeatherData> getCurrentLocationWeather() async {
    // For now, return Ho Chi Minh City as default
    // In future, you can integrate with GPS location service
    return getWeatherByCity('Ho Chi Minh City');
  }
}
