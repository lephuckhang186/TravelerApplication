import 'package:firebase_auth/firebase_auth.dart';
import '../../Login/services/user_profile.dart';
import 'firestore_user_service.dart';
import 'profile_api_service.dart';
import 'auth_service.dart';

/// Service for managing user profiles with multi-source synchronization.
///
/// Orchestrates data retrieval and updates between:
/// 1. Firestore (Primary, real-time)
/// 2. Backend API (Secondary, relational data)
/// 3. Firebase Auth (Fallback for basic info)
///
/// Implements a read-through cache strategy.
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();

  /// Factory constructor for singleton instance.
  factory UserProfileService() => _instance;

  UserProfileService._internal();

  final FirestoreUserService _firestoreService = FirestoreUserService();
  final ProfileApiService _apiService = ProfileApiService();
  final AuthService _authService = AuthService();

  UserProfile? _cachedProfile;

  /// Retrieves the current user's profile using a fallback strategy.
  ///
  /// Order of precedence:
  /// 1. Firestore
  /// 2. Backend API
  /// 3. Firebase Auth metadata (creats new profile if needed)
  ///
  /// Caches the result for subsequent calls.
  Future<UserProfile?> getUserProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      // First try to get from Firestore (primary source)
      UserProfile? profile = await _firestoreService.getUserProfile(
        currentUser.uid,
      );

      // Fallback: try to get from backend API
      profile ??= await _apiService.getUserProfile();

      // Last resort: create from Firebase Auth data
      profile ??= await _createProfileFromAuthData(currentUser);

      _cachedProfile = profile;
      return profile;
    } catch (e) {
      return _cachedProfile;
    }
  }

  /// Updates the user profile across both Firestore and the Backend API.
  ///
  /// Returns `true` if update succeeded in at least one system.
  /// Clears local cache on success.
  Future<bool> updateUserProfile({
    String? fullName,
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
          phone: phone,
          address: address,
          gender: gender,
          dateOfBirth: dateOfBirth,
          profilePicture: profilePicture,
        );
      } catch (e) {
        firestoreSuccess = false;
      }

      // Update in backend API (secondary)
      bool apiSuccess = true;
      try {
        apiSuccess = await _apiService.updateUserProfile(
          fullName: fullName,
          phone: phone,
          address: address,
          gender: gender,
          dateOfBirth: dateOfBirth,
          profilePicture: profilePicture,
        );
      } catch (e) {
        apiSuccess = false;
      }

      // Clear cache if update was successful
      if (firestoreSuccess || apiSuccess) {
        _cachedProfile = null;
      }

      // Return true if at least one update succeeded
      return firestoreSuccess || apiSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Updates a specific field in the user profile.
  ///
  /// Primarily updates Firestore, with a best-effort attempt to update the API.
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
        success = false;
      }

      // Also try to update via API
      try {
        await _apiService.updateField(field, value);
      } catch (e) {
        // Fail silently for API, as long as Firestore works
      }

      // Clear cache
      if (success) {
        _cachedProfile = null;
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Syncs user data from Firebase Auth to backend systems after login.
  ///
  /// Creates a Firestore profile if one doesn't exist.
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
      // Fail silently
    }
  }

  /// Creates a new [UserProfile] based on [User] data from Firebase Auth.
  Future<UserProfile?> _createProfileFromAuthData(User user) async {
    try {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName?.isNotEmpty == true
            ? user.displayName!
            : user.email?.split('@').first ?? 'User',
        createdAt: now,
        updatedAt: now,
        profilePicture: user.photoURL,
      );

      await _firestoreService.createOrUpdateUser(profile);
      return profile;
    } catch (e) {
      //
      return null;
    }
  }

  /// Returns a real-time stream of the user's profile from Firestore.
  Stream<UserProfile?> getUserProfileStream() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestoreService.getUserProfileStream(currentUser.uid);
  }

  /// Manually clears the local profile cache.
  void clearCache() {
    _cachedProfile = null;
  }
}
