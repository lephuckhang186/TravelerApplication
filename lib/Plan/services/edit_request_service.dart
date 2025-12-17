import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../Core/config/api_config.dart';
import '../models/collaboration_models.dart';

/// Service for managing edit access requests
class EditRequestService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Create a new edit access request
  Future<EditRequest> createEditRequest({
    required String tripId,
    String? message,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/edit-requests/'),
        headers: headers,
        body: jsonEncode({
          'trip_id': tripId,
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return EditRequest.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create edit request');
      }
    } catch (e) {
      // print('❌ CREATE_EDIT_REQUEST_ERROR: $e');
      rethrow;
    }
  }

  /// Get all edit requests created by current user
  Future<List<EditRequest>> getMyEditRequests({String? status}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/edit-requests/my-requests';
      if (status != null) {
        url += '?status_filter=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EditRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load edit requests');
      }
    } catch (e) {
      // print('❌ GET_MY_EDIT_REQUESTS_ERROR: $e');
      return [];
    }
  }

  /// Get pending edit requests for trips owned by current user
  Future<List<EditRequest>> getPendingApprovals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/edit-requests/pending-approvals'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EditRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pending approvals');
      }
    } catch (e) {
      // print('❌ GET_PENDING_APPROVALS_ERROR: $e');
      return [];
    }
  }

  /// Get all edit requests for a specific trip (owner only)
  Future<List<EditRequest>> getTripEditRequests({
    required String tripId,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/edit-requests/trip/$tripId';
      if (status != null) {
        url += '?status_filter=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EditRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trip edit requests');
      }
    } catch (e) {
      // print('❌ GET_TRIP_EDIT_REQUESTS_ERROR: $e');
      return [];
    }
  }

  /// Approve or reject an edit request
  Future<EditRequest> updateEditRequest({
    required String requestId,
    required EditRequestStatus status,
    bool promoteToEditor = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/edit-requests/$requestId'),
        headers: headers,
        body: jsonEncode({
          'status': status.toJson(),
          'promote_to_editor': promoteToEditor,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EditRequest.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to update edit request');
      }
    } catch (e) {
      // print('❌ UPDATE_EDIT_REQUEST_ERROR: $e');
      rethrow;
    }
  }

  /// Delete an edit request
  Future<void> deleteEditRequest(String requestId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/edit-requests/$requestId'),
        headers: headers,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete edit request');
      }
    } catch (e) {
      // print('❌ DELETE_EDIT_REQUEST_ERROR: $e');
      rethrow;
    }
  }

  /// Check if user has a pending edit request for a trip
  Future<EditRequest?> checkPendingRequest(String tripId) async {
    try {
      final requests = await getMyEditRequests(status: 'pending');
      return requests.firstWhere(
        (req) => req.tripId == tripId,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      return null;
    }
  }
}
