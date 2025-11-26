import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class PlannerDetailScreen extends StatefulWidget {
  final String plannerName;
  final String destination;

  const PlannerDetailScreen({
    super.key,
    required this.plannerName,
    required this.destination,
  });

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  // Sample data theo mẫu design
  final List<Map<String, dynamic>> _activities = [
    {
      'time': '8:00',
      'title': 'SFO - JFK',
      'subtitle':
          'Confirmation: DL1234\nTerminal 2, Gate C8, Seat 19B\nArrive: 11:30AM',
      'icon': Icons.flight_takeoff,
      'color': const Color(0xFF4CAF50),
    },
    {
      'time': '12:00',
      'title': 'Having lunch (Ngũ Phát Lộc)',
      'subtitle':
          'Ăn trưa với món bún đậu mắm tôm đặc sản của người dân Hà Nội',
      'icon': Icons.restaurant,
      'color': const Color(0xFF2196F3),
    },
    {
      'time': '13:30',
      'title': 'Tham quan nhà tù Hoả lò',
      'subtitle': 'Tìm hiểu về một phần lịch sử hào hùng của Việt Nam',
      'icon': Icons.location_on,
      'color': const Color(0xFF2196F3),
    },
    {
      'time': '',
      'title': 'Khám phá dao quanh khu phố cổ',
      'subtitle':
          'Khám phá các con phố nghề truyền thống (Hàng Mã, Hàng Gai, Hàng Bạc)',
      'icon': Icons.explore,
      'color': const Color(0xFF9C27B0),
    },
    {
      'time': '',
      'title': 'Cà phê trứng tại Vinh',
      'subtitle':
          'Thưởng thức các tách cà phê nóng hổi trong bầu trời chiều Hà Nội',
      'icon': Icons.local_cafe,
      'color': const Color(0xFF795548),
    },
    {
      'time': '17:00',
      'title': 'Having dinner (Đông Xuân)',
      'subtitle':
          'Thưởng thức dim thác đường phố tại Chợ đêm Đông Xuân (nếu là cuối tuần) hoặc các quán ăn vặt nổi tiếng như nem chua ran, nem bò khô',
      'icon': Icons.dinner_dining,
      'color': const Color(0xFF2196F3),
    },
    {
      'time': '',
      'title': 'Giải trí về đêm',
      'subtitle':
          'Xem Múa rối nước tại Nhà hát Múa rối Thăng Long (về không có 100,000 - 150,000 VND/người) để tôi nghiệm nghề thuật truyền thống',
      'icon': Icons.theater_comedy,
      'color': const Color(0xFF9C27B0),
    },
    {
      'time': '21:00',
      'title': 'Trở về khách sạn',
      'subtitle':
          'Nghỉ ngơi & khách sạn hoặc đi dao gần khách sạn chuẩn bị cho chuyến đi ngày hôm sau',
      'icon': Icons.hotel,
      'color': const Color(0xFF607D8B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              'Riêng tư',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header với thông tin trip
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: AssetImage('images/danang.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIÊU ĐỀ',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '25 Nov 2025 - 27 Nov 2025',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade200,
            child: Text(
              'TUESDAY, 25 NOVEMBER 2025',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Timeline Activities
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _activities.length + 1, // +1 for next day header
              itemBuilder: (context, index) {
                if (index == _activities.length) {
                  // Next day header
                  return Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'WEDNESDAY, 26 NOVEMBER 2025',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }

                return _buildTimelineItem(_activities[index], index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActivityModal(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> activity, int index) {
    bool hasTime = activity['time'].isNotEmpty;
    bool isLast = index == _activities.length - 1;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: hasTime
                ? Text(
                    activity['time'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  )
                : const SizedBox(),
          ),

          // Timeline Line & Icon
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activity['color'],
                  shape: BoxShape.circle,
                ),
                child: Icon(activity['icon'], color: Colors.white, size: 20),
              ),
              if (!isLast)
                Container(width: 2, height: 60, color: AppColors.primary),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['subtitle'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddActivityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddActivitySheet(),
    );
  }

  Widget _buildAddActivitySheet() {
    final categories = [
      {
        'title': 'Restaurant',
        'icon': Icons.restaurant,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Activity',
        'icon': Icons.local_activity,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Flight',
        'icon': Icons.flight,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Lodging',
        'icon': Icons.hotel,
        'color': const Color(0xFF2196F3),
      },
      {'title': 'Tour', 'icon': Icons.tour, 'color': const Color(0xFF2196F3)},
      {
        'title': 'Car Rental',
        'icon': Icons.car_rental,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Concert',
        'icon': Icons.music_note,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Cruise',
        'icon': Icons.directions_boat,
        'color': const Color(0xFF2196F3),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                'Add a Plan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 60), // Balance the cancel button
            ],
          ),
          const SizedBox(height: 20),

          // Previously Used Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'PREVIOUSLY USED',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          _buildCategoryItem('Restaurant', Icons.restaurant),
          _buildCategoryItem('Activity', Icons.local_activity),

          const SizedBox(height: 20),

          // Most Popular Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'MOST POPULAR',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          _buildCategoryItem('Flight', Icons.flight),
          _buildCategoryItem('Lodging', Icons.hotel),
          _buildCategoryItem('Tour', Icons.tour),

          const SizedBox(height: 20),

          // More Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'MORE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          _buildCategoryItem('Car Rental', Icons.car_rental),
          _buildCategoryItem('Concert', Icons.music_note),
          _buildCategoryItem('Cruise', Icons.directions_boat),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _addNewActivity(title, icon);
      },
    );
  }

  void _addNewActivity(String type, IconData icon) {
    // Add new activity logic
    setState(() {
      _activities.add({
        'time': '',
        'title': 'New $type',
        'subtitle': 'Tap to add details...',
        'icon': icon,
        'color': AppColors.primary,
      });
    });
  }

  void _showMoreOptions() {
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
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Trip'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Trip'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outlined),
              title: const Text('Delete Trip'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
