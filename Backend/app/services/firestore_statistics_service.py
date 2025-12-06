"""
Firestore Statistics Service for real-time user travel statistics
Kết nối với Firebase Firestore để lấy thống kê thời gian thực
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)

class FirestoreStatisticsService:
    def __init__(self):
        self.db = firestore.client()
    
    def get_user_statistics(self, user_id: str) -> Dict:
        """
        Lấy thống kê tổng hợp của user từ Firestore
        
        Args:
            user_id: Firebase UID của user
            
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
            stats = {
                'total_plans': 0,
                'total_days': 0,
                'locations_visited': 0,
                'total_trips': 0,
                'total_expenses': 0.0,
                # Stats for 2025
                'total_plans_2025': 0,
                'total_days_2025': 0,
                'locations_visited_2025': 0,
                'total_trips_2025': 0
            }
            
            # Lấy trips của user
            trips_ref = self.db.collection('users').document(user_id).collection('trips')
            trips = trips_ref.stream()
            
            now = datetime.now()
            year_2025_start = datetime(2025, 1, 1)
            year_2025_end = datetime(2025, 12, 31, 23, 59, 59)
            
            for trip_doc in trips:
                trip_data = trip_doc.to_dict()
                stats['total_plans'] += 1
                
                # Parse dates
                start_date = self._parse_date_helper(trip_data.get('startDate'))
                end_date = self._parse_date_helper(trip_data.get('endDate'))
                created_at = self._parse_date_helper(trip_data.get('createdAt')) or self._parse_date_helper(trip_data.get('created_at'))
                
                # Check if trip/plan is in 2025
                is_in_2025 = False
                if start_date and end_date:
                    # Check if trip overlaps with 2025
                    is_in_2025 = (end_date > year_2025_start and start_date < year_2025_end)
                elif created_at:
                    # Fallback: check creation date
                    is_in_2025 = created_at.year == 2025
                
                if is_in_2025:
                    stats['total_plans_2025'] += 1
                
                # Calculate trip duration and status
                if start_date and end_date:
                    duration = (end_date - start_date).days + 1
                    
                    # Check if trip is completed
                    if end_date < now:
                        stats['total_trips'] += 1
                        stats['total_days'] += duration  # Only count completed trips for total days
                        if is_in_2025:
                            stats['total_trips_2025'] += 1
                            stats['total_days_2025'] += duration
                    elif start_date <= now <= end_date:
                        # Ongoing trip - count days elapsed
                        days_elapsed = (now - start_date).days + 1
                        stats['total_days'] += days_elapsed
                        if is_in_2025:
                            stats['total_days_2025'] += days_elapsed
                
                # Count check-ins (locations actually visited)
                activities = trip_data.get('activities', [])
                for activity in activities:
                    # Check if activity is checked-in OR completed
                    is_checked_in = activity.get('checkIn', False) or activity.get('check_in', False)
                    is_completed = activity.get('status') == 'completed'
                    
                    # Filter by location-based activity types
                    activity_type = activity.get('activityType') or activity.get('activity_type', '')
                    is_location_based = self._is_location_based_activity(activity_type)
                    
                    if (is_checked_in or is_completed) and is_location_based:
                        stats['locations_visited'] += 1
                        if is_in_2025:
                            stats['locations_visited_2025'] += 1
                        # Add actual cost if available
                        if activity.get('actualCost'):
                            stats['total_expenses'] += float(activity.get('actualCost', 0))
            
            # Also check expenses collection
            try:
                expenses_ref = self.db.collection('users').document(user_id).collection('expenses')
                expenses = expenses_ref.stream()
                
                expenses_total = 0.0
                for expense_doc in expenses:
                    expense_data = expense_doc.to_dict()
                    actual_amount = expense_data.get('actual_amount', 0)
                    if actual_amount:
                        expenses_total += float(actual_amount)
                
                # Use expenses total if it's greater than activity costs
                if expenses_total > stats['total_expenses']:
                    stats['total_expenses'] = expenses_total
                    
            except Exception as e:
                logger.warning(f"Error getting expenses for user {user_id}: {e}")
            
            logger.info(f"Statistics for user {user_id}: {stats}")
            return stats
            
        except Exception as e:
            logger.error(f"Error getting statistics for user {user_id}: {e}")
            return {
                'total_plans': 0,
                'total_days': 0,
                'locations_visited': 0,
                'total_trips': 0,
                'total_expenses': 0.0,
                'total_plans_2025': 0,
                'total_days_2025': 0,
                'locations_visited_2025': 0,
                'total_trips_2025': 0,
                'error': str(e)
            }
    
    def _parse_date_helper(self, date_value):
        """
        Helper method to parse different date formats
        """
        if date_value is None:
            return None
        
        try:
            if hasattr(date_value, 'timestamp'):
                # Firestore Timestamp
                return datetime.fromtimestamp(date_value.timestamp())
            elif isinstance(date_value, str):
                # ISO string
                return datetime.fromisoformat(date_value.replace('Z', '+00:00')).replace(tzinfo=None)
            elif isinstance(date_value, datetime):
                # Already datetime
                return date_value.replace(tzinfo=None) if date_value.tzinfo else date_value
        except Exception as e:
            logger.warning(f"Error parsing date {date_value}: {e}")
        
        return None
    
    def _is_location_based_activity(self, activity_type: str) -> bool:
        """
        Check if activity type represents a location that can be visited
        """
        location_based_types = {
            'activity',
            'lodging', 
            'restaurant',
            'tour',
            'concert',
            'theater',
            'meeting',
            'parking'
        }
        return activity_type in location_based_types
    
    def get_trip_details(self, user_id: str) -> Dict:
        """
        Lấy chi tiết về các trips của user
        
        Returns:
            Dict với thông tin chi tiết về trips
        """
        try:
            details = {
                'total': 0,
                'completed': 0,
                'ongoing': 0,
                'upcoming': 0
            }
            
            trips_ref = self.db.collection('users').document(user_id).collection('trips')
            trips = trips_ref.stream()
            
            now = datetime.now()
            
            for trip_doc in trips:
                trip_data = trip_doc.to_dict()
                details['total'] += 1
                
                start_date = trip_data.get('startDate')
                end_date = trip_data.get('endDate')
                
                if start_date and end_date:
                    try:
                        # Parse dates
                        if isinstance(start_date, str):
                            start_date = datetime.fromisoformat(start_date.replace('Z', '+00:00')).replace(tzinfo=None)
                        elif hasattr(start_date, 'timestamp'):
                            start_date = datetime.fromtimestamp(start_date.timestamp())
                            
                        if isinstance(end_date, str):
                            end_date = datetime.fromisoformat(end_date.replace('Z', '+00:00')).replace(tzinfo=None)
                        elif hasattr(end_date, 'timestamp'):
                            end_date = datetime.fromtimestamp(end_date.timestamp())
                        
                        # Categorize trip
                        if end_date < now:
                            details['completed'] += 1
                        elif start_date > now:
                            details['upcoming'] += 1
                        else:
                            details['ongoing'] += 1
                            
                    except Exception as e:
                        logger.warning(f"Error parsing dates for trip {trip_doc.id}: {e}")
            
            return details
            
        except Exception as e:
            logger.error(f"Error getting trip details for user {user_id}: {e}")
            return {'total': 0, 'completed': 0, 'ongoing': 0, 'upcoming': 0, 'error': str(e)}
    
    def get_monthly_expenses(self, user_id: str, limit: int = 12) -> List[Dict]:
        """
        Lấy chi tiêu theo tháng
        
        Returns:
            List các dict chứa month và amount
        """
        try:
            monthly_expenses = {}
            
            # Get from expenses collection
            expenses_ref = self.db.collection('users').document(user_id).collection('expenses')
            expenses = expenses_ref.order_by('created_at', direction=firestore.Query.DESCENDING).limit(50).stream()
            
            for expense_doc in expenses:
                expense_data = expense_doc.to_dict()
                created_at = expense_data.get('created_at')
                actual_amount = expense_data.get('actual_amount', 0)
                
                if created_at and actual_amount:
                    if hasattr(created_at, 'timestamp'):
                        date = datetime.fromtimestamp(created_at.timestamp())
                    else:
                        continue
                        
                    month_key = f"{date.year}-{date.month:02d}"
                    monthly_expenses[month_key] = monthly_expenses.get(month_key, 0) + float(actual_amount)
            
            # Convert to list and sort
            result = [
                {'month': month, 'amount': amount}
                for month, amount in monthly_expenses.items()
            ]
            result.sort(key=lambda x: x['month'])
            
            return result[-limit:] if len(result) > limit else result
            
        except Exception as e:
            logger.error(f"Error getting monthly expenses for user {user_id}: {e}")
            return []