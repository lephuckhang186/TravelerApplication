import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final Set<Marker> _googleMarkers = {};
  final Set<Polyline> _googlePolylines = {};
  final List<flutter_map.Marker> _flutterMarkers = [];
  final List<flutter_map.Polyline> _flutterPolylines = [];
  int _currentActivityIndex = 0;
  bool _isLoading = false;
  bool _isMapReady = false;

  // Button scale states
  bool _selectTripPressed = false;
  bool _clearTripPressed = false;
  bool _centerPressed = false;
  bool _checkInPressed = false;

  final MapService _mapService = MapService();

  @override
  void initState() {
    super.initState();
    // Initialize Flutter Map controller
    _flutterMapController = flutter_map.MapController();
    // Load last selected trip from Firestore
    _loadLastSelectedTrip();
  }

  // Save selected trip ID to Firestore
  Future<void> _saveSelectedTripId(String? tripId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'lastSelectedTripId': tripId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving selected trip ID: $e');
    }
  }

  // Load last selected trip from Firestore on init
  Future<void> _loadLastSelectedTrip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final lastTripId = doc.data()?['lastSelectedTripId'] as String?;
      
      if (lastTripId != null && mounted) {
        // Load trips and find the one with matching ID
        final provider = Provider.of<TripPlanningProvider>(context, listen: false);
        
        // Initialize provider if trips not loaded yet
        if (provider.trips.isEmpty) {
          await provider.initialize();
        }
        
        final trips = provider.trips;
        final trip = trips.cast<TripModel?>().firstWhere(
          (t) => t?.id == lastTripId,
          orElse: () => null,
        );
        
        if (trip != null && mounted) {
          _selectTrip(trip);
        }
      }
    } catch (e) {
      debugPrint('Error loading last selected trip: $e');
    }
  }

  Future<void> _loadTrips() async {
    final tripProvider = Provider.of<TripPlanningProvider>(
      context,
      listen: false,
    );
    if (tripProvider.trips.isNotEmpty) {
      _showTripSelectionDialog(tripProvider.trips);
    }
  }

  void _showTripSelectionDialog(List<TripModel> trips) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 160, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimateGradient(
            duration: const Duration(seconds: 5),
            primaryColors: const [
              AppColors.surface,
              AppColors.steelBlue,
              AppColors.surface,
            ],
            secondaryColors: const [
              AppColors.steelBlue,
              AppColors.surface,
              AppColors.steelBlue,
            ],
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chọn chuyến đi',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Trip list with constrained height (shows ~3.5 cards)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              trip.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${trip.destination} - ${trip.startDate.toString().split(' ')[0]}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _selectTrip(trip);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
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

    // Save selected trip ID to Firestore
    await _saveSelectedTripId(trip.id);

    await _loadTripData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTripData() async {
    if (_selectedTrip == null) return;

    final activities = _selectedTrip!.activities
        .where(
          (activity) =>
              activity.location?.latitude != null &&
              activity.location?.longitude != null,
        )
        .toList();

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

    debugPrint(
      'Loaded trip with ${activities.length} activities, current index: $_currentActivityIndex',
    );

    // Add markers for activities
    if (!kIsWeb) {
      // Google Maps markers
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final marker = Marker(
          markerId: MarkerId(activity.id ?? 'activity_$i'),
          position: LatLng(
            activity.location!.latitude!,
            activity.location!.longitude!,
          ),
          infoWindow: InfoWindow(
            title: activity.title,
            snippet: activity.description ?? '',
          ),
          icon: i == _currentActivityIndex
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ) // Starting point - blue
              : i == _currentActivityIndex + 1
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ) // Next destination - red
              : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow,
                ), // Others - yellow
        );
        _googleMarkers.add(marker);
      }
    } else {
      // Flutter Map markers
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final marker = flutter_map.Marker(
          point: latlong.LatLng(
            activity.location!.latitude!,
            activity.location!.longitude!,
          ),
          child: Icon(
            Icons.location_on,
            color: i == _currentActivityIndex
                ? Colors
                      .blue // Starting point - blue
                : i == _currentActivityIndex + 1
                ? Colors
                      .red // Next destination - red
                : Colors.yellow, // Others - yellow
            size: 40,
          ),
        );
        _flutterMarkers.add(marker);
      }
    }

    // Get route for current segment
    if (_currentActivityIndex < activities.length - 1) {
      await _loadRoute(
        activities[_currentActivityIndex],
        activities[_currentActivityIndex + 1],
      );
    }

    // Center map on first activity
    if (activities.isNotEmpty) {
      if (!kIsWeb) {
        _googleMapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              activities[0].location!.latitude!,
              activities[0].location!.longitude!,
            ),
            12,
          ),
        );
      } else {
        _flutterMapController.move(
          latlong.LatLng(
            activities[0].location!.latitude!,
            activities[0].location!.longitude!,
          ),
          12,
        );
      }
    }

    setState(() {});
  }

  Future<void> _loadRoute(ActivityModel from, ActivityModel to) async {
    if (from.location?.latitude == null ||
        from.location?.longitude == null ||
        to.location?.latitude == null ||
        to.location?.longitude == null) {
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
        final flutterPoints = route
            .map((point) => latlong.LatLng(point.latitude, point.longitude))
            .toList();
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

    final activities = _selectedTrip!.activities
        .where(
          (activity) =>
              activity.location?.latitude != null &&
              activity.location?.longitude != null,
        )
        .toList();

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

  Future<void> _performCheckIn(
    ActivityModel activity,
    double actualCost,
    List<ActivityModel> activities,
  ) async {
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

      final tripProvider = Provider.of<TripPlanningProvider>(
        context,
        listen: false,
      );
      final success = await tripProvider.updateActivityInTrip(
        _selectedTrip!.id!,
        updatedActivity,
      );

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
        final updatedActivities = _selectedTrip!.activities
            .where(
              (activity) =>
                  activity.location?.latitude != null &&
                  activity.location?.longitude != null,
            )
            .toList();

        if (_currentActivityIndex < updatedActivities.length - 1) {
          await _loadRoute(
            updatedActivities[_currentActivityIndex],
            updatedActivities[_currentActivityIndex + 1],
          );
          // Update marker colors
          _updateMarkers(updatedActivities);

          if (!mounted) return;
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

          if (!mounted) return;
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
      if (!mounted) return;
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
    debugPrint('Center to current starting point called');
    debugPrint('isMapReady: $_isMapReady');
    debugPrint('kIsWeb: $kIsWeb');
    debugPrint('Current activity index: $_currentActivityIndex');
    debugPrint('Google controller: ${_googleMapController != null}');

    final activities = _selectedTrip!.activities
        .where(
          (activity) =>
              activity.location?.latitude != null &&
              activity.location?.longitude != null,
        )
        .toList();

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
        debugPrint('Animating Google Maps camera to current starting point');
        _googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              currentStartingActivity.location!.latitude!,
              currentStartingActivity.location!.longitude!,
            ),
            19, // High zoom level (120% more detailed)
          ),
        );
      } else {
        debugPrint('Google Maps controller is null!');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bản đồ chưa sẵn sàng')));
        return;
      }
    } else {
      // For web (Flutter Map)
      _flutterMapController.move(
        latlong.LatLng(
          currentStartingActivity.location!.latitude!,
          currentStartingActivity.location!.longitude!,
        ),
        19, // High zoom level (120% more detailed)
      );
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} VND';
  }

  String _getStartingPointText() {
    if (_selectedTrip == null) return '';

    final activities = _selectedTrip!.activities
        .where(
          (activity) =>
              activity.location?.latitude != null &&
              activity.location?.longitude != null,
        )
        .toList();

    if (activities.isEmpty || _currentActivityIndex >= activities.length) {
      return '';
    }

    final currentActivity = activities[_currentActivityIndex];
    // Display location name or address instead of activity title
    return currentActivity.location?.name ??
        currentActivity.location?.address ??
        currentActivity.title;
  }

  String _getNextDestinationText() {
    if (_selectedTrip == null) return '';

    final activities = _selectedTrip!.activities
        .where(
          (activity) =>
              activity.location?.latitude != null &&
              activity.location?.longitude != null,
        )
        .toList();

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
          position: LatLng(
            activity.location!.latitude!,
            activity.location!.longitude!,
          ),
          infoWindow: InfoWindow(
            title: activity.title,
            snippet: activity.description ?? '',
          ),
          icon: i == _currentActivityIndex
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ) // Starting point - blue
              : i == _currentActivityIndex + 1
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ) // Next destination - red
              : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow,
                ), // Others - yellow
        );
        _googleMarkers.add(marker);
      }
    } else {
      _flutterMarkers.clear();
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final marker = flutter_map.Marker(
          point: latlong.LatLng(
            activity.location!.latitude!,
            activity.location!.longitude!,
          ),
          child: Icon(
            Icons.location_on,
            color: i == _currentActivityIndex
                ? Colors
                      .blue // Starting point - blue
                : i == _currentActivityIndex + 1
                ? Colors
                      .red // Next destination - red
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
      body: Stack(
        children: [
          if (!kIsWeb)
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  10.8231,
                  106.6297,
                ), // Default to Ho Chi Minh City
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
                initialCenter: latlong.LatLng(
                  10.8231,
                  106.6297,
                ), // Default to Ho Chi Minh City
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          // Trip selection buttons at top right
          Positioned(
            right: 16,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTapDown: (_) => setState(() => _selectTripPressed = true),
                    onTapUp: (_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) setState(() => _selectTripPressed = false);
                      });
                    },
                    onTapCancel: () =>
                        setState(() => _selectTripPressed = false),
                    child: AnimatedScale(
                      scale: _selectTripPressed ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: FloatingActionButton.small(
                        onPressed: _loadTrips,
                        backgroundColor: Colors.white,
                        tooltip: 'Chọn chuyến đi',
                        heroTag: 'select_trip',
                        child: const Icon(
                          Icons.list,
                          color: AppColors.navyBlue,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedTrip != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTapDown: (_) =>
                          setState(() => _clearTripPressed = true),
                      onTapUp: (_) {
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            setState(() => _clearTripPressed = false);
                          }
                        });
                      },
                      onTapCancel: () =>
                          setState(() => _clearTripPressed = false),
                      child: AnimatedScale(
                        scale: _clearTripPressed ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: FloatingActionButton.small(
                          onPressed: () {
                            setState(() {
                              _selectedTrip = null;
                              _googleMarkers.clear();
                              _googlePolylines.clear();
                              _flutterMarkers.clear();
                              _flutterPolylines.clear();
                            });
                            // Clear saved trip ID from Firestore
                            _saveSelectedTripId(null);
                          },
                          backgroundColor: Colors.white,
                          tooltip: 'Bỏ chọn chuyến đi',
                          heroTag: 'clear_trip',
                          child: const Icon(
                            Icons.close,
                            color: AppColors.navyBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Location info overlay
          if (_selectedTrip != null)
            Positioned(
              left: 16,
              right: 70,
              child: SafeArea(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 88,
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 13,
                        bottom: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Starting point content (without label)
                          Row(
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getStartingPointText(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Divider
                          Divider(
                            color: Colors.black.withValues(alpha: 0.3),
                            thickness: 1,
                            height: 1,
                          ),
                          // Next destination content (without label)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getNextDestinationText(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // "Điểm xuất phát" label on top border
                    Positioned(
                      top: -8,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Điểm xuất phát',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // "Điểm tiếp theo" label on divider line
                    Positioned(
                      top: 37,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Điểm tiếp theo',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedTrip != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Center to first activity button - only show when map is ready
                if (_isMapReady)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _centerPressed = true),
                      onTapUp: (_) {
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) setState(() => _centerPressed = false);
                        });
                      },
                      onTapCancel: () => setState(() => _centerPressed = false),
                      child: AnimatedScale(
                        scale: _centerPressed ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: FloatingActionButton.small(
                          onPressed: _centerToCurrentStartingPoint,
                          backgroundColor: Colors.white,
                          tooltip: 'Về điểm xuất phát',
                          child: const Icon(
                            Icons.my_location,
                            color: AppColors.navyBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Check-in button
                Container(
                  margin: const EdgeInsets.only(
                    bottom: 50,
                  ), // Add margin to avoid navigation bar
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _checkInPressed = true),
                    onTapUp: (_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) setState(() => _checkInPressed = false);
                      });
                    },
                    onTapCancel: () => setState(() => _checkInPressed = false),
                    child: AnimatedScale(
                      scale: _checkInPressed ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AnimateGradient(
                          duration: const Duration(seconds: 5),
                          primaryColors: [
                            AppColors.dodgerBlue.withValues(alpha: 0.9),
                            AppColors.steelBlue.withValues(alpha: 0.8),
                            AppColors.skyBlue.withValues(alpha: 0.7),
                          ],
                          secondaryColors: [
                            AppColors.skyBlue.withValues(alpha: 0.7),
                            AppColors.dodgerBlue.withValues(alpha: 0.9),
                            AppColors.steelBlue.withValues(alpha: 0.8),
                          ],
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _checkIn,
                              child: Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
