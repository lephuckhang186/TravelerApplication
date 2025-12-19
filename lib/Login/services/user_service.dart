import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static const String _keyUsername = 'username';
  // static const String _keyPassword = 'password'; // Removed unused field
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
  String? _currentPhone;
  String? _currentAddress;
  
  // Get current username
  String get currentUsername => _currentUsername ?? 'User';
  
  // Get user profile information
  Future<String?> getFullName() async {
    if (_currentFullName != null) return _currentFullName;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_keyFullName}_${_currentUsername ?? 'default'}');
  }
  
  Future<String?> getEmail() async {
    if (_currentEmail != null) return _currentEmail;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_keyEmail}_${_currentUsername ?? 'default'}');
  }
  
  Future<String?> getPhone() async {
    if (_currentPhone != null) return _currentPhone;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone_${_currentUsername ?? 'default'}');
  }
  
  Future<String?> getAddress() async {
    if (_currentAddress != null) return _currentAddress;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('address_${_currentUsername ?? 'default'}');
  }
  
  Future<String?> getAvatarPath() async {
    if (_currentAvatarPath != null) return _currentAvatarPath;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_keyAvatarPath}_${_currentUsername ?? 'default'}');
  }
  
  // Save user profile information
  Future<void> saveProfile({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? avatarPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _currentUsername ?? 'default';
    
    if (fullName != null) {
      _currentFullName = fullName;
      await prefs.setString('${_keyFullName}_$userKey', fullName);
    }
    if (email != null) {
      _currentEmail = email;
      await prefs.setString('${_keyEmail}_$userKey', email);
    }
    if (phone != null) {
      _currentPhone = phone;
      await prefs.setString('phone_$userKey', phone);
    }
    if (address != null) {
      _currentAddress = address;
      await prefs.setString('address_$userKey', address);
    }
    if (avatarPath != null) {
      _currentAvatarPath = avatarPath;
      await prefs.setString('${_keyAvatarPath}_$userKey', avatarPath);
    }
  }
  
  // Initialize service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString(_keyUsername);
    if (_currentUsername != null) {
      _currentAvatarPath = prefs.getString('${_keyAvatarPath}_$_currentUsername');
      _currentEmail = prefs.getString('${_keyEmail}_$_currentUsername');
      _currentFullName = prefs.getString('${_keyFullName}_$_currentUsername');
    }
    
    // Also try to load user from JSON if SharedPreferences is empty
    if (_currentUsername == null) {
      await _loadUserFromJson();
    }
  }
  
  // Load user from JSON file
  Future<void> _loadUserFromJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/users.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          final List<Map<String, dynamic>> users = jsonList.cast<Map<String, dynamic>>();
          
          // If there's at least one user, we can auto-load the last one
          // (In a real app, you'd implement proper session management)
          if (users.isNotEmpty) {
            final lastUser = users.last;
            final username = lastUser['username'] as String;
            
            // Set as current user in SharedPreferences for next login
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keyUsername, username);
            _currentUsername = username;
            
            // Load profile data if exists
            _currentAvatarPath = prefs.getString('${_keyAvatarPath}_$username');
            _currentEmail = prefs.getString('${_keyEmail}_$username');
            _currentFullName = prefs.getString('${_keyFullName}_$username');
          }
        }
      }
    } catch (e) {
      // Handle error silently
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
      final savedHashedPassword = prefs.getString('user_$username');
      if (savedHashedPassword != null && BCrypt.checkpw(password, savedHashedPassword)) {
        // Save login state
        await prefs.setString(_keyUsername, username);
        await prefs.setBool(_keyIsLoggedIn, true);
        _currentUsername = username;

        // Load user profile data
        _currentAvatarPath = prefs.getString('${_keyAvatarPath}_$username');
        _currentEmail = prefs.getString('${_keyEmail}_$username');
        _currentFullName = prefs.getString('${_keyFullName}_$username');

        // Authenticate with Firebase anonymously for Firestore access
        await _authenticateWithFirebase();

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Login user with detailed information about success/failure reason
  Future<Map<String, dynamic>> loginWithDetails(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user exists
      final savedHashedPassword = prefs.getString('user_$username');
      if (savedHashedPassword == null) {
        return {
          'success': false,
          'userExists': false,
        };
      }
      
      // Check password
      if (BCrypt.checkpw(password, savedHashedPassword)) {
        // Save login state
        await prefs.setString(_keyUsername, username);
        await prefs.setBool(_keyIsLoggedIn, true);
        _currentUsername = username;
        
        // Load user profile data
        _currentAvatarPath = prefs.getString('${_keyAvatarPath}_$username');
        _currentEmail = prefs.getString('${_keyEmail}_$username');
        _currentFullName = prefs.getString('${_keyFullName}_$username');
        
        return {
          'success': true,
          'userExists': true,
        };
      } else {
        return {
          'success': false,
          'userExists': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'userExists': false,
      };
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
  Future<String?> saveAvatarImage(dynamic imageFile) async {
    try {
      if (_currentUsername == null) return null;
      
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      
      final fileName = '${_currentUsername}_avatar.jpg';
      final savedImage = await (imageFile as File).copy('${avatarDir.path}/$fileName');
      
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
      final savedHashedPassword = prefs.getString('user_$_currentUsername');
      
      if (savedHashedPassword == null || !BCrypt.checkpw(currentPassword, savedHashedPassword)) {
        return false; // Current password is incorrect
      }
      
      // Hash new password before saving
      final newHashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await prefs.setString('user_$_currentUsername', newHashedPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Save user to JSON file
  Future<bool> saveUserToJson(String username, String passwordHash, String email) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/users.json');
      
      List<Map<String, dynamic>> users = [];
      
      // Read existing users if file exists
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          users = jsonList.cast<Map<String, dynamic>>();
        }
      }
      
      // Check if user already exists and update, otherwise add new
      final existingUserIndex = users.indexWhere((user) => user['username'] == username);
      final userData = {
        'username': username,
        'passwordHash': passwordHash,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      if (existingUserIndex >= 0) {
        users[existingUserIndex] = userData;
      } else {
        users.add(userData);
      }
      
      // Write back to file
      final jsonString = jsonEncode(users);
      await file.writeAsString(jsonString);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Update email in JSON file
  Future<bool> updateEmailInJson(String username, String email) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/users.json');

      if (!await file.exists()) {
        return false; // File doesn't exist
      }

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return false; // Empty file
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<Map<String, dynamic>> users = jsonList.cast<Map<String, dynamic>>();

      // Find and update user
      final userIndex = users.indexWhere((user) => user['username'] == username);
      if (userIndex >= 0) {
        users[userIndex]['email'] = email;
        users[userIndex]['updatedAt'] = DateTime.now().toIso8601String();

        // Write back to file
        final updatedJsonString = jsonEncode(users);
        await file.writeAsString(updatedJsonString);

        return true;
      }

      return false; // User not found
    } catch (e) {
      return false;
    }
  }

  // Authenticate with Firebase anonymously for Firestore access
  Future<void> _authenticateWithFirebase() async {
    try {
      // Check if already authenticated
      if (FirebaseAuth.instance.currentUser != null) {
        debugPrint('DEBUG: UserService - Already authenticated with Firebase');
        return;
      }

      // Sign in anonymously to get Firebase Auth context
      final credential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint('DEBUG: UserService - Authenticated with Firebase anonymously: ${credential.user?.uid}');

    } catch (e) {
      debugPrint('DEBUG: UserService - Failed to authenticate with Firebase: $e');
      // Don't throw error - collaboration features will be limited but app still works
    }
  }
}
