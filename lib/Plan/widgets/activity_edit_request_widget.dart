import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/collaboration_models.dart';
import '../services/activity_edit_request_service.dart';
import 'activity_edit_request_approval_dialog.dart';

/// Widget for displaying activity edit request count with badge
class ActivityEditRequestWidget extends StatelessWidget {
  final String tripId;

  const ActivityEditRequestWidget({
    Key? key,
    required this.tripId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🔔 ActivityEditRequestWidget: Building for trip $tripId');

    return FutureBuilder<List<ActivityEditRequest>>(
      future: ActivityEditRequestService().getPendingActivityEditApprovals(),
      builder: (context, snapshot) {
        debugPrint('🔔 ActivityEditRequestWidget: FutureBuilder state - ${snapshot.connectionState}');

        if (snapshot.hasError) {
          debugPrint('🔔 ActivityEditRequestWidget: Error - ${snapshot.error}');
        }

        final allRequests = snapshot.data ?? [];
        debugPrint('🔔 ActivityEditRequestWidget: Got ${allRequests.length} total requests');

        final pendingRequests = allRequests.where((req) => req.tripId == tripId).toList();
        debugPrint('🔔 ActivityEditRequestWidget: Filtered ${pendingRequests.length} requests for trip $tripId');

        final hasPendingRequests = pendingRequests.isNotEmpty;
        debugPrint('🔔 ActivityEditRequestWidget: Has pending requests: $hasPendingRequests');

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.pending_actions,
                color: hasPendingRequests ? Colors.orange : Colors.black,
                size: 24,
              ),
              onPressed: () => _showActivityEditRequestsDialog(context, pendingRequests),
              tooltip: 'Activity Requests',
            ),
            if (hasPendingRequests)
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
                    '${pendingRequests.length}',
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
      },
    );
  }

  void _showActivityEditRequestsDialog(BuildContext context, List<ActivityEditRequest> requests) {
    ActivityEditRequestApprovalDialog.show(
      context,
      requests: requests,
      onRequestHandled: () {
        // Refresh the widget by rebuilding
        if (context.mounted) {
          (context as Element).markNeedsBuild();
        }
      },
    );
  }
}
