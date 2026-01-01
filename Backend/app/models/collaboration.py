"""
Collaboration models for the TravelPro backend API.
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class InvitationStatus(str, Enum):
    """
    Status of an invitation to collaborate.

    Attributes:
        PENDING: Invitation has been sent but not responded to.
        ACCEPTED: User has accepted the invitation.
        REJECTED: User has declined the invitation.
    """
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"


class CollaboratorRole(str, Enum):
    """
    Role of a collaborator in a trip.

    Attributes:
        OWNER: The creator of the trip with full permissions.
        EDITOR: Can modify trip details.
        VIEWER: Can only view trip details.
    """
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"


class EditRequestStatus(str, Enum):
    """
    Status of a request to edit a trip.

    Attributes:
        PENDING: Request is awaiting approval.
        APPROVED: Request has been approved.
        REJECTED: Request has been denied.
    """
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class CollaboratorBase(BaseModel):
    """
    Base collaborator model with common fields.

    Attributes:
        user_id (str): ID of the user.
        planner_id (str): ID of the trip/planner.
    """
    user_id: str
    planner_id: str


class CollaboratorCreate(CollaboratorBase):
    """
    Collaborator creation model.
    Inherits all fields from CollaboratorBase.
    """
    pass


class Collaborator(CollaboratorBase):
    """
    Complete collaborator model with database fields.
    """
    class Config:
        """Pydantic configuration."""
        from_attributes = True


class EditRequest(BaseModel):
    """
    Model for edit access requests.

    Attributes:
        id (Optional[str]): Request ID.
        trip_id (str): Associated trip ID.
        requester_id (str): ID of the user requesting access.
        requester_name (str): Name of the requester.
        requester_email (str): Email of the requester.
        status (EditRequestStatus): Current status of request.
        requested_at (datetime): Timestamp of request.
        responded_at (Optional[datetime]): Timestamp of response.
        responded_by (Optional[str]): ID of the user who responded.
        owner_id (str): ID of the trip owner.
        message (Optional[str]): Optional message from requester.
    """
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
    """
    Request body for creating an edit request.

    Attributes:
        trip_id (str): ID of the trip to edit.
        message (Optional[str]): Reason for request.
    """
    trip_id: str
    message: Optional[str] = None


class EditRequestResponse(BaseModel):
    """
    Response model for an edit request.

    Attributes:
        id (str): Request ID.
        trip_id (str): Trip ID.
        requester_id (str): Requester's user ID.
        requester_name (str): Requester's name.
        requester_email (str): Requester's email.
        status (EditRequestStatus): Request status.
        requested_at (datetime): Request timestamp.
        responded_at (Optional[datetime]): Response timestamp.
        responded_by (Optional[str]): Responder ID.
        message (Optional[str]): Request message.
        trip_title (Optional[str]): Title of the trip.
    """
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
    """
    Request body for updating an edit request status.

    Attributes:
        status (EditRequestStatus): New status (APPROVED/REJECTED).
        promote_to_editor (bool): If true, promote requester to editor role upon approval.
    """
    status: EditRequestStatus
    promote_to_editor: bool = False  # If true, promote viewer to editor after approval


class ActivityEditRequestStatus(str, Enum):
    """
    Status of a request to edit an activity.

    Attributes:
        PENDING: Request is pending.
        APPROVED: Request approved.
        REJECTED: Request rejected.
    """
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ActivityEditRequest(BaseModel):
    """
    Model for activity edit requests.

    Attributes:
        id (Optional[str]): Request ID.
        trip_id (str): Trip ID.
        request_type (str): Type of edit ('add_activity', 'edit_activity', 'delete_activity').
        requester_id (str): Requester ID.
        requester_name (str): Requester name.
        requester_email (str): Requester email.
        owner_id (str): Trip owner ID.
        activity_id (Optional[str]): ID of activity being modified (if applicable).
        proposed_changes (Optional[dict]): Dictionary of proposed changes.
        status (ActivityEditRequestStatus): Request status.
        requested_at (datetime): Request timestamp.
        responded_at (Optional[datetime]): Response timestamp.
        responded_by (Optional[str]): Responder ID.
        message (Optional[str]): Message from requester.
        activity_title (Optional[str]): Title of activity.
    """
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
    """
    Request body for creating an activity edit request.

    Attributes:
        trip_id (str): Trip ID.
        request_type (str): Type of request (add/edit/delete).
        activity_id (Optional[str]): Target activity ID.
        proposed_changes (Optional[dict]): Changes proposed.
        message (Optional[str]): Optional message.
        activity_title (Optional[str]): Title of activity.
    """
    trip_id: str
    request_type: str
    activity_id: Optional[str] = None
    proposed_changes: Optional[dict] = None
    message: Optional[str] = None
    activity_title: Optional[str] = None


class ActivityEditRequestResponse(BaseModel):
    """
    Response model for an activity edit request.

    Attributes:
        id (str): Request ID.
        trip_id (str): Trip ID.
        request_type (str): Request type.
        requester_id (str): Requester ID.
        requester_name (str): Requester name.
        requester_email (str): Requester email.
        owner_id (str): Owner ID.
        activity_id (Optional[str]): Activity ID.
        proposed_changes (Optional[dict]): Proposed changes.
        status (ActivityEditRequestStatus): Current status.
        requested_at (datetime): Request timestamp.
        responded_at (Optional[datetime]): Response timestamp.
        responded_by (Optional[str]): Responder ID.
        message (Optional[str]): Message.
        activity_title (Optional[str]): Activity title.
        trip_title (Optional[str]): Trip title.
    """
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
    """
    Request body for updating an activity edit request status.

    Attributes:
        status (ActivityEditRequestStatus): New status.
    """
    status: ActivityEditRequestStatus
