import 'dart:async';
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
import '../../Plan/providers/collaboration_provider.dart';
import '../../Core/providers/app_mode_provider.dart';
import '../../Plan/models/trip_model.dart';
import '../../Plan/models/collaboration_models.dart';
import '../../Plan/models/activity_models.dart';
import '../../Expense/providers/expense_provider.dart';
import '../../Core/theme/app_theme.dart';
import '../services/map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _googleMapController;
  late flutter_map.MapController _flutterMapController;
  final Set<Marker> _googleMarkers = {};
  final Set<Polyline> _googlePolylines = {};
  final List<flutter_map.Marker> _flutterMarkers = [];
  final List<flutter_map.Polyline> _flutterPolylines = [];
  int _currentActivityIndex = 0;
  bool _isLoading = false;
  bool _isMapReady = false;

  // Auto refresh timer
  Timer? _autoRefreshTimer;

  // Button scale states
  bool _selectTripPressed = false;
  bool _clearTripPressed = false;
  bool _centerPressed = false;
  bool _checkInPressed = false;
  bool _refreshPressed = false;

  final MapService _mapService = MapService();

  // Local state variables (needed for UI updates)
  TripModel? _selectedTrip;
  SharedTripModel? _selectedSharedTrip;



  @override
  void initState() {
    super.initState();
    // Initialize Flutter Map controller
    _flutterMapController = flutter_map.MapController();
    // Load last selected trip from Firestore
    _loadLastSelectedTrip();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
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
      //
    }
  }

  // Load last selected trip from Firestore on init
  Future<void> _loadLastSelectedTrip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Set loading state immediately to prevent showing fake interface
    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final lastTripId = doc.data()?['lastSelectedTripId'] as String?;

      if (lastTripId != null && mounted) {
        final appMode = Provider.of<AppModeProvider>(context, listen: false);

        if (appMode.isPrivateMode) {
          // Load from private provider
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
          } else {
            // No trip found, clear loading state
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          // Load from collaboration provider
          final provider = Provider.of<CollaborationProvider>(context, listen: false);

          // Initialize provider if trips not loaded yet
          await provider.ensureInitialized();

          // Find trip in collaboration data
          SharedTripModel? trip;
          for (final sharedTrip in provider.mySharedTrips) {
            if (sharedTrip.id == lastTripId) {
              trip = sharedTrip;
              break;
            }
          }

          // Also check shared with me trips
          if (trip == null) {
            for (final sharedTrip in provider.sharedWithMeTrips) {
              if (sharedTrip.id == lastTripId) {
                trip = sharedTrip;
                break;
              }
            }
          }

          if (trip != null && mounted) {
            // Use provider's selectSharedTrip method to ensure consistency across screens
            final provider = Provider.of<CollaborationProvider>(context, listen: false);
            await provider.selectSharedTrip(trip.id!);
            _selectedSharedTrip = provider.selectedSharedTrip;
            _selectedTrip = _selectedSharedTrip?.toTripModel();
            await _loadTripData();
            _startAutoRefreshTimer();
          }

          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // No last trip ID, clear loading state
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading last selected trip: $e');
      // Clear loading state on error
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrips() async {
    final appMode = Provider.of<AppModeProvider>(context, listen: false);

    if (appMode.isPrivateMode) {
      final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
      if (tripProvider.trips.isNotEmpty) {
        _showTripSelectionDialog(tripProvider.trips);
      }
    } else {
      final collabProvider = Provider.of<CollaborationProvider>(context, listen: false);
      final allTrips = [
        ...collabProvider.mySharedTrips.map((t) => t.toTripModel()),
        ...collabProvider.sharedWithMeTrips.map((t) => t.toTripModel()),
      ];

      if (allTrips.isNotEmpty) {
        _showTripSelectionDialog(allTrips);
      }
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
                            'Select Trip',
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
                            onTap: () async {
                              Navigator.of(context).pop();

                              // Check if this is a collaboration trip
                              final appMode = Provider.of<AppModeProvider>(context, listen: false);
                              if (appMode.isPrivateMode) {
                                _selectTrip(trip);
                              } else {
                                // For collaboration trips, use provider's selectSharedTrip method
                                final provider = Provider.of<CollaborationProvider>(context, listen: false);
                                final sharedTrip = provider.mySharedTrips.firstWhere(
                                  (t) => t.id == trip.id,
                                  orElse: () => provider.sharedWithMeTrips.firstWhere(
                                    (t) => t.id == trip.id,
                                  ),
                                );

                                if (sharedTrip.id != null) {
                                  setState(() => _isLoading = true);
                                  await provider.selectSharedTrip(sharedTrip.id!);
                                  _selectedSharedTrip = provider.selectedSharedTrip;
                                  _selectedTrip = _selectedSharedTrip?.toTripModel();
                                  await _loadTripData();
                                  _startAutoRefreshTimer();
                                  setState(() => _isLoading = false);
                                }
                              }
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
      _selectedSharedTrip = null; // Clear shared trip when selecting regular trip
      _googleMarkers.clear();
      _googlePolylines.clear();
      _flutterMarkers.clear();
      _flutterPolylines.clear();
      _isLoading = true;
    });

    // Save selected trip ID to Firestore
    await _saveSelectedTripId(trip.id);

    await _loadTripData();

    // Start auto refresh timer for map data
    _startAutoRefreshTimer();

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No activities have locations')),
        );
      }
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


    // Clear existing markers and polylines first
    _googleMarkers.clear();
    _googlePolylines.clear();
    _flutterMarkers.clear();
    _flutterPolylines.clear();

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

    // Get route for current segment - only if next activity is not checked in
    if (_currentActivityIndex < activities.length - 1 &&
        !activities[_currentActivityIndex + 1].checkIn) {
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

    // Don't call setState here - let the parent method handle the state update
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
        const SnackBar(content: Text('All activities completed')),
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
            onPressed: () async {
              final costText = actualCostController.text.trim();
              if (costText.isNotEmpty) {
                final cost = double.tryParse(costText);
                if (cost != null && cost > 0) {
                  // Cost > 0 is always valid
                  Navigator.pop(context, cost);
                } else if (cost == 0) {
                  // Show confirmation for 0 cost
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Free Activity'),
                      content: const Text('You entered 0 for the actual cost. Are you sure this activity was completely free?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Edit Cost'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Confirm Free'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    Navigator.pop(context, 0.0);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid cost (must be > 0)')),
                  );
                }
              } else {
                // No cost entered - require confirmation
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Free Activity'),
                    content: const Text('No cost entered. Are you sure this activity was completely free?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Enter Cost'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirm Free'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  Navigator.pop(context, 0.0);
                }
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

      var updatedActivity = activity.copyWith(
        checkIn: true,
        budget: updatedBudget,
      );

      bool success;
      if (_selectedSharedTrip != null) {
        // Collaboration mode - update shared trip
        final collabProvider = Provider.of<CollaborationProvider>(
          context,
          listen: false,
        );
        final updatedSharedTrip = _selectedSharedTrip!.copyWith(
          activities: _selectedTrip!.activities.map((a) =>
            a.id == updatedActivity.id ? updatedActivity : a
          ).toList(),
        );
        success = await collabProvider.updateSharedTrip(updatedSharedTrip);
        if (success) {
          _selectedSharedTrip = updatedSharedTrip;
          _selectedTrip = updatedSharedTrip.toTripModel();
        }
      } else {
        // Private mode - update private trip
        final tripProvider = Provider.of<TripPlanningProvider>(
          context,
          listen: false,
        );
        success = await tripProvider.updateActivityInTrip(
          _selectedTrip!.id!,
          updatedActivity,
        );
        if (success) {
          // Update selected trip from provider to reflect changes
          final updatedTrip = tripProvider.getTripById(_selectedTrip!.id!);
          if (updatedTrip != null) {
            _selectedTrip = updatedTrip;
          }
        }
      }

      if (success) {
        // Create expense record for this check-in and get expense ID
        String? createdExpenseId;
        if (!mounted) return;
        
        try {
          final expenseProvider = Provider.of<ExpenseProvider>(
            context,
            listen: false,
          );
          
          // Check if expense already exists for this activity
          if (updatedActivity.expenseInfo.expenseSynced &&
              updatedActivity.expenseInfo.expenseId != null) {
            createdExpenseId = updatedActivity.expenseInfo.expenseId;
          } else if (actualCost > 0) {
            // Create new expense using ExpenseService directly
            final expenseService = expenseProvider.expenseService;
            final expense = await expenseService.createExpenseFromActivity(
              amount: actualCost,
              category: updatedActivity.activityType.value,
              description: updatedActivity.title,
              activityId: updatedActivity.id,
              tripId: _selectedTrip!.id,
            );
            
            createdExpenseId = expense.id;
            
            // Update activity with expense info
            final updatedExpenseInfo = updatedActivity.expenseInfo.copyWith(
              expenseId: createdExpenseId,
              hasExpense: true,
              expenseCategory: updatedActivity.activityType.value,
              expenseSynced: true,
            );

            updatedActivity = updatedActivity.copyWith(
              expenseInfo: updatedExpenseInfo,
            );

            // Save the updated activity with expense info back to provider
            if (_selectedSharedTrip != null) {
              // Update shared trip again with expense info
              final collabProvider = Provider.of<CollaborationProvider>(
                context,
                listen: false,
              );
              final updatedSharedTripWithExpense = _selectedSharedTrip!.copyWith(
                activities: _selectedTrip!.activities.map((a) =>
                  a.id == updatedActivity.id ? updatedActivity : a
                ).toList(),
              );
              await collabProvider.updateSharedTrip(updatedSharedTripWithExpense);
              _selectedSharedTrip = updatedSharedTripWithExpense;
              _selectedTrip = updatedSharedTripWithExpense.toTripModel();
            } else {
              // Private mode
              final tripProvider = Provider.of<TripPlanningProvider>(
                context,
                listen: false,
              );
              await tripProvider.updateActivityInTrip(
                _selectedTrip!.id!,
                updatedActivity,
              );
              // Update selected trip from provider to reflect changes
              final updatedTrip = tripProvider.getTripById(_selectedTrip!.id!);
              if (updatedTrip != null) {
                _selectedTrip = updatedTrip;
              }
            }

          }
        } catch (e) {
          // Continue with check-in even if expense creation fails
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

        if (_currentActivityIndex < updatedActivities.length - 1 &&
            !updatedActivities[_currentActivityIndex + 1].checkIn) {
          await _loadRoute(
            updatedActivities[_currentActivityIndex],
            updatedActivities[_currentActivityIndex + 1],
          );
          // Update marker colors
          _updateMarkers(updatedActivities);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Checked in at ${updatedActivity.title}!'),
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
              content: const Text('🎉 Congratulations! You have completed the trip!'),
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
          content: Text('Check-in error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _centerToCurrentStartingPoint() {
    if (_selectedTrip == null) return;


    final activities = _selectedTrip!.activities
        .where(
          (activity) =>
              activity.location?.latitude != null &&
              activity.location?.longitude != null,
        )
        .toList();

    if (activities.isEmpty || _currentActivityIndex >= activities.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No activities have locations')),
      );
      return;
    }

    final currentStartingActivity = activities[_currentActivityIndex];

    // Center map on current starting point with maximum zoom for clarity
    if (!kIsWeb) {
      if (_googleMapController != null) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Map not ready')));
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
      return 'Trip completed';
    }

    final nextActivity = activities[_currentActivityIndex + 1];
    // If next activity is already checked in, show completion message
    if (nextActivity.checkIn) {
      return 'Trip completed';
    }

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

  bool _canUserCheckIn() {
    // Always allow check-in for private mode
    if (_selectedSharedTrip == null) return true;

    // For collaboration mode, only allow owners to check-in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    return _selectedSharedTrip!.isOwnerUser(user.uid);
  }

  void _startAutoRefreshTimer() {
    // Cancel existing timer
    _autoRefreshTimer?.cancel();

    // Start new timer that refreshes every 10 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted || _selectedTrip == null) {
        timer.cancel();
        return;
      }


      try {
        // For collaboration trips, refresh from service
        if (_selectedSharedTrip != null && _selectedSharedTrip!.id != null) {
          final collabProvider = Provider.of<CollaborationProvider>(context, listen: false);
          final updatedTrip = await collabProvider.collaborationService.getSharedTrip(_selectedSharedTrip!.id!);

          if (updatedTrip != null && mounted) {
            // Update trip data if there are changes
            if (_tripDataChanged(updatedTrip)) {
              _selectedSharedTrip = updatedTrip;
              _selectedTrip = updatedTrip.toTripModel();
              await _loadTripData(); // Reload markers and routes
              debugPrint('✅ Auto-refreshed: Trip data updated');
            }
          }
        }
        // For private trips, we could add similar logic if needed
      } catch (e) {
        debugPrint('❌ Auto-refresh error: $e');
      }
    });

    debugPrint('✅ Auto-refresh timer started (10 second intervals)');
  }

  bool _tripDataChanged(SharedTripModel newTrip) {
    if (_selectedSharedTrip == null) return true;

    // Check if activities have changed (check-in status, etc.)
    if (newTrip.activities.length != _selectedSharedTrip!.activities.length) return true;

    for (int i = 0; i < newTrip.activities.length; i++) {
      if (newTrip.activities[i].checkIn != _selectedSharedTrip!.activities[i].checkIn) {
        return true;
      }
    }

    return false;
  }

  Future<void> _refreshTripData() async {
    if (_selectedSharedTrip == null || _selectedSharedTrip!.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Reload trip data from collaboration provider
      final collabProvider = Provider.of<CollaborationProvider>(context, listen: false);
      final updatedTrip = await collabProvider.collaborationService.getSharedTrip(_selectedSharedTrip!.id!);

      if (updatedTrip != null && mounted) {
        // Update the provider's selected trip
        await collabProvider.selectSharedTrip(_selectedSharedTrip!.id!);
        // Update local state
        _selectedSharedTrip = collabProvider.selectedSharedTrip;
        _selectedTrip = _selectedSharedTrip?.toTripModel();
        // Reload UI data
        await _loadTripData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip data refreshed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh data')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error refreshing data')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
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
                        tooltip: 'Select trip',
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
                    // Refresh button - only show for collaborators (not owners) in collab mode
                    if (_selectedSharedTrip != null && !_canUserCheckIn())
                      GestureDetector(
                        onTapDown: (_) => setState(() => _refreshPressed = true),
                        onTapUp: (_) {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) setState(() => _refreshPressed = false);
                          });
                        },
                        onTapCancel: () => setState(() => _refreshPressed = false),
                        child: AnimatedScale(
                          scale: _refreshPressed ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: FloatingActionButton.small(
                            onPressed: _refreshTripData,
                            backgroundColor: Colors.white,
                        tooltip: 'Refresh data',
                            heroTag: 'refresh_trip',
                            child: const Icon(
                              Icons.refresh,
                              color: AppColors.navyBlue,
                            ),
                          ),
                        ),
                      ),
                    if (_selectedSharedTrip != null && !_canUserCheckIn()) const SizedBox(height: 8),
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
                          // Cancel auto refresh timer
                          _autoRefreshTimer?.cancel();
                          _autoRefreshTimer = null;

                          setState(() {
                            _selectedTrip = null;
                            _selectedSharedTrip = null;
                            _googleMarkers.clear();
                            _googlePolylines.clear();
                            _flutterMarkers.clear();
                            _flutterPolylines.clear();
                          });
                          // Clear saved trip ID from Firestore
                          _saveSelectedTripId(null);
                        },
                          backgroundColor: Colors.white,
                        tooltip: 'Clear selected trip',
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
                          'Starting point',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // "Next destination" label on divider line
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
                          'Next destination',
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
                    margin: EdgeInsets.only(bottom: _canUserCheckIn() ? 16 : 50), // More margin when checkin button is hidden
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
                          tooltip: 'Go to starting point',
                          child: const Icon(
                            Icons.my_location,
                            color: AppColors.navyBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Check-in button - only show for owners in collab mode
                if (_canUserCheckIn())
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
