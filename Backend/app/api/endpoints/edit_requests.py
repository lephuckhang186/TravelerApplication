"""
Edit Request API endpoints for role-based access control.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime

try:
    from ...core.dependencies import get_current_user
    from ...models.user import User
    from ...models.collaboration import (
        EditRequest,
        EditRequestCreate,
        EditRequestResponse,
        EditRequestUpdate,
        EditRequestStatus,
        CollaboratorRole
    )
    from ...services.firebase_service import firebase_service
except ImportError:
    # Fallback for direct execution
    import sys
    import os
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    from core.dependencies import get_current_user
    from models.user import User
    from models.collaboration import (
        EditRequest,
        EditRequestCreate,
        EditRequestResponse,
        EditRequestUpdate,
        EditRequestStatus,
        CollaboratorRole
    )
    from services.firebase_service import firebase_service

router = APIRouter(prefix="/edit-requests", tags=["edit-requests"])


@router.post("/", response_model=EditRequestResponse)
async def create_edit_request(
    request_data: EditRequestCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Create a new edit access request (Viewer requests to become Editor).

    Allows a user with Viewer role to request Editor privileges from the Trip Owner.

    Args:
        request_data (EditRequestCreate): The data for creation (trip ID and message).
        current_user (User): The current authenticated user making the request.

    Returns:
        EditRequestResponse: The created edit request details.

    Raises:
        HTTPException(404): If the trip is not found.
        HTTPException(400): If the trip has no owner, user already has editor rights, or request is pending.
        HTTPException(403): If the user is not a collaborator on the trip.
        HTTPException(500): If the request creation fails.
    """
    try:
        trip_id = request_data.trip_id
        
        # 1. Verify trip exists (try without user_id first to get trip data)
        trip = await firebase_service.get_trip(trip_id)
        if not trip:
            # Try with current user's ID
            trip = await firebase_service.get_trip(trip_id, current_user.id)
            if not trip:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Trip {trip_id} not found"
                )
        
        owner_id = trip.get('user_id') or trip.get('userId') or trip.get('ownerId') or trip.get('owner_id')
        if not owner_id:
            print(f"❌ TRIP_OWNER_ERROR: Trip data: {trip}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trip has no owner"
            )
        
        # 2. Check if user is collaborator
        # For shared trips, collaborators are in 'sharedCollaborators' field
        shared_collaborators = trip.get('sharedCollaborators', [])
        
        # Try to find user in shared collaborators first
        user_collab = None
        if shared_collaborators:
            user_collab = next((c for c in shared_collaborators if c.get('userId') == current_user.id or c.get('user_id') == current_user.id), None)
        
        # If not found, try the collaborators collection (for backward compatibility)
        if not user_collab:
            collaborators = await firebase_service.get_planner_collaborators(trip_id)
            user_collab = next((c for c in collaborators if c.get('user_id') == current_user.id), None)
        
        if not user_collab:
            print(f"❌ USER_NOT_COLLABORATOR: User {current_user.id} not found in collaborators")
            print(f"   Shared collaborators: {shared_collaborators}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not a collaborator on this trip"
            )
        
        # 3. Check if user is already editor or owner
        user_role = user_collab.get('role', 'viewer')
        if user_role in ['owner', 'editor']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"You already have {user_role} access"
            )
        
        # 4. Check if there's already a pending request
        existing_request = await firebase_service.check_pending_edit_request(trip_id, current_user.id)
        if existing_request:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You already have a pending edit request for this trip"
            )
        
        # 5. Create edit request
        edit_request = await firebase_service.create_edit_request(
            trip_id=trip_id,
            requester_id=current_user.id,
            requester_name=f"{current_user.first_name} {current_user.last_name}".strip() or current_user.username,
            requester_email=current_user.email,
            owner_id=owner_id,
            message=request_data.message
        )
        
        # Add trip title to response
        edit_request['trip_title'] = trip.get('name') or trip.get('title')
        
        return EditRequestResponse(**edit_request)
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ CREATE_EDIT_REQUEST_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create edit request: {str(e)}"
        )


@router.get("/my-requests", response_model=List[EditRequestResponse])
async def get_my_edit_requests(
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get all edit requests created by current user.

    Args:
        status_filter (Optional[str]): Filter requests by status (pending, approved, rejected).
        current_user (User): The current authenticated user.

    Returns:
        List[EditRequestResponse]: A list of edit requests.

    Raises:
        HTTPException(500): If retrieving requests fails.
    """
    try:
        requests = await firebase_service.get_user_edit_requests(
            current_user.id,
            status=status_filter
        )
        
        # Enrich with trip titles
        result = []
        for req in requests:
            trip = await firebase_service.get_trip(req['trip_id'])
            if not trip:
                trip = await firebase_service.get_trip(req['trip_id'], current_user.id)
            req['trip_title'] = trip.get('name') or trip.get('title') if trip else None
            result.append(EditRequestResponse(**req))
        
        return result
        
    except Exception as e:
        print(f"❌ GET_MY_EDIT_REQUESTS_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get edit requests: {str(e)}"
        )


@router.get("/pending-approvals", response_model=List[EditRequestResponse])
async def get_pending_approvals(
    current_user: User = Depends(get_current_user)
):
    """
    Get all pending edit requests for trips owned by current user.

    Args:
        current_user (User): The current authenticated user (acting as owner).

    Returns:
        List[EditRequestResponse]: A list of pending requests requiring approval.

    Raises:
        HTTPException(500): If retrieving approvals fails.
    """
    try:
        requests = await firebase_service.get_owner_edit_requests(
            current_user.id,
            status='pending'
        )
        
        # Enrich with trip titles
        result = []
        for req in requests:
            trip = await firebase_service.get_trip(req['trip_id'])
            if not trip:
                trip = await firebase_service.get_trip(req['trip_id'], req['owner_id'])
            req['trip_title'] = trip.get('name') or trip.get('title') if trip else None
            result.append(EditRequestResponse(**req))
        
        return result
        
    except Exception as e:
        print(f"❌ GET_PENDING_APPROVALS_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get pending approvals: {str(e)}"
        )


@router.get("/trip/{trip_id}", response_model=List[EditRequestResponse])
async def get_trip_edit_requests(
    trip_id: str,
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get all edit requests for a specific trip (owner only).

    Args:
        trip_id (str): The ID of the trip.
        status_filter (Optional[str]): optional status filter.
        current_user (User): The current authenticated user.

    Returns:
        List[EditRequestResponse]: List of associated edit requests.

    Raises:
        HTTPException(404): If trip is not found.
        HTTPException(403): If user is not the owner.
        HTTPException(500): If retrieval fails.
    """
    try:
        # Verify user is trip owner
        trip = await firebase_service.get_trip(trip_id)
        if not trip:
            # Try with current user's ID
            trip = await firebase_service.get_trip(trip_id, current_user.id)
            if not trip:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Trip {trip_id} not found"
                )
        
        owner_id = trip.get('user_id') or trip.get('userId') or trip.get('ownerId') or trip.get('owner_id')
        if owner_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only trip owner can view edit requests"
            )
        
        requests = await firebase_service.get_trip_edit_requests(
            trip_id,
            status=status_filter
        )
        
        trip_title = trip.get('name') or trip.get('title')
        result = []
        for req in requests:
            req['trip_title'] = trip_title
            result.append(EditRequestResponse(**req))
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ GET_TRIP_EDIT_REQUESTS_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get trip edit requests: {str(e)}"
        )


@router.put("/{request_id}", response_model=EditRequestResponse)
async def update_edit_request(
    request_id: str,
    update_data: EditRequestUpdate,
    current_user: User = Depends(get_current_user)
):
    """
    Approve or reject an edit request (owner only).

    If approved and `promote_to_editor` is true, the user's role on the trip is updated to EDITOR.

    Args:
        request_id (str): The ID of the edit request.
        update_data (EditRequestUpdate): The update payload (status, promote_to_editor).
        current_user (User): The current authenticated user.

    Returns:
        EditRequestResponse: The updated edit request.

    Raises:
        HTTPException(404): Request or Trip not found.
        HTTPException(403): User is not the owner.
        HTTPException(400): Request is not pending.
        HTTPException(500): Update operation fails.
    """
    try:
        # 1. Get the request
        edit_request = await firebase_service.get_edit_request(request_id)
        if not edit_request:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Edit request {request_id} not found"
            )
        
        # 2. Verify user is trip owner
        trip_id = edit_request['trip_id']
        trip = await firebase_service.get_trip(trip_id)
        if not trip:
            # Try with current user's ID
            trip = await firebase_service.get_trip(trip_id, current_user.id)
            if not trip:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Trip {trip_id} not found"
                )
        
        owner_id = trip.get('user_id') or trip.get('userId') or trip.get('ownerId') or trip.get('owner_id')
        if owner_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only trip owner can respond to edit requests"
            )
        
        # 3. Check if request is still pending
        if edit_request['status'] != 'pending':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Request is already {edit_request['status']}"
            )
        
        # 4. Update request status
        updated_request = await firebase_service.update_edit_request(
            request_id,
            update_data.status.value,
            current_user.id
        )
        
        # 5. If approved and promote_to_editor is True, update collaborator role
        if update_data.status == EditRequestStatus.APPROVED and update_data.promote_to_editor:
            requester_id = edit_request['requester_id']
            
            # Check if this is a shared trip
            shared_collaborators = trip.get('sharedCollaborators', [])
            if shared_collaborators:
                # Update role in sharedCollaborators field
                updated_collaborators = []
                for collab in shared_collaborators:
                    if collab.get('userId') == requester_id or collab.get('user_id') == requester_id:
                        collab['role'] = CollaboratorRole.EDITOR.value
                        print(f"✅ Updating role for {collab.get('name', 'user')} to editor")
                    updated_collaborators.append(collab)
                
                # Update the trip document
                firebase_service.db.collection('shared_trips').document(trip_id).update({
                    'sharedCollaborators': updated_collaborators,
                    'updatedAt': datetime.utcnow().isoformat()
                })
                print(f"✅ Updated sharedCollaborators in shared_trips collection")
                
                # Also update user's shared trips reference
                firebase_service.db.collection('users').document(requester_id).collection('user_shared_trips').document(trip_id).update({
                    'role': CollaboratorRole.EDITOR.value
                })
                print(f"✅ Updated user_shared_trips reference for user {requester_id}")
            else:
                # Fallback to old method for non-shared trips
                await firebase_service.update_collaborator_role(
                    trip_id,
                    requester_id,
                    CollaboratorRole.EDITOR.value
                )
            
            print(f"✅ Promoted user {requester_id} to editor on trip {trip_id}")
        
        # Add trip title to response
        updated_request['trip_title'] = trip.get('name') or trip.get('title')
        
        return EditRequestResponse(**updated_request)
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ UPDATE_EDIT_REQUEST_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update edit request: {str(e)}"
        )


@router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_edit_request(
    request_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Delete an edit request (requester or owner only).

    Args:
        request_id (str): The ID of the request to delete.
        current_user (User): The current authenticated user.

    Returns:
        None

    Raises:
        HTTPException(404): Request not found.
        HTTPException(403): User is not requester or owner.
        HTTPException(500): Delete fails.
    """
    try:
        # Get the request
        edit_request = await firebase_service.get_edit_request(request_id)
        if not edit_request:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Edit request {request_id} not found"
            )
        
        # Verify user is requester or owner
        if edit_request['requester_id'] != current_user.id and edit_request['owner_id'] != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own requests or requests on your trips"
            )
        
        # Delete request
        success = await firebase_service.delete_edit_request(request_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete edit request"
            )
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ DELETE_EDIT_REQUEST_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete edit request: {str(e)}"
        )
