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
  late flutter_map.MapController _flutterMapController;
  TripModel? _selectedTrip;
  Set<Marker> _googleMarkers = {};
  Set<Polyline> _googlePolylines = {};
  List<flutter_map.Marker> _flutterMarkers = [];
  List<flutter_map.Polyline> _flutterPolylines = [];
  int _currentActivityIndex = 0;
  bool _isLoading = false;
  bool _isMapReady = false;

  final MapService _mapService = MapService();

  @override
  void initState() {
    super.initState();
    // Initialize Flutter Map controller
    _flutterMapController = flutter_map.MapController();
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

    // Find the first unchecked activity
    int firstUncheckedIndex = 0;
    for (int i = 0; i < activities.length; i++) {
      if (!activities[i].checkIn) {
        firstUncheckedIndex = i;
        break;
      }
    }
    _currentActivityIndex = firstUncheckedIndex;

    print('Loaded trip with ${activities.length} activities, current index: $_currentActivityIndex');

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
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)  // Starting point - blue
              : i == _currentActivityIndex + 1
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)   // Next destination - red
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), // Others - yellow
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
                ? Colors.blue       // Starting point - blue
                : i == _currentActivityIndex + 1
                    ? Colors.red    // Next destination - red
                    : Colors.yellow, // Others - yellow
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

    if (_currentActivityIndex >= activities.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn thành tất cả hoạt động')),
      );
      return;
    }

    final currentActivity = activities[_currentActivityIndex];

    // Show dialog to input actual cost (same as Plan screen)
    final result = await _showCheckInCostDialog(currentActivity);

    if (result != null) {
      await _performCheckIn(currentActivity, result, activities);
    }
  }

  Future<double?> _showCheckInCostDialog(ActivityModel activity) async {
    final TextEditingController actualCostController = TextEditingController();
    final expectedCost = activity.budget?.estimatedCost;

    // Pre-fill with expected cost if available
    if (expectedCost != null) {
      actualCostController.text = expectedCost.toStringAsFixed(0);
    }

    return await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check-in: ${activity.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expectedCost != null) ...[
              Text(
                'Expected Cost: ${_formatCurrency(expectedCost)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Enter actual cost:'),
            const SizedBox(height: 8),
            TextField(
              controller: actualCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Actual cost (VND)',
                border: OutlineInputBorder(),
                prefixText: 'VND ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final costText = actualCostController.text.trim();
              if (costText.isNotEmpty) {
                final cost = double.tryParse(costText);
                if (cost != null && cost >= 0) {
                  Navigator.pop(context, cost);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid cost')),
                  );
                }
              } else {
                // Allow check-in without cost
                Navigator.pop(context, 0.0);
              }
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCheckIn(ActivityModel activity, double actualCost, List<ActivityModel> activities) async {
    try {
      // Update activity with actual cost and check-in status
      final updatedBudget = BudgetModel(
        estimatedCost: activity.budget?.estimatedCost ?? actualCost,
        actualCost: actualCost,
        currency: activity.budget?.currency ?? 'VND',
        category: activity.budget?.category,
      );

      final updatedActivity = activity.copyWith(
        checkIn: true,
        budget: updatedBudget,
      );

      final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
      final success = await tripProvider.updateActivityInTrip(_selectedTrip!.id!, updatedActivity);

      if (success) {
        // Update selected trip from provider to reflect changes
        final updatedTrip = tripProvider.getTripById(_selectedTrip!.id!);
        if (updatedTrip != null) {
          _selectedTrip = updatedTrip;
        }

        // Move to next activity
        setState(() {
          _currentActivityIndex++;
          if (!kIsWeb) {
            _googlePolylines.clear();
          } else {
            _flutterPolylines.clear();
          }
        });

        // Get updated activities from the updated trip
        final updatedActivities = _selectedTrip!.activities.where((activity) =>
          activity.location?.latitude != null && activity.location?.longitude != null
        ).toList();

        if (_currentActivityIndex < updatedActivities.length - 1) {
          await _loadRoute(updatedActivities[_currentActivityIndex], updatedActivities[_currentActivityIndex + 1]);
          // Update marker colors
          _updateMarkers(updatedActivities);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã check-in ${updatedActivity.title}!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Trip completed - clear all polylines and update markers
          setState(() {
            if (!kIsWeb) {
              _googlePolylines.clear();
            } else {
              _flutterPolylines.clear();
            }
          });
          _updateMarkers(updatedActivities);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎉 Chúc mừng! Bạn đã hoàn thành chuyến đi!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi check-in: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _centerToCurrentStartingPoint() {
    if (_selectedTrip == null) return;

    // Debug logs
    print('Center to current starting point called');
    print('isMapReady: $_isMapReady');
    print('kIsWeb: $kIsWeb');
    print('Current activity index: $_currentActivityIndex');
    print('Google controller: ${_googleMapController != null}');
    print('Flutter controller: ${_flutterMapController != null}');

    final activities = _selectedTrip!.activities.where((activity) =>
      activity.location?.latitude != null && activity.location?.longitude != null
    ).toList();

    if (activities.isEmpty || _currentActivityIndex >= activities.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có hoạt động nào có vị trí')),
      );
      return;
    }

    final currentStartingActivity = activities[_currentActivityIndex];

    // Center map on current starting point with maximum zoom for clarity
    if (!kIsWeb) {
      if (_googleMapController != null) {
        print('Animating Google Maps camera to current starting point');
        _googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(currentStartingActivity.location!.latitude!, currentStartingActivity.location!.longitude!),
            18, // Maximum zoom for clearest view
          ),
        );
      } else {
        print('Google Maps controller is null!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bản đồ chưa sẵn sàng')),
        );
        return;
      }
    } else {
      if (_flutterMapController != null) {
        print('Moving Flutter Map to current starting point');
        _flutterMapController!.move(
          latlong.LatLng(currentStartingActivity.location!.latitude!, currentStartingActivity.location!.longitude!),
          18, // Maximum zoom for clearest view
        );
      } else {
        print('Flutter Map controller is null!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bản đồ chưa sẵn sàng')),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã về điểm xuất phát: ${_getStartingPointText()}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} VND';
  }

  String _getStartingPointText() {
    if (_selectedTrip == null) return '';

    final activities = _selectedTrip!.activities.where((activity) =>
      activity.location?.latitude != null && activity.location?.longitude != null
    ).toList();

    if (activities.isEmpty || _currentActivityIndex >= activities.length) return '';

    final currentActivity = activities[_currentActivityIndex];
    // Display location name or address instead of activity title
    return currentActivity.location?.name ??
           currentActivity.location?.address ??
           currentActivity.title;
  }

  String _getNextDestinationText() {
    if (_selectedTrip == null) return '';

    final activities = _selectedTrip!.activities.where((activity) =>
      activity.location?.latitude != null && activity.location?.longitude != null
    ).toList();

    if (_currentActivityIndex >= activities.length - 1) {
      return 'Hoàn thành chuyến đi';
    }

    final nextActivity = activities[_currentActivityIndex + 1];
    // Display location name or address instead of activity title
    return nextActivity.location?.name ??
           nextActivity.location?.address ??
           nextActivity.title;
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
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)  // Starting point - blue
              : i == _currentActivityIndex + 1
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)   // Next destination - red
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), // Others - yellow
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
                ? Colors.blue       // Starting point - blue
                : i == _currentActivityIndex + 1
                    ? Colors.red    // Next destination - red
                    : Colors.yellow, // Others - yellow
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
          IconButton(
            icon: const Icon(Icons.list, color: AppColors.navyBlue),
            onPressed: _loadTrips,
            tooltip: 'Chọn chuyến đi',
          ),
          if (_selectedTrip != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.navyBlue),
              onPressed: () => _loadTrips(),
              tooltip: 'Chọn lại chuyến đi',
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
              onMapCreated: (controller) {
                _googleMapController = controller;
                setState(() {
                  _isMapReady = true;
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            )
          else
            flutter_map.FlutterMap(
              mapController: _flutterMapController,
              options: flutter_map.MapOptions(
                initialCenter: latlong.LatLng(10.8231, 106.6297), // Default to Ho Chi Minh City
                initialZoom: 10,
                onMapReady: () {
                  setState(() {
                    _isMapReady = true;
                  });
                },
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
          // Location info overlay
          if (_selectedTrip != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Starting point
                    Row(
                      children: [
                        Icon(Icons.play_circle_fill, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                              text: _getStartingPointText(),
                            ),
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Điểm xuất phát',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Next destination
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                              text: _getNextDestinationText(),
                            ),
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Điểm tiếp theo',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedTrip != null ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Center to first activity button - only show when map is ready
          if (_isMapReady)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.small(
              onPressed: _centerToCurrentStartingPoint,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: AppColors.navyBlue),
                tooltip: 'Về điểm xuất phát',
              ),
            ),
          // Check-in button
          Container(
            margin: const EdgeInsets.only(bottom: 80), // Add margin to avoid navigation bar
            child: FloatingActionButton(
              onPressed: _checkIn,
              backgroundColor: AppColors.skyBlue,
              child: const Icon(Icons.check_circle, color: Colors.white),
              tooltip: 'Check-in',
            ),
          ),
        ],
      ) : null,
    );
  }
}
