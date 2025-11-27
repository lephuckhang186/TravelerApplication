"""
Activities Management API Endpoints with Integrated Expense Tracking
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Depends, Query, status
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, Field, validator

# Import dependencies and services
try:
    from ...core.dependencies import get_current_user
    from ...services.activities_management import (
        Activity, ActivityType, ActivityStatus, Priority,
        Location, Budget, Contact
    )
    from ...services.annalytics_service import (
        IntegratedTravelManager
    )
    from ...models.user import User
    from ...database import db_manager
except ImportError:
    # Fallback for direct execution
    import sys
    import os
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    from core.dependencies import get_current_user
    
    from services.activities_management import (
        Activity, ActivityType, ActivityStatus, Priority,
        Location, Budget, Contact, ActivityManager
    )
    from services.annalytics_service import (
        IntegratedTravelManager
    )
    from database import db_manager
    from models.user import User

# Create router
router = APIRouter(prefix="/activities", tags=["Activities & Expense Management"])

# Global integrated travel manager instance (in production, use database)
travel_manager = IntegratedTravelManager()


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
    check_in: bool = False

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
    """Activity update model with all optional fields for flexibility"""
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
    check_in: Optional[bool] = None

    @validator('tags')
    def validate_tags(cls, v):
        """Validate tags if provided"""
        if v:
            for tag in v:
                if not isinstance(tag, str) or len(tag) > 50:
                    raise ValueError("Each tag must be a string with max length 50")
        return v

    @validator('end_date')
    def validate_dates(cls, v, values):
        """Validate that end_date is after start_date if both provided"""
        if v and values.get('start_date') and v <= values['start_date']:
            raise ValueError("End date must be after start date")
        return v


class ExpenseInfo(BaseModel):
    """Expense information for activity"""
    expense_id: Optional[str] = None
    has_expense: bool = False
    expense_category: Optional[str] = None
    auto_synced: bool = False

class ActivityResponse(BaseModel):
    """Activity response model with expense integration"""
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
    check_in: bool
    expense_info: ExpenseInfo


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

class TripCreate(BaseModel):
    """Trip creation model"""
    name: str = Field(..., min_length=1, max_length=200)
    destination: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    start_date: date
    end_date: date
    total_budget: Optional[float] = Field(None, gt=0)
    currency: str = Field(default="VND", max_length=3)

class TripResponse(BaseModel):
    """Trip response model"""
    id: str
    name: str
    destination: str
    description: Optional[str]
    start_date: date
    end_date: date
    total_budget: Optional[float]
    currency: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    created_by: str


# ============= HELPER UTILITIES =============

def _ensure_user_record(user: User) -> None:
    """Ensure the current user exists inside the local SQLite store."""
    try:
        if not db_manager.get_user(user.id):
            full_name = f"{user.first_name or ''} {user.last_name or ''}".strip()
            display_name = full_name or user.username or user.email.split("@")[0]
            db_manager.create_user(
                user_id=user.id,
                email=user.email,
                display_name=display_name,
                photo_url=user.profile_picture
            )
    except Exception as exc:
        # Surface a clearer error if we cannot sync user data
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to sync user profile: {exc}"
        ) from exc


def _trip_row_to_response(trip_row: Dict[str, Any]) -> TripResponse:
    """Convert a raw SQLite trip row into API response model."""
    return TripResponse(
        id=trip_row["id"],
        name=trip_row["name"],
        destination=trip_row["destination"],
        description=trip_row.get("description"),
        start_date=date.fromisoformat(trip_row["start_date"]),
        end_date=date.fromisoformat(trip_row["end_date"]),
        total_budget=trip_row.get("total_budget"),
        currency=trip_row.get("currency", "VND"),
        is_active=bool(trip_row.get("is_active", True)),
        created_at=datetime.fromisoformat(trip_row["created_at"]),
        updated_at=datetime.fromisoformat(trip_row["updated_at"]),
        created_by=trip_row["user_id"]
    )

class TripBudgetSetup(BaseModel):
    """Trip budget setup request"""
    trip_id: Optional[str] = None
    start_date: date
    end_date: date
    total_budget: float = Field(..., gt=0)
    currency: str = Field(default="VND", max_length=3)
    category_allocations: Optional[Dict[str, float]] = None

class ActivityCostUpdate(BaseModel):
    """Update activity actual cost"""
    actual_cost: float = Field(..., ge=0)
    currency: str = Field(default="VND", max_length=3)

class ExpenseSummaryResponse(BaseModel):
    """Expense summary response"""
    total_activities: int
    synced_activities: int
    unsynced_activities: int
    total_estimated_cost: float
    total_actual_cost: float
    budget_variance: float
    budget_status: Optional[Dict[str, Any]] = None
    category_status: Optional[Dict[str, Any]] = None

class ActivityExpenseDetail(BaseModel):
    """Activity expense detail"""
    activity_id: str
    title: str
    type: str
    status: str
    estimated_cost: Optional[float]
    actual_cost: Optional[float]
    has_expense: bool
    expense_category: Optional[str]


# ============= HELPER FUNCTIONS =============

def activity_to_response(activity: Activity) -> ActivityResponse:
    """Convert Activity to ActivityResponse with expense info"""
    # Get expense info
    expense_info = ExpenseInfo()
    if activity.id in travel_manager.expense_manager._activity_expense_map:
        expense_info.has_expense = True
        expense_info.expense_id = travel_manager.expense_manager._activity_expense_map[activity.id]
        expense_info.auto_synced = True
        # Get expense category
        category = travel_manager.expense_manager._map_activity_type_to_expense_category(activity.activity_type)
        expense_info.expense_category = category.value
    elif activity.budget and activity.budget.actual_cost:
        expense_info.has_expense = False
        expense_info.auto_synced = False
    
    return ActivityResponse(
        id=activity.id,
        title=activity.name,
        description=activity.details,
        activity_type=activity.activity_type,
        status=activity.status,
        priority=activity.priority,
        start_date=activity.start_time,
        end_date=activity.end_time,
        duration_minutes=None,
        location=LocationResponse(**activity.location.__dict__) if activity.location else None,
        budget=BudgetResponse(
            estimated_cost=float(activity.budget.estimated_cost),
            actual_cost=float(activity.budget.actual_cost) if activity.budget.actual_cost else None,
            currency=activity.budget.currency,
            category=activity.budget.category
        ) if activity.budget else None,
        contact=ContactResponse(**activity.contact.__dict__) if activity.contact else None,
        notes=activity.notes,
        tags=activity.tags or [],
        attachments=[],
        created_by=activity.created_by,
        created_at=activity.created_at,
        updated_at=activity.updated_at,
        trip_id=activity.trip_id,
        check_in=activity.check_in,
        expense_info=expense_info
    )


# ============= API ENDPOINTS =============

@router.post("/", response_model=ActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    activity_data: ActivityCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new activity with automatic expense tracking"""
    try:
        # Validate required fields
        if not activity_data.title or activity_data.title.strip() == "":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Activity title is required"
            )
        # Extract budget info
        estimated_cost = None
        actual_cost = None
        currency = "VND"
        
        if activity_data.budget:
            estimated_cost = Decimal(str(activity_data.budget.estimated_cost))
            if activity_data.budget.actual_cost is not None:
                actual_cost = Decimal(str(activity_data.budget.actual_cost))
            currency = activity_data.budget.currency

        # Prepare additional kwargs
        kwargs = {
            'details': activity_data.description,
            'status': activity_data.status,
            'priority': activity_data.priority,
            'start_time': activity_data.start_date,
            'end_time': activity_data.end_date,
            'trip_id': activity_data.trip_id,
            'notes': activity_data.notes,
            'tags': activity_data.tags,
            'currency': currency,
            'check_in': activity_data.check_in,
            'expected_cost': estimated_cost,
            'real_cost': actual_cost
        }

        # Add location if provided
        if activity_data.location:
            kwargs['location'] = activity_data.location.dict()
            
        # Add contact if provided
        if activity_data.contact:
            kwargs['contact'] = activity_data.contact.dict()

        # Use integrated manager to create activity with automatic expense sync
        activity = travel_manager.create_activity_with_expense(
            title=activity_data.title,
            activity_type=activity_data.activity_type,
            created_by=current_user.id,
            estimated_cost=estimated_cost,
            actual_cost=actual_cost,
            **kwargs
        )

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
    """Get activities with expense tracking information"""
    try:
        # Start with all user's activities
        activities = travel_manager.activity_manager.get_activities_by_user(current_user.id)

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


# ============= TRIP MANAGEMENT ENDPOINTS =============


@router.post("/trips", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
async def create_trip(
    trip_data: TripCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new trip with real data storage"""
    try:
        _ensure_user_record(current_user)

        # Create trip data for storage
        trip_data_dict = {
            "name": trip_data.name,
            "destination": trip_data.destination,
            "description": trip_data.description,
            "start_date": trip_data.start_date.isoformat(),
            "end_date": trip_data.end_date.isoformat(),
            "total_budget": trip_data.total_budget,
            "currency": trip_data.currency,
        }
        
        # Store trip in database
        stored_trip = db_manager.create_trip(current_user.id, trip_data_dict)
        
        # Setup budget if provided
        if trip_data.total_budget:
            travel_manager.setup_trip_with_budget(
                start_date=trip_data.start_date,
                end_date=trip_data.end_date,
                total_budget=Decimal(str(trip_data.total_budget))
            )
        
        # Convert stored trip to response model
        return _trip_row_to_response(stored_trip)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create trip: {str(e)}"
        )



@router.get("/trips", response_model=List[TripResponse])
async def get_trips(
    current_user: User = Depends(get_current_user)
):
    """Get all trips for the current user"""
    try:
        _ensure_user_record(current_user)

        # Get user's trips from database
        stored_trips = db_manager.get_user_trips(current_user.id)
        
        # Convert to response models
        trips = [_trip_row_to_response(stored_trip) for stored_trip in stored_trips]
        return trips
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get trips: {str(e)}"
        )


@router.get("/trips/{trip_id}", response_model=TripResponse)
async def get_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific trip by ID"""
    try:
        _ensure_user_record(current_user)

        stored_trip = db_manager.get_trip(trip_id, current_user.id)
        if stored_trip:
            return _trip_row_to_response(stored_trip)

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get trip: {str(e)}"
        )



@router.delete("/trips/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a trip"""
    try:
        _ensure_user_record(current_user)

        # Delete trip from database
        success = db_manager.delete_trip(trip_id, current_user.id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found or unauthorized"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete trip: {str(e)}"
        )

@router.get("/{activity_id}", response_model=ActivityResponse)
async def get_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get activity by ID with expense information"""
    activity = travel_manager.activity_manager.get_activity(activity_id)
    
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
    """Update an existing activity with automatic expense sync"""
    activity = travel_manager.activity_manager.get_activity(activity_id)
    
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
                # Convert to Decimal and prepare budget dict
                budget_dict = value
                budget_dict['estimated_cost'] = Decimal(str(budget_dict['estimated_cost']))
                if budget_dict['actual_cost'] is not None:
                    budget_dict['actual_cost'] = Decimal(str(budget_dict['actual_cost']))
                updates[field] = budget_dict
            elif field == "location" and value:
                updates[field] = value
            elif field == "contact" and value:
                updates[field] = value
            else:
                updates[field] = value

        # Use integrated manager for automatic expense sync
        updated_activity = travel_manager.update_activity_with_expense_sync(activity_id, **updates)
        
        if not updated_activity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to update activity"
            )
            
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
    """Delete an activity with automatic expense removal"""
    activity = travel_manager.activity_manager.get_activity(activity_id)
    
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

    # Use integrated manager for automatic expense removal
    success = travel_manager.delete_activity_with_expense_sync(activity_id)
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
    activity = travel_manager.activity_manager.get_activity(activity_id)
    
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
        updated_activity = travel_manager.activity_manager.schedule_activity(
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


@router.post("/{activity_id}/cost", response_model=ActivityResponse)
async def update_activity_cost(
    activity_id: str,
    cost_data: ActivityCostUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update activity actual cost with automatic expense sync"""
    activity = travel_manager.activity_manager.get_activity(activity_id)
    
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
        # Use integrated manager to set actual cost and auto-sync expense
        success = travel_manager.set_activity_actual_cost(
            activity_id,
            Decimal(str(cost_data.actual_cost)),
            cost_data.currency
        )
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to update activity cost"
            )
        
        # Get updated activity
        updated_activity = travel_manager.activity_manager.get_activity(activity_id)
        return activity_to_response(updated_activity)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to update activity cost: {str(e)}"
        )


@router.post("/trip/budget/setup", status_code=status.HTTP_201_CREATED)
async def setup_trip_budget(
    budget_data: TripBudgetSetup,
    current_user: User = Depends(get_current_user)
):
    """Setup trip budget for expense tracking"""
    try:
        # Convert category allocations if provided
        category_allocations = None
        if budget_data.category_allocations:
            category_allocations = {}
            for category_str, amount in budget_data.category_allocations.items():
                try:
                    category = ActivityType(category_str.lower())
                    category_allocations[category] = Decimal(str(amount))
                except ValueError:
                    # Skip invalid categories
                    continue
        
        # Setup trip and budget
        travel_manager.setup_trip_with_budget(
            start_date=budget_data.start_date,
            end_date=budget_data.end_date,
            total_budget=Decimal(str(budget_data.total_budget)),
            category_allocations=category_allocations
        )
        
        return {
            "message": "Trip budget setup successfully",
            "trip_period": f"{budget_data.start_date} to {budget_data.end_date}",
            "total_budget": budget_data.total_budget,
            "currency": budget_data.currency
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to setup trip budget: {str(e)}"
        )


@router.get("/expenses/summary", response_model=ExpenseSummaryResponse)
async def get_expense_summary(
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive activity-expense summary"""
    try:
        # Filter activities by user
        if trip_id:
            user_activities = [
                activity for activity in travel_manager.activity_manager.get_activities_by_trip(trip_id)
                if activity.created_by == current_user.id
            ]
        else:
            user_activities = travel_manager.activity_manager.get_activities_by_user(current_user.id)
        
        # Create temporary manager with user's activities only
        temp_manager = IntegratedTravelManager()
        temp_manager.activity_manager.activities = {a.id: a for a in user_activities}
        
        # Copy expense mappings for user's activities
        for activity_id in temp_manager.activity_manager.activities.keys():
            if activity_id in travel_manager.expense_manager._activity_expense_map:
                temp_manager.expense_manager._activity_expense_map[activity_id] = \
                    travel_manager.expense_manager._activity_expense_map[activity_id]
        
        # Copy relevant expenses (expenses linked to user's activities)
        user_activity_ids = set(temp_manager.activity_manager.activities.keys())
        temp_manager.expense_manager.expenses = [
            expense for expense in travel_manager.expense_manager.expenses
            if any(activity_id in user_activity_ids 
                   for activity_id in travel_manager.expense_manager._activity_expense_map
                   if expense in travel_manager.expense_manager._activity_expense_map.get(activity_id, []))
        ]
        
        # Copy budget info
        temp_manager.expense_manager.trip_budget = travel_manager.expense_manager.trip_budget
        temp_manager.expense_manager.trip = travel_manager.expense_manager.trip
        
        summary = temp_manager.get_activity_expense_summary(trip_id)
        
        return ExpenseSummaryResponse(**summary['summary'])

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get expense summary: {str(e)}"
        )


@router.post("/expenses/sync", status_code=status.HTTP_200_OK)
async def sync_activities_with_expenses(
    trip_id: Optional[str] = Query(None, description="Sync specific trip or all activities"),
    current_user: User = Depends(get_current_user)
):
    """Force sync all activities with expenses"""
    try:
        # Get user's activities
        if trip_id:
            user_activities = [
                activity for activity in travel_manager.activity_manager.get_activities_by_trip(trip_id)
                if activity.created_by == current_user.id
            ]
        else:
            user_activities = travel_manager.activity_manager.get_activities_by_user(current_user.id)
        
        synced_count = 0
        for activity in user_activities:
            if activity.budget and activity.budget.actual_cost:
                expense_id = travel_manager.expense_manager.sync_activity_to_expense(activity)
                if expense_id:
                    synced_count += 1
        
        return {
            "message": f"Successfully synced {synced_count} activities with expenses",
            "total_activities": len(user_activities),
            "synced_activities": synced_count
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to sync activities with expenses: {str(e)}"
        )


@router.post("/conflicts/check", response_model=List[ActivityResponse])
async def check_schedule_conflicts(
    conflict_data: ConflictCheckRequest,
    current_user: User = Depends(get_current_user)
):
    """Check for scheduling conflicts"""
    try:
        conflicts = travel_manager.activity_manager.check_schedule_conflicts(
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
    """Get activity statistics with expense information"""
    try:
        # Get user's activities for the trip
        if trip_id:
            user_activities = [
                activity for activity in travel_manager.activity_manager.get_activities_by_trip(trip_id)
                if activity.created_by == current_user.id
            ]
        else:
            user_activities = travel_manager.activity_manager.get_activities_by_user(current_user.id)

        # Create temporary manager with user's activities
        from services.activities_management import ActivityManager
        temp_manager = ActivityManager()
        temp_manager.activities = {a.id: a for a in user_activities}
        
        # Get basic stats
        stats = temp_manager.get_activity_statistics()
        
        # Add expense information
        total_estimated_cost = sum(
            float(a.budget.estimated_cost) for a in user_activities 
            if a.budget and a.budget.estimated_cost
        )
        total_actual_cost = sum(
            float(a.budget.actual_cost) for a in user_activities 
            if a.budget and a.budget.actual_cost
        )
        synced_activities = len([
            a for a in user_activities 
            if a.id in travel_manager.expense_manager._activity_expense_map
        ])
        
        stats.update({
            'expense_info': {
                'total_estimated_cost': total_estimated_cost,
                'total_actual_cost': total_actual_cost,
                'budget_variance': total_actual_cost - total_estimated_cost,
                'synced_activities': synced_activities,
                'total_activities': len(user_activities)
            }
        })
        
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
    """Export activities with expense information to JSON format"""
    try:
        # Get user's activities
        if trip_id:
            user_activities = [
                activity for activity in travel_manager.activity_manager.get_activities_by_trip(trip_id)
                if activity.created_by == current_user.id
            ]
        else:
            user_activities = travel_manager.activity_manager.get_activities_by_user(current_user.id)

        # Create temporary manager with user's activities
        from services.activities_management import ActivityManager
        temp_manager = ActivityManager()
        temp_manager.activities = {a.id: a for a in user_activities}
        
        # Get basic export data
        export_data = temp_manager.export_activities(trip_id)
        
        # Add expense information
        expense_summary = travel_manager.get_activity_expense_summary(trip_id)
        export_data['expense_summary'] = expense_summary['summary']
        export_data['expense_details'] = expense_summary['activities']
        
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
