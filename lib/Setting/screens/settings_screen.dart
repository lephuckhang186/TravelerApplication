import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../Core/theme/app_theme.dart';
import '../../Login/services/user_service.dart';
import '../../Login/services/user_profile_service.dart';
import '../../Login/services/auth_service.dart';
import '../../Login/services/user_profile.dart';
import '../../Login/screens/auth_screen.dart';
import 'help_center_screen.dart';
import 'notification_settings_screen.dart';
import 'share_feedback_screen.dart';
import 'general_info_screen.dart';
import '../../Analysis/screens/analysis_screen.dart';
import 'profile_screen.dart';
import 'travel_stats_screen.dart';
import '../../Core/utils/translation/screens/translation_screen.dart';
import '../../Core/utils/currency/screens/currency_converter_screen.dart';
import '../../core/utils/weather/screens/weather_screen.dart';
import '../../core/utils/world_clock/screens/world_clock_screen.dart';
import 'change_password_screen.dart';
import '../../Login/services/firestore_statistics_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  String _currentUsername = 'Loading...';
  String? _currentAvatarPath;
  String _displayName = 'Đang tải...';
  bool _isVerified = true;
  bool _isLoading = true;

  final UserProfileService _profileService = UserProfileService();
  final AuthService _authService = AuthService();
  final FirestoreStatisticsService _statisticsService = FirestoreStatisticsService();
  UserProfile? _userProfile;
  UserTravelStats _stats = UserTravelStats.empty();

  final ScrollController _scrollController = ScrollController();
  final ScrollController _utilitiesScrollController = ScrollController();
  bool _isScrolled = false;
  int _currentUtilityIndex = 0;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
    _scrollController.addListener(_onScroll);
    _utilitiesScrollController.addListener(_onUtilitiesScroll);

    // Set up real-time listener for profile changes
    _profileService.getUserProfileStream().listen((profile) {
      if (mounted && profile != null) {
        _updateDisplayData(profile);
      }
    });

    // Set up real-time listener for statistics
    _statisticsService.getUserStatisticsStream().listen((stats) {
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    });
  }

  void _updateDisplayData(UserProfile profile) {
    final fullName = profile.fullName.trim();

    // Determine best display name
    String displayName = '';
    if (fullName.isNotEmpty) {
      displayName = fullName;
    } else {
      final currentUser = _authService.currentUser;
      displayName = currentUser?.displayName?.isNotEmpty == true
          ? currentUser!.displayName!
          : currentUser?.email?.split('@').first ?? 'User';
    }

    if (mounted) {
      setState(() {
        _displayName = displayName;
        _currentUsername = displayName;
        _currentAvatarPath = profile.profilePicture;
        _userProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _utilitiesScrollController.removeListener(_onUtilitiesScroll);
    _utilitiesScrollController.dispose();
    _statisticsService.dispose();
    super.dispose();
  }

  void _loadStatistics() {
    // Statistics will be loaded via stream listener
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

  void _onUtilitiesScroll() {
    if (!_utilitiesScrollController.hasClients) return;
    
    final scrollOffset = _utilitiesScrollController.offset;
    const itemWidth = 180.0; // Width of first item + spacing
    const itemWidth2 = 172.0; // Width of second/third/fourth items + spacing (160 + 12)
    
    int newIndex = 0;
    if (scrollOffset < itemWidth * 0.5) {
      newIndex = 0; // First item
    } else if (scrollOffset < itemWidth + itemWidth2 * 0.5) {
      newIndex = 1; // Second item
    } else {
      newIndex = 2; // Third item (covers weather & world clock)
    }
    
    if (newIndex != _currentUtilityIndex) {
      // Haptic feedback when changing utility
      HapticFeedback.selectionClick();
      
      setState(() {
        _currentUtilityIndex = newIndex;
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

        // Determine best display name
        String displayName = '';
        if (fullName.isNotEmpty) {
          displayName = fullName;
        } else if (currentUser.displayName?.isNotEmpty == true) {
          displayName = currentUser.displayName!;
        } else {
          displayName = currentUser.email?.split('@').first ?? 'User';
        }

        setState(() {
          _displayName = displayName;
          _currentUsername = displayName;
          _currentAvatarPath =
              _userProfile!.profilePicture ?? currentUser.photoURL;
          _isVerified = currentUser.emailVerified;
        });
      } else {
        // Fallback to Firebase Auth data
        setState(() {
          final fallbackName = currentUser.displayName?.isNotEmpty == true
              ? currentUser.displayName!
              : currentUser.email?.split('@').first ?? 'User';
          _displayName = fallbackName;
          _currentUsername = fallbackName;
          _currentAvatarPath = currentUser.photoURL;
          _isVerified = currentUser.emailVerified;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _setDefaultUserData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setDefaultUserData() {
    final currentUser = _authService.currentUser;
    final fallbackName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : currentUser?.email?.split('@').first ?? 'User';
    setState(() {
      _displayName = fallbackName;
      _currentUsername = fallbackName;
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
                      style: TextStyle(fontFamily: 'Urbanist-Regular', 
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

                        const SizedBox(height: 100),
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
                      ? _buildAvatarImage(_currentAvatarPath!, 100)
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
            style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
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
                      style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
                      ? _buildAvatarImage(_currentAvatarPath!, 40)
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
                  style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
        ],
      ),
    );
  }

  /// Build avatar image with proper error handling
  Widget _buildAvatarImage(String imagePath, double size) {
    try {
      // Check if it's a network URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Network image error: $error');
            return _buildDefaultAvatar(size: size);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        );
      } else {
        // Local file
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Local image error: $error');
              return _buildDefaultAvatar(size: size);
            },
          );
        } else {
          debugPrint('Local image file does not exist: $imagePath');
          return _buildDefaultAvatar(size: size);
        }
      }
    } catch (e) {
      debugPrint('Avatar image error: $e');
      return _buildDefaultAvatar(size: size);
    }
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
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Utilities Section - 3 items in 1 horizontal row
  Widget _buildUtilitiesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiện ích',
            style: TextStyle(fontFamily: 'Urbanist-Regular', 
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          // Horizontal scrollable utilities with enhanced UX
          Column(
            children: [
              SizedBox(
                height: 85, // Fixed height for the scroll area
                child: ListView(
                  controller: _utilitiesScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 8, right: 16), // Reduce left padding
                  physics: const BouncingScrollPhysics(), // iOS-style bouncing animation
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 180, // Fixed width per utility item
                      child: _buildRectangularUtilityItem(
                        Icons.currency_exchange,
                        'Chuyển đổi tiền tệ',
                        const Color(0xFFFF9800), // Orange
                        () => _onCurrencyConverter(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 160, // Fixed width per utility item
                      child: _buildRectangularUtilityItem(
                        Icons.translate,
                        'Dịch văn bản',
                        const Color(0xFF9C27B0), // Purple
                        () => _onTranslation(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 160, // Fixed width per utility item
                      child: _buildRectangularUtilityItem(
                        Icons.cloud,
                        'Thời tiết',
                        const Color(0xFF2196F3), // Blue
                        () => _onWeather(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 160, // Fixed width per utility item
                      child: _buildRectangularUtilityItem(
                        Icons.access_time,
                        'Múi giờ thế giới',
                        const Color(0xFF4CAF50), // Green
                        () => _onWorldClock(),
                      ),
                    ),
                  ],
                ),
              ),
              // Scroll indicator dots
              const SizedBox(height: 8),
              _buildScrollIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  /// Dynamic Scroll Indicator - dots showing current scroll position
  Widget _buildScrollIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dot 1 - Currency Converter
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _currentUtilityIndex == 0 ? 8 : 6,
          height: _currentUtilityIndex == 0 ? 8 : 6,
          decoration: BoxDecoration(
            color: _currentUtilityIndex == 0 
                ? const Color(0xFF7B61FF) 
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        // Dot 2 - Translation
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _currentUtilityIndex == 1 ? 8 : 6,
          height: _currentUtilityIndex == 1 ? 8 : 6,
          decoration: BoxDecoration(
            color: _currentUtilityIndex == 1 
                ? const Color(0xFF7B61FF) 
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        // Dot 3 - Weather & World Clock
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _currentUtilityIndex == 2 ? 8 : 6,
          height: _currentUtilityIndex == 2 ? 8 : 6,
          decoration: BoxDecoration(
            color: _currentUtilityIndex == 2 
                ? const Color(0xFF7B61FF) 
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ],
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
        height: 75, // Fixed height
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
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
                  fontSize: 12, // Larger font for better readability
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

  /// Travel Statistics Card with Real Data
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
                Icon(Icons.analytics, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Travel Stats',
                  style: TextStyle(fontFamily: 'Urbanist-Regular', 
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  'Show All',
                  style: TextStyle(fontFamily: 'Urbanist-Regular', 
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total Trips Section with Real Data
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
                    style: TextStyle(fontFamily: 'Urbanist-Regular', 
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stats.completedTrips.toString(),
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Chart based on real data
                  _buildTravelTimelineChart(),

                  const SizedBox(height: 16),

                  // Current year progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2024',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '2025: ${_stats.completedTrips2025} trips',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '2026',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
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

  /// Build travel timeline chart with real data
  Widget _buildTravelTimelineChart() {
    final currentYear = DateTime.now().year;
    final maxTrips = _stats.completedTrips > 0 ? _stats.completedTrips : 5;
    
    // Calculate column heights based on data
    final trips2024 = 0; // Could add this to stats if needed
    final trips2025 = _stats.completedTrips2025;
    final trips2026 = 0; // Future trips
    
    return Container(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2024 column
          Expanded(
            child: _buildTimelineColumn(
              trips2024, 
              maxTrips,
              Colors.grey[400]!,
              '24'
            ),
          ),
          const SizedBox(width: 8),
          // 2025 column (current year)
          Expanded(
            child: _buildTimelineColumn(
              trips2025,
              maxTrips, 
              Colors.blue,
              '25'
            ),
          ),
          const SizedBox(width: 8),
          // 2026 column
          Expanded(
            child: _buildTimelineColumn(
              trips2026,
              maxTrips,
              Colors.grey[300]!,
              '26'
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual timeline column
  Widget _buildTimelineColumn(int trips, int maxTrips, Color color, String year) {
    final heightPercentage = maxTrips > 0 ? (trips / maxTrips).clamp(0.0, 1.0) : 0.0;
    final minHeight = trips > 0 ? 0.2 : 0.05; // Minimum height for visibility
    final finalHeight = (heightPercentage < minHeight ? minHeight : heightPercentage);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Trip count (only show if > 0)
        Container(
          height: 16,
          alignment: Alignment.center,
          child: trips > 0 ? Text(
            trips.toString(),
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ) : null,
        ),
        // Column bar
        Container(
          width: double.infinity,
          height: 36 * finalHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            gradient: trips > 0 ? LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [color, color.withOpacity(0.7)],
            ) : null,
          ),
        ),
        const SizedBox(height: 4),
        // Year label
        Text(
          year,
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
            Icons.lock_reset_outlined,
            'Đổi mật khẩu',
            () => _onChangePassword(),
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
                style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
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

  void _onNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
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

  void _onWeather() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherScreen()),
    );
  }

  void _onWorldClock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorldClockScreen()),
    );
  }

  void _onChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Đăng xuất',
          style: TextStyle(fontFamily: 'Urbanist-Regular', fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
          style: TextStyle(fontFamily: 'Urbanist-Regular', ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(fontFamily: 'Urbanist-Regular', color: Colors.grey[600]),
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

              // Store navigator reference
              final navigator = Navigator.of(context);

              // Logout user
              final userService = UserService();
              await userService.logout();

              // Clear profile service cache
              _profileService.clearCache();

              // Close loading dialog and navigate if widget is still mounted
              if (mounted) {
                navigator.pop();

                // Navigate to auth screen
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng xuất', style: TextStyle(fontFamily: 'Urbanist-Regular', )),
          ),
        ],
      ),
    );
  }
}
