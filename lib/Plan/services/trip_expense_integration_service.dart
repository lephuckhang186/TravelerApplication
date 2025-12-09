import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../../Expense/providers/expense_provider.dart';
import '../../Expense/models/expense_models.dart';

/// Service to integrate trip planning with expense management
class TripExpenseIntegrationService {
  static final TripExpenseIntegrationService _instance =
      TripExpenseIntegrationService._internal();
  factory TripExpenseIntegrationService() => _instance;
  TripExpenseIntegrationService._internal();

  ExpenseProvider? _expenseProvider;
  final Map<String, List<String>> _tripExpenseMap = {};
  final Map<String, List<String>> _activityExpenseMap = {};

  /// Set the expense provider reference
  void setExpenseProvider(ExpenseProvider provider) {
    _expenseProvider = provider;
    debugPrint('DEBUG: Integration - Expense provider set successfully');

    // Ensure the expense provider has proper authentication
    _ensureExpenseProviderAuth();
  }

  /// Ensure expense provider has proper authentication
  void _ensureExpenseProviderAuth() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _expenseProvider != null) {
        // The expense service should auto-initialize auth, but let's make sure
        debugPrint(
          'DEBUG: Integration - Ensuring expense provider has auth for user: ${user.uid}',
        );
      } else {
        debugPrint('DEBUG: Integration - Warning: No authenticated user found');
      }
    } catch (e) {
      debugPrint('DEBUG: Integration - Error ensuring auth: $e');
    }
  }

  /// Create expense from activity cost
  Future<bool> syncActivityExpense(ActivityModel activity) async {
    if (_expenseProvider == null || activity.budget == null) {
      debugPrint(
        'DEBUG: Integration - No expense provider or budget available',
      );
      return false;
    }

    // Use actual cost if available, otherwise use estimated cost
    final amount =
        activity.budget!.actualCost ?? activity.budget!.estimatedCost;
    if (amount <= 0) {
      debugPrint('DEBUG: Integration - No valid amount: $amount');
      return false;
    }

    try {
      debugPrint(
        'DEBUG: Integration - Attempting to create expense: amount=$amount, type=${activity.activityType.value}',
      );
      debugPrint(
        'DEBUG: Integration - ExpenseProvider available: ${_expenseProvider != null}',
      );

      final expense = await _expenseProvider!.createExpenseFromActivity(
        amount: amount,
        category: activity.activityType.value,
        description: activity.budget!.actualCost != null
            ? activity.title
            : activity.title,
        activityId: activity.id ?? '',
        tripId: activity.tripId ?? '',
      );

      debugPrint('DEBUG: Integration - Expense creation result: ${expense != null}');

      if (expense != null && activity.id != null) {
        // Track activity-expense mapping
        final activityId = activity.id;
        if (activityId != null) {
          if (!_activityExpenseMap.containsKey(activityId)) {
            _activityExpenseMap[activityId] = [];
          }
          _activityExpenseMap[activityId]!.add(
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
        }

        // Track trip-expense mapping
        final tripId = activity.tripId;
        if (tripId != null) {
          if (!_tripExpenseMap.containsKey(tripId)) {
            _tripExpenseMap[tripId] = [];
          }
          _tripExpenseMap[tripId]!.add(
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
        }
      }

      return expense != null;
    } catch (e) {
      debugPrint('DEBUG: Integration - Failed to sync activity expense: $e');
      return false;
    }
  }

  /// Get total expenses for a trip
  Future<double> getTripTotalExpenses(String tripId) async {
    if (_expenseProvider == null) return 0.0;

    final expenses = _expenseProvider!.expenses;
    double total = 0.0;

    for (final expense in expenses) {
      if (expense.description.contains(tripId)) {
        total += expense.amount;
      }
    }

    return total;
  }

  /// Get expense breakdown by category for a trip
  Future<Map<ExpenseCategory, double>> getTripExpensesByCategory(
    String tripId,
  ) async {
    if (_expenseProvider == null) return {};

    final expenses = _expenseProvider!.expenses;
    final Map<ExpenseCategory, double> breakdown = {};

    for (final expense in expenses) {
      if (expense.description.contains(tripId)) {
        breakdown[expense.category] =
            (breakdown[expense.category] ?? 0.0) + expense.amount;
      }
    }

    return breakdown;
  }

  /// Calculate budget vs actual spending for trip
  Future<TripBudgetSummary> getTripBudgetSummary(TripModel trip) async {
    final String tripId = trip.id ?? '';
    final totalExpenses = await getTripTotalExpenses(tripId);
    final totalBudget = trip.budget?.estimatedCost ?? 0.0;
    final expensesByCategory = await getTripExpensesByCategory(tripId);

    return TripBudgetSummary(
      tripId: tripId,
      tripName: trip.name,
      totalBudget: totalBudget,
      totalSpent: totalExpenses,
      remaining: totalBudget - totalExpenses,
      percentageUsed: totalBudget > 0
          ? (totalExpenses / totalBudget * 100)
          : 0.0,
      isOverBudget: totalExpenses > totalBudget,
      expensesByCategory: expensesByCategory,
      activitiesCount: trip.activities.length,
      checkedInActivities: trip.activities.where((a) => a.checkIn).length,
    );
  }

  /// Get activities with their expense status for calendar
  List<CalendarActivityInfo> getActivitiesForCalendar(List<TripModel> trips) {
    final List<CalendarActivityInfo> activities = [];

    for (final trip in trips) {
      for (final activity in trip.activities) {
        final hasExpense = _activityExpenseMap.containsKey(activity.id ?? '');
        final expectedCost = activity.budget?.estimatedCost;
        final actualCost = activity.budget?.actualCost;

        activities.add(
          CalendarActivityInfo(
            id: activity.id ?? '',
            title: activity.title,
            date: activity.startDate ?? DateTime.now(),
            tripId: trip.id ?? '',
            tripName: trip.name,
            activityType: activity.activityType,
            isCheckedIn: activity.checkIn,
            hasExpense: hasExpense,
            expectedCost: expectedCost,
            actualCost: actualCost,
            budgetVariance: (actualCost != null && expectedCost != null)
                ? actualCost - expectedCost
                : null,
          ),
        );
      }
    }

    return activities;
  }

  /// Get statistics data for analytics screen
  Future<TripStatistics> getTripStatistics(List<TripModel> trips) async {
    double totalBudget = 0.0;
    double totalSpent = 0.0;
    int totalActivities = 0;
    int completedActivities = 0;
    int activitiesWithExpenses = 0;
    final Map<ExpenseCategory, double> categorySpending = {};

    for (final trip in trips) {
      final budgetSummary = await getTripBudgetSummary(trip);
      totalBudget += budgetSummary.totalBudget;
      totalSpent += budgetSummary.totalSpent;
      totalActivities += trip.activities.length;
      completedActivities += trip.activities.where((a) => a.checkIn).length;

      // Count activities with expenses
      for (final activity in trip.activities) {
        if (_activityExpenseMap.containsKey(activity.id ?? '')) {
          activitiesWithExpenses++;
        }
      }

      // Aggregate category spending
      for (final entry in budgetSummary.expensesByCategory.entries) {
        categorySpending[entry.key] =
            (categorySpending[entry.key] ?? 0.0) + entry.value;
      }
    }

    return TripStatistics(
      totalTrips: trips.length,
      activeTrips: trips.where((t) => _isTripActive(t)).length,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      budgetUtilization: totalBudget > 0
          ? (totalSpent / totalBudget * 100)
          : 0.0,
      totalActivities: totalActivities,
      completedActivities: completedActivities,
      activitiesWithExpenses: activitiesWithExpenses,
      categorySpending: categorySpending,
      averageSpendingPerTrip: trips.isNotEmpty
          ? totalSpent / trips.length
          : 0.0,
      averageSpendingPerActivity: totalActivities > 0
          ? totalSpent / totalActivities
          : 0.0,
    );
  }

  bool _isTripActive(TripModel trip) {
    final now = DateTime.now();
    return trip.startDate.isBefore(now) && trip.endDate.isAfter(now);
  }

  /// Clear cached data
  void clearCache() {
    _tripExpenseMap.clear();
    _activityExpenseMap.clear();
  }
}

/// Model for trip budget summary
class TripBudgetSummary {
  final String tripId;
  final String tripName;
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double percentageUsed;
  final bool isOverBudget;
  final Map<ExpenseCategory, double> expensesByCategory;
  final int activitiesCount;
  final int checkedInActivities;

  const TripBudgetSummary({
    required this.tripId,
    required this.tripName,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.percentageUsed,
    required this.isOverBudget,
    required this.expensesByCategory,
    required this.activitiesCount,
    required this.checkedInActivities,
  });
}

/// Model for calendar activity info
class CalendarActivityInfo {
  final String id;
  final String title;
  final DateTime date;
  final String tripId;
  final String tripName;
  final ActivityType activityType;
  final bool isCheckedIn;
  final bool hasExpense;
  final double? expectedCost;
  final double? actualCost;
  final double? budgetVariance;

  const CalendarActivityInfo({
    required this.id,
    required this.title,
    required this.date,
    required this.tripId,
    required this.tripName,
    required this.activityType,
    required this.isCheckedIn,
    required this.hasExpense,
    this.expectedCost,
    this.actualCost,
    this.budgetVariance,
  });
}

/// Model for trip statistics
class TripStatistics {
  final int totalTrips;
  final int activeTrips;
  final double totalBudget;
  final double totalSpent;
  final double budgetUtilization;
  final int totalActivities;
  final int completedActivities;
  final int activitiesWithExpenses;
  final Map<ExpenseCategory, double> categorySpending;
  final double averageSpendingPerTrip;
  final double averageSpendingPerActivity;

  const TripStatistics({
    required this.totalTrips,
    required this.activeTrips,
    required this.totalBudget,
    required this.totalSpent,
    required this.budgetUtilization,
    required this.totalActivities,
    required this.completedActivities,
    required this.activitiesWithExpenses,
    required this.categorySpending,
    required this.averageSpendingPerTrip,
    required this.averageSpendingPerActivity,
  });
}
