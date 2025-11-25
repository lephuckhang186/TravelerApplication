"""
Activities Management API Endpoints
"""
from fastapi import APIRouter, HTTPException, Depends, Query, status
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, Field, validator

# Import dependencies and services
try:
    from ...core.dependencies import get_current_user, get_firebase_user
    from ...services.activities_management import (
        ActivityManager, Activity, ActivityType, ActivityStatus, Priority,
        Location, Budget, Contact
    )
    from ...models.user import User
except ImportError:
    # Fallback for direct execution
    import sys
    import os
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    from core.dependencies import get_current_user, get_firebase_user
    from services.activities_management import (
        ActivityManager, Activity, ActivityType, ActivityStatus, Priority,
        Location, Budget, Contact
    )
    from models.user import User

# Create router
router = APIRouter(prefix="/activities", tags=["Activities Management"])

# Global activity manager instance (in production, use database)
activity_manager = ActivityManager()


# ============= PYDANTIC MODELS =============

class LocationCreate(BaseModel):
    """Location creation model"""
    name: str = Field(..., min_length=1, max_length=200)
    address: Optional[str] = Field(None, max_length=500)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    city: Optional[str] = Field(None, max_length=100)
    country: Optional[str] = Field(None, max_length=100)
    postal_code: Optional[str] = Field(None, max_length=20)


class LocationResponse(LocationCreate):
    """Location response model"""
    pass


class BudgetCreate(BaseModel):
    """Budget creation model"""
    estimated_cost: float = Field(..., ge=0)
    actual_cost: Optional[float] = Field(None, ge=0)
    currency: str = Field(default="VND", max_length=3)
    category: Optional[str] = Field(None, max_length=50)


class BudgetResponse(BudgetCreate):
    """Budget response model"""
    pass


class ContactCreate(BaseModel):
    """Contact creation model"""
    name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    email: Optional[str] = Field(None, max_length=100)
    website: Optional[str] = Field(None, max_length=200)


class ContactResponse(ContactCreate):
    """Contact response model"""
    pass


class ActivityCreate(BaseModel):
    """Activity creation model"""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    activity_type: ActivityType
    status: ActivityStatus = ActivityStatus.PLANNED
    priority: Priority = Priority.MEDIUM
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, ge=1, le=86400)  # Max 1 day
    location: Optional[LocationCreate] = None
    budget: Optional[BudgetCreate] = None
    contact: Optional[ContactCreate] = None
    notes: Optional[str] = Field(None, max_length=2000)
    tags: List[str] = Field(default_factory=list, max_items=20)
    trip_id: Optional[str] = Field(None, max_length=50)
    booking_reference: Optional[str] = Field(None, max_length=100)
    booking_url: Optional[str] = Field(None, max_length=500)
    is_booked: bool = False

    @validator('tags')
    def validate_tags(cls, v):
        """Validate tags"""
        if v:
            for tag in v:
                if not isinstance(tag, str) or len(tag) > 50:
                    raise ValueError("Each tag must be a string with max length 50")
        return v

    @validator('end_date')
    def validate_dates(cls, v, values):
        """Validate that end_date is after start_date"""
        if v and values.get('start_date') and v <= values['start_date']:
            raise ValueError("End date must be after start date")
        return v


class ActivityUpdate(BaseModel):
    """Activity update model"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    activity_type: Optional[ActivityType] = None
    status: Optional[ActivityStatus] = None
    priority: Optional[Priority] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, ge=1, le=86400)
    location: Optional[LocationCreate] = None
    budget: Optional[BudgetCreate] = None
    contact: Optional[ContactCreate] = None
    notes: Optional[str] = Field(None, max_length=2000)
    tags: Optional[List[str]] = Field(None, max_items=20)
    trip_id: Optional[str] = Field(None, max_length=50)
    booking_reference: Optional[str] = Field(None, max_length=100)
    booking_url: Optional[str] = Field(None, max_length=500)
    is_booked: Optional[bool] = None


class ActivityResponse(BaseModel):
    """Activity response model"""
    id: str
    title: str
    description: Optional[str]
    activity_type: ActivityType
    status: ActivityStatus
    priority: Priority
    start_date: Optional[datetime]
    end_date: Optional[datetime]
    duration_minutes: Optional[int]
    location: Optional[LocationResponse]
    budget: Optional[BudgetResponse]
    contact: Optional[ContactResponse]
    notes: Optional[str]
    tags: List[str]
    attachments: List[str]
    created_by: str
    created_at: datetime
    updated_at: datetime
    trip_id: Optional[str]
    booking_reference: Optional[str]
    booking_url: Optional[str]
    is_booked: bool


class ActivityListResponse(BaseModel):
    """Activity list response model"""
    activities: List[ActivityResponse]
    total: int
    page: int
    limit: int
    has_next: bool


class ScheduleRequest(BaseModel):
    """Schedule activity request"""
    start_date: datetime
    end_date: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, ge=1, le=86400)


class ConflictCheckRequest(BaseModel):
    """Schedule conflict check request"""
    start_date: datetime
    end_date: datetime
    trip_id: Optional[str] = None
    exclude_activity_id: Optional[str] = None


# ============= HELPER FUNCTIONS =============

def activity_to_response(activity: Activity) -> ActivityResponse:
    """Convert Activity to ActivityResponse"""
    return ActivityResponse(
        id=activity.id,
        title=activity.title,
        description=activity.description,
        activity_type=activity.activity_type,
        status=activity.status,
        priority=activity.priority,
        start_date=activity.start_date,
        end_date=activity.end_date,
        duration_minutes=activity.duration_minutes,
        location=LocationResponse(**activity.location.__dict__) if activity.location else None,
        budget=BudgetResponse(
            estimated_cost=float(activity.budget.estimated_cost),
            actual_cost=float(activity.budget.actual_cost) if activity.budget.actual_cost else None,
            currency=activity.budget.currency,
            category=activity.budget.category
        ) if activity.budget else None,
        contact=ContactResponse(**activity.contact.__dict__) if activity.contact else None,
        notes=activity.notes,
        tags=activity.tags,
        attachments=activity.attachments,
        created_by=activity.created_by,
        created_at=activity.created_at,
        updated_at=activity.updated_at,
        trip_id=activity.trip_id,
        booking_reference=activity.booking_reference,
        booking_url=activity.booking_url,
        is_booked=activity.is_booked
    )


# ============= API ENDPOINTS =============

@router.post("/", response_model=ActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    activity_data: ActivityCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new activity"""
    try:
        # Convert budget to Decimal if provided
        budget_dict = None
        if activity_data.budget:
            budget_dict = activity_data.budget.dict()
            budget_dict['estimated_cost'] = Decimal(str(budget_dict['estimated_cost']))
            if budget_dict['actual_cost'] is not None:
                budget_dict['actual_cost'] = Decimal(str(budget_dict['actual_cost']))

        # Convert location to dict if provided
        location_dict = activity_data.location.dict() if activity_data.location else None
        
        # Convert contact to dict if provided
        contact_dict = activity_data.contact.dict() if activity_data.contact else None

        activity = activity_manager.create_activity(
            title=activity_data.title,
            activity_type=activity_data.activity_type,
            created_by=current_user.id,
            description=activity_data.description,
            status=activity_data.status,
            priority=activity_data.priority,
            start_date=activity_data.start_date,
            end_date=activity_data.end_date,
            duration_minutes=activity_data.duration_minutes,
            location=location_dict,
            budget=budget_dict,
            trip_id=activity_data.trip_id,
            notes=activity_data.notes,
            tags=activity_data.tags,
            booking_reference=activity_data.booking_reference,
            booking_url=activity_data.booking_url,
            is_booked=activity_data.is_booked
        )

        # Set contact if provided
        if contact_dict:
            activity.contact = Contact(**contact_dict)

        return activity_to_response(activity)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create activity: {str(e)}"
        )


@router.get("/", response_model=ActivityListResponse)
async def get_activities(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    activity_type: Optional[ActivityType] = Query(None, description="Filter by activity type"),
    status: Optional[ActivityStatus] = Query(None, description="Filter by status"),
    priority: Optional[Priority] = Query(None, description="Filter by priority"),
    search: Optional[str] = Query(None, description="Search in title, description, tags"),
    start_date: Optional[date] = Query(None, description="Filter by start date (from)"),
    end_date: Optional[date] = Query(None, description="Filter by end date (to)"),
    current_user: User = Depends(get_current_user)
):
    """Get activities with filtering and pagination"""
    try:
        # Start with all user's activities
        activities = activity_manager.get_activities_by_user(current_user.id)

        # Apply filters
        if trip_id:
            activities = [a for a in activities if a.trip_id == trip_id]
        
        if activity_type:
            activities = [a for a in activities if a.activity_type == activity_type]
            
        if status:
            activities = [a for a in activities if a.status == status]
            
        if priority:
            activities = [a for a in activities if a.priority == priority]
            
        if search:
            search_lower = search.lower()
            activities = [
                a for a in activities
                if (search_lower in a.title.lower() or
                    (a.description and search_lower in a.description.lower()) or
                    any(search_lower in tag.lower() for tag in a.tags))
            ]
            
        if start_date and end_date:
            activities = [
                a for a in activities
                if a.start_date and a.start_date.date() >= start_date and
                (not a.end_date or a.end_date.date() <= end_date)
            ]

        # Sort by created_at descending
        activities.sort(key=lambda x: x.created_at, reverse=True)

        # Pagination
        total = len(activities)
        start_idx = (page - 1) * limit
        end_idx = start_idx + limit
        paginated_activities = activities[start_idx:end_idx]

        return ActivityListResponse(
            activities=[activity_to_response(activity) for activity in paginated_activities],
            total=total,
            page=page,
            limit=limit,
            has_next=end_idx < total
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get activities: {str(e)}"
        )


@router.get("/{activity_id}", response_model=ActivityResponse)
async def get_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get activity by ID"""
    activity = activity_manager.get_activity(activity_id)
    
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    # Check ownership
    if activity.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this activity"
        )

    return activity_to_response(activity)


@router.put("/{activity_id}", response_model=ActivityResponse)
async def update_activity(
    activity_id: str,
    activity_data: ActivityUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update an existing activity"""
    activity = activity_manager.get_activity(activity_id)
    
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    # Check ownership
    if activity.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this activity"
        )

    try:
        # Prepare updates
        updates = {}
        for field, value in activity_data.dict(exclude_unset=True).items():
            if field == "budget" and value:
                # Convert to Decimal
                budget_dict = value
                budget_dict['estimated_cost'] = Decimal(str(budget_dict['estimated_cost']))
                if budget_dict['actual_cost'] is not None:
                    budget_dict['actual_cost'] = Decimal(str(budget_dict['actual_cost']))
                updates[field] = Budget(**budget_dict)
            elif field == "location" and value:
                updates[field] = Location(**value)
            elif field == "contact" and value:
                updates[field] = Contact(**value)
            else:
                updates[field] = value

        updated_activity = activity_manager.update_activity(activity_id, **updates)
        return activity_to_response(updated_activity)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to update activity: {str(e)}"
        )


@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an activity"""
    activity = activity_manager.get_activity(activity_id)
    
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    # Check ownership
    if activity.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this activity"
        )

    success = activity_manager.delete_activity(activity_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete activity"
        )


@router.post("/{activity_id}/schedule", response_model=ActivityResponse)
async def schedule_activity(
    activity_id: str,
    schedule_data: ScheduleRequest,
    current_user: User = Depends(get_current_user)
):
    """Schedule an activity with specific timing"""
    activity = activity_manager.get_activity(activity_id)
    
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    # Check ownership
    if activity.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to schedule this activity"
        )

    try:
        updated_activity = activity_manager.schedule_activity(
            activity_id,
            schedule_data.start_date,
            schedule_data.end_date,
            schedule_data.duration_minutes
        )
        
        if not updated_activity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to schedule activity"
            )

        return activity_to_response(updated_activity)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to schedule activity: {str(e)}"
        )


@router.post("/conflicts/check", response_model=List[ActivityResponse])
async def check_schedule_conflicts(
    conflict_data: ConflictCheckRequest,
    current_user: User = Depends(get_current_user)
):
    """Check for scheduling conflicts"""
    try:
        conflicts = activity_manager.check_schedule_conflicts(
            conflict_data.start_date,
            conflict_data.end_date,
            conflict_data.trip_id,
            conflict_data.exclude_activity_id
        )

        # Filter to only user's activities
        user_conflicts = [
            conflict for conflict in conflicts
            if conflict.created_by == current_user.id
        ]

        return [activity_to_response(activity) for activity in user_conflicts]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check conflicts: {str(e)}"
        )


@router.get("/statistics/{trip_id}")
async def get_activity_statistics(
    trip_id: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """Get activity statistics"""
    try:
        # Get user's activities for the trip
        if trip_id:
            user_activities = [
                activity for activity in activity_manager.get_activities_by_trip(trip_id)
                if activity.created_by == current_user.id
            ]
        else:
            user_activities = activity_manager.get_activities_by_user(current_user.id)

        # Create temporary manager with user's activities
        temp_manager = ActivityManager()
        temp_manager.activities = {a.id: a for a in user_activities}
        
        stats = temp_manager.get_activity_statistics()
        return stats

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get statistics: {str(e)}"
        )


@router.get("/export/{trip_id}")
async def export_activities(
    trip_id: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """Export activities to JSON format"""
    try:
        # Get user's activities
        if trip_id:
            user_activities = [
                activity for activity in activity_manager.get_activities_by_trip(trip_id)
                if activity.created_by == current_user.id
            ]
        else:
            user_activities = activity_manager.get_activities_by_user(current_user.id)

        # Create temporary manager with user's activities
        temp_manager = ActivityManager()
        temp_manager.activities = {a.id: a for a in user_activities}
        
        export_data = temp_manager.export_activities(trip_id)
        return export_data

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to export activities: {str(e)}"
        )


@router.get("/types/list")
async def get_activity_types():
    """Get list of available activity types"""
    return {
        "activity_types": [
            {"value": activity_type.value, "label": activity_type.value.replace("_", " ").title()}
            for activity_type in ActivityType
        ]
    }


@router.get("/statuses/list")
async def get_activity_statuses():
    """Get list of available activity statuses"""
    return {
        "statuses": [
            {"value": status.value, "label": status.value.replace("_", " ").title()}
            for status in ActivityStatus
        ]
    }


@router.get("/priorities/list")
async def get_activity_priorities():
    """Get list of available activity priorities"""
    return {
        "priorities": [
            {"value": priority.value, "label": priority.value.replace("_", " ").title()}
            for priority in Priority
        ]
    }