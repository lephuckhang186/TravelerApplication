import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Core/theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _helpCategories = [
    {
      'title': 'Bắt đầu sử dụng',
      'icon': Icons.rocket_launch,
      'color': Colors.purple,
      'items': [
        {
          'question': 'Ứng dụng có những tính năng gì?',
          'answer':
              'Ứng dụng có 3 tab chính:\n• Plan: Lập kế hoạch du lịch, tìm kiếm địa điểm, sử dụng AI Assistant\n• Analysis: Quản lý chi tiêu, xem báo cáo tài chính\n• Setting: Cài đặt tài khoản, tiện ích, hỗ trợ',
        },
        {
          'question': 'Làm thế nào để điều hướng trong ứng dụng?',
          'answer':
              'Sử dụng thanh điều hướng dưới cùng để chuyển đổi giữa 3 tab chính. Mỗi tab có các tính năng và màn hình con riêng biệt.',
        },
        {
          'question': 'Tôi nên bắt đầu từ đâu?',
          'answer':
              'Khuyến nghị bắt đầu từ tab "Plan" để tạo kế hoạch du lịch đầu tiên. Sau đó sử dụng tab "Analysis" để theo dõi chi phí và tab "Setting" để tùy chỉnh ứng dụng.',
        },
      ],
    },
    {
      'title': 'Lập kế hoạch du lịch',
      'icon': Icons.event_note,
      'color': Colors.blue,
      'items': [
        {
          'question': 'Cách tạo một kế hoạch du lịch mới?',
          'answer':
              'Vào tab "Plan" → nhấn nút "+" → nhập tên chuyến đi, thời gian, số người tham gia → chọn "Lưu". Bạn có thể thêm hoạt động, địa điểm, và ghi chú vào kế hoạch của mình.',
        },
        {
          'question': 'Có thể chia sẻ kế hoạch với bạn bè không?',
          'answer':
              'Có! Mở kế hoạch → nhấn nút "Chia sẻ" → chọn cách chia sẻ (link, email, mạng xã hội). Bạn bè có thể xem và đóng góp ý kiến cho kế hoạch của bạn.',
        },
        {
          'question': 'Làm thế nào để AI hỗ trợ lập kế hoạch?',
          'answer':
              'Sử dụng tính năng AI Assistant bằng cách nhấn vào khung chat "Ask, chat, plan trip with AI...". AI sẽ gợi ý lịch trình, hoạt động phù hợp dựa trên sở thích và ngân sách của bạn.',
        },
      ],
    },
    {
      'title': 'Quản lý chi tiêu',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
      'items': [
        {
          'question': 'Cách theo dõi chi phí trong chuyến đi?',
          'answer':
              'Vào tab "Analysis" → "Quản lý chi tiêu" → nhấn "+" để thêm khoản chi. Bạn có thể phân loại theo: ăn uống, di chuyển, lưu trú, mua sắm, giải trí.',
        },
        {
          'question': 'Có thể đặt ngân sách cho chuyến đi không?',
          'answer':
              'Có! Khi tạo kế hoạch mới, bạn có thể đặt ngân sách tổng. Ứng dụng sẽ theo dõi và cảnh báo khi chi tiêu gần đạt giới hạn đã đặt.',
        },
        {
          'question': 'Xem báo cáo chi tiêu như thế nào?',
          'answer':
              'Tab "Analysis" hiển thị biểu đồ chi tiêu theo danh mục, so sánh với tháng trước, và xu hướng chi tiêu. Bạn có thể export báo cáo dạng PDF hoặc Excel.',
        },
      ],
    },
    {
      'title': 'Tài khoản & Bảo mật',
      'icon': Icons.account_circle,
      'color': Colors.orange,
      'items': [
        {
          'question': 'Cách thay đổi thông tin cá nhân?',
          'answer':
              'Vào tab "Setting" → nhấn vào "Trang cá nhân" hoặc avatar của bạn. Tại đây bạn có thể cập nhật tên, ảnh đại diện, và thông tin liên hệ.',
        },
        {
          'question': 'Dữ liệu của tôi có an toàn không?',
          'answer':
              'Chúng tôi sử dụng mã hóa SSL và lưu trữ dữ liệu trên server bảo mật. Thông tin cá nhân không được chia sẻ với bên thứ ba mà không có sự đồng ý của bạn.',
        },
        {
          'question': 'Các tiện ích trong Setting có gì?',
          'answer':
              'Tab Setting cung cấp nhiều tiện ích hữu ích:\n• Chuyển đổi tiền tệ\n• Dịch văn bản\n• Quản lý chi tiêu\n• Travel Stats\n• Cài đặt thông báo\n• Thay đổi mật khẩu',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _helpCategories;

    return _helpCategories
        .map((category) {
          final filteredItems = category['items']
              .where(
                (item) =>
                    item['question'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    item['answer'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

          if (filteredItems.isEmpty) return null;

          return {...category, 'items': filteredItems};
        })
        .where((category) => category != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trung tâm trợ giúp',
          style: GoogleFonts.quattrocento(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm câu hỏi...',
                  hintStyle: GoogleFonts.quattrocento(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.quattrocento(fontSize: 14),
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category['icon'], color: category['color'], size: 24),
        ),
        title: Text(
          category['title'],
          style: GoogleFonts.quattrocento(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${category['items'].length} câu hỏi',
          style: GoogleFonts.quattrocento(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: (category['items'] as List)
            .map<Widget>(
              (item) => _buildQuestionItem(item['question'], item['answer']),
            )
            .toList(),
      ),
    );
  }

  Widget _buildQuestionItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.quattrocento(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: GoogleFonts.quattrocento(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
