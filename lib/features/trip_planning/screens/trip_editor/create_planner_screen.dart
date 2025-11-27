import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_planning_provider.dart';
import '../../services/trip_planning_service.dart';
import '../../services/trip_storage_service.dart';

class CreatePlannerScreen extends StatefulWidget {
  const CreatePlannerScreen({super.key});

  @override
  State<CreatePlannerScreen> createState() => _CreatePlannerScreenState();
}

class _CreatePlannerScreenState extends State<CreatePlannerScreen> {
  final _tripNameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.quattrocento(
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'Create Trip',
          style: GoogleFonts.quattrocento(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canSave() && !_isSaving ? _saveTrip : null,
            child: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: GoogleFonts.quattrocento(
                color: _canSave() && !_isSaving
                    ? AppColors.primary
                    : Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Trip Name Field
            _buildInputField(
              label: 'Trip Name',
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
            
            // Description Field
            _buildInputField(
              label: 'Description',
              controller: _descriptionController,
              hintText: 'Add trip description (optional)',
              maxLines: 4,
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quattrocento(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.quattrocento(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.quattrocento(
              fontSize: 18,
              color: Colors.grey.shade400,
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

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
          style: GoogleFonts.quattrocento(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey),
              ),
            ),
            child: Text(
              _formatDate(date),
              style: GoogleFonts.quattrocento(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    String dayName = days[date.weekday - 1];
    String day = date.day.toString();
    String month = months[date.month - 1];
    String year = date.year.toString();
    
    return '$dayName, $day $month $year';
  }

  bool _canSave() {
    return _destinationController.text.trim().isNotEmpty;
  }

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
        // If end date is before start date, set end date to start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

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

      TripModel? createdTrip;
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
        );
      }

      createdTrip ??= await _createTripFallback(
        tripName: tripName,
        destination: _destinationController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      navigator.pop(); // close loading dialog

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip "${createdTrip.name}" created successfully!'),
          backgroundColor: AppColors.primary,
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

  Future<TripModel> _createTripFallback({
    required String tripName,
    required String destination,
    String? description,
  }) async {
    final trip = TripModel(
      name: tripName,
      destination: destination,
      startDate: _startDate,
      endDate: _endDate,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final tripService = TripPlanningService();
      final createdTrip = await tripService.createTrip(trip);
      final storageService = TripStorageService();
      return await storageService.saveTrip(createdTrip);
    } catch (_) {
      final storageService = TripStorageService();
      return await storageService.saveTrip(
        trip.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
    }
  }
}
