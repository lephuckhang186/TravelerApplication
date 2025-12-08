import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../Core/config/api_config.dart';
import '../../Login/services/user_profile.dart';
import 'package:flutter/foundation.dart';

class ProfileApiService {
  static const String _baseUrl = ApiConfig.baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get authorization header with Firebase token
  Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get user profile from backend
  Future<UserProfile?> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromMap(data);
      } else if (response.statusCode == 404) {
        return null; // Profile not found
      } else {
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile on backend
  Future<bool> updateUserProfile({
    String? fullName,
    String? phone,
    String? address,
    String? gender,
    DateTime? dateOfBirth,
    String? profilePicture,
  }) async {
    try {
      final headers = await _getHeaders();

      final updateData = <String, dynamic>{};
      if (fullName != null) {
        updateData['full_name'] = fullName;
      }
      if (phone != null) {
        updateData['phone'] = phone;
      }
      if (address != null) {
        updateData['address'] = address;
      }
      if (gender != null) {
        updateData['gender'] = gender;
      }
      if (dateOfBirth != null) {
        updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (profilePicture != null) {
        updateData['profile_picture'] = profilePicture;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Profile update failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Sync user data with backend (called after login)
  Future<bool> syncUserData({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final headers = await _getHeaders();

      final syncData = {
        'uid': uid,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/sync-user'),
        headers: headers,
        body: json.encode(syncData),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error syncing user data: $e');
      return false;
    }
  }

  // Update a specific field
  Future<bool> updateField(String field, dynamic value) async {
    switch (field) {
      case 'fullName':
        return updateUserProfile(fullName: value);
      case 'phone':
        return updateUserProfile(phone: value);
      case 'address':
        return updateUserProfile(address: value);
      case 'gender':
        return updateUserProfile(gender: value);
      case 'dateOfBirth':
        return updateUserProfile(dateOfBirth: value);
      default:
        return false;
    }
  }
}
