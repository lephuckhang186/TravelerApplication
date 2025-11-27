"""
Planner models for the TravelPro backend API.
"""
from typing import Optional, List
from datetime import datetime, date
from pydantic import BaseModel, Field


class ActivityBase(BaseModel):
    """Base activity model with common fields."""
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    location: Optional[str] = Field(None, max_length=255)


class ActivityCreate(ActivityBase):
    """Activity creation model."""
    pass


class Activity(ActivityBase):
    """Complete activity model with database fields."""
    id: str
    planner_id: str

    class Config:
        """Pydantic configuration."""
        from_attributes = True


class PlannerBase(BaseModel):
    """Base planner model with common fields."""
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    start_date: date
    end_date: date


class PlannerCreate(PlannerBase):
    """Planner creation model."""
    pass


class PlannerUpdate(BaseModel):
    """Planner update model - all fields optional."""
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None


class Planner(PlannerBase):
    """Complete planner model with database fields."""
    id: str
    user_id: str
    activities: List[Activity] = []

    class Config:
        """Pydantic configuration."""
        from_attributes = True
