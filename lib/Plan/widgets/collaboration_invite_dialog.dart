import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/theme/app_theme.dart';
import '../providers/collaboration_provider.dart';
import '../models/collaboration_models.dart';

/// Dialog for inviting new collaborators to a trip via email.
///
/// Allows the owner to specify an email address, choose a permission level
/// (Editor or Viewer), and include an optional personal message. It also
/// displays a list of currently active collaborators for context.
class CollaborationInviteDialog extends StatefulWidget {
  /// The trip to which the new collaborator will be invited.
  final SharedTripModel trip;

  const CollaborationInviteDialog({super.key, required this.trip});

  @override
  State<CollaborationInviteDialog> createState() =>
      _CollaborationInviteDialogState();
}

class _CollaborationInviteDialogState extends State<CollaborationInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'editor'; // Default to editor

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Invite Collaborator',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Trip: ${widget.trip.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter collaborator\'s email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    return _validateEmail(value);
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Role selector
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Permission Level',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'editor',
                      child: Text('✏️ Editor - Can edit activities'),
                    ),
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('👀 Viewer - Read-only access'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Invitation Message (Optional)',
                    hintText: 'Add a personal message...',
                    prefixIcon: Icon(Icons.message),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Collaborators:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.trip.sharedCollaborators
                          .map(
                            (collaborator) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: collaborator.isOwner
                                        ? Colors.orange
                                        : Colors.blue,
                                    child: Text(
                                      collaborator.name.isNotEmpty
                                          ? collaborator.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${collaborator.name} (${collaborator.email})',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (collaborator.isOwner)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Owner',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendInvitation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Send Invitation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Comprehensive email validation with checks for self-invitation and redundancy.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address';
    }

    final email = value.trim().toLowerCase();

    // Basic email format validation
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Check if email is the owner's email
    if (email == widget.trip.ownerEmail.toLowerCase()) {
      return 'You cannot invite yourself to your own trip';
    }

    // Check if email is already a collaborator
    final isAlreadyCollaborator = widget.trip.sharedCollaborators.any(
      (c) => c.email.toLowerCase() == email,
    );
    if (isAlreadyCollaborator) {
      return 'This person is already a collaborator on this trip';
    }

    // Check for pending invitations (if available)
    try {
      final collabProvider = context.read<CollaborationProvider>();
      final hasPendingInvitation = collabProvider.pendingInvitations.any(
        (inv) =>
            inv.inviteeEmail.toLowerCase() == email &&
            inv.tripId == widget.trip.id,
      );
      if (hasPendingInvitation) {
        return 'An invitation has already been sent to this email';
      }
    } catch (e) {
      // If provider not available, skip this check
    }

    return null; // Valid email
  }

  /// Initiates the invitation process through the [CollaborationProvider].
  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional async validation checks
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
    });

    try {
      // Double-check for pending invitations (async check)
      final collabProvider = context.read<CollaborationProvider>();
      await collabProvider.loadPendingInvitations();

      final hasPendingInvitation = collabProvider.pendingInvitations.any(
        (inv) =>
            inv.inviteeEmail.toLowerCase() == email &&
            inv.tripId == widget.trip.id,
      );

      if (hasPendingInvitation) {
        _showError(
          'An invitation has already been sent to this email. Please wait for a response or try again later.',
        );
        return;
      }

      final message = _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null;

      final success = await collabProvider.inviteCollaborator(
        widget.trip.id!,
        email,
        message: message,
        permissionLevel: _selectedRole,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invitation sent successfully to ${_emailController.text.trim()}',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        _showError(
          'Failed to send invitation. Please check your connection and try again.',
        );
      }
    } catch (networkError) {
      // Provide specific error messages based on error type
      String errorMessage =
          'Failed to send invitation due to network issues. Please check your internet connection and try again.';

      if (networkError.toString().contains('timeout')) {
        errorMessage =
            'Request timed out. Please check your connection and try again.';
      } else if (networkError.toString().contains('403')) {
        errorMessage =
            'You do not have permission to invite collaborators to this trip.';
      } else if (networkError.toString().contains('404')) {
        errorMessage = 'Trip not found. It may have been deleted.';
      } else if (networkError.toString().contains('409')) {
        errorMessage = 'This email is already associated with this trip.';
      } else if (networkError.toString().contains('422')) {
        errorMessage = 'Invalid email format or invitation data.';
      }

      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Displays an error feedback message via Snackbar.
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: message.contains('try again')
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _sendInvitation(),
                )
              : null,
        ),
      );
    }
  }
}
