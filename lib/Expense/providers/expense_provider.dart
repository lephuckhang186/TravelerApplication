import 'package:flutter/foundation.dart';
import '../models/expense_models.dart';
import '../services/expense_service.dart';

/// Provider for managing expense state and API interactions
class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService;

  // State variables
  List<Expense> _expenses = [];
  BudgetStatus? _budgetStatus;
  List<CategoryStatus> _categoryStatus = [];
  ExpenseSummary? _expenseSummary;
  SpendingTrends? _spendingTrends;
  Trip? _currentTrip;

  // Calendar state
  int? _selectedDay;
  DateTime? _selectedMonth;
  DateTime? _currentDate;

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

  // Trip and calendar getters
  Trip? get currentTrip => _currentTrip;
  int? get selectedDay => _selectedDay;
  DateTime? get selectedMonth => _selectedMonth ?? DateTime.now();
  DateTime? get currentDate => _currentDate ?? DateTime.now();

  // Get selected date as DateTime
  DateTime? get selectedDate {
    if (_selectedDay == null) return null;
    final month = _selectedMonth ?? DateTime.now();
    return DateTime(month.year, month.month, _selectedDay!);
  }

  // Authentication
  void setAuthToken(String token) {
    _expenseService.setAuthToken(token);
  }

  void clearAuthToken() {
    _expenseService.clearAuthToken();
  }

  /// Get current trip from backend
  Future<void> fetchCurrentTrip() async {
    try {
      _currentTrip = await _expenseService.getCurrentTrip();
      notifyListeners();
    } catch (e) {
      // Trip not found, user needs to create one
      _currentTrip = null;
      notifyListeners();
    }
  }

  /// Set selected day for calendar
  void setSelectedDay(int day) {
    _selectedDay = day;
    notifyListeners();

    // Automatically fetch expenses for the selected date
    if (_selectedMonth != null) {
      final selectedDate = DateTime(
        _selectedMonth!.year,
        _selectedMonth!.month,
        day,
      );
      fetchExpensesForDate(selectedDate);
    }
  }

  /// Set selected month for calendar
  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    _selectedDay = null; // Clear day selection when month changes
    notifyListeners();
  }

  /// Clear day selection
  void clearSelectedDay() {
    _selectedDay = null;
    notifyListeners();
  }

  /// Create a new trip
  Future<bool> createTrip(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    try {
      // Create a trip with meaningful default name and destination
      final tripName = 'Budget Trip ${startDate.day}/${startDate.month}/${startDate.year}';
      final trip = Trip(
        startDate: startDate, 
        endDate: endDate,
        name: tripName,
        destination: 'Budget Destination'
      );
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

  /// Create expense from activity integration
  Future<bool> createExpenseFromActivity({
    required double amount,
    required String category,
    required String description,
    String? activityId,
    String? tripId,
  }) async {
    // Map backend ActivityType directly to ExpenseCategory enum
    ExpenseCategory expenseCategory;
    switch (category.toLowerCase()) {
      case 'flight':
        expenseCategory = ExpenseCategory.flight;
        break;
      case 'activity':
        expenseCategory = ExpenseCategory.activity;
        break;
      case 'lodging':
        expenseCategory = ExpenseCategory.lodging;
        break;
      case 'car_rental':
        expenseCategory = ExpenseCategory.carRental;
        break;
      case 'concert':
        expenseCategory = ExpenseCategory.concert;
        break;
      case 'cruising':
        expenseCategory = ExpenseCategory.cruising;
        break;
      case 'ferry':
        expenseCategory = ExpenseCategory.ferry;
        break;
      case 'ground_transportation':
        expenseCategory = ExpenseCategory.groundTransportation;
        break;
      case 'rail':
        expenseCategory = ExpenseCategory.rail;
        break;
      case 'restaurant':
        expenseCategory = ExpenseCategory.restaurant;
        break;
      case 'theater':
        expenseCategory = ExpenseCategory.theater;
        break;
      case 'tour':
        expenseCategory = ExpenseCategory.tour;
        break;
      case 'transportation':
        expenseCategory = ExpenseCategory.transportation;
        break;
      case 'shopping':
        expenseCategory = ExpenseCategory.shopping;
        break;
      default:
        expenseCategory = ExpenseCategory.miscellaneous;
    }

    return await createExpense(
      amount,
      expenseCategory,
      description: description,
      tripId: tripId,
    );
  }

  /// Create a new expense
  Future<bool> createExpense(
    double amount,
    ExpenseCategory category, {
    String description = '',
    DateTime? expenseDate,
    String? tripId,
  }) async {
    _setLoading(true);
    try {
      final request = ExpenseCreateRequest(
        amount: amount,
        category: category,
        description: description,
        expenseDate: expenseDate,
        tripId: tripId,
      );

      final newExpense = await _expenseService.createExpense(request);
      _expenses.insert(0, newExpense); // Add to beginning of list
      _clearError();

      // Refresh related data
      await Future.wait([
        fetchBudgetStatus(tripId: tripId), 
        fetchExpenseSummary(tripId: tripId)
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
    String? tripId,
  }) async {
    _setLoading(true);
    try {
      _selectedCategory = category;
      _startDate = startDate;
      _endDate = endDate;

      debugPrint('FETCH_EXPENSES: Fetching with tripId=$tripId, start=$startDate, end=$endDate');
      
      _expenses = await _expenseService.getExpenses(
        category: category,
        startDate: startDate,
        endDate: endDate,
        tripId: tripId,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('FETCH_EXPENSES: Request timed out after 15 seconds');
          throw Exception('Request timed out. Please check your connection.');
        },
      );
      
      debugPrint('FETCH_EXPENSES: Successfully loaded ${_expenses.length} expenses');
      _clearError();
    } catch (e) {
      debugPrint('FETCH_EXPENSES ERROR: $e');
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
      await Future.wait([fetchBudgetStatus(), fetchExpenseSummary()]);

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch budget status
  /// Fetch budget status for a specific trip or current trip
  Future<void> fetchBudgetStatus({String? tripId}) async {
    _isBudgetLoading = true;
    _budgetError = null;
    notifyListeners();

    try {
      _budgetStatus = await _expenseService.getBudgetStatus(tripId: tripId);
      _budgetError = null;
    } catch (e) {
      _budgetError = e.toString();
      debugPrint('DEBUG: Failed to fetch budget status: $e');
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
  Future<void> fetchExpenseSummary({String? tripId}) async {
    _isSummaryLoading = true;
    _summaryError = null;
    notifyListeners();

    try {
      _expenseSummary = await _expenseService.getExpenseSummary(tripId: tripId);
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

  /// Load all data based on current trip
  Future<void> loadData({String? tripId}) async {
    _setLoading(true);

    try {
      debugPrint('LOAD_DATA: Loading expenses for tripId: $tripId, startDate: $_startDate, endDate: $_endDate, forceRefresh: false');
      
      // Note: Trip model from expense service doesn't have ID
      // tripId must be passed from calling code
      if (tripId == null) {
        await fetchCurrentTrip();
        // _currentTrip doesn't have id field - caller must provide tripId
      }

      if (_currentTrip != null) {
        // Set date range based on trip
        _startDate = _currentTrip!.startDate;
        _endDate = _currentTrip!.endDate;
        _selectedMonth = _currentTrip!.startDate;
      }

      debugPrint('LOAD_DATA: Using tripId: $tripId for loading data');

      // Load all expense data with tripId
      await Future.wait([
        fetchExpenses(
          category: _selectedCategory,
          startDate: _startDate,
          endDate: _endDate,
          tripId: tripId,
        ),
        fetchBudgetStatus(tripId: tripId),
        fetchCategoryStatus(),
        fetchExpenseSummary(tripId: tripId),
        fetchSpendingTrends(),
      ]);
      
      debugPrint('LOAD_DATA: Loaded ${_expenses.length} expenses');
    } catch (e) {
      _setError('Failed to load data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    await loadData();
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
        .where(
          (expense) =>
              expense.expenseDate.isAfter(start) &&
              expense.expenseDate.isBefore(end.add(const Duration(days: 1))),
        )
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

  /// Fetch expenses for a specific date (API call)
  Future<void> fetchExpensesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    await fetchExpenses(startDate: startOfDay, endDate: endOfDay);
  }

  /// Get total amount spent on a specific day
  double getTotalForDay(int day) {
    if (_selectedMonth == null) return 0.0;

    final date = DateTime(_selectedMonth!.year, _selectedMonth!.month, day);
    final dayExpenses = getExpensesForDate(date);
    return dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Check if a day has expenses
  bool hasDayExpenses(int day) {
    if (_selectedMonth == null) return false;

    final date = DateTime(_selectedMonth!.year, _selectedMonth!.month, day);
    return getExpensesForDate(date).isNotEmpty;
  }

  /// Get days in current month
  int getDaysInCurrentMonth() {
    final month = _selectedMonth ?? DateTime.now();
    return DateTime(month.year, month.month + 1, 0).day;
  }

  /// Check if trip is active
  bool get hasActiveTrip => _currentTrip?.isActive ?? false;

  /// Get trip progress percentage
  double get tripProgressPercentage {
    if (_currentTrip == null) return 0.0;

    final totalDays = _currentTrip!.totalDays;
    final elapsedDays = _currentTrip!.daysElapsed;

    return (elapsedDays / totalDays * 100).clamp(0.0, 100.0);
  }

  @override
  void dispose() {
    _expenseService.dispose();
    super.dispose();
  }
}
