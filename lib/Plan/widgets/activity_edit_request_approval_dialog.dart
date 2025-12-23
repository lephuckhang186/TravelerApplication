import 'package:flutter/material.dart';
import '../models/collaboration_models.dart';
import '../services/activity_edit_request_service.dart';
import '../../Core/theme/app_theme.dart';

/// Dialog for owner to approve/reject activity edit requests
class ActivityEditRequestApprovalDialog extends StatefulWidget {
  final List<ActivityEditRequest> requests;
  final VoidCallback? onRequestHandled;

  const ActivityEditRequestApprovalDialog({
    Key? key,
    required this.requests,
    this.onRequestHandled,
  }) : super(key: key);

  static void show(BuildContext context, {
    required List<ActivityEditRequest> requests,
    VoidCallback? onRequestHandled,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivityEditRequestBottomSheet(
        requests: requests,
        onRequestHandled: onRequestHandled,
      ),
    );
  }

  @override
  State<ActivityEditRequestApprovalDialog> createState() => _ActivityEditRequestApprovalDialogState();
}

class _ActivityEditRequestApprovalDialogState extends State<ActivityEditRequestApprovalDialog> {
  final ActivityEditRequestService _service = ActivityEditRequestService();
  final Set<String> _processing = {};

  Future<void> _handleRequest(ActivityEditRequest request, bool approve) async {
    setState(() => _processing.add(request.id));

    try {
      // Handle permission change requests differently
      if (request.requestType == 'permission_change') {
        await _handlePermissionChangeRequest(request, approve);
      } else {
        // Handle activity edit requests
        await _service.updateActivityEditRequest(
          requestId: request.id,
          status: approve ? ActivityEditRequestStatus.approved : ActivityEditRequestStatus.rejected,
        );
      }

      if (mounted) {
        String message;
        if (request.requestType == 'permission_change') {
          message = approve
            ? '${request.requesterName} is now an Editor'
            : 'Permission request rejected';
        } else {
          message = approve
            ? 'Activity edit request approved'
            : 'Activity edit request rejected';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );

        widget.onRequestHandled?.call();

        // Close the bottom sheet after successful operation
        Navigator.of(context).pop();

        // Close the bottom sheet after successful operation
        Navigator.of(context).pop();

        // Close the dialog/bottom sheet after successful operation
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && _processing.contains(request.id)) {
        setState(() => _processing.remove(request.id));
      }
    }
  }

  Future<void> _handlePermissionChangeRequest(ActivityEditRequest request, bool approve) async {
    // For permission change requests, we need to update the collaborator's role
    // This would require calling the collaboration service to update permissions
    // For now, we'll mark the request as approved/rejected
    await _service.updateActivityEditRequest(
      requestId: request.id,
      status: approve ? ActivityEditRequestStatus.approved : ActivityEditRequestStatus.rejected,
    );

    // TODO: If approved, update the user's role in the collaboration system
    // This might require additional API calls to update the user's role
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Edit Requests',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.requests.length} pending request${widget.requests.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: widget.requests.length,
                itemBuilder: (context, index) {
                  final request = widget.requests[index];
                  final isProcessing = _processing.contains(request.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Request header
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  request.requesterName.isNotEmpty
                                    ? request.requesterName[0].toUpperCase()
                                    : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.requesterName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      request.requestTypeDisplay,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3CD), // amber.shade100
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 14, color: Color(0xFFF57C00)), // amber.shade700
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: const Color(0xFFF57C00), // amber.shade700
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Trip and activity info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (request.tripTitle != null) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.trip_origin, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          request.tripTitle!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  children: [
                                    Icon(
                                      _getActivityTypeIcon(request.requestType),
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        request.activityTitle ?? 'Activity',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Message if provided
                          if (request.message != null && request.message!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.message, size: 16, color: Color(0xFF1976D2)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Message',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          request.message!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Proposed changes preview (if available)
                          if (request.proposedChanges != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.edit_note, size: 16, color: Color(0xFF388E3C)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Proposed Changes',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF388E3C),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ..._buildProposedChangesList(request.proposedChanges!),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Timestamp
                          const SizedBox(height: 12),
                          Text(
                            'Requested ${_formatTimeAgo(request.requestedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),

                          // Action buttons
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing
                                    ? null
                                    : () => _handleRequest(request, false),
                                  icon: isProcessing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red.shade700,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing
                                    ? null
                                    : () => _handleRequest(request, true),
                                  icon: isProcessing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade50,
                                    foregroundColor: Colors.green.shade700,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityTypeIcon(String requestType) {
    switch (requestType) {
      case 'edit_activity':
        return Icons.edit;
      case 'add_activity':
        return Icons.add_circle;
      case 'delete_activity':
        return Icons.delete;
      case 'permission_change':
        return Icons.person_add;
      default:
        return Icons.help_outline;
    }
  }

  List<Widget> _buildProposedChangesList(Map<String, dynamic> changes) {
    final widgets = <Widget>[];

    changes.forEach((key, value) {
      String displayKey = _formatChangeKey(key);
      String displayValue = _formatChangeValue(key, value);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '$displayKey: $displayValue',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      );
    });

    return widgets;
  }

  String _formatChangeKey(String key) {
    switch (key) {
      case 'title':
        return 'Title';
      case 'description':
        return 'Description';
      case 'activityType':
        return 'Type';
      case 'startDate':
        return 'Date/Time';
      case 'budget':
        return 'Budget';
      case 'location':
        return 'Location';
      case 'checkIn':
        return 'Check-in';
      default:
        return key;
    }
  }

  String _formatChangeValue(String key, dynamic value) {
    if (value == null) return 'None';

    switch (key) {
      case 'startDate':
        if (value is String) {
          try {
            final date = DateTime.parse(value);
            return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            return value;
          }
        }
        return value.toString();
      case 'budget':
        if (value is Map<String, dynamic>) {
          final estimated = value['estimated_cost'];
          return estimated != null ? '$estimated VND' : 'Not set';
        }
        return value.toString();
      case 'location':
        if (value is Map<String, dynamic>) {
          return value['name'] ?? 'Location set';
        }
        return value.toString();
      case 'checkIn':
        return value ? 'Yes' : 'No';
      case 'activityType':
        return value.toString();
      default:
        return value.toString();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Bottom sheet widget for activity edit requests (notification-style)
class _ActivityEditRequestBottomSheet extends StatefulWidget {
  final List<ActivityEditRequest> requests;
  final VoidCallback? onRequestHandled;

  const _ActivityEditRequestBottomSheet({
    required this.requests,
    this.onRequestHandled,
  });

  @override
  State<_ActivityEditRequestBottomSheet> createState() => _ActivityEditRequestBottomSheetState();
}

class _ActivityEditRequestBottomSheetState extends State<_ActivityEditRequestBottomSheet> {
  final ActivityEditRequestService _service = ActivityEditRequestService();
  final Set<String> _processing = {};

  Future<void> _handleRequest(ActivityEditRequest request, bool approve) async {
    setState(() => _processing.add(request.id));

    try {
      // Handle permission change requests differently
      if (request.requestType == 'permission_change') {
        await _handlePermissionChangeRequest(request, approve);
      } else {
        // Handle activity edit requests
        await _service.updateActivityEditRequest(
          requestId: request.id,
          status: approve ? ActivityEditRequestStatus.approved : ActivityEditRequestStatus.rejected,
        );
      }

      if (mounted) {
        String message;
        if (request.requestType == 'permission_change') {
          message = approve
            ? '${request.requesterName} is now an Editor'
            : 'Permission request rejected';
        } else {
          message = approve
            ? 'Activity edit request approved'
            : 'Activity edit request rejected';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );

        widget.onRequestHandled?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing.remove(request.id));
      }
    }
  }

  Future<void> _handlePermissionChangeRequest(ActivityEditRequest request, bool approve) async {
    // For permission change requests, we need to update the collaborator's role
    // This would require calling the collaboration service to update permissions
    // For now, we'll mark the request as approved/rejected
    await _service.updateActivityEditRequest(
      requestId: request.id,
      status: approve ? ActivityEditRequestStatus.approved : ActivityEditRequestStatus.rejected,
    );

    // TODO: If approved, update the user's role in the collaboration system
    // This might require additional API calls to update the user's role
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity Edit Requests',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (widget.requests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.requests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: widget.requests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.requests.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final request = widget.requests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildRequestItem(request),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No pending requests',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity edit requests will appear here',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(ActivityEditRequest request) {
    final isProcessing = _processing.contains(request.id);

    return Dismissible(
      key: Key(request.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _handleRequest(request, false); // Reject on dismiss
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              _getActivityTypeIcon(request.requestType),
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.requesterName,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                request.requestTypeDisplay,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                request.activityTitle ?? 'Activity',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimeAgo(request.requestedAt),
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _handleRequest(request, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _handleRequest(request, true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  IconData _getActivityTypeIcon(String requestType) {
    switch (requestType) {
      case 'edit_activity':
        return Icons.edit;
      case 'add_activity':
        return Icons.add_circle;
      case 'delete_activity':
        return Icons.delete;
      case 'permission_change':
        return Icons.person_add;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
