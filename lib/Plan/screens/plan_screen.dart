import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../Core/theme/app_theme.dart';
import '../../Login/services/user_service.dart';
import '../panel/ai_assistant_panel.dart';
import 'create_planner_screen.dart';
import 'planner_detail_screen.dart';
import '../models/trip_model.dart';
import '../services/trip_planning_service.dart';
import '../services/trip_storage_service.dart';
import '../providers/trip_planning_provider.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with AutomaticKeepAliveClientMixin {
  String _displayName = 'User';
  final List<TripModel> _trips = [];
  bool _isLoading = false;
  final TripPlanningService _tripService = TripPlanningService();
  final TripStorageService _storageService = TripStorageService();

  // Add missing search variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<TripModel> get _visibleTrips {
    if (_searchQuery.isEmpty) {
      print('DEBUG: No search query, returning all ${_trips.length} trips');
      return _trips;
    }
    final query = _searchQuery.toLowerCase();
    final filtered = _trips.where((trip) {
      final nameMatch = trip.name.toLowerCase().contains(query);
      final destinationMatch = trip.destination.toLowerCase().contains(query);
      final descriptionMatch = (trip.description ?? '').toLowerCase().contains(
        query,
      );
      return nameMatch || destinationMatch || descriptionMatch;
    }).toList();
    print(
      'DEBUG: Search query "$_searchQuery" filtered ${_trips.length} trips to ${filtered.length}',
    );
    return filtered;
  }

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final userService = UserService();
    final profile = userService.getUserProfile();
    final username = await userService.getDisplayName();

    setState(() {
      _displayName = profile['fullName']?.isNotEmpty == true
          ? profile['fullName']!
          : username;
    });
  }

  void _loadTrips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First load from local storage for immediate display
      final cachedTrips = await _storageService.loadTrips();
      print('DEBUG: Loaded ${cachedTrips.length} cached trips');
      if (mounted && cachedTrips.isNotEmpty) {
        setState(() {
          _trips
            ..clear()
            ..addAll(cachedTrips);
        });
        print('DEBUG: Displaying ${_trips.length} cached trips');
      }

      // Then fetch from API to get latest data
      final remoteTrips = await _tripService.getTrips();
      print('DEBUG: Fetched ${remoteTrips.length} trips from API');

      if (remoteTrips.isNotEmpty) {
        await _storageService.saveTrips(remoteTrips);
        if (mounted) {
          setState(() {
            _trips
              ..clear()
              ..addAll(remoteTrips);
          });
          print('DEBUG: Updated UI with ${_trips.length} remote trips');
        }
      } else {
        print('DEBUG: No remote trips received, keeping cached trips');
      }
    } catch (e) {
      print('DEBUG: Error loading trips: $e');
      // Preserve whatever list we currently have and surface no UI error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('DEBUG: Final trip count: ${_trips.length}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $_displayName',
              style: GoogleFonts.quattrocento(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'Trips',
              style: GoogleFonts.quattrocento(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.more_horiz, color: Colors.white),
              ),
              onPressed: () => _showOptionsMenu(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Places, dates, travel plans...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
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
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Trip Cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visibleTrips.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No trips yet. Create your first trip!'
                            : 'No trips match “$_searchQuery”.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _visibleTrips.length,
                      itemBuilder: (context, index) {
                        final trip = _visibleTrips[index];
                        print(
                          'DEBUG: Building trip card ${index + 1}: ${trip.name}',
                        );
                        return _buildTripCard(trip, index);
                      },
                    ),
            ),
          ),

          // Fixed height spacer instead of flexible Spacer to ensure ListView gets proper space
          const SizedBox(height: 20),

          // AI Chat Box với góc tròn ở 2 đầu - thu nhỏ chiều rộng
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 90.0, // Đẩy lên cao hơn tránh Dynamic Island
            ),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.9,
                        child: AiAssistantPanel(
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30), // Góc tròn ở 2 đầu
                    border: Border.all(color: AppColors.support),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Thu nhỏ theo nội dung
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ask, chat, plan trip with AI...',
                        style: GoogleFonts.quattrocento(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 160, // Đẩy nút + lên cao hơn để tránh Dynamic Island
        ), // Đẩy nút + lên cao hơn để tránh dính chat box
        child: FloatingActionButton(
          onPressed: () => _showCreateTripModal(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
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
      status = 'Ongoing';
    }

    // Format date range
    final dateRange =
        '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year} - ${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToTripDetail(trip),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Trip Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                              color: AppColors.primary,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.travel_explore,
                        color: AppColors.primary,
                        size: 30,
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
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateRange,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
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
    );
  }

  Future<void> _navigateToTripDetail(TripModel trip) async {
    // Use Provider if available, otherwise navigate directly
    try {
      context.read<TripPlanningProvider>().setCurrentTrip(trip);
    } catch (e) {
      // Provider might not be available, continue with navigation
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlannerDetailScreen(trip: trip)),
    );

    if (!mounted) return;

    if (result == true) {
      _loadTrips();
    } else if (result is TripModel) {
      final index = _trips.indexWhere((t) => t.id == result.id);
      if (index >= 0) {
        setState(() {
          _trips[index] = result;
        });
        await _storageService.saveTrips(_trips);
      } else {
        _loadTrips();
      }
    }
  }

  void _showCreateTripModal(BuildContext context) async {
    final result = await Navigator.push<TripModel>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePlannerScreen()),
    );

    // If a trip was created, refresh the list
    if (result != null) {
      await _storageService.saveTrip(result);
      _loadTrips();
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create New Trip'),
              onTap: () {
                Navigator.pop(context);
                _showCreateTripModal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Collaborations'),
              subtitle: const Text('Uh oh! There is not anyone yet!'),
              onTap: () {
                Navigator.pop(context);
                _showCollaborationsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Handle settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCollaborationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_outlined),
            SizedBox(width: 12),
            Text('Collaborations'),
          ],
        ),
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'Uh oh! There is not anyone yet!',
                style: GoogleFonts.quattrocento(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle invite collaborators
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}
