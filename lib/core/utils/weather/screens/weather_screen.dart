import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_models.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();
  late WeatherProvider _weatherProvider;

  @override
  void initState() {
    super.initState();
    _weatherProvider = WeatherProvider();
    // Load current location weather on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _weatherProvider.loadCurrentLocationWeather();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _weatherProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Weather',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<WeatherProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Search Bar
                _buildSearchBar(provider),
                
                // Search Results or Weather Display
                Expanded(
                  child: provider.searchResults.isNotEmpty
                      ? _buildSearchResults(provider)
                      : _buildWeatherDisplay(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(WeatherProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          if (value.trim().isNotEmpty) {
            provider.searchLocations(value);
          } else {
            provider.clearSearchResults();
          }
        },
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(
            fontFamily: 'Urbanist-Regular',
            color: Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearchResults();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults(WeatherProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final location = provider.searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blue),
            title: Text(
              location.name,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              location.displayName,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            onTap: () {
              _searchController.clear();
              provider.clearSearchResults();
              provider.loadWeatherByCoordinates(
                location.latitude, 
                location.longitude,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWeatherDisplay(WeatherProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading weather information...'),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 16,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadCurrentLocationWeather(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (provider.currentWeather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for a city to view weather',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return _buildWeatherCard(provider.currentWeather!, provider);
  }

  Widget _buildWeatherCard(WeatherData weather, WeatherProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main Weather Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3),
                  const Color(0xFF1976D2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.cityName,
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weather.country,
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Temperature and Description
                Column(
                  children: [
                    Text(
                      weather.temperatureCelsius,
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weather.description.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Weather Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather Details',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.thermostat,
                        'Feels like',
                        weather.feelsLikeCelsius,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.water_drop,
                        'Humidity',
                        '${weather.humidity}%',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.air,
                        'Wind',
                        '${weather.windSpeed} m/s',
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.speed,
                        'Pressure',
                        '${weather.pressure} hPa',
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}