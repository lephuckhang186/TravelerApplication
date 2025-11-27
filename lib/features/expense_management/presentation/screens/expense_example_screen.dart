import 'package:flutter/material.dart';
import '../providers/expense_provider.dart';
import '../../data/models/expense_models.dart';
import '../../../../services/auth_service.dart';

/// Example screen showing how to use the expense management system
class ExpenseExampleScreen extends StatefulWidget {
  const ExpenseExampleScreen({super.key});

  @override
  State<ExpenseExampleScreen> createState() => _ExpenseExampleScreenState();
}

class _ExpenseExampleScreenState extends State<ExpenseExampleScreen> {
  late ExpenseProvider _expenseProvider;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  ExpenseCategory _selectedCategory = ExpenseCategory.foodBeverage;

  @override
  void initState() {
    super.initState();
    _expenseProvider = ExpenseProvider();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Initialize authentication with Firebase token
    await _setupAuthentication();
    
    // Load real user data from backend
    await _expenseProvider.loadData();
  }
  
  Future<void> _setupAuthentication() async {
    try {
      final AuthService authService = AuthService();
      final token = await authService.getIdToken();
      
      if (token != null) {
        // Set authentication token in expense provider
        _expenseProvider.setAuthToken(token);
      } else {
        // User not authenticated, redirect to auth screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      print('Error setting up authentication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _expenseProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _expenseProvider.refreshAllData(),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _expenseProvider,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Expense Section
                _buildAddExpenseCard(),
                const SizedBox(height: 16),

                // Budget Status
                _buildBudgetStatusCard(),
                const SizedBox(height: 16),

                // Recent Expenses
                _buildRecentExpensesCard(),
                const SizedBox(height: 16),

                // Category Status
                _buildCategoryStatusCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddExpenseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Amount field
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (VND)',
                border: OutlineInputBorder(),
                prefixText: '₫ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            // Category dropdown
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ExpenseCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _expenseProvider.isLoading ? null : _addExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: _expenseProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Expense'),
              ),
            ),
            
            if (_expenseProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _expenseProvider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStatusCard() {
    final budgetStatus = _expenseProvider.budgetStatus;
    
    if (_expenseProvider.isBudgetLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (budgetStatus == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget Setup Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Create a budget to track your spending and stay within limits.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showCreateBudgetDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Budget'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Budget'),
                    Text(
                      '₫${budgetStatus.totalBudget.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Spent'),
                    Text(
                      '₫${budgetStatus.totalSpent.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: budgetStatus.isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            LinearProgressIndicator(
              value: budgetStatus.percentageUsed / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                budgetStatus.isOverBudget ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            
            Text('${budgetStatus.percentageUsed.toStringAsFixed(1)}% used'),
            Text('Status: ${budgetStatus.burnRateStatus}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpensesCard() {
    if (_expenseProvider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final expenses = _expenseProvider.expenses.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (expenses.isEmpty)
              Column(
                children: [
                  const Text('No expenses yet'),
                  const SizedBox(height: 16),
                  if (_expenseProvider.currentTrip == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showCreateTripDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create Trip First'),
                      ),
                    ),
                ],
              )
            else
              ...expenses.map((expense) {
                return ListTile(
                  leading: Icon(
                    _getCategoryIcon(expense.category),
                    color: Colors.blue[600],
                  ),
                  title: Text(
                    expense.description.isNotEmpty 
                        ? expense.description 
                        : expense.category.displayName,
                  ),
                  subtitle: Text(
                    '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                  ),
                  trailing: Text(
                    '₫${expense.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStatusCard() {
    if (_expenseProvider.isCategoryLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final categories = _expenseProvider.categoryStatus;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (categories.isEmpty)
              const Text('No category data available')
            else
              ...categories.map((category) {
                return ListTile(
                  title: Text(category.category.displayName),
                  subtitle: Text('Allocated: ₫${category.allocated.toStringAsFixed(0)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₫${category.spent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: category.isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                      Text('${category.percentageUsed.toStringAsFixed(1)}%'),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _addExpense() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final success = await _expenseProvider.createExpense(
      amount,
      _selectedCategory,
      description: _descriptionController.text.trim(),
    );

    if (success) {
      _amountController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.foodBeverage:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.activities:
        return Icons.local_activity;
      case ExpenseCategory.shopping:
        return Icons.shopping_cart;
      case ExpenseCategory.miscellaneous:
        return Icons.more_horiz;
      case ExpenseCategory.emergency:
        return Icons.emergency;
    }
  }

  Future<void> _handleSignOut() async {
    try {
      final authService = AuthService();
      await authService.signOut();
      
      // Clear expense provider authentication
      _expenseProvider.clearAuthToken();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateTripDialog() {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You need to create a trip first to track expenses.'),
            const SizedBox(height: 16),
            TextField(
              controller: startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date',
                hintText: 'YYYY-MM-DD',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  startDate = date;
                  startDateController.text = date.toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(
                labelText: 'End Date',
                hintText: 'YYYY-MM-DD',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: startDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  endDate = date;
                  endDateController.text = date.toString().split(' ')[0];
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (startDate != null && endDate != null) {
                Navigator.pop(context);
                final success = await _expenseProvider.createTrip(startDate!, endDate!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateBudgetDialog() {
    final budgetController = TextEditingController();
    final dailyLimitController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: budgetController,
              decoration: const InputDecoration(
                labelText: 'Total Budget (VND)',
                prefixText: '₫ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dailyLimitController,
              decoration: const InputDecoration(
                labelText: 'Daily Limit (VND) - Optional',
                prefixText: '₫ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final budgetText = budgetController.text.trim();
              if (budgetText.isNotEmpty) {
                final budget = double.tryParse(budgetText);
                if (budget != null && budget > 0) {
                  Navigator.pop(context);
                  
                  final dailyLimitText = dailyLimitController.text.trim();
                  final dailyLimit = dailyLimitText.isNotEmpty 
                    ? double.tryParse(dailyLimitText) 
                    : null;
                  
                  final success = await _expenseProvider.createBudget(
                    budget,
                    dailyLimit: dailyLimit,
                  );
                  
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}