import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/world_clock_provider.dart';
import '../models/world_clock_models.dart';
import '../services/world_clock_service.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorldClockProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Múi giờ thế giới',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7B61FF),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF7B61FF),
            labelStyle: const TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Yêu thích'),
              Tab(text: 'Tất cả'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Consumer<WorldClockProvider>(
                builder: (context, provider, child) {
                  return TextField(
                    controller: _searchController,
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm thành phố...',
                      hintStyle: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        color: Colors.grey[500],
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: provider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                provider.clearSearch();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7B61FF)),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  );
                },
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFavoritesTab(),
                  _buildAllCitiesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer<WorldClockProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final favoriteData = provider.favoriteWorldClockData;

        if (favoriteData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có múi giờ yêu thích',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thêm múi giờ vào danh sách yêu thích\nđể theo dõi dễ dàng hơn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteData.length,
          itemBuilder: (context, index) {
            final clockData = favoriteData[index];
            return _buildClockCard(clockData, provider, isFavorite: true);
          },
        );
      },
    );
  }

  Widget _buildAllCitiesTab() {
    return Consumer<WorldClockProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final clockData = provider.filteredWorldClockData;

        if (clockData.isEmpty && provider.searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy kết quả',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thử tìm kiếm với từ khóa khác',
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clockData.length,
          itemBuilder: (context, index) {
            final clock = clockData[index];
            return _buildClockCard(clock, provider);
          },
        );
      },
    );
  }

  Widget _buildClockCard(WorldClockData clockData, WorldClockProvider provider,
      {bool isFavorite = false}) {
    final isDark = !clockData.isDayTime;
    final timeDiff = WorldClockService.getTimeDifferenceFromVietnam(clockData.timeZone);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E),
                    ]
                  : [
                      const Color(0xFF6DD5FA),
                      const Color(0xFF2980B9),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Flag and city info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            clockData.timeZone.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clockData.timeZone.name,
                                  style: const TextStyle(
                                    fontFamily: 'Urbanist-Regular',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  clockData.timeZone.country,
                                  style: TextStyle(
                                    fontFamily: 'Urbanist-Regular',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Time difference
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeDiff,
                          style: const TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Time and date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      clockData.formattedTime24,
                      style: const TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${clockData.dayOfWeek}, ${clockData.formattedDate}',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Day/Night indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          clockData.isDayTime ? Icons.wb_sunny : Icons.nights_stay,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          clockData.isDayTime ? 'Ngày' : 'Đêm',
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Favorite button
                IconButton(
                  onPressed: () {
                    provider.toggleFavorite(clockData.timeZone);
                  },
                  icon: Icon(
                    provider.isFavorite(clockData.timeZone)
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: provider.isFavorite(clockData.timeZone)
                        ? Colors.red[300]
                        : Colors.white.withOpacity(0.8),
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
}