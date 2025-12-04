import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Core/theme/app_theme.dart';
import '../services/email_service_web.dart';

class ShareFeedbackScreen extends StatefulWidget {
  const ShareFeedbackScreen({super.key});

  @override
  State<ShareFeedbackScreen> createState() => _ShareFeedbackScreenState();
}

class _ShareFeedbackScreenState extends State<ShareFeedbackScreen> {
  String _selectedCategory = 'Tính năng mới';
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  int _rating = 5;

  final List<String> _categories = [
    'Tính năng mới',
    'Báo lỗi',
    'Cải thiện hiệu suất',
    'Giao diện người dùng',
    'Quản lý chi tiêu',
    'Lập kế hoạch du lịch',
    'Khám phá địa điểm',
    'Khác',
  ];

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
          'Chia sẻ góp ý',
          style: GoogleFonts.quattrocento(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildRatingSection(),
          const SizedBox(height: 20),
          _buildCategorySection(),
          const SizedBox(height: 20),
          _buildFeedbackSection(),
          const SizedBox(height: 20),
          _buildContactSection(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
          const SizedBox(height: 20),
          _buildQuickFeedbackOptions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.1), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.feedback,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Góp ý của bạn rất quan trọng!',
                    style: GoogleFonts.quattrocento(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Chúng tôi luôn lắng nghe và cải thiện ứng dụng để mang đến trải nghiệm du lịch tuyệt vời nhất cho bạn.',
              style: GoogleFonts.quattrocento(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đánh giá ứng dụng',
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star,
                      size: 32,
                      color: index < _rating ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingText(),
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loại góp ý',
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.quattrocento(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết góp ý',
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Hãy chia sẻ chi tiết về trải nghiệm của bạn...',
                  hintStyle: GoogleFonts.quattrocento(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.quattrocento(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin liên hệ (tùy chọn)',
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Để chúng tôi có thể phản hồi nếu cần',
              style: GoogleFonts.quattrocento(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email của bạn',
                hintStyle: GoogleFonts.quattrocento(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: GoogleFonts.quattrocento(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _feedbackController.text.isNotEmpty ? _submitFeedback : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.send, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Gửi góp ý',
            style: GoogleFonts.quattrocento(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFeedbackOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoặc liên hệ trực tiếp',
          style: GoogleFonts.quattrocento(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickContactCard(
                Icons.email,
                'Email',
                'teamtripwise@gmail.com',
                () => _openDirectEmail(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickContactCard(
                Icons.phone,
                'Hotline',
                '+84 898 999 033',
                () => _showSnackBar('Đang gọi hotline...'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickContactCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.quattrocento(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.quattrocento(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Rất không hài lòng';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
        return 'Rất hài lòng';
      default:
        return '';
    }
  }

  void _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập chi tiết góp ý trước khi gửi');
      return;
    }

    // Hiển thị loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Đang gửi góp ý...',
              style: GoogleFonts.quattrocento(),
            ),
          ],
        ),
      ),
    );

    try {
      // Gửi email (mở email client)
      final success = await EmailService.sendFeedbackEmail(
        rating: _rating,
        category: _selectedCategory,
        feedback: _feedbackController.text.trim(),
        userEmail: _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
      );

      // Đóng loading dialog
      Navigator.pop(context);

      if (success) {
        // Hiển thị dialog thành công (email client đã mở)
        _showEmailOpenedDialog();
      } else {
        // Hiển thị dialog fallback (copy content)
        _showManualEmailDialog();
      }
    } catch (e) {
      // Đóng loading dialog
      Navigator.pop(context);
      
      // Hiển thị dialog fallback
      _showManualEmailDialog();
    }
  }

  void _showEmailOpenedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(
              'Email đã mở!',
              style: GoogleFonts.quattrocento(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email client đã được mở với nội dung góp ý được điền sẵn.',
              style: GoogleFonts.quattrocento(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng kiểm tra email client và nhấn Send để gửi góp ý đến team TripWise.',
                      style: GoogleFonts.quattrocento(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualEmailDialog();
            },
            child: Text(
              'Xem nội dung',
              style: GoogleFonts.quattrocento(color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _resetForm();
              _showSnackBar('Cảm ơn bạn đã gửi góp ý! 🎉');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Hoàn thành',
              style: GoogleFonts.quattrocento(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'Mở email client',
              style: GoogleFonts.quattrocento(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Ứng dụng sẽ mở email client với nội dung góp ý đã được điền sẵn. Bạn chỉ cần nhấn Send trong email client.',
          style: GoogleFonts.quattrocento(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.quattrocento(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualEmailDialog();
            },
            child: Text(
              'Copy nội dung',
              style: GoogleFonts.quattrocento(color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Mở ứng dụng email với địa chỉ team
              final success = await EmailService.sendFeedbackEmail(
                rating: _rating,
                category: _selectedCategory,
                feedback: _feedbackController.text.trim(),
                userEmail: _emailController.text.trim().isNotEmpty 
                    ? _emailController.text.trim() 
                    : null,
              );
              if (success) {
                _showSnackBar('Đã mở email client. Vui lòng kiểm tra và gửi email.');
              } else {
                _showManualEmailDialog();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Mở Email',
              style: GoogleFonts.quattrocento(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEmailDialog() {
    final emailInfo = EmailService.getManualEmailInfo(
      _rating,
      _selectedCategory,
      _feedbackController.text.trim(),
      _emailController.text.trim().isNotEmpty 
          ? _emailController.text.trim() 
          : null,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.content_copy, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Thông tin Email',
              style: GoogleFonts.quattrocento(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nội dung email đã được copy vào clipboard. Bạn có thể paste vào email client:',
                style: GoogleFonts.quattrocento(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  emailInfo,
                  style: GoogleFonts.courierPrime(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _resetForm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Đóng',
              style: GoogleFonts.quattrocento(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _rating = 5;
      _selectedCategory = 'Tính năng mới';
      _feedbackController.clear();
      _emailController.clear();
    });
  }

  void _openDirectEmail() async {
    try {
      final success = await EmailService.sendFeedbackEmail(
        rating: _rating,
        category: 'Liên hệ trực tiếp',
        feedback: 'Người dùng muốn liên hệ trực tiếp với team',
        userEmail: _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
      );
      
      if (success) {
        _showSnackBar('Đã mở ứng dụng email để liên hệ với team');
      } else {
        _showSnackBar('Không thể mở ứng dụng email');
      }
    } catch (e) {
      _showSnackBar('Lỗi: Không thể mở email');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
