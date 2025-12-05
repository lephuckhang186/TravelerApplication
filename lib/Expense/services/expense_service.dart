/// API Client kết nối với backend

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Core/network/api_client.dart';
import '../../Core/network/exceptions.dart';
import '../../Core/config/api_config.dart';
import '../models/expense_models.dart';

/// Service class for managing expense-related API calls
class ExpenseService {
  final ApiClient _apiClient;

  ExpenseService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    _initializeAuth();
  }

  /// Initialize authentication
  Future<void> _initializeAuth() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          _apiClient.setAuthToken(token);
          debugPrint(
            'DEBUG: ExpenseService - Auth token set for user: ${user.uid}',
          );
          debugPrint(
            'DEBUG: ExpenseService - Token: ${token.isNotEmpty ? token.substring(0, 50) : "empty"}...',
          );
        } else {
          debugPrint(
            'DEBUG: ExpenseService - Failed to get token for user: ${user.uid}',
          );
        }
      } else {
        debugPrint('DEBUG: ExpenseService - No authenticated user found');
      }
    } catch (e) {
      debugPrint('DEBUG: ExpenseService - Failed to initialize auth: $e');
    }
  }

  /// Ensure authentication before making API calls
  Future<void> _ensureAuthentication() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true); // Force refresh token
        if (token != null) {
          _apiClient.setAuthToken(token);
          debugPrint(
            'DEBUG: ExpenseService - Refreshed auth token for user: ${user.uid}',
          );
          debugPrint(
            'DEBUG: ExpenseService - Token preview: ${token.substring(0, 50)}...',
          );
        } else {
          debugPrint(
            'DEBUG: ExpenseService - Failed to refresh token for user: ${user.uid}',
          );
          throw Exception('Failed to get authentication token');
        }
      } else {
        debugPrint('DEBUG: ExpenseService - No authenticated user found');
        throw Exception('User not authenticated');
      }
    } catch (e) {
      debugPrint('DEBUG: ExpenseService - Failed to refresh auth: $e');
      rethrow;
    }
  }

  /// Get current trip
  Future<Trip?> getCurrentTrip() async {
    try {
      await _ensureAuthentication();
      final response = await _apiClient.get('/expenses/trip/current');
      if (response != null) {
        return Trip.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Return null if no trip found instead of throwing error
      if (e.toString().contains('404') ||
          e.toString().contains('No active trip')) {
        return null;
      }
      throw _handleException(e, 'Failed to fetch current trip');
    }
  }

  /// Create a new trip
  Future<Map<String, dynamic>> createTrip(Trip trip) async {
    try {
      await _ensureAuthentication();
      final response = await _apiClient.post(
        '/activities/trips',
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
      await _ensureAuthentication();
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
      // Ensure we have a fresh auth token before making the request
      await _ensureAuthentication();

      debugPrint(
        'DEBUG: ExpenseService - Creating expense with endpoint: ${ApiConfig.expensesEndpoint}',
      );
      debugPrint('DEBUG: ExpenseService - Request body: ${request.toJson()}');

      final response = await _apiClient.post(
        ApiConfig.expensesEndpoint,
        body: request.toJson(),
      );

      debugPrint('DEBUG: ExpenseService - Expense created successfully');
      return Expense.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('DEBUG: ExpenseService - Create expense error: $e');
      throw _handleException(e, 'Failed to create expense');
    }
  }

  /// Convenient method to create expense with basic parameters
  Future<Expense> createExpenseFromActivity({
    required double amount,
    required String category,
    required String description,
    String? activityId,
    String? tripId,
  }) async {
    // Enhanced description to include activity and trip linking
    String enhancedDescription = description;
    if (activityId != null) {
      enhancedDescription += ' [Activity: $activityId]';
    }
    if (tripId != null) {
      enhancedDescription += ' [Trip: $tripId]';
    }

    final request = ExpenseCreateRequest(
      amount: amount,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.value == category,
        orElse: () => ExpenseCategory.activity, // Default to activity category
      ),
      description: enhancedDescription,
      expenseDate: DateTime.now(),
      tripId: tripId, // Pass the tripId to associate with the trip
    );

    debugPrint(
      'DEBUG: Creating expense from activity with amount: $amount, category: $category, tripId: $tripId, description: $enhancedDescription',
    );
    debugPrint('DEBUG: ExpenseCreateRequest.toJson(): ${request.toJson()}');
    
    final createdExpense = await createExpense(request);
    
    debugPrint('DEBUG: Created expense - ID: ${createdExpense.id}, TripId: ${createdExpense.tripId}, Description: ${createdExpense.description}');
    
    return createdExpense;
  }

  /// Get all expenses with optional filters
  Future<List<Expense>> getExpenses({
    ExpenseCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    String? tripId,
  }) async {
    try {
      debugPrint('ExpenseService.getExpenses: tripId=$tripId, startDate=$startDate, endDate=$endDate');
      
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
      if (tripId != null) {
        queryParams['planner_id'] = tripId;
        debugPrint('ExpenseService.getExpenses: Adding planner_id=$tripId to query');
      } else {
        debugPrint('ExpenseService.getExpenses: No tripId, loading ALL user expenses');
      }

      final response = await _apiClient.get(
        ApiConfig.expensesEndpoint,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response is List) {
        final expenses = response
            .map((item) => Expense.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('ExpenseService.getExpenses: Loaded ${expenses.length} expenses');
        return expenses;
      }
      return [];
    } catch (e) {
      debugPrint('ExpenseService.getExpenses: Error - $e');
      throw _handleException(e, 'Failed to fetch expenses');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _ensureAuthentication();
      await _apiClient.delete('${ApiConfig.expensesEndpoint}/$expenseId');
    } catch (e) {
      throw _handleException(e, 'Failed to delete expense');
    }
  }

  /// Get budget status for a specific trip or current trip
  Future<BudgetStatus> getBudgetStatus({String? tripId}) async {
    try {
      await _ensureAuthentication();
      final queryParams = tripId != null ? {'trip_id': tripId} : null;
      final response = await _apiClient.get(
        ApiConfig.budgetStatusEndpoint,
        queryParams: queryParams,
      );
      return BudgetStatus.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Return default budget status if API returns 404 or error
      if (e.toString().contains('404') || e.toString().contains('No budget')) {
        return BudgetStatus(
          totalBudget: 0.0,
          totalSpent: 0.0,
          percentageUsed: 0.0,
          remainingBudget: 0.0,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          daysRemaining: 0,
          daysTotal: 0,
          recommendedDailySpending: 0.0,
          averageDailySpending: 0.0,
          burnRateStatus: BurnRateStatus.onTrack,
          isOverBudget: false,
          categoryOverruns: [],
        );
      }
      throw _handleException(e, 'Failed to fetch budget status');
    }
  }

  /// Get category status
  Future<List<CategoryStatus>> getCategoryStatus() async {
    try {
      await _ensureAuthentication();
      final response = await _apiClient.get(ApiConfig.categoryStatusEndpoint);

      if (response is List) {
        return response
            .map(
              (item) => CategoryStatus.fromJson(item as Map<String, dynamic>),
            )
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
      await _ensureAuthentication();
      final response = await _apiClient.get(ApiConfig.spendingTrendsEndpoint);
      return SpendingTrends.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw _handleException(e, 'Failed to fetch spending trends');
    }
  }

  /// Get expense summary
  Future<ExpenseSummary> getExpenseSummary({String? tripId}) async {
    try {
      await _ensureAuthentication();
      final queryParams = tripId != null ? {'trip_id': tripId} : null;
      final response = await _apiClient.get(
        ApiConfig.expenseSummaryEndpoint,
        queryParams: queryParams,
      );
      return ExpenseSummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw _handleException(e, 'Failed to fetch expense summary');
    }
  }

  /// Export expense data
  Future<Map<String, dynamic>> exportExpenseData() async {
    try {
      await _ensureAuthentication();
      final response = await _apiClient.get(ApiConfig.exportExpenseEndpoint);
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
      return ExpenseServiceException(
        '$context: Network error - ${exception.message}',
      );
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
