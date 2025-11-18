import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/user_service.dart';
import 'auth_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  bool _pushNotificationEnabled = true;
  bool _emailNotificationEnabled = true;
  bool _locationServicesEnabled = true;
  bool _darkModeEnabled = true;
  
  String _currentUsername = 'User';
  String? _currentAvatarPath;
  String _displayName = 'User';
  
  @override
  bool get wantKeepAlive => false; // Don't keep alive so it refreshes
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData(); // Refresh when widget updates
  }
  
  void _loadUserData() async {
    final userService = UserService();
    final profile = userService.getUserProfile();
    final username = await userService.getDisplayName();
    
    setState(() {
      _currentUsername = username;
      _displayName = profile['fullName']?.isNotEmpty == true 
          ? profile['fullName']! 
          : username;
      _currentAvatarPath = profile['avatarPath'];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Section
              _buildProfileSection(),
              
              const SizedBox(height: 16),
              
              // Main Settings
              _buildMainSettings(),
              
              const SizedBox(height: 16),
              
              // Notification Settings
              _buildNotificationSettings(),
              
              const SizedBox(height: 16),
              
              // Privacy & Security
              _buildPrivacySettings(),
              
              const SizedBox(height: 16),
              
              // Help & Support
              _buildHelpSettings(),
              
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  /// Profile Section
  Widget _buildProfileSection() {
    return Column(
      children: [
        // Profile Avatar with horizontal line
        Stack(
          alignment: Alignment.center,
          children: [
            // Horizontal black line
            Container(
              width: double.infinity,
              height: 2,
              color: Colors.black,
            ),
            // Profile Avatar
            GestureDetector(
              onTap: () => _onProfileTap(),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: _currentAvatarPath != null
                      ? Image.file(
                          File(_currentAvatarPath!),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Display Name
        Text(
          _displayName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Build default avatar with user initial
  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF7B61FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : 'U',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Main Settings Section
  Widget _buildMainSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!, width: 1.5),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            Icons.person_outline,
            'Edit profile',
            () => _onEditProfile(),
            showArrow: true,
          ),
          _buildDivider(),
          _buildSettingsItem(
            Icons.lock_outline,
            'Change password',
            () => _onChangePassword(),
            showArrow: true,
          ),
          _buildDivider(),
          _buildSettingsItem(
            Icons.language,
            'Languages',
            () => _onLanguages(),
            showArrow: true,
          ),
          _buildDivider(),
          _buildSettingsItem(
            Icons.attach_money,
            'Currencies',
            () => _onCurrencies(),
            showArrow: true,
          ),
        ],
      ),
    );
  }

  /// Notification Settings
  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Notification',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!, width: 1.5),
          ),
          child: Column(
            children: [
              _buildToggleItem(
                Icons.notifications_outlined,
                'Push notification',
                _pushNotificationEnabled,
                (value) => setState(() => _pushNotificationEnabled = value),
              ),
              _buildDivider(),
              _buildToggleItem(
                Icons.email_outlined,
                'Email notification',
                _emailNotificationEnabled,
                (value) => setState(() => _emailNotificationEnabled = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Privacy & Security Settings
  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Privacy & Security',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!, width: 1.5),
          ),
          child: Column(
            children: [
              _buildToggleItem(
                Icons.location_on_outlined,
                'Location Services',
                _locationServicesEnabled,
                (value) => setState(() => _locationServicesEnabled = value),
              ),
              _buildDivider(),
              _buildToggleItem(
                Icons.dark_mode_outlined,
                'Dark Mode',
                _darkModeEnabled,
                (value) => setState(() => _darkModeEnabled = value),
              ),
              _buildDivider(),
              _buildSettingsItem(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                () => _onPrivacyPolicy(),
                showArrow: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Help & Support Settings
  Widget _buildHelpSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Help & Support',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!, width: 1.5),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                Icons.phone_outlined,
                'Contact Us',
                () => _onContactUs(),
                showArrow: true,
              ),
              _buildDivider(),
              _buildSettingsItem(
                Icons.help_outline,
                'FAQ',
                () => _onFAQ(),
                showArrow: true,
              ),
              _buildDivider(),
              _buildSettingsItem(
                Icons.logout,
                'Log out',
                () => _onLogout(),
                showArrow: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Settings Item Widget
  Widget _buildSettingsItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool showArrow = false,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: () => _onSettingsItemTapWithAnimation(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Toggle Item Widget
  Widget _buildToggleItem(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Switch.adaptive(
              key: ValueKey(value),
              value: value,
              onChanged: onChanged,
              activeColor: Colors.orange[600],
              activeTrackColor: Colors.orange[300],
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }

  /// Divider
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[400],
    );
  }

  // Event handlers with animations
  void _onSettingsItemTapWithAnimation(VoidCallback onTap) {
    // Add subtle animation
    setState(() {});
    Future.delayed(const Duration(milliseconds: 100), onTap);
  }

  void _onProfileTap() {
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
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Change Photo'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Opening camera...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Opening gallery...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Opening profile...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    );
    
    // Reload user data if profile was updated
    if (result == true) {
      _loadUserData();
    }
  }

  void _onChangePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Change Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Password changed!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
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
              'Select Language',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              trailing: const Icon(Icons.check, color: Colors.green),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Language changed to English');
              },
            ),
            ListTile(
              leading: const Text('🇻🇳'),
              title: const Text('Tiếng Việt'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Language changed to Vietnamese');
              },
            ),
            ListTile(
              leading: const Text('🇯🇵'),
              title: const Text('日本語'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Language changed to Japanese');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onCurrencies() {
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
              'Select Currency',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('VND (₫)'),
              trailing: const Icon(Icons.check, color: Colors.green),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Currency changed to VND');
              },
            ),
            ListTile(
              title: const Text('USD (\$)'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Currency changed to USD');
              },
            ),
            ListTile(
              title: const Text('EUR (€)'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Currency changed to EUR');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'This is a sample privacy policy content. In a real app, this would contain the actual privacy policy text with details about data collection, usage, and user rights.',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onContactUs() {
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
              'Contact Us',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@travelapp.com'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Opening email...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone Support'),
              subtitle: const Text('+84 937 877 653'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Calling support...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 24/7'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Starting live chat...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onFAQ() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'FAQ',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFAQItem(
                'How to create a travel plan?',
                'You can create a travel plan by going to the Plan tab and tapping the "+" button.',
              ),
              _buildFAQItem(
                'How to track expenses?',
                'Use the Analysis tab to view your spending patterns and add new expenses.',
              ),
              _buildFAQItem(
                'How to change language?',
                'Go to Settings > Languages to change your preferred language.',
              ),
              _buildFAQItem(
                'How to contact support?',
                'You can contact support through Settings > Help & Support > Contact Us.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
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
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
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
        content: Text(message),
        backgroundColor: const Color(0xFF7B61FF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}