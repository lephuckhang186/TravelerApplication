import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../core/theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'auth_screen.dart';
import 'help_center_screen.dart';
import 'notification_settings_screen.dart';
import 'share_feedback_screen.dart';
import 'general_info_screen.dart';
import 'analysis_screen.dart';
import 'security_login_screen.dart';
import 'profile_screen.dart';
import 'travel_stats_screen.dart';
import '../features/translation/screens/translation_screen.dart';
import '../features/currency_converter/screens/currency_converter_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  String _currentUsername = 'Người dùng';
  String? _currentAvatarPath;
  String _displayName = 'Đang tải...';
  String _phoneNumber = '';
  String _currentLanguage = 'VI';
  bool _isVerified = true;
  bool _isLoading = true;
  
  final UserProfileService _profileService = UserProfileService();
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;

  ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController.addListener(_onScroll);
    
    // Set up real-time listener for profile changes
    _profileService.getUserProfileStream().listen((profile) {
      if (mounted && profile != null) {
        _updateDisplayData(profile);
      }
    });
  }

  void _updateDisplayData(UserProfile profile) {
    final fullName = profile.fullName.trim();
    final firstName = profile.firstName?.trim() ?? '';
    final lastName = profile.lastName?.trim() ?? '';
    
    // Determine best display name
    String displayName = '';
    if (fullName.isNotEmpty) {
      displayName = fullName;
    } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
      displayName = '$firstName $lastName'.trim();
    } else {
      displayName = 'Người dùng';
    }

    if (mounted) {
      setState(() {
        _displayName = displayName;
        _currentUsername = displayName;
        _phoneNumber = profile.phone ?? '';
        _currentAvatarPath = profile.profilePicture;
        _userProfile = profile;
      });
    }
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
    try {
      setState(() => _isLoading = true);
      
      // Get current user from Firebase Auth
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setDefaultUserData();
        return;
      }

      // Get user profile from our integrated service
      _userProfile = await _profileService.getUserProfile();
      
      if (_userProfile != null) {
        // Load real data from Firestore
        final fullName = _userProfile!.fullName.trim();
        final firstName = _userProfile!.firstName?.trim() ?? '';
        final lastName = _userProfile!.lastName?.trim() ?? '';
        
        // Determine best display name
        String displayName = '';
        if (fullName.isNotEmpty) {
          displayName = fullName;
        } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
          displayName = '$firstName $lastName'.trim();
        } else if (currentUser.displayName?.isNotEmpty == true) {
          displayName = currentUser.displayName!;
        } else {
          displayName = 'Người dùng';
        }

        setState(() {
          _displayName = displayName;
          _currentUsername = displayName;
          _phoneNumber = _userProfile!.phone ?? '';
          _currentAvatarPath = _userProfile!.profilePicture ?? currentUser.photoURL;
          _isVerified = currentUser.emailVerified;
        });
        
      } else {
        // Fallback to Firebase Auth data
        setState(() {
          _displayName = currentUser.displayName ?? 'Người dùng';
          _currentUsername = currentUser.displayName ?? 'Người dùng';
          _phoneNumber = '';
          _currentAvatarPath = currentUser.photoURL;
          _isVerified = currentUser.emailVerified;
        });
      }
      
    } catch (e) {
      print('Error loading user data: $e');
      _setDefaultUserData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setDefaultUserData() {
    setState(() {
      _displayName = 'Người dùng';
      _currentUsername = 'Người dùng';
      _phoneNumber = '';
      _currentAvatarPath = null;
      _isVerified = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải thông tin...',
                    style: GoogleFonts.quattrocento(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Stack(
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

                      // Travel Statistics Card
                      _buildTravelStatsCard(),

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
                        style: GoogleFonts.quattrocento(
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
            style: GoogleFonts.quattrocento(
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
                      style: GoogleFonts.quattrocento(
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
                  style: GoogleFonts.quattrocento(
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
          style: GoogleFonts.quattrocento(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Quick Actions Section (3 icons) - evenly spaced and balanced
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionItem(
            Icons.account_balance_wallet_outlined,
            'Quản lý\nchi tiêu',
            Colors.grey[600]!,
            null,
            () => _onExpenseManagement(),
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
                        style: GoogleFonts.quattrocento(
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
            style: GoogleFonts.quattrocento(
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
            style: GoogleFonts.quattrocento(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          // Synchronized scrolling for both rows
          SizedBox(
            height: 138, // Height for 2 rows + spacing (65 + 65 + 8)
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
                          Icons.translate,
                          'Dịch văn bản',
                          const Color(0xFF9C27B0), // Purple
                          () => _onTranslation(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row
                    Row(
                      children: [
                        _buildRectangularUtilityItem(
                          Icons.analytics,
                          'Thống kê du lịch',
                          const Color(0xFF00BCD4), // Cyan
                          () => _onTravelStats(),
                        ),
                        const SizedBox(width: 8),
                        _buildRectangularUtilityItem(
                          Icons.currency_exchange,
                          'Chuyển đổi tiền tệ',
                          const Color(0xFFFF9800), // Orange
                          () => _onCurrencyConverter(),
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
                style: GoogleFonts.quattrocento(
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

  /// Travel Statistics Card
  Widget _buildTravelStatsCard() {
    return GestureDetector(
      onTap: () => _onTravelStats(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Text(
                  'Travel Stats',
                  style: GoogleFonts.quattrocento(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  'Show All',
                  style: GoogleFonts.quattrocento(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Total Trips Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Trips',
                    style: GoogleFonts.quattrocento(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '0',
                    style: GoogleFonts.quattrocento(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Simple timeline
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: Colors.blue,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: Colors.blue,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Years
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2023',
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '2024',
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '2025',
                        style: GoogleFonts.quattrocento(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                style: GoogleFonts.quattrocento(
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
                style: GoogleFonts.quattrocento(
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
                    style: GoogleFonts.quattrocento(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentLanguage,
                    style: GoogleFonts.quattrocento(
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

  /// Action Button - Logout only
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => _onLogout(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Đăng xuất',
              textAlign: TextAlign.center,
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
          ),
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

  void _onTravelStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TravelStatsScreen()),
    );
  }

  void _onPaymentSettings() {
    // Payment settings functionality
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
    // Credit score functionality
  }

  void _onPaymentHistory() {
    // Payment history functionality  
  }

  void _onGiftCard() {
    // Gift card functionality
  }

  void _onMoreGifts() {
    // More gifts functionality
  }

  void _onFinancialCenter() {
    // Financial center functionality
  }

  void _onTranslation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TranslationScreen()),
    );
  }

  void _onCurrencyConverter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CurrencyConverterScreen()),
    );
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
              style: GoogleFonts.quattrocento(
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
                // Camera functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                // Photo library functionality
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
          style: GoogleFonts.quattrocento(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có muốn đăng nhập bằng tài khoản khác?',
          style: GoogleFonts.quattrocento(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.quattrocento(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Account switching functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
            ),
            child: Text('Đồng ý', style: GoogleFonts.quattrocento()),
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
              style: GoogleFonts.quattrocento(
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
          style: GoogleFonts.quattrocento(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
          style: GoogleFonts.quattrocento(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.quattrocento(color: Colors.grey[600]),
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
              
              // Clear profile service cache
              _profileService.clearCache();

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
            child: Text('Đăng xuất', style: GoogleFonts.quattrocento()),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    // Message display functionality
  }

}
