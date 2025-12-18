import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'search_place_screen.dart';
import '../widgets/ai_assistant_dialog.dart';
import '../../Core/theme/app_theme.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../providers/trip_planning_provider.dart';
import '../providers/collaboration_provider.dart';
import '../models/collaboration_models.dart';
import '../services/trip_planning_service.dart';
import '../services/firebase_trip_service.dart';
import '../services/activity_edit_request_service.dart';
import '../widgets/activity_edit_request_approval_dialog.dart';
import '../widgets/activity_edit_request_widget.dart';
import '../../Expense/services/expense_service.dart';
import '../../Expense/providers/expense_provider.dart';
import '../services/trip_expense_integration_service.dart';
import '../utils/activity_scheduling_validator.dart';
import '../../smart-nofications/widgets/smart_notification_widget.dart';
import '../../smart-nofications/providers/smart_notification_provider.dart';

/// Formatter để tự động thêm dấu chấm sau mỗi 3 chữ số
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Loại bỏ tất cả dấu chấm hiện có
    String newText = newValue.text.replaceAll('.', '');

    // Chỉ giữ lại số
    newText = newText.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue();
    }

    // Thêm dấu chấm sau mỗi 3 chữ số từ phải sang trái
    String formatted = '';
    int count = 0;
    for (int i = newText.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = '.$formatted';
        count = 0;
      }
      formatted = newText[i] + formatted;
      count++;
    }

    // Tính toán vị trí con trở mới
    int cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

/// Bottom sheet widget for managing permissions (notification-style)
class _ManagePermissionsBottomSheet extends StatefulWidget {
  final SharedTripModel sharedTrip;
  final CollaborationProvider collabProvider;
  final VoidCallback onPermissionUpdated;

  const _ManagePermissionsBottomSheet({
    required this.sharedTrip,
    required this.collabProvider,
    required this.onPermissionUpdated,
  });

  @override
  State<_ManagePermissionsBottomSheet> createState() => _ManagePermissionsBottomSheetState();
}

class _ManagePermissionsBottomSheetState extends State<_ManagePermissionsBottomSheet> {
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
                    'Manage Permissions',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (widget.sharedTrip.sharedCollaborators.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.sharedTrip.sharedCollaborators.length}',
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

            // Trip info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip: ${widget.sharedTrip.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.sharedTrip.sharedCollaborators.length} members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: widget.sharedTrip.sharedCollaborators.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.sharedTrip.sharedCollaborators.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final collaborator = widget.sharedTrip.sharedCollaborators[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildMemberItem(collaborator),
                      );
                    },
                  ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
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
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No collaborators',
            style: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite people to collaborate on this trip',
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

  Widget _buildMemberItem(Collaborator collaborator) {
    final isOwner = collaborator.isOwner;
    final currentRole = collaborator.role;

    return Dismissible(
      key: Key(collaborator.id),
      direction: isOwner ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.remove_circle,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        // Handle remove collaborator
        _removeCollaborator(collaborator);
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
            backgroundColor: isOwner ? Colors.orange : Colors.blue,
            child: Text(
              collaborator.name.isNotEmpty
                  ? collaborator.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collaborator.name,
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
                collaborator.email,
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
          subtitle: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOwner
                  ? Colors.orange
                  : currentRole == 'editor'
                      ? Colors.blue
                      : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isOwner ? 'Owner' : currentRole == 'editor' ? 'Editor' : 'Viewer',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing: isOwner
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showRoleSelector(collaborator),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeCollaborator(collaborator),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  void _showRoleSelector(Collaborator collaborator) {
    final currentRole = collaborator.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change role for ${collaborator.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Editor'),
              subtitle: const Text('Can add, edit, and delete activities'),
              leading: Radio<String>(
                value: 'editor',
                groupValue: currentRole,
                onChanged: (value) => _changeRole(collaborator, value!),
              ),
            ),
            ListTile(
              title: const Text('Viewer'),
              subtitle: const Text('Can only view the trip'),
              leading: Radio<String>(
                value: 'viewer',
                groupValue: currentRole,
                onChanged: (value) => _changeRole(collaborator, value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(Collaborator collaborator, String newRole) async {
    if (newRole == collaborator.role) {
      Navigator.pop(context);
      return;
    }

    try {
      await widget.collabProvider.updateCollaboratorPermission(
        widget.sharedTrip.id!,
        collaborator.userId,
        newRole,
      );

      if (mounted) {
        Navigator.pop(context); // Close role selector
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${collaborator.name} is now ${newRole == 'editor' ? 'an Editor' : 'a Viewer'}'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the widget
        setState(() {});
        widget.onPermissionUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeCollaborator(Collaborator collaborator) async {
    try {
      await widget.collabProvider.removeCollaborator(
        widget.sharedTrip.id!,
        collaborator.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${collaborator.name} removed from trip'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the widget
        setState(() {});
        widget.onPermissionUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove collaborator: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class PlannerDetailScreen extends StatefulWidget {
  final TripModel trip;

  const PlannerDetailScreen({super.key, required this.trip});

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  final TripPlanningService _tripService = TripPlanningService();
  final FirebaseTripService _firebaseService = FirebaseTripService();
  final ExpenseService _expenseService = ExpenseService();
  final TripExpenseIntegrationService _integrationService =
      TripExpenseIntegrationService();
  ExpenseProvider? _expenseProvider;

  late TripModel _trip;
  late List<ActivityModel> _activities;
  bool _isDeleting = false;
  bool _hasChanges = false;
  bool _isRefreshing = false;

  // User permissions for collaboration trips
  String? _userRole; // 'owner', 'editor', 'viewer'
  bool get isOwner => _userRole == 'owner';
  bool get isEditor => _userRole == 'editor';
  bool get isViewer => _userRole == 'viewer';

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _activities = List<ActivityModel>.from(widget.trip.activities);
    _loadActivitiesFromServer();
    // Check user permissions for collaboration trips
    _checkUserPermissions();
    // Try to get expense provider from context after first frame (optional)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('DEBUG: PostFrameCallback - Starting initialization');
      _initializeExpenseProvider();
      _initializeSmartNotifications();
      debugPrint('DEBUG: PostFrameCallback - Initialization complete');
    });
  }

  void _initializeExpenseProvider() {
    try {
      if (mounted) {
        _expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        _integrationService.setExpenseProvider(_expenseProvider!);
        debugPrint('ExpenseProvider successfully initialized');
      }
    } catch (e) {
      // ExpenseProvider not available - continue without expense integration
      debugPrint(
        'ExpenseProvider not available, expense integration disabled: $e',
      );
      _expenseProvider = null;
    }
  }

  void _initializeSmartNotifications() async {
    try {
      if (mounted && _trip.id != null) {
        debugPrint('DEBUG: Attempting to initialize smart notifications for trip: ${_trip.id}');
        
        // Try to get provider with enhanced error handling
        try {
          final notificationProvider = Provider.of<SmartNotificationProvider>(
            context, 
            listen: false
          );
          
          debugPrint('DEBUG: Provider found, calling initialize...');
          
          // Initialize with timeout to prevent hanging
          await notificationProvider.initialize(_trip.id!).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('DEBUG: Smart notifications initialization timed out');
              throw TimeoutException('Initialization timeout');
            },
          );
          
          debugPrint('DEBUG: Smart notifications initialization completed for trip: ${_trip.id}');
          
          // Force a rebuild to show notifications
          if (mounted) {
            setState(() {});
          }
          
        } catch (providerError) {
          debugPrint('DEBUG: Provider error: $providerError');
          
          final errorString = providerError.toString().toLowerCase();
          if (errorString.contains('failed to fetch') || 
              errorString.contains('clientexception') ||
              errorString.contains('socketexception') ||
              errorString.contains('timeout') ||
              errorString.contains('connection')) {
            debugPrint('DEBUG: Network issue detected - smart notifications will work when connection is restored');
          } else {
            debugPrint('DEBUG: Other provider error - notifications may be limited');
          }
        }
      } else {
        debugPrint('DEBUG: Cannot initialize smart notifications - mounted: $mounted, trip.id: ${_trip.id}');
      }
    } catch (e) {
      debugPrint('DEBUG: Smart notifications initialization failed: $e');
      // Don't show error to user - notifications are a nice-to-have feature
    }
  }

  /// Check user permissions for collaboration trips
  void _checkUserPermissions() {
    try {
      final collabProvider = context.read<CollaborationProvider>();

      // Check if this is a collaboration trip
      final isCollaborationTrip = collabProvider.mySharedTrips
          .any((t) => t.id == _trip.id) ||
          collabProvider.sharedWithMeTrips
          .any((t) => t.id == _trip.id);

      if (isCollaborationTrip) {
        // Find the shared trip
        SharedTripModel? sharedTrip;
        try {
          sharedTrip = collabProvider.mySharedTrips
              .firstWhere((t) => t.id == _trip.id,
                  orElse: () => collabProvider.sharedWithMeTrips
                      .firstWhere((t) => t.id == _trip.id));
        } catch (e) {
          sharedTrip = null;
        }

        if (sharedTrip != null) {
          // Get current user ID
          final currentUserId = collabProvider.collaborationService.currentUserId;

          if (currentUserId != null) {
            if (sharedTrip.isOwnerUser(currentUserId)) {
              _userRole = 'owner';
            } else {
              final collaborator = sharedTrip.getCollaboratorByUserId(currentUserId);
              if (collaborator != null) {
                _userRole = collaborator.role; // 'editor' or 'viewer'
              } else {
                _userRole = 'viewer'; // Fallback to viewer
              }
            }
          }
        }
      } else {
        // Not a collaboration trip - user is effectively owner
        _userRole = 'owner';
      }

      debugPrint('🎯 USER_ROLE: $_userRole for trip ${_trip.id}');
    } catch (e) {
      debugPrint('❌ PERMISSION_CHECK_ERROR: $e');
      _userRole = 'owner'; // Fallback to owner for private trips
    }
  }

  /// Load activities from local trip data (no longer needed to fetch from server)
  Future<void> _loadActivitiesFromServer() async {
    // Activities are already loaded from trip.activities in initState
    // This function is kept for compatibility but does nothing
    debugPrint('Activities loaded from local trip data: ${_activities.length}');
  }

  Future<bool> _handleWillPop() async {
    Navigator.pop(context, _hasChanges ? _trip : null);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for real-time updates from collaboration provider
    return Consumer<CollaborationProvider>(
      builder: (context, collabProvider, child) {
        // Check if this trip exists in collaboration data
        final isCollaborationTrip = collabProvider.mySharedTrips
            .any((t) => t.id == _trip.id) ||
            collabProvider.sharedWithMeTrips
            .any((t) => t.id == _trip.id);

        // Auto-refresh local trip data when collaboration provider updates
        if (isCollaborationTrip && !_isRefreshing) {
          _autoRefreshFromProvider(collabProvider);
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) async {
            if (didPop) return;
            final shouldPop = await _handleWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
                onPressed: _handleWillPop,
              ),
              title: _buildTripHeader(),
              centerTitle: false,
              actions: [
                // Refresh button for manual sync
                if (isCollaborationTrip)
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: _isRefreshing ? null : () => _manualRefresh(collabProvider),
                    tooltip: 'Sync changes',
                  ),
                // Activity requests widget (only for owners)
                if (isCollaborationTrip && isOwner)
                  ActivityEditRequestWidget(tripId: _trip.id ?? ''),
                SmartNotificationWidget(tripId: _trip.id ?? ''),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.black),
                  onPressed: _isDeleting ? null : _showMoreOptions,
                ),
              ],
            ),
            body: _buildTimeline(),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add Activity Button - Hidden for viewers, shown for owners and editors
                if (!isViewer)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.skyBlue.withValues(alpha: 0.9),
                          AppColors.steelBlue.withValues(alpha: 0.8),
                          AppColors.dodgerBlue.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isDeleting ? null : _handleAddActivity,
                        customBorder: const CircleBorder(),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                if (!isViewer) const SizedBox(height: 16),
                // AI Assistant Button - Only for Owner
                if (isOwner)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.skyBlue.withValues(alpha: 0.9),
                          AppColors.steelBlue.withValues(alpha: 0.8),
                          AppColors.dodgerBlue.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isDeleting ? null : _openAIAssistant,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'images/chatbot.png',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripHeader() {
    final dateRange =
        '${_formatDate(_trip.startDate)} - ${_formatDate(_trip.endDate)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(
            -25,
            4,
          ), // Adjust this value to move left side down
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.travel_explore,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Transform.translate(
            offset: const Offset(-30, 0), // Adjust this value to move text down
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _trip.name,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _trip.destination,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        dateRange,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    if (_activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No plans yet',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start building your itinerary by adding flights, meals, visits or custom notes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group activities by date
    final Map<DateTime, List<ActivityModel>> activitiesByDate = {};
    for (final activity in _activities) {
      if (activity.startDate != null) {
        final date = DateTime(
          activity.startDate!.year,
          activity.startDate!.month,
          activity.startDate!.day,
        );
        if (!activitiesByDate.containsKey(date)) {
          activitiesByDate[date] = [];
        }
        activitiesByDate[date]!.add(activity);
      }
    }

    // Sort dates
    final sortedDates = activitiesByDate.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final activitiesForDate = activitiesByDate[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.skyBlue.withValues(alpha: 0.9),
                    AppColors.steelBlue.withValues(alpha: 0.8),
                    AppColors.dodgerBlue.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _formatDateWithDayOfWeek(date),
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Activities for this date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: activitiesForDate.asMap().entries.map((entry) {
                  final activityIndex = entry.key;
                  final activity = entry.value;
                  final isLast = activityIndex == activitiesForDate.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 24 : 12),
                    child: _buildTimelineItem(activity, activityIndex, isLast),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem(ActivityModel activity, int index, bool isLast) {
    final icon = _iconForType(activity.activityType);
    final timeLabel = activity.startDate != null
        ? _formatTime(activity.startDate!)
        : '--';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 55,
          alignment: Alignment.centerLeft,
          child: activity.startDate != null
              ? Text(
                  timeLabel,
                  style: TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                )
              : const SizedBox(),
        ),
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: activity.checkIn
                    ? null
                    : LinearGradient(
                        colors: [
                          AppColors.skyBlue.withValues(alpha: 0.9),
                          AppColors.steelBlue.withValues(alpha: 0.8),
                          AppColors.dodgerBlue.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: activity.checkIn ? Colors.green : null,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 155,
                decoration: BoxDecoration(
                  gradient: activity.checkIn
                      ? null
                      : LinearGradient(
                          colors: [
                            AppColors.skyBlue.withValues(alpha: 0.9),
                            AppColors.steelBlue.withValues(alpha: 0.8),
                            AppColors.dodgerBlue.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  color: activity.checkIn ? Colors.green : null,
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 195,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, 0),
                          child: Text(
                            activity.title,
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Check-in button - Only for Owner
                      if (isOwner)
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: IconButton(
                            icon: activity.checkIn
                                ? Icon(Icons.check_circle, color: Colors.green)
                                : Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.skyBlue.withValues(
                                            alpha: 0.9,
                                          ),
                                          AppColors.steelBlue.withValues(
                                            alpha: 0.8,
                                          ),
                                          AppColors.dodgerBlue.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                            onPressed: () => _toggleCheckIn(activity),
                          ),
                        ),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteActivity(activity);
                            } else if (value == 'edit') {
                              _showEditActivityModal(activity);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Activity'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (activity.description != null &&
                      activity.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: Text(
                        activity.description!,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (activity.location != null) ...[
                    const SizedBox(height: 8),
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.location!.name,
                              style: TextStyle(
                                fontFamily: 'Urbanist-Regular',
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Budget information - show expected cost before check-in, actual cost after
                  if (activity.budget != null) ...[
                    const SizedBox(height: 8),
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Before check-in: Show expected cost only
                          if (!activity.checkIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expected: ${_formatCurrency(activity.budget!.estimatedCost)}',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist-Regular',
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // After check-in: Show actual cost
                          if (activity.checkIn &&
                              activity.budget!.actualCost != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.receipt,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Spent: ${_formatCurrency(activity.budget!.actualCost!)}',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist-Regular',
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // After check-in but no actual cost recorded
                          if (activity.checkIn &&
                              activity.budget!.actualCost == null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.warning_amber,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'No cost recorded',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist-Regular',
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditActivityModal(ActivityModel activity) {
    // Check permissions: only owner can edit directly, editors must request approval
    if (isEditor) {
      _showEditRequestDialog(activity);
      return;
    } else if (isViewer) {
      _showPermissionDeniedDialog('You can only view this trip');
      return;
    }

    // Owner can edit directly
    _showActivityEditForm(activity);
  }

  /// Show edit request dialog for editors
  void _showEditRequestDialog(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Edit Permission'),
        content: Text(
          'As an editor, you need approval from the trip owner to edit activities. '
          'Send a request to the owner to modify "${activity.title}"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendEditRequest(activity, 'Edit activity: ${activity.title}');
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  /// Handle add activity button click based on user role
  void _handleAddActivity() {
    if (isOwner) {
      // Owner can add activities directly
      _showAddActivityModal();
    } else if (isEditor) {
      // Editor can fill activity details and submit for approval
      _showAddActivityModal();
    } else if (isViewer) {
      // Viewer needs to request edit permission from owner
      _showRequestEditPermissionDialog();
    }
  }

  /// Show permission denied dialog
  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show activity edit form (for owners only)
  void _showActivityEditForm(ActivityModel activity) {
    final titleController = TextEditingController(text: activity.title);
    final descriptionController = TextEditingController(
      text: activity.description ?? '',
    );
    // Format expected cost with thousand separators
    String formattedCost = '';
    if (activity.budget?.estimatedCost != null) {
      final cost = activity.budget!.estimatedCost.toInt().toString();
      // Add dots every 3 digits from right to left
      String formatted = '';
      int count = 0;
      for (int i = cost.length - 1; i >= 0; i--) {
        if (count == 3) {
          formatted = '.$formatted';
          count = 0;
        }
        formatted = cost[i] + formatted;
        count++;
      }
      formattedCost = formatted;
    }
    final expectedCostController = TextEditingController(text: formattedCost);
    dynamic selectedPlace = activity.location != null
        ? {
            'display_name': activity.location!.name,
            'lat': activity.location!.latitude?.toString() ?? '0',
            'lon': activity.location!.longitude?.toString() ?? '0',
          }
        : null;
    ActivityType selectedType = activity.activityType;
    DateTime selectedDate = activity.startDate ?? _trip.startDate;
    TimeOfDay selectedTime = TimeOfDay(
      hour: selectedDate.hour,
      minute: selectedDate.minute,
    );
    bool checkInStatus = activity.checkIn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          'Edit Activity',
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 64),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: titleController,
                      label: 'Title',
                      hint: 'e.g. Morning flight to Hanoi',
                    ),
                    const SizedBox(height: 16),
                    _buildTypeSelector(selectedType, (value) {
                      setModalState(() => selectedType = value);
                    }),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Destination',
                      hint: 'Enter destination details',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Get category name from selected activity type
                          String categoryName = _getActivityTypeSearchName(
                            selectedType,
                          );

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchPlaceScreen(
                                prefilledLocation: _trip.destination,
                                prefilledCategory: categoryName,
                              ),
                            ),
                          );

                          if (result != null) {
                            setModalState(() {
                              selectedPlace = result['place'];
                              titleController.text = result['category'];
                              descriptionController.text =
                                  result['place']['display_name'];
                            });
                          }
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Auto Pick Activities'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCheckInToggle(checkInStatus, (value) {
                      setModalState(() => checkInStatus = value);
                    }),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: expectedCostController,
                      label: checkInStatus
                          ? 'Real Cost (VND)'
                          : 'Expected Cost (VND)',
                      hint: checkInStatus
                          ? 'Enter actual cost spent'
                          : 'Enter estimated cost (optional)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerTile(
                            label: 'Date',
                            value: _formatDate(selectedDate),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: _trip.startDate,
                                lastDate: _trip.endDate,
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPickerTile(
                            label: 'Time',
                            value:
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final startDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final expectedCost =
                              expectedCostController.text.trim().isEmpty
                              ? null
                              : double.tryParse(
                                  expectedCostController.text.trim().replaceAll(
                                    '.',
                                    '',
                                  ),
                                );

                          // Create budget preserving actual cost if exists
                          BudgetModel? budget;
                          if (expectedCost != null) {
                            budget = BudgetModel(
                              estimatedCost: expectedCost,
                              actualCost: activity
                                  .budget
                                  ?.actualCost, // Preserve actual cost
                              currency: 'VND',
                              category: activity.budget?.category,
                            );
                          } else if (activity.budget != null) {
                            budget = activity
                                .budget; // Keep existing budget if no new expected cost
                          }

                          final updatedActivity = activity.copyWith(
                            title: title,
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            activityType: selectedType,
                            startDate: startDate,
                            budget: budget,
                            checkIn: checkInStatus,
                            location: selectedPlace != null
                                ? LocationModel(
                                    name: selectedPlace['display_name'],
                                    latitude: double.tryParse(
                                      selectedPlace['lat'],
                                    ),
                                    longitude: double.tryParse(
                                      selectedPlace['lon'],
                                    ),
                                  )
                                : null,
                            // Preserve expense info to maintain expense tracking
                            expenseInfo: activity.expenseInfo,
                          );
                          Navigator.pop(context);
                          _updateActivity(updatedActivity);

          // Check budget notification when checking in with actual cost
          if (updatedActivity.checkIn && updatedActivity.budget?.actualCost != null) {
            debugPrint('DEBUG: Activity checked in with actual cost, triggering budget check');
            _checkBudgetNotification(updatedActivity);
          } else {
            debugPrint('DEBUG: Activity check-in status: ${updatedActivity.checkIn}, actual cost: ${updatedActivity.budget?.actualCost}');
          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Update Activity'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Send edit request to owner
  Future<void> _sendEditRequest(ActivityModel activity, String message) async {
    try {
      // Validate time conflicts before creating request (exclude current activity)
      final validationResult = ActivitySchedulingValidator.validateActivityTime(
        activity,
        _activities,
        excludeActivityId: activity.id,
      );

      if (validationResult.hasConflicts) {
        // Show conflict dialog
        final shouldContinue = await _showTimeConflictDialog(
          validationResult.message,
          validationResult.conflictingActivities,
        );

        if (!shouldContinue) {
          return; // User chose not to continue
        }
      }

      final service = ActivityEditRequestService();

      // Get current activity data as proposed changes
      final proposedChanges = {
        'title': activity.title,
        'description': activity.description,
        'activityType': activity.activityType.value,
        'startDate': activity.startDate?.toIso8601String(),
        'budget': activity.budget?.toJson(),
        'location': activity.location?.toJson(),
        'checkIn': activity.checkIn,
      };

      final request = await service.createEditActivityRequest(
        tripId: _trip.id!,
        activity: activity,
        proposedChanges: proposedChanges,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edit request sent to trip owner for "${activity.title}"'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      debugPrint('📤 EDIT_REQUEST_SENT: Request ${request.id} sent for activity ${activity.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send edit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAIAssistant() async {
    final result = await AiAssistantDialog.show(context, currentTrip: _trip);

    // Check if AI assistant made any changes
    if (result != null) {
      final changes = result['changes'] as List?;
      if (changes != null && changes.isNotEmpty) {
        // Apply the changes locally
        _applyAIChanges(changes);
      } else if (result.containsKey('new_trip')) {
        // New trip was created - navigate to it
        // final newTrip = result['new_trip'];
        if (mounted) {
          // Close current screen and navigate to new trip
          Navigator.of(context).pop(result['new_trip']);
        }
      } else {
        // No changes made, just refresh from server
        await _loadActivitiesFromServer();
      }
    }
  }

  /// Apply changes made by AI assistant
  void _applyAIChanges(List<dynamic> changes) {
    // Check if this is a full replacement (all activities should be replaced)
    final hasFullReplace = changes.any(
      (change) => change['action'] == 'replace_all',
    );

    if (hasFullReplace) {
      // Full replacement: clear all existing activities and add the new ones
      final newActivities = changes
          .where((change) => change['action'] == 'replace_all')
          .map(
            (change) => ActivityModel.fromJson(
              change['activity'] as Map<String, dynamic>,
            ),
          )
          .toList();

      setState(() {
        _activities = ActivitySchedulingValidator.sortActivitiesChronologically(
          newActivities,
        );
      });

      debugPrint(
        'AI applied full plan replacement with ${newActivities.length} activities',
      );
    } else {
      // Partial changes: apply individual add/remove/update operations
      for (final change in changes) {
        final action = change['action'];
        final activityData = change['activity'];

        switch (action) {
          case 'add':
            final newActivity = ActivityModel.fromJson(activityData);
            setState(() {
              _activities.add(newActivity);
              _activities =
                  ActivitySchedulingValidator.sortActivitiesChronologically(
                    _activities,
                  );
            });
            break;

          case 'remove':
            final activityId = activityData['id'];
            setState(() {
              _activities.removeWhere((activity) => activity.id == activityId);
            });
            break;

          case 'update':
            final updatedActivity = ActivityModel.fromJson(activityData);
            final index = _activities.indexWhere(
              (activity) => activity.id == updatedActivity.id,
            );
            if (index != -1) {
              setState(() {
                _activities[index] = updatedActivity;
                _activities =
                    ActivitySchedulingValidator.sortActivitiesChronologically(
                      _activities,
                    );
              });
            }
            break;
        }
      }
    }

    // Save changes to local storage
    _persistTripChanges();
  }

  void _showAddActivityModal() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final expectedCostController = TextEditingController();
    dynamic selectedPlace;
    ActivityType selectedType = ActivityType.activity;
    DateTime selectedDate = _trip.startDate;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    bool checkInStatus = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          'Add a plan',
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 64),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: titleController,
                      label: 'Title',
                      hint: 'e.g. Morning flight to Hanoi',
                    ),
                    const SizedBox(height: 16),
                    _buildTypeSelector(selectedType, (value) {
                      setModalState(() => selectedType = value);
                    }),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Destination',
                      hint: 'Enter destination details',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Get category name from selected activity type
                          String categoryName = _getActivityTypeSearchName(
                            selectedType,
                          );

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchPlaceScreen(
                                prefilledLocation: _trip.destination,
                                prefilledCategory: categoryName,
                              ),
                            ),
                          );

                          if (result != null) {
                            setModalState(() {
                              selectedPlace = result['place'];
                              titleController.text = result['category'];
                              descriptionController.text =
                                  result['place']['display_name'];
                            });
                          }
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Auto Pick Activities'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCheckInToggle(checkInStatus, (value) {
                      setModalState(() => checkInStatus = value);
                    }),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: expectedCostController,
                      label: checkInStatus
                          ? 'Real Cost (VND)'
                          : 'Expected Cost (VND)',
                      hint: checkInStatus
                          ? 'Enter actual cost spent'
                          : 'Enter estimated cost (optional)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerTile(
                            label: 'Date',
                            value: _formatDate(selectedDate),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: _trip.startDate,
                                lastDate: _trip.endDate,
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPickerTile(
                            label: 'Time',
                            value:
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;
                          final startDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final expectedCost =
                              expectedCostController.text.trim().isEmpty
                              ? null
                              : double.tryParse(
                                  expectedCostController.text.trim().replaceAll(
                                    '.',
                                    '',
                                  ),
                                );

                          // Create budget if expected cost is provided
                          BudgetModel? budget;
                          if (expectedCost != null) {
                            budget = BudgetModel(
                              estimatedCost: expectedCost,
                              currency: 'VND',
                            );
                          }

                          final newActivity = ActivityModel(
                            id: 'local_act_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            activityType: selectedType,
                            startDate: startDate,
                            tripId: _trip.id,
                            budget: budget,
                            checkIn: checkInStatus,
                            location: selectedPlace != null
                                ? LocationModel(
                                    name: selectedPlace['display_name'],
                                    latitude: double.parse(
                                      selectedPlace['lat'],
                                    ),
                                    longitude: double.parse(
                                      selectedPlace['lon'],
                                    ),
                                  )
                                : null,
                          );
                          Navigator.pop(context);
                          _addActivity(newActivity);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save plan'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _checkBudgetNotification(ActivityModel activity) async {
    try {
      debugPrint('DEBUG: Checking budget notification for activity: ${activity.title}');
      debugPrint('DEBUG: Activity check-in: ${activity.checkIn}, actualCost: ${activity.budget?.actualCost}, estimatedCost: ${activity.budget?.estimatedCost}');
      
      if (activity.budget?.actualCost != null && 
          activity.budget?.estimatedCost != null &&
          _trip.id != null && 
          activity.id != null) {
        
        final actualCost = activity.budget!.actualCost!;
        final estimatedCost = activity.budget!.estimatedCost;
        final overage = actualCost - estimatedCost;
        
        debugPrint('DEBUG: Budget check - Actual: $actualCost, Estimated: $estimatedCost, Overage: $overage');
        
        // Only trigger if overage is more than 10%
        if (overage > estimatedCost * 0.1) {
          debugPrint('DEBUG: Budget overage detected! Triggering notification...');
          try {
            final notificationProvider = Provider.of<SmartNotificationProvider>(
              context,
              listen: false,
            );
            await notificationProvider.checkBudgetOnActivity(
              _trip.id!,
              activity.id!,
              actualCost,
            );
            debugPrint('DEBUG: Budget notification triggered successfully');
          } catch (providerError) {
            debugPrint('DEBUG: SmartNotificationProvider not available: $providerError');
          }
        } else {
          debugPrint('DEBUG: Budget overage within acceptable range (<=10%)');
        }
      } else {
        debugPrint('DEBUG: Budget notification skipped - missing data');
      }
    } catch (e) {
      debugPrint('DEBUG: Error checking budget notification: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    // Áp dụng formatter cho số tiền khi keyboardType là number
    final inputFormatters = keyboardType == TextInputType.number
        ? [ThousandsSeparatorInputFormatter()]
        : <TextInputFormatter>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInToggle(bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Text(
          'Check-in Status',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildTypeSelector(
    ActivityType selected,
    ValueChanged<ActivityType> onChanged,
  ) {
    final types = ActivityType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final isSelected = type == selected;
            return ChoiceChip(
              label: Text(_getActivityTypeDisplayName(type)),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                fontFamily: 'Urbanist-Regular',
                color: isSelected ? AppColors.primary : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getActivityTypeDisplayName(ActivityType type) {
    switch (type) {
      case ActivityType.flight:
        return '✈️ Flight';
      case ActivityType.activity:
        return '🎯 Activity';
      case ActivityType.lodging:
        return '🏨 Lodging';
      case ActivityType.carRental:
        return '🚗 Car Rental';
      case ActivityType.concert:
        return '🎵 Concert';
      case ActivityType.cruising:
        return '🛳️ Cruise';
      case ActivityType.direction:
        return '🧭 Directions';
      case ActivityType.ferry:
        return '⛴️ Ferry';
      case ActivityType.groundTransportation:
        return '🚌 Ground Transportation';
      case ActivityType.map:
        return '🗺️ Map';
      case ActivityType.meeting:
        return '🤝 Meeting';
      case ActivityType.note:
        return '📝 Note';
      case ActivityType.parking:
        return '🅿️ Parking';
      case ActivityType.rail:
        return '🚂 Rail';
      case ActivityType.restaurant:
        return '🍽️ Restaurant';
      case ActivityType.theater:
        return '🎭 Theater';
      case ActivityType.tour:
        return '🎫 Tour';
      case ActivityType.transportation:
        return '🚇 Transportation';
    }
  }

  String _getActivityTypeSearchName(ActivityType type) {
    switch (type) {
      case ActivityType.flight:
        return 'airport';
      case ActivityType.activity:
        return 'attraction';
      case ActivityType.lodging:
        return 'hotel';
      case ActivityType.carRental:
        return 'car rental';
      case ActivityType.concert:
        return 'concert hall';
      case ActivityType.cruising:
        return 'port';
      case ActivityType.direction:
        return 'landmark';
      case ActivityType.ferry:
        return 'ferry terminal';
      case ActivityType.groundTransportation:
        return 'bus station';
      case ActivityType.map:
        return 'tourist information';
      case ActivityType.meeting:
        return 'conference center';
      case ActivityType.note:
        return 'landmark';
      case ActivityType.parking:
        return 'parking';
      case ActivityType.rail:
        return 'train station';
      case ActivityType.restaurant:
        return 'restaurant';
      case ActivityType.theater:
        return 'theater';
      case ActivityType.tour:
        return 'tour operator';
      case ActivityType.transportation:
        return 'transport hub';
    }
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTripDialog() {
    final nameController = TextEditingController(text: _trip.name);
    final destinationController = TextEditingController(
      text: _trip.destination,
    );
    final descriptionController = TextEditingController(
      text: _trip.description ?? '',
    );
    final budgetController = TextEditingController(
      text: _trip.budget?.estimatedCost != null
          ? _formatCurrency(_trip.budget!.estimatedCost).replaceAll(' VND', '')
          : '',
    );
    DateTime selectedStartDate = _trip.startDate;
    DateTime selectedEndDate = _trip.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Trip Information'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Trip Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Budget (VND)',
                      border: OutlineInputBorder(),
                      helperText: 'Format: 1.000.000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && picked != selectedStartDate) {
                        setDialogState(() {
                          selectedStartDate = picked;
                          // Ensure end date is not before start date
                          if (selectedEndDate.isBefore(selectedStartDate)) {
                            selectedEndDate = selectedStartDate;
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_formatDate(selectedStartDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEndDate,
                        firstDate: selectedStartDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && picked != selectedEndDate) {
                        setDialogState(() {
                          selectedEndDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_formatDate(selectedEndDate)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveEditedTripInfo(
                    nameController.text.trim(),
                    destinationController.text.trim(),
                    descriptionController.text.trim(),
                    budgetController.text.trim(),
                    selectedStartDate,
                    selectedEndDate,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMoreOptions() {
    // Check if this is a collaboration trip (same logic as in Consumer)
    final isCollaborationTrip = (() {
      try {
        final collabProvider = context.read<CollaborationProvider>();
        return collabProvider.mySharedTrips.any((t) => t.id == _trip.id) ||
               collabProvider.sharedWithMeTrips.any((t) => t.id == _trip.id);
      } catch (e) {
        return false;
      }
    })();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.skyBlue.withValues(alpha: 0.9),
              AppColors.steelBlue.withValues(alpha: 0.8),
              AppColors.dodgerBlue.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text(
                  'Edit Trip Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Rename or update the description',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTripDialog();
                },
              ),
              if (isCollaborationTrip) ...[
                ListTile(
                  leading: const Icon(Icons.people_outline, color: Colors.white),
                  title: const Text(
                    'Manage Permissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Change member roles and permissions',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showManagePermissionsDialog();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.white),
                title: const Text(
                  'Delete Trip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Remove this trip and all its data',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: _confirmDeleteTrip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateActivity(ActivityModel updatedActivity) async {
    try {
      // Find the activity to update
      final index = _activities.indexWhere((a) => a.id == updatedActivity.id);
      if (index == -1) {
        throw Exception('Activity not found');
      }

      // Validate time conflicts (exclude the current activity being updated)
      final validationResult = ActivitySchedulingValidator.validateActivityTime(
        updatedActivity,
        _activities,
        excludeActivityId: updatedActivity.id,
      );

      if (validationResult.hasConflicts) {
        // Show conflict dialog
        final shouldContinue = await _showTimeConflictDialog(
          validationResult.message,
          validationResult.conflictingActivities,
        );

        if (!shouldContinue) {
          return; // User chose not to continue
        }
      }

      // Update locally only - no backend API call needed
      setState(() {
        _activities[index] = updatedActivity;
        // Resort activities by start date
        _activities.sort((a, b) {
          if (a.startDate == null && b.startDate == null) return 0;
          if (a.startDate == null) return 1;
          if (b.startDate == null) return -1;
          return a.startDate!.compareTo(b.startDate!);
        });
      });
      await _persistTripChanges();
    } catch (e) {
      debugPrint('Failed to update activity: $e');
    }
  }

  Future<void> _addActivity(ActivityModel activity) async {
    try {
      // Check user permissions - editors must request approval
      if (isEditor) {
        await _createAddActivityRequest(activity);
        return;
      }

      // Owners can add directly
      // Validate time conflicts
      final validationResult = ActivitySchedulingValidator.validateActivityTime(
        activity,
        _activities,
      );

      if (validationResult.hasConflicts) {
        // Show conflict dialog
        final shouldContinue = await _showTimeConflictDialog(
          validationResult.message,
          validationResult.conflictingActivities,
        );

        if (!shouldContinue) {
          return; // User chose not to continue
        }
      }

      // Add activity locally only - no backend API call needed
      setState(() {
        _activities.add(activity);
        // Sort activities chronologically
        _activities = ActivitySchedulingValidator.sortActivitiesChronologically(
          _activities,
        );
      });
      await _persistTripChanges();

      // Don't auto-create expense - only create on check-in
    } catch (e) {
      debugPrint('Failed to add activity: $e');
    }
  }

  Future<void> _deleteActivity(ActivityModel activity) async {
    try {
      // Delete locally only - no backend API call needed
      setState(() {
        _activities.remove(activity);
      });
      await _persistTripChanges();
    } catch (e) {
      debugPrint('Failed to remove activity: $e');
    }
  }

  Future<void> _saveEditedTripInfo(
    String name,
    String destination,
    String description,
    String budgetText,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (name.isEmpty || destination.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip name and destination are required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Parse budget - remove commas first
      double? budget;
      if (budgetText.isNotEmpty) {
        // Remove commas and any non-digit characters except decimal point
        final cleanBudget = budgetText.replaceAll(',', '').replaceAll(' ', '');
        budget = double.tryParse(cleanBudget);
        if (budget == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid budget amount'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Create updated budget model
      BudgetModel? budgetModel;
      if (budget != null) {
        budgetModel = BudgetModel(
          estimatedCost: budget,
          currency: _trip.budget?.currency ?? 'VND',
          actualCost: _trip.budget?.actualCost,
          category: _trip.budget?.category,
        );
      }

      // Update trip with new information
      final updatedTrip = _trip.copyWith(
        name: name,
        destination: destination,
        description: description.isNotEmpty ? description : null,
        budget: budgetModel,
        startDate: startDate,
        endDate: endDate,
        updatedAt: DateTime.now(),
      );

      // Save to storage
      await _firebaseService.saveTrip(updatedTrip);
      final storedTrip = updatedTrip;

      // Try to update on server if trip has ID and not local
      if (storedTrip.id != null && !storedTrip.id!.startsWith('local_')) {
        try {
          await _tripService.updateTrip(storedTrip.id!, storedTrip);
        } catch (e) {
          debugPrint('Failed to update trip on server: $e');
          // Continue with local update even if server fails
        }
      }

      setState(() {
        _trip = storedTrip;
        _hasChanges = true;
      });
    } catch (e) {
      debugPrint('Failed to update trip: $e');
    }
  }

  Future<void> _persistTripChanges() async {
    final updatedTrip = _trip.copyWith(
      activities: List<ActivityModel>.from(_activities),
    );

    // Save to Firebase
    await _firebaseService.saveTrip(updatedTrip);

    // Check if this is a collaboration trip and update the provider accordingly
    try {
      final collaborationProvider = context.read<CollaborationProvider>();
      // If we can read CollaborationProvider, this might be a collaboration trip
      // Check if the trip ID exists in collaboration data
      final isCollaborationTrip = collaborationProvider.mySharedTrips
          .any((t) => t.id == _trip.id) ||
          collaborationProvider.sharedWithMeTrips
          .any((t) => t.id == _trip.id);

      if (isCollaborationTrip) {
        // Convert back to SharedTripModel for collaboration provider
        final sharedTrip = collaborationProvider.mySharedTrips
            .firstWhere((t) => t.id == _trip.id,
                orElse: () => collaborationProvider.sharedWithMeTrips
                    .firstWhere((t) => t.id == _trip.id));

        final updatedSharedTrip = sharedTrip.copyWith(
          activities: List<ActivityModel>.from(_activities),
          updatedAt: DateTime.now(),
        );

        // Update collaboration provider
        await collaborationProvider.updateSharedTrip(updatedSharedTrip);
        debugPrint('✅ Persisted AI changes to CollaborationProvider for trip: ${_trip.id}');
      } else {
        // Regular private trip - just save to Firebase
        debugPrint('✅ Persisted AI changes to Firebase for private trip: ${_trip.id}');
      }
    } catch (e) {
      // CollaborationProvider not available - changes are still saved to Firebase above
      debugPrint('ℹ️ AI changes persisted to Firebase only (no provider update needed): ${_trip.id}');
    }

    final storedTrip = updatedTrip;
    setState(() {
      _trip = storedTrip;
      _hasChanges = true;
    });
  }

  Future<void> _confirmDeleteTrip() async {
    Navigator.pop(context); // close sheet
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this trip?'),
        content: const Text(
          'This action cannot be undone and will remove all activities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteTrip();
    }
  }

  Future<void> _deleteTrip() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      TripPlanningProvider? provider;
      try {
        provider = context.read<TripPlanningProvider>();
      } catch (_) {
        provider = null;
      }

      if (provider != null && _trip.id != null) {
        await provider.deleteTrip(_trip.id!);
      } else if (_trip.id != null) {
        try {
          await _tripService.deleteTrip(_trip.id!);
        } catch (_) {
          // ignore server failure, we'll still remove locally
        }
        await _firebaseService.deleteTrip(_trip.id!);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Failed to delete trip: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  IconData _iconForType(ActivityType type) {
    switch (type) {
      case ActivityType.flight:
        return Icons.flight_takeoff;
      case ActivityType.restaurant:
        return Icons.restaurant;
      case ActivityType.tour:
        return Icons.tour;
      case ActivityType.lodging:
        return Icons.hotel;
      case ActivityType.carRental:
        return Icons.directions_car;
      case ActivityType.note:
        return Icons.sticky_note_2_outlined;
      default:
        return Icons.local_activity;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateWithDayOfWeek(DateTime date) {
    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dayOfWeek = daysOfWeek[date.weekday - 1];
    return '$dayOfWeek, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hours = dateTime.hour;
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final suffix = hours >= 12 ? 'PM' : 'AM';
    final normalizedHour = hours == 0
        ? 12
        : hours > 12
        ? hours - 12
        : hours;
    return '$normalizedHour:$minutes $suffix';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} VND';
  }

  void _toggleCheckIn(ActivityModel activity) async {
    try {
      if (!activity.checkIn) {
        // Checking in - prompt for actual cost
        await _checkInWithActualCost(activity);
      } else {
        // Checking out - remove expense and toggle status
        await _checkOutActivity(activity);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update check-in status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle checkout - remove expense if exists and toggle status
  Future<void> _checkOutActivity(ActivityModel activity) async {
    // Delete expense using optimistic update pattern
    if (activity.expenseInfo.expenseSynced &&
        activity.expenseInfo.expenseId != null) {
      if (_expenseProvider != null) {
        // Optimistic update: remove from local cache immediately
        final expenseId = activity.expenseInfo.expenseId!;
        _expenseProvider!.expenses.removeWhere((exp) => exp.id == expenseId);
        debugPrint('Optimistically removed expense from local cache: $expenseId');
        
        // Delete on backend in background (fire-and-forget with error handling)
        _expenseProvider!.deleteExpense(expenseId).catchError((e) {
          debugPrint('Failed to delete expense on backend: $e');
          // Note: Local cache already updated, so UI won't show it
          // If this is critical, consider implementing rollback
          return false;
        });
      }
    }

    // Update activity immediately: uncheck and clear expense info
    final updatedActivity = activity.copyWith(
      checkIn: false,
      expenseInfo: ExpenseInfo(), // Reset expense info
    );

    await _updateActivityCheckIn(updatedActivity);
  }

  /// Handle check-in with actual cost input
  Future<void> _checkInWithActualCost(ActivityModel activity) async {
    final TextEditingController actualCostController = TextEditingController();
    final expectedCost = activity.budget?.estimatedCost;

    // Pre-fill with expected cost if available
    if (expectedCost != null) {
      actualCostController.text = expectedCost.toStringAsFixed(0);
    }

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check-in: ${activity.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expectedCost != null) ...[
              Text(
                'Expected Cost: ${_formatCurrency(expectedCost)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Enter actual cost:'),
            const SizedBox(height: 8),
            TextField(
              controller: actualCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Actual cost (VND)',
                border: OutlineInputBorder(),
                prefixText: 'VND ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final costText = actualCostController.text.trim();
              if (costText.isNotEmpty) {
                final cost = double.tryParse(costText);
                if (cost != null && cost > 0) {
                  Navigator.pop(context, cost);
                }
              } else {
                // Allow check-in without cost
                Navigator.pop(context, 0.0);
              }
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _performCheckIn(activity, result);
    }
  }

  /// Perform the actual check-in with cost
  Future<void> _performCheckIn(
    ActivityModel activity,
    double actualCost,
  ) async {
    // Update activity with actual cost and check-in status
    final updatedBudget = BudgetModel(
      estimatedCost: activity.budget?.estimatedCost ?? actualCost,
      actualCost: actualCost,
      currency: activity.budget?.currency ?? 'VND',
      category: activity.budget?.category,
    );

    final updatedActivity = activity.copyWith(
      checkIn: true,
      budget: updatedBudget,
    );

    await _updateActivityCheckIn(updatedActivity);

    // Create expense entry only after successful check-in
    if (actualCost > 0) {
      await _createExpenseForCheckedInActivity(updatedActivity);
    }
  }

  /// Update activity check-in status
  Future<void> _updateActivityCheckIn(ActivityModel updatedActivity) async {
    debugPrint(
      'Updating activity check-in: ${updatedActivity.title}, checkIn: ${updatedActivity.checkIn}',
    );

    final index = _activities.indexWhere((a) => a.id == updatedActivity.id);
    if (index == -1) {
      debugPrint('Activity not found for check-in update');
      return;
    }

    // Update locally only - no backend API call needed
    setState(() {
      _activities[index] = updatedActivity;
      // Re-sort activities chronologically
      _activities = ActivitySchedulingValidator.sortActivitiesChronologically(
        _activities,
      );
    });
    await _persistTripChanges();
    debugPrint('Check-in status updated locally and persisted');
  }

  /// Create expense for checked-in activity
  Future<void> _createExpenseForCheckedInActivity(
    ActivityModel activity,
  ) async {
    try {
      if (activity.budget?.actualCost == null ||
          activity.budget!.actualCost! <= 0) {
        return;
      }

      // Check if expense already exists for this activity
      if (activity.expenseInfo.expenseSynced &&
          activity.expenseInfo.expenseId != null) {
        debugPrint(
          'Expense already exists for activity: ${activity.title} (expenseId: ${activity.expenseInfo.expenseId})',
        );
        return;
      }

      // Only try expense integration if provider is available
      if (_expenseProvider != null) {
        // Double-check: Verify expense doesn't exist on server
        // This prevents duplicates if checkout deletion is still pending
        try {
          final existingExpenses = _expenseProvider!.expenses;
          final duplicateExpense = existingExpenses.where((exp) =>
            exp.description == activity.title &&
            exp.tripId == _trip.id &&
            exp.amount == activity.budget!.actualCost
          ).firstOrNull;
          
          if (duplicateExpense != null) {
            debugPrint(
              'Found existing expense for activity: ${activity.title}, reusing expense ID: ${duplicateExpense.id}',
            );
            
            // Reuse existing expense instead of creating new one
            final updatedExpenseInfo = activity.expenseInfo.copyWith(
              expenseId: duplicateExpense.id,
              hasExpense: true,
              expenseCategory: activity.activityType.value,
              expenseSynced: true,
            );

            final updatedActivity = activity.copyWith(
              expenseInfo: updatedExpenseInfo,
            );

            final index = _activities.indexWhere((a) => a.id == activity.id);
            if (index != -1) {
              setState(() {
                _activities[index] = updatedActivity;
              });
              await _persistTripChanges();
            }
            return;
          }
        } catch (e) {
          debugPrint('Error checking for duplicate expense: $e');
          // Continue to create new expense
        }
        
        // Create expense and get the expense ID
        final expense = await _expenseService.createExpenseFromActivity(
          amount: activity.budget!.actualCost!,
          category: activity.activityType.value,
          description: activity.title,
          activityId: activity.id,
          tripId: _trip.id,
        );

        debugPrint(
          'Created expense for checked-in activity: ${activity.title} (${activity.budget!.actualCost} VND), expenseId: ${expense.id}',
        );

        // Check if backend returned a budget warning
        if (expense.budgetWarning != null) {
          debugPrint('💰 BUDGET_WARNING from backend: ${expense.budgetWarning}');
          
          // Trigger smart notification for budget warning
          try {
            if (mounted) {
              final notificationProvider = Provider.of<SmartNotificationProvider>(
                context,
                listen: false,
              );
              
              final warningType = expense.budgetWarning!['type'] as String?;
             final message = expense.budgetWarning!['message'] as String?;
            
            debugPrint('🔔 Triggering notification for budget warning: $warningType - $message');
            
            // Create notification based on warning type
            if (warningType == 'OVER_BUDGET' || warningType == 'WARNING' || warningType == 'NO_BUDGET') {
              await notificationProvider.handleExpenseCreatedWithResponse(
                _trip.id!,
                expense,
                activity.id,
              );
              debugPrint('✅ Budget warning notification created successfully');
            }
            }
          } catch (providerError) {
            debugPrint('❌ Failed to create budget warning notification: $providerError');
          }
        } else {
          debugPrint('ℹ️ No budget warning from backend');
        }

        // Update activity with expense info
        final updatedExpenseInfo = activity.expenseInfo.copyWith(
          expenseId: expense.id,
          hasExpense: true,
          expenseCategory: activity.activityType.value,
          expenseSynced: true,
        );

        final updatedActivity = activity.copyWith(
          expenseInfo: updatedExpenseInfo,
        );

        // Update the activity in local state
        final index = _activities.indexWhere((a) => a.id == activity.id);
        if (index != -1) {
          setState(() {
            _activities[index] = updatedActivity;
          });
          await _persistTripChanges();
        }
      } else {
        // Log activity cost without expense integration
        debugPrint(
          'Activity cost recorded (expense integration disabled): ${activity.title} (${activity.budget!.actualCost} VND)',
        );
      }
    } catch (e) {
      debugPrint('Failed to create expense for checked-in activity: $e');
      // Don't throw error - continue without expense integration
    }
  }

  /// Show time conflict dialog
  Future<bool> _showTimeConflictDialog(
    String message,
    List<ActivityModel> conflictingActivities,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Xung đột thời gian'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              if (conflictingActivities.isNotEmpty) ...[
                const Text(
                  'Hoạt động bị trùng:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...conflictingActivities.map<Widget>((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${activity.title} (${_formatActivityTime(activity)})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gợi ý: Chọn thời gian khác để tránh xung đột',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Quay lại',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Format activity time for display
  String _formatActivityTime(ActivityModel activity) {
    if (activity.startDate == null) return '';

    final start = activity.startDate!;
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    if (activity.endDate != null) {
      final end = activity.endDate!;
      final endStr =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      return '$startStr - $endStr';
    }

    return startStr;
  }

  /// Refresh trip data from provider
  Future<void> _refreshTripData(SharedTripModel updatedTrip) async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Update trip and activities
      setState(() {
        _trip = updatedTrip.toTripModel();
        _activities = List<ActivityModel>.from(updatedTrip.activities);
      });

      debugPrint('✅ Refreshed trip data: ${updatedTrip.name} (${updatedTrip.activities.length} activities)');
    } catch (e) {
      debugPrint('❌ Failed to refresh trip data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Auto-refresh local trip data when collaboration provider updates
  void _autoRefreshFromProvider(CollaborationProvider collabProvider) {
    try {
      // Find the current trip in collaboration provider data
      SharedTripModel? updatedTrip;
      try {
        updatedTrip = collabProvider.mySharedTrips
            .firstWhere((t) => t.id == _trip.id,
                orElse: () => collabProvider.sharedWithMeTrips
                    .firstWhere((t) => t.id == _trip.id));
      } catch (e) {
        // Trip not found in provider
        return;
      }

      if (updatedTrip == null) return;

      // Check if the trip data has actually changed
      final currentActivities = _activities;
      final providerActivities = updatedTrip.activities;

      // Compare activities count and last updated time
      final hasChanges = currentActivities.length != providerActivities.length ||
          updatedTrip.updatedAt != _trip.updatedAt;

      if (hasChanges && updatedTrip != null) {
        debugPrint('🔄 AUTO_REFRESH: Detected changes in trip ${updatedTrip.id}, updating local state...');

        // Update local state with provider data
        setState(() {
          _trip = updatedTrip!.toTripModel();
          _activities = List<ActivityModel>.from(updatedTrip!.activities);
        });

        debugPrint('✅ AUTO_REFRESH: Updated local trip data - ${_activities.length} activities');
      }
    } catch (e) {
      debugPrint('❌ AUTO_REFRESH: Failed to auto-refresh from provider: $e');
    }
  }

  /// Manual refresh triggered by user
  Future<void> _manualRefresh(CollaborationProvider collabProvider) async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Force refresh collaboration data
      await collabProvider.initialize();

      // Find updated trip
      final updatedTrip = collabProvider.mySharedTrips
          .firstWhere((t) => t.id == _trip.id,
              orElse: () => collabProvider.sharedWithMeTrips
                  .firstWhere((t) => t.id == _trip.id));

      if (updatedTrip != null) {
        setState(() {
          _trip = updatedTrip.toTripModel();
          _activities = List<ActivityModel>.from(updatedTrip.activities);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip data refreshed')),
        );
      }

      debugPrint('✅ Manual refresh completed');
    } catch (e) {
      debugPrint('❌ Manual refresh failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Create add activity request for editors
  Future<void> _createAddActivityRequest(ActivityModel activity) async {
    try {
      // Validate time conflicts before creating request
      final validationResult = ActivitySchedulingValidator.validateActivityTime(
        activity,
        _activities,
      );

      if (validationResult.hasConflicts) {
        // Show conflict dialog
        final shouldContinue = await _showTimeConflictDialog(
          validationResult.message,
          validationResult.conflictingActivities,
        );

        if (!shouldContinue) {
          return; // User chose not to continue
        }
      }

      final service = ActivityEditRequestService();

      // For add activity request, we need to send the full activity data as proposed changes
      final proposedActivityData = {
        'title': activity.title,
        'description': activity.description,
        'activityType': activity.activityType.value,
        'startDate': activity.startDate?.toIso8601String(),
        'budget': activity.budget?.toJson(),
        'location': activity.location?.toJson(),
        'checkIn': activity.checkIn,
      };

      final request = await service.createAddActivityRequest(
        tripId: _trip.id!,
        proposedActivityData: proposedActivityData,
        message: 'Request to add new activity: ${activity.title}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add activity request sent to trip owner'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      debugPrint('📤 ADD_ACTIVITY_REQUEST_SENT: Request ${request.id} sent for new activity ${activity.title}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send add activity request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show request edit permission dialog for viewers
  void _showRequestEditPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Edit Permission'),
        content: const Text(
          'As a viewer, you can only view this trip. To add activities or make changes, '
          'you need to request edit permission from the trip owner. '
          'Send a request to become an editor?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendPermissionRequest();
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  /// Send permission request to owner
  Future<void> _sendPermissionRequest() async {
    try {
      final service = ActivityEditRequestService();

      // Create a permission change request
      final request = await service.createActivityEditRequest(
        tripId: _trip.id!,
        requestType: 'permission_change',
        message: 'Request to change my role from viewer to editor so I can contribute to the trip planning.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission request sent to trip owner'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      debugPrint('📤 PERMISSION_REQUEST_SENT: Request ${request.id} sent for role change');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send permission request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show activity edit requests dialog for owners
  void _showActivityEditRequestsDialog() async {
    try {
      final service = ActivityEditRequestService();
      final requests = await service.getPendingActivityEditApprovals();

      // Filter requests for this specific trip
      final tripRequests = requests.where((req) => req.tripId == _trip.id).toList();

      if (mounted) {
        ActivityEditRequestApprovalDialog.show(
          context,
          requests: tripRequests,
          onRequestHandled: () async {
            // Refresh trip data directly from Firebase after handling requests
            try {
              debugPrint('🔄 Refreshing trip data after request approval...');

              // Force refresh collaboration provider to get latest shared trip data
              final collabProvider = context.read<CollaborationProvider>();
              await collabProvider.initialize();

              // Get updated trip from refreshed collaboration provider
              final updatedTrip = collabProvider.mySharedTrips
                  .firstWhere((t) => t.id == _trip.id,
                      orElse: () => collabProvider.sharedWithMeTrips
                          .firstWhere((t) => t.id == _trip.id));

              if (updatedTrip != null) {
                setState(() {
                  _trip = updatedTrip;
                  _activities = List<ActivityModel>.from(updatedTrip.activities);
                });
                debugPrint('✅ Trip data refreshed from Firebase: ${_activities.length} activities');

                // Also update collaboration provider with new data
                try {
                  final sharedTrip = collabProvider.mySharedTrips
                      .firstWhere((t) => t.id == _trip.id,
                          orElse: () => collabProvider.sharedWithMeTrips
                              .firstWhere((t) => t.id == _trip.id));

                  if (sharedTrip != null) {
                    final updatedSharedTrip = sharedTrip.copyWith(
                      activities: _activities,
                      updatedAt: DateTime.now(),
                    );
                    await collabProvider.updateSharedTrip(updatedSharedTrip);
                    debugPrint('✅ Collaboration provider updated with new activities');
                  }
                } catch (collabError) {
                  debugPrint('⚠️ Could not update collaboration provider: $collabError');
                }
              } else {
                debugPrint('❌ Trip not found in Firebase after refresh');
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip updated with approved changes')),
                );
              }
            } catch (e) {
              debugPrint('❌ Failed to refresh after handling requests: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request processed but failed to refresh: $e')),
                );
              }
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load activity edit requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show manage permissions dialog (only for collaboration trips and owners)
  void _showManagePermissionsDialog() {
    // Check if user is owner
    if (!isOwner) {
      _showPermissionDeniedDialog('Only trip owners can manage permissions');
      return;
    }

    final collabProvider = context.read<CollaborationProvider>();

    // Get the shared trip
    final sharedTrip = collabProvider.mySharedTrips
        .firstWhere((t) => t.id == _trip.id,
            orElse: () => collabProvider.sharedWithMeTrips
                .firstWhere((t) => t.id == _trip.id));

    if (sharedTrip == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManagePermissionsBottomSheet(
        sharedTrip: sharedTrip,
        collabProvider: collabProvider,
        onPermissionUpdated: () => _manualRefresh(collabProvider),
      ),
    );
  }
}
