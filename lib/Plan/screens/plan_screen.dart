import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/providers/app_mode_provider.dart';
import 'create_planner_screen.dart';
import 'planner_detail_screen.dart';
import '../models/trip_model.dart';
import '../models/collaboration_models.dart';
import '../providers/trip_planning_provider.dart';
import '../providers/collaboration_provider.dart';
import '../widgets/collaboration_invite_dialog.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isInitialized = false;

  // Unified trip filtering for both modes
  List<dynamic> _getVisibleTrips(List<dynamic> allTrips) {
    if (_searchQuery.isEmpty) {
      debugPrint('DEBUG: No search query, returning all ${allTrips.length} trips');
      return allTrips;
    }
    final query = _searchQuery.toLowerCase();
    final filtered = allTrips.where((trip) {
      final nameMatch = trip.name.toLowerCase().contains(query);
      final destinationMatch = trip.destination.toLowerCase().contains(query);
      final descriptionMatch = (trip.description ?? '').toLowerCase().contains(query);
      return nameMatch || destinationMatch || descriptionMatch;
    }).toList();
    debugPrint('DEBUG: Search query "$_searchQuery" filtered ${allTrips.length} trips to ${filtered.length}');
    return filtered;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize appropriate provider based on mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appMode = context.read<AppModeProvider>();
      if (appMode.isPrivateMode) {
        // Only initialize TripPlanningProvider in private mode
        Provider.of<TripPlanningProvider>(context, listen: false).initialize();
        setState(() => _isInitialized = true);
      } else {
        // Collaboration mode: only initialize collaboration provider
        // TripPlanningProvider will remain empty/uninitialized
        _initializeCollaboration();
      }
    });
  }

  Future<void> _initializeCollaboration() async {
    try {
      final collaborationProvider = context.read<CollaborationProvider>();
      await collaborationProvider.ensureInitialized();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
      debugPrint('✅ COLLABORATION_SCREEN: Initialized successfully');
    } catch (e) {
      debugPrint('❌ COLLABORATION_SCREEN: Failed to initialize: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<AppModeProvider>(
      builder: (context, appMode, child) {
        if (appMode.isPrivateMode) {
          return _buildPrivateMode();
        } else {
          return _buildCollaborationMode();
        }
      },
    );
  }

  Widget _buildPrivateMode() {
    final tripProvider = context.watch<TripPlanningProvider>();
    final allTrips = tripProvider.trips;
    final isLoading = tripProvider.isLoading;
    final visibleTrips = _getVisibleTrips(allTrips);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Trip Cards List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleTrips.isEmpty
                  ? _buildEmptyState(
                      _searchQuery.isEmpty ? 'No trips yet' : 'No trips found',
                      _searchQuery.isEmpty
                          ? 'Create your first trip to get started!'
                          : 'Try adjusting your search terms',
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

  Widget _buildCollaborationMode() {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<String>(
      stream: context.read<CollaborationProvider>().collaborationService.watchUserSharedTrips().map((trips) {
        final key = '${trips.length}_${trips.map((t) => t.id).join('_')}_${trips.map((t) => t.updatedAt?.millisecondsSinceEpoch ?? 0).join('_')}';
        return key;
      }),
      builder: (context, snapshot) {
        return Consumer<CollaborationProvider>(
          builder: (context, provider, child) {
            return Scaffold(
              backgroundColor: const Color(0xFFF5F7FA),
              body: Column(
                children: [
                  // Header with tabs
                  _buildCollaborationHeader(provider),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMyTripsTab(provider),
                          _buildSharedWithMeTab(provider),
                          _buildInvitationsTab(provider),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: FloatingActionButton(
                  onPressed: () => _showCreateTripModal(context, isCollaborative: true),
                  backgroundColor: const Color(0xFF2196F3),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A9EFF), Color(0xFF2196F3)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  onChanged: (value) => setState(() => _searchQuery = value),
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
                      child: Icon(Icons.search, color: Colors.grey[500]),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[500]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollaborationHeader(CollaborationProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A9EFF), Color(0xFF2196F3)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  onChanged: (value) => setState(() => _searchQuery = value),
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
                      child: Icon(Icons.search, color: Colors.grey[500]),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[500]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Tab bar
              Container(
                height: 50,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                  tabs: [
                    Tab(child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('My Trips'),
                        if (provider.mySharedTrips.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${provider.mySharedTrips.length}',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    )),
                    Tab(child: Selector<CollaborationProvider, int>(
                      selector: (context, provider) => provider.sharedWithMeTrips.length,
                      builder: (context, sharedCount, child) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Shared'),
                          if (sharedCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$sharedCount',
                                style: const TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                    Tab(child: Consumer<CollaborationProvider>(
                      builder: (context, provider, child) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Invitations'),
                          if (provider.pendingInvitations.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${provider.pendingInvitations.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyTripsTab(CollaborationProvider provider) {
    final filteredTrips = _getVisibleTrips(provider.mySharedTrips);

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    if (filteredTrips.isEmpty) {
      return _buildEmptyState(
        'No shared trips created yet',
        'Create your first shared trip and invite friends to plan together!',
        Icons.group_add,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await provider.initialize(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) => _buildSharedTripCard(filteredTrips[index], true),
      ),
    );
  }

  Widget _buildSharedWithMeTab(CollaborationProvider provider) {
    final filteredTrips = _getVisibleTrips(provider.sharedWithMeTrips);

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    if (filteredTrips.isEmpty) {
      return _buildEmptyState(
        'No trips shared with you',
        'When friends invite you to their trips, they will appear here!',
        Icons.share,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await provider.initialize(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) => _buildSharedTripCard(filteredTrips[index], false),
      ),
    );
  }

  Widget _buildInvitationsTab(CollaborationProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    if (provider.pendingInvitations.isEmpty) {
      return _buildEmptyState(
        'No pending invitations',
        'Trip invitations from friends will appear here!',
        Icons.mail_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await provider.initialize(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: provider.pendingInvitations.length,
        itemBuilder: (context, index) => _buildInvitationCard(provider.pendingInvitations[index]),
      ),
    );
  }

  Widget _buildSharedTripCard(SharedTripModel trip, bool isOwner) {
    String status;
    final now = DateTime.now();
    if (trip.startDate.isAfter(now)) status = 'Upcoming';
    else if (trip.endDate.isBefore(now)) status = 'Completed';
    else status = 'In Progress';

    final dateRange = '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _navigateToSharedTripDetail(trip),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9EFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.travel_explore, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trip.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Urbanist-Regular',
                              ),
                            ),
                          ),
                          if (isOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A9EFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
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
                              color: status == 'In Progress' ? Colors.green :
                                     status == 'Upcoming' ? Colors.orange : Colors.grey,
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
                          if (trip.sharedCollaborators.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.group, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.sharedCollaborators.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Urbanist-Regular',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleSharedTripAction(trip, value, isOwner),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'view', child: Row(
                      children: [Icon(Icons.visibility), SizedBox(width: 8), Text('View Details')],
                    )),
                    if (isOwner) ...[
                      const PopupMenuItem(value: 'invite', child: Row(
                        children: [Icon(Icons.person_add), SizedBox(width: 8), Text('Invite Members')],
                      )),
                      const PopupMenuItem(value: 'edit', child: Row(
                        children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit Trip')],
                      )),
                      const PopupMenuItem(value: 'delete', child: Row(
                        children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete Trip', style: TextStyle(color: Colors.red))],
                      )),
                    ] else ...[
                      const PopupMenuItem(value: 'leave', child: Row(
                        children: [Icon(Icons.exit_to_app, color: Colors.red), SizedBox(width: 8), Text('Leave Trip', style: TextStyle(color: Colors.red))],
                      )),
                    ],
                  ],
                  child: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(TripInvitation invitation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitation.tripName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text('Invited by ${invitation.inviterName}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptInvitation(invitation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineInvitation(invitation),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, [IconData? icon]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.travel_explore, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle, textAlign: TextAlign.center, style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            )),
          ),
        ],
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

  Future<void> _showCreateTripModal(BuildContext context, {bool isCollaborative = false}) async {
    if (isCollaborative) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePlannerScreen(isCollaborative: true)),
      );
    } else {
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
        provider.initialize();
      }
    }
  }

  // Collaboration-specific methods
  void _navigateToSharedTripDetail(SharedTripModel trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlannerDetailScreen(trip: trip.toTripModel())),
    );
  }

  void _handleSharedTripAction(SharedTripModel trip, String action, bool isOwner) {
    switch (action) {
      case 'view':
        _navigateToSharedTripDetail(trip);
        break;
      case 'invite':
        if (isOwner) _showInviteDialog(trip);
        break;
      case 'edit':
        if (isOwner) _editSharedTrip(trip);
        break;
      case 'delete':
        if (isOwner) _deleteSharedTrip(trip);
        break;
      case 'leave':
        if (!isOwner) _leaveSharedTrip(trip);
        break;
    }
  }

  void _showInviteDialog(SharedTripModel trip) {
    showDialog(
      context: context,
      builder: (context) => CollaborationInviteDialog(trip: trip),
    );
  }

  void _editSharedTrip(SharedTripModel trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlannerScreen(
          isCollaborative: true,
          existingTrip: trip.toTripModel(),
        ),
      ),
    );
  }

  void _deleteSharedTrip(SharedTripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shared Trip'),
        content: Text(
          'Are you sure you want to delete "${trip.name}"? This action cannot be undone and will remove the trip for all members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<CollaborationProvider>();
              await provider.deleteSharedTrip(trip.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip deleted successfully')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _leaveSharedTrip(SharedTripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Trip'),
        content: Text(
          'Are you sure you want to leave "${trip.name}"? You will no longer have access to this trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<CollaborationProvider>();
              await provider.leaveSharedTrip(trip.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Left trip successfully')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _acceptInvitation(TripInvitation invitation) async {
    final provider = context.read<CollaborationProvider>();
    await provider.respondToInvitation(invitation.id, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation accepted!')),
      );
    }
  }

  void _declineInvitation(TripInvitation invitation) async {
    final provider = context.read<CollaborationProvider>();
    await provider.respondToInvitation(invitation.id, false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation declined')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
