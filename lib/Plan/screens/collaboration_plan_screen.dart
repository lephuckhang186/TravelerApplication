import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Core/theme/app_theme.dart';
import '../providers/collaboration_provider.dart';
import '../models/collaboration_models.dart';
import 'collaboration_trip_detail_screen.dart';
import 'create_planner_screen.dart';
import '../widgets/collaboration_invite_dialog.dart';
import '../widgets/trip_invitation_card.dart';

/// Collaboration mode plan screen - COMPLETELY SEPARATE from private mode
class CollaborationPlanScreen extends StatefulWidget {
  const CollaborationPlanScreen({super.key});

  @override
  State<CollaborationPlanScreen> createState() => _CollaborationPlanScreenState();
}

class _CollaborationPlanScreenState extends State<CollaborationPlanScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late TabController _tabController;
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Always initialize collaboration data when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCollaboration();
    });
  }

  @override
  void didUpdateWidget(CollaborationPlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CRITICAL FIX: Always re-initialize when widget updates (e.g., when switching back to collaboration mode)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCollaboration();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CRITICAL FIX: Force refresh when dependencies change (e.g., when coming back to this screen)
    if (_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceRefreshAllData();
      });
    }
  }

  Future<void> _forceRefreshAllData() async {
    try {
      debugPrint('🔄 FORCE_REFRESH: Force refreshing all collaboration data...');

      final provider = context.read<CollaborationProvider>();

      // Stop existing listeners
      provider.stopRealTimeListening();

      // Clear all data and reload fresh
      provider.clearAllData();

      // Force re-initialize everything
      await provider.initialize();

      debugPrint('✅ FORCE_REFRESH: All collaboration data refreshed');
    } catch (e) {
      debugPrint('❌ FORCE_REFRESH: Failed to refresh data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeCollaboration() async {
    try {
      // Always ensure collaboration data is loaded (similar to private mode)
      final collaborationProvider = context.read<CollaborationProvider>();

      // Use ensureInitialized to handle lazy loading
      await collaborationProvider.ensureInitialized();

      // Mark as initialized only after successful load
      if (!_isInitialized && mounted) {
        setState(() {
          _isInitialized = true;
        });
        debugPrint('✅ COLLABORATION_SCREEN: Initialized successfully');
      }
    } catch (e) {
      debugPrint('❌ COLLABORATION_SCREEN: Failed to initialize: $e');
      // Still mark as initialized to prevent infinite retry, but show error
      if (!_isInitialized && mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      final collaborationProvider = context.read<CollaborationProvider>();
      debugPrint('🔄 COLLABORATION_SCREEN: Refreshing data...');
      await collaborationProvider.initialize();
      debugPrint('✅ COLLABORATION_SCREEN: Data refreshed - ${collaborationProvider.mySharedTrips.length} my trips');
    } catch (e) {
      debugPrint('❌ COLLABORATION_SCREEN: Failed to refresh data: $e');
    }
  }

  List<SharedTripModel> _getFilteredTrips(List<SharedTripModel> trips) {
    if (_searchQuery.isEmpty) return trips;
    
    final query = _searchQuery.toLowerCase();
    return trips.where((trip) {
      final nameMatch = trip.name.toLowerCase().contains(query);
      final destinationMatch = trip.destination.toLowerCase().contains(query);
      final descriptionMatch = (trip.description ?? '').toLowerCase().contains(query);
      return nameMatch || destinationMatch || descriptionMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header with search and tabs
          _buildHeader(),
          
          // Content (TabView)
          Expanded(
            child: _isInitialized ? _buildBody() : _buildLoadingIndicator(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: _createNewSharedTrip,
          backgroundColor: const Color(0xFF2196F3),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              
              // Tab bar - matching plan.png with My Trips(2), Shared(0), Invitations
              Container(
                height: 50,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: Consumer<CollaborationProvider>(
                        builder: (context, provider, child) {
                          return Row(
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
                          );
                        },
                      ),
                    ),
                    Tab(
                      child: Selector<CollaborationProvider, int>(
                        selector: (context, provider) => provider.sharedWithMeTrips.length,
                        builder: (context, sharedCount, child) {
                          return Row(
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
                          );
                        },
                      ),
                    ),
                    Tab(
                      child: Consumer<CollaborationProvider>(
                        builder: (context, provider, child) {
                          return Row(
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
                          );
                        },
                      ),
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

  Widget _buildBody() {
    debugPrint('🏗️ BODY_BUILD: Building body...');

    // Use StreamBuilder for guaranteed real-time updates
    return StreamBuilder<String>(
      stream: context.read<CollaborationProvider>().collaborationService.watchUserSharedTrips().map((trips) {
        // Convert trips to a string key that changes when data changes
        final key = '${trips.length}_${trips.map((t) => t.id).join('_')}_${trips.map((t) => t.updatedAt?.millisecondsSinceEpoch ?? 0).join('_')}';
        debugPrint('📡 STREAM_BUILDER: Generated key $key for ${trips.length} trips');
        return key;
      }),
      builder: (context, snapshot) {
        debugPrint('🔄 STREAM_BUILDER_UPDATE: Stream triggered - hasData: ${snapshot.hasData}, data: ${snapshot.data}');

        return Consumer<CollaborationProvider>(
          builder: (context, provider, child) {
            debugPrint('🔄 CONSUMER_REBUILD: Consumer triggered - myTrips: ${provider.mySharedTrips.length}, shared: ${provider.sharedWithMeTrips.length}, invites: ${provider.pendingInvitations.length}');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: TabBarView(
                  key: ValueKey('tab_view_${provider.mySharedTrips.length}_${provider.sharedWithMeTrips.length}_${provider.pendingInvitations.length}_${snapshot.data ?? 'no_data'}'),
                  controller: _tabController,
                  children: [
                    _buildMyTripsTab(provider),
                    _buildSharedWithMeTab(provider),
                    _buildInvitationsTab(provider),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyTripsTab(CollaborationProvider provider) {
    final filteredTrips = _getFilteredTrips(provider.mySharedTrips);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredTrips.isEmpty) {
      return _buildEmptyState(
        'No shared trips created yet',
        'Create your first shared trip and invite friends to plan together!',
        Icons.group_add,
      );
    }

    debugPrint('🔄 MY_TRIPS_TAB: Building with ${filteredTrips.length} trips');

    return ListView.builder(
      key: ValueKey('my_trips_${filteredTrips.length}_${filteredTrips.hashCode}'),
      padding: const EdgeInsets.only(top: 20),
      itemCount: filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = filteredTrips[index];
        debugPrint('🏗️ MY_TRIPS_BUILD: Building card for ${trip.name}');
        return _buildTripCard(trip, true);
      },
    );
  }

  Widget _buildSharedWithMeTab(CollaborationProvider provider) {
    final filteredTrips = _getFilteredTrips(provider.sharedWithMeTrips);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredTrips.isEmpty) {
      return _buildEmptyState(
        'No trips shared with you',
        'When friends invite you to their trips, they will appear here!',
        Icons.share,
      );
    }

    debugPrint('🔄 SHARED_TRIPS_TAB: Building with ${filteredTrips.length} trips');

    return ListView.builder(
      key: ValueKey('shared_trips_${filteredTrips.length}_${filteredTrips.hashCode}'),
      padding: const EdgeInsets.only(top: 20),
      itemCount: filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = filteredTrips[index];
        debugPrint('🏗️ SHARED_TRIPS_BUILD: Building card for ${trip.name}');
        return _buildTripCard(trip, false);
      },
    );
  }

  Widget _buildInvitationsTab(CollaborationProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.pendingInvitations.isEmpty) {
      return _buildEmptyState(
        'No pending invitations',
        'Trip invitations from friends will appear here!',
        Icons.mail_outline,
      );
    }

    debugPrint('🔄 INVITATIONS_TAB: Building with ${provider.pendingInvitations.length} invitations');

    return ListView.builder(
      key: ValueKey('invitations_${provider.pendingInvitations.length}_${provider.pendingInvitations.hashCode}'),
      padding: const EdgeInsets.only(top: 20),
      itemCount: provider.pendingInvitations.length,
      itemBuilder: (context, index) {
        final invitation = provider.pendingInvitations[index];
        debugPrint('📨 INVITATION_BUILD: Building card for ${invitation.tripName} from ${invitation.inviterName}');
        return TripInvitationCard(
          key: ValueKey('invitation_${invitation.id}_${invitation.status}'),
          invitation: invitation,
          onAccept: () => _acceptInvitation(invitation),
          onDecline: () => _declineInvitation(invitation),
        );
      },
    );
  }

  Widget _buildTripCard(SharedTripModel trip, bool isOwner) {
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
    final dateRange = '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _openTripDetail(trip),
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
                          if (trip.sharedCollaborators.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.group,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.sharedCollaborators.length + 1}',
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
                
                // More actions menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTripAction(trip, value, isOwner),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    if (isOwner) ...[
                      const PopupMenuItem(
                        value: 'invite',
                        child: Row(
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 8),
                            Text('Invite Members'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Trip'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Trip', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ] else ...[
                      const PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          children: [
                            Icon(Icons.exit_to_app, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Leave Trip', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading collaboration data...'),
        ],
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openTripDetail(SharedTripModel trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollaborationTripDetailScreen(trip: trip, tripId: '',),
      ),
    );
  }

  void _createNewSharedTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePlannerScreen(isCollaborative: true),
      ),
    );
  }

  void _handleTripAction(SharedTripModel trip, String action, bool isOwner) {
    switch (action) {
      case 'view':
        _openTripDetail(trip);
        break;
      case 'invite':
        if (isOwner) _inviteMembers(trip);
        break;
      case 'edit':
        if (isOwner) _editTrip(trip);
        break;
      case 'delete':
        if (isOwner) _deleteTrip(trip);
        break;
      case 'leave':
        if (!isOwner) _leaveTrip(trip);
        break;
    }
  }

  void _inviteMembers(SharedTripModel trip) {
    showDialog(
      context: context,
      builder: (context) => CollaborationInviteDialog(trip: trip),
    );
  }

  void _editTrip(SharedTripModel trip) {
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

  void _deleteTrip(SharedTripModel trip) {
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
                // ignore: use_build_context_synchronously
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

  void _leaveTrip(SharedTripModel trip) {
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
                // ignore: use_build_context_synchronously
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

}

