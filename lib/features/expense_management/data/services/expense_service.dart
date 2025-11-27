/// API Client kết nối với backend

import '../../../../core/network/api_client.dart';
import '../../../../core/network/exceptions.dart';
import '../../../../core/config/api_config.dart';
import '../models/expense_models.dart';

/// Service class for managing expense-related API calls
class ExpenseService {
  final ApiClient _apiClient;

  ExpenseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get current trip
  Future<Trip?> getCurrentTrip() async {
    try {
      final response = await _apiClient.get('/expenses/trip/current');
      if (response != null) {
        return Trip.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Return null if no trip found instead of throwing error
      if (e.toString().contains('404') || e.toString().contains('No active trip')) {
        return null;
      }
      throw _handleException(e, 'Failed to fetch current trip');
    }
  }

  /// Create a new trip
  Future<Map<String, dynamic>> createTrip(Trip trip) async {
    try {
      final response = await _apiClient.post(
        '/expenses/trip/create',
        body: trip.toJson(),
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw _handleException(e, 'Failed to create trip');
    }
  }

  /// Create a budget
  Future<Map<String, dynamic>> createBudget(Budget budget) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.createBudgetEndpoint,
        body: budget.toJson(),
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw _handleException(e, 'Failed to create budget');
    }
  }

  /// Create a new expense
  Future<Expense> createExpense(ExpenseCreateRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.expensesEndpoint,
        body: request.toJson(),
      );
      return Expense.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw _handleException(e, 'Failed to create expense');
    }
  }

  /// Get all expenses with optional filters
  Future<List<Expense>> getExpenses({
    ExpenseCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (category != null) {
        queryParams['category'] = category.value;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        ApiConfig.expensesEndpoint,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response is List) {
        return response
            .map((item) => Expense.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleException(e, 'Failed to fetch expenses');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _apiClient.delete('${ApiConfig.expensesEndpoint}/$expenseId');
    } catch (e) {
      throw _handleException(e, 'Failed to delete expense');
    }
  }

  /// Get budget status
  Future<BudgetStatus> getBudgetStatus() async {
    try {
      final response = await _apiClient.get(ApiConfig.budgetStatusEndpoint);
      return BudgetStatus.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw _handleException(e, 'Failed to fetch budget status');
    }
  }

  /// Get category status
  Future<List<CategoryStatus>> getCategoryStatus() async {
    try {
      final response = await _apiClient.get(ApiConfig.categoryStatusEndpoint);
      
      if (response is List) {
        return response
            .map((item) => CategoryStatus.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleException(e, 'Failed to fetch category status');
    }
  }

  /// Get spending trends
  Future<SpendingTrends> getSpendingTrends() async {
    try {
      final response = await _apiClient.get(ApiConfig.spendingTrendsEndpoint);
      return SpendingTrends.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw _handleException(e, 'Failed to fetch spending trends');
    }
  }

  /// Get expense summary
  Future<ExpenseSummary> getExpenseSummary() async {
    try {
      final response = await _apiClient.get(ApiConfig.expenseSummaryEndpoint);
      return ExpenseSummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw _handleException(e, 'Failed to fetch expense summary');
    }
  }

  /// Export expense data
  Future<Map<String, dynamic>> exportExpenseData() async {
    try {
      final response = await _apiClient.post(ApiConfig.exportDataEndpoint);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw _handleException(e, 'Failed to export expense data');
    }
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _apiClient.setAuthToken(token);
  }

  /// Clear authentication token
  void clearAuthToken() {
    _apiClient.clearAuthToken();
  }

  /// Handle and transform exceptions
  Exception _handleException(dynamic exception, String context) {
    if (exception is ApiException) {
      return ExpenseServiceException('$context: ${exception.message}');
    } else if (exception is NetworkException) {
      return ExpenseServiceException('$context: Network error - ${exception.message}');
    } else {
      return ExpenseServiceException('$context: Unexpected error - $exception');
    }
  }

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
}

/// Custom exception for expense service
class ExpenseServiceException implements Exception {
  final String message;
  
  const ExpenseServiceException(this.message);

  @override
  String toString() => 'ExpenseServiceException: $message';
}