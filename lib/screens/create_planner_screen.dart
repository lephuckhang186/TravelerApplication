import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePlannerScreen extends StatefulWidget {
  const CreatePlannerScreen({super.key});

  @override
  State<CreatePlannerScreen> createState() => _CreatePlannerScreenState();
}

class _CreatePlannerScreenState extends State<CreatePlannerScreen> {
  final _plannerNameController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _plannerType = 'Private';

  @override
  void dispose() {
    _plannerNameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create New Planner',
          style: GoogleFonts.quattrocento(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _createPlanner,
            child: Text(
              'Create',
              style: GoogleFonts.quattrocento(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B61FF),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planner Name
            _buildSectionTitle('Planner Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _plannerNameController,
              hintText: 'Enter planner name (e.g., Da Nang Trip)',
              icon: Icons.edit,
            ),
            
            const SizedBox(height: 24),
            
            // Destination
            _buildSectionTitle('Destination'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _destinationController,
              hintText: 'Enter destination (e.g., Da Nang, Vietnam)',
              icon: Icons.location_on,
            ),
            
            const SizedBox(height: 24),
            
            // Travel Dates
            _buildSectionTitle('Travel Dates'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    title: 'Start Date',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateSelector(
                    title: 'End Date',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Planner Type
            _buildSectionTitle('Planner Type'),
            const SizedBox(height: 12),
            _buildPlannerTypeSelector(),
            
            const SizedBox(height: 32),
            
            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createPlanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Create Planner',
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.quattrocento(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.quattrocento(
          fontSize: 14,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.quattrocento(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.quattrocento(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  date != null 
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Select date',
                  style: GoogleFonts.quattrocento(
                    fontSize: 14,
                    color: date != null ? Colors.black87 : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption('Private', Icons.lock_outline),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption('Shared', Icons.share_outlined),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String type, IconData icon) {
    final isSelected = _plannerType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _plannerType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B61FF).withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: GoogleFonts.quattrocento(
                fontSize: 14,
                color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7B61FF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _createPlanner() {
    if (_plannerNameController.text.isEmpty) {
      _showMessage('Please enter a planner name');
      return;
    }

    if (_destinationController.text.isEmpty) {
      _showMessage('Please enter a destination');
      return;
    }

    // Create the planner data
    final plannerData = {
      'name': _plannerNameController.text,
      'destination': _destinationController.text,
      'startDate': _startDate,
      'endDate': _endDate,
      'type': _plannerType,
    };

    // Debug print
    print('Creating planner with data: $plannerData');

    // Show success message and immediately go back with data
    _showMessage('Planner "${_plannerNameController.text}" created successfully!');
    
    // Return immediately with the data
    Navigator.pop(context, plannerData);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7B61FF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}