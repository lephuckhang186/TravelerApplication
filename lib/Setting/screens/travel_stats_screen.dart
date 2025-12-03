import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TravelStatsScreen extends StatefulWidget {
  const TravelStatsScreen({super.key});

  @override
  State<TravelStatsScreen> createState() => _TravelStatsScreenState();
}

class _TravelStatsScreenState extends State<TravelStatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          style: GoogleFonts.quattrocento(
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
              labelStyle: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.quattrocento(
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
          
          // Bottom Illustration
          _buildBottomIllustration(),
        ],
      ),
    );
  }

  Widget _buildYearStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance Traveled Section
          _buildDistanceTraveledSection(),
          
          const SizedBox(height: 20),
          
          // Stats List
          _buildStatsList(),
          
          const SizedBox(height: 20),
          
          // Bottom Illustration
          _buildBottomIllustration(),
        ],
      ),
    );
  }

  Widget _buildDistanceTraveledSection() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distance Traveled',
            style: GoogleFonts.quattrocento(
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
                '0',
                style: GoogleFonts.quattrocento(
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
                  style: GoogleFonts.quattrocento(
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
            'You haven\'t traveled yet. TripIt will update your travel stats every time you complete a trip.',
            style: GoogleFonts.quattrocento(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'icon': Icons.calendar_today, 'title': 'Total Days', 'value': '0'},
      {'icon': Icons.card_travel, 'title': 'Total Trips', 'value': '0'},
      {'icon': Icons.public, 'title': 'Countries/Regions Visited', 'value': '0'},
      {'icon': Icons.location_city, 'title': 'Cities Visited', 'value': '0'},
    ];

    return Column(
      children: stats.map((stat) => _buildStatItem(
        stat['icon'] as IconData,
        stat['title'] as String,
        stat['value'] as String,
      )).toList(),
    );
  }

  Widget _buildStatsList() {
    final stats = [
      {'icon': Icons.calendar_today, 'title': 'Total Days', 'value': '0'},
      {'icon': Icons.card_travel, 'title': 'Total Trips', 'value': '0'},
      {'icon': Icons.public, 'title': 'Countries/Regions Visited', 'value': '0'},
      {'icon': Icons.location_city, 'title': 'Cities Visited', 'value': '0'},
    ];

    return Column(
      children: stats.map((stat) => Container(
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
                style: GoogleFonts.quattrocento(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              stat['value'] as String,
              style: GoogleFonts.quattrocento(
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
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.quattrocento(
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
}