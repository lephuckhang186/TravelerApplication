from enum import Enum
from typing import List, Optional, Dict, Tuple, Any
from datetime import datetime, date, timedelta
from decimal import Decimal, getcontext
from dataclasses import dataclass
from collections import defaultdict
import json


class ActivityType(Enum):
    """
    Enumeration of different activity types supported in the application.
    """
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
    """
    Enumeration of possible statuses for an activity.
    """
    PLANNED = "planned"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Priority(Enum):
    """
    Enumeration of priority levels for activities.
    """
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


@dataclass
class Location:
    """
    Location information for activities.

    Attributes:
        name (str): Name of the location.
        address (Optional[str]): Street address.
        latitude (Optional[float]): Geographical latitude.
        longitude (Optional[float]): Geographical longitude.
        city (Optional[str]): City name.
        country (Optional[str]): Country name.
        postal_code (Optional[str]): Postal/ZIP code.
    """
    name: str
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    city: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None


@dataclass
class Budget:
    """
    Budget information for activities.

    Attributes:
        estimated_cost (Decimal): The estimated cost of the activity.
        actual_cost (Optional[Decimal]): The actual cost incurred.
        currency (str): Currency code (default: "VND").
        category (Optional[str]): Budget category (e.g., "Food", "Transport").
    """
    estimated_cost: Decimal
    actual_cost: Optional[Decimal] = None
    currency: str = "VND"
    category: Optional[str] = None


@dataclass
class Contact:
    """
    Contact information for activities.

    Attributes:
        name (Optional[str]): Contact person or organization name.
        phone (Optional[str]): Phone number.
        email (Optional[str]): Email address.
        website (Optional[str]): Website URL.
    """
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    
@dataclass
class Activity:
    """
    Dataclass representing a travel activity.

    Attributes:
        activity_type (ActivityType): The type of activity.
        name (str): The name or title of the activity.
        start_date (date): The starting date.
        end_date (date): The ending date.
        real_cost (Optional[Decimal]): The actual cost.
        expected_cost (Optional[Decimal]): The expected/budgeted cost.
        currency (Optional[str]): Currency code.
        start_time (Optional[datetime]): Specific start time.
        end_time (Optional[datetime]): Specific end time.
        location (Optional[Location]): Location details.
        details (Optional[str]): Detailed description.
        check_in (bool): Whether the user has checked in.
        status (ActivityStatus): Current status of the activity.
        priority (Priority): Priority level.
        budget (Optional[Budget]): Detailed budget information.
        contact (Optional[Contact]): Contact information.
        notes (Optional[str]): User notes.
        tags (List[str]): List of tags for categorization.
        trip_id (Optional[str]): Associated trip ID.
        id (Optional[str]): Unique activity ID.
        created_by (Optional[str]): User ID of the creator.
        created_at (Optional[datetime]): Creation timestamp.
        updated_at (Optional[datetime]): Last update timestamp.
    """
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
    """
    Manages the lifecycle and storage of travel activities.
    
    This class handles in-memory management of activities, providing methods
    to add, update, retrieve, and delete activities. It is designed to work
    in conjunction with a persistence layer (like Firestore or a local DB).
    """
    def __init__(self):
        """
        Initialize the ActivityManager.
        
        Sets up the internal dictionary for storing activities and attempts
        to load existing data from the configured storage.
        """
        self.activities: Dict[str, Activity] = {}
        # ✅ CRITICAL FIX: Load existing activities from SQLite database
        self._load_activities_from_database()
    
    def _load_activities_from_database(self):
        """
        Load all activities from the database into memory.

        Note:
            This method is currently disabled ("Database removed - using Firebase only").
            It acts as a placeholder or legacy hook.
        """
        try:
            # Database removed - using Firebase only
            return  # Skip database loading
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
        """
        Add a new activity to the manager.

        Args:
            activity (Activity): The activity object to add.

        Returns:
            str: The ID of the added activity (generated if not present).
        """
        if activity.id is None:
            import uuid
            activity.id = str(uuid.uuid4())
        activity.created_at = datetime.now()
        activity.updated_at = datetime.now()
        self.activities[activity.id] = activity
        return activity.id
        
    def get_activity_by_id(self, activity_id: str) -> Optional[Activity]:
        """
        Retrieve an activity by its unique ID.

        Args:
            activity_id (str): The ID of the activity.

        Returns:
            Optional[Activity]: The activity object if found, None otherwise.
        """
        return self.activities.get(activity_id)
        
    def get_activities_by_type(self, activity_type: ActivityType) -> List[Activity]:
        """
        Retrieve all activities of a specific type.

        Args:
            activity_type (ActivityType): The type filter.

        Returns:
            List[Activity]: A list of matching activities.
        """
        return [activity for activity in self.activities.values() if activity.activity_type == activity_type]
    
    def get_activities_in_date_range(self, start_date: date, end_date: date) -> List[Activity]:
        """
        Retrieve activities occurring within a specific date range.

        Args:
            start_date (date): The start of the date range.
            end_date (date): The end of the date range.

        Returns:
            List[Activity]: A list of activities overlapping with the range.
        """
        result = []
        for activity in self.activities.values():
            if activity.start_time and activity.end_time:
                if start_date <= activity.start_time.date() <= end_date or start_date <= activity.end_time.date() <= end_date:
                      result.append(activity)   
        return result
    
    def get_all_activities(self, user_id: Optional[str] = None) -> List[Activity]:
        """
        Retrieve all activities, optionally filtered by user.

        Args:
            user_id (Optional[str]): If provided, only returns activities created by this user.

        Returns:
            List[Activity]: A list of all (or filtered) activities.
        """
        if user_id:
            return [activity for activity in self.activities.values() if activity.created_by == user_id]
        return list(self.activities.values())
    
    def update_activity(self, activity_id: str, updates: Dict) -> bool:
        """
        Update an existing activity with new values.

        Args:
            activity_id (str): The ID of the activity to update.
            updates (Dict): A dictionary of field names and new values.

        Returns:
            bool: True if the update was successful, False if activity not found.
        """
        activity = self.activities.get(activity_id)
        if not activity:
            return False
            
        for key, value in updates.items():
            if hasattr(activity, key) and value is not None:
                setattr(activity, key, value)
        
        activity.updated_at = datetime.now()
        return True
    
    def remove_activity(self, activity: Activity) -> bool:
        """
        Remove an activity object from the manager.

        Args:
            activity (Activity): The activity object to remove.

        Returns:
            bool: True if removed, False if not found.
        """
        if activity.id in self.activities:
            del self.activities[activity.id]
            return True
        return False
    
    def remove_activity_by_id(self, activity_id: str) -> bool:
        """
        Remove an activity by its unique ID.

        Args:
            activity_id (str): The ID of the activity to remove.

        Returns:
            bool: True if removed, False if not found.
        """
        if activity_id in self.activities:
            del self.activities[activity_id]
            return True
        return False

    def checkin_activity(self, activity: Activity):
        """
        Mark an activity as checked in and update its status to IN_PROGRESS.

        Args:
            activity (Activity): The activity to check in.
        """
        activity.check_in = True
        activity.status = ActivityStatus.IN_PROGRESS
        activity.updated_at = datetime.now()

    def add_details_to_activity(self, activity: Activity, details: str):
        """
        Append additional details to an activity's description.

        Args:
            activity (Activity): The activity to update.
            details (str): The text to append to the existing details.
        """
        if activity.details is None:
            activity.details = ""
        activity.details += details
        activity.updated_at = datetime.now()
        
    def get_activities_by_status(self, status: ActivityStatus) -> List[Activity]:
        """
        Retrieve all activities with a specific status.

        Args:
            status (ActivityStatus): The status to filter by.

        Returns:
            List[Activity]: List of matching activities.
        """
        return [activity for activity in self.activities.values() if activity.status == status]
        
    def get_activities_by_priority(self, priority: Priority) -> List[Activity]:
        """
        Retrieve all activities with a specific priority level.

        Args:
            priority (Priority): The priority to filter by.

        Returns:
            List[Activity]: List of matching activities.
        """
        return [activity for activity in self.activities.values() if activity.priority == priority]
    
    def get_activities_by_user(self, user_id: str) -> List[Activity]:
        """
        Retrieve all activities created by a specific user.

        Args:
            user_id (str): The user ID.

        Returns:
            List[Activity]: List of matching activities.
        """
        return [activity for activity in self.activities.values() if activity.created_by == user_id]
    
    def get_activity(self, activity_id: str) -> Optional[Activity]:
        """
        Retrieve an activity by ID (Alias for get_activity_by_id).

        Args:
            activity_id (str): The activity ID.

        Returns:
            Optional[Activity]: The activity if found, None otherwise.
        """
        return self.activities.get(activity_id)
    
    def schedule_activity(self, activity_id: str, start_date: datetime, 
                         end_date: Optional[datetime] = None, duration_minutes: Optional[int] = None):
        """
        Schedule or reschedule an activity.
        
        This method updates the start and end times of an activity.

        Args:
            activity_id (str): The ID of the activity.
            start_date (datetime): The new start datetime.
            end_date (Optional[datetime]): The new end datetime.
            duration_minutes (Optional[int]): Duration in minutes (used if end_date is not provided).

        Returns:
            Optional[Activity]: The updated activity object if found, None otherwise.
        """
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
        """
        Check for any activities that conflict with the given time range.

        Args:
            start_date (datetime): The start of the proposed time slot.
            end_date (datetime): The end of the proposed time slot.
            trip_id (Optional[str]): If provided, only check against activities in this trip.
            exclude_activity_id (Optional[str]): ID of an activity to ignore (e.g., the one being rescheduled).

        Returns:
            List[Activity]: A list of conflicting activities.
        """
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
    
    def get_activity_statistics(self) -> Dict[str, Any]:
        """
        Calculate statistics for all managed activities.
        
        Aggregates counts by status, type, and priority.

        Returns:
            Dict[str, Any]: A dictionary containing statistical data:
                - 'total_activities' (int)
                - 'by_status' (Dict[str, int])
                - 'by_type' (Dict[str, int])
                - 'by_priority' (Dict[str, int])
        """
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
    
    def export_activities(self, trip_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Export activities to a dictionary format suitable for serialization (e.g., JSON).

        Args:
            trip_id (Optional[str]): If provided, only exports activities for this trip.

        Returns:
            Dict[str, Any]: A dictionary containing the list of exported activities and metadata.
        """
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
    