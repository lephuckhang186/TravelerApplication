"""
Activities Management API Endpoints with Integrated Expense Tracking
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Depends, Query
from fastapi import status
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, Field, validator

# Import dependencies and services
from app.core.dependencies import get_current_user
from app.services.activities_management import (
    Activity, ActivityType, ActivityStatus, Priority,
    Location, Budget, Contact, ActivityManager
)
from app.services.annalytics_service import (
    IntegratedTravelManager
)
from app.services.firebase_service import firebase_service
from app.models.user import User

# Create router - Remove prefix to avoid double prefixing
router = APIRouter(tags=["Activities & Expense Management"])

# Global integrated travel manager instance (lazy initialization to avoid import issues)
travel_manager = None

def get_travel_manager():
    """Get or create the global travel manager instance"""
    global travel_manager
    if travel_manager is None:
        travel_manager = IntegratedTravelManager()
    return travel_manager


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

async def _ensure_user_record(user: User) -> None:
    """Ensure the current user exists in Firestore."""
    try:
        print(f"👤 USER_SYNC: Checking user record for {user.id}")
        existing_user = await firebase_service.get_user_by_id(user.id)
        
        if not existing_user:
            print(f"👤 USER_CREATE: Creating new user record for {user.id}")
            # User will be auto-created via Firebase service
            user_data = {
                'uid': user.id,
                'email': user.email,
                'name': f"{user.first_name or ''} {user.last_name or ''}".strip(),
                'picture': user.profile_picture
            }
            await firebase_service.get_or_create_user(user_data)
    except Exception as exc:
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
    travel_mgr = get_travel_manager()
    if activity.id in travel_mgr.expense_manager._activity_expense_map:
        expense_info.has_expense = True
        expense_info.expense_id = travel_mgr.expense_manager._activity_expense_map[activity.id]
        expense_info.auto_synced = True
        # Get expense category
        category = travel_mgr.expense_manager._map_activity_type_to_expense_category(activity.activity_type)
        expense_info.expense_category = category.value
    elif activity.budget:
        # Handle budget as dict or object
        actual_cost = None
        if hasattr(activity.budget, 'actual_cost'):
            actual_cost = activity.budget.actual_cost
        elif isinstance(activity.budget, dict):
            actual_cost = activity.budget.get('actual_cost')
        
        if actual_cost:
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
        location=LocationResponse(**activity.location) if isinstance(activity.location, dict) and activity.location else (LocationResponse(**activity.location.__dict__) if activity.location and hasattr(activity.location, '__dict__') else None),
        budget=BudgetResponse(
            estimated_cost=float(activity.budget.estimated_cost),
            actual_cost=float(activity.budget.actual_cost) if activity.budget.actual_cost else None,
            currency=activity.budget.currency,
            category=activity.budget.category
        ) if activity.budget else None,
        contact=ContactResponse(**activity.contact) if isinstance(activity.contact, dict) and activity.contact else (ContactResponse(**activity.contact.__dict__) if activity.contact and hasattr(activity.contact, '__dict__') else None),
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
            
        if not activity_data.activity_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Activity type is required"
            )
        
        # Validate trip_id if provided - should not be mock data
        if activity_data.trip_id and "mock" in activity_data.trip_id.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Please use a valid trip ID. Mock/test trip IDs are not allowed."
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
        travel_mgr = get_travel_manager()
        activity = travel_mgr.create_activity_with_expense(
            title=activity_data.title,
            activity_type=activity_data.activity_type,
            created_by=current_user.id,
            estimated_cost=estimated_cost,
            actual_cost=actual_cost,
            **kwargs
        )

        return activity_to_response(activity)

    except ValueError as e:
        # Handle validation errors more specifically
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Validation error: {str(e)}"
        )
    except Exception as e:
        # Log the error for debugging
        print(f"Activity creation error: {str(e)}")
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
        travel_mgr = get_travel_manager()
        activities = travel_mgr.activity_manager.get_activities_by_user(current_user.id)

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
            status_code=500,
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
        from fastapi import Request
        import inspect
        
        # Get request info for debugging
        frame = inspect.currentframe()
        request_info = "Unknown"
        if frame and frame.f_back and 'request' in frame.f_back.f_locals:
            request = frame.f_back.f_locals.get('request')
            if hasattr(request, 'client'):
                request_info = f"{request.client.host}:{request.client.port}"
        
        print(f"🚀 TRIP_CREATE: User {current_user.id} creating trip '{trip_data.name}' from {request_info}")
        print(f"  Destination: {trip_data.destination}")
        print(f"  Dates: {trip_data.start_date} to {trip_data.end_date}")
        
        # Check for recent duplicate trips (within 5 seconds)
        import time
        current_time = time.time()
        if not hasattr(create_trip, '_recent_trips'):
            create_trip._recent_trips = {}
        
        trip_key = f"{current_user.id}_{trip_data.name}_{trip_data.destination}_{trip_data.start_date}_{trip_data.end_date}"
        if trip_key in create_trip._recent_trips:
            time_diff = current_time - create_trip._recent_trips[trip_key]
            if time_diff < 5:  # Within 5 seconds
                print(f"🚫 DUPLICATE_TRIP_BLOCKED: Identical trip created {time_diff:.2f}s ago, blocking duplicate")
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Duplicate trip creation blocked. Same trip created {time_diff:.2f}s ago."
                )
        
        create_trip._recent_trips[trip_key] = current_time
        
        # Cleanup old entries (older than 30 seconds)
        create_trip._recent_trips = {
            k: v for k, v in create_trip._recent_trips.items() 
            if current_time - v < 30
        }
        
        # Validate required fields
        if not trip_data.name or trip_data.name.strip() == "":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trip name is required"
            )
            
        if not trip_data.destination or trip_data.destination.strip() == "":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trip destination is required"
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trip destination is required"
            )
            
        if trip_data.start_date >= trip_data.end_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="End date must be after start date"
            )
        
        print(f"📝 TRIP_VALIDATION: All validations passed")
        
        # Ensure user record exists first
        _ensure_user_record(current_user)

        # Create trip data for storage
        trip_data_dict = {
            "name": trip_data.name.strip(),
            "destination": trip_data.destination.strip(),
            "description": trip_data.description,
            "start_date": trip_data.start_date.isoformat(),
            "end_date": trip_data.end_date.isoformat(),
            "total_budget": trip_data.total_budget,
            "currency": trip_data.currency,
        }
        
        # Store trip in Firestore
        print(f"💾 FIRESTORE_CREATE: Creating trip in Firestore")
        try:
            stored_trip = await firebase_service.create_trip(current_user.id, trip_data_dict)
            print(f"✅ TRIP_CREATED: Trip {stored_trip['id']} created successfully")
        except Exception as db_error:
            print(f"❌ DATABASE_ERROR: {db_error}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Database error creating trip: {str(db_error)}"
            )
        
        # Setup budget if provided
        if trip_data.total_budget:
            try:
                travel_mgr = get_travel_manager()
                travel_mgr.setup_trip_with_budget(
                    start_date=trip_data.start_date,
                    end_date=trip_data.end_date,
                    total_budget=Decimal(str(trip_data.total_budget))
                )
            except Exception as budget_error:
                # Don't fail trip creation if budget setup fails
                print(f"WARNING: Budget setup failed: {budget_error}")
        
        # Convert stored trip to response model
        try:
            return _trip_row_to_response(stored_trip)
        except Exception as response_error:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to format trip response: {str(response_error)}"
            )
        
    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
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

        # Get user's trips from Firestore
        stored_trips = await firebase_service.get_user_trips(current_user.id)
        
        # Convert to response models
        trips = []
        for stored_trip in stored_trips:
            try:
                trip_response = _trip_row_to_response(stored_trip)
                trips.append(trip_response)
            except Exception as trip_error:
                # Continue with other trips instead of failing completely
                continue
        
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
        await _ensure_user_record(current_user)

        stored_trip = await firebase_service.get_trip(trip_id, current_user.id)
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
    """Delete a trip with SQLite database cleanup (no more in-memory expense managers)"""
    try:
        _ensure_user_record(current_user)

        # Clean up activities from integrated travel manager (in-memory cleanup)
        travel_mgr = get_travel_manager()
        activities_to_delete = [
            activity_id for activity_id, activity in travel_mgr.activity_manager.activities.items()
            if getattr(activity, 'trip_id', None) == trip_id and activity.created_by == current_user.id
        ]
        
        deleted_activities_count = 0
        for activity_id in activities_to_delete:
            if travel_mgr.delete_activity_with_expense_sync(activity_id):
                deleted_activities_count += 1
        
        # Delete trip from Firestore (this will cascade delete all expenses and activities)
        success = await firebase_service.delete_trip(trip_id, current_user.id)
        
        # Also try to delete from JSON file storage (for mobile app compatibility)
        try:
            from app.services.trip_storage_service import trip_storage
            trip_storage.delete_trip(trip_id, current_user.id)
        except Exception as json_error:
            print(f"JSON storage cleanup warning: {json_error}")
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found or unauthorized"
            )
        
        # Additional cleanup logging (database already logged in db_manager.delete_trip)
        print(f"🧹 ACTIVITIES_CLEANUP: Cleaned up {deleted_activities_count} in-memory activities for trip {trip_id}")
        
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
    travel_mgr = get_travel_manager()
    activity = travel_mgr.activity_manager.get_activity(activity_id)
    
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
    """Update an existing activity with automatic expense sync on check-in"""
    travel_mgr = get_travel_manager()
    activity = travel_mgr.activity_manager.get_activity(activity_id)
    
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
        print(f"🔄 ACTIVITY_UPDATE: Updating activity {activity_id}")
        print(f"   User: {current_user.id}")
        print(f"   Updates: {activity_data.dict(exclude_unset=True)}")
        
        # Check if this is a check-in action
        is_checking_in = activity_data.check_in is True and not activity.check_in
        
        if is_checking_in:
            print(f"✅ CHECK_IN_DETECTED: Activity {activity_id} is being checked in")
            print(f"   Activity: {activity.name}")
            print(f"   Type: {activity.activity_type}")
            print(f"   Has budget: {activity.budget is not None}")
            if activity.budget:
                print(f"   Estimated cost: {activity.budget.estimated_cost}")
                print(f"   Actual cost: {activity.budget.actual_cost}")
        
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
        updated_activity = travel_mgr.update_activity_with_expense_sync(activity_id, **updates)
        
        if not updated_activity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to update activity"
            )
        
        # If checking in, create expense in Firebase
        if is_checking_in and updated_activity.trip_id:
            print(f"💰 AUTO_EXPENSE: Creating expense for checked-in activity")
            
            # Determine amount - use actual cost if available, otherwise estimated cost
            amount = 0.0
            if updated_activity.budget:
                if updated_activity.budget.actual_cost:
                    amount = float(updated_activity.budget.actual_cost)
                elif updated_activity.budget.estimated_cost:
                    amount = float(updated_activity.budget.estimated_cost)
            
            if amount > 0:
                expense_data = {
                    "name": f"{updated_activity.name} - Check-in",
                    "amount": amount,
                    "currency": updated_activity.budget.currency if updated_activity.budget else "VND",
                    "category": updated_activity.activity_type.value,
                    "date": datetime.now().isoformat()
                }
                
                try:
                    expense = await firebase_service.create_expense(updated_activity.trip_id, expense_data)
                    print(f"✅ EXPENSE_CREATED: {expense['id']} - {amount} {expense_data['currency']}")
                    print(f"   Linked to activity: {activity_id}")
                    print(f"   Trip: {updated_activity.trip_id}")
                except Exception as exp_error:
                    print(f"❌ EXPENSE_CREATE_ERROR: {exp_error}")
                    # Don't fail the activity update if expense creation fails
            else:
                print(f"⚠️ NO_EXPENSE_AMOUNT: Activity has no cost to create expense")
        
        return activity_to_response(updated_activity)

    except Exception as e:
        print(f"❌ ACTIVITY_UPDATE_ERROR: {e}")
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
    travel_mgr = get_travel_manager()
    activity = travel_mgr.activity_manager.get_activity(activity_id)
    
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
    success = travel_mgr.delete_activity_with_expense_sync(activity_id)
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
        travel_mgr = get_travel_manager()
        travel_mgr.setup_trip_with_budget(
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
        travel_mgr = get_travel_manager()
        if trip_id:
            user_activities = [
                activity for activity in travel_mgr.activity_manager.get_activities_by_user(current_user.id)
                if activity.trip_id == trip_id
            ]
        else:
            user_activities = travel_mgr.activity_manager.get_activities_by_user(current_user.id)
        
        # Create temporary manager with user's activities only
        temp_manager = IntegratedTravelManager()
        temp_manager.activity_manager.activities = {a.id: a for a in user_activities}
        
        # Copy expense mappings for user's activities
        for activity_id in temp_manager.activity_manager.activities.keys():
            if activity_id in travel_mgr.expense_manager._activity_expense_map:
                temp_manager.expense_manager._activity_expense_map[activity_id] = \
                    travel_mgr.expense_manager._activity_expense_map[activity_id]
        
        # Copy relevant expenses (expenses linked to user's activities)
        user_activity_ids = set(temp_manager.activity_manager.activities.keys())
        temp_manager.expense_manager.expenses = [
            expense for expense in travel_mgr.expense_manager.expenses
            if any(activity_id in user_activity_ids 
                   for activity_id in travel_mgr.expense_manager._activity_expense_map
                   if expense in travel_mgr.expense_manager._activity_expense_map.get(activity_id, []))
        ]
        
        # Copy budget info
        temp_manager.expense_manager.trip_budget = travel_mgr.expense_manager.trip_budget
        temp_manager.expense_manager.trip = travel_mgr.expense_manager.trip
        
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

# ============= DEBUG & DATA SYNCHRONIZATION ENDPOINTS =============

@router.get("/debug/user-status")
async def get_user_debug_status(current_user: User = Depends(get_current_user)):
    """DEPRECATED - Use Firebase only"""
    return {"message": "This endpoint is deprecated. All data is now in Firebase Firestore."}

@router.post("/debug/force-user-creation")
async def force_user_creation(
    current_user: User = Depends(get_current_user)
):
    """Force user creation in database for debugging"""
    try:
        print(f"🔧 FORCE_USER_CREATE: Creating user {current_user.id}")
        
        # Force user creation
        await _ensure_user_record(current_user)
        
        # Verify creation
        existing_user = await firebase_service.get_user_by_id(current_user.id)
        
        return {
            "message": "User creation forced",
            "user_id": current_user.id,
            "user_created": existing_user is not None,
            "user_record": existing_user,
            "debug_time": datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"❌ FORCE_CREATE_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to force user creation: {str(e)}"
        )

@router.post("/trips/quick-setup")
async def quick_trip_setup(
    current_user: User = Depends(get_current_user)
):
    """Quick setup: Create user and default trip for immediate use"""
    try:
        print(f"🚀 QUICK_SETUP: Setting up user {current_user.id}")
        
        # Step 1: Ensure user exists
        print(f"🔧 SETUP_STEP1: Ensuring user record exists...")
        await _ensure_user_record(current_user)
        print(f"✅ SETUP_STEP1: User record verified")
        
        # Step 2: Check if user already has trips
        print(f"🔧 SETUP_STEP2: Checking existing trips...")
        existing_trips = await firebase_service.get_user_trips(current_user.id)
        print(f"📊 SETUP_STEP2: Found {len(existing_trips)} existing trips")
        
        if existing_trips:
            return {
                "message": "User already has trips",
                "user_id": current_user.id,
                "existing_trip_count": len(existing_trips),
                "recent_trip": existing_trips[0] if existing_trips else None
            }
        
        # Step 3: Create default trip
        print(f"🔧 SETUP_STEP3: Creating default trip...")
        from datetime import date, timedelta
        today = date.today()
        default_trip_data = {
            "name": "My Travel Plan",
            "destination": "Travel Destination",
            "description": "Default trip for expense tracking",
            "start_date": today.isoformat(),
            "end_date": (today + timedelta(days=7)).isoformat(),
            "total_budget": 5000000,  # 5 million VND default
            "currency": "VND"
        }
        
        print(f"📋 SETUP_STEP3: Trip data prepared: {default_trip_data}")
        created_trip = await firebase_service.create_trip(current_user.id, default_trip_data)
        print(f"✅ SETUP_STEP3: Trip created successfully: {created_trip['id']}")
        
        return {
            "message": "Quick setup completed successfully",
            "user_id": current_user.id,
            "trip_created": True,
            "trip_id": created_trip["id"],
            "trip_name": created_trip["name"],
            "trip_budget": created_trip["total_budget"],
            "ready_for_expenses": True
        }
        
    except Exception as e:
        print(f"❌ QUICK_SETUP_ERROR: {e}")
        print(f"❌ ERROR_TYPE: {type(e).__name__}")
        import traceback
        print(f"❌ FULL_TRACEBACK: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Quick setup failed: {str(e)}"
        )

@router.post("/trips/test-creation")
async def test_trip_creation(current_user: User = Depends(get_current_user)):
    """DEPRECATED"""
    return {"message": "DEPRECATED - Use POST /activities/trips instead"}

@router.post("/sync/cleanup-orphaned-data")
async def cleanup_orphaned_data(current_user: User = Depends(get_current_user)):
    """DEPRECATED"""
    return {"message": "DEPRECATED - Firestore handles data integrity automatically"}

@router.post("/sync/force-sync-storage")
async def force_sync_storage_systems(current_user: User = Depends(get_current_user)):
    """DEPRECATED"""
    return {"message": "DEPRECATED - Using Firebase Firestore only"}

@router.get("/debug/storage-status")
async def get_storage_status(current_user: User = Depends(get_current_user)):
    """Get Firebase storage status"""
    trips = await firebase_service.get_user_trips(current_user.id)
    return {"storage": "Firebase Firestore", "trip_count": len(trips), "status": "active"}



