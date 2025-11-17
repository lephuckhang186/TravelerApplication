import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  File? _selectedImage;
  String? _currentAvatarPath;
  String _currentUsername = '';
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final userService = UserService();
    final profile = userService.getUserProfile();
    
    setState(() {
      _currentUsername = profile['username'] ?? '';
      _fullNameController.text = profile['fullName'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _currentAvatarPath = profile['avatarPath'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              _buildAvatarSection(),
              
              const SizedBox(height: 32),
              
              // Profile Information
              _buildProfileSection(),
              
              const SizedBox(height: 24),
              
              // Password Change Section
              _buildPasswordSection(),
              
              const SizedBox(height: 32),
              
              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Text(
          'Avatar',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(color: const Color(0xFF7B61FF), width: 3),
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : _currentAvatarPath != null
                      ? Image.file(
                          File(_currentAvatarPath!),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Text(
            'Change profile picture',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7B61FF),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF7B61FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF7B61FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : 'U',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cá nhân',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Username (read-only)
          TextFormField(
            initialValue: _currentUsername,
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Tên đăng nhập',
              prefixIcon: const Icon(Icons.person, color: Color(0xFF7B61FF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
          
          const SizedBox(height: 16),
          
          // Full Name
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên',
              prefixIcon: const Icon(Icons.badge, color: Color(0xFF7B61FF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 16),
          ),
          
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email, color: Color(0xFF7B61FF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 16),
            validator: (value) {
              if (value != null && value.isNotEmpty && !value.contains('@')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thay đổi mật khẩu (tùy chọn)',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Để trống nếu không muốn thay đổi mật khẩu',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
            const SizedBox(height: 16),
            
            // Current Password
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF7B61FF)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 16),
              validator: (value) {
                // Only validate if user is trying to change password
                if (_isPasswordChangeAttempted() && (value?.isEmpty ?? true)) {
                  return 'Vui lòng nhập mật khẩu hiện tại';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // New Password
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7B61FF)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 16),
              validator: (value) {
                if (_isPasswordChangeAttempted()) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value!.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_clock, color: Color(0xFF7B61FF)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 16),
              validator: (value) {
                if (_isPasswordChangeAttempted()) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng xác nhận mật khẩu mới';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                }
                return null;
              },
            ),
        ]
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Lưu thay đổi',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Check if user is attempting to change password
  bool _isPasswordChangeAttempted() {
    return _currentPasswordController.text.isNotEmpty || 
           _newPasswordController.text.isNotEmpty || 
           _confirmPasswordController.text.isNotEmpty;
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn ảnh đại diện',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF7B61FF)),
              title: Text('Chụp ảnh', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF7B61FF)),
              title: Text('Chọn từ thư viện', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_currentAvatarPath != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa ảnh đại diện', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _currentAvatarPath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi chọn ảnh'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      
      // Save avatar if changed
      String? newAvatarPath;
      if (_selectedImage != null) {
        newAvatarPath = await userService.saveAvatarImage(_selectedImage!);
      } else if (_currentAvatarPath == null) {
        newAvatarPath = null; // User deleted avatar
      } else {
        newAvatarPath = _currentAvatarPath; // Keep current avatar
      }
      
      // Update profile
      bool profileSuccess = await userService.updateProfile(
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        avatarPath: newAvatarPath,
      );
      
      // Change password if requested
      bool passwordSuccess = true;
      if (_isPasswordChangeAttempted()) {
        passwordSuccess = await userService.changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
      }
      
      if (profileSuccess && passwordSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật profile thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (!passwordSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu hiện tại không đúng'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi cập nhật profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra, vui lòng thử lại'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}