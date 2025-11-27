import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'plan_screen.dart';
import '../features/expense_management/analysis_screen.dart';
import '../core/theme/app_theme.dart';

/// Home Screen - Travel & Tourism Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  List<Widget> get _screens => [
    const _TravelHomeContent(),
    const PlanScreen(),
    const AnalysisScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar());
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2)),
        ]),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                iconPath: 'images/home.png',
                label: 'Home',
                index: 0,
                isSelected: _currentIndex == 0),
              _buildNavItem(
                iconPath: 'images/blueprint.png',
                label: 'Plan',
                index: 1,
                isSelected: _currentIndex == 1),
              _buildNavItem(
                iconPath: 'images/analytics.png',
                label: 'Analysis',
                index: 2,
                isSelected: _currentIndex == 2),
              _buildNavItem(
                iconPath: 'images/account.png',
                label: 'Me',
                index: 3,
                isSelected: _currentIndex == 3),
            ]))));
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 11,
                color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ])));
  }
}

/// Travel Home Content - Nội dung màn hình travel home
class _TravelHomeContent extends StatefulWidget {
  const _TravelHomeContent();

  @override
  State<_TravelHomeContent> createState() => _TravelHomeContentState();
}

class _TravelHomeContentState extends State<_TravelHomeContent> {
  int _recommendedTabIndex = 0; // 0: Recommended, 1: Nearby

  // Hover state tracking
  bool _isHoveringNearbyHeader = false;
  bool _isHoveringRecentlyViewedHeader = false;
  bool _isHoveringWhereToNextHeader = false;
  bool _isHoveringRecommendedHeader = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Section - Fixed at top
            _buildSearchBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Nearby gems Section
                    _buildNearbyGemsSection(),

                    const SizedBox(height: 24),

                    // Recently Viewed Section
                    _buildRecentlyViewedSection(),

                    const SizedBox(height: 24),

                    // Where to next Section
                    _buildWhereToNextSection(),

                    const SizedBox(height: 24),

                    // Recommended Section
                    _buildRecommendedSection(),

                    const SizedBox(height: 100), // Space for bottom nav
                  ]))),
          ])));
  }

  /// Search Bar với 3 nút chính
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search Button - Mở rộng để hiển thị địa điểm đề cử
          Expanded(
            child: GestureDetector(
              onTap: () => _showSearchSuggestionsDialog(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.support),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                  ]),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tìm kiếm địa điểm...',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Plan Button - Hiển thị plan hiện tại
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
              ]),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.accent.withValues(alpha: 0.2),
                highlightColor: AppColors.accent.withValues(alpha: 0.1),
                onTap: () {
                  _showCurrentPlansDialog(context);
                },
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.map_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    // Badge hiển thị số lượng plan
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Notification Button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
              ]),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.accent.withValues(alpha: 0.2),
                highlightColor: AppColors.accent.withValues(alpha: 0.1),
                onTap: () {
                  _showNotificationsDialog(context);
                },
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    // Notification badge
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Nearby gems Section
  Widget _buildNearbyGemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Nearby gems in Ho Chi Minh',
                  style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                    fontSize: 20,color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1)),
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringNearbyHeader = true),
                onExit: (_) => setState(() => _isHoveringNearbyHeader = false),
                child: GestureDetector(
                  onTap: () => _onNearbyGemsSeMoreTap(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.diagonal3Values(
                      _isHoveringNearbyHeader ? 1.05 : 1.0,
                      _isHoveringNearbyHeader ? 1.05 : 1.0,
                      1.0),
                    child: Text(
                      'See more',
                      style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                        color: _isHoveringNearbyHeader
                            ? const Color(0xFF5B41FF)
                            : const Color(0xFF7B61FF),fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: _isHoveringNearbyHeader
                            ? const Color(0xFF5B41FF)
                            : const Color(0xFF7B61FF)))))),
            ])),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) => _buildTourCard(index))),
      ]);
  }

  // Tour Card
  Widget _buildTourCard(int index) {
    final tours = [
      {
        'title': 'Ho Chi Minh City Sightseeing Double-Decker Bus',
        'badge': 'Bestselling Tours',
        'image': 'images/hcmc_bus_tour.jpg',
        'imageColor': Colors.red[300]!,
      },
      {
        'title': 'Ho Chi Minh City Skyline & River View',
        'badge': 'Most saved Tours',
        'image': 'images/hcmc_skyline.jpg',
        'imageColor': Colors.blue[300]!,
      },
      {
        'title': 'Ho Chi Minh City Street Food Tour',
        'badge': 'Popular',
        'image': 'images/hcmc_food_tour.jpg',
        'imageColor': Colors.orange[300]!,
      },
      {
        'title': 'Ho Chi Minh City Center Tour',
        'badge': 'New Tour',
        'image': 'images/hcmc_skyline.jpg',
        'imageColor': Colors.purple[300]!,
      },
    ];
    final tour = tours[index % tours.length];

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                  child: _buildImageWithAnimation(
                    tour['image'] as String,
                    140,
                    double.infinity,
                    tour['imageColor'] as Color)),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[700],
                      borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          tour['badge'] as String,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white)),
                      ]))),
              ])),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour['title'] as String,
                    style: const TextStyle(
                      fontSize: 14,color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                        elevation: 0),
                      child: const Text(
                        'Add to plan',
                        style: TextStyle(
                          fontSize: 13)))),
                ]))),
        ]));
  }

  Widget _buildRecentlyViewedSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recently Viewed',
                  style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                    fontSize: 18,color: AppColors.textPrimary))),
              MouseRegion(
                onEnter: (_) =>
                    setState(() => _isHoveringRecentlyViewedHeader = true),
                onExit: (_) =>
                    setState(() => _isHoveringRecentlyViewedHeader = false),
                child: GestureDetector(
                  onTap: () => _onRecentlyViewedSeeMoreTap(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.diagonal3Values(
                      _isHoveringRecentlyViewedHeader ? 1.05 : 1.0,
                      _isHoveringRecentlyViewedHeader ? 1.05 : 1.0,
                      1.0),
                    child: Text(
                      'See more',
                      style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                        color: _isHoveringRecentlyViewedHeader
                            ? AppColors.accentHover
                            : AppColors.accent,fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: _isHoveringRecentlyViewedHeader
                            ? AppColors.accentHover
                            : AppColors.accent))))),
            ])),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            itemBuilder: (context, index) =>
                _buildCompactRecentCard(context, index))),
      ]);
  }

  Widget _buildCompactRecentCard(BuildContext context, int index) {
    final recentTours = [
      {
        'title': 'Ho Chi Minh City Sightseeing Double-Decker Bus Ticket',
        'subtitle': 'Bestselling Tours',
        'image': 'images/hcmc_bus_tour.jpg',
        'color': Colors.red[300]!,
      },
      {
        'title': 'Enjoy the great outdoor in Ho Chi Minh city with these local',
        'subtitle': 'Popular',
        'image': 'images/hcmc_skyline.jpg',
        'color': Colors.blue[300]!,
      },
    ];

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4)),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: (recentTours[index]['color'] as Color).withValues(
            alpha: 0.2),
          hoverColor: (recentTours[index]['color'] as Color).withValues(
            alpha: 0.05),
          onTap: () => _onRecentlyViewedTap(
            context,
            recentTours[index]['title'] as String),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                _buildImageWithAnimation(
                  recentTours[index]['image'] as String,
                  140,
                  180,
                  recentTours[index]['color'] as Color),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ]))),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recentTours[index]['title'] as String,
                        style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                          fontSize: 13,color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    ])),
              ])))));
  }

  Widget _buildWhereToNextSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Where to next?',
                  style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                    fontSize: 18,color: AppColors.textPrimary))),
              MouseRegion(
                onEnter: (_) =>
                    setState(() => _isHoveringWhereToNextHeader = true),
                onExit: (_) =>
                    setState(() => _isHoveringWhereToNextHeader = false),
                child: GestureDetector(
                  onTap: () => _onWhereToNextSeeMoreTap(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.diagonal3Values(
                      _isHoveringWhereToNextHeader ? 1.05 : 1.0,
                      _isHoveringWhereToNextHeader ? 1.05 : 1.0,
                      1.0),
                    child: Text(
                      'See more',
                      style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                        color: _isHoveringWhereToNextHeader
                            ? const Color(0xFF5B41FF)
                            : const Color(0xFF7B61FF),fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: _isHoveringWhereToNextHeader
                            ? const Color(0xFF5B41FF)
                            : const Color(0xFF7B61FF)))))),
            ])),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) =>
                _buildCompactDestinationCard(context, index))),
      ]);
  }

  Widget _buildCompactDestinationCard(BuildContext context, int index) {
    final destinations = [
      {
        'title': 'Ho Chi Minh',
        'image': 'images/hcmc_skyline.jpg',
        'color': Colors.orange[300]!,
      },
      {
        'title': 'Da Nang',
        'image': 'images/danang.jpg',
        'color': Colors.blue[300]!,
      },
      {
        'title': 'Ha Noi',
        'image': 'images/hanoi.jpg',
        'color': Colors.red[300]!,
      },
    ];
    final destination = destinations[index];

    return Container(
      width: 100,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3)),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: (destination['color'] as Color).withValues(alpha: 0.3),
          hoverColor: (destination['color'] as Color).withValues(alpha: 0.1),
          onTap: () =>
              _onWhereToNextTap(context, destination['title'] as String),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImageWithAnimation(
                  destination['image'] as String,
                  80,
                  100,
                  destination['color'] as Color)),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ]))),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  destination['title'] as String,
                  style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                    fontSize: 12,color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
            ]))));
  }

  Widget _buildRecommendedSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildTabButton('Recommended', 0),
                    const SizedBox(width: 16),
                    _buildTabButton('Nearby', 1),
                  ])),
              MouseRegion(
                onEnter: (_) =>
                    setState(() => _isHoveringRecommendedHeader = true),
                onExit: (_) =>
                    setState(() => _isHoveringRecommendedHeader = false),
                child: GestureDetector(
                  onTap: () => _onRecommendedSeeMoreTap(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.diagonal3Values(
                      _isHoveringRecommendedHeader ? 1.05 : 1.0,
                      _isHoveringRecommendedHeader ? 1.05 : 1.0,
                      1.0),
                    child: Text(
                      'See more',
                      style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                        color: _isHoveringRecommendedHeader
                            ? const Color(0xFF5B41FF)
                            : const Color(0xFF7B61FF),fontSize: 14,
                        decoration: TextDecoration.underline))))),
            ])),
        const SizedBox(height: 16),
        _buildTabContent(),
      ]);
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _recommendedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _recommendedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[300]!)),
        child: Text(
          title,
          style: TextStyle(
                fontFamily: 'Urbanist-Regular',
            fontSize: 14,color: isSelected ? Colors.white : Colors.grey[700]))));
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recommendedTabIndex == 0 ? 4 : 4,
        itemBuilder: (context, index) => _recommendedTabIndex == 0
            ? _buildRecommendedCard(context, index)
            : _buildNearbyCard(context, index)));
  }

  Widget _buildRecommendedCard(BuildContext context, int index) {
    final places = [
      {
        'title': 'Ben Thanh Market',
        'subtitle': 'Traditional Market',
        'image': 'images/hcmc_food_tour.jpg',
        'color': Colors.orange[300]!,
        'rating': '4.5',
      },
      {
        'title': 'Saigon Skydeck',
        'subtitle': 'City Views',
        'image': 'images/hcmc_skyline.jpg',
        'color': Colors.blue[300]!,
        'rating': '4.7',
      },
      {
        'title': 'War Remnants Museum',
        'subtitle': 'History & Culture',
        'image': 'images/hcm_war_remmants_museum.jpg',
        'color': Colors.red[300]!,
        'rating': '4.6',
      },
      {
        'title': 'Independence Palace',
        'subtitle': 'Historic Site',
        'image': 'images/hcm_independence_palace.jpg',
        'color': Colors.purple[300]!,
        'rating': '4.4',
      },
    ];
    final place = places[index % places.length];

    return Container(
      width: 160,
      height: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4)),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onRecommendedTap(context, place['title'] as String),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                    child: _buildImageWithAnimation(
                      place['image'] as String,
                      110,
                      160,
                      place['color'] as Color)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            place['rating'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9)),
                        ]))),
                ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place['title'] as String,
                        style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                          fontSize: 13,color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                        place['subtitle'] as String,
                        style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                          fontSize: 11,
                          color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    ]))),
            ]))));
  }

  Widget _buildNearbyCard(BuildContext context, int index) {
    final places = [
      {
        'title': 'Coffee Shop District 1',
        'subtitle': 'Traditional Coffee',
        'image': 'images/hcmc_food_tour.jpg',
        'color': Colors.brown[300]!,
        'distance': '0.5 km',
      },
      {
        'title': 'Nguyen Hue Walking Street',
        'subtitle': 'City Center',
        'image': 'images/hcmc_skyline.jpg',
        'color': Colors.blue[300]!,
        'distance': '0.8 km',
      },
      {
        'title': 'Saigon Central Post Office',
        'subtitle': 'Historic Building',
        'image': 'images/hcmc_bus_tour.jpg',
        'color': Colors.green[300]!,
        'distance': '1.2 km',
      },
      {
        'title': 'Ben Thanh Night Market',
        'subtitle': 'Local Market',
        'image': 'images/hcmc_food_tour.jpg',
        'color': Colors.orange[300]!,
        'distance': '0.3 km',
      },
    ];
    final place = places[index % places.length];

    return Container(
      width: 160,
      height: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4)),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: (place['color'] as Color).withValues(alpha: 0.2),
          hoverColor: (place['color'] as Color).withValues(alpha: 0.05),
          onTap: () => _onNearbyTap(context, place['title'] as String),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                    child: _buildImageWithAnimation(
                      place['image'] as String,
                      110,
                      160,
                      place['color'] as Color)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 10),
                          const SizedBox(width: 2),
                          Text(
                            place['distance'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9)),
                        ]))),
                ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place['title'] as String,
                        style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                          fontSize: 13,color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                        place['subtitle'] as String,
                        style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                          fontSize: 11,
                          color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    ]))),
            ]))));
  }

  Widget _buildImageWithAnimation(
    String imagePath,
    double height,
    double width,
    Color fallbackColor) {
    return SizedBox(
      height: height,
      width: width,
      child: Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          width: width,
          color: fallbackColor,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white,
              size: height * 0.3)))));
  }

  // Handler methods

  // Event handlers - Dialog implementations
  void _showSearchSuggestionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tìm kiếm địa điểm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Input
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Nhập tên địa điểm...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
            ),
            
            SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Địa điểm đề cử
                    Text(
                      'Địa điểm đề cử',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._buildSuggestedPlaces(),
                    
                    SizedBox(height: 24),
                    
                    // Từng ghé qua
                    Text(
                      'Từng ghé qua',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._buildVisitedPlaces(),
                    
                    SizedBox(height: 24),
                    
                    // Khu vực phổ biến
                    Text(
                      'Khu vực phổ biến',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._buildPopularAreas(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSuggestedPlaces() {
    final suggestedPlaces = [
      {'name': 'Chùa Ngọc Hoàng', 'location': 'Quận 1', 'icon': Icons.temple_hindu},
      {'name': 'Bảo tàng Chứng tích Chiến tranh', 'location': 'Quận 3', 'icon': Icons.museum},
      {'name': 'Dinh Độc Lập', 'location': 'Quận 1', 'icon': Icons.location_city},
      {'name': 'Chợ Bến Thành', 'location': 'Quận 1', 'icon': Icons.shopping_cart},
    ];
    
    return suggestedPlaces.map((place) => ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(place['icon'] as IconData, color: AppColors.primary),
      ),
      title: Text(place['name'] as String),
      subtitle: Text(place['location'] as String),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        // TODO: Navigate to place detail
      },
    )).toList();
  }

  List<Widget> _buildVisitedPlaces() {
    final visitedPlaces = [
      {'name': 'Bitexco Financial Tower', 'location': 'Quận 1', 'date': '2 tuần trước'},
      {'name': 'Nhà hát Thành phố', 'location': 'Quận 1', 'date': '1 tháng trước'},
    ];
    
    return visitedPlaces.map((place) => ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        child: Icon(Icons.check, color: Colors.green),
      ),
      title: Text(place['name'] as String),
      subtitle: Text('${place['location']} • ${place['date']}'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        // TODO: Navigate to place detail
      },
    )).toList();
  }

  List<Widget> _buildPopularAreas() {
    final popularAreas = [
      {'name': 'Quận 1', 'description': 'Trung tâm thành phố'},
      {'name': 'Quận 3', 'description': 'Khu văn hóa - giải trí'},
      {'name': 'Quận 7', 'description': 'Khu đô thị mới'},
    ];
    
    return popularAreas.map((area) => ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        child: Icon(Icons.location_on, color: Colors.orange),
      ),
      title: Text(area['name'] as String),
      subtitle: Text(area['description'] as String),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        // TODO: Navigate to area
      },
    )).toList();
  }

  void _showCurrentPlansDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Kế hoạch của bạn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Plan đang thực hiện
                  _buildPlanCard(
                    'Khám phá Sài Gòn',
                    'Đang thực hiện',
                    '15-20 Dec',
                    Colors.green,
                    Icons.play_circle_fill,
                    true,
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Plan sắp tới
                  _buildPlanCard(
                    'Du lịch Đà Nẵng',
                    'Sắp tới',
                    '25-30 Dec',
                    Colors.orange,
                    Icons.schedule,
                    false,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Button tạo plan mới
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to create plan
                    },
                    icon: Icon(Icons.add),
                    label: Text('Tạo kế hoạch mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildPlanCard(String title, String status, String date, Color statusColor, IconData statusIcon, bool isActive) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(date, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to plan detail
        },
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Mark all as read
                        },
                        child: Text('Đánh dấu tất cả đã đọc'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildNotificationItem(
                    'Kế hoạch "Khám phá Sài Gòn" sắp bắt đầu',
                    'Chuyến đi của bạn sẽ bắt đầu vào ngày mai',
                    '2 giờ trước',
                    Icons.calendar_today,
                    Colors.blue,
                    true,
                  ),
                  
                  _buildNotificationItem(
                    'Địa điểm mới được thêm',
                    'Chùa Ngọc Hoàng đã được thêm vào danh sách yêu thích',
                    '1 ngày trước',
                    Icons.favorite,
                    Colors.red,
                    false,
                  ),
                  
                  _buildNotificationItem(
                    'Cập nhật thời tiết',
                    'Thời tiết tại Sài Gòn: Nắng, 28°C',
                    '2 ngày trước',
                    Icons.wb_sunny,
                    Colors.orange,
                    false,
                  ),
                  
                  _buildNotificationItem(
                    'Đánh giá địa điểm',
                    'Hãy đánh giá trải nghiệm tại Bitexco Financial Tower',
                    '3 ngày trước',
                    Icons.star_rate,
                    Colors.amber,
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message, String time, IconData icon, Color color, bool isUnread) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? color.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: isUnread 
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            )
          : null,
      ),
    );
  }

  void _onNearbyGemsSeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading more nearby gems...'),
        backgroundColor: const Color(0xFF7B61FF)));
  }

  void _onRecentlyViewedTap(BuildContext context, String tourName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $tourName...'),
        backgroundColor: Colors.blueAccent));
  }

  void _onRecentlyViewedSeeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading more recently viewed items...'),
        backgroundColor: Colors.blueAccent));
  }

  void _onWhereToNextTap(BuildContext context, String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exploring $destination...'),
        backgroundColor: Colors.green));
  }

  void _onWhereToNextSeeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading more destinations...'),
        backgroundColor: Colors.green));
  }

  void _onRecommendedTap(BuildContext context, String placeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exploring $placeName...'),
        backgroundColor: const Color(0xFF7B61FF)));
  }

  void _onNearbyTap(BuildContext context, String placeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $placeName...'),
        backgroundColor: Colors.green));
  }

  void _onRecommendedSeeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Loading more ${_recommendedTabIndex == 0 ? "recommended" : "nearby"} places...'),
        backgroundColor: const Color(0xFF7B61FF)));
  }
}
