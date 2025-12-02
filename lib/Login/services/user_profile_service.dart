import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile.dart';
import '../services/firestore_user_service.dart';
import '../services/profile_api_service.dart';
import '../services/auth_service.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirestoreUserService _firestoreService = FirestoreUserService();
  final ProfileApiService _apiService = ProfileApiService();
  final AuthService _authService = AuthService();

  UserProfile? _cachedProfile;

  // Get user profile with fallback strategy
  Future<UserProfile?> getUserProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      // First try to get from Firestore (primary source)
      UserProfile? profile = await _firestoreService.getUserProfile(
        currentUser.uid,
      );

      if (profile == null) {
        // Fallback: try to get from backend API
        profile = await _apiService.getUserProfile();

        if (profile == null) {
          // Last resort: create from Firebase Auth data
          profile = await _createProfileFromAuthData(currentUser);
        }
      }

      _cachedProfile = profile;
      return profile;
    } catch (e) {
      print('Error getting user profile: $e');
      return _cachedProfile;
    }
  }

  // Update user profile with dual sync (Firestore + Backend)
  Future<bool> updateUserProfile({
    String? fullName,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? gender,
    DateTime? dateOfBirth,
    String? profilePicture,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Update in Firestore (primary)
      bool firestoreSuccess = true;
      try {
        await _firestoreService.updateUserProfile(
          uid: currentUser.uid,
          fullName: fullName,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          address: address,
          gender: gender,
          dateOfBirth: dateOfBirth,
          profilePicture: profilePicture,
        );
      } catch (e) {
        print('Firestore update failed: $e');
        firestoreSuccess = false;
      }

      // Update in backend API (secondary)
      bool apiSuccess = true;
      try {
        apiSuccess = await _apiService.updateUserProfile(
          fullName: fullName,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          address: address,
          gender: gender,
          dateOfBirth: dateOfBirth,
          profilePicture: profilePicture,
        );
      } catch (e) {
        print('API update failed: $e');
        apiSuccess = false;
      }

      // Clear cache if update was successful
      if (firestoreSuccess || apiSuccess) {
        _cachedProfile = null;
      }

      // Return true if at least one update succeeded
      return firestoreSuccess || apiSuccess;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Update a specific field
  Future<bool> updateField(String field, dynamic value) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Update in Firestore
      bool success = true;
      try {
        await _firestoreService.updateUserField(
          uid: currentUser.uid,
          field: field,
          value: value,
        );
      } catch (e) {
        print('Firestore field update failed: $e');
        success = false;
      }

      // Also try to update via API
      try {
        await _apiService.updateField(field, value);
      } catch (e) {
        print('API field update failed: $e');
      }

      // Clear cache
      if (success) {
        _cachedProfile = null;
      }

      return success;
    } catch (e) {
      print('Error updating field $field: $e');
      return false;
    }
  }

  // Sync user data after login
  Future<void> syncAfterLogin() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Sync with backend
      await _apiService.syncUserData(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: currentUser.displayName,
        photoUrl: currentUser.photoURL,
      );

      // Ensure user has a profile in Firestore
      final profile = await _firestoreService.getUserProfile(currentUser.uid);
      if (profile == null) {
        await _createProfileFromAuthData(currentUser);
      }
    } catch (e) {
      print('Error syncing after login: $e');
    }
  }

  // Create profile from Firebase Auth data
  Future<UserProfile?> _createProfileFromAuthData(User user) async {
    try {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName ?? 'Người dùng mới',
        createdAt: now,
        updatedAt: now,
        profilePicture: user.photoURL,
        firstName: _extractFirstName(user.displayName),
        lastName: _extractLastName(user.displayName),
      );

      await _firestoreService.createOrUpdateUser(profile);
      return profile;
    } catch (e) {
      print('Error creating profile from auth data: $e');
      return null;
    }
  }

  // Get real-time profile stream
  Stream<UserProfile?> getUserProfileStream() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestoreService.getUserProfileStream(currentUser.uid);
  }

  // Clear cached profile
  void clearCache() {
    _cachedProfile = null;
  }

  // Extract first name from full name
  String? _extractFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return null;
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }

  // Extract last name from full name
  String? _extractLastName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return null;
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : null;
  }
}
