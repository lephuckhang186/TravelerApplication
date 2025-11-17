import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserService {
  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password';
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyAvatarPath = 'avatarPath';
  static const String _keyEmail = 'email';
  static const String _keyFullName = 'fullName';
  
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();
  
  String? _currentUsername;
  String? _currentAvatarPath;
  String? _currentEmail;
  String? _currentFullName;
  
  // Get current username
  String get currentUsername => _currentUsername ?? 'User';
  
  // Initialize service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString(_keyUsername);
    if (_currentUsername != null) {
      _currentAvatarPath = prefs.getString('${_keyAvatarPath}_$_currentUsername');
      _currentEmail = prefs.getString('${_keyEmail}_$_currentUsername');
      _currentFullName = prefs.getString('${_keyFullName}_$_currentUsername');
    }
  }
  
  // Register user
  Future<bool> register(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if username already exists
      final existingPassword = prefs.getString('user_$username');
      if (existingPassword != null) {
        return false; // Username already exists
      }
      
      // Save user credentials
      await prefs.setString('user_$username', password);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Login user
  Future<bool> login(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check credentials
      final savedPassword = prefs.getString('user_$username');
      if (savedPassword == password) {
        // Save login state
        await prefs.setString(_keyUsername, username);
        await prefs.setBool(_keyIsLoggedIn, true);
        _currentUsername = username;
        
        // Load user profile data
        _currentAvatarPath = prefs.getString('${_keyAvatarPath}_$username');
        _currentEmail = prefs.getString('${_keyEmail}_$username');
        _currentFullName = prefs.getString('${_keyFullName}_$username');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUsername);
      await prefs.setBool(_keyIsLoggedIn, false);
      _currentUsername = null;
      _currentAvatarPath = null;
      _currentEmail = null;
      _currentFullName = null;
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Get username for display (fallback to 'User' if not logged in)
  Future<String> getDisplayName() async {
    if (_currentUsername != null) {
      return _currentUsername!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    if (username != null) {
      _currentUsername = username;
      return username;
    }
    
    return 'User';
  }
  
  // Reset password (simplified version - in real app would send email)
  Future<bool> resetPassword(String username, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if username exists
      final savedPassword = prefs.getString('user_$username');
      if (savedPassword == null) {
        return false; // Username doesn't exist
      }
      
      // Update password
      await prefs.setString('user_$username', newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Update profile
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? avatarPath,
  }) async {
    try {
      if (_currentUsername == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      
      if (fullName != null) {
        await prefs.setString('${_keyFullName}_$_currentUsername', fullName);
        _currentFullName = fullName;
      }
      
      if (email != null) {
        await prefs.setString('${_keyEmail}_$_currentUsername', email);
        _currentEmail = email;
      }
      
      if (avatarPath != null) {
        await prefs.setString('${_keyAvatarPath}_$_currentUsername', avatarPath);
        _currentAvatarPath = avatarPath;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Save avatar image to app directory
  Future<String?> saveAvatarImage(File imageFile) async {
    try {
      if (_currentUsername == null) return null;
      
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      
      final fileName = '${_currentUsername}_avatar.jpg';
      final savedImage = await imageFile.copy('${avatarDir.path}/$fileName');
      
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }
  
  // Get user profile data
  Map<String, String?> getUserProfile() {
    return {
      'username': _currentUsername,
      'fullName': _currentFullName,
      'email': _currentEmail,
      'avatarPath': _currentAvatarPath,
    };
  }
  
  // Get avatar path
  String? get avatarPath => _currentAvatarPath;
  
  // Get email
  String? get email => _currentEmail;
  
  // Get full name
  String? get fullName => _currentFullName;
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUsername == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('user_$_currentUsername');
      
      if (savedPassword != currentPassword) {
        return false; // Current password is incorrect
      }
      
      await prefs.setString('user_$_currentUsername', newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
}