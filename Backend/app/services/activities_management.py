from enum import Enum
from typing import List, Optional, Dict, Tuple
from datetime import datetime, date, timedelta
from decimal import Decimal, getcontext
from dataclasses import dataclass
from collections import defaultdict
import json


class ActivityType(Enum):
    """Enumeration of different activity types."""
    FLIGHT = "flight"
    ACTIVITY = "activity"
    LODGING = "lodging"
    CAR_RENTAL = "car_rental"
    CONCERT = "concert"
    CRUISING = "cruising"
    DIRECTION = "direction"
    FERRY = "ferry"
    GROUND_TRANSPORTATION = "ground_transportation"
    MAP = "map"
    MEETING = "meeting"
    NOTE = "note"
    PARKING = "parking"
    RAIL = "rail"
    RESTAURANT = "restaurant"
    THEATER = "theater"
    TOUR = "tour"
    TRANSPORTATION = "transportation"


class ActivityStatus(Enum):
    """Enumeration of activity statuses."""
    PLANNED = "planned"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Priority(Enum):
    """Enumeration of priority levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


@dataclass
class Location:
    """Location information for activities."""
    name: str
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    city: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None


@dataclass
class Budget:
    """Budget information for activities."""
    estimated_cost: Decimal
    actual_cost: Optional[Decimal] = None
    currency: str = "VND"
    category: Optional[str] = None


@dataclass
class Contact:
    """Contact information for activities."""
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    
@dataclass
class Activity:
    """Dataclass representing an activity."""
    activity_type: ActivityType
    name: str
    start_date: date
    end_date: date
    real_cost: Optional[Decimal] = None 
    expected_cost: Optional[Decimal] = None
    currency: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    location: Optional[Location] = None
    details: Optional[str] = None
    check_in: bool = False
    # Additional fields for API compatibility
    status: ActivityStatus = ActivityStatus.PLANNED
    priority: Priority = Priority.MEDIUM
    budget: Optional[Budget] = None
    contact: Optional[Contact] = None
    notes: Optional[str] = None
    tags: List[str] = None
    trip_id: Optional[str] = None
    id: Optional[str] = None
    created_by: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Initialize default values after object creation."""
        if self.tags is None:
            self.tags = []
        if self.created_at is None:
            self.created_at = datetime.now()
        if self.updated_at is None:
            self.updated_at = datetime.now()
        if self.id is None:
            import uuid
            self.id = str(uuid.uuid4())

class ActivityManager:
    def __init__(self):
        self.activities: Dict[str, Activity] = {}
        # ✅ CRITICAL FIX: Load existing activities from SQLite database
        self._load_activities_from_database()
    
    def _load_activities_from_database(self):
        """Load all activities from SQLite database into memory"""
        try:
            from app.database import DatabaseManager
            db_manager = DatabaseManager()
            from datetime import datetime
            
            # Get all activities from database
            db_activities = db_manager.get_all_activities()
            
            if db_activities:
                for db_activity in db_activities:
                    try:
                        # Convert database record to Activity object
                        activity_data = {
                            'id': db_activity.get('id'),
                            'name': db_activity.get('name', ''),
                            'activity_type': ActivityType(db_activity.get('activity_type', 'OTHER')),
                            'details': db_activity.get('description', '') or db_activity.get('details', ''),
                            'location': db_activity.get('location'),
                            'contact': db_activity.get('contact'),
                            'notes': db_activity.get('notes', ''),
                            'tags': db_activity.get('tags', []) or [],
                            'check_in': db_activity.get('check_in', False),
                            'created_by': db_activity.get('created_by', ''),
                        }
                        
                        # Handle datetime fields
                        if db_activity.get('start_time'):
                            try:
                                activity_data['start_time'] = datetime.fromisoformat(db_activity['start_time'].replace('Z', '+00:00'))
                            except:
                                activity_data['start_time'] = None
                                
                        if db_activity.get('end_time'):
                            try:
                                activity_data['end_time'] = datetime.fromisoformat(db_activity['end_time'].replace('Z', '+00:00'))
                            except:
                                activity_data['end_time'] = None
                                
                        if db_activity.get('created_at'):
                            try:
                                activity_data['created_at'] = datetime.fromisoformat(db_activity['created_at'].replace('Z', '+00:00'))
                            except:
                                activity_data['created_at'] = datetime.now()
                        else:
                            activity_data['created_at'] = datetime.now()
                            
                        if db_activity.get('updated_at'):
                            try:
                                activity_data['updated_at'] = datetime.fromisoformat(db_activity['updated_at'].replace('Z', '+00:00'))
                            except:
                                activity_data['updated_at'] = datetime.now()
                        else:
                            activity_data['updated_at'] = datetime.now()
                        
                        # Add trip_id if available
                        if db_activity.get('trip_id'):
                            activity_data['trip_id'] = db_activity['trip_id']
                        
                        # Create Activity object and add to memory
                        activity = Activity(**activity_data)
                        self.activities[activity.id] = activity
                        
                    except Exception as e:
                        print(f"⚠️ ACTIVITY_LOAD_WARNING: Failed to load activity {db_activity.get('id', 'unknown')}: {e}")
                
                print(f"✅ ACTIVITIES_LOADED: Loaded {len(self.activities)} activities from database into memory")
            else:
                print("ℹ️ ACTIVITIES_INIT: No activities found in database")
                
        except Exception as e:
            print(f"❌ ACTIVITIES_LOAD_ERROR: Failed to load activities from database: {e}")
        
    def add_activity(self, activity: Activity) -> str:
        """Adds an activity to the manager and returns its ID."""
        if activity.id is None:
            import uuid
            activity.id = str(uuid.uuid4())
        activity.created_at = datetime.now()
        activity.updated_at = datetime.now()
        self.activities[activity.id] = activity
        return activity.id
        
    def get_activity_by_id(self, activity_id: str) -> Optional[Activity]:
        """Retrieves an activity by its ID."""
        return self.activities.get(activity_id)
        
    def get_activities_by_type(self, activity_type: ActivityType) -> List[Activity]:
        """Retrieves activities of a specific type."""
        return [activity for activity in self.activities.values() if activity.activity_type == activity_type]
    
    def get_activities_in_date_range(self, start_date: date, end_date: date) -> List[Activity]:
        """Retrieves activities within a specific date range."""
        result = []
        for activity in self.activities.values():
            if activity.start_time and activity.end_time:
                if start_date <= activity.start_time.date() <= end_date or start_date <= activity.end_time.date() <= end_date:
                      result.append(activity)   
        return result
    
    def get_all_activities(self, user_id: Optional[str] = None) -> List[Activity]:
        """Retrieves all activities, optionally filtered by user."""
        if user_id:
            return [activity for activity in self.activities.values() if activity.created_by == user_id]
        return list(self.activities.values())
    
    def update_activity(self, activity_id: str, updates: Dict) -> bool:
        """Updates an activity with the given updates."""
        activity = self.activities.get(activity_id)
        if not activity:
            return False
            
        for key, value in updates.items():
            if hasattr(activity, key) and value is not None:
                setattr(activity, key, value)
        
        activity.updated_at = datetime.now()
        return True
    
    def remove_activity(self, activity: Activity) -> bool:
        """Removes an activity from the manager."""
        if activity.id in self.activities:
            del self.activities[activity.id]
            return True
        return False
    
    def remove_activity_by_id(self, activity_id: str) -> bool:
        """Removes an activity by its ID."""
        if activity_id in self.activities:
            del self.activities[activity_id]
            return True
        return False

    def checkin_activity(self, activity: Activity):
        """Marks an activity as checked in."""
        activity.check_in = True
        activity.status = ActivityStatus.IN_PROGRESS
        activity.updated_at = datetime.now()

    def add_details_to_activity(self, activity: Activity, details: str):
        """Adds additional details to an activity."""
        if activity.details is None:
            activity.details = ""
        activity.details += details
        activity.updated_at = datetime.now()
        
    def get_activities_by_status(self, status: ActivityStatus) -> List[Activity]:
        """Retrieves activities by status."""
        return [activity for activity in self.activities.values() if activity.status == status]
        
    def get_activities_by_priority(self, priority: Priority) -> List[Activity]:
        """Retrieves activities by priority."""
        return [activity for activity in self.activities.values() if activity.priority == priority]
    
    def get_activities_by_user(self, user_id: str) -> List[Activity]:
        """Get activities by user ID"""
        return [activity for activity in self.activities.values() if activity.created_by == user_id]
    
    def get_activity(self, activity_id: str) -> Optional[Activity]:
        """Get activity by ID"""
        return self.activities.get(activity_id)
    
    def schedule_activity(self, activity_id: str, start_date: datetime, 
                         end_date: Optional[datetime] = None, duration_minutes: Optional[int] = None):
        """Schedule an activity"""
        activity = self.activities.get(activity_id)
        if not activity:
            return None
            
        activity.start_time = start_date
        if end_date:
            activity.end_time = end_date
        elif duration_minutes:
            activity.end_time = start_date + timedelta(minutes=duration_minutes)
            
        activity.updated_at = datetime.now()
        return activity
    
    def check_schedule_conflicts(self, start_date: datetime, end_date: datetime,
                               trip_id: Optional[str] = None, exclude_activity_id: Optional[str] = None):
        """Check for schedule conflicts"""
        conflicts = []
        for activity in self.activities.values():
            if exclude_activity_id and activity.id == exclude_activity_id:
                continue
            if trip_id and activity.trip_id != trip_id:
                continue
                
            if (activity.start_time and activity.end_time and
                not (end_date <= activity.start_time or start_date >= activity.end_time)):
                conflicts.append(activity)
                
        return conflicts
    
    def get_activity_statistics(self):
        """Get activity statistics"""
        total_activities = len(self.activities)
        status_counts = {}
        type_counts = {}
        priority_counts = {}
        
        for activity in self.activities.values():
            # Count by status
            status = activity.status.value if hasattr(activity.status, 'value') else str(activity.status)
            status_counts[status] = status_counts.get(status, 0) + 1
            
            # Count by type
            activity_type = activity.activity_type.value if hasattr(activity.activity_type, 'value') else str(activity.activity_type)
            type_counts[activity_type] = type_counts.get(activity_type, 0) + 1
            
            # Count by priority
            priority = activity.priority.value if hasattr(activity.priority, 'value') else str(activity.priority)
            priority_counts[priority] = priority_counts.get(priority, 0) + 1
        
        return {
            'total_activities': total_activities,
            'by_status': status_counts,
            'by_type': type_counts,
            'by_priority': priority_counts
        }
    
    def export_activities(self, trip_id: Optional[str] = None):
        """Export activities"""
        activities_to_export = []
        
        for activity in self.activities.values():
            if trip_id and activity.trip_id != trip_id:
                continue
                
            activity_data = {
                'id': activity.id,
                'name': activity.name,
                'type': activity.activity_type.value if hasattr(activity.activity_type, 'value') else str(activity.activity_type),
                'status': activity.status.value if hasattr(activity.status, 'value') else str(activity.status),
                'priority': activity.priority.value if hasattr(activity.priority, 'value') else str(activity.priority),
                'start_date': activity.start_date.isoformat() if activity.start_date else None,
                'end_date': activity.end_date.isoformat() if activity.end_date else None,
                'start_time': activity.start_time.isoformat() if activity.start_time else None,
                'end_time': activity.end_time.isoformat() if activity.end_time else None,
                'details': activity.details,
                'notes': activity.notes,
                'tags': activity.tags,
                'trip_id': activity.trip_id,
                'check_in': activity.check_in,
                'expected_cost': str(activity.expected_cost) if activity.expected_cost else None,
                'real_cost': str(activity.real_cost) if activity.real_cost else None,
                'currency': activity.currency,
                'created_by': activity.created_by,
                'created_at': activity.created_at.isoformat() if activity.created_at else None,
                'updated_at': activity.updated_at.isoformat() if activity.updated_at else None
            }
            
            if activity.location:
                activity_data['location'] = {
                    'name': activity.location.name,
                    'address': activity.location.address,
                    'latitude': activity.location.latitude,
                    'longitude': activity.location.longitude,
                    'city': activity.location.city,
                    'country': activity.location.country,
                    'postal_code': activity.location.postal_code
                }
            
            if activity.contact:
                activity_data['contact'] = {
                    'name': activity.contact.name,
                    'phone': activity.contact.phone,
                    'email': activity.contact.email,
                    'website': activity.contact.website
                }
                
            if activity.budget:
                activity_data['budget'] = {
                    'estimated_cost': str(activity.budget.estimated_cost),
                    'actual_cost': str(activity.budget.actual_cost) if activity.budget.actual_cost else None,
                    'currency': activity.budget.currency,
                    'category': activity.budget.category
                }
            
            activities_to_export.append(activity_data)
        
        return {
            'activities': activities_to_export,
            'total_count': len(activities_to_export),
            'export_date': datetime.now().isoformat(),
            'trip_id': trip_id
        }
    