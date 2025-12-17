import 'package:flutter/material.dart';
import '../models/collaboration_models.dart';
import '../services/edit_request_service.dart';

/// Dialog for owner to approve/reject edit requests
class EditRequestApprovalDialog extends StatefulWidget {
  final List<EditRequest> requests;
  final VoidCallback? onRequestHandled;

  const EditRequestApprovalDialog({
    Key? key,
    required this.requests,
    this.onRequestHandled,
  }) : super(key: key);

  @override
  State<EditRequestApprovalDialog> createState() => _EditRequestApprovalDialogState();
}

class _EditRequestApprovalDialogState extends State<EditRequestApprovalDialog> {
  final EditRequestService _editRequestService = EditRequestService();
  final Set<String> _processing = {};

  Future<void> _handleRequest(EditRequest request, bool approve) async {
    setState(() => _processing.add(request.id));

    try {
      await _editRequestService.updateEditRequest(
        requestId: request.id,
        status: approve ? EditRequestStatus.approved : EditRequestStatus.rejected,
        promoteToEditor: approve, // Promote to editor if approved
      );

      if (mounted) {
        setState(() => _processing.remove(request.id));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? '✅ ${request.requesterName} is now an editor!'
                  : '❌ Request rejected',
            ),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );

        widget.onRequestHandled?.call();

        // Remove from list
        widget.requests.remove(request);
        if (widget.requests.isEmpty) {
          Navigator.pop(context);
        } else {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing.remove(request.id));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.notification_important, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Edit Access Requests'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.requests.length,
          itemBuilder: (context, index) {
            final request = widget.requests[index];
            final isProcessing = _processing.contains(request.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            request.requesterName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                request.requesterEmail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Trip info
                    if (request.tripTitle != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.map, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.tripTitle!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Message
                    if (request.message != null && request.message!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '"${request.message}"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    // Requested time
                    const SizedBox(height: 8),
                    Text(
                      'Requested ${_formatTime(request.requestedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    // Action buttons
                    const SizedBox(height: 12),
                    if (isProcessing)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _handleRequest(request, false),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleRequest(request, true),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
