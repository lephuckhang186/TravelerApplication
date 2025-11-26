from enum import Enum
from typing import List, Optional, Dict, Tuple, Any
from datetime import datetime, date, timedelta
from decimal import Decimal, getcontext
from dataclasses import dataclass, field
from collections import defaultdict
import json
import uuid
from pydantic import BaseModel, Field, validator


class ActivityType(str, Enum):
    """Activity types for travel planning"""
    SIGHTSEEING = "sightseeing"
    DINING = "dining"
    SHOPPING = "shopping"
    TRANSPORTATION = "transportation"
    ACCOMMODATION = "accommodation"
    ENTERTAINMENT = "entertainment"
    ADVENTURE = "adventure"
    CULTURAL = "cultural"
    BUSINESS = "business"
    LEISURE = "leisure"
    FITNESS = "fitness"
    EDUCATION = "education"
    MEDICAL = "medical"
    OTHER = "other"


class ActivityStatus(str, Enum):
    """Activity status options"""
    PLANNED = "planned"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    POSTPONED = "postponed"


class Priority(str, Enum):
    """Priority levels for activities"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class Location:
    """Location information for activities"""
    name: str
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    city: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None


@dataclass
class Budget:
    """Budget information for activities"""
    estimated_cost: Decimal
    actual_cost: Optional[Decimal] = None
    currency: str = "VND"
    category: Optional[str] = None


@dataclass
class Contact:
    """Contact information for activities"""
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None


@dataclass
class Activity:
    """Main activity class"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    title: str = ""
    description: Optional[str] = None
    activity_type: ActivityType = ActivityType.OTHER
    status: ActivityStatus = ActivityStatus.PLANNED
    priority: Priority = Priority.MEDIUM
    
    # Timing
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    
    # Location and Budget
    location: Optional[Location] = None
    budget: Optional[Budget] = None
    
    # Additional info
    contact: Optional[Contact] = None
    notes: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    attachments: List[str] = field(default_factory=list)  # File URLs
    
    # Metadata
    created_by: str = ""
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    trip_id: Optional[str] = None
    
    # Booking info
    booking_reference: Optional[str] = None
    booking_url: Optional[str] = None
    is_booked: bool = False


class ActivityManager:
    """Service class for managing travel activities"""
    
    def __init__(self):
        self.activities: Dict[str, Activity] = {}
        
    def create_activity(
        self,
        title: str,
        activity_type: ActivityType,
        created_by: str,
        description: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        location: Optional[Dict] = None,
        budget: Optional[Dict] = None,
        trip_id: Optional[str] = None,
        **kwargs
    ) -> Activity:
        """Create a new activity"""
        activity = Activity(
            title=title,
            description=description,
            activity_type=activity_type,
            start_date=start_date,
            end_date=end_date,
            created_by=created_by,
            trip_id=trip_id,
            **kwargs
        )
        
        if location:
            activity.location = Location(**location)
            
        if budget:
            activity.budget = Budget(**budget)
            
        self.activities[activity.id] = activity
        return activity
    
    def get_activity(self, activity_id: str) -> Optional[Activity]:
        """Get activity by ID"""
        return self.activities.get(activity_id)
    
    def update_activity(
        self,
        activity_id: str,
        **updates
    ) -> Optional[Activity]:
        """Update an existing activity"""
        activity = self.activities.get(activity_id)
        if not activity:
            return None
            
        for key, value in updates.items():
            if hasattr(activity, key):
                setattr(activity, key, value)
                
        activity.updated_at = datetime.now()
        return activity
    
    def delete_activity(self, activity_id: str) -> bool:
        """Delete an activity"""
        if activity_id in self.activities:
            del self.activities[activity_id]
            return True
        return False
    
    def get_activities_by_trip(self, trip_id: str) -> List[Activity]:
        """Get all activities for a specific trip"""
        return [
            activity for activity in self.activities.values()
            if activity.trip_id == trip_id
        ]
    
    def get_activities_by_user(self, user_id: str) -> List[Activity]:
        """Get all activities created by a specific user"""
        return [
            activity for activity in self.activities.values()
            if activity.created_by == user_id
        ]
    
    def get_activities_by_type(self, activity_type: ActivityType) -> List[Activity]:
        """Get activities by type"""
        return [
            activity for activity in self.activities.values()
            if activity.activity_type == activity_type
        ]
    
    def get_activities_by_status(self, status: ActivityStatus) -> List[Activity]:
        """Get activities by status"""
        return [
            activity for activity in self.activities.values()
            if activity.status == status
        ]
    
    def get_activities_by_date_range(
        self,
        start_date: date,
        end_date: date,
        trip_id: Optional[str] = None
    ) -> List[Activity]:
        """Get activities within a date range"""
        activities = []
        for activity in self.activities.values():
            if activity.start_date and activity.start_date.date() >= start_date:
                if not activity.end_date or activity.end_date.date() <= end_date:
                    if not trip_id or activity.trip_id == trip_id:
                        activities.append(activity)
        return activities
    
    def search_activities(
        self,
        query: str,
        trip_id: Optional[str] = None,
        activity_type: Optional[ActivityType] = None,
        status: Optional[ActivityStatus] = None
    ) -> List[Activity]:
        """Search activities by title, description, or tags"""
        query_lower = query.lower()
        results = []
        
        for activity in self.activities.values():
            # Check trip filter
            if trip_id and activity.trip_id != trip_id:
                continue
                
            # Check type filter
            if activity_type and activity.activity_type != activity_type:
                continue
                
            # Check status filter
            if status and activity.status != status:
                continue
            
            # Search in title, description, and tags
            if (query_lower in activity.title.lower() or
                (activity.description and query_lower in activity.description.lower()) or
                any(query_lower in tag.lower() for tag in activity.tags)):
                results.append(activity)
                
        return results
    
    def get_activity_statistics(self, trip_id: Optional[str] = None) -> Dict[str, Any]:
        """Get statistics about activities"""
        activities = (
            self.get_activities_by_trip(trip_id) if trip_id
            else list(self.activities.values())
        )
        
        if not activities:
            return {
                "total_activities": 0,
                "by_type": {},
                "by_status": {},
                "by_priority": {},
                "budget_summary": {}
            }
        
        # Count by type
        type_counts = defaultdict(int)
        for activity in activities:
            type_counts[activity.activity_type.value] += 1
            
        # Count by status
        status_counts = defaultdict(int)
        for activity in activities:
            status_counts[activity.status.value] += 1
            
        # Count by priority
        priority_counts = defaultdict(int)
        for activity in activities:
            priority_counts[activity.priority.value] += 1
            
        # Budget summary
        total_estimated = Decimal('0')
        total_actual = Decimal('0')
        currencies = set()
        
        for activity in activities:
            if activity.budget:
                total_estimated += activity.budget.estimated_cost
                if activity.budget.actual_cost:
                    total_actual += activity.budget.actual_cost
                currencies.add(activity.budget.currency)
        
        return {
            "total_activities": len(activities),
            "by_type": dict(type_counts),
            "by_status": dict(status_counts),
            "by_priority": dict(priority_counts),
            "budget_summary": {
                "total_estimated": float(total_estimated),
                "total_actual": float(total_actual),
                "currencies": list(currencies),
                "variance": float(total_actual - total_estimated) if total_actual else None
            }
        }
    
    def schedule_activity(
        self,
        activity_id: str,
        start_date: datetime,
        end_date: Optional[datetime] = None,
        duration_minutes: Optional[int] = None
    ) -> Optional[Activity]:
        """Schedule an activity with specific timing"""
        activity = self.get_activity(activity_id)
        if not activity:
            return None
            
        activity.start_date = start_date
        
        if end_date:
            activity.end_date = end_date
            activity.duration_minutes = int((end_date - start_date).total_seconds() / 60)
        elif duration_minutes:
            activity.duration_minutes = duration_minutes
            activity.end_date = start_date + timedelta(minutes=duration_minutes)
            
        activity.updated_at = datetime.now()
        return activity
    
    def check_schedule_conflicts(
        self,
        start_date: datetime,
        end_date: datetime,
        trip_id: Optional[str] = None,
        exclude_activity_id: Optional[str] = None
    ) -> List[Activity]:
        """Check for scheduling conflicts with existing activities"""
        conflicts = []
        
        for activity in self.activities.values():
            if exclude_activity_id and activity.id == exclude_activity_id:
                continue
                
            if trip_id and activity.trip_id != trip_id:
                continue
                
            if not activity.start_date or not activity.end_date:
                continue
                
            # Check for overlap
            if (start_date < activity.end_date and end_date > activity.start_date):
                conflicts.append(activity)
                
        return conflicts
    
    def export_activities(self, trip_id: Optional[str] = None) -> Dict[str, Any]:
        """Export activities to JSON format"""
        activities = (
            self.get_activities_by_trip(trip_id) if trip_id
            else list(self.activities.values())
        )
        
        return {
            "export_date": datetime.now().isoformat(),
            "trip_id": trip_id,
            "total_activities": len(activities),
            "activities": [
                {
                    "id": activity.id,
                    "title": activity.title,
                    "description": activity.description,
                    "type": activity.activity_type.value,
                    "status": activity.status.value,
                    "priority": activity.priority.value,
                    "start_date": activity.start_date.isoformat() if activity.start_date else None,
                    "end_date": activity.end_date.isoformat() if activity.end_date else None,
                    "location": {
                        "name": activity.location.name,
                        "address": activity.location.address,
                        "latitude": activity.location.latitude,
                        "longitude": activity.location.longitude,
                        "city": activity.location.city,
                        "country": activity.location.country
                    } if activity.location else None,
                    "budget": {
                        "estimated_cost": float(activity.budget.estimated_cost),
                        "actual_cost": float(activity.budget.actual_cost) if activity.budget.actual_cost else None,
                        "currency": activity.budget.currency
                    } if activity.budget else None,
                    "notes": activity.notes,
                    "tags": activity.tags,
                    "booking_reference": activity.booking_reference,
                    "is_booked": activity.is_booked
                }
                for activity in activities
            ]
        }