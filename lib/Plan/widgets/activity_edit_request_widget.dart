import 'package:flutter/material.dart';
import 'dart:async';
import '../models/collaboration_models.dart';
import '../services/activity_edit_request_service.dart';
import 'activity_edit_request_approval_dialog.dart';

/// Widget for displaying activity edit request count with badge
class ActivityEditRequestWidget extends StatefulWidget {
  final String tripId;

  const ActivityEditRequestWidget({
    Key? key,
    required this.tripId,
  }) : super(key: key);

  @override
  State<ActivityEditRequestWidget> createState() => _ActivityEditRequestWidgetState();
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
    debugPrint('🔔 ActivityEditRequestWidget: Building for trip ${widget.tripId} - hasPending: $_hasPendingRequests, cached: ${_cachedRequests?.length ?? 0}');

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
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '${_pendingRequestCount}',
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

  bool get _hasPendingRequests => _pendingRequestCount > 0;

  int get _pendingRequestCount {
    if (_cachedRequests == null) return 0;
    return _cachedRequests!.where((req) => req.tripId == widget.tripId).length;
  }

  void _startRealTimeRefresh() {
    // Refresh every 30 seconds to check for new requests
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;

      try {
        debugPrint('🔔 ActivityEditRequestWidget: Real-time refresh check...');
        final allRequests = await ActivityEditRequestService().getPendingActivityEditApprovals();
        final previousCount = _pendingRequestCount;
        final newCount = allRequests.where((req) => req.tripId == widget.tripId).length;

        if (previousCount != newCount) {
          debugPrint('🔔 ActivityEditRequestWidget: Badge count changed from $previousCount to $newCount');
          if (mounted) {
            setState(() {
              _cachedRequests = allRequests;
            });
          }
        }
      } catch (e) {
        debugPrint('❌ REAL_TIME_REFRESH_ERROR: $e');
        // Don't show error to user, just continue
      }
    });
  }

  Future<void> _loadRequestsForBadge() async {
    if (_hasInitialized) return;

    try {
      debugPrint('🔔 ActivityEditRequestWidget: Loading requests for badge...');
      final allRequests = await ActivityEditRequestService().getPendingActivityEditApprovals();
      debugPrint('🔔 ActivityEditRequestWidget: Loaded ${allRequests.length} requests for badge');

      if (mounted) {
        setState(() {
          _cachedRequests = allRequests;
          _hasInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ GET_PENDING_ACTIVITY_EDIT_APPROVALS_ERROR: $e');
      if (mounted) {
        setState(() {
          _hasInitialized = true; // Mark as initialized even on error
        });
      }
    }
  }

  Future<void> _showActivityEditRequestsDialog() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔔 ActivityEditRequestWidget: Loading requests...');
      final allRequests = await ActivityEditRequestService().getPendingActivityEditApprovals();
      debugPrint('🔔 ActivityEditRequestWidget: Got ${allRequests.length} total requests');

      final pendingRequests = allRequests.where((req) => req.tripId == widget.tripId).toList();
      debugPrint('🔔 ActivityEditRequestWidget: Filtered ${pendingRequests.length} requests for trip ${widget.tripId}');

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
      debugPrint('❌ GET_PENDING_ACTIVITY_EDIT_APPROVALS_ERROR: $e');
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
