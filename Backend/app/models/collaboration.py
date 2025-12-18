"""
Collaboration models for the TravelPro backend API.
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class InvitationStatus(str, Enum):
    """Invitation status enum"""
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"


class CollaboratorRole(str, Enum):
    """Collaborator role enum"""
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"


class EditRequestStatus(str, Enum):
    """Edit request status enum"""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


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


class EditRequest(BaseModel):
    """Model for edit access requests"""
    id: Optional[str] = None
    trip_id: str
    requester_id: str
    requester_name: str
    requester_email: str
    status: EditRequestStatus = EditRequestStatus.PENDING
    requested_at: datetime = Field(default_factory=datetime.now)
    responded_at: Optional[datetime] = None
    responded_by: Optional[str] = None
    owner_id: str
    message: Optional[str] = None


class EditRequestCreate(BaseModel):
    """Request body for creating edit request"""
    trip_id: str
    message: Optional[str] = None


class EditRequestResponse(BaseModel):
    """Response model for edit request"""
    id: str
    trip_id: str
    requester_id: str
    requester_name: str
    requester_email: str
    status: EditRequestStatus
    requested_at: datetime
    responded_at: Optional[datetime] = None
    responded_by: Optional[str] = None
    message: Optional[str] = None
    trip_title: Optional[str] = None


class EditRequestUpdate(BaseModel):
    """Request body for updating edit request status"""
    status: EditRequestStatus
    promote_to_editor: bool = False  # If true, promote viewer to editor after approval


class ActivityEditRequestStatus(str, Enum):
    """Activity edit request status enum"""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ActivityEditRequest(BaseModel):
    """Model for activity edit requests"""
    id: Optional[str] = None
    trip_id: str
    request_type: str  # 'add_activity', 'edit_activity', 'delete_activity'
    requester_id: str
    requester_name: str
    requester_email: str
    owner_id: str
    activity_id: Optional[str] = None
    proposed_changes: Optional[dict] = None
    status: ActivityEditRequestStatus = ActivityEditRequestStatus.PENDING
    requested_at: datetime = Field(default_factory=datetime.now)
    responded_at: Optional[datetime] = None
    responded_by: Optional[str] = None
    message: Optional[str] = None
    activity_title: Optional[str] = None


class ActivityEditRequestCreate(BaseModel):
    """Request body for creating activity edit request"""
    trip_id: str
    request_type: str
    activity_id: Optional[str] = None
    proposed_changes: Optional[dict] = None
    message: Optional[str] = None
    activity_title: Optional[str] = None


class ActivityEditRequestResponse(BaseModel):
    """Response model for activity edit request"""
    id: str
    trip_id: str
    request_type: str
    requester_id: str
    requester_name: str
    requester_email: str
    owner_id: str
    activity_id: Optional[str] = None
    proposed_changes: Optional[dict] = None
    status: ActivityEditRequestStatus
    requested_at: datetime
    responded_at: Optional[datetime] = None
    responded_by: Optional[str] = None
    message: Optional[str] = None
    activity_title: Optional[str] = None
    trip_title: Optional[str] = None


class ActivityEditRequestUpdate(BaseModel):
    """Request body for updating activity edit request status"""
    status: ActivityEditRequestStatus
