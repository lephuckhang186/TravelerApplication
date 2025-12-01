import 'package/latlong2/latlong.dart';

class Trip {
  final String name;
  final List<LatLng> locations;

  Trip({required this.name, required this.locations});
}

class PlanService {
  Future<List<Trip>> getTrips() async {
    // Mock data
    return [
      Trip(
        name: 'Ho Chi Minh City Tour',
        locations: [
          const LatLng(10.7769, 106.7009),
          const LatLng(10.7749, 106.7009),
          const LatLng(10.7749, 106.7029),
          const LatLng(10.7769, 106.7029),
        ],
      ),
      Trip(
        name: 'Da Nang Adventure',
        locations: [
          const LatLng(16.0544, 108.2022),
          const LatLng(16.0524, 108.2022),
          const LatLng(16.0524, 108.2042),
          const LatLng(16.0544, 108.2042),
        ],
      ),
    ];
  }
}
