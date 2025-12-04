import 'activity_models.dart';

/// Trip model for managing travel plans
class TripModel {
  final String? id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final List<ActivityModel> activities;
  final BudgetModel? budget;
  final List<String> collaborators;
  final String? coverImage;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? preferences;

  TripModel({
    this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.description,
    this.activities = const [],
    this.budget,
    this.collaborators = const [],
    this.coverImage,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.preferences,
  });

  /// Get trip duration in days
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Get remaining days until trip starts
  int get daysUntilStart {
    final now = DateTime.now();
    if (startDate.isAfter(now)) {
      return startDate.difference(now).inDays;
    }
    return 0;
  }

  /// Check if trip is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Check if trip is completed
  bool get isCompleted {
    return DateTime.now().isAfter(endDate);
  }

  /// Get total estimated budget
  double get totalEstimatedBudget {
    double total = budget?.estimatedCost ?? 0;
    for (final activity in activities) {
      total += activity.budget?.estimatedCost ?? 0;
    }
    return total;
  }

  /// Get total actual spent
  double get totalActualSpent {
    double total = budget?.actualCost ?? 0;
    for (final activity in activities) {
      total += activity.budget?.actualCost ?? 0;
    }
    return total;
  }

  /// Get remaining budget
  double get remainingBudget => totalEstimatedBudget - totalActualSpent;

  /// Get budget usage percentage
  double get budgetUsagePercentage {
    if (totalEstimatedBudget <= 0) return 0.0;
    return (totalActualSpent / totalEstimatedBudget * 100).clamp(0.0, 100.0);
  }

  /// Check if over budget
  bool get isOverBudget => totalActualSpent > totalEstimatedBudget;

  /// Get budget status
  String get budgetStatus {
    if (totalEstimatedBudget <= 0) return 'No Budget Set';
    final percentage = budgetUsagePercentage;
    if (isOverBudget) return 'Over Budget';
    if (percentage >= 90) return 'Critical';
    if (percentage >= 75) return 'Warning';
    if (percentage >= 50) return 'On Track';
    return 'Under Budget';
  }

  /// Get recommended daily spending
  double get recommendedDailySpending {
    if (isCompleted) return 0.0;
    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return remainingBudget;
    return remainingBudget / daysRemaining;
  }

  /// Update trip with expense data
  TripModel copyWithExpenseUpdate({
    double? newActualSpent,
    List<ActivityModel>? updatedActivities,
  }) {
    BudgetModel? updatedBudget;
    if (newActualSpent != null && budget != null) {
      updatedBudget = budget!.copyWithActualCost(newActualSpent);
    }

    return TripModel(
      id: id,
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      description: description,
      activities: updatedActivities ?? activities,
      budget: updatedBudget ?? budget,
      collaborators: collaborators,
      coverImage: coverImage,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive,
      preferences: preferences,
    );
  }

  /// Get activities by type
  List<ActivityModel> getActivitiesByType(ActivityType type) {
    return activities.where((activity) => activity.activityType == type).toList();
  }

  /// Get activities by status
  List<ActivityModel> getActivitiesByStatus(ActivityStatus status) {
    return activities.where((activity) => activity.status == status).toList();
  }

  /// Get activities for a specific date
  List<ActivityModel> getActivitiesForDate(DateTime date) {
    return activities.where((activity) {
      if (activity.startDate == null) return false;
      final activityDate = DateTime(
        activity.startDate!.year,
        activity.startDate!.month,
        activity.startDate!.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return activityDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'description': description,
      'activities': activities.map((a) => a.toJson()).toList(),
      'budget': budget?.toJson(),
      'collaborators': collaborators,
      'cover_image': coverImage,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'preferences': preferences,
    };
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      name: json['name'] ?? '',
      destination: json['destination'] ?? '',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : DateTime.now(),
      description: json['description'],
      activities: (json['activities'] as List<dynamic>?)
          ?.map((a) => ActivityModel.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      budget: json['budget'] != null ? BudgetModel.fromJson(json['budget']) : null,
      collaborators: List<String>.from(json['collaborators'] ?? []),
      coverImage: json['cover_image'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isActive: json['is_active'] ?? true,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  TripModel copyWith({
    String? id,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<ActivityModel>? activities,
    BudgetModel? budget,
    List<String>? collaborators,
    String? coverImage,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      activities: activities ?? this.activities,
      budget: budget ?? this.budget,
      collaborators: collaborators ?? this.collaborators,
      coverImage: coverImage ?? this.coverImage,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripModel &&
        other.id == id &&
        other.name == name &&
        other.destination == destination;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ destination.hashCode;
  }

  @override
  String toString() {
    return 'TripModel{id: $id, name: $name, destination: $destination, startDate: $startDate, endDate: $endDate}';
  }
}