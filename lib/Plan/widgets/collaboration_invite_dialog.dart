import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/theme/app_theme.dart';
import '../providers/collaboration_provider.dart';
import '../models/collaboration_models.dart';

class CollaborationInviteDialog extends StatefulWidget {
  final SharedTripModel trip;

  const CollaborationInviteDialog({
    Key? key,
    required this.trip,
  }) : super(key: key);

  @override
  State<CollaborationInviteDialog> createState() => _CollaborationInviteDialogState();
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
    return AlertDialog(
      title: const Text('Invite Collaborator'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email address';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
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
                  child: Row(
                    children: [
                      Text('✏️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Editor', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Can edit activities and details', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'viewer',
                  child: Row(
                    children: [
                      Text('👀', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Viewer', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Can only view, must request to edit', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
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
            ...widget.trip.sharedCollaborators.map((collaborator) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: collaborator.isOwner ? Colors.orange : Colors.blue,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final message = _messageController.text.trim().isNotEmpty 
          ? _messageController.text.trim() 
          : null;

      // Check if email is already a collaborator
      final isAlreadyCollaborator = widget.trip.sharedCollaborators
          .any((c) => c.email.toLowerCase() == email.toLowerCase());

      if (isAlreadyCollaborator) {
        _showError('This email is already a collaborator on this trip');
        return;
      }

      final collaborationProvider = context.read<CollaborationProvider>();
      final success = await collaborationProvider.inviteCollaborator(
        widget.trip.id!,
        email,
        message: message,
        permissionLevel: _selectedRole, // Pass the selected role
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to $email'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to send invitation: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

