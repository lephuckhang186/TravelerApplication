import '../models/notification_models.dart';
import '../../Plan/models/activity_models.dart';
import '../../Plan/services/trip_planning_service.dart';

class BudgetNotificationService {
  final TripPlanningService _tripService = TripPlanningService();

  Future<BudgetWarning?> checkBudgetOverage(String activityId, double actualCost, {String? tripId}) async {
    try {
      
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
          //
        }
      }
      
      // Fallback: try to get activity directly (may fail if backend is down)
      if (activity == null) {
        try {
          activity = await _tripService.getActivity(activityId);
        } catch (e) {
          //
          return null;
        }
      }
      
      if (activity?.budget?.estimatedCost == null) {
        return null;
      }

      final estimatedCost = activity!.budget!.estimatedCost;
      final overage = actualCost - estimatedCost;
      
      // Only alert if overage is more than 10%
      if (overage > estimatedCost * 0.1) {
        final overagePercentage = (overage / estimatedCost) * 100;
        
        
        return BudgetWarning(
          activityTitle: activity.title,
          estimatedCost: estimatedCost,
          actualCost: actualCost,
          overageAmount: overage,
          overagePercentage: overagePercentage,
          currency: activity.budget!.currency,
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<BudgetWarning>> checkTripBudgetStatus(String tripId) async {
    try {
      
      List<ActivityModel> activities = [];
      
      // Try to get activities from trip object first
      try {
        final trip = await _tripService.getTrip(tripId);
        if (trip != null) {
          activities = trip.activities;
        }
      } catch (e) {
        //
      }
      
      // Fallback: try to get activities from backend (may fail)
      if (activities.isEmpty) {
        try {
          activities = await _tripService.getActivities(tripId: tripId);
        } catch (e) {
          return [];
        }
      }

      final warnings = <BudgetWarning>[];

      for (final activity in activities) {
        if (activity.checkIn && 
            activity.budget != null && 
            activity.budget!.actualCost != null) {
          
          
          final warning = await checkBudgetOverage(
            activity.id!, 
            activity.budget!.actualCost!,
            tripId: tripId
          );
          
          if (warning != null) {
            warnings.add(warning);
          }
        }
      }

      return warnings;
    } catch (e) {
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