import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/plan_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PlanService _planService = PlanService();
  List<LatLng> _currentRoute = [];
  int _currentLocationIndex = 0;
  final MapController _mapController = MapController();

  void _showPlanSelectionDialog() async {
    final trips = await _planService.getTrips();
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
                    setState(() {
                      _currentRoute = trip.locations;
                    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(10.7769, 106.7009), // Ho Chi Minh City
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          if (_currentRoute.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _currentRoute,
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
                if (_currentRoute.isNotEmpty) {
                  setState(() {
                    _currentLocationIndex =
                        (_currentLocationIndex + 1) % _currentRoute.length;
                  });
                  _mapController.move(
                      _currentRoute[_currentLocationIndex], 15.0);
                }
              },
              heroTag: 'nextLocation',
              child: const Icon(Icons.my_location),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton(
              onPressed: _showPlanSelectionDialog,
              heroTag: 'selectPlan',
              child: const Icon(Icons.navigation),
            ),
          ),
        ],
      ),
    );
  }
}
