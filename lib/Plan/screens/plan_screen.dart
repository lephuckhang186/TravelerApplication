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
  bool _isPrivateMode = true; // true = Private, false = Collaboration

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

    // 🎯 Sửa: Sử dụng context.watch để lắng nghe thay đổi từ TripPlanningProvider
    final tripProvider = context.watch<TripPlanningProvider>();
    final allTrips = tripProvider.trips;
    final isLoading = tripProvider.isLoading;
    final visibleTrips = _getVisibleTrips(allTrips);

    debugPrint(
      'DEBUG: PlanScreen building - Total Trips: ${allTrips.length}, Visible Trips: ${visibleTrips.length}, IsLoading: $isLoading',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient Header with Search Bar
          Container(
            padding: const EdgeInsets.only(bottom: 30.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.skyBlue.withValues(alpha: 0.9),
                  AppColors.steelBlue.withValues(alpha: 0.8),
                  AppColors.dodgerBlue.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Urbanist-Regular',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Places, dates, travel plans...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontFamily: 'Urbanist-Regular',
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 7),
                            child: Icon(
                              Icons.search,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 24,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.only(
                            left: 0,
                            right: 16,
                            top: 16,
                            bottom: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Private/Collaboration Toggle Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPrivateMode = !_isPrivateMode;
                        });
                      },
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              _isPrivateMode
                                  ? 'images/private.png'
                                  : 'images/collaboration.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isPrivateMode ? 'Private' : 'Collaboration',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Urbanist-Regular',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Trip Cards
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : visibleTrips.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No trips yet. Create your first trip!'
                              : 'No trips match "$_searchQuery".',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: visibleTrips.length,
                        itemBuilder: (context, index) {
                          final trip = visibleTrips[index];
                          debugPrint(
                            'DEBUG: Building trip card ${index + 1}: ${trip.name}',
                          );
                          return _buildTripCard(trip, index);
                        },
                      ),
              ),
            ),
          ),

          // Fixed height spacer
          const SizedBox(height: 20),
        ],
      ),
      floatingActionButton: _AddButton(
        onTap: () => _showCreateTripModal(context),
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

    return _TripCard(
      trip: trip,
      status: status,
      dateRange: dateRange,
      onTap: () => _navigateToTripDetail(trip),
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
      MaterialPageRoute(builder: (context) => const CreatePlannerScreen()),
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

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 50, // Đẩy nút + lên cao hơn
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyBlue.withValues(alpha: 0.9),
                      AppColors.steelBlue.withValues(alpha: 0.8),
                      AppColors.dodgerBlue.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatefulWidget {
  final TripModel trip;
  final String status;
  final String dateRange;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.status,
    required this.dateRange,
    required this.onTap,
  });

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(seconds: 9),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [
                      AppColors.dodgerBlue.withValues(alpha: 0.9),
                      AppColors.steelBlue.withValues(alpha: 0.8),
                      AppColors.skyBlue.withValues(alpha: 0.7),
                    ]
                  : [
                      AppColors.skyBlue.withValues(alpha: 0.9),
                      AppColors.steelBlue.withValues(alpha: 0.8),
                      AppColors.dodgerBlue.withValues(alpha: 0.7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: _isHovered ? 0.25 : 0.9),
                blurRadius: _isHovered ? 15 : 10,
                offset: const Offset(0, 3),
                spreadRadius: _isHovered ? 2 : 1,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Trip Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.skyBlue.withValues(alpha: 0.3),
                      ),
                      child: widget.trip.coverImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.trip.coverImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.travel_explore,
                                    color: AppColors.primary,
                                    size: 36,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.travel_explore,
                              color: AppColors.primary,
                              size: 36,
                            ),
                    ),
                    const SizedBox(width: 16),

                    // Trip Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.trip.name,
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.dateRange,
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.status,
                                style: TextStyle(
                                  fontFamily: 'Urbanist-Regular',
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
          ),
        ),
      ),
    );
  }
}
