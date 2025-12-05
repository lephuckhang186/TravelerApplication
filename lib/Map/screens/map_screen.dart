import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Plan/providers/trip_planning_provider.dart';
import '../../Plan/models/trip_model.dart';
import '../../Plan/models/activity_models.dart';
import '../../core/theme/app_theme.dart';
import '../services/map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _googleMapController;
  flutter_map.MapController? _flutterMapController;
  TripModel? _selectedTrip;
  Set<Marker> _googleMarkers = {};
  Set<Polyline> _googlePolylines = {};
  List<flutter_map.Marker> _flutterMarkers = [];
  List<flutter_map.Polyline> _flutterPolylines = [];
  int _currentActivityIndex = 0;
  bool _isLoading = false;

  final MapService _mapService = MapService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadTrips() async {
    final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
    if (tripProvider.trips.isNotEmpty) {
      _showTripSelectionDialog(tripProvider.trips);
    }
  }

  void _showTripSelectionDialog(List<TripModel> trips) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Chọn chuyến đi',
          style: GoogleFonts.quattrocento(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return ListTile(
                title: Text(trip.name),
                subtitle: Text('${trip.destination} - ${trip.startDate.toString().split(' ')[0]}'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectTrip(trip);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTrip(TripModel trip) async {
    setState(() {
      _selectedTrip = trip;
      _currentActivityIndex = 0;
      _googleMarkers.clear();
      _googlePolylines.clear();
      _flutterMarkers.clear();
      _flutterPolylines.clear();
      _isLoading = true;
    });

    await _loadTripData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTripData() async {
    if (_selectedTrip == null) return;

    final activities = _selectedTrip!.activities.where((activity) =>
      activity.location?.latitude != null && activity.location?.longitude != null
    ).toList();

    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có hoạt động nào có vị trí')),
      );
      return;
    }

    // Add markers for activities
    if (!kIsWeb) {
      // Google Maps markers
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final marker = Marker(
          markerId: MarkerId(activity.id ?? 'activity_$i'),
          position: LatLng(activity.location!.latitude!, activity.location!.longitude!),
          infoWindow: InfoWindow(
            title: activity.title,
            snippet: activity.description ?? '',
          ),
          icon: i == _currentActivityIndex
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
              : BitmapDescriptor.defaultMarker,
        );
        _googleMarkers.add(marker);
      }
    } else {
      // Flutter Map markers
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final marker = flutter_map.Marker(
          point: latlong.LatLng(activity.location!.latitude!, activity.location!.longitude!),
          child: Icon(
            Icons.location_on,
            color: i == _currentActivityIndex
                ? Colors.blue
                : i < _currentActivityIndex
                    ? Colors.green
                    : Colors.red,
            size: 40,
          ),
        );
        _flutterMarkers.add(marker);
      }
    }

    // Get route for current segment
    if (_currentActivityIndex < activities.length - 1) {
      await _loadRoute(activities[_currentActivityIndex], activities[_currentActivityIndex + 1]);
    }

    // Center map on first activity
    if (activities.isNotEmpty) {
      if (!kIsWeb) {
        _googleMapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(activities[0].location!.latitude!, activities[0].location!.longitude!),
            12,
          ),
        );
      } else {
        _flutterMapController?.move(
          latlong.LatLng(activities[0].location!.latitude!, activities[0].location!.longitude!),
          12,
        );
      }
    }

    setState(() {});
  }

  Future<void> _loadRoute(ActivityModel from, ActivityModel to) async {
    if (from.location?.latitude == null || from.location?.longitude == null ||
        to.location?.latitude == null || to.location?.longitude == null) {
      return;
    }

    final route = await _mapService.getDirections(
      LatLng(from.location!.latitude!, from.location!.longitude!),
      LatLng(to.location!.latitude!, to.location!.longitude!),
    );

    if (route != null) {
      if (!kIsWeb) {
        _googlePolylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: route,
            color: Colors.blue,
            width: 5,
          ),
        );
      } else {
        final flutterPoints = route.map((point) =>
          latlong.LatLng(point.latitude, point.longitude)
        ).toList();
        _flutterPolylines.add(
          flutter_map.Polyline(
            points: flutterPoints,
            color: Colors.blue,
            strokeWidth: 5,
          ),
        );
      }
    }
  }

  void _checkIn() async {
    if (_selectedTrip == null) return;

    final activities = _selectedTrip!.activities.where((activity) =>
      activity.location?.latitude != null && activity.location?.longitude != null
    ).toList();

    if (_currentActivityIndex >= activities.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn thành tất cả hoạt động')),
      );
      return;
    }

    // Mark current activity as checked in
    final updatedActivity = activities[_currentActivityIndex].copyWith(checkIn: true);

    final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
    final success = await tripProvider.updateActivityInTrip(_selectedTrip!.id!, updatedActivity);

    if (success) {
      // Move to next activity
      setState(() {
        _currentActivityIndex++;
        if (!kIsWeb) {
          _googlePolylines.clear();
        } else {
          _flutterPolylines.clear();
        }
      });

      if (_currentActivityIndex < activities.length - 1) {
        await _loadRoute(activities[_currentActivityIndex], activities[_currentActivityIndex + 1]);
        // Update marker colors
        _updateMarkers(activities);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã check-in ${updatedActivity.title}')),
      );
    }
  }

  void _updateMarkers(List<ActivityModel> activities) {
    if (!kIsWeb) {
      _googleMarkers.clear();
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final marker = Marker(
          markerId: MarkerId(activity.id ?? 'activity_$i'),
          position: LatLng(activity.location!.latitude!, activity.location!.longitude!),
          infoWindow: InfoWindow(
            title: activity.title,
            snippet: activity.description ?? '',
          ),
          icon: i == _currentActivityIndex
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
              : i < _currentActivityIndex
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                  : BitmapDescriptor.defaultMarker,
        );
        _googleMarkers.add(marker);
      }
    } else {
      _flutterMarkers.clear();
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final marker = flutter_map.Marker(
          point: latlong.LatLng(activity.location!.latitude!, activity.location!.longitude!),
          child: Icon(
            Icons.location_on,
            color: i == _currentActivityIndex
                ? Colors.blue
                : i < _currentActivityIndex
                    ? Colors.green
                    : Colors.red,
            size: 40,
          ),
        );
        _flutterMarkers.add(marker);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bản đồ',
          style: GoogleFonts.quattrocento(
            color: AppColors.navyBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedTrip != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.navyBlue),
              onPressed: () => _loadTrips(),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!kIsWeb)
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(10.8231, 106.6297), // Default to Ho Chi Minh City
                zoom: 10,
              ),
              markers: _googleMarkers,
              polylines: _googlePolylines,
              onMapCreated: (controller) => _googleMapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            )
          else
            flutter_map.FlutterMap(
              mapController: _flutterMapController,
              options: flutter_map.MapOptions(
                initialCenter: latlong.LatLng(10.8231, 106.6297), // Default to Ho Chi Minh City
                initialZoom: 10,
              ),
              children: [
                flutter_map.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                ),
                flutter_map.MarkerLayer(markers: _flutterMarkers),
                flutter_map.PolylineLayer(polylines: _flutterPolylines),
              ],
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_selectedTrip == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Chọn chuyến đi để xem bản đồ',
                    style: GoogleFonts.quattrocento(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTrips,
                    child: const Text('Chọn chuyến đi'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedTrip != null ? FloatingActionButton(
        onPressed: _checkIn,
        backgroundColor: AppColors.skyBlue,
        child: const Icon(Icons.check_circle, color: Colors.white),
      ) : null,
    );
  }
}
