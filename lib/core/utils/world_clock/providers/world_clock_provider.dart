import 'package:flutter/foundation.dart';
import '../models/world_clock_models.dart';
import '../services/world_clock_service.dart';
import 'dart:async';

class WorldClockProvider with ChangeNotifier {
  List<WorldClockData> _worldClockData = [];
  List<WorldTimeZone> _favoriteTimeZones = [];
  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _timer;

  List<WorldClockData> get worldClockData => _worldClockData;
  List<WorldTimeZone> get favoriteTimeZones => _favoriteTimeZones;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<WorldClockData> get filteredWorldClockData {
    if (_searchQuery.isEmpty) {
      return _worldClockData;
    }
    
    final filtered = WorldClockService.searchTimeZones(_searchQuery);
    return filtered.map((timeZone) => WorldClockService.getWorldClockData(timeZone)).toList();
  }

  List<WorldClockData> get favoriteWorldClockData {
    return _favoriteTimeZones
        .map((timeZone) => WorldClockService.getWorldClockData(timeZone))
        .toList();
  }

  WorldClockProvider() {
    _initialize();
  }

  void _initialize() {
    _loadWorldClockData();
    _startTimer();
  }

  void _loadWorldClockData() {
    _isLoading = true;
    notifyListeners();

    try {
      _worldClockData = WorldClockService.getAllWorldClockData();
      _loadFavoriteTimeZones();
    } catch (e) {
      //
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadFavoriteTimeZones() {
    // Mặc định thêm một số múi giờ phổ biến vào favorites
    _favoriteTimeZones = [
      WorldClockService.popularTimeZones.firstWhere(
        (tz) => tz.name == 'Hồ Chí Minh City',
      ),
      WorldClockService.popularTimeZones.firstWhere(
        (tz) => tz.name == 'Tokyo',
      ),
      WorldClockService.popularTimeZones.firstWhere(
        (tz) => tz.name == 'New York',
      ),
      WorldClockService.popularTimeZones.firstWhere(
        (tz) => tz.name == 'London',
      ),
    ];
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimes();
    });
  }

  void _updateTimes() {
    _worldClockData = WorldClockService.getAllWorldClockData();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void addToFavorites(WorldTimeZone timeZone) {
    if (!_favoriteTimeZones.any((tz) => tz.timeZone == timeZone.timeZone)) {
      _favoriteTimeZones.add(timeZone);
      notifyListeners();
    }
  }

  void removeFromFavorites(WorldTimeZone timeZone) {
    _favoriteTimeZones.removeWhere((tz) => tz.timeZone == timeZone.timeZone);
    notifyListeners();
  }

  bool isFavorite(WorldTimeZone timeZone) {
    return _favoriteTimeZones.any((tz) => tz.timeZone == timeZone.timeZone);
  }

  void toggleFavorite(WorldTimeZone timeZone) {
    if (isFavorite(timeZone)) {
      removeFromFavorites(timeZone);
    } else {
      addToFavorites(timeZone);
    }
  }

  void refreshData() {
    _loadWorldClockData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}