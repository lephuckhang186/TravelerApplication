"""
API endpoints for Firestore-based statistics
Cung cấp các API để lấy thống kê thời gian thực từ Firestore
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
    Lấy thống kê tổng hợp của user từ Firestore
    
    Returns:
        Dict chứa các thống kê:
        - total_plans: Tổng số plan được tạo ra
        - total_days: Tổng số ngày trong các plan (completed + ongoing)
        - locations_visited: Số địa điểm đã check-in thực tế
        - total_trips: Số chuyến đi đã hoàn thành
        - total_expenses: Tổng chi tiêu thực tế
        - Cùng các thống kê cho năm 2025
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
    Lấy chi tiết về các trips của user
    
    Returns:
        Dict với thông tin chi tiết về trips
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
    Lấy chi tiêu theo tháng
    
    Args:
        limit: Số tháng muốn lấy (default: 12)
        
    Returns:
        List các dict chứa month và amount
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
    Lấy tất cả dữ liệu cần thiết cho dashboard
    
    Returns:
        Dict chứa statistics, trip_details, và monthly_expenses
    """
    try:
        user_id = current_user.get('uid')
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found"
            )
        
        logger.info(f"Getting dashboard data for user: {user_id}")
        
        # Lấy tất cả dữ liệu cùng lúc
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