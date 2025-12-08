import 'package:flutter/foundation.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  
  WeatherData? _currentWeather;
  List<LocationData> _searchResults = [];
  final List<WeatherData> _favoriteWeathers = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  WeatherData? get currentWeather => _currentWeather;
  List<LocationData> get searchResults => _searchResults;
  List<WeatherData> get favoriteWeathers => _favoriteWeathers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load weather for a specific city
  Future<void> loadWeatherByCity(String cityName) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentWeather = await _weatherService.getWeatherByCity(cityName);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load weather by coordinates
  Future<void> loadWeatherByCoordinates(double lat, double lon) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentWeather = await _weatherService.getWeatherByCoordinates(lat, lon);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Search locations
  Future<void> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    
    try {
      _searchResults = await _weatherService.searchLocations(query);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _searchResults = [];
    } finally {
      _setLoading(false);
    }
  }

  // Load current location weather
  Future<void> loadCurrentLocationWeather() async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentWeather = await _weatherService.getCurrentLocationWeather();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Add to favorites
  void addToFavorites(WeatherData weather) {
    if (!_favoriteWeathers.any((w) => 
        w.cityName == weather.cityName && w.country == weather.country)) {
      _favoriteWeathers.add(weather);
      notifyListeners();
    }
  }

  // Remove from favorites
  void removeFromFavorites(WeatherData weather) {
    _favoriteWeathers.removeWhere((w) => 
        w.cityName == weather.cityName && w.country == weather.country);
    notifyListeners();
  }

  // Check if weather is in favorites
  bool isFavorite(WeatherData weather) {
    return _favoriteWeathers.any((w) => 
        w.cityName == weather.cityName && w.country == weather.country);
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}