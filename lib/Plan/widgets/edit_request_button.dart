import 'package:flutter/material.dart';
import '../models/collaboration_models.dart';
import '../services/edit_request_service.dart';

/// Interactive button for [Viewer] collaborators to initiate a request for [Editor] access.
///
/// Automatically checks for existing pending requests and updates its UI to reflect
/// the current status (Request Pending, or Send Request). Supports request cancellation.
class EditRequestButton extends StatefulWidget {
  /// The ID of the trip for which edit access is being requested.
  final String tripId;

  /// Optional callback invoked when a request is successfully transmitted.
  final VoidCallback? onRequestSent;

  const EditRequestButton({
    super.key,
    required this.tripId,
    this.onRequestSent,
  });

  @override
  State<EditRequestButton> createState() => _EditRequestButtonState();
}

class _EditRequestButtonState extends State<EditRequestButton> {
  final EditRequestService _editRequestService = EditRequestService();
  bool _isLoading = false;
  EditRequest? _pendingRequest;

  @override
  void initState() {
    super.initState();
    _checkPendingRequest();
  }

  /// Queries the service to see if the current user already has a pending request.
  Future<void> _checkPendingRequest() async {
    final request = await _editRequestService.checkPendingRequest(
      widget.tripId,
    );
    if (mounted) {
      setState(() {
        _pendingRequest = request;
      });
    }
  }

  /// Displays the dialog for entering an optional message before sending the request.
  Future<void> _showRequestDialog() async {
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Request Edit Access'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send a request to the trip owner to gain edit permissions.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'Why do you need edit access?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _sendRequest(messageController.text);
    }
  }

  /// Persists the new [EditRequest] to the backend.
  Future<void> _sendRequest(String message) async {
    setState(() => _isLoading = true);

    try {
      final request = await _editRequestService.createEditRequest(
        tripId: widget.tripId,
        message: message.isNotEmpty ? message : null,
      );

      if (mounted) {
        setState(() {
          _pendingRequest = request;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Edit request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onRequestSent?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Deletes the currently pending request to 'cancel' it.
  Future<void> _cancelRequest() async {
    if (_pendingRequest == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
          'Are you sure you want to cancel your edit access request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await _editRequestService.deleteEditRequest(_pendingRequest!.id);

        if (mounted) {
          setState(() {
            _pendingRequest = null;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_pendingRequest != null) {
      return Chip(
        avatar: const Icon(Icons.schedule, size: 18, color: Colors.orange),
        label: const Text('Request Pending'),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: _cancelRequest,
      );
    }

    return ElevatedButton.icon(
      onPressed: _showRequestDialog,
      icon: const Icon(Icons.edit_note),
      label: const Text('Request Edit Access'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
