import 'package:flutter/material.dart';
import '../providers/expense_provider.dart';
import '../../data/models/expense_models.dart';

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
  ExpenseCategory _selectedCategory = ExpenseCategory.food;

  @override
  void initState() {
    super.initState();
    _expenseProvider = ExpenseProvider();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Create a sample trip and budget if none exist
    await _expenseProvider.createTrip(
      DateTime.now().subtract(const Duration(days: 5)),
      DateTime.now().add(const Duration(days: 25)),
    );

    await _expenseProvider.createBudget(
      50000.0, // 50K VND budget
      dailyLimit: 2000.0, // 2K daily limit
      categoryAllocations: {
        'FOOD': 20000.0,
        'TRANSPORTATION': 15000.0,
        'ENTERTAINMENT': 10000.0,
        'OTHER': 5000.0,
      },
    );

    // Load data
    _expenseProvider.refreshAllData();
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
        title: const Text('Expense Management Example'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No budget data available'),
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
              const Text('No expenses yet')
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
                  title: Text(category.category),
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
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.shopping:
        return Icons.shopping_cart;
      case ExpenseCategory.health:
        return Icons.local_hospital;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.utilities:
        return Icons.power;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}