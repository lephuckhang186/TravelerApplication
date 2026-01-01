import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:intl/intl.dart';
import '../../Core/theme/app_theme.dart';
import '../../Core/providers/app_mode_provider.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../providers/trip_planning_provider.dart';
import '../providers/collaboration_provider.dart';
import '../services/trip_planning_service.dart';
import '../services/firebase_trip_service.dart';
import '../../Expense/services/expense_service.dart';
import '../../Expense/models/expense_models.dart';

/// Custom text input formatter to add thousand separators (dots) for currency input.
class NumberTextInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    // Format with thousand separators using dots for VND representation
    int value = int.parse(digits);
    String formatted = _formatter.format(value).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// A comprehensive screen for creating a new travel trip.
///
/// Supports both private trips and collaborative (shared) trips depending on
/// the context. It captures fundamental trip details including name, destination,
/// start/end dates, total budget, and an optional description.
/// It also integrates with the Expense module to initialize a trip budget there.
class CreatePlannerScreen extends StatefulWidget {
  /// Indicates if the trip to be created should be collaborative.
  final bool isCollaborative;

  /// Optional existing trip model for edit scenarios (though currently focused on creation).
  final TripModel? existingTrip;

  const CreatePlannerScreen({
    super.key,
    this.isCollaborative = false,
    this.existingTrip,
  });

  @override
  State<CreatePlannerScreen> createState() => _CreatePlannerScreenState();
}

class _CreatePlannerScreenState extends State<CreatePlannerScreen> {
  final _tripNameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimateGradient(
        duration: const Duration(seconds: 10),
        primaryColors: const [
          AppColors.steelBlue,
          Color(0xFF8BB8D8),
          Color.fromARGB(255, 183, 215, 243),
        ],
        secondaryColors: const [
          Color(0xFF8BB8D8),
          AppColors.steelBlue,
          AppColors.surface,
        ],
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Consumer<AppModeProvider>(
                      builder: (context, appMode, child) {
                        return Text(
                          appMode.isPrivateMode
                              ? 'Create Trip'
                              : 'Create Shared Trip',
                          style: const TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: _canSave() && !_isSaving ? _saveTrip : null,
                      child: Text(
                        _isSaving ? 'Saving...' : 'Save',
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          color: _canSave() && !_isSaving
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body content
              Expanded(
                child: Column(
                  children: [
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Trip Name Field
                            _buildInputField(
                              label: 'Trip Name*',
                              controller: _tripNameController,
                              hintText: 'Enter trip name',
                            ),

                            const SizedBox(height: 30),

                            // Destination Field
                            _buildInputField(
                              label: 'Destination City*',
                              controller: _destinationController,
                              hintText: 'Where are you going?',
                            ),

                            const SizedBox(height: 30),

                            // Start Date
                            _buildDateField(
                              label: 'Start Date*',
                              date: _startDate,
                              onTap: () => _selectStartDate(),
                            ),

                            const SizedBox(height: 30),

                            // End Date
                            _buildDateField(
                              label: 'End Date*',
                              date: _endDate,
                              onTap: () => _selectEndDate(),
                            ),

                            const SizedBox(height: 30),

                            // Budget Field
                            _buildInputField(
                              label: 'Total Budget (VND)*',
                              controller: _budgetController,
                              hintText: 'Enter total budget',
                              keyboardType: TextInputType.number,
                              inputFormatters: [NumberTextInputFormatter()],
                            ),

                            const SizedBox(height: 30),

                            // Description Field
                            _buildInputField(
                              label: 'Description',
                              controller: _descriptionController,
                              hintText: 'Add trip description (optional)',
                              maxLines: 4,
                            ),

                            const SizedBox(
                              height: 100,
                            ), // Extra space for scrolling
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build a styled input field with a label.
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Urbanist-Regular',
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  /// Helper to build a date selection field with a calendar icon.
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Formats a [DateTime] into a friendly string (e.g., "Mon, 1 Jan 2024").
  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

    String dayName = days[date.weekday - 1];
    String day = date.day.toString();
    String month = months[date.month - 1];
    String year = date.year.toString();

    return '$dayName, $day $month $year';
  }

  /// Validates that all required fields are filled.
  bool _canSave() {
    return _tripNameController.text.trim().isNotEmpty &&
        _destinationController.text.trim().isNotEmpty &&
        _budgetController.text.trim().isNotEmpty;
  }

  /// Opens the standard Material Date Picker for the trip's start date.
  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Adjust end date if it's now before the new start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  /// Opens the standard Material Date Picker for the trip's end date.
  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  /// Handles the save operation logic, including integration with providers and services.
  void _saveTrip() async {
    if (!_canSave() || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tripName = _tripNameController.text.trim().isNotEmpty
          ? _tripNameController.text.trim()
          : _destinationController.text.trim();

      final budgetAmount = _budgetController.text.trim().isNotEmpty
          ? double.tryParse(_budgetController.text.trim().replaceAll('.', ''))
          : null;

      TripModel? createdTrip;

      if (widget.isCollaborative) {
        // Create shared trip using collaboration provider
        final collaborationProvider = context.read<CollaborationProvider>();

        final sharedTrip = await collaborationProvider.createTrip(
          name: tripName,
          destination: _destinationController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          budget: budgetAmount,
        );

        if (sharedTrip != null) {
          createdTrip = sharedTrip.toTripModel();
          // Force refresh of collaboration data
          await collaborationProvider.initialize();
        }
      } else {
        // Create private trip
        TripPlanningProvider? provider;
        try {
          provider = context.read<TripPlanningProvider>();
        } catch (_) {
          provider = null;
        }

        if (provider != null) {
          createdTrip = await provider.createTrip(
            name: tripName,
            destination: _destinationController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            budget: budgetAmount,
          );
        } else {
          createdTrip = await _createTripFallback(
            tripName: tripName,
            destination: _destinationController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            budget: budgetAmount,
          );
        }
      }

      // Initialize an linked budget in the Expense module if an amount was provided
      if (budgetAmount != null && createdTrip != null) {
        await _createExpenseBudget(createdTrip.id!, budgetAmount);
      }

      navigator.pop(); // close loading dialog

      if (!mounted) return;

      final appModeForMessage = context.read<AppModeProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appModeForMessage.isCollaborationMode
                ? 'Shared trip created successfully!'
                : 'Trip created successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, createdTrip);
    } catch (e) {
      navigator.pop(); // close loading dialog
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create trip: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Automatically synchronizes the new trip with the standalone [ExpenseService].
  Future<void> _createExpenseBudget(String tripId, double budgetAmount) async {
    try {
      final expenseService = ExpenseService();

      // Create trip record for expense tracking
      final trip = Trip(
        startDate: _startDate,
        endDate: _endDate,
        name: _tripNameController.text.trim(),
        destination: _destinationController.text.trim(),
      );
      await expenseService.createTrip(trip);

      // Initialize daily budget limits
      final days = _endDate.difference(_startDate).inDays + 1;
      final dailyLimit = budgetAmount / (days > 0 ? days : 1);

      final budget = Budget(totalBudget: budgetAmount, dailyLimit: dailyLimit);
      await expenseService.createBudget(budget);
    } catch (e) {
      // Silently fail as this is a convenience feature
    }
  }

  /// Fallback mechanism for trip creation if primary provider fails.
  Future<TripModel> _createTripFallback({
    required String tripName,
    required String destination,
    String? description,
    double? budget,
  }) async {
    final trip = TripModel(
      name: tripName,
      destination: destination,
      startDate: _startDate,
      endDate: _endDate,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      budget: budget != null
          ? BudgetModel(estimatedCost: budget, currency: 'VND')
          : null,
    );

    try {
      final tripService = TripPlanningService();
      final createdTrip = await tripService.createTrip(trip);
      final firebaseService = FirebaseTripService();
      await firebaseService.saveTrip(createdTrip);
      return createdTrip;
    } catch (e) {
      // Direct Firebase save as ultimate fallback
      final firebaseService = FirebaseTripService();
      final tripWithId = trip.copyWith(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      );
      await firebaseService.saveTrip(tripWithId);
      return tripWithId;
    }
  }
}
