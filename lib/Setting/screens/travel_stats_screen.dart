import 'package:flutter/material.dart';
import '../../Login/services/firestore_statistics_service.dart';
//import '../../Login/services/auth_service.dart';
import 'dart:async';

class TravelStatsScreen extends StatefulWidget {
  const TravelStatsScreen({super.key});

  @override
  State<TravelStatsScreen> createState() => _TravelStatsScreenState();
}

class _TravelStatsScreenState extends State<TravelStatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreStatisticsService _statisticsService = FirestoreStatisticsService();
  //final AuthService _authService = AuthService();
  
  UserTravelStats _stats = UserTravelStats.empty();
  bool _isLoading = true;
  StreamSubscription<UserTravelStats>? _statsSubscription;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStatistics();
  }

  void _loadStatistics() {
    _statsSubscription = _statisticsService.getUserStatisticsStream().listen(
      (stats) {
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        print('Error loading statistics: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statsSubscription?.cancel();
    _statisticsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Travel Stats',
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.blue),
            onPressed: () {
              // Handle share functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue,
              labelStyle: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: '2025'),
              ],
            ),
          ),
          
          // Tab View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllStatsTab(),
                _buildYearStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllStatsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance Traveled Section
          _buildDistanceTraveledSection(),
          
          const SizedBox(height: 20),
          
          // Stats Grid
          _buildStatsGrid(),
          
          const SizedBox(height: 20),
          
          // All Time Progress Chart
          _buildAllTimeProgressChart(),
          
          const SizedBox(height: 20),
          
          // Bottom Illustration
          _buildBottomIllustration(),
        ],
      ),
    );
  }

  Widget _buildYearStatsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance Traveled Section (for 2025, show proportional distance)
          _buildDistanceTraveledSection(isYear2025: true),
          
          const SizedBox(height: 20),
          
          // Stats List for 2025
          _buildStatsList(isYear2025: true),
          
          const SizedBox(height: 20),
          
          // 2025 Progress Chart
          _build2025ProgressChart(),
          
          const SizedBox(height: 20),
          
          // Bottom Illustration
          _buildBottomIllustration(),
        ],
      ),
    );
  }

  Widget _buildDistanceTraveledSection({bool isYear2025 = false}) {
    // Calculate distance based on total days (estimated 100km per day)
    final distance = isYear2025 
        ? (_stats.totalDays2025 * 100.0).toInt()
        : _stats.totalDistance.toInt();
    
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isYear2025 ? 'Distance Traveled (2025)' : 'Distance Traveled',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    distance.toString(),
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'km',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),
          const SizedBox(height: 16),
          Text(
            isYear2025 
                ? 'Distance is calculated from your 2025 trips. Continue planning and traveling!'
                : 'Distance is calculated from your completed trips. Start traveling to see real data!',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({bool isYear2025 = false}) {
    final statsData = [
      {
        'icon': Icons.calendar_today, 
        'title': 'Total Days', 
        'value': isYear2025 ? _stats.totalDays2025.toString() : _stats.totalDays.toString()
      },
      {
        'icon': Icons.card_travel, 
        'title': 'Total Trips', 
        'value': isYear2025 ? _stats.completedTrips2025.toString() : _stats.completedTrips.toString()
      },
      {
        'icon': Icons.location_on, 
        'title': 'Locations Visited', 
        'value': isYear2025 ? _stats.checkedInLocations2025.toString() : _stats.checkedInLocations.toString()
      },
      {
        'icon': Icons.event_note, 
        'title': 'Total Plans', 
        'value': isYear2025 ? _stats.totalPlans2025.toString() : _stats.totalPlans.toString()
      },
    ];

    return Column(
      children: statsData.map((stat) => _buildStatItem(
        stat['icon'] as IconData,
        stat['title'] as String,
        stat['value'] as String,
      )).toList(),
    );
  }

  Widget _buildStatsList({bool isYear2025 = false}) {
    final statsData = [
      {
        'icon': Icons.calendar_today, 
        'title': 'Total Days', 
        'value': isYear2025 ? _stats.totalDays2025.toString() : _stats.totalDays.toString()
      },
      {
        'icon': Icons.card_travel, 
        'title': 'Total Trips', 
        'value': isYear2025 ? _stats.completedTrips2025.toString() : _stats.completedTrips.toString()
      },
      {
        'icon': Icons.location_on, 
        'title': 'Locations Visited', 
        'value': isYear2025 ? _stats.checkedInLocations2025.toString() : _stats.checkedInLocations.toString()
      },
      {
        'icon': Icons.event_note, 
        'title': 'Total Plans', 
        'value': isYear2025 ? _stats.totalPlans2025.toString() : _stats.totalPlans.toString()
      },
    ];

    return Column(
          children: statsData.map((stat) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stat['title'] as String,
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )).toList(),
        );
  }

  Widget _buildStatItem(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: 'Urbanist-Regular', 
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomIllustration() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Simple city skyline illustration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue[200]!,
                    Colors.blue[300]!,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBuilding(60, Colors.blue[400]!),
                  _buildBuilding(80, Colors.blue[500]!),
                  _buildBuilding(45, Colors.blue[400]!),
                  _buildBuilding(70, Colors.blue[500]!),
                  _buildBuilding(55, Colors.blue[400]!),
                ],
              ),
            ),
          ),
          // Travel icons scattered around
          Positioned(
            top: 20,
            left: 30,
            child: Icon(Icons.airplanemode_active, color: Colors.blue[300], size: 24),
          ),
          Positioned(
            top: 40,
            right: 40,
            child: Icon(Icons.location_on, color: Colors.blue[300], size: 20),
          ),
          Positioned(
            top: 60,
            left: 60,
            child: Icon(Icons.camera_alt, color: Colors.blue[300], size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBuilding(double height, Color color) {
    return Container(
      width: 30,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Windows
          for (int i = 0; i < (height / 20).floor(); i++)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
              height: 8,
              decoration: BoxDecoration(
                color: Colors.yellow[200],
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllTimeProgressChart() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'All Time Progress',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Chart - using real data, auto-scaling
            Container(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChartColumn(
                    'Plans',
                    _stats.totalPlans,
                    _getMaxValue([_stats.totalPlans, _stats.totalDays, _stats.checkedInLocations, _stats.completedTrips]),
                    Icons.event_note,
                    Colors.blue,
                  ),
                  _buildChartColumn(
                    'Days',
                    _stats.totalDays,
                    _getMaxValue([_stats.totalPlans, _stats.totalDays, _stats.checkedInLocations, _stats.completedTrips]),
                    Icons.calendar_today,
                    Colors.green,
                  ),
                  _buildChartColumn(
                    'Locations',
                    _stats.checkedInLocations,
                    _getMaxValue([_stats.totalPlans, _stats.totalDays, _stats.checkedInLocations, _stats.completedTrips]),
                    Icons.location_on,
                    Colors.orange,
                  ),
                  _buildChartColumn(
                    'Trips',
                    _stats.completedTrips,
                    _getMaxValue([_stats.totalPlans, _stats.totalDays, _stats.checkedInLocations, _stats.completedTrips]),
                    Icons.flight,
                    Colors.purple,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your complete travel journey! Track all your adventures from the beginning.',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build2025ProgressChart() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  '2025 Progress',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Chart - using real 2025 data, auto-scaling
            Container(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChartColumn(
                    'Plans',
                    _stats.totalPlans2025,
                    _getMaxValue([_stats.totalPlans2025, _stats.totalDays2025, _stats.checkedInLocations2025, _stats.completedTrips2025]),
                    Icons.event_note,
                    Colors.blue,
                  ),
                  _buildChartColumn(
                    'Days',
                    _stats.totalDays2025,
                    _getMaxValue([_stats.totalPlans2025, _stats.totalDays2025, _stats.checkedInLocations2025, _stats.completedTrips2025]),
                    Icons.calendar_today,
                    Colors.green,
                  ),
                  _buildChartColumn(
                    'Locations',
                    _stats.checkedInLocations2025,
                    _getMaxValue([_stats.totalPlans2025, _stats.totalDays2025, _stats.checkedInLocations2025, _stats.completedTrips2025]),
                    Icons.location_on,
                    Colors.orange,
                  ),
                  _buildChartColumn(
                    'Trips',
                    _stats.completedTrips2025,
                    _getMaxValue([_stats.totalPlans2025, _stats.totalDays2025, _stats.checkedInLocations2025, _stats.completedTrips2025]),
                    Icons.flight,
                    Colors.purple,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Track your 2025 travel achievements! Each bar shows your progress this year.',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMaxValue(List<int> values) {
    if (values.isEmpty) return 10;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue : 10; // Minimum scale
  }

  Widget _buildChartColumn(String label, int value, int maxValue, IconData icon, Color color) {
    // Calculate height percentage (minimum 10% for visibility, maximum 100%)
    double heightPercentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    if (value > 0 && heightPercentage < 0.1) {
      heightPercentage = 0.1; // Minimum height for visibility
    }
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Value label
            Container(
              height: 24,
              alignment: Alignment.center,
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            
            // Chart bar
            Container(
              height: 140 * heightPercentage,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    color,
                    color.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: value > 0 ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: value > 0 ? Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: heightPercentage > 0.3 ? 20 : 16,
                ),
              ) : null,
            ),
            
            const SizedBox(height: 8),
            
            // Label
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}