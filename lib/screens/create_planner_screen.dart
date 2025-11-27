import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: const Color(0xFF1976D2),
              fontSize: 16,
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'Create Trip',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canSave() ? _saveTrip : null,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: _canSave() ? const Color(0xFF1976D2) : Colors.grey.shade400,
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
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
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
              borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
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
          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
    return _destinationController.text.isNotEmpty;
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

  void _saveTrip() {
    if (!_canSave()) return;
    
    // Create trip logic
    final tripData = {
      'name': _tripNameController.text.isNotEmpty 
          ? _tripNameController.text 
          : _destinationController.text,
      'destination': _destinationController.text,
      'startDate': _startDate,
      'endDate': _endDate,
      'description': _descriptionController.text,
    };
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip "${tripData['name']}" created successfully!'),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Navigate back
    Navigator.pop(context, tripData);
  }
}