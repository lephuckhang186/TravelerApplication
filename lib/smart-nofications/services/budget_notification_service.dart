import 'package:flutter/foundation.dart';
import '../models/notification_models.dart';
import '../../Plan/models/activity_models.dart';
import '../../Plan/services/trip_planning_service.dart';

class BudgetNotificationService {
  final TripPlanningService _tripService = TripPlanningService();

  Future<BudgetWarning?> checkBudgetOverage(String activityId, double actualCost, {String? tripId}) async {
    try {
      debugPrint('BudgetNotificationService: Checking overage for activity $activityId with actual cost $actualCost');
      
      ActivityModel? activity;
      
      // Try to get activity from trip if tripId provided
      if (tripId != null) {
        try {
          final trip = await _tripService.getTrip(tripId);
          if (trip != null) {
            activity = trip.activities.firstWhere(
              (a) => a.id == activityId,
              orElse: () => throw Exception('Activity not found in trip'),
            );
          }
        } catch (e) {
          debugPrint('BudgetNotificationService: Could not get activity from trip: $e');
        }
      }
      
      // Fallback: try to get activity directly (may fail if backend is down)
      if (activity == null) {
        try {
          activity = await _tripService.getActivity(activityId);
        } catch (e) {
          debugPrint('BudgetNotificationService: Could not get activity from backend: $e');
          return null;
        }
      }
      
      if (activity?.budget?.estimatedCost == null) {
        debugPrint('BudgetNotificationService: No budget set for activity $activityId');
        return null;
      }

      final estimatedCost = activity!.budget!.estimatedCost;
      final overage = actualCost - estimatedCost;
      
      debugPrint('BudgetNotificationService: Estimated: $estimatedCost, Actual: $actualCost, Overage: $overage');
      
      // Only alert if overage is more than 10%
      if (overage > estimatedCost * 0.1) {
        final overagePercentage = (overage / estimatedCost) * 100;
        
        debugPrint('BudgetNotificationService: Budget overage detected: ${overagePercentage.toInt()}%');
        
        return BudgetWarning(
          activityTitle: activity.title,
          estimatedCost: estimatedCost,
          actualCost: actualCost,
          overageAmount: overage,
          overagePercentage: overagePercentage,
          currency: activity.budget!.currency,
        );
      }
      
      debugPrint('BudgetNotificationService: Budget overage within acceptable range');
      return null;
    } catch (e) {
      debugPrint('BudgetNotificationService: Error checking budget overage: $e');
      return null;
    }
  }

  Future<List<BudgetWarning>> checkTripBudgetStatus(String tripId) async {
    try {
      debugPrint('BudgetNotificationService: Checking budget status for trip $tripId');
      
      List<ActivityModel> activities = [];
      
      // Try to get activities from trip object first
      try {
        final trip = await _tripService.getTrip(tripId);
        if (trip != null) {
          activities = trip.activities;
          debugPrint('BudgetNotificationService: Got ${activities.length} activities from trip object');
        }
      } catch (e) {
        debugPrint('BudgetNotificationService: Could not get trip: $e');
      }
      
      // Fallback: try to get activities from backend (may fail)
      if (activities.isEmpty) {
        try {
          activities = await _tripService.getActivities(tripId: tripId);
          debugPrint('BudgetNotificationService: Got ${activities.length} activities from backend');
        } catch (e) {
          debugPrint('BudgetNotificationService: Could not get activities from backend: $e');
          return [];
        }
      }

      final warnings = <BudgetWarning>[];

      for (final activity in activities) {
        if (activity.checkIn && 
            activity.budget != null && 
            activity.budget!.actualCost != null) {
          
          debugPrint('BudgetNotificationService: Checking activity ${activity.id} with actual cost ${activity.budget!.actualCost}');
          
          final warning = await checkBudgetOverage(
            activity.id!, 
            activity.budget!.actualCost!,
            tripId: tripId
          );
          
          if (warning != null) {
            warnings.add(warning);
            debugPrint('BudgetNotificationService: Added budget warning for activity ${activity.id}');
          }
        }
      }

      debugPrint('BudgetNotificationService: Found ${warnings.length} budget warnings for trip $tripId');
      return warnings;
    } catch (e) {
      debugPrint('BudgetNotificationService: Error checking trip budget status: $e');
      return [];
    }
  }

  double calculateTotalOverage(List<ActivityModel> activities) {
    double totalOverage = 0;
    
    for (final activity in activities) {
      if (activity.budget?.estimatedCost != null && 
          activity.budget?.actualCost != null) {
        final overage = activity.budget!.actualCost! - activity.budget!.estimatedCost;
        if (overage > 0) {
          totalOverage += overage;
        }
      }
    }
    
    return totalOverage;
  }

  double calculateBudgetUtilization(List<ActivityModel> activities) {
    double totalEstimated = 0;
    double totalActual = 0;
    
    for (final activity in activities) {
      if (activity.budget?.estimatedCost != null) {
        totalEstimated += activity.budget!.estimatedCost;
      }
      if (activity.budget?.actualCost != null) {
        totalActual += activity.budget!.actualCost!;
      }
    }
    
    if (totalEstimated == 0) return 0;
    return (totalActual / totalEstimated) * 100;
  }
}