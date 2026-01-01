"""
Planner models for the TravelPro backend API.
"""
from typing import Optional, List
from datetime import datetime, date
from pydantic import BaseModel, Field


class ActivityBase(BaseModel):
    """
    Base activity model with common fields.

    Attributes:
        name (str): Name of the activity.
        description (Optional[str]): Detailed description.
        start_time (datetime): Start timestamp.
        end_time (datetime): End timestamp.
        location (Optional[str]): Location name or address.
    """
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    location: Optional[str] = Field(None, max_length=255)


class ActivityCreate(ActivityBase):
    """
    Activity creation model.
    Inherits all fields from ActivityBase.
    """
    pass


class Activity(ActivityBase):
    """
    Complete activity model with database fields.

    Attributes:
        id (str): Unique activity ID.
        planner_id (str): ID of the parent planner/trip.
    """
    id: str
    planner_id: str

    class Config:
        """Pydantic configuration."""
        from_attributes = True


class PlannerBase(BaseModel):
    """
    Base planner model with common fields.

    Attributes:
        name (str): Name of the trip/plan.
        description (Optional[str]): Description of the trip.
        start_date (date): Start date of the trip.
        end_date (date): End date of the trip.
    """
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    start_date: date
    end_date: date


class PlannerCreate(PlannerBase):
    """
    Planner creation model.
    Inherits all fields from PlannerBase.
    """
    pass


class PlannerUpdate(BaseModel):
    """
    Planner update model - all fields optional.

    Attributes:
        name (Optional[str]): New name.
        description (Optional[str]): New description.
        start_date (Optional[date]): New start date.
        end_date (Optional[date]): New end date.
    """
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None


class Planner(PlannerBase):
    """
    Complete planner model with database fields.

    Attributes:
        id (str): Unique planner ID.
        user_id (str): ID of the user who owns this plan.
        activities (List[Activity]): List of associated activities.
    """
    id: str
    user_id: str
    activities: List[Activity] = []

    class Config:
        """Pydantic configuration."""
        from_attributes = True
