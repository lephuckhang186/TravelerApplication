///Định nghĩa các data models cho expense management

import 'package:flutter/foundation.dart';
/// Expense category enumeration matching backend
enum ExpenseCategory {
  // Core categories matching backend ActivityType
  flight,
  activity,
  lodging,
  carRental,
  concert,
  cruising,
  ferry,
  groundTransportation,
  rail,
  restaurant,
  theater,
  tour,
  transportation,
  // Additional expense categories
  shopping,
  miscellaneous,
  emergency
}

/// Extension for ExpenseCategory to handle string conversion
extension ExpenseCategoryExtension on ExpenseCategory {
  String get value {
    switch (this) {
      case ExpenseCategory.flight:
        return 'flight';
      case ExpenseCategory.activity:
        return 'activity';
      case ExpenseCategory.lodging:
        return 'lodging';
      case ExpenseCategory.carRental:
        return 'car_rental';
      case ExpenseCategory.concert:
        return 'concert';
      case ExpenseCategory.cruising:
        return 'cruising';
      case ExpenseCategory.ferry:
        return 'ferry';
      case ExpenseCategory.groundTransportation:
        return 'ground_transportation';
      case ExpenseCategory.rail:
        return 'rail';
      case ExpenseCategory.restaurant:
        return 'restaurant';
      case ExpenseCategory.theater:
        return 'theater';
      case ExpenseCategory.tour:
        return 'tour';
      case ExpenseCategory.transportation:
        return 'transportation';
      case ExpenseCategory.shopping:
        return 'shopping';
      case ExpenseCategory.miscellaneous:
        return 'miscellaneous';
      case ExpenseCategory.emergency:
        return 'emergency';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.flight:
        return 'Chuyến bay';
      case ExpenseCategory.activity:
        return 'Hoạt động';
      case ExpenseCategory.lodging:
        return 'Lưu trú';
      case ExpenseCategory.carRental:
        return 'Thuê xe';
      case ExpenseCategory.concert:
        return 'Hòa nhạc';
      case ExpenseCategory.cruising:
        return 'Du thuyền';
      case ExpenseCategory.ferry:
        return 'Phà';
      case ExpenseCategory.groundTransportation:
        return 'Di chuyển mặt đất';
      case ExpenseCategory.rail:
        return 'Tàu hỏa';
      case ExpenseCategory.restaurant:
        return 'Nhà hàng';
      case ExpenseCategory.theater:
        return 'Rạp hát';
      case ExpenseCategory.tour:
        return 'Tour du lịch';
      case ExpenseCategory.transportation:
        return 'Di chuyển';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.miscellaneous:
        return 'Khác';
      case ExpenseCategory.emergency:
        return 'Khẩn cấp';
    }
  }

  static ExpenseCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'flight':
        return ExpenseCategory.flight;
      case 'activity':
        return ExpenseCategory.activity;
      case 'lodging':
        return ExpenseCategory.lodging;
      case 'car_rental':
        return ExpenseCategory.carRental;
      case 'concert':
        return ExpenseCategory.concert;
      case 'cruising':
        return ExpenseCategory.cruising;
      case 'ferry':
        return ExpenseCategory.ferry;
      case 'ground_transportation':
        return ExpenseCategory.groundTransportation;
      case 'rail':
        return ExpenseCategory.rail;
      case 'restaurant':
        return ExpenseCategory.restaurant;
      case 'theater':
        return ExpenseCategory.theater;
      case 'tour':
        return ExpenseCategory.tour;
      case 'transportation':
        return ExpenseCategory.transportation;
      case 'shopping':
        return ExpenseCategory.shopping;
      case 'miscellaneous':
        return ExpenseCategory.miscellaneous;
      case 'emergency':
        return ExpenseCategory.emergency;
      default:
        return ExpenseCategory.miscellaneous;
    }
  }
}

/// Expense model matching backend structure
class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String description;
  final String currency;
  final String? tripId; // Added trip ID support
  final Map<String, dynamic>? budgetWarning; // Budget warning from backend

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.description = '',
    this.currency = 'VND',
    this.tripId,
    this.budgetWarning,
  });

  /// Validate expense amount
  bool get isValid => amount >= 0;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final expense = Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategoryExtension.fromString(json['category'] as String),
      date: DateTime.parse(json['expense_date'] as String),
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? 'VND',
      tripId: json['planner_id'] as String?, // Map backend planner_id to tripId
      budgetWarning: json['budget_warning'] as Map<String, dynamic>?,
    );
    
    debugPrint('DEBUG: Expense.fromJson - ID: ${expense.id}, TripId: ${expense.tripId}, planner_id from backend: ${json['planner_id']}');
    if (expense.budgetWarning != null) {
      debugPrint('DEBUG: Expense.fromJson - Budget warning detected: ${expense.budgetWarning}');
    }
    
    return expense;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category.value,
      'date': date.toIso8601String(),
      'description': description,
      'currency': currency,
      if (tripId != null) 'planner_id': tripId,
      if (budgetWarning != null) 'budget_warning': budgetWarning,
    };
  }

  /// Get expense date for backward compatibility
  DateTime get expenseDate => date;
}

/// Expense create request model matching backend
class ExpenseCreateRequest {
  final double amount;
  final ExpenseCategory category;
  final String description;
  final DateTime? expenseDate;
  final String? tripId; // Added trip ID support

  const ExpenseCreateRequest({
    required this.amount,
    required this.category,
    this.description = '',
    this.expenseDate,
    this.tripId,
  });

  /// Validate request data
  bool get isValid => amount > 0;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category.value,
      'description': description,
      if (expenseDate != null) 'expense_date': expenseDate!.toIso8601String(),
      if (tripId != null) 'planner_id': tripId,
    };
  }
}

/// Budget model matching backend Budget class
class Budget {
  final double totalBudget;
  final double? dailyLimit;
  final Map<String, double>? categoryAllocations;
  final Map<ExpenseCategory, CategoryBudget>? categoryBudgets;

  const Budget({
    required this.totalBudget,
    this.dailyLimit,
    this.categoryAllocations,
    this.categoryBudgets,
  });

  /// Validate budget
  bool get isValid => totalBudget > 0;

  /// Get total allocated amount
  double get totalAllocated {
    if (categoryAllocations != null) {
      return categoryAllocations!.values.fold(0.0, (sum, amount) => sum + amount);
    }
    return 0.0;
  }

  /// Get unallocated amount
  double get unallocated => totalBudget - totalAllocated;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      totalBudget: (json['total_budget'] as num).toDouble(),
      dailyLimit: json['daily_limit'] != null 
          ? (json['daily_limit'] as num).toDouble() 
          : null,
      categoryAllocations: json['category_allocations'] != null
          ? Map<String, double>.from(
              (json['category_allocations'] as Map).map(
                (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_budget': totalBudget,
      if (dailyLimit != null) 'daily_limit': dailyLimit,
      if (categoryAllocations != null) 'category_allocations': categoryAllocations,
    };
  }
}

/// Trip model
class Trip {
  final DateTime startDate;
  final DateTime endDate;
  final int? durationDays;
  final String name;
  final String destination;

  const Trip({
    required this.startDate,
    required this.endDate,
    required this.name,
    required this.destination,
    this.durationDays,
  });

  /// Check if trip is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Get total days in trip
  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Get days remaining in trip
  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isAfter(now)) {
      return endDate.difference(now).inDays;
    }
    return 0;
  }

  /// Get days elapsed in trip
  int get daysElapsed {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      return 0;
    } else if (now.isAfter(endDate)) {
      return totalDays;
    } else {
      return now.difference(startDate).inDays + 1;
    }
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      name: json['name'] as String,
      destination: json['destination'] as String,
      durationDays: json['duration_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'destination': destination,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };
  }
}

/// Category budget model matching backend CategoryBudget
class CategoryBudget {
  final double allocatedAmount;
  final double spentAmount;

  const CategoryBudget({
    required this.allocatedAmount,
    this.spentAmount = 0.0,
  });

  /// Get remaining budget
  double get remaining => allocatedAmount - spentAmount;

  /// Get percentage used
  double get percentageUsed {
    if (allocatedAmount <= 0) return 0.0;
    return (spentAmount / allocatedAmount * 100).clamp(0.0, 100.0);
  }

  /// Check if over budget
  bool get isOverBudget => spentAmount > allocatedAmount;

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      allocatedAmount: (json['allocated_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allocated_amount': allocatedAmount,
      'spent_amount': spentAmount,
    };
  }
}

/// Budget status response modelng backend
enum BurnRateStatus {
  completed,
  highBurn,
  moderateBurn,
  onTrack,
}

/// Extension for BurnRateStatus
extension BurnRateStatusExtension on BurnRateStatus {
  String get value {
    switch (this) {
      case BurnRateStatus.completed:
        return 'COMPLETED';
      case BurnRateStatus.highBurn:
        return 'HIGH_BURN';
      case BurnRateStatus.moderateBurn:
        return 'MODERATE_BURN';
      case BurnRateStatus.onTrack:
        return 'ON_TRACK';
    }
  }

  static BurnRateStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLETED':
        return BurnRateStatus.completed;
      case 'HIGH_BURN':
        return BurnRateStatus.highBurn;
      case 'MODERATE_BURN':
        return BurnRateStatus.moderateBurn;
      case 'ON_TRACK':
        return BurnRateStatus.onTrack;
      default:
        return BurnRateStatus.onTrack;
    }
  }
}

/// Budget status response model matching backend BudgetStatus
class BudgetStatus {
  final double totalBudget;
  final double totalSpent;
  final double percentageUsed;
  final double remainingBudget;
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;
  final int daysTotal;
  final double recommendedDailySpending;
  final double averageDailySpending;
  final BurnRateStatus burnRateStatus;
  final bool isOverBudget;
  final List<ExpenseCategory> categoryOverruns;

  const BudgetStatus({
    required this.totalBudget,
    required this.totalSpent,
    required this.percentageUsed,
    required this.remainingBudget,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.daysTotal,
    required this.recommendedDailySpending,
    required this.averageDailySpending,
    required this.burnRateStatus,
    required this.isOverBudget,
    required this.categoryOverruns,
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    return BudgetStatus(
      totalBudget: (json['total_budget'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      percentageUsed: (json['percentage_used'] as num).toDouble(),
      remainingBudget: (json['remaining_budget'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      daysRemaining: json['days_remaining'] as int,
      daysTotal: json['days_total'] as int,
      recommendedDailySpending: (json['recommended_daily_spending'] as num).toDouble(),
      averageDailySpending: (json['average_daily_spending'] as num).toDouble(),
      burnRateStatus: BurnRateStatusExtension.fromString(json['burn_rate_status'] as String),
      isOverBudget: json['is_over_budget'] as bool,
      categoryOverruns: (json['category_overruns'] as List)
          .map((cat) => ExpenseCategoryExtension.fromString(cat.toString()))
          .toList(),
    );
  }
}

/// Category status type enum matching backend
enum CategoryStatusType {
  overBudget,
  warning,
  ok,
}

/// Extension for CategoryStatusType
extension CategoryStatusTypeExtension on CategoryStatusType {
  String get value {
    switch (this) {
      case CategoryStatusType.overBudget:
        return 'OVER_BUDGET';
      case CategoryStatusType.warning:
        return 'WARNING';
      case CategoryStatusType.ok:
        return 'OK';
    }
  }

  static CategoryStatusType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OVER_BUDGET':
        return CategoryStatusType.overBudget;
      case 'WARNING':
        return CategoryStatusType.warning;
      case 'OK':
        return CategoryStatusType.ok;
      default:
        return CategoryStatusType.ok;
    }
  }
}

/// Category status response model matching backend
class CategoryStatus {
  final ExpenseCategory category;
  final double allocated;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final bool isOverBudget;
  final CategoryStatusType status;

  const CategoryStatus({
    required this.category,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.isOverBudget,
    required this.status,
  });

  factory CategoryStatus.fromJson(Map<String, dynamic> json) {
    return CategoryStatus(
      category: ExpenseCategoryExtension.fromString(json['category'] as String),
      allocated: (json['allocated'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      percentageUsed: (json['percentage_used'] as num).toDouble(),
      isOverBudget: json['is_over_budget'] as bool,
      status: CategoryStatusTypeExtension.fromString(json['status'] as String),
    );
  }
}

/// Expense summary model
class ExpenseSummary {
  final int totalExpenses;
  final double totalAmount;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> dailyBreakdown;

  const ExpenseSummary({
    required this.totalExpenses,
    required this.totalAmount,
    required this.categoryBreakdown,
    required this.dailyBreakdown,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      totalExpenses: json['total_expenses'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      categoryBreakdown: Map<String, double>.from(
        (json['category_breakdown'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      dailyBreakdown: Map<String, double>.from(
        (json['daily_breakdown'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
    );
  }
}

/// Spending trend type enum matching backend
enum SpendingTrendType {
  increasing,
  decreasing,
  stable,
  insufficientData,
}

/// Extension for SpendingTrendType
extension SpendingTrendTypeExtension on SpendingTrendType {
  String get value {
    switch (this) {
      case SpendingTrendType.increasing:
        return 'INCREASING';
      case SpendingTrendType.decreasing:
        return 'DECREASING';
      case SpendingTrendType.stable:
        return 'STABLE';
      case SpendingTrendType.insufficientData:
        return 'INSUFFICIENT_DATA';
    }
  }

  static SpendingTrendType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INCREASING':
        return SpendingTrendType.increasing;
      case 'DECREASING':
        return SpendingTrendType.decreasing;
      case 'STABLE':
        return SpendingTrendType.stable;
      case 'INSUFFICIENT_DATA':
        return SpendingTrendType.insufficientData;
      default:
        return SpendingTrendType.stable;
    }
  }
}

/// Spending trends model matching backend Analytics
class SpendingTrends {
  final SpendingTrendType trend;
  final double recentAverage;
  final double overallAverage;
  final Map<DateTime, double> dailyTotals;
  final Map<ExpenseCategory, double> categoryTrends;
  final Map<String, dynamic> spendingPatterns;
  final Map<String, dynamic> predictions;

  const SpendingTrends({
    required this.trend,
    required this.recentAverage,
    required this.overallAverage,
    required this.dailyTotals,
    required this.categoryTrends,
    required this.spendingPatterns,
    required this.predictions,
  });

  factory SpendingTrends.fromJson(Map<String, dynamic> json) {
    // Parse daily totals from backend format
    final dailyTotalsMap = json['daily_totals'] as Map? ?? {};
    final dailyTotals = <DateTime, double>{};
    for (final entry in dailyTotalsMap.entries) {
      final date = DateTime.parse(entry.key.toString());
      final amount = (entry.value as num).toDouble();
      dailyTotals[date] = amount;
    }

    // Parse category trends
    final categoryTrendsMap = json['category_trends'] as Map? ?? {};
    final categoryTrends = <ExpenseCategory, double>{};
    for (final entry in categoryTrendsMap.entries) {
      final category = ExpenseCategoryExtension.fromString(entry.key.toString());
      final amount = (entry.value as num).toDouble();
      categoryTrends[category] = amount;
    }

    return SpendingTrends(
      trend: SpendingTrendTypeExtension.fromString(json['trend'] as String? ?? 'STABLE'),
      recentAverage: (json['recent_average'] as num?)?.toDouble() ?? 0.0,
      overallAverage: (json['overall_average'] as num?)?.toDouble() ?? 0.0,
      dailyTotals: dailyTotals,
      categoryTrends: categoryTrends,
      spendingPatterns: json['spending_patterns'] as Map<String, dynamic>? ?? {},
      predictions: json['predictions'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Daily spending model
class DailySpending {
  final DateTime date;
  final double amount;

  const DailySpending({
    required this.date,
    required this.amount,
  });

  factory DailySpending.fromJson(Map<String, dynamic> json) {
    return DailySpending(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}