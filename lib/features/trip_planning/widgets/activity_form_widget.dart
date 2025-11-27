import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity_models.dart';
import '../utils/expense_integration.dart';

/// Form widget for creating/editing activities with expense integration
class ActivityFormWidget extends StatefulWidget {
  final ActivityModel? activity;
  final Function(ActivityModel) onSave;
  final VoidCallback? onCancel;

  const ActivityFormWidget({
    super.key,
    this.activity,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<ActivityFormWidget> createState() => _ActivityFormWidgetState();
}

class _ActivityFormWidgetState extends State<ActivityFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _actualCostController = TextEditingController();

  // Location fields
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  // Contact fields
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  ActivityType _selectedType = ActivityType.activity;
  ActivityStatus _selectedStatus = ActivityStatus.planned;
  Priority _selectedPriority = Priority.medium;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCurrency = 'VND';
  List<String> _tags = [];
  bool _checkIn = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.activity != null) {
      final activity = widget.activity!;
      _titleController.text = activity.title;
      _descriptionController.text = activity.description ?? '';
      _notesController.text = activity.notes ?? '';
      _selectedType = activity.activityType;
      _selectedStatus = activity.status;
      _selectedPriority = activity.priority;
      _startDate = activity.startDate;
      _endDate = activity.endDate;
      _checkIn = activity.checkIn;
      _tags = List.from(activity.tags);

      // Budget fields
      if (activity.budget != null) {
        _estimatedCostController.text = activity.budget!.estimatedCost.toString();
        if (activity.budget!.actualCost != null) {
          _actualCostController.text = activity.budget!.actualCost.toString();
        }
        _selectedCurrency = activity.budget!.currency;
      }

      // Location fields
      if (activity.location != null) {
        _locationNameController.text = activity.location!.name;
        _addressController.text = activity.location!.address ?? '';
        _cityController.text = activity.location!.city ?? '';
        _countryController.text = activity.location!.country ?? '';
      }

      // Contact fields
      if (activity.contact != null) {
        _contactNameController.text = activity.contact!.name ?? '';
        _phoneController.text = activity.contact!.phone ?? '';
        _emailController.text = activity.contact!.email ?? '';
        _websiteController.text = activity.contact!.website ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _estimatedCostController.dispose();
    _actualCostController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? 'Create Activity' : 'Edit Activity'),
        actions: [
          TextButton(
            onPressed: _saveActivity,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 20),
              _buildDateTimeSection(),
              const SizedBox(height: 20),
              _buildBudgetSection(),
              const SizedBox(height: 20),
              _buildLocationSection(),
              const SizedBox(height: 20),
              _buildContactSection(),
              const SizedBox(height: 20),
              _buildAdditionalOptionsSection(),
              const SizedBox(height: 20),
              _buildExpenseInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter activity title',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter activity description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ActivityType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Activity Type *'),
              items: ActivityType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.value.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ActivityStatus>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ActivityStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.value.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Priority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: Priority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.value.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate?.toString() ?? 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate?.toString() ?? 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Budget & Expense Integration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (ExpenseIntegration.shouldAutoCreateExpense(_selectedType))
                  const Chip(
                    label: Text('Auto Expense', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _estimatedCostController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Cost *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Estimated cost is required';
                      }
                      final cost = double.tryParse(value!);
                      if (cost == null || cost < 0) {
                        return 'Please enter a valid cost';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _actualCostController,
                    decoration: const InputDecoration(
                      labelText: 'Actual Cost',
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: ['VND', 'USD', 'EUR'].map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expense Category Mapping',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This activity will be categorized as: ${ExpenseIntegration.getExpenseCategoryDisplayName(ExpenseIntegration.mapActivityTypeToExpenseCategory(_selectedType))}',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationNameController,
              decoration: const InputDecoration(
                labelText: 'Location Name',
                hintText: 'e.g., Restaurant ABC',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter full address',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                prefixIcon: Icon(Icons.web),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add any additional notes...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Check-in Required'),
              subtitle: const Text('Mark if this activity requires check-in'),
              value: _checkIn,
              onChanged: (value) {
                setState(() {
                  _checkIn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseInfoSection() {
    if (widget.activity?.expenseInfo.hasExpense != true) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Integration Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Expense Synchronized',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Expense ID: ${widget.activity!.expenseInfo.expenseId}'),
                  Text('Category: ${widget.activity!.expenseInfo.expenseCategory}'),
                  Text('Auto-synced: ${widget.activity!.expenseInfo.autoSynced ? "Yes" : "No"}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveActivity() {
    if (!_formKey.currentState!.validate()) return;

    // Create budget
    BudgetModel? budget;
    if (_estimatedCostController.text.isNotEmpty) {
      budget = BudgetModel(
        estimatedCost: double.parse(_estimatedCostController.text),
        actualCost: _actualCostController.text.isNotEmpty 
            ? double.parse(_actualCostController.text) 
            : null,
        currency: _selectedCurrency,
        category: ExpenseIntegration.mapActivityTypeToExpenseCategory(_selectedType),
      );
    }

    // Create location
    LocationModel? location;
    if (_locationNameController.text.isNotEmpty) {
      location = LocationModel(
        name: _locationNameController.text,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        country: _countryController.text.isNotEmpty ? _countryController.text : null,
      );
    }

    // Create contact
    ContactModel? contact;
    if (_contactNameController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _websiteController.text.isNotEmpty) {
      contact = ContactModel(
        name: _contactNameController.text.isNotEmpty ? _contactNameController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      );
    }

    // Create activity
    final activity = ActivityModel(
      id: widget.activity?.id,
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      activityType: _selectedType,
      status: _selectedStatus,
      priority: _selectedPriority,
      startDate: _startDate,
      endDate: _endDate,
      budget: budget,
      location: location,
      contact: contact,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      tags: _tags,
      checkIn: _checkIn,
      createdBy: widget.activity?.createdBy,
      createdAt: widget.activity?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      expenseInfo: widget.activity?.expenseInfo,
    );

    widget.onSave(activity);
  }
}