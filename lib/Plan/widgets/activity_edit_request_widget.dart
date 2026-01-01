import 'package:flutter/material.dart';
import 'dart:async';
import '../models/collaboration_models.dart';
import '../services/activity_edit_request_service.dart';
import 'activity_edit_request_approval_dialog.dart';

/// Interactive badge widget that displays the count of pending activity edit requests.
///
/// Periodically polls the [ActivityEditRequestService] to update the badge
/// and provides an entry point to the [ActivityEditRequestApprovalDialog].
class ActivityEditRequestWidget extends StatefulWidget {
  /// The ID of the trip to monitor for edit requests.
  final String tripId;

  const ActivityEditRequestWidget({super.key, required this.tripId});

  @override
  State<ActivityEditRequestWidget> createState() =>
      _ActivityEditRequestWidgetState();
}

class _ActivityEditRequestWidgetState extends State<ActivityEditRequestWidget> {
  List<ActivityEditRequest>? _cachedRequests;
  bool _isLoading = false;
  bool _hasInitialized = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load requests on init to show badge immediately
    _loadRequestsForBadge();
    // Start real-time refresh timer
    _startRealTimeRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.pending_actions,
            color: _hasPendingRequests ? Colors.orange : Colors.black,
            size: 24,
          ),
          onPressed: _showActivityEditRequestsDialog,
          tooltip: 'Activity Requests',
        ),
        if (_hasPendingRequests)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_pendingRequestCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Whether there are any pending requests for the current trip.
  bool get _hasPendingRequests => _pendingRequestCount > 0;

  /// Retrieves the current count of pending requests for the specified trip.
  int get _pendingRequestCount {
    if (_cachedRequests == null) return 0;
    return _cachedRequests!.where((req) => req.tripId == widget.tripId).length;
  }

  /// Starts a periodic timer to poll for new edit requests every 5 seconds.
  void _startRealTimeRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;

      try {
        final allRequests = await ActivityEditRequestService()
            .getPendingActivityEditApprovals();
        final previousCount = _pendingRequestCount;
        final newCount = allRequests
            .where((req) => req.tripId == widget.tripId)
            .length;

        if (previousCount != newCount) {
          if (mounted) {
            setState(() {
              _cachedRequests = allRequests;
            });
          }
        }
      } catch (e) {
        // Silently handle errors for background polling
      }
    });
  }

  /// Initial load of requests to populate the badge status.
  Future<void> _loadRequestsForBadge() async {
    if (_hasInitialized) return;

    try {
      final allRequests = await ActivityEditRequestService()
          .getPendingActivityEditApprovals();

      if (mounted) {
        setState(() {
          _cachedRequests = allRequests;
          _hasInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasInitialized = true; // Mark as initialized even on error
        });
      }
    }
  }

  /// Fetches the latest requests and displays the approval dialog.
  Future<void> _showActivityEditRequestsDialog() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final allRequests = await ActivityEditRequestService()
          .getPendingActivityEditApprovals();

      final pendingRequests = allRequests
          .where((req) => req.tripId == widget.tripId)
          .toList();

      // Cache the requests for badge display
      if (mounted) {
        setState(() {
          _cachedRequests = allRequests;
          _isLoading = false;
        });
      }

      if (mounted) {
        ActivityEditRequestApprovalDialog.show(
          context,
          requests: pendingRequests,
          onRequestHandled: () {
            // Clear cache to force refresh on next load
            if (mounted) {
              setState(() {
                _cachedRequests = null;
              });
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show empty dialog on error
        ActivityEditRequestApprovalDialog.show(
          context,
          requests: [],
          onRequestHandled: () {},
        );
      }
    }
  }
}
