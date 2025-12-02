import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class SecurityLoginScreen extends StatefulWidget {
  const SecurityLoginScreen({super.key});

  @override
  State<SecurityLoginScreen> createState() => _SecurityLoginScreenState();
}

class _SecurityLoginScreenState extends State<SecurityLoginScreen> {
  // Removed biometric settings as requested
  bool _loginNotifications = true;
  String _lastLogin = '15/01/2024 - 14:30';

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
          'Đăng nhập và bảo mật',
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
          _buildSecurityOverviewCard(),
          const SizedBox(height: 16),
          _buildLoginHistorySection(),
          const SizedBox(height: 16),
          _buildPasswordSection(),
          const SizedBox(height: 16),
          _buildPrivacySection(),
        ],
      ),
    );
  }

  Widget _buildSecurityOverviewCard() {
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
                  child: const Icon(Icons.security, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bảo mật tài khoản',
                        style: GoogleFonts.quattrocento(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Quản lý cài đặt bảo mật cho tài khoản',
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tài khoản được bảo vệ tốt',
                    style: GoogleFonts.quattrocento(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
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

  // Biometric section removed as requested


  Widget _buildLoginHistorySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lịch sử đăng nhập',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Lần đăng nhập cuối', _lastLogin),
            const SizedBox(height: 8),
            _buildInfoRow('Thiết bị', 'iPhone 14 Pro'),
            const SizedBox(height: 8),
            _buildInfoRow('Vị trí', 'Hà Nội, Việt Nam'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _viewLoginHistory,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Xem lịch sử',
                      style: GoogleFonts.quattrocento(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _logoutAllDevices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Đăng xuất tất cả',
                      style: GoogleFonts.quattrocento(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vpn_key, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mật khẩu & Khóa',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              'Đổi mật khẩu',
              'Cập nhật mật khẩu đăng nhập',
              Icons.lock_reset,
              _changePassword,
            ),
            _buildActionItem(
              'Tạo mã PIN',
              'Thiết lập mã PIN 6 số',
              Icons.pin,
              _setupPIN,
            ),
            _buildActionItem(
              'Khóa ứng dụng',
              'Cài đặt khóa bảo mật ứng dụng',
              Icons.app_blocking,
              _setupAppLock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quyền riêng tư',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              'Thông báo đăng nhập',
              'Nhận thông báo khi có đăng nhập mới',
              _loginNotifications,
              (value) => setState(() => _loginNotifications = value),
              icon: Icons.notifications,
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              'Quyền ứng dụng',
              'Quản lý quyền truy cập dữ liệu',
              Icons.admin_panel_settings,
              _managePermissions,
            ),
            _buildActionItem(
              'Xóa dữ liệu',
              'Xóa toàn bộ dữ liệu cá nhân',
              Icons.delete_forever,
              _deleteData,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.quattrocento(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive ? Colors.red : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quattrocento(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.quattrocento(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: GoogleFonts.quattrocento(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.quattrocento(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }


  void _viewLoginHistory() {
    _showSnackBar('Đang tải lịch sử đăng nhập...');
  }

  void _logoutAllDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi tất cả thiết bị?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Đã đăng xuất khỏi tất cả thiết bị');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    _showSnackBar('Đang mở trang đổi mật khẩu...');
  }

  void _setupPIN() {
    _showSnackBar('Đang thiết lập mã PIN...');
  }

  void _setupAppLock() {
    _showSnackBar('Đang cài đặt khóa ứng dụng...');
  }

  void _managePermissions() {
    _showSnackBar('Đang mở cài đặt quyền...');
  }

  void _deleteData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cảnh báo', style: TextStyle(color: Colors.red)),
        content: Text('Hành động này sẽ xóa toàn bộ dữ liệu và không thể khôi phục. Bạn có chắc chắn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Tính năng đang được phát triển...');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
}
