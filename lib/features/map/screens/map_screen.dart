import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../trip_planning/providers/trip_planning_provider.dart';
import '../../trip_planning/models/activity_models.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Consumer<TripPlanningProvider>(
      builder: (context, provider, child) {
        final currentTrip = provider.currentTrip;
        final activities = currentTrip?.activities ?? [];
        final route = activities
            .where((a) => a.location?.latitude != null && a.location?.longitude != null)
            .map((a) => LatLng(a.location!.latitude!, a.location!.longitude!))
            .toList();

        ActivityModel? nextActivity;
        if (currentTrip != null) {
          nextActivity = currentTrip.activities.firstWhere(
            (a) => a.status == ActivityStatus.planned,
            orElse: () => currentTrip.activities.first,
          );
        }

        return Scaffold(
          body: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: nextActivity?.location != null
                  ? LatLng(nextActivity!.location!.latitude!, nextActivity.location!.longitude!)
                  : const LatLng(10.7769, 106.7009), // Ho Chi Minh City
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    if (nextActivity?.location != null) {
                      _mapController.move(
                        LatLng(nextActivity!.location!.latitude!, nextActivity.location!.longitude!),
                        15.0,
                      );
                    }
                  },
                  heroTag: 'nextLocation',
                  child: const Icon(Icons.my_location),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: FloatingActionButton(
                  onPressed: () => _showPlanSelectionDialog(context),
                  heroTag: 'selectPlan',
                  child: const Icon(Icons.navigation),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlanSelectionDialog(BuildContext context) {
    final provider = Provider.of<TripPlanningProvider>(context, listen: false);
    final trips = provider.trips;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Plan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return ListTile(
                  title: Text(trip.name),
                  onTap: () {
                    provider.setCurrentTrip(trip);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
