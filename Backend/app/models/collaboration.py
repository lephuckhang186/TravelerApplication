"""
Collaboration models for the TravelPro backend API.
"""
from pydantic import BaseModel


class CollaboratorBase(BaseModel):
    """Base collaborator model with common fields."""
    user_id: str
    planner_id: str


class CollaboratorCreate(CollaboratorBase):
    """Collaborator creation model."""
    pass


class Collaborator(CollaboratorBase):
    """Complete collaborator model with database fields."""
    class Config:
        """Pydantic configuration."""
        from_attributes = True
