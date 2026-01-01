"""
API endpoints for Firestore-based statistics.
"""

from fastapi import APIRouter, Depends, HTTPException, status
#from firebase_admin import auth
from typing import Dict, List
import logging

from ...core.dependencies import get_current_user
from ...services.firestore_statistics_service import FirestoreStatisticsService

router = APIRouter()
logger = logging.getLogger(__name__)

# Initialize Firestore Statistics Service
firestore_stats_service = FirestoreStatisticsService()

@router.get("/statistics", response_model=Dict)
async def get_user_statistics(
    current_user: dict = Depends(get_current_user)
):
    """
    Get aggregated statistics for a specific user from Firestore.

    Args:
        current_user (dict): The current authenticated user object (from Firebase Auth).

    Returns:
        Dict: A dictionary containing various statistics:
            - total_plans (int): Total number of plans created.
            - total_days (int): Total number of days across all plans.
            - locations_visited (int): Number of actual location check-ins.
            - total_trips (int): Number of completed trips.
            - total_expenses (float): Total actual expenses.
            - total_plans_2025 (int): Plans in 2025.
            - total_days_2025 (int): Days traveled in 2025.
            - locations_visited_2025 (int): Locations visited in 2025.
            - total_trips_2025 (int): Trips completed in 2025.
            - total_activities (int): Legacy mapping for total_plans.
            - completed_trips (int): Legacy mapping for completed trips.
            - checked_in_locations (int): Legacy mapping for locations visited.
        
    Raises:
        HTTPException(401): If the User ID is not found in the token.
        HTTPException(500): If there is an error retrieving statistics.
    """
    try:
        user_id = current_user.get('uid')
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found"
            )
        
        logger.info(f"Getting Firestore statistics for user: {user_id}")
        
        stats = firestore_stats_service.get_user_statistics(user_id)
        
        # Transform to match expected format with new statistics
        result = {
            'total_plans': stats.get('total_plans', 0),
            'total_days': stats.get('total_days', 0),
            'locations_visited': stats.get('locations_visited', 0),
            'total_trips': stats.get('total_trips', 0),
            'total_expenses': stats.get('total_expenses', 0.0),
            # 2025 specific stats
            'total_plans_2025': stats.get('total_plans_2025', 0),
            'total_days_2025': stats.get('total_days_2025', 0),
            'locations_visited_2025': stats.get('locations_visited_2025', 0),
            'total_trips_2025': stats.get('total_trips_2025', 0),
            # Legacy fields for backward compatibility
            'total_activities': stats.get('total_plans', 0),  # Map to total_plans
            'completed_trips': stats.get('total_trips', 0),
            'checked_in_locations': stats.get('locations_visited', 0),
        }
        
        if 'error' in stats:
            result['error'] = stats['error']
            
        return result
        
    except Exception as e:
        logger.error(f"Error in get_user_statistics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get statistics: {str(e)}"
        )

@router.get("/trip-details", response_model=Dict)
async def get_trip_details(
    current_user: dict = Depends(get_current_user)
):
    """
    Get detailed information about a user's trips.

    Args:
        current_user (dict): The current authenticated user object.

    Returns:
        Dict: A dictionary containing trip details (total, completed, ongoing, upcoming).

    Raises:
        HTTPException(401): If the User ID is not found.
        HTTPException(500): If there is an error retrieving trip details.
    """
    try:
        user_id = current_user.get('uid')
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found"
            )
        
        logger.info(f"Getting trip details for user: {user_id}")
        
        details = firestore_stats_service.get_trip_details(user_id)
        
        return details
        
    except Exception as e:
        logger.error(f"Error in get_trip_details: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get trip details: {str(e)}"
        )

@router.get("/monthly-expenses", response_model=List[Dict])
async def get_monthly_expenses(
    limit: int = 12,
    current_user: dict = Depends(get_current_user)
):
    """
    Get monthly expense totals for a user.

    Args:
        limit (int): Maximum number of months to return. Defaults to 12.
        current_user (dict): The current authenticated user.

    Returns:
        List[Dict]: A list of dictionaries, each containing 'month' (YYYY-MM) and 'amount'.

    Raises:
        HTTPException(401): If the User ID is not found.
        HTTPException(500): If there is an error retrieving monthly expenses.
    """
    try:
        user_id = current_user.get('uid')
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found"
            )
        
        logger.info(f"Getting monthly expenses for user: {user_id}")
        
        expenses = firestore_stats_service.get_monthly_expenses(user_id, limit)
        
        return expenses
        
    except Exception as e:
        logger.error(f"Error in get_monthly_expenses: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get monthly expenses: {str(e)}"
        )

@router.get("/dashboard", response_model=Dict)
async def get_dashboard_data(
    current_user: dict = Depends(get_current_user)
):
    """
    Get all data required for the user dashboard.

    Aggregates statistics, trip details, and monthly expenses into a single response.

    Args:
        current_user (dict): The current authenticated user.

    Returns:
        Dict: A dictionary containing:
            - statistics: User statistics (plans, days, locations, etc.).
            - trip_details: Counts of trips by status.
            - monthly_expenses: List of monthly expense totals.
            - summary: Calculated estimates for total distance, total days, and average expense.

    Raises:
        HTTPException(401): If the User ID is not found.
        HTTPException(500): If there is an error retrieving dashboard data.
    """
    try:
        user_id = current_user.get('uid')
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found"
            )
        
        logger.info(f"Getting dashboard data for user: {user_id}")
        
        # Get all data concurrently (sequentially here for simplicity)
        stats = firestore_stats_service.get_user_statistics(user_id)
        trip_details = firestore_stats_service.get_trip_details(user_id)
        monthly_expenses = firestore_stats_service.get_monthly_expenses(user_id)
        
        dashboard_data = {
            'statistics': {
                'total_plans': stats.get('total_plans', 0),
                'total_days': stats.get('total_days', 0),
                'locations_visited': stats.get('locations_visited', 0),
                'total_trips': stats.get('total_trips', 0),
                'total_expenses': stats.get('total_expenses', 0.0),
                'total_plans_2025': stats.get('total_plans_2025', 0),
                'total_days_2025': stats.get('total_days_2025', 0),
                'locations_visited_2025': stats.get('locations_visited_2025', 0),
                'total_trips_2025': stats.get('total_trips_2025', 0),
            },
            'trip_details': trip_details,
            'monthly_expenses': monthly_expenses,
            'summary': {
                'total_distance': stats.get('completed_trips', 0) * 500,  # Estimate 500km per trip
                'total_days': stats.get('completed_trips', 0) * 3,  # Estimate 3 days per trip
                'average_expense_per_trip': (
                    stats.get('total_expenses', 0) / stats.get('completed_trips', 1) 
                    if stats.get('completed_trips', 0) > 0 else 0
                )
            }
        }
        
        return dashboard_data
        
    except Exception as e:
        logger.error(f"Error in get_dashboard_data: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get dashboard data: {str(e)}"
        )