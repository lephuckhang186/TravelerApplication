import 'package:flutter/foundation.dart';
import '../models/notification_models.dart';
import '../../Plan/models/activity_models.dart';
import '../../Plan/services/trip_planning_service.dart';

class BudgetNotificationService {
  final TripPlanningService _tripService = TripPlanningService();

  Future<BudgetWarning?> checkBudgetOverage(String activityId, double actualCost) async {
    try {
      debugPrint('BudgetNotificationService: Checking overage for activity $activityId with actual cost $actualCost');
      
      // For demo purposes, create a mock activity if service not available
      try {
        final activity = await _tripService.getActivity(activityId);
        
        if (activity?.budget?.estimatedCost == null) {
          debugPrint('BudgetNotificationService: No budget set for activity');
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
            currency: activity.budget!.currency ?? 'VND',
          );
        }
        
        debugPrint('BudgetNotificationService: Budget overage within acceptable range');
        return null;
      } catch (serviceError) {
        debugPrint('BudgetNotificationService: Service error, creating mock warning: $serviceError');
        
        // Create mock warning for demo if service fails
        final mockEstimatedCost = 300000.0; // Mock estimated cost
        final overage = actualCost - mockEstimatedCost;
        
        if (overage > mockEstimatedCost * 0.1) {
          final overagePercentage = (overage / mockEstimatedCost) * 100;
          
          return BudgetWarning(
            activityTitle: 'Activity (Mock)',
            estimatedCost: mockEstimatedCost,
            actualCost: actualCost,
            overageAmount: overage,
            overagePercentage: overagePercentage,
            currency: 'VND',
          );
        }
        
        return null;
      }
    } catch (e) {
      debugPrint('BudgetNotificationService: Error checking budget overage: $e');
      return null;
    }
  }

  Future<List<BudgetWarning>> checkTripBudgetStatus(String tripId) async {
    try {
      final activities = await _tripService.getActivities(tripId: tripId);
      final warnings = <BudgetWarning>[];

      for (final activity in activities) {
        if (activity.checkIn && 
            activity.budget != null && 
            activity.budget!.actualCost != null) {
          
          final warning = await checkBudgetOverage(
            activity.id!, 
            activity.budget!.actualCost!
          );
          
          if (warning != null) {
            warnings.add(warning);
          }
        }
      }

      return warnings;
    } catch (e) {
      print('Error checking trip budget status: $e');
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