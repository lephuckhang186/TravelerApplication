import '../models/activity_models.dart';

/// Utility class for handling expense integration with activities
class ExpenseIntegration {
  /// Map activity type to expense category
  static String mapActivityTypeToExpenseCategory(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.flight:
        return 'transportation';
      case ActivityType.carRental:
      case ActivityType.groundTransportation:
      case ActivityType.rail:
      case ActivityType.ferry:
      case ActivityType.transportation:
        return 'transportation';
      case ActivityType.lodging:
        return 'accommodation';
      case ActivityType.restaurant:
        return 'food';
      case ActivityType.activity:
      case ActivityType.tour:
      case ActivityType.concert:
      case ActivityType.theater:
        return 'entertainment';
      case ActivityType.cruising:
        return 'transportation';
      case ActivityType.parking:
        return 'transportation';
      case ActivityType.meeting:
      case ActivityType.note:
      case ActivityType.direction:
      case ActivityType.map:
      default:
        return 'other';
    }
  }

  /// Check if activity type should automatically create expense
  static bool shouldAutoCreateExpense(ActivityType activityType) {
    return activityType != ActivityType.note &&
           activityType != ActivityType.direction &&
           activityType != ActivityType.map;
  }

  /// Get expense category display name
  static String getExpenseCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'transportation':
        return 'Transportation';
      case 'accommodation':
        return 'Accommodation';
      case 'food':
        return 'Food & Dining';
      case 'entertainment':
        return 'Entertainment';
      case 'shopping':
        return 'Shopping';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  /// Validate activity before creating expense
  static bool validateActivityForExpense(ActivityModel activity) {
    return activity.budget != null &&
           activity.budget!.estimatedCost > 0 &&
           shouldAutoCreateExpense(activity.activityType);
  }

  /// Create expense summary from activities
  static Map<String, dynamic> createExpenseSummary(List<ActivityModel> activities) {
    double totalEstimated = 0.0;
    double totalActual = 0.0;
    int totalActivities = activities.length;
    int syncedActivities = 0;
    Map<String, double> categoryBreakdown = {};

    for (final activity in activities) {
      if (activity.budget != null) {
        totalEstimated += activity.budget!.estimatedCost;
        if (activity.budget!.actualCost != null) {
          totalActual += activity.budget!.actualCost!;
        }
      }

      if (activity.expenseInfo.hasExpense) {
        syncedActivities++;
      }

      // Category breakdown
      final category = mapActivityTypeToExpenseCategory(activity.activityType);
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0.0) + 
                                   (activity.budget?.actualCost ?? activity.budget?.estimatedCost ?? 0.0);
    }

    return {
      'total_activities': totalActivities,
      'synced_activities': syncedActivities,
      'unsynced_activities': totalActivities - syncedActivities,
      'total_estimated_cost': totalEstimated,
      'total_actual_cost': totalActual,
      'budget_variance': totalActual - totalEstimated,
      'category_breakdown': categoryBreakdown,
      'sync_percentage': totalActivities > 0 ? (syncedActivities / totalActivities) * 100 : 0,
    };
  }

  /// Get activities that need expense sync
  static List<ActivityModel> getActivitiesNeedingSync(List<ActivityModel> activities) {
    return activities.where((activity) =>
      validateActivityForExpense(activity) && !activity.expenseInfo.hasExpense
    ).toList();
  }

  /// Get activities with expense mismatches
  static List<ActivityModel> getActivitiesWithMismatches(List<ActivityModel> activities) {
    return activities.where((activity) {
      if (!activity.expenseInfo.hasExpense || activity.budget?.actualCost == null) {
        return false;
      }
      // Check if there's a significant difference (more than 1% or 10,000 VND)
      final budgetCost = activity.budget!.actualCost!;
      const threshold = 10000.0; // 10,000 VND
      return (budgetCost - budgetCost).abs() > threshold;
    }).toList();
  }

  /// Format currency amount
  static String formatCurrency(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'VND':
        return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} VND';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  /// Parse currency amount from string
  static double parseCurrency(String currencyString) {
    final numericString = currencyString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }

  /// Get budget status color
  static String getBudgetStatusColor(double variance, double totalBudget) {
    if (totalBudget == 0) return 'grey';
    final percentage = (variance / totalBudget) * 100;
    
    if (percentage <= -10) return 'green';  // Under budget
    if (percentage <= 5) return 'yellow';   // Close to budget
    return 'red';  // Over budget
  }

  /// Get budget status message
  static String getBudgetStatusMessage(double variance, double totalBudget) {
    if (totalBudget == 0) return 'No budget set';
    final percentage = (variance / totalBudget) * 100;
    
    if (variance < 0) {
      return 'Under budget by ${percentage.abs().toStringAsFixed(1)}%';
    } else if (variance > 0) {
      return 'Over budget by ${percentage.toStringAsFixed(1)}%';
    } else {
      return 'On budget';
    }
  }
}