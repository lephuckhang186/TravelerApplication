import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../Core/config/api_config.dart';
import '../models/collaboration_models.dart';
import '../models/activity_models.dart';

/// Service for managing activity edit requests
class ActivityEditRequestService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Flag to enable/disable mock responses when backend is not available
  static const bool useMockData = false;

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

  /// Create a new activity edit request
  Future<ActivityEditRequest> createActivityEditRequest({
    required String tripId,
    required String requestType, // 'edit_activity', 'add_activity', 'delete_activity'
    String? activityId,
    Map<String, dynamic>? proposedChanges,
    String? message,
    String? activityTitle,
  }) async {
    try {
      final headers = await _getHeaders();
      final user = FirebaseAuth.instance.currentUser!;

      final response = await http.post(
        Uri.parse('$baseUrl/activity-edit-requests/'),
        headers: headers,
        body: jsonEncode({
          'trip_id': tripId,
          'request_type': requestType,
          'activity_id': activityId,
          'proposed_changes': proposedChanges,
          'message': message,
          'activity_title': activityTitle,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ActivityEditRequest.fromJson(data);
      } else {
        final errorBody = response.body;
        print('❌ API Error - Status: ${response.statusCode}, Body: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          throw Exception(error['detail'] ?? 'Failed to create activity edit request');
        } catch (jsonError) {
          throw Exception('Failed to create activity edit request: HTTP ${response.statusCode} - $errorBody');
        }
      }
    } catch (e) {
      // Log error only if it's not a network error (to avoid spam)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('failed to fetch') &&
          !errorString.contains('clientexception') &&
          !errorString.contains('connection')) {
        print('❌ CREATE_ACTIVITY_EDIT_REQUEST_ERROR: $e');
      }

      // Return mock response if backend is not available
      if (useMockData) {
        return _createMockActivityEditRequest(
          tripId: tripId,
          requestType: requestType,
          activityId: activityId,
          proposedChanges: proposedChanges,
          message: message,
          activityTitle: activityTitle,
        );
      }
      rethrow;
    }
  }

  /// Create mock activity edit request when backend is not available
  ActivityEditRequest _createMockActivityEditRequest({
    required String tripId,
    required String requestType,
    String? activityId,
    Map<String, dynamic>? proposedChanges,
    String? message,
    String? activityTitle,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    return ActivityEditRequest(
      id: 'mock_${now.millisecondsSinceEpoch}',
      tripId: tripId,
      requesterId: user?.uid ?? 'mock_user',
      requesterName: user?.displayName ?? user?.email ?? 'Mock User',
      requesterEmail: user?.email ?? 'mock@example.com',
      ownerId: 'mock_owner', // Mock owner ID - in real scenario would be actual owner
      requestType: requestType,
      activityId: activityId,
      proposedChanges: proposedChanges,
      status: ActivityEditRequestStatus.pending,
      requestedAt: now,
      message: message,
      activityTitle: activityTitle ?? 'Mock Activity',
    );
  }

  /// Get all activity edit requests created by current user
  Future<List<ActivityEditRequest>> getMyActivityEditRequests({String? status}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/activity-edit-requests/my-requests';
      if (status != null) {
        url += '?status_filter=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ActivityEditRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load activity edit requests');
      }
    } catch (e) {
      print('❌ GET_MY_ACTIVITY_EDIT_REQUESTS_ERROR: $e');
      return [];
    }
  }

  /// Get pending activity edit requests for trips owned by current user
  Future<List<ActivityEditRequest>> getPendingActivityEditApprovals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/activity-edit-requests/pending-approvals'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ActivityEditRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pending activity edit approvals');
      }
    } catch (e) {
      print('❌ GET_PENDING_ACTIVITY_EDIT_APPROVALS_ERROR: $e');
      // Return mock data if backend is not available
      if (useMockData) {
        return _getMockPendingApprovals();
      }
      return [];
    }
  }

  /// Create mock pending approvals when backend is not available
  /// Note: This will be called from getPendingActivityEditApprovals
  /// but we need to know the current tripId. For now, we'll return mock data
  /// that would be filtered by the widget
  List<ActivityEditRequest> _getMockPendingApprovals() {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    return [
      ActivityEditRequest(
        id: 'mock_approval_1',
        tripId: 'pNSLXzxkwTOJxoKEQF8Y', // Use the current trip ID from logs
        requesterId: 'mock_editor_1',
        requesterName: 'John Editor',
        requesterEmail: 'john@example.com',
        ownerId: user?.uid ?? 'mock_owner',
        requestType: 'add_activity',
        proposedChanges: {'title': 'Visit Eiffel Tower', 'description': 'Iconic landmark'},
        status: ActivityEditRequestStatus.pending,
        requestedAt: now.subtract(const Duration(hours: 2)),
        message: 'Request to add a new activity to the Paris trip',
        tripTitle: 'Paris Adventure',
        activityTitle: 'Visit Eiffel Tower',
      ),
      ActivityEditRequest(
        id: 'mock_approval_2',
        tripId: 'pNSLXzxkwTOJxoKEQF8Y', // Use the current trip ID
        requesterId: 'mock_editor_2',
        requesterName: 'Jane Contributor',
        requesterEmail: 'jane@example.com',
        ownerId: user?.uid ?? 'mock_owner',
        requestType: 'permission_change',
        status: ActivityEditRequestStatus.pending,
        requestedAt: now.subtract(const Duration(hours: 1)),
        message: 'Request to become an editor for this trip',
        tripTitle: 'Paris Adventure',
      ),
    ];
  }

  /// Get all activity edit requests for a specific trip (owner only)
  Future<List<ActivityEditRequest>> getTripActivityEditRequests({
    required String tripId,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/activity-edit-requests/trip/$tripId';
      if (status != null) {
        url += '?status_filter=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ActivityEditRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trip activity edit requests');
      }
    } catch (e) {
      print('❌ GET_TRIP_ACTIVITY_EDIT_REQUESTS_ERROR: $e');
      return [];
    }
  }

  /// Approve or reject an activity edit request
  Future<ActivityEditRequest> updateActivityEditRequest({
    required String requestId,
    required ActivityEditRequestStatus status,
    String? message,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/activity-edit-requests/$requestId'),
        headers: headers,
        body: jsonEncode({
          'status': status.toJson(),
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivityEditRequest.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to update activity edit request');
      }
    } catch (e) {
      print('❌ UPDATE_ACTIVITY_EDIT_REQUEST_ERROR: $e');
      // Return mock updated request if backend is not available
      if (useMockData) {
        return _createMockUpdatedRequest(requestId, status, message);
      }
      rethrow;
    }
  }

  /// Create mock updated request when backend is not available
  ActivityEditRequest _createMockUpdatedRequest(
    String requestId,
    ActivityEditRequestStatus status,
    String? message,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    // Find the mock request and update it
    final mockApprovals = _getMockPendingApprovals();
    final originalRequest = mockApprovals.firstWhere(
      (req) => req.id == requestId,
      orElse: () => mockApprovals.first, // Fallback to first mock
    );

    return ActivityEditRequest(
      id: requestId,
      tripId: originalRequest.tripId,
      requesterId: originalRequest.requesterId,
      requesterName: originalRequest.requesterName,
      requesterEmail: originalRequest.requesterEmail,
      ownerId: originalRequest.ownerId,
      requestType: originalRequest.requestType,
      activityId: originalRequest.activityId,
      proposedChanges: originalRequest.proposedChanges,
      status: status,
      requestedAt: originalRequest.requestedAt,
      respondedAt: now,
      respondedBy: user?.uid ?? 'mock_owner',
      message: message ?? originalRequest.message,
      tripTitle: originalRequest.tripTitle,
      activityTitle: originalRequest.activityTitle,
    );
  }

  /// Delete an activity edit request
  Future<void> deleteActivityEditRequest(String requestId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/activity-edit-requests/$requestId'),
        headers: headers,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete activity edit request');
      }
    } catch (e) {
      print('❌ DELETE_ACTIVITY_EDIT_REQUEST_ERROR: $e');
      rethrow;
    }
  }

  /// Check if user has a pending activity edit request for a specific activity
  Future<ActivityEditRequest?> checkPendingActivityEditRequest(String tripId, String activityId) async {
    try {
      final requests = await getMyActivityEditRequests(status: 'pending');
      return requests.firstWhere(
        (req) => req.tripId == tripId && req.activityId == activityId && req.isPending,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Helper method to create edit request for editing an activity
  Future<ActivityEditRequest> createEditActivityRequest({
    required String tripId,
    required ActivityModel activity,
    required Map<String, dynamic> proposedChanges,
    String? message,
  }) async {
    return createActivityEditRequest(
      tripId: tripId,
      requestType: 'edit_activity',
      activityId: activity.id,
      proposedChanges: proposedChanges,
      message: message,
      activityTitle: activity.title,
    );
  }

  /// Helper method to create request for adding an activity
  Future<ActivityEditRequest> createAddActivityRequest({
    required String tripId,
    required Map<String, dynamic> proposedActivityData,
    String? message,
  }) async {
    return createActivityEditRequest(
      tripId: tripId,
      requestType: 'add_activity',
      proposedChanges: proposedActivityData,
      message: message,
      activityTitle: proposedActivityData['title'],
    );
  }

  /// Helper method to create request for deleting an activity
  Future<ActivityEditRequest> createDeleteActivityRequest({
    required String tripId,
    required ActivityModel activity,
    String? message,
  }) async {
    return createActivityEditRequest(
      tripId: tripId,
      requestType: 'delete_activity',
      activityId: activity.id,
      message: message,
      activityTitle: activity.title,
    );
  }
}
