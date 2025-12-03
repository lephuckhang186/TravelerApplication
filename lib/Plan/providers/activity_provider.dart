import 'package:flutter/foundation.dart';
import '../models/activity_models.dart';
import '../services/trip_planning_service.dart';

/// Provider for managing activity state with expense integration
class ActivityProvider extends ChangeNotifier {
  final TripPlanningService _apiService = TripPlanningService();

  List<ActivityModel> _activities = [];
  Map<String, dynamic>? _expenseSummary;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ActivityModel> get activities => _activities;
  Map<String, dynamic>? get expenseSummary => _expenseSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load activities for a trip
  Future<void> loadActivities({String? tripId}) async {
    _setLoading(true);
    try {
      _activities = await _apiService.getActivities(tripId: tripId);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load activities: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new activity
  Future<ActivityModel?> createActivity(ActivityModel activity) async {
    _setLoading(true);
    try {
      final createdActivity = await _apiService.createActivity(activity);
      _activities.add(createdActivity);
      _clearError();
      notifyListeners();
      return createdActivity;
    } catch (e) {
      _setError('Failed to create activity: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing activity
  Future<ActivityModel?> updateActivity(
    String activityId,
    ActivityModel activity,
  ) async {
    _setLoading(true);
    try {
      final updatedActivity = await _apiService.updateActivity(
        activityId,
        activity,
      );
      final index = _activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        _activities[index] = updatedActivity;
      }
      _clearError();
      notifyListeners();
      return updatedActivity;
    } catch (e) {
      _setError('Failed to update activity: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an activity
  Future<bool> deleteActivity(String activityId) async {
    _setLoading(true);
    try {
      await _apiService.deleteActivity(activityId);
      _activities.removeWhere((a) => a.id == activityId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete activity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Schedule an activity
  Future<ActivityModel?> scheduleActivity(
    String activityId,
    DateTime startDate, {
    DateTime? endDate,
    int? durationMinutes,
  }) async {
    _setLoading(true);
    try {
      final scheduledActivity = await _apiService.scheduleActivity(
        activityId,
        startDate,
        endDate: endDate,
        durationMinutes: durationMinutes,
      );
      final index = _activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        _activities[index] = scheduledActivity;
      }
      _clearError();
      notifyListeners();
      return scheduledActivity;
    } catch (e) {
      _setError('Failed to schedule activity: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update activity cost
  Future<ActivityModel?> updateActivityCost(
    String activityId,
    double actualCost,
    String currency,
  ) async {
    _setLoading(true);
    try {
      final updatedActivity = await _apiService.updateActivityCost(
        activityId,
        actualCost,
        currency,
      );
      final index = _activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        _activities[index] = updatedActivity;
      }
      _clearError();
      notifyListeners();
      return updatedActivity;
    } catch (e) {
      _setError('Failed to update activity cost: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Check for schedule conflicts
  Future<List<ActivityModel>> checkScheduleConflicts(
    DateTime startDate,
    DateTime endDate, {
    String? tripId,
    String? excludeActivityId,
  }) async {
    try {
      return await _apiService.checkScheduleConflicts(
        startDate,
        endDate,
        tripId: tripId,
        excludeActivityId: excludeActivityId,
      );
    } catch (e) {
      _setError('Failed to check conflicts: $e');
      return [];
    }
  }

  /// Setup trip budget
  Future<bool> setupTripBudget({
    String? tripId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalBudget,
    String currency = 'VND',
    Map<String, double>? categoryAllocations,
  }) async {
    _setLoading(true);
    try {
      await _apiService.setupTripBudget(
        tripId: tripId,
        startDate: startDate,
        endDate: endDate,
        totalBudget: totalBudget,
        currency: currency,
        categoryAllocations: categoryAllocations,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to setup trip budget: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load expense summary
  Future<void> loadExpenseSummary({String? tripId}) async {
    _setLoading(true);
    try {
      _expenseSummary = await _apiService.getExpenseSummary(tripId: tripId);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load expense summary: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sync activities with expenses
  Future<bool> syncActivitiesWithExpenses({String? tripId}) async {
    _setLoading(true);
    try {
      await _apiService.syncActivitiesWithExpenses(tripId: tripId);
      // Reload activities to get updated expense info
      await loadActivities(tripId: tripId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to sync activities with expenses: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get activities by type
  List<ActivityModel> getActivitiesByType(ActivityType type) {
    return _activities
        .where((activity) => activity.activityType == type)
        .toList();
  }

  /// Get activities by status
  List<ActivityModel> getActivitiesByStatus(ActivityStatus status) {
    return _activities.where((activity) => activity.status == status).toList();
  }

  /// Get activities for a specific date
  List<ActivityModel> getActivitiesForDate(DateTime date) {
    return _activities.where((activity) {
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

  /// Get activities with expenses
  List<ActivityModel> getActivitiesWithExpenses() {
    return _activities
        .where((activity) => activity.expenseInfo.hasExpense)
        .toList();
  }

  /// Get activities without expenses
  List<ActivityModel> getActivitiesWithoutExpenses() {
    return _activities
        .where((activity) => !activity.expenseInfo.hasExpense)
        .toList();
  }

  /// Calculate total estimated cost
  double getTotalEstimatedCost() {
    return _activities.fold(0.0, (sum, activity) {
      return sum + (activity.budget?.estimatedCost ?? 0.0);
    });
  }

  /// Calculate total actual cost
  double getTotalActualCost() {
    return _activities.fold(0.0, (sum, activity) {
      return sum + (activity.budget?.actualCost ?? 0.0);
    });
  }

  /// Calculate budget variance
  double getBudgetVariance() {
    return getTotalActualCost() - getTotalEstimatedCost();
  }

  // Private helper methods
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

  /// Clear all data
  void clear() {
    _activities.clear();
    _expenseSummary = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
