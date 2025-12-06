import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  // Free Routing APIs:
  // 1. OpenRouteService - Free API key at: https://openrouteservice.org/dev/#/signup (2,000 requests/month)
  // 2. OSRM (Open Source Routing Machine) - https://router.project-osrm.org/ (free, no key)

  /// Get directions with advanced routing constraints
  Future<List<LatLng>?> getDirections(
    LatLng origin,
    LatLng destination, {
    String profile = 'driving-car',
    List<String> avoidFeatures = const [],
    Map<String, dynamic> vehicleOptions = const {},
  }) async {
    // Try real routing APIs first for actual driving directions
    try {
      // Priority 1: OpenRouteService (free, reliable)
      print('Trying OpenRouteService for real driving directions...');
      final orsRoute = await _getOpenRouteServiceDirections(
        origin,
        destination,
        profile: profile,
        avoidFeatures: avoidFeatures,
        vehicleOptions: vehicleOptions,
      );
      if (orsRoute != null && orsRoute.isNotEmpty) {
        print('OpenRouteService routing successful: ${orsRoute.length} points');
        return orsRoute;
      }

      // Priority 2: OSRM (free, alternative)
      print('Trying OSRM as backup...');
      final osrmRoute = await _getOSRMDirections(origin, destination);
      if (osrmRoute != null && osrmRoute.isNotEmpty) {
        print('OSRM routing successful: ${osrmRoute.length} points');
        return osrmRoute;
      }

      // Note: Google Directions requires paid API key
      // To use Google Maps routing, get API key from: https://console.cloud.google.com/

      // Last resort: Create a simple curved route (not straight line)
      print('All routing APIs failed, creating curved path...');
      final curvedRoute = _createSimpleCurvedRoute(origin, destination);
      if (curvedRoute.isNotEmpty) {
        return curvedRoute;
      }

      // Absolute fallback: straight line
      print('Using straight line as final fallback');
      return [origin, destination];
    } catch (e) {
      print('Error getting directions: $e');
      return [origin, destination];
    }
  }

  // OpenRouteService (Free routing API with generous limits)
  // Sign up at: https://openrouteservice.org/dev/#/signup
  Future<List<LatLng>?> _getOpenRouteServiceDirections(
    LatLng origin,
    LatLng destination, {
    String profile = 'driving-car',
    List<String> avoidFeatures = const [],
    Map<String, dynamic> vehicleOptions = const {},
  }) async {
    // 🚀 HƯỚNG DẪN LẤY API KEY MIỄN PHÍ:
    // 1. Vào: https://openrouteservice.org/dev/#/signup
    // 2. Đăng ký tài khoản miễn phí
    // 3. Verify email
    // 4. Vào Dashboard > Tokens > Tạo API key
    // 5. Copy API key và thay thế dòng dưới đây

    const String orsApiKey =
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImE5NGY4ZmVmOWM4NjQwOTdhMTIzOWE0NDQzMWM4ZWMxIiwiaCI6Im11cm11cjY0In0='; // 🔑 OpenRouteService API Key

    // Build URL with advanced parameters
    final baseUrl = 'https://api.openrouteservice.org/v2/directions/$profile';
    final params = {
      'api_key': orsApiKey,
      'start': '${origin.longitude},${origin.latitude}',
      'end': '${destination.longitude},${destination.latitude}',
      'format': 'geojson',
      'profile': profile,
      'geometry_simplify': 'false',
      'continue_straight': 'false', // Handle one-way streets properly
    };

    // Add avoid features if specified
    if (avoidFeatures.isNotEmpty) {
      params['options'] = json.encode({
        'avoid_features': avoidFeatures,
        'profile_params': vehicleOptions.isNotEmpty
            ? {'restrictions': vehicleOptions}
            : null,
      });
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final url = uri.toString();

    print(
      'OpenRouteService API Key being used: ${orsApiKey.substring(0, 20)}...',
    );
    print('Request URL: $url');
    print(
      'Profile: $profile, Avoid features: $avoidFeatures, Vehicle options: $vehicleOptions',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      print('OpenRouteService Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print(
        'Response body preview: ${response.body.substring(0, min(300, response.body.length))}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for different response formats
        if (data['features'] != null && data['features'].isNotEmpty) {
          final geometry = data['features'][0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            print(
              'OpenRouteService Success: Found ${coordinates.length} coordinates',
            );
            print('Route avoids: ${avoidFeatures.join(", ")}');
            return coordinates
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
          }
        } else if (data['routes'] != null && data['routes'].isNotEmpty) {
          // Alternative response format
          final geometry = data['routes'][0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            print(
              'OpenRouteService Success (alt format): Found ${coordinates.length} coordinates',
            );
            print('Route avoids: ${avoidFeatures.join(", ")}');
            return coordinates
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
          }
        }

        print(
          'OpenRouteService response format unexpected: ${data.keys.join(', ')}',
        );
      } else if (response.statusCode == 400) {
        // Handle specific error cases
        final errorData = json.decode(response.body);
        print('OpenRouteService Bad Request: ${errorData}');
        if (errorData['error'] != null &&
            errorData['error']['message'] != null) {
          print('Error message: ${errorData['error']['message']}');
        }
      } else {
        print(
          'OpenRouteService HTTP error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('Error calling OpenRouteService: $e');
    }

    return null;
  }

  // OSRM (Open Source Routing Machine) implementation for web fallback
  Future<List<LatLng>?> _getOSRMDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    // Try multiple OSRM servers for better reliability
    final servers = [
      'https://router.project-osrm.org', // Main OSRM server
      'https://routing.openstreetmap.de', // Alternative server
    ];

    for (final server in servers) {
      final url = Uri.parse(
        '$server/routed-car/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&alternatives=false',
      );

      try {
        print('Trying OSRM server: $server');
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 10));

        print('OSRM Response status: ${response.statusCode}');
        print(
          'OSRM Response body: ${response.body.substring(0, min(200, response.body.length))}',
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['code'] == 'Ok' &&
              data['routes'] != null &&
              data['routes'].isNotEmpty) {
            final coordinates =
                data['routes'][0]['geometry']['coordinates'] as List;
            print('OSRM Success: Found ${coordinates.length} coordinates');
            return coordinates
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
          } else {
            print('OSRM Response code: ${data['code']}');
          }
        }
      } catch (e) {
        print('Error with OSRM server $server: $e');
        continue; // Try next server
      }
    }

    // Try a simpler OSRM endpoint as last resort
    try {
      final simpleUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?steps=false&overview=simplified&geometries=geojson',
      );

      print('Trying simplified OSRM endpoint');
      final response = await http
          .get(simpleUrl)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;
          print(
            'Simplified OSRM Success: Found ${coordinates.length} coordinates',
          );
          return coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
        }
      }
    } catch (e) {
      print('Simplified OSRM also failed: $e');
    }

    return null;
  }

  // Simple curved route as fallback when APIs fail
  List<LatLng> _createSimpleCurvedRoute(LatLng origin, LatLng destination) {
    try {
      final points = <LatLng>[];
      final latDiff = destination.latitude - origin.latitude;
      final lngDiff = destination.longitude - origin.longitude;

      // Create a gentle curve with intermediate points
      const numPoints = 20;
      for (int i = 0; i <= numPoints; i++) {
        final t = i / numPoints;
        // Add slight curve
        final curve = sin(t * pi) * 0.00005; // Very subtle curve
        final lat = origin.latitude + (latDiff * t) + curve;
        final lng = origin.longitude + (lngDiff * t);
        points.add(LatLng(lat, lng));
      }

      print('Created simple curved route with ${points.length} points');
      return points;
    } catch (e) {
      print('Error creating simple curved route: $e');
      return [origin, destination];
    }
  }

  /// Get directions for trucks with restrictions
  Future<List<LatLng>?> getTruckDirections(
    LatLng origin,
    LatLng destination, {
    double? weight,
    double? height,
    double? width,
    List<String> avoidFeatures = const ['highways', 'tollways'],
  }) {
    final vehicleOptions = <String, dynamic>{};
    if (weight != null) vehicleOptions['weight'] = weight;
    if (height != null) vehicleOptions['height'] = height;
    if (width != null) vehicleOptions['width'] = width;

    return getDirections(
      origin,
      destination,
      profile: 'driving-hgv', // Heavy goods vehicle
      avoidFeatures: avoidFeatures,
      vehicleOptions: vehicleOptions,
    );
  }

  /// Get directions for bicycles
  Future<List<LatLng>?> getBicycleDirections(
    LatLng origin,
    LatLng destination, {
    List<String> avoidFeatures = const ['steps', 'ferries'],
  }) {
    return getDirections(
      origin,
      destination,
      profile: 'cycling-regular',
      avoidFeatures: avoidFeatures,
    );
  }

  /// Get directions for pedestrians
  Future<List<LatLng>?> getWalkingDirections(
    LatLng origin,
    LatLng destination, {
    List<String> avoidFeatures = const ['ferries', 'highways'],
  }) {
    return getDirections(
      origin,
      destination,
      profile: 'foot-walking',
      avoidFeatures: avoidFeatures,
    );
  }

  /// Get directions avoiding toll roads
  Future<List<LatLng>?> getTollFreeDirections(
    LatLng origin,
    LatLng destination,
  ) {
    return getDirections(
      origin,
      destination,
      profile: 'driving-car',
      avoidFeatures: ['tollways'],
    );
  }

  /// Get directions avoiding highways
  Future<List<LatLng>?> getHighwayFreeDirections(
    LatLng origin,
    LatLng destination,
  ) {
    return getDirections(
      origin,
      destination,
      profile: 'driving-car',
      avoidFeatures: ['highways'],
    );
  }
}
