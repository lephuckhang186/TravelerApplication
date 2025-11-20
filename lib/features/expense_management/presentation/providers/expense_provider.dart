import 'package:flutter/foundation.dart';
import '../../data/models/expense_models.dart';
import '../../data/services/expense_service.dart';

/// Provider for managing expense state and API interactions
class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService;

  // State variables
  List<Expense> _expenses = [];
  BudgetStatus? _budgetStatus;
  List<CategoryStatus> _categoryStatus = [];
  ExpenseSummary? _expenseSummary;
  SpendingTrends? _spendingTrends;
  
  // Loading states
  bool _isLoading = false;
  bool _isBudgetLoading = false;
  bool _isCategoryLoading = false;
  bool _isSummaryLoading = false;
  bool _isTrendsLoading = false;
  
  // Error states
  String? _error;
  String? _budgetError;
  String? _categoryError;
  String? _summaryError;
  String? _trendsError;

  // Current filters
  ExpenseCategory? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  ExpenseProvider({ExpenseService? expenseService}) 
      : _expenseService = expenseService ?? ExpenseService();

  // Getters
  List<Expense> get expenses => _expenses;
  BudgetStatus? get budgetStatus => _budgetStatus;
  List<CategoryStatus> get categoryStatus => _categoryStatus;
  ExpenseSummary? get expenseSummary => _expenseSummary;
  SpendingTrends? get spendingTrends => _spendingTrends;
  
  bool get isLoading => _isLoading;
  bool get isBudgetLoading => _isBudgetLoading;
  bool get isCategoryLoading => _isCategoryLoading;
  bool get isSummaryLoading => _isSummaryLoading;
  bool get isTrendsLoading => _isTrendsLoading;
  
  String? get error => _error;
  String? get budgetError => _budgetError;
  String? get categoryError => _categoryError;
  String? get summaryError => _summaryError;
  String? get trendsError => _trendsError;

  ExpenseCategory? get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Authentication
  void setAuthToken(String token) {
    _expenseService.setAuthToken(token);
  }

  void clearAuthToken() {
    _expenseService.clearAuthToken();
  }

  /// Create a new trip
  Future<bool> createTrip(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    try {
      final trip = Trip(startDate: startDate, endDate: endDate);
      await _expenseService.createTrip(trip);
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new budget
  Future<bool> createBudget(
    double totalBudget, {
    double? dailyLimit,
    Map<String, double>? categoryAllocations,
  }) async {
    _setLoading(true);
    try {
      final budget = Budget(
        totalBudget: totalBudget,
        dailyLimit: dailyLimit,
        categoryAllocations: categoryAllocations,
      );
      await _expenseService.createBudget(budget);
      _clearError();
      // Refresh budget status after creation
      await fetchBudgetStatus();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new expense
  Future<bool> createExpense(
    double amount,
    ExpenseCategory category, {
    String description = '',
    DateTime? expenseDate,
  }) async {
    _setLoading(true);
    try {
      final request = ExpenseCreateRequest(
        amount: amount,
        category: category,
        description: description,
        expenseDate: expenseDate,
      );
      
      final newExpense = await _expenseService.createExpense(request);
      _expenses.insert(0, newExpense); // Add to beginning of list
      _clearError();
      
      // Refresh related data
      await Future.wait([
        fetchBudgetStatus(),
        fetchExpenseSummary(),
      ]);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch expenses with filters
  Future<void> fetchExpenses({
    ExpenseCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    try {
      _selectedCategory = category;
      _startDate = startDate;
      _endDate = endDate;
      
      _expenses = await _expenseService.getExpenses(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an expense
  Future<bool> deleteExpense(String expenseId) async {
    _setLoading(true);
    try {
      await _expenseService.deleteExpense(expenseId);
      _expenses.removeWhere((expense) => expense.id == expenseId);
      _clearError();
      
      // Refresh related data
      await Future.wait([
        fetchBudgetStatus(),
        fetchExpenseSummary(),
      ]);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch budget status
  Future<void> fetchBudgetStatus() async {
    _isBudgetLoading = true;
    _budgetError = null;
    notifyListeners();
    
    try {
      _budgetStatus = await _expenseService.getBudgetStatus();
      _budgetError = null;
    } catch (e) {
      _budgetError = e.toString();
    } finally {
      _isBudgetLoading = false;
      notifyListeners();
    }
  }

  /// Fetch category status
  Future<void> fetchCategoryStatus() async {
    _isCategoryLoading = true;
    _categoryError = null;
    notifyListeners();
    
    try {
      _categoryStatus = await _expenseService.getCategoryStatus();
      _categoryError = null;
    } catch (e) {
      _categoryError = e.toString();
    } finally {
      _isCategoryLoading = false;
      notifyListeners();
    }
  }

  /// Fetch expense summary
  Future<void> fetchExpenseSummary() async {
    _isSummaryLoading = true;
    _summaryError = null;
    notifyListeners();
    
    try {
      _expenseSummary = await _expenseService.getExpenseSummary();
      _summaryError = null;
    } catch (e) {
      _summaryError = e.toString();
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

  /// Fetch spending trends
  Future<void> fetchSpendingTrends() async {
    _isTrendsLoading = true;
    _trendsError = null;
    notifyListeners();
    
    try {
      _spendingTrends = await _expenseService.getSpendingTrends();
      _trendsError = null;
    } catch (e) {
      _trendsError = e.toString();
    } finally {
      _isTrendsLoading = false;
      notifyListeners();
    }
  }

  /// Export expense data
  Future<Map<String, dynamic>?> exportExpenseData() async {
    _setLoading(true);
    try {
      final data = await _expenseService.exportExpenseData();
      _clearError();
      return data;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      fetchExpenses(
        category: _selectedCategory,
        startDate: _startDate,
        endDate: _endDate,
      ),
      fetchBudgetStatus(),
      fetchCategoryStatus(),
      fetchExpenseSummary(),
      fetchSpendingTrends(),
    ]);
  }

  /// Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _startDate = null;
    _endDate = null;
    fetchExpenses();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get total spending for a specific period
  double getTotalSpendingForPeriod(DateTime start, DateTime end) {
    return _expenses
        .where((expense) =>
            expense.expenseDate.isAfter(start) &&
            expense.expenseDate.isBefore(end.add(const Duration(days: 1))))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get spending by category
  Map<ExpenseCategory, double> getSpendingByCategory() {
    final Map<ExpenseCategory, double> categorySpending = {};
    
    for (final expense in _expenses) {
      categorySpending[expense.category] = 
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }
    
    return categorySpending;
  }

  /// Get expenses for a specific date
  List<Expense> getExpensesForDate(DateTime date) {
    return _expenses.where((expense) {
      final expenseDate = expense.expenseDate;
      return expenseDate.year == date.year &&
          expenseDate.month == date.month &&
          expenseDate.day == date.day;
    }).toList();
  }

  @override
  void dispose() {
    _expenseService.dispose();
    super.dispose();
  }
}