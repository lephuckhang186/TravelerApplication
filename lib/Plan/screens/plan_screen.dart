import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/theme/app_theme.dart';
import 'create_planner_screen.dart';
import 'planner_detail_screen.dart';
import '../models/trip_model.dart';
import '../providers/trip_planning_provider.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with AutomaticKeepAliveClientMixin {
  // 🎯 Đã loại bỏ List<TripModel> _trips và bool _isLoading
  // 🎯 Đã loại bỏ TripPlanningService _tripService và TripStorageService _storageService

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🎯 Sửa: Thay thế getter _visibleTrips bằng một hàm nhận vào danh sách trips từ Provider
  List<TripModel> _getVisibleTrips(List<TripModel> allTrips) {
    if (_searchQuery.isEmpty) {
      debugPrint(
        'DEBUG: No search query, returning all ${allTrips.length} trips',
      );
      return allTrips;
    }
    final query = _searchQuery.toLowerCase();
    final filtered = allTrips.where((trip) {
      final nameMatch = trip.name.toLowerCase().contains(query);
      final destinationMatch = trip.destination.toLowerCase().contains(query);
      final descriptionMatch = (trip.description ?? '').toLowerCase().contains(
        query,
      );
      return nameMatch || destinationMatch || descriptionMatch;
    }).toList();
    debugPrint(
      'DEBUG: Search query "$_searchQuery" filtered ${allTrips.length} trips to ${filtered.length}',
    );
    return filtered;
  }

  @override
  bool get wantKeepAlive => true; // Thay đổi thành true để giữ trạng thái màn hình

  @override
  void initState() {
    super.initState();

    // 🎯 Sửa: Gọi initialize() của Provider trong initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripPlanningProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🎯 Đã loại bỏ hàm _loadTrips() thủ công

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tripProvider = context.watch<TripPlanningProvider>();
    final allTrips = tripProvider.trips;
    final isLoading = tripProvider.isLoading;
    final visibleTrips = _getVisibleTrips(allTrips);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header matching plan.png design
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A9EFF), // Light blue
                  Color(0xFF2196F3), // Medium blue
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and subtitle
                    const Text(
                      'Plan Your Trip',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Urbanist-Regular',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Discover amazing destinations and plan your journey',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Urbanist-Regular',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontFamily: 'Urbanist-Regular',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search your trips...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontFamily: 'Urbanist-Regular',
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 15, right: 10),
                            child: Icon(
                              Icons.search,
                              color: Colors.grey[500],
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[500],
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Trip Cards List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleTrips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.travel_explore,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No trips yet'
                                : 'No trips found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Create your first trip to get started!'
                                : 'Try adjusting your search terms',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 20),
                      itemCount: visibleTrips.length,
                      itemBuilder: (context, index) {
                        final trip = visibleTrips[index];
                        return _buildTripCard(trip, index);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => _showCreateTripModal(context),
          backgroundColor: const Color(0xFF2196F3),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildTripCard(TripModel trip, int index) {
    // Calculate status based on dates
    String status;
    final now = DateTime.now();
    if (trip.startDate.isAfter(now)) {
      status = 'Upcoming';
    } else if (trip.endDate.isBefore(now)) {
      status = 'Completed';
    } else {
      status = 'In Progress';
    }

    // Format date range
    final dateRange =
        '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year} - ${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _navigateToTripDetail(trip),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Trip Icon/Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9EFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: trip.coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            trip.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.travel_explore,
                                color: Colors.white,
                                size: 28,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.travel_explore,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Trip Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Urbanist-Regular',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Urbanist-Regular',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status == 'In Progress' 
                                ? Colors.green 
                                : status == 'Upcoming' 
                                  ? Colors.orange 
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Urbanist-Regular',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToTripDetail(TripModel trip) async {
    // 🎯 Sửa: Luôn sử dụng Provider để đặt trip hiện tại
    final provider = context.read<TripPlanningProvider>();
    provider.setCurrentTrip(trip);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlannerDetailScreen(trip: trip)),
    );

    if (!mounted) return;

    if (result == true || result is TripModel) {
      // Trip bị xóa (result == true) hoặc được update (result is TripModel)
      // Gọi initialize để làm mới và đồng bộ lại danh sách trips
      await provider.initialize();
      // Không cần setState vì UI đã watch Provider
    }
  }

  Future<void> _showCreateTripModal(BuildContext context) async {
    final navigator = Navigator.of(context);
    final provider = Provider.of<TripPlanningProvider>(context, listen: false);

    final result = await navigator.push<TripModel>(
      MaterialPageRoute(builder: (context) => const CreatePlannerScreen(isCollaborative: false)),
    );

    if (!mounted) return;

    // Nếu một trip được tạo thành công, Provider đã tự thêm và notifyListeners()
    if (result != null) {
      // Để đảm bảo trip mới được thêm vào và local-only trips được sync,
      // chúng ta gọi initialize lần nữa sau khi tạo.
      // 🎯 Sửa: Gọi initialize để đồng bộ hóa
      provider.initialize();
      // Không cần gọi provider.addTrip(result);
      // Không cần setState vì UI đã watch Provider
    }
  }
}

