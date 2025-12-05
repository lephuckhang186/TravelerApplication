import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  // API Keys - Replace with your own keys for better reliability
  static const String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Get from: https://console.cloud.google.com/

  // Free Routing APIs (no API key needed for basic usage):
  // 1. OSRM (Open Source Routing Machine) - https://router.project-osrm.org/
  // 2. OpenRouteService - Sign up for free API key at: https://openrouteservice.org/dev/#/signup
  // 3. GraphHopper - Free tier available at: https://www.graphhopper.com/
  // 4. HERE Maps - Freemium at: https://developer.here.com/
  // 5. Mapbox - Free tier at: https://account.mapbox.com/

  Future<List<LatLng>?> getDirections(LatLng origin, LatLng destination) async {
    // Try multiple free routing APIs for actual driving directions
    try {
      // Priority 1: OpenRouteService (free, reliable)
      print('Trying OpenRouteService for real driving directions...');
      final orsRoute = await _getOpenRouteServiceDirections(origin, destination);
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

      // Priority 3: Google Directions (if API key available)
      if (_googleApiKey != 'YOUR_GOOGLE_MAPS_API_KEY') {
        print('Trying Google Directions...');
        final googleRoute = await _getGoogleDirections(origin, destination);
        if (googleRoute != null && googleRoute.isNotEmpty) {
          print('Google routing successful: ${googleRoute.length} points');
          return googleRoute;
        }
      }

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

  // Get detailed directions with instructions
  Future<Map<String, dynamic>?> getDetailedDirections(LatLng origin, LatLng destination) async {
    try {
      // Try Google first
      if (_googleApiKey != 'YOUR_GOOGLE_MAPS_API_KEY') {
        final googleResult = await _getGoogleDetailedDirections(origin, destination);
        if (googleResult != null) {
          return googleResult;
        }
      }

      // Fallback to OSRM
      final osrmResult = await _getOSRMDetailedDirections(origin, destination);
      if (osrmResult != null) {
        return osrmResult;
      }
    } catch (e) {
      print('Error getting detailed directions: $e');
    }
    return null;
  }

  // OpenRouteService (Free routing API with generous limits)
  // Sign up at: https://openrouteservice.org/dev/#/signup
  Future<List<LatLng>?> _getOpenRouteServiceDirections(LatLng origin, LatLng destination) async {
    // 🚀 HƯỚNG DẪN LẤY API KEY MIỄN PHÍ:
    // 1. Vào: https://openrouteservice.org/dev/#/signup
    // 2. Đăng ký tài khoản miễn phí
    // 3. Verify email
    // 4. Vào Dashboard > Tokens > Tạo API key
    // 5. Copy API key và thay thế dòng dưới đây

    const String orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImE5NGY4ZmVmOWM4NjQwOTdhMTIzOWE0NDQzMWM4ZWMxIiwiaCI6Im11cm11cjY0In0='; // 🔑 OpenRouteService API Key

    if (orsApiKey == 'YOUR_OPENROUTESERVICE_API_KEY' || orsApiKey.isEmpty) {
      print('❌ OpenRouteService API key chưa được thiết lập');
      print('📝 Hướng dẫn lấy API key miễn phí (2,000 requests/tháng):');
      print('   🌐 Vào: https://openrouteservice.org/dev/#/signup');
      print('   📧 Đăng ký tài khoản miễn phí');
      print('   ✅ Verify email');
      print('   🔑 Vào Dashboard > Tokens > Tạo API key');
      print('   📝 Copy API key và thay thế \'YOUR_OPENROUTESERVICE_API_KEY\'');
      print('   🎯 Thay thế trong: lib/Map/services/map_service.dart dòng 44');
      return null;
    }

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?'
      'api_key=$orsApiKey'
      '&start=${origin.longitude},${origin.latitude}'
      '&end=${destination.longitude},${destination.latitude}'
    );

    try {
      print('Calling OpenRouteService API...');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      print('OpenRouteService Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final geometry = data['features'][0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            print('OpenRouteService Success: Found ${coordinates.length} coordinates');
            return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
          }
        }
      } else {
        print('OpenRouteService API error: ${response.body}');
      }
    } catch (e) {
      print('Error calling OpenRouteService: $e');
    }
    return null;
  }

  // Google Directions API implementation
  Future<List<LatLng>?> _getGoogleDirections(LatLng origin, LatLng destination) async {
    if (_googleApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      // If no API key is set, skip Google Directions
      return null;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}&'
      'destination=${destination.latitude},${destination.longitude}&'
      'mode=driving&' // You can change to walking, bicycling, transit
      'key=$_googleApiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(points);
        }
      }
    } catch (e) {
      print('Error getting Google directions: $e');
    }
    return null;
  }

  // Google detailed directions with steps
  Future<Map<String, dynamic>?> _getGoogleDetailedDirections(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}&'
      'destination=${destination.latitude},${destination.longitude}&'
      'mode=driving&'
      'key=$_googleApiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'];
          final steps = route['legs'][0]['steps'] as List;

          return {
            'polyline': _decodePolyline(polyline),
            'steps': steps.map((step) => {
              'instruction': _stripHtmlTags(step['html_instructions']),
              'distance': step['distance']['text'],
              'duration': step['duration']['text'],
              'start_location': LatLng(
                step['start_location']['lat'],
                step['start_location']['lng']
              ),
              'end_location': LatLng(
                step['end_location']['lat'],
                step['end_location']['lng']
              ),
            }).toList(),
            'total_distance': route['legs'][0]['distance']['text'],
            'total_duration': route['legs'][0]['duration']['text'],
          };
        }
      }
    } catch (e) {
      print('Error getting Google detailed directions: $e');
    }
    return null;
  }

  // OSRM detailed directions
  Future<Map<String, dynamic>?> _getOSRMDetailedDirections(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=true'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          final steps = route['legs'][0]['steps'] as List;

          return {
            'polyline': coordinates.map((coord) => LatLng(coord[1], coord[0])).toList(),
            'steps': steps.map((step) => {
              'instruction': step['maneuver']['modifier'] != null
                ? '${step['maneuver']['type']} ${step['maneuver']['modifier']}'
                : step['maneuver']['type'],
              'distance': '${(step['distance'] / 1000).toStringAsFixed(1)} km',
              'duration': '${(step['duration'] / 60).toStringAsFixed(0)} min',
              'start_location': LatLng(
                step['maneuver']['location'][1],
                step['maneuver']['location'][0]
              ),
              'end_location': LatLng(
                coordinates[coordinates.length - 1][1],
                coordinates[coordinates.length - 1][0]
              ),
            }).toList(),
            'total_distance': '${(route['distance'] / 1000).toStringAsFixed(1)} km',
            'total_duration': '${(route['duration'] / 60).toStringAsFixed(0)} min',
          };
        }
      }
    } catch (e) {
      print('Error getting OSRM detailed directions: $e');
    }
    return null;
  }

  // OSRM (Open Source Routing Machine) implementation for web fallback
  Future<List<LatLng>?> _getOSRMDirections(LatLng origin, LatLng destination) async {
    // Try multiple OSRM servers for better reliability
    final servers = [
      'https://router.project-osrm.org',  // Main OSRM server
      'https://routing.openstreetmap.de', // Alternative server
    ];

    for (final server in servers) {
      final url = Uri.parse(
        '$server/routed-car/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&alternatives=false'
      );

      try {
        print('Trying OSRM server: $server');
        final response = await http.get(url).timeout(const Duration(seconds: 10));

        print('OSRM Response status: ${response.statusCode}');
        print('OSRM Response body: ${response.body.substring(0, min(200, response.body.length))}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
            final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
            print('OSRM Success: Found ${coordinates.length} coordinates');
            return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
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
        '?steps=false&overview=simplified&geometries=geojson'
      );

      print('Trying simplified OSRM endpoint');
      final response = await http.get(simpleUrl).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          print('Simplified OSRM Success: Found ${coordinates.length} coordinates');
          return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
      }
    } catch (e) {
      print('Simplified OSRM also failed: $e');
    }

    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Simulated routing algorithm for demo purposes
  // Creates clear 90-degree turns like real city streets
  List<LatLng> _createSimulatedRoute(LatLng origin, LatLng destination) {
    try {
      print('Creating city street route with 90-degree turns');

      // Create waypoints that form a clear rectangular path
      final waypoints = <LatLng>[];
      final points = <LatLng>[];

      // Calculate distance
      final latDiff = destination.latitude - origin.latitude;
      final lngDiff = destination.longitude - origin.longitude;

      // Create a path that goes: origin -> right -> up -> left -> up -> destination
      // This creates clear 90-degree turns that look like city streets

      waypoints.add(origin);

      // Point 1: Go right/east from origin
      waypoints.add(LatLng(origin.latitude, origin.longitude + lngDiff * 0.3));

      // Point 2: Go up/north
      waypoints.add(LatLng(origin.latitude + latDiff * 0.4, origin.longitude + lngDiff * 0.3));

      // Point 3: Go left/west
      waypoints.add(LatLng(origin.latitude + latDiff * 0.4, origin.longitude + lngDiff * 0.7));

      // Point 4: Go up/north again
      waypoints.add(LatLng(origin.latitude + latDiff * 0.8, origin.longitude + lngDiff * 0.7));

      // Final destination
      waypoints.add(destination);

      // Create smooth lines between waypoints with many points for visibility
      for (int i = 0; i < waypoints.length - 1; i++) {
        final start = waypoints[i];
        final end = waypoints[i + 1];

        // Add many points to make the route clearly visible
        const pointsPerSegment = 25;
        for (int j = 0; j <= pointsPerSegment; j++) {
          final t = j / pointsPerSegment;
          final lat = start.latitude + (end.latitude - start.latitude) * t;
          final lng = start.longitude + (end.longitude - start.longitude) * t;
          points.add(LatLng(lat, lng));
        }
      }

      print('City street route created with ${waypoints.length} turns and ${points.length} points');
      print('Waypoints: ${waypoints.map((p) => '(${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})').join(' -> ')}');

      return points;
    } catch (e) {
      print('Error creating city street route: $e');
      return [origin, destination];
    }
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

  // Helper method to strip HTML tags from instructions
  String _stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>');
    return htmlString.replaceAll(exp, '');
  }
}
