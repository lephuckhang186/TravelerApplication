import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'search_place_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../models/activity_models.dart';
import '../../providers/trip_planning_provider.dart';
import '../../services/trip_planning_service.dart';
import '../../services/trip_storage_service.dart';
import '../../../expense_management/data/services/expense_service.dart';
import '../../../expense_management/presentation/providers/expense_provider.dart';
import '../../services/trip_expense_integration_service.dart';

class PlannerDetailScreen extends StatefulWidget {
  final TripModel trip;

  const PlannerDetailScreen({super.key, required this.trip});

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  final TripPlanningService _tripService = TripPlanningService();
  final TripStorageService _storageService = TripStorageService();
  final ExpenseService _expenseService = ExpenseService();
  final TripExpenseIntegrationService _integrationService = TripExpenseIntegrationService();
  ExpenseProvider? _expenseProvider;

  late TripModel _trip;
  late List<ActivityModel> _activities;
  bool _isDeleting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _activities = List<ActivityModel>.from(widget.trip.activities);
    _loadActivitiesFromServer();
    // Get expense provider from context after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        _integrationService.setExpenseProvider(_expenseProvider!);
      } catch (e) {
        // ExpenseProvider not available in this context
        print('ExpenseProvider not found: $e');
      }
    });
  }

  /// Load activities from server to ensure we have the latest data
  Future<void> _loadActivitiesFromServer() async {
    if (_trip.id == null) return;
    
    try {
      final serverActivities = await _tripService.getActivities(tripId: _trip.id);
      setState(() {
        // Merge server activities with local ones, prioritizing server data
        final Map<String, ActivityModel> activityMap = {};
        
        // First add local activities
        for (final activity in _activities) {
          if (activity.id != null) {
            activityMap[activity.id!] = activity;
          }
        }
        
        // Then add/override with server activities
        for (final activity in serverActivities) {
          if (activity.id != null) {
            activityMap[activity.id!] = activity;
          }
        }
        
        _activities = activityMap.values.toList();
        // Sort by start date
        _activities.sort((a, b) {
          if (a.startDate == null && b.startDate == null) return 0;
          if (a.startDate == null) return 1;
          if (b.startDate == null) return -1;
          return a.startDate!.compareTo(b.startDate!);
        });
      });
    } catch (e) {
      debugPrint('Failed to load activities from server: $e');
      // Continue with local activities if server fails
    }
  }

  Future<bool> _handleWillPop() async {
    Navigator.pop(context, _hasChanges ? _trip : null);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
            onPressed: _handleWillPop,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                'Private',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onPressed: _isDeleting ? null : _showMoreOptions,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTripHeader(),
            Expanded(child: _buildTimeline()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isDeleting ? null : _showAddActivityModal,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTripHeader() {
    final dateRange =
        '${_formatDate(_trip.startDate)} - ${_formatDate(_trip.endDate)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.travel_explore,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trip.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _trip.destination,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      dateRange,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty,
                  size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'No plans yet',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start building your itinerary by adding flights, meals, visits or custom notes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) =>
          _buildTimelineItem(_activities[index], index),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _activities.length,
    );
  }

  Widget _buildTimelineItem(ActivityModel activity, int index) {
    final isLast = index == _activities.length - 1;
    final icon = _iconForType(activity.activityType);
    final color = activity.checkIn 
        ? Colors.green // Checked-in color
        : _colorForType(activity.activityType);
    final timeLabel = activity.startDate != null
        ? _formatTime(activity.startDate!)
        : '--';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: activity.startDate != null
              ? Text(
                  timeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                )
              : const SizedBox(),
        ),
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
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
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Check-in button
                    IconButton(
                      icon: Icon(
                        activity.checkIn ? Icons.check_circle : Icons.check_circle_outline,
                        color: activity.checkIn ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _toggleCheckIn(activity),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteActivity(activity);
                        } else if (value == 'edit_cost') {
                          _showRealCostInput(activity);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit_cost',
                          child: Text('Add Real Cost'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Remove'),
                        ),
                      ],
                    )
                  ],
                ),
                if (activity.description != null &&
                    activity.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.description!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
                if (activity.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location!.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Budget information - show expected cost before check-in, actual cost after
                if (activity.budget != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Before check-in: Show expected cost only
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
                              const Icon(
                                Icons.schedule,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expected: ${_formatCurrency(activity.budget!.estimatedCost)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // After check-in: Show actual cost
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
                              const Icon(
                                Icons.receipt,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Spent: ${_formatCurrency(activity.budget!.actualCost!)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // After check-in but no actual cost recorded
                      if (activity.checkIn && activity.budget!.actualCost == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                style: GoogleFonts.inter(
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
                ],
              ],
            ),
          ),
        ),
      ],
    );
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          'Add a plan',
                          style: GoogleFonts.inter(
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchPlaceScreen(),
                            ),
                          );

                          if (result != null) {
                            setModalState(() {
                              selectedPlace = result['place'];
                              titleController.text = result['category'];
                              descriptionController.text = result['place']['display_name'];
                            });
                          }
                        },
                        child: const Text('Search for a place'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Notes',
                      hint: 'Add extra details (optional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: expectedCostController,
                      label: 'Expected Cost (VND)',
                      hint: 'Enter estimated cost (optional)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildCheckInToggle(checkInStatus, (value) {
                      setModalState(() => checkInStatus = value);
                    }),
                    const SizedBox(height: 16),
                    _buildTypeSelector(selectedType, (value) {
                      setModalState(() => selectedType = value);
                    }),
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
                          final expectedCost = expectedCostController.text.trim().isEmpty 
                              ? null 
                              : double.tryParse(expectedCostController.text.trim());
                          
                          // Create budget if expected cost is provided
                          BudgetModel? budget;
                          if (expectedCost != null) {
                            budget = BudgetModel(
                              estimatedCost: expectedCost,
                              currency: 'VND',
                            );
                          }
                          
                          final newActivity = ActivityModel(
                            id:
                                'local_act_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            description: descriptionController.text.trim().isEmpty
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
                                    latitude: double.parse(selectedPlace['lat']),
                                    longitude: double.parse(selectedPlace['lon']),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
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
          style: GoogleFonts.inter(
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
      ActivityType selected, ValueChanged<ActivityType> onChanged) {
    final types = ActivityType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.inter(
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
              labelStyle: GoogleFonts.inter(
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
        return '✈️ Chuyến bay';
      case ActivityType.activity:
        return '🎯 Hoạt động';
      case ActivityType.lodging:
        return '🏨 Lưu trú';
      case ActivityType.carRental:
        return '🚗 Thuê xe';
      case ActivityType.concert:
        return '🎵 Hòa nhạc';
      case ActivityType.cruising:
        return '🛳️ Du thuyền';
      case ActivityType.direction:
        return '🧭 Chỉ đường';
      case ActivityType.ferry:
        return '⛴️ Phà';
      case ActivityType.groundTransportation:
        return '🚌 Di chuyển mặt đất';
      case ActivityType.map:
        return '🗺️ Bản đồ';
      case ActivityType.meeting:
        return '🤝 Cuộc họp';
      case ActivityType.note:
        return '📝 Ghi chú';
      case ActivityType.parking:
        return '🅿️ Đỗ xe';
      case ActivityType.rail:
        return '🚂 Tàu hỏa';
      case ActivityType.restaurant:
        return '🍽️ Nhà hàng';
      case ActivityType.theater:
        return '🎭 Rạp hát';
      case ActivityType.tour:
        return '🎫 Tour du lịch';
      case ActivityType.transportation:
        return '🚇 Di chuyển';
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
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Trip Info'),
              subtitle: const Text('Rename or update the description'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Trip'),
              subtitle: const Text('Remove this trip and all its data'),
              onTap: _confirmDeleteTrip,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addActivity(ActivityModel activity) async {
    try {
      // First, try to create the activity on the server
      ActivityModel createdActivity;
      try {
        createdActivity = await _tripService.createActivity(activity);
      } catch (e) {
        debugPrint('Failed to create activity on server: $e');
        // If server fails, continue with local storage only
        createdActivity = activity;
      }
      
      setState(() {
        _activities.add(createdActivity);
      });
      await _persistTripChanges();
      
      // Don't auto-create expense - only create on check-in
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteActivity(ActivityModel activity) async {
    try {
      // Try to delete from server if activity has an ID
      if (activity.id != null && !activity.id!.startsWith('local_')) {
        try {
          await _tripService.deleteActivity(activity.id!);
        } catch (e) {
          debugPrint('Failed to delete activity from server: $e');
        }
      }
      
      setState(() {
        _activities.remove(activity);
      });
      await _persistTripChanges();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity removed successfully'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _persistTripChanges() async {
    final updatedTrip = _trip.copyWith(
      activities: List<ActivityModel>.from(_activities),
    );
    final storedTrip = await _storageService.saveTrip(updatedTrip);
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
            'This action cannot be undone and will remove all activities.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
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
        await _storageService.deleteTrip(_trip.id!);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  Color _colorForType(ActivityType type) {
    switch (type) {
      case ActivityType.flight:
        return const Color(0xFF4CAF50);
      case ActivityType.restaurant:
        return const Color(0xFF2196F3);
      case ActivityType.tour:
        return const Color(0xFF9C27B0);
      case ActivityType.lodging:
        return const Color(0xFF607D8B);
      case ActivityType.carRental:
        return const Color(0xFFFF9800);
      case ActivityType.note:
        return const Color(0xFF795548);
      default:
        return AppColors.primary;
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
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} VND';
  }

  void _toggleCheckIn(ActivityModel activity) async {
    try {
      if (!activity.checkIn) {
        // Checking in - prompt for actual cost
        await _checkInWithActualCost(activity);
      } else {
        // Checking out - just toggle status
        final updatedActivity = activity.copyWith(checkIn: false);
        await _updateActivityCheckIn(updatedActivity);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checked out'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid cost')),
                  );
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
  Future<void> _performCheckIn(ActivityModel activity, double actualCost) async {
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked in! ${actualCost > 0 ? "Expense created." : ""}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Update activity check-in status
  Future<void> _updateActivityCheckIn(ActivityModel updatedActivity) async {
    final index = _activities.indexWhere((a) => a.id == updatedActivity.id);
    if (index != -1) {
      setState(() {
        _activities[index] = updatedActivity;
      });
      await _persistTripChanges();
    }
  }

  /// Create expense for checked-in activity
  Future<void> _createExpenseForCheckedInActivity(ActivityModel activity) async {
    try {
      if (activity.budget?.actualCost == null || activity.budget!.actualCost! <= 0) {
        return;
      }

      final success = await _integrationService.syncActivityExpense(activity);
      
      if (!success) {
        // Fallback to direct expense service call
        await _expenseService.createExpenseFromActivity(
          amount: activity.budget!.actualCost!,
          category: activity.activityType.value,
          description: '${activity.title}',
          activityId: activity.id,
          tripId: _trip.id,
        );
      }

      debugPrint('Created expense for checked-in activity: ${activity.title} (${activity.budget!.actualCost} VND)');
    } catch (e) {
      debugPrint('Failed to create expense for checked-in activity: $e');
    }
  }

  void _showRealCostInput(ActivityModel activity) {
    final costController = TextEditingController();
    if (activity.budget?.actualCost != null) {
      costController.text = activity.budget!.actualCost!.toString();
    }

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
            left: 20,
            right: 20,
            top: 24,
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
              Text(
                'Add Real Cost',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Activity: ${activity.title}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: costController,
                label: 'Actual Cost (VND)',
                hint: 'Enter the real cost spent',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveRealCost(activity, costController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _saveRealCost(ActivityModel activity, String costText) async {
    final cost = double.tryParse(costText.trim());
    if (cost == null || cost < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid cost amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);

    try {
      // Update budget with actual cost
      final existingBudget = activity.budget ?? BudgetModel(
        estimatedCost: 0,
        currency: 'VND',
      );
      final updatedBudget = BudgetModel(
        estimatedCost: existingBudget.estimatedCost,
        actualCost: cost,
        currency: existingBudget.currency,
      );
      final updatedActivity = activity.copyWith(budget: updatedBudget);
      
      // Update in memory
      final index = _activities.indexOf(activity);
      if (index != -1) {
        setState(() {
          _activities[index] = updatedActivity;
        });
      }
      
      await _persistTripChanges();
      
      // Sync with expense management
      await _syncExpense(updatedActivity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Real cost saved and synced to expenses!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save cost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncExpense(ActivityModel activity) async {
    if (activity.budget?.actualCost == null) return;
    
    try {
      // Use integration service for better tracking
      final success = await _integrationService.syncActivityExpense(activity);
      
      if (!success) {
        // Fallback to direct service call if integration fails
        await _expenseService.createExpenseFromActivity(
          amount: activity.budget!.actualCost!,
          category: activity.activityType.value,
          description: '${activity.title}',
          activityId: activity.id,
          tripId: _trip.id,
        );
      }
    } catch (e) {
      debugPrint('Failed to sync expense: $e');
      // Don't show error to user as this is background sync
    }
  }

}
