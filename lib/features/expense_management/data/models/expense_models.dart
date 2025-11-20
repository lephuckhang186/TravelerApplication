import 'dart:convert';

/// Expense category enumeration
enum ExpenseCategory {
  food,
  transportation,
  accommodation,
  entertainment,
  shopping,
  health,
  education,
  utilities,
  other
}

/// Extension for ExpenseCategory to handle string conversion
extension ExpenseCategoryExtension on ExpenseCategory {
  String get value {
    switch (this) {
      case ExpenseCategory.food:
        return 'FOOD';
      case ExpenseCategory.transportation:
        return 'TRANSPORTATION';
      case ExpenseCategory.accommodation:
        return 'ACCOMMODATION';
      case ExpenseCategory.entertainment:
        return 'ENTERTAINMENT';
      case ExpenseCategory.shopping:
        return 'SHOPPING';
      case ExpenseCategory.health:
        return 'HEALTH';
      case ExpenseCategory.education:
        return 'EDUCATION';
      case ExpenseCategory.utilities:
        return 'UTILITIES';
      case ExpenseCategory.other:
        return 'OTHER';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.transportation:
        return 'Di chuyển';
      case ExpenseCategory.accommodation:
        return 'Lưu trú';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.health:
        return 'Sức khỏe';
      case ExpenseCategory.education:
        return 'Giáo dục';
      case ExpenseCategory.utilities:
        return 'Tiện ích';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  static ExpenseCategory fromString(String value) {
    switch (value.toUpperCase()) {
      case 'FOOD':
        return ExpenseCategory.food;
      case 'TRANSPORTATION':
        return ExpenseCategory.transportation;
      case 'ACCOMMODATION':
        return ExpenseCategory.accommodation;
      case 'ENTERTAINMENT':
        return ExpenseCategory.entertainment;
      case 'SHOPPING':
        return ExpenseCategory.shopping;
      case 'HEALTH':
        return ExpenseCategory.health;
      case 'EDUCATION':
        return ExpenseCategory.education;
      case 'UTILITIES':
        return ExpenseCategory.utilities;
      case 'OTHER':
        return ExpenseCategory.other;
      default:
        return ExpenseCategory.other;
    }
  }
}

/// Expense model
class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final DateTime expenseDate;
  final String currency;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
    this.currency = 'VND',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategoryExtension.fromString(json['category'] as String),
      description: json['description'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      currency: json['currency'] as String? ?? 'VND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category.value,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'currency': currency,
    };
  }
}

/// Expense create request model
class ExpenseCreateRequest {
  final double amount;
  final ExpenseCategory category;
  final String description;
  final DateTime? expenseDate;

  const ExpenseCreateRequest({
    required this.amount,
    required this.category,
    this.description = '',
    this.expenseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category.value,
      'description': description,
      if (expenseDate != null) 'expense_date': expenseDate!.toIso8601String(),
    };
  }
}

/// Budget model
class Budget {
  final double totalBudget;
  final double? dailyLimit;
  final Map<String, double>? categoryAllocations;

  const Budget({
    required this.totalBudget,
    this.dailyLimit,
    this.categoryAllocations,
  });

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

  const Trip({
    required this.startDate,
    required this.endDate,
    this.durationDays,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      durationDays: json['duration_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };
  }
}

/// Budget status response model
class BudgetStatus {
  final double totalBudget;
  final double totalSpent;
  final double percentageUsed;
  final double remainingBudget;
  final int daysRemaining;
  final int daysTotal;
  final double recommendedDailySpending;
  final double averageDailySpending;
  final String burnRateStatus;
  final bool isOverBudget;
  final List<String> categoryOverruns;

  const BudgetStatus({
    required this.totalBudget,
    required this.totalSpent,
    required this.percentageUsed,
    required this.remainingBudget,
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
      daysRemaining: json['days_remaining'] as int,
      daysTotal: json['days_total'] as int,
      recommendedDailySpending: (json['recommended_daily_spending'] as num).toDouble(),
      averageDailySpending: (json['average_daily_spending'] as num).toDouble(),
      burnRateStatus: json['burn_rate_status'] as String,
      isOverBudget: json['is_over_budget'] as bool,
      categoryOverruns: List<String>.from(json['category_overruns'] as List),
    );
  }
}

/// Category status response model
class CategoryStatus {
  final String category;
  final double allocated;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final bool isOverBudget;
  final String status;

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
      category: json['category'] as String,
      allocated: (json['allocated'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      percentageUsed: (json['percentage_used'] as num).toDouble(),
      isOverBudget: json['is_over_budget'] as bool,
      status: json['status'] as String,
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

/// Spending trends model
class SpendingTrends {
  final List<DailySpending> dailyTrends;
  final Map<String, double> categoryTrends;
  final Map<String, dynamic> spendingPatterns;
  final Map<String, dynamic> predictions;

  const SpendingTrends({
    required this.dailyTrends,
    required this.categoryTrends,
    required this.spendingPatterns,
    required this.predictions,
  });

  factory SpendingTrends.fromJson(Map<String, dynamic> json) {
    final dailyTrendsData = json['daily_trends'] as List? ?? [];
    return SpendingTrends(
      dailyTrends: dailyTrendsData
          .map((item) => DailySpending.fromJson(item as Map<String, dynamic>))
          .toList(),
      categoryTrends: Map<String, double>.from(
        (json['category_trends'] as Map? ?? {}).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
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