import 'package:flutter/material.dart';
import '../data/services/expense_service.dart';
import '../data/models/expense_models.dart';

/// Example expense provider showing how to use Trip data in _loadData()
class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  
  // State variables
  Trip? _currentTrip;
  List<Expense> _expenses = [];
  BudgetStatus? _budgetStatus;
  List<CategoryStatus> _categoryStatus = [];
  SpendingTrends? _spendingTrends;
  ExpenseSummary? _expenseSummary;
  bool _isLoading = false;
  String? _error;

  // Getters
  Trip? get currentTrip => _currentTrip;
  List<Expense> get expenses => _expenses;
  BudgetStatus? get budgetStatus => _budgetStatus;
  List<CategoryStatus> get categoryStatus => _categoryStatus;
  SpendingTrends? get spendingTrends => _spendingTrends;
  ExpenseSummary? get expenseSummary => _expenseSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Load all expense data based on current trip
  Future<void> _loadData() async {
    setLoading(true);
    setError(null);
    
    try {
      // First, get the current trip
      final currentTrip = await _expenseService.getCurrentTrip();
      
      if (currentTrip == null) {
        setError('No active trip found. Please create a trip first.');
        return;
      }
      
      _currentTrip = currentTrip;
      
      // Extract start and end dates from the trip
      final startDate = currentTrip.startDate;
      final endDate = currentTrip.endDate;
      
      // Load all expense data using trip date range
      await Future.wait([
        fetchExpenses(startDate: startDate, endDate: endDate),
        fetchExpenseSummary(),
        fetchCategoryStatus(),
        fetchSpendingTrends(),
        fetchBudgetStatus(),
      ]);
      
    } catch (e) {
      setError('Failed to load expense data: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  /// Fetch expenses with optional date filters
  Future<void> fetchExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
  }) async {
    try {
      _expenses = await _expenseService.getExpenses(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch expenses: ${e.toString()}');
    }
  }

  /// Fetch expense summary
  Future<void> fetchExpenseSummary() async {
    try {
      _expenseSummary = await _expenseService.getExpenseSummary();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch expense summary: ${e.toString()}');
    }
  }

  /// Fetch category status
  Future<void> fetchCategoryStatus() async {
    try {
      _categoryStatus = await _expenseService.getCategoryStatus();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch category status: ${e.toString()}');
    }
  }

  /// Fetch spending trends
  Future<void> fetchSpendingTrends() async {
    try {
      _spendingTrends = await _expenseService.getSpendingTrends();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch spending trends: ${e.toString()}');
    }
  }

  /// Fetch budget status
  Future<void> fetchBudgetStatus() async {
    try {
      _budgetStatus = await _expenseService.getBudgetStatus();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch budget status: ${e.toString()}');
    }
  }

  /// Create a new trip
  Future<bool> createTrip({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    setLoading(true);
    
    try {
      final trip = Trip(
        startDate: startDate,
        endDate: endDate,
      );
      
      final result = await _expenseService.createTrip(trip);
      
      if (result['message'] != null) {
        // Reload data after creating trip
        await _loadData();
        return true;
      }
      return false;
    } catch (e) {
      setError('Failed to create trip: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Create a new budget
  Future<bool> createBudget({
    required double totalBudget,
    double? dailyLimit,
    Map<String, double>? categoryAllocations,
  }) async {
    setLoading(true);
    
    try {
      final budget = Budget(
        totalBudget: totalBudget,
        dailyLimit: dailyLimit,
        categoryAllocations: categoryAllocations,
      );
      
      final result = await _expenseService.createBudget(budget);
      
      if (result['message'] != null) {
        // Reload budget status after creating budget
        await fetchBudgetStatus();
        return true;
      }
      return false;
    } catch (e) {
      setError('Failed to create budget: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Add a new expense
  Future<bool> addExpense({
    required double amount,
    required ExpenseCategory category,
    String description = '',
    DateTime? expenseDate,
  }) async {
    try {
      final request = ExpenseCreateRequest(
        amount: amount,
        category: category,
        description: description,
        expenseDate: expenseDate,
      );
      
      final expense = await _expenseService.createExpense(request);
      
      // Add to local list and reload relevant data
      _expenses.insert(0, expense);
      notifyListeners();
      
      // Refresh summary and status data
      await Future.wait([
        fetchExpenseSummary(),
        fetchCategoryStatus(),
        fetchBudgetStatus(),
      ]);
      
      return true;
    } catch (e) {
      setError('Failed to add expense: ${e.toString()}');
      return false;
    }
  }

  /// Initialize provider - call this when the provider is created
  Future<void> initialize() async {
    await _loadData();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _loadData();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user has an active trip
  bool get hasActiveTrip => _currentTrip != null && (_currentTrip?.isActive ?? false);

  /// Get trip progress percentage (0-100)
  double get tripProgressPercentage {
    if (_currentTrip == null) return 0.0;
    
    final totalDays = _currentTrip!.durationDays ?? 1;
    final elapsedDays = DateTime.now().difference(_currentTrip!.startDate).inDays + 1;
    
    return (elapsedDays / totalDays * 100).clamp(0.0, 100.0);
  }

  /// Get days remaining in trip
  int get daysRemainingInTrip {
    if (_currentTrip == null) return 0;
    
    final remaining = _currentTrip!.endDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}