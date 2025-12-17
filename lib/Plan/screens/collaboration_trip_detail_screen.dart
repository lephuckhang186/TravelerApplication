import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Core/theme/app_theme.dart';
import '../providers/collaboration_provider.dart';
import '../models/collaboration_models.dart';
import '../models/activity_models.dart';
import '../models/trip_model.dart';
import '../widgets/ai_assistant_dialog.dart';
import '../widgets/edit_request_button.dart';
import '../widgets/edit_request_approval_dialog.dart';
import '../services/edit_request_service.dart';
import 'search_place_screen.dart';
import '../../Expense/services/expense_service.dart';
import '../../Expense/providers/expense_provider.dart';
import '../services/trip_expense_integration_service.dart';
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

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CollaborationTripDetailScreen extends StatefulWidget {
  final SharedTripModel trip;
  final String tripId;

  const CollaborationTripDetailScreen({
    Key? key,
    required this.trip,
    required this.tripId,
  }) : super(key: key);

  @override
  State<CollaborationTripDetailScreen> createState() => _CollaborationTripDetailScreenState();
}

class _CollaborationTripDetailScreenState extends State<CollaborationTripDetailScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TripExpenseIntegrationService _integrationService = TripExpenseIntegrationService();
  final EditRequestService _editRequestService = EditRequestService();
  ExpenseProvider? _expenseProvider;
  
  late SharedTripModel _trip;
  late List<ActivityModel> _activities;
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _hasChanges = false;
  List<EditRequest> _pendingEditRequests = [];

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _activities = List<ActivityModel>.from(widget.trip.activities);
    _initializeCollaboration();
    // Initialize expense provider and smart notifications after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeExpenseProvider();
      _initializeSmartNotifications();
      _loadPendingEditRequests();
    });
  }

  Future<void> _loadPendingEditRequests() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || !_trip.isOwnerUser(currentUserId)) return;

    try {
      final requests = await _editRequestService.getTripEditRequests(
        tripId: _trip.id!,
        status: 'pending',
      );
      if (mounted) {
        setState(() {
          _pendingEditRequests = requests;
        });
      }
    } catch (e) {
      debugPrint('Failed to load edit requests: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to selectedSharedTrip changes from provider
    final provider = context.watch<CollaborationProvider>();
    final selectedTrip = provider.selectedSharedTrip;

    if (selectedTrip != null && selectedTrip.id == _trip.id && selectedTrip != _trip) {
      debugPrint('🎯 TRIP_DETAIL: Selected trip updated from provider');
      setState(() {
        _trip = selectedTrip;
        _activities = List<ActivityModel>.from(selectedTrip.activities);
      });
    }
  }

  Future<void> _initializeCollaboration() async {
    final collaborationProvider = context.read<CollaborationProvider>();
    await collaborationProvider.selectSharedTrip(widget.tripId);
  }

  void _initializeExpenseProvider() {
    try {
      _expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      debugPrint('DEBUG: ExpenseProvider initialized successfully');
    } catch (e) {
      debugPrint('DEBUG: ExpenseProvider not found in context: $e');
    }
  }

  void _initializeSmartNotifications() async {
    try {
      if (_trip.id != null) {
        final notificationProvider = Provider.of<SmartNotificationProvider>(context, listen: false);
        await notificationProvider.initialize(_trip.id!);
        debugPrint('DEBUG: SmartNotificationProvider initialized successfully');
      }
    } catch (e) {
      debugPrint('DEBUG: SmartNotificationProvider not found in context: $e');
    }
  }

  // Permission helpers
  bool get _isOwner {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId != null && _trip.isOwnerUser(currentUserId);
  }

  bool get _canEdit {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId != null && _trip.canUserEdit(currentUserId);
  }

  bool get _isViewer {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId != null && _trip.canUserOnlyView(currentUserId);
  }

  Future<bool> _handleWillPop() async {
    Navigator.pop(context, _hasChanges ? _trip : null);
    return false;
  }

  void _showEditRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) => EditRequestApprovalDialog(
        requests: _pendingEditRequests,
        onRequestHandled: () {
          _loadPendingEditRequests();
          // Reload trip to refresh collaborator roles
          _initializeCollaboration();
        },
      ),
    );
  }

  void _showNoPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('View Only Access'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You currently have viewer access to this trip.'),
            const SizedBox(height: 16),
            const Text('To make changes, you need to request edit access from the trip owner.'),
            const SizedBox(height: 16),
            EditRequestButton(
              tripId: _trip.id!,
              onRequestSent: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // Show pending edit requests badge for owner
            if (_isOwner && _pendingEditRequests.isNotEmpty)
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active, color: Colors.orange),
                    onPressed: _showEditRequestsDialog,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingEditRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          // Add Activity Button
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
                onTap: _isDeleting ? null : _showAddActivityModal,
                customBorder: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // AI Assistant Button
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
                onTap: _isDeleting ? null : () => _openAIAssistant(_trip),
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
                  style: const TextStyle(
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
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Check-in button
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: IconButton(
                          icon: activity.checkIn
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : Container(
                                  width: 24,
                                  height: 24,
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
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                          onPressed: _canEdit ? () => _toggleCheckIn(activity) : null,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: _canEdit
                            ? PopupMenuButton<String>(
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
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  if (activity.description != null && activity.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
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
                  ],
                  if (activity.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
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
                  ],
                  if (activity.budget != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (!activity.checkIn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Expected: ${_formatCurrency(activity.budget!.estimatedCost)}',
                                  style: const TextStyle(
                                    fontFamily: 'Urbanist-Regular',
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (activity.checkIn && activity.budget!.actualCost != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Spent: ${_formatCurrency(activity.budget!.actualCost!)}',
                                  style: const TextStyle(
                                    fontFamily: 'Urbanist-Regular',
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateWithDayOfWeek(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toInt().toString();
    String result = '';
    int count = 0;
    for (int i = formatted.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = formatted[i] + result;
      count++;
    }
    return '${result} VND';
  }

  IconData _iconForType(ActivityType type) {
    switch (type) {
      case ActivityType.flight:
        return Icons.flight;
      case ActivityType.lodging:
        return Icons.hotel;
      case ActivityType.restaurant:
        return Icons.restaurant;
      case ActivityType.activity:
        return Icons.place;
      case ActivityType.transportation:
      case ActivityType.groundTransportation:
      case ActivityType.carRental:
      case ActivityType.rail:
        return Icons.directions_car;
      case ActivityType.concert:
      case ActivityType.theater:
        return Icons.local_activity;
      case ActivityType.tour:
        return Icons.tour;
      case ActivityType.ferry:
      case ActivityType.cruising:
        return Icons.directions_boat;
      case ActivityType.meeting:
        return Icons.meeting_room;
      case ActivityType.parking:
        return Icons.local_parking;
      case ActivityType.map:
      case ActivityType.direction:
        return Icons.map;
      case ActivityType.note:
        return Icons.event_note;
      default:
        return Icons.event;
    }
  }

  void _showEditActivityModal(ActivityModel activity) {
    // Check permission
    if (!_canEdit) {
      _showNoPermissionDialog();
      return;
    }
    final titleController = TextEditingController(text: activity.title);
    final descriptionController = TextEditingController(
      text: activity.description ?? '',
    );
    
    // Format expected cost with thousand separators
    String formattedCost = '';
    if (activity.budget?.estimatedCost != null) {
      final cost = activity.budget!.estimatedCost.toInt().toString();
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Text(
                          'Edit Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 64),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Title field
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Morning flight to Hanoi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter activity details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cost field
                    TextField(
                      controller: expectedCostController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: checkInStatus ? 'Actual Cost (VND)' : 'Expected Cost (VND)',
                        hintText: checkInStatus ? 'Enter actual cost spent' : 'Enter estimated cost',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final expectedCost = expectedCostController.text.trim().isEmpty
                              ? null
                              : double.tryParse(expectedCostController.text.trim().replaceAll('.', ''));

                          BudgetModel? budget;
                          if (expectedCost != null) {
                            budget = BudgetModel(
                              estimatedCost: expectedCost,
                              actualCost: checkInStatus ? expectedCost : activity.budget?.actualCost,
                              currency: 'VND',
                              category: activity.budget?.category,
                            );
                          } else if (activity.budget != null) {
                            budget = activity.budget;
                          }

                          final updatedActivity = activity.copyWith(
                            title: title,
                            description: descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            budget: budget,
                            checkIn: checkInStatus,
                          );
                          
                          Navigator.pop(context);
                          _updateActivity(updatedActivity);
                          
                          // Dispose controllers
                          titleController.dispose();
                          descriptionController.dispose();
                          expectedCostController.dispose();
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

  void _showAddActivityModal() {
    // Check permission
    if (!_canEdit) {
      _showNoPermissionDialog();
      return;
    }
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
                          'Add Activity',
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
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
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
                                      expectedCostController.text
                                          .trim()
                                          .replaceAll('.', ''),
                                    );

                          final newActivity = ActivityModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            description: descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            activityType: selectedType,
                            startDate: startDate,
                            budget: expectedCost != null
                                ? BudgetModel(
                                    estimatedCost: expectedCost,
                                    actualCost: checkInStatus ? expectedCost : null,
                                    currency: 'VND',
                                  )
                                : null,
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
                          );
                          
                          Navigator.pop(context);
                          _addActivity(newActivity);
                          
                          // Dispose controllers
                          titleController.dispose();
                          descriptionController.dispose();
                          expectedCostController.dispose();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Activity'),
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

  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      debugPrint('⚠️ SAVE_CHANGES_SKIP: No changes to save');
      return;
    }

    debugPrint('💾 SAVE_CHANGES_START: Saving ${(_activities.length - _trip.activities.length)} activity changes');

    try {
      final collaborationProvider = context.read<CollaborationProvider>();

      // Update trip with new activities
      final updatedTrip = _trip.copyWith(activities: _activities);
      debugPrint('📤 SAVE_CHANGES_UPDATE: Updating trip ${_trip.id} with ${updatedTrip.activities.length} activities');

      await collaborationProvider.updateSharedTrip(updatedTrip);

      debugPrint('✅ SAVE_CHANGES_SUCCESS: Trip updated successfully');

      setState(() {
        _trip = updatedTrip;
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('❌ SAVE_CHANGES_ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    }
  }

  void _openAIAssistant(SharedTripModel trip) {
    // Convert SharedTripModel to TripModel for AI Assistant
    final tripModel = TripModel(
      id: trip.id,
      name: trip.name,
      destination: trip.destination,
      startDate: trip.startDate,
      endDate: trip.endDate,
      budget: trip.budget,
      activities: trip.activities,
      description: trip.description,
    );

    showDialog(
      context: context,
      builder: (context) => AiAssistantDialog(currentTrip: tripModel),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
              const Text(
                'Trip Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.group_work,
                title: 'Collaboration',
                subtitle: 'Manage shared access',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Collaboration management - to be implemented')),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.info,
                title: 'Trip Info',
                subtitle: 'View trip details',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip info - to be implemented')),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.share,
                title: 'Share Trip',
                subtitle: 'Share with friends',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share trip - to be implemented')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }

  // Activity management methods (same as private mode)
  Future<void> _deleteActivity(ActivityModel activity) async {
    setState(() {
      _activities.removeWhere((a) => a.id == activity.id);
      _hasChanges = true;
    });
    await _saveChanges();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity removed')),
      );
    }
  }

  void _updateActivity(ActivityModel updatedActivity) {
    setState(() {
      final index = _activities.indexWhere((a) => a.id == updatedActivity.id);
      if (index != -1) {
        _activities[index] = updatedActivity;
        _hasChanges = true;
      }
    });
    _saveChanges();
  }

  void _toggleCheckIn(ActivityModel activity) {
    final updatedActivity = activity.copyWith(checkIn: !activity.checkIn);
    _updateActivity(updatedActivity);
  }

  // Helper methods for form building
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ActivityType selectedType, Function(ActivityType) onChanged) {
    return DropdownButtonFormField<ActivityType>(
      value: selectedType,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      items: ActivityType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_iconForType(type), size: 16),
              const SizedBox(width: 8),
              Text(_getActivityTypeName(type)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _buildCheckInToggle(bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          value ? 'Already completed' : 'Mark as completed',
          style: TextStyle(
            color: value ? Colors.green : Colors.grey.shade600,
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.flight:
        return 'Flight';
      case ActivityType.lodging:
        return 'Lodging';
      case ActivityType.restaurant:
        return 'Restaurant';
      case ActivityType.activity:
        return 'Activity';
      case ActivityType.transportation:
        return 'Transportation';
      case ActivityType.groundTransportation:
        return 'Ground Transportation';
      case ActivityType.carRental:
        return 'Car Rental';
      case ActivityType.rail:
        return 'Rail';
      case ActivityType.concert:
        return 'Concert';
      case ActivityType.theater:
        return 'Theater';
      case ActivityType.tour:
        return 'Tour';
      case ActivityType.ferry:
        return 'Ferry';
      case ActivityType.cruising:
        return 'Cruising';
      case ActivityType.meeting:
        return 'Meeting';
      case ActivityType.parking:
        return 'Parking';
      case ActivityType.map:
        return 'Map';
      case ActivityType.direction:
        return 'Direction';
      case ActivityType.note:
        return 'Note';
      default:
        return 'Other';
    }
  }

  String _getActivityTypeSearchName(ActivityType type) {
    switch (type) {
      case ActivityType.flight:
        return 'airport';
      case ActivityType.lodging:
        return 'hotel';
      case ActivityType.restaurant:
        return 'restaurant';
      case ActivityType.activity:
        return 'tourist_attraction';
      case ActivityType.transportation:
      case ActivityType.groundTransportation:
        return 'transit_station';
      case ActivityType.carRental:
        return 'car_rental';
      case ActivityType.rail:
        return 'train_station';
      case ActivityType.concert:
      case ActivityType.theater:
        return 'entertainment';
      case ActivityType.tour:
        return 'tourist_attraction';
      case ActivityType.ferry:
        return 'ferry';
      case ActivityType.cruising:
        return 'harbor';
      case ActivityType.meeting:
        return 'business';
      case ActivityType.parking:
        return 'parking';
      default:
        return 'establishment';
    }
  }

  ActivityType _getActivityTypeFromCategory(String category) {
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('flight') || lowerCategory.contains('airport')) {
      return ActivityType.flight;
    } else if (lowerCategory.contains('hotel') || lowerCategory.contains('lodging')) {
      return ActivityType.lodging;
    } else if (lowerCategory.contains('restaurant') || lowerCategory.contains('food')) {
      return ActivityType.restaurant;
    } else if (lowerCategory.contains('transport') || lowerCategory.contains('bus') || lowerCategory.contains('taxi')) {
      return ActivityType.transportation;
    } else if (lowerCategory.contains('train') || lowerCategory.contains('rail')) {
      return ActivityType.rail;
    } else if (lowerCategory.contains('car rental')) {
      return ActivityType.carRental;
    } else if (lowerCategory.contains('concert') || lowerCategory.contains('music')) {
      return ActivityType.concert;
    } else if (lowerCategory.contains('theater') || lowerCategory.contains('show')) {
      return ActivityType.theater;
    } else if (lowerCategory.contains('tour')) {
      return ActivityType.tour;
    } else if (lowerCategory.contains('ferry') || lowerCategory.contains('boat')) {
      return ActivityType.ferry;
    } else if (lowerCategory.contains('cruise')) {
      return ActivityType.cruising;
    } else if (lowerCategory.contains('meeting') || lowerCategory.contains('business')) {
      return ActivityType.meeting;
    } else if (lowerCategory.contains('parking')) {
      return ActivityType.parking;
    } else if (lowerCategory.contains('map') || lowerCategory.contains('navigation')) {
      return ActivityType.map;
    } else if (lowerCategory.contains('direction')) {
      return ActivityType.direction;
    } else if (lowerCategory.contains('note')) {
      return ActivityType.note;
    } else {
      return ActivityType.activity; // Default to general activity
    }
  }

  void _addActivity(ActivityModel activity) {
    setState(() {
      _activities.add(activity);
      _hasChanges = true;
    });
    _saveChanges();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity added successfully')),
      );
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
