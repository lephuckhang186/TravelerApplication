import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../models/activity_models.dart';
import '../../providers/trip_planning_provider.dart';
import '../../services/trip_planning_service.dart';
import '../../services/trip_storage_service.dart';

class PlannerDetailScreen extends StatefulWidget {
  final TripModel trip;

  const PlannerDetailScreen({super.key, required this.trip});

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  final TripPlanningService _tripService = TripPlanningService();
  final TripStorageService _storageService = TripStorageService();

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
      print('Failed to load activities from server: $e');
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
    final color = _colorForType(activity.activityType);
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
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteActivity(activity);
                        }
                      },
                      itemBuilder: (context) => [
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
    ActivityType selectedType = ActivityType.activity;
    DateTime selectedDate = _trip.startDate;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

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
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Notes',
                      hint: 'Add extra details (optional)',
                      maxLines: 3,
                    ),
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

  Widget _buildTypeSelector(
      ActivityType selected, ValueChanged<ActivityType> onChanged) {
    final types = [
      ActivityType.flight,
      ActivityType.restaurant,
      ActivityType.activity,
      ActivityType.tour,
      ActivityType.lodging,
      ActivityType.note,
    ];

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
              label: Text(type.value.replaceAll('_', ' ').toUpperCase()),
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
        print('Failed to create activity on server: $e');
        // If server fails, continue with local storage only
        createdActivity = activity;
      }
      
      setState(() {
        _activities.add(createdActivity);
      });
      await _persistTripChanges();
      
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
          print('Failed to delete activity from server: $e');
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
}
