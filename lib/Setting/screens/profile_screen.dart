import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../../Core/theme/app_theme.dart';
import '../../Login/services/user_service.dart';
import '../../Login/services/firestore_user_service.dart';
import '../../Login/services/auth_service.dart';
import '../../Login/services/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FirestoreUserService _firestoreService = FirestoreUserService();
  final AuthService _authService = AuthService();

  String? _avatarPath;
  String _gender = 'Chưa cập nhật';
  DateTime _birthDate = DateTime(1990, 1, 1);
  bool _isEditing = false;
  bool _isLoading = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
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

      // Try to get user profile from Firestore
      try {
        _userProfile = await _firestoreService.getUserProfile(currentUser.uid);
      } catch (firestoreError) {
        debugPrint('Firestore error: $firestoreError');
        _userProfile = null;
      }

      if (_userProfile != null) {
        // Load data from Firestore
        _nameController.text = _userProfile!.fullName.isNotEmpty
            ? _userProfile!.fullName
            : (currentUser.displayName?.isNotEmpty == true 
                ? currentUser.displayName! 
                : currentUser.email?.split('@').first ?? 'User');
        _emailController.text = _userProfile!.email;
        _phoneController.text = _userProfile!.phone ?? '';
        _addressController.text = _userProfile!.address ?? '';
        _gender = _userProfile!.gender ?? 'Chưa cập nhật';
        _birthDate = _userProfile!.dateOfBirth ?? DateTime(1990, 1, 1);
        _avatarPath = _userProfile!.profilePicture ?? currentUser.photoURL;
      } else {
        // Fallback to using Firebase Auth data for Google users
        _nameController.text = currentUser.displayName?.isNotEmpty == true
            ? currentUser.displayName!
            : currentUser.email?.split('@').first ?? 'User';
        _emailController.text = currentUser.email ?? '';
        _phoneController.text = '';
        _addressController.text = '';
        _gender = 'Chưa cập nhật';
        _birthDate = DateTime(1990, 1, 1);
        _avatarPath = currentUser.photoURL;

        // Create initial profile in Firestore if user has basic info
        if (currentUser.displayName?.isNotEmpty == true || currentUser.email?.isNotEmpty == true) {
          final displayName = currentUser.displayName?.isNotEmpty == true
              ? currentUser.displayName!
              : currentUser.email?.split('@').first ?? 'User';
          try {
            await _createInitialProfile(
              currentUser.uid,
              currentUser.email ?? '',
              displayName,
            );
          } catch (createError) {
            debugPrint('Error creating initial profile: $createError');
            // Không ném lỗi, vẫn hiển thị thông tin từ Firebase Auth
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _setDefaultUserData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createInitialProfile(
    String uid,
    String email,
    String displayName,
  ) async {
    try {
      final now = DateTime.now();
      final userProfile = UserProfile(
        uid: uid,
        email: email,
        fullName: displayName,
        createdAt: now,
        updatedAt: now,
      );
      await _firestoreService.createOrUpdateUser(userProfile);
      _userProfile = userProfile;
    } catch (e) {
      debugPrint('Error creating initial profile: $e');
    }
  }

  void _setDefaultUserData() {
    // Set meaningful default data instead of empty fields
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final fallbackName = currentUser.displayName?.isNotEmpty == true
          ? currentUser.displayName!
          : currentUser.email?.split('@').first ?? 'User';
      _nameController.text = fallbackName;
      _emailController.text = currentUser.email ?? 'user@example.com';
      _phoneController.text = '';
      _addressController.text = '';
      _gender = 'Chưa cập nhật';
      _birthDate = DateTime(1995, 1, 1);
      _avatarPath = currentUser.photoURL;
    } else {
      // Fallback when no user is authenticated
      _nameController.text = 'User';
      _emailController.text = 'user@example.com';
      _phoneController.text = '';
      _addressController.text = '';
      _gender = 'Chưa cập nhật';
      _birthDate = DateTime(1995, 1, 1);
      _avatarPath = null;
    }
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Họ và tên':
        return 'Nhập họ và tên của bạn';
      case 'Email':
        return 'Nhập địa chỉ email';
      case 'Số điện thoại':
        return 'Nhập số điện thoại';
      case 'Địa chỉ':
        return 'Nhập địa chỉ của bạn';
      default:
        return 'Chưa cập nhật';
    }
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
          'Trang cá nhân',
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
              ),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(),
                const SizedBox(height: 16),
                _buildContactInfoSection(),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
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
                    child: _avatarPath != null
                        ? _avatarPath!.startsWith('http')
                            ? Image.network(
                                _avatarPath!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar();
                                },
                              )
                            : Image.file(
                                File(_avatarPath!),
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
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeAvatar,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'User',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _emailController.text.isNotEmpty
                  ? _emailController.text
                  : 'Chưa cập nhật email',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 14,
                color: _emailController.text.isNotEmpty
                    ? Colors.grey[600]
                    : Colors.grey[400],
                fontStyle: _emailController.text.isNotEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Tài khoản đã xác thực',
                    style: TextStyle(fontFamily: 'Urbanist-Regular', 
                      fontSize: 12,
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

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFF40E0D0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _nameController.text.isNotEmpty
              ? _nameController.text[0].toUpperCase()
              : 'N',
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(fontFamily: 'Urbanist-Regular', 
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              'Họ và tên',
              _nameController,
              Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildGenderSelector(),
            const SizedBox(height: 12),
            _buildDateSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Thông tin liên hệ',
                  style: TextStyle(fontFamily: 'Urbanist-Regular', 
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              'Email',
              _emailController,
              Icons.email_outlined,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              'Số điện thoại',
              _phoneController,
              Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              'Địa chỉ',
              _addressController,
              Icons.location_on_outlined,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: _isEditing,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
            hintText: _getHintText(label),
            hintStyle: TextStyle(fontFamily: 'Urbanist-Regular', 
              fontSize: 14,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: TextStyle(fontFamily: 'Urbanist-Regular', fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới tính',
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _isEditing ? _showGenderPicker : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: _isEditing ? Colors.white : Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 12),
                Text(
                  _gender,
                  style: TextStyle(fontFamily: 'Urbanist-Regular', 
                    fontSize: 14,
                    color: _gender == 'Chưa cập nhật'
                        ? Colors.grey[400]
                        : Colors.black87,
                    fontStyle: _gender == 'Chưa cập nhật'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày sinh',
          style: TextStyle(fontFamily: 'Urbanist-Regular', 
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _isEditing ? _showDatePicker : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: _isEditing ? Colors.white : Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 12),
                Text(
                  '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                  style: TextStyle(fontFamily: 'Urbanist-Regular', fontSize: 14),
                ),
                const Spacer(),
                if (_isEditing)
                  Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }


  void _toggleEditMode() {
    if (_isEditing) {
      _saveProfile();
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showSnackBar('Lỗi: Người dùng chưa đăng nhập');
        return;
      }

      // Update Firestore with new data
      await _firestoreService.updateUserProfile(
        uid: currentUser.uid,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gender: _gender,
        dateOfBirth: _birthDate,
        profilePicture: _avatarPath,
      );

      // Also save to local UserService for backward compatibility
      final userService = UserService();
      await userService.saveProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        avatarPath: _avatarPath,
      );

      _showSnackBar('Đã lưu thông tin cá nhân');
    } catch (e) {
      debugPrint('Error saving profile: $e');
      _showSnackBar('Lỗi khi lưu thông tin: $e');
    }
  }

  void _changeAvatar() {
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
              'Thay đổi ảnh đại diện',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
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
                _showSnackBar('Đang mở camera...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Đang mở thư viện ảnh...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker() {
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
              'Chọn giới tính',
              style: TextStyle(fontFamily: 'Urbanist-Regular', 
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...['Nam', 'Nữ', 'Khác', 'Chưa cập nhật']
                .map(
                  (gender) => ListTile(
                    title: Text(gender),
                    trailing: _gender == gender
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() => _gender = gender);
                      Navigator.pop(context);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
