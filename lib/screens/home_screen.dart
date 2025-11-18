import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'plan_screen.dart';
import 'analysis_screen.dart';

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
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                isSelected: _currentIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.event_note_outlined,
                activeIcon: Icons.event_note,
                label: 'Plan',
                index: 1,
                isSelected: _currentIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                label: 'Analysis',
                index: 2,
                isSelected: _currentIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Me',
                index: 3,
                isSelected: _currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
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
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: Colors.white,
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

                    // Category Icons Row
                    _buildCategoryIcons(),

                    const SizedBox(height: 24),

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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search Bar với icons
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showSearchDialog(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Vietnam tradition places',
                      style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.blue.withOpacity(0.2),
                highlightColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  _onPlanTap(context);
                },
                child: Center(
                  child: Icon(Icons.event_note_outlined, color: Colors.grey[700]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.orange.withOpacity(0.2),
                highlightColor: Colors.orange.withOpacity(0.1),
                onTap: () {
                  _onNotificationTap(context);
                },
                child: Center(
                  child: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Category Icons Row
  Widget _buildCategoryIcons() {
    final categories = [
      {'icon': Icons.beach_access, 'label': 'Beachs', 'color': const Color(0xFF7B61FF)},
      {'icon': Icons.directions_bus, 'label': 'Transportation', 'color': Colors.blue},
      {'icon': Icons.apartment, 'label': 'Rentals', 'color': Colors.green},
      {'icon': Icons.location_city, 'label': 'Hotels', 'color': Colors.amber},
      {'icon': Icons.celebration, 'label': 'Concerts', 'color': Colors.pink},
    ];

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((category) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    boxShadow: [BoxShadow(color: (category['color'] as Color).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      splashColor: (category['color'] as Color).withOpacity(0.3),
                      onTap: () => _onCategoryTap(context, category['label'] as String),
                      child: Center(child: Icon(category['icon'] as IconData, color: Colors.grey[700], size: 24)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(category['label'] as String, textAlign: TextAlign.center, 
                     style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                     maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
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
                child: Text('Nearby gems in Ho Chi Minh', 
                     style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                     overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringNearbyHeader = true),
                onExit: (_) => setState(() => _isHoveringNearbyHeader = false),
                child: GestureDetector(
                  onTap: () => _onNearbyGemsSeMoreTap(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()..scale(_isHoveringNearbyHeader ? 1.05 : 1.0),
                    child: Text('See more', style: GoogleFonts.inter(
                      color: _isHoveringNearbyHeader ? const Color(0xFF5B41FF) : const Color(0xFF7B61FF),
                      fontWeight: FontWeight.w600, fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: _isHoveringNearbyHeader ? const Color(0xFF5B41FF) : const Color(0xFF7B61FF))),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) => _buildTourCard(index),
          ),
        ),
      ],
    );
  }

  // Tour Card
  Widget _buildTourCard(int index) {
    final tours = [
      {'title': 'Ho Chi Minh City Sightseeing Double-Decker Bus', 'badge': 'Bestselling Tours', 'image': 'images/hcmc_bus_tour.jpg', 'imageColor': Colors.red[300]!},
      {'title': 'Ho Chi Minh City Skyline & River View', 'badge': 'Most saved Tours', 'image': 'images/hcmc_skyline.jpg', 'imageColor': Colors.blue[300]!},
      {'title': 'Ho Chi Minh City Street Food Tour', 'badge': 'Popular', 'image': 'images/hcmc_food_tour.jpg', 'imageColor': Colors.orange[300]!},
      {'title': 'Ho Chi Minh City Center Tour', 'badge': 'New Tour', 'image': 'images/hcmc_skyline.jpg', 'imageColor': Colors.purple[300]!},
    ];
    final tour = tours[index % tours.length];

    return Container(
      width: 200, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            child: Stack(children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildImageWithAnimation(tour['image'] as String, 140, double.infinity, tour['imageColor'] as Color)),
              Positioned(top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(tour['badge'] as String, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                  ]))),
            ]),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tour['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                     maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity,
                  child: ElevatedButton(onPressed: () {}, 
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0),
                    child: const Text('Add to plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
              ])),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: Text('Recently Viewed', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringRecentlyViewedHeader = true),
            onExit: (_) => setState(() => _isHoveringRecentlyViewedHeader = false),
            child: GestureDetector(onTap: () => _onRecentlyViewedSeeMoreTap(context),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isHoveringRecentlyViewedHeader ? 1.05 : 1.0),
                child: Text('See more', style: GoogleFonts.inter(
                  color: _isHoveringRecentlyViewedHeader ? const Color(0xFF5B41FF) : const Color(0xFF7B61FF),
                  fontWeight: FontWeight.w600, fontSize: 14, 
                  decoration: TextDecoration.underline,
                  decorationColor: _isHoveringRecentlyViewedHeader ? const Color(0xFF5B41FF) : const Color(0xFF7B61FF)))))),
        ])),
      const SizedBox(height: 12),
      SizedBox(height: 140,
        child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 2, itemBuilder: (context, index) => _buildCompactRecentCard(context, index))),
    ]);
  }

  Widget _buildRecentCard(BuildContext context, int index) {
    final recentTours = [
      {'title': 'Ho Chi Minh City Hop On Hop Off Pass', 'image': 'images/hcmc_skyline.jpg', 'color': Colors.blue[300]!},
      {'title': 'Ho Chi Minh City Sightseeing Double-Decker', 'image': 'images/hcmc_bus_tour.jpg', 'color': Colors.red[300]!},
      {'title': 'Ho Chi Minh City Food Tour', 'image': 'images/hcmc_food_tour.jpg', 'color': Colors.orange[300]!},
      {'title': 'Ho Chi Minh City Center Tour', 'image': 'images/hcmc_skyline.jpg', 'color': Colors.purple[300]!},
    ];

    return Container(width: 160, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(12),
          splashColor: (recentTours[index % recentTours.length]['color'] as Color).withOpacity(0.2),
          onTap: () => _onRecentlyViewedTap(context, recentTours[index % recentTours.length]['title'] as String),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildImageWithAnimation(recentTours[index % recentTours.length]['image'] as String, 100, double.infinity,
                recentTours[index % recentTours.length]['color'] as Color)),
            Padding(padding: const EdgeInsets.all(10),
              child: Text(recentTours[index % recentTours.length]['title'] as String,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]))));
  }

  Widget _buildCompactRecentCard(BuildContext context, int index) {
    final recentTours = [
      {'title': 'Ho Chi Minh City Sightseeing Double-Decker Bus Ticket', 'subtitle': 'Bestselling Tours', 'image': 'images/hcmc_bus_tour.jpg', 'color': Colors.red[300]!},
      {'title': 'Enjoy the great outdoor in Ho Chi Minh city with these local', 'subtitle': 'Popular', 'image': 'images/hcmc_skyline.jpg', 'color': Colors.blue[300]!},
    ];

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: (recentTours[index]['color'] as Color).withOpacity(0.2),
          hoverColor: (recentTours[index]['color'] as Color).withOpacity(0.05),
          onTap: () => _onRecentlyViewedTap(context, recentTours[index]['title'] as String),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                _buildImageWithAnimation(
                  recentTours[index]['image'] as String, 
                  140, 
                  180, 
                  recentTours[index]['color'] as Color
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7)
                      ]
                    )
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recentTours[index]['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildWhereToNextSection() {
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: Text('Where to next?', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringWhereToNextHeader = true),
            onExit: (_) => setState(() => _isHoveringWhereToNextHeader = false),
            child: GestureDetector(onTap: () => _onWhereToNextSeeMoreTap(context),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isHoveringWhereToNextHeader ? 1.05 : 1.0),
                child: Text('See more', style: GoogleFonts.inter(
                  color: _isHoveringWhereToNextHeader ? const Color(0xFF5B41FF) : const Color(0xFF7B61FF),
                  fontWeight: FontWeight.w600, fontSize: 14, 
                  decoration: TextDecoration.underline,
                  decorationColor: _isHoveringWhereToNextHeader ? const Color(0xFF5B41FF) : const Color(0xFF7B61FF)))))),
        ])),
      const SizedBox(height: 12),
      SizedBox(height: 80,
        child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3, itemBuilder: (context, index) => _buildCompactDestinationCard(context, index))),
    ]);
  }

  Widget _buildDestinationCard(BuildContext context, int index) {
    final destinations = [
      {'title': 'Da Nang', 'subtitle': 'Beach & Mountains', 'image': 'images/danang.jpg', 'color': Colors.blue[300]!},
      {'title': 'Hanoi', 'subtitle': 'Culture & History', 'image': 'images/hanoi.jpg', 'color': Colors.red[300]!},
      {'title': 'Hue', 'subtitle': 'Imperial City', 'image': 'images/hue.jpg', 'color': Colors.purple[300]!},
      {'title': 'Ho Chi Minh City', 'subtitle': 'Modern & Dynamic', 'image': 'images/hcmc_skyline.jpg', 'color': Colors.orange[300]!},
    ];
    final destination = destinations[index % destinations.length];

    return Container(width: 180, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(16), 
          onTap: () => _onWhereToNextTap(context, destination['title'] as String),
          child: Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(16),
              child: _buildImageWithAnimation(destination['image'] as String, 200, 180, destination['color'] as Color)),
            Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)]))),
            Positioned(bottom: 16, left: 16, right: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(destination['title'] as String, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(destination['subtitle'] as String, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9))),
              ])),
          ]))));
  }

  Widget _buildCompactDestinationCard(BuildContext context, int index) {
    final destinations = [
      {'title': 'Ho Chi Minh', 'image': 'images/hcmc_skyline.jpg', 'color': Colors.orange[300]!},
      {'title': 'Da Nang', 'image': 'images/danang.jpg', 'color': Colors.blue[300]!},
      {'title': 'Ha Noi', 'image': 'images/hanoi.jpg', 'color': Colors.red[300]!},
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3)
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: (destination['color'] as Color).withOpacity(0.3),
          hoverColor: (destination['color'] as Color).withOpacity(0.1),
          onTap: () => _onWhereToNextTap(context, destination['title'] as String),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImageWithAnimation(
                  destination['image'] as String, 
                  80, 
                  100, 
                  destination['color'] as Color
                )
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6)
                    ]
                  )
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  destination['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: Row(children: [
            _buildTabButton('Recommended', 0),
            const SizedBox(width: 16),
            _buildTabButton('Nearby', 1),
          ])),
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringRecommendedHeader = true),
            onExit: (_) => setState(() => _isHoveringRecommendedHeader = false),
            child: GestureDetector(onTap: () => _onRecommendedSeeMoreTap(context),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isHoveringRecommendedHeader ? 1.05 : 1.0),
                child: Text('See more', style: GoogleFonts.inter(color: _isHoveringRecommendedHeader ? const Color(0xFF5B41FF) : const Color(0xFF7B61FF),
                  fontWeight: FontWeight.w600, fontSize: 14, decoration: TextDecoration.underline))))),
        ])),
      const SizedBox(height: 16),
      _buildTabContent(),
    ]);
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _recommendedTabIndex == index;
    return GestureDetector(onTap: () => setState(() => _recommendedTabIndex = index),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[300]!)),
        child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : Colors.grey[700]))));
  }

  Widget _buildTabContent() {
    return SizedBox(height: 220,
      child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recommendedTabIndex == 0 ? 4 : 4,
        itemBuilder: (context, index) => _recommendedTabIndex == 0 ? _buildRecommendedCard(context, index) : _buildNearbyCard(context, index)));
  }

  Widget _buildRecommendedCard(BuildContext context, int index) {
    final places = [
      {'title': 'Ben Thanh Market', 'subtitle': 'Traditional Market', 'image': 'images/hcmc_food_tour.jpg', 'color': Colors.orange[300]!, 'rating': '4.5'},
      {'title': 'Saigon Skydeck', 'subtitle': 'City Views', 'image': 'images/hcmc_skyline.jpg', 'color': Colors.blue[300]!, 'rating': '4.7'},
      {'title': 'War Remnants Museum', 'subtitle': 'History & Culture', 'image': 'images/hcm_war_remmants_museum.jpg', 'color': Colors.red[300]!, 'rating': '4.6'},
      {'title': 'Independence Palace', 'subtitle': 'Historic Site', 'image': 'images/hcm_independence_palace.jpg', 'color': Colors.purple[300]!, 'rating': '4.4'},
    ];
    final place = places[index % places.length];

    return Container(width: 160, height: 200, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(12),
          onTap: () => _onRecommendedTap(context, place['title'] as String),
          child: Column(children: [
            Stack(children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildImageWithAnimation(place['image'] as String, 110, 160, place['color'] as Color)),
              Positioned(top: 6, right: 6,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star, color: Colors.yellow, size: 10),
                    const SizedBox(width: 2),
                    Text(place['rating'] as String, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ]))),
            ]),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(place['title'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                       maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(place['subtitle'] as String, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                       maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
            ),
          ]))));
  }

  Widget _buildNearbyCard(BuildContext context, int index) {
    final places = [
      {'title': 'Coffee Shop District 1', 'subtitle': 'Traditional Coffee', 'image': 'images/hcmc_food_tour.jpg', 'color': Colors.brown[300]!, 'distance': '0.5 km'},
      {'title': 'Nguyen Hue Walking Street', 'subtitle': 'City Center', 'image': 'images/hcmc_skyline.jpg', 'color': Colors.blue[300]!, 'distance': '0.8 km'},
      {'title': 'Saigon Central Post Office', 'subtitle': 'Historic Building', 'image': 'images/hcmc_bus_tour.jpg', 'color': Colors.green[300]!, 'distance': '1.2 km'},
      {'title': 'Ben Thanh Night Market', 'subtitle': 'Local Market', 'image': 'images/hcmc_food_tour.jpg', 'color': Colors.orange[300]!, 'distance': '0.3 km'},
    ];
    final place = places[index % places.length];

    return Container(width: 160, height: 200, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(12),
          splashColor: (place['color'] as Color).withOpacity(0.2),
          hoverColor: (place['color'] as Color).withOpacity(0.05),
          onTap: () => _onNearbyTap(context, place['title'] as String),
          child: Column(children: [
            Stack(children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildImageWithAnimation(place['image'] as String, 110, 160, place['color'] as Color)),
              Positioned(top: 6, right: 6,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_on, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(place['distance'] as String, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ]))),
            ]),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(place['title'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                       maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(place['subtitle'] as String, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                       maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
            ),
          ]))));
  }

  Widget _buildImageWithAnimation(String imagePath, double height, double width, Color fallbackColor) {
    return Container(height: height, width: width,
      child: Image.asset(imagePath, height: height, width: width, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: fallbackColor,
          child: Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white, size: height * 0.3)))));
  }

  // Handler methods
  void _onCategoryTap(BuildContext context, String categoryName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exploring $categoryName...'), backgroundColor: const Color(0xFF7B61FF)));
  }

  void _showSearchDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search feature coming soon!')));
  }

  void _onPlanTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening plan...'), backgroundColor: Colors.blue));
  }

  void _onNotificationTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You have 3 new notifications'), backgroundColor: Colors.orange));
  }

  void _onNearbyGemsSeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading more nearby gems...'), backgroundColor: const Color(0xFF7B61FF)));
  }

  void _onLocationPromptClose(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location prompt dismissed')));
  }

  void _onRecentlyViewedTap(BuildContext context, String tourName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $tourName...'), backgroundColor: Colors.blueAccent));
  }

  void _onRecentlyViewedSeeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading more recently viewed items...'), backgroundColor: Colors.blueAccent));
  }

  void _onWhereToNextTap(BuildContext context, String destination) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exploring $destination...'), backgroundColor: Colors.green));
  }

  void _onWhereToNextSeeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading more destinations...'), backgroundColor: Colors.green));
  }

  void _onRecommendedTap(BuildContext context, String placeName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exploring $placeName...'), backgroundColor: const Color(0xFF7B61FF)));
  }

  void _onNearbyTap(BuildContext context, String placeName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigating to $placeName...'), backgroundColor: Colors.green));
  }

  void _onRecommendedSeeMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading more ${_recommendedTabIndex == 0 ? "recommended" : "nearby"} places...'), backgroundColor: const Color(0xFF7B61FF)));
  }
}