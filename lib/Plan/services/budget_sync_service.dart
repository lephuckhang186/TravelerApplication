import '../../Expense/models/expense_models.dart';
import '../../Expense/services/expense_service.dart';
import '../models/trip_model.dart';
import '../models/activity_models.dart';
import '../providers/trip_planning_provider.dart';

/// Service to sync expense data with trip budget status
class BudgetSyncService {
  final ExpenseService _expenseService;

  BudgetSyncService({ExpenseService? expenseService})
    : _expenseService = expenseService ?? ExpenseService();

  /// Create expense from activity and sync budget
  Future<void> createExpenseFromActivity({
    required ActivityModel activity,
    required TripModel trip,
    required double actualCost,
    String? description,
    TripPlanningProvider? tripProvider,
  }) async {
    try {
      // Create expense through expense service
      await _expenseService.createExpenseFromActivity(
        amount: actualCost,
        category: _mapActivityTypeToExpenseCategory(
          activity.activityType,
        ).value,
        description: description ?? activity.title,
        activityId: activity.id,
        tripId: trip.id,
      );

      // Update activity budget with actual cost
      final updatedActivity = activity.copyWith(
        budget:
            activity.budget?.copyWithActualCost(actualCost) ??
            BudgetModel(
              estimatedCost:
                  actualCost, // If no budget exists, set estimated to actual
              actualCost: actualCost,
            ),
      );

      // Update trip through provider if available
      if (tripProvider != null) {
        await tripProvider.updateActivityInTrip(trip.id!, updatedActivity);
      }

    } catch (e) {
      throw Exception('Failed to sync expense with trip budget: $e');
    }
  }

  /// Sync all expenses for a trip and update budget status
  Future<TripModel> syncTripBudgetStatus(TripModel trip) async {
    try {
      // Get expenses directly by trip ID if available
      List<Expense> tripExpenses = [];

      if (trip.id != null && trip.id!.isNotEmpty) {
        // Get expenses by specific trip ID
        try {
          tripExpenses = await _expenseService.getExpenses(
            startDate: trip.startDate,
            endDate: trip.endDate,
            tripId: trip.id!, // Filter by specific trip ID
          );
        } catch (e) {
          // Fallback to date range and filtering
          final allExpenses = await _expenseService.getExpenses(
            startDate: trip.startDate,
            endDate: trip.endDate,
          );
          tripExpenses = allExpenses.where((expense) {
            return _isExpenseFromTrip(expense, trip);
          }).toList();
        }
      } else {
        // Fallback to date range filtering for trips without ID
        final allExpenses = await _expenseService.getExpenses(
          startDate: trip.startDate,
          endDate: trip.endDate,
        );
        tripExpenses = allExpenses.where((expense) {
          return _isExpenseFromTrip(expense, trip);
        }).toList();
      }

      // Calculate total actual spent from expenses
      final totalActualSpent = tripExpenses.fold<double>(
        0.0,
        (sum, expense) => sum + expense.amount,
      );

      // Update trip budget with actual spending (calculated in copyWithExpenseUpdate)

      // Update activities with their actual costs
      final updatedActivities = <ActivityModel>[];
      for (final activity in trip.activities) {
        // Find expenses for this specific activity
        final activityExpenses = tripExpenses.where((expense) {
          return expense.description.contains(activity.title) ||
              expense.description.contains('[Activity: ${activity.id}]');
        }).toList();

        final activityActualCost = activityExpenses.fold<double>(
          0.0,
          (sum, expense) => sum + expense.amount,
        );

        // Update activity budget if it has expenses
        if (activityActualCost > 0) {
          final updatedActivityBudget =
              activity.budget?.copyWithActualCost(activityActualCost) ??
              BudgetModel(
                estimatedCost: activityActualCost,
                actualCost: activityActualCost,
              );

          updatedActivities.add(
            activity.copyWith(budget: updatedActivityBudget),
          );
        } else {
          updatedActivities.add(activity);
        }
      }

      // Return updated trip
      return trip.copyWithExpenseUpdate(
        newActualSpent: totalActualSpent,
        updatedActivities: updatedActivities,
      );
    } catch (e) {
      return trip; // Return original trip if sync fails
    }
  }

  /// Check if an expense belongs to a specific trip
  bool _isExpenseFromTrip(Expense expense, TripModel trip) {
    // Priority 1: Check if expense description contains exact trip ID
    if (trip.id != null && expense.description.contains('[Trip: ${trip.id}]')) {
      return true;
    }

    // Priority 2: Check if expense description contains trip name (less reliable)
    if (expense.description.contains('[Trip: ${trip.name}]')) {
      return true;
    }

    // Priority 3 (Fallback): Check if expense date falls within trip dates
    // Only use this if no trip ID matching is found
    if (trip.id == null || trip.id!.isEmpty) {
      final expenseDate = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
        expense.expenseDate.day,
      );
      final tripStartDate = DateTime(
        trip.startDate.year,
        trip.startDate.month,
        trip.startDate.day,
      );
      final tripEndDate = DateTime(
        trip.endDate.year,
        trip.endDate.month,
        trip.endDate.day,
      );

      return expenseDate.isAtSameMomentAs(tripStartDate) ||
          expenseDate.isAtSameMomentAs(tripEndDate) ||
          (expenseDate.isAfter(tripStartDate) &&
              expenseDate.isBefore(tripEndDate.add(const Duration(days: 1))));
    }

    // Default: not from this trip if no criteria match
    return false;
  }

  /// Map activity type to expense category
  ExpenseCategory _mapActivityTypeToExpenseCategory(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.flight:
        return ExpenseCategory.flight;
      case ActivityType.lodging:
        return ExpenseCategory.lodging;
      case ActivityType.activity:
        return ExpenseCategory.activity;
      case ActivityType.carRental:
        return ExpenseCategory.carRental;
      case ActivityType.concert:
        return ExpenseCategory.concert;
      case ActivityType.cruising:
        return ExpenseCategory.cruising;
      case ActivityType.ferry:
        return ExpenseCategory.ferry;
      case ActivityType.groundTransportation:
        return ExpenseCategory.groundTransportation;
      case ActivityType.rail:
        return ExpenseCategory.rail;
      case ActivityType.restaurant:
        return ExpenseCategory.restaurant;
      case ActivityType.theater:
        return ExpenseCategory.theater;
      case ActivityType.tour:
        return ExpenseCategory.tour;
      case ActivityType.transportation:
        return ExpenseCategory.transportation;
      default:
        return ExpenseCategory.activity;
    }
  }

  /// Get budget status for a trip
  Future<Map<String, dynamic>> getTripBudgetStatus(TripModel trip) async {
    try {
      final syncedTrip = await syncTripBudgetStatus(trip);

      return {
        'totalBudget': syncedTrip.totalEstimatedBudget,
        'totalSpent': syncedTrip.totalActualSpent,
        'remainingBudget': syncedTrip.remainingBudget,
        'usagePercentage': syncedTrip.budgetUsagePercentage,
        'isOverBudget': syncedTrip.isOverBudget,
        'budgetStatus': syncedTrip.budgetStatus,
        'recommendedDailySpending': syncedTrip.recommendedDailySpending,
        'daysRemaining': syncedTrip.endDate.difference(DateTime.now()).inDays,
      };
    } catch (e) {
      return {
        'totalBudget': trip.totalEstimatedBudget,
        'totalSpent': trip.totalActualSpent,
        'remainingBudget': trip.remainingBudget,
        'usagePercentage': trip.budgetUsagePercentage,
        'isOverBudget': trip.isOverBudget,
        'budgetStatus': trip.budgetStatus,
        'recommendedDailySpending': trip.recommendedDailySpending,
        'daysRemaining': trip.endDate.difference(DateTime.now()).inDays,
      };
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up resources if needed
  }
}
