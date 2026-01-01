import 'package:flutter/material.dart';
import '../../Core/theme/app_theme.dart';
import '../services/email_service_web.dart';

/// Interactive form allowing users to submit feedback and ratings for the TripWise app.
class ShareFeedbackScreen extends StatefulWidget {
  const ShareFeedbackScreen({super.key});

  @override
  State<ShareFeedbackScreen> createState() => _ShareFeedbackScreenState();
}

class _ShareFeedbackScreenState extends State<ShareFeedbackScreen> {
  String _selectedCategory = 'New Feature';
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  int _rating = 5;

  final List<String> _categories = [
    'New Feature',
    'Bug Report',
    'Performance Improvement',
    'User Interface',
    'Expense Management',
    'Travel Planning',
    'Location Discovery',
    'Other',
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
          'Share Feedback',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
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
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.surface,
            ],
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
                    'Your feedback is very important!',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
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
              'We always listen and improve the app to bring you the best travel experience.',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
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
              'Rate the App',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
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
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
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
              'Feedback Type',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
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
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
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
              'Feedback Details',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
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
                  hintText: 'Please share details about your experience...',
                  hintStyle: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(fontFamily: 'Urbanist-Regular', fontSize: 14),
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
              'Contact Information (Optional)',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'So we can respond if needed',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Your email',
                hintStyle: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  color: Colors.grey[500],
                ),
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
              style: TextStyle(fontFamily: 'Urbanist-Regular', fontSize: 14),
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
            'Send Feedback',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
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
          'Or contact directly',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
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
                () => _showSnackBar('Calling hotline...'),
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
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
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
        return 'Very Dissatisfied';
      case 2:
        return 'Dissatisfied';
      case 3:
        return 'Neutral';
      case 4:
        return 'Satisfied';
      case 5:
        return 'Very Satisfied';
      default:
        return '';
    }
  }

  void _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Please enter feedback details before sending');
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
              'Sending feedback...',
              style: TextStyle(fontFamily: 'Urbanist-Regular'),
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
      if (!mounted) return;
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
      if (!mounted) return;
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
              'Email opened!',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email client has been opened with feedback content pre-filled.',
              style: TextStyle(fontFamily: 'Urbanist-Regular'),
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
                      'Please check your email client and press Send to submit feedback to the TripWise team.',
                      style: TextStyle(
                        fontFamily: 'Urbanist-Regular',
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
              'View Content',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                color: AppColors.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _resetForm();
              _showSnackBar('Thank you for your feedback! 🎉');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Complete',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                color: Colors.white,
              ),
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
              'Email Information',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email content has been copied to clipboard. You can paste it into your email client:',
                style: TextStyle(fontFamily: 'Urbanist-Regular'),
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
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 12,
                  ),
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
              'Close',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _rating = 5;
      _selectedCategory = 'New Feature';
      _feedbackController.clear();
      _emailController.clear();
    });
  }

  void _openDirectEmail() async {
    try {
      final success = await EmailService.sendFeedbackEmail(
        rating: _rating,
        category: 'Direct Contact',
        feedback: 'User wants to contact the team directly',
        userEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      if (success) {
        _showSnackBar('Email app opened to contact the team');
      } else {
        _showSnackBar('Cannot open email app');
      }
    } catch (e) {
      _showSnackBar('Error: Cannot open email');
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
