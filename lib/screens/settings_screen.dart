import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../core/theme/app_theme.dart';
import '../services/user_service.dart';
import 'auth_screen.dart';
import 'help_center_screen.dart';
import 'notification_settings_screen.dart';
import 'share_feedback_screen.dart';
import 'general_info_screen.dart';
import 'analysis_screen.dart';
import 'security_login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  String _currentUsername = 'Nguyễn Kiều Anh Quân';
  String? _currentAvatarPath;
  String _displayName = 'Nguyễn Kiều Anh Quân';
  String _phoneNumber = '0898999033';
  String _currentLanguage = 'VI';
  bool _isVerified = true;

  ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const scrollThreshold = 100.0;
    if (_scrollController.offset > scrollThreshold && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= scrollThreshold && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData();
  }

  void _loadUserData() async {
    final userService = UserService();
    final profile = userService.getUserProfile();
    final username = await userService.getDisplayName();

    setState(() {
      _currentUsername = username.isNotEmpty
          ? username
          : 'Nguyễn Kiều Anh Quân';
      _displayName = profile['fullName']?.isNotEmpty == true
          ? profile['fullName']!
          : _currentUsername;
      _currentAvatarPath = profile['avatarPath'];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Main scroll content
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Header section (shows when not scrolled)
                  if (!_isScrolled) _buildFullHeaderSection(),
                  if (_isScrolled)
                    const SizedBox(height: 56), // Space for pinned header

                  const SizedBox(height: 12),

                  // Quick Actions (4 icons)
                  _buildQuickActions(),

                  const SizedBox(height: 12),

                  // Utilities Section
                  _buildUtilitiesSection(),

                  const SizedBox(height: 12),

                  // Expense Management Card
                  _buildExpenseCard(),

                  const SizedBox(height: 12),

                  // Settings Menu
                  _buildSettingsMenu(),

                  const SizedBox(height: 12),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Pinned header when scrolled
            if (_isScrolled) _buildCompactHeader(),
          ],
        ),
      ),
    );
  }

  /// Full Header Section (tôi1.jpg - when at top)
  Widget _buildFullHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(color: Color(0xFFF5F7FA)),
      child: Column(
        children: [
          // Top right "Đổi ảnh nền" button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _onChangeBackground,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đổi ảnh nền',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Centered Profile Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child: _currentAvatarPath != null
                      ? Image.file(
                          File(_currentAvatarPath!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              // Verified badge
              if (_isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 15),

          // Centered Name
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // Centered Name only (removed phone and biometric status)
          const SizedBox(),

          const SizedBox(height: 20),

          // QR Code section
          Container(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Trang cá nhân',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[600],
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

  /// Compact Header (tôi2.jpg - when scrolled)
  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          // Small Avatar
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: ClipOval(
                  child: _currentAvatarPath != null
                      ? Image.file(
                          File(_currentAvatarPath!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(size: 40);
                          },
                        )
                      : _buildDefaultAvatar(size: 40),
                ),
              ),
              // Verified badge
              if (_isVerified)
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 10),

          // Name and Status in horizontal layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),

          // Right side - simplified buttons
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
            ),
          ),

          const SizedBox(width: 4),


          // "Đổi ảnh nền" button
          GestureDetector(
            onTap: _onChangeBackground,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.palette_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build default avatar with user initial
  Widget _buildDefaultAvatar({double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF7B61FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : 'N',
          style: GoogleFonts.inter(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Quick Actions Section (4 icons) - matching tôi1.jpg
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            spreadRadius: 1,
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionItem(
            Icons.account_balance_wallet_outlined,
            'Quản lý',
            Colors.grey[600]!,
            null,
            () => _onExpenseManagement(),
          ),
          _buildQuickActionItem(
            Icons.settings_outlined,
            'Cài đặt\nthanh toán',
            Colors.grey[600]!,
            null,
            () => _onPaymentSettings(),
          ),
          _buildQuickActionItem(
            Icons.lock_outline,
            'Đăng nhập\nvà bảo mật',
            Colors.grey[600]!,
            null,
            () => _onSecuritySettings(),
          ),
          _buildQuickActionItem(
            Icons.notifications_outlined,
            'Cài đặt\nthông báo',
            Colors.grey[600]!,
            null,
            () => _onNotificationSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String label,
    Color iconColor,
    String? badge,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              if (badge != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Utilities Section - 2 horizontal rows with synchronized scrolling
  Widget _buildUtilitiesSection() {
    final ScrollController scrollController = ScrollController();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiện ích',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          // Synchronized scrolling for both rows
          SizedBox(
            height: 138, // Height for 2 rows + spacing
            child: ListView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                Column(
                  children: [
                    // First row
                    Row(
                      children: [
                        _buildRectangularUtilityItem(
                          Icons.monetization_on,
                          'Trung Tâm Tài Chính',
                          const Color(0xFF2196F3), // Blue
                          () => _onFinancialCenter(),
                        ),
                        const SizedBox(width: 8),
                        _buildRectangularUtilityItem(
                          Icons.receipt_long,
                          'Thanh Toán Nhanh',
                          const Color(0xFF00BCD4), // Cyan
                          () => _onPaymentHistory(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row
                    Row(
                      children: [
                        _buildRectangularUtilityItem(
                          Icons.account_balance_wallet,
                          'Quản lý chi tiêu',
                          const Color(0xFF00BCD4), // Cyan
                          () => _onExpenseManagement(),
                        ),
                        const SizedBox(width: 8),
                        _buildRectangularUtilityItem(
                          Icons.redeem,
                          'Quà của tôi',
                          const Color(0xFF8BC34A), // Green
                          () => _onMoreGifts(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16), // End padding
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Rectangular Utility Item - icon at top left, text below
  Widget _buildRectangularUtilityItem(
    IconData icon,
    String label,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, // Rectangular width
        height: 65,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon at top left
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 6), // Reduced spacing
            // Text below icon - using Flexible instead of Expanded
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10, // Slightly smaller font
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.2, // Line height for better spacing
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Expense Management Card
  Widget _buildExpenseCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý chi tiêu',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Tháng này',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
            ],
          ),

          const SizedBox(height: 8),

          // Expense Summary Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.06),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng chi',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '113.045đ',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 10,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '389.955đ',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Cùng kỳ tháng trước',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.06),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xem biến động thu chi',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '100% Nhận xu',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 lần/SĐT',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Settings Menu
  Widget _buildSettingsMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            spreadRadius: 1,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuListItem(
            Icons.help_center_outlined,
            'Trung tâm trợ giúp',
            () => _onHelpCenter(),
          ),
          _buildMenuDivider(),
          _buildMenuListItem(
            Icons.notifications_outlined,
            'Cài đặt thông báo',
            () => _onNotificationSettings(),
          ),
          _buildMenuDivider(),
          _buildMenuListItem(
            Icons.share_outlined,
            'Chia sẻ góp ý',
            () => _onShareFeedback(),
          ),
          _buildMenuDivider(),
          _buildMenuListItem(
            Icons.info_outline,
            'Thông tin chung',
            () => _onGeneralInfo(),
          ),
          _buildMenuDivider(),
          _buildMenuListItem(
            Icons.palette_outlined,
            'Đổi hình nền',
            () => _onChangeBackground(),
          ),
          _buildMenuDivider(),
          _buildLanguageItem(),
        ],
      ),
    );
  }

  Widget _buildMenuListItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem() {
    return GestureDetector(
      onTap: () => _onLanguages(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.language_outlined, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                'Ngôn ngữ',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EN',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentLanguage,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
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

  Widget _buildMenuDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.grey[200],
    );
  }

  /// Action Buttons - Combined logout and switch account with vertical divider
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onLogout(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Đăng xuất',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            // Vertical divider
            Container(width: 1, height: 24, color: Colors.grey[300]),
            Expanded(
              child: GestureDetector(
                onTap: () => _onSwitchAccount(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Đổi tài khoản',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers for new design
  void _onExpenseManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisScreen()),
    );
  }

  void _onPaymentSettings() {
    _showMessage('Mở cài đặt thanh toán...');
  }

  void _onSecuritySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityLoginScreen()),
    );
  }

  void _onNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
    );
  }

  void _onHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
    );
  }

  void _onShareFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShareFeedbackScreen()),
    );
  }

  void _onGeneralInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GeneralInfoScreen()),
    );
  }

  // New utility handlers
  void _onCreditScore() {
    _showMessage('Mở điểm tín cậy...');
  }

  void _onPaymentHistory() {
    _showMessage('Mở lịch sử thanh toán...');
  }

  void _onGiftCard() {
    _showMessage('Mở quà tặng...');
  }

  void _onMoreGifts() {
    _showMessage('Mở thêm quà tặng...');
  }

  void _onFinancialCenter() {
    _showMessage('Trung tâm tài chính đang được phát triển...');
  }

  void _onChangeBackground() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn ảnh nền',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Đang mở camera...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Đang mở thư viện ảnh...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onSwitchAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Đổi tài khoản',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có muốn đăng nhập bằng tài khoản khác?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Đang chuyển tài khoản...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
            ),
            child: Text('Đồng ý', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _onLanguages() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn ngôn ngữ',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              trailing: _currentLanguage == 'EN'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _currentLanguage = 'EN';
                });
                Navigator.pop(context);
                _showMessage('Đã chuyển sang tiếng Anh');
              },
            ),
            ListTile(
              leading: const Text('🇻🇳'),
              title: const Text('Tiếng Việt'),
              trailing: _currentLanguage == 'VI'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _currentLanguage = 'VI';
                });
                Navigator.pop(context);
                _showMessage('Đã chuyển sang tiếng Việt');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // Logout user
              final userService = UserService();
              await userService.logout();

              // Close loading dialog
              Navigator.pop(context);

              // Navigate to auth screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng xuất', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
