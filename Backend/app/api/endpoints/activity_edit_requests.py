"""
Activity Edit Request API endpoints for activity modification requests.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime

try:
    from ...core.dependencies import get_current_user
    from ...models.user import User
    from ...models.collaboration import (
        ActivityEditRequest,
        ActivityEditRequestCreate,
        ActivityEditRequestResponse,
        ActivityEditRequestUpdate,
        ActivityEditRequestStatus
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
        ActivityEditRequest,
        ActivityEditRequestCreate,
        ActivityEditRequestResponse,
        ActivityEditRequestUpdate,
        ActivityEditRequestStatus
    )
    from services.firebase_service import firebase_service

router = APIRouter(prefix="/activity-edit-requests", tags=["activity-edit-requests"])


@router.post("/", response_model=ActivityEditRequestResponse)
async def create_activity_edit_request(
    request_data: ActivityEditRequestCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Create a new activity edit request (Editor requests to modify activities).

    Allows a user with Editor role (or Owner) to propose changes to activities (add, edit, delete).

    Args:
        request_data (ActivityEditRequestCreate): The payload containing change details.
        current_user (User): The current authenticated user.

    Returns:
        ActivityEditRequestResponse: The created request details.

    Raises:
        HTTPException(404): Trip not found.
        HTTPException(400): Trip has no owner.
        HTTPException(403): User is not an editor or owner.
        HTTPException(500): Creation failure.
    """
    try:
        trip_id = request_data.trip_id

        # 1. Verify trip exists
        trip = await firebase_service.get_trip(trip_id)
        if not trip:
            trip = await firebase_service.get_trip(trip_id, current_user.id)
            if not trip:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Trip {trip_id} not found"
                )

        owner_id = trip.get('user_id') or trip.get('userId') or trip.get('ownerId') or trip.get('owner_id')
        if not owner_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trip has no owner"
            )

        # 2. Check if user is editor or owner
        shared_collaborators = trip.get('sharedCollaborators', [])
        user_role = 'viewer'

        # Check if user is owner
        if owner_id == current_user.id:
            user_role = 'owner'
        else:
            # Check shared collaborators
            user_collab = next((c for c in shared_collaborators
                              if c.get('userId') == current_user.id or c.get('user_id') == current_user.id), None)
            if user_collab:
                user_role = user_collab.get('role', 'viewer')

        # Only editors and owners can create activity edit requests
        if user_role not in ['owner', 'editor']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only trip editors can request activity modifications"
            )

        # 3. Create activity edit request
        activity_request = await firebase_service.create_activity_edit_request(
            trip_id=trip_id,
            request_type=request_data.request_type,
            requester_id=current_user.id,
            requester_name=f"{current_user.first_name} {current_user.last_name}".strip() or current_user.username,
            requester_email=current_user.email,
            owner_id=owner_id,
            activity_id=request_data.activity_id,
            proposed_changes=request_data.proposed_changes,
            message=request_data.message,
            activity_title=request_data.activity_title
        )

        # Add trip title to response
        activity_request['trip_title'] = trip.get('name') or trip.get('title')

        return ActivityEditRequestResponse(**activity_request)

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ CREATE_ACTIVITY_EDIT_REQUEST_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create activity edit request: {str(e)}"
        )


@router.get("/my-requests", response_model=List[ActivityEditRequestResponse])
async def get_my_activity_edit_requests(
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get all activity edit requests created by current user.

    Args:
        status_filter (Optional[str]): filter by status (pending, approved, rejected).
        current_user (User): The current authenticated user.

    Returns:
        List[ActivityEditRequestResponse]: List of user's requests.
    """
    try:
        requests = await firebase_service.get_user_activity_edit_requests(
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
            result.append(ActivityEditRequestResponse(**req))

        return result

    except Exception as e:
        print(f"❌ GET_MY_ACTIVITY_EDIT_REQUESTS_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get activity edit requests: {str(e)}"
        )


@router.get("/pending-approvals", response_model=List[ActivityEditRequestResponse])
async def get_pending_activity_approvals(
    current_user: User = Depends(get_current_user)
):
    """
    Get all pending activity edit requests for trips owned by current user.

    Args:
        current_user (User): The current authenticated user (acting as Owner).

    Returns:
        List[ActivityEditRequestResponse]: List of pending requests.
    """
    try:
        requests = await firebase_service.get_owner_activity_edit_requests(
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
            result.append(ActivityEditRequestResponse(**req))

        return result

    except Exception as e:
        print(f"❌ GET_PENDING_ACTIVITY_APPROVALS_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get pending activity approvals: {str(e)}"
        )


@router.get("/trip/{trip_id}", response_model=List[ActivityEditRequestResponse])
async def get_trip_activity_edit_requests(
    trip_id: str,
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get all activity edit requests for a specific trip (owner only).

    Args:
        trip_id (str): The ID of the trip.
        status_filter (Optional[str]): Optional status filter.
        current_user (User): The current authenticated user.

    Returns:
        List[ActivityEditRequestResponse]: List of requests for the trip.

    Raises:
        HTTPException(404): Trip not found.
        HTTPException(403): User is not the owner.
    """
    try:
        # Verify user is trip owner
        trip = await firebase_service.get_trip(trip_id)
        if not trip:
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
                detail="Only trip owner can view activity edit requests"
            )

        requests = await firebase_service.get_trip_activity_edit_requests(
            trip_id,
            status=status_filter
        )

        trip_title = trip.get('name') or trip.get('title')
        result = []
        for req in requests:
            req['trip_title'] = trip_title
            result.append(ActivityEditRequestResponse(**req))

        return result

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ GET_TRIP_ACTIVITY_EDIT_REQUESTS_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get trip activity edit requests: {str(e)}"
        )


@router.put("/{request_id}", response_model=ActivityEditRequestResponse)
async def update_activity_edit_request(
    request_id: str,
    update_data: ActivityEditRequestUpdate,
    current_user: User = Depends(get_current_user)
):
    """
    Approve or reject an activity edit request (owner only).

    If approved, the changes are automatically applied to the trip's activities.

    Args:
        request_id (str): The ID of the request to update.
        update_data (ActivityEditRequestUpdate): The update payload (status).
        current_user (User): The current authenticated user.

    Returns:
        ActivityEditRequestResponse: The updated request.

    Raises:
        HTTPException(404): Request or trip not found.
        HTTPException(403): User is not the owner.
        HTTPException(400): Request is not pending.
        HTTPException(500): Update or Application of changes failed.
    """
    try:
        # 1. Get the request
        activity_request = await firebase_service.get_activity_edit_request(request_id)
        if not activity_request:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Activity edit request {request_id} not found"
            )

        # 2. Verify user is trip owner
        trip_id = activity_request['trip_id']
        trip = await firebase_service.get_trip(trip_id)
        if not trip:
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
                detail="Only trip owner can respond to activity edit requests"
            )

        # 3. Check if request is still pending
        if activity_request['status'] != 'pending':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Request is already {activity_request['status']}"
            )

        # 4. Update request status
        updated_request = await firebase_service.update_activity_edit_request(
            request_id,
            update_data.status.value,
            current_user.id
        )

        # 5. If approved, apply the activity changes
        if update_data.status == ActivityEditRequestStatus.APPROVED:
            await _apply_activity_changes(activity_request, trip)

        # Add trip title to response
        updated_request['trip_title'] = trip.get('name') or trip.get('title')

        return ActivityEditRequestResponse(**updated_request)

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ UPDATE_ACTIVITY_EDIT_REQUEST_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update activity edit request: {str(e)}"
        )


async def _apply_activity_changes(activity_request: dict, trip: dict):
    """
    Apply approved activity changes to the trip.

    Handles 'add_activity', 'edit_activity', and 'delete_activity' request types.

    Args:
        activity_request (dict): The confirmed activity edit request.
        trip (dict): The trip data to modify.
    
    Raises:
        HTTPException(500): If applying changes fails.
    """
    try:
        trip_id = activity_request['trip_id']
        request_type = activity_request['request_type']
        proposed_changes = activity_request.get('proposed_changes', {})

        print(f"✅ Applying activity changes: {request_type} on trip {trip_id}")
        print(f"   Trip has {len(trip.get('activities', []))} current activities")

        # Get current activities from trip
        current_activities = trip.get('activities', [])
        updated_activities = current_activities.copy()

        if request_type == 'add_activity':
            # Add new activity
            new_activity = proposed_changes.copy()
            new_activity['id'] = f"activity_{datetime.utcnow().timestamp()}"
            new_activity['tripId'] = trip_id

            updated_activities.append(new_activity)
            print(f"✅ Added new activity: {new_activity.get('title', 'Untitled')}")

        elif request_type == 'edit_activity':
            # Update existing activity
            activity_id = activity_request['activity_id']
            print(f"   Looking for activity {activity_id} to update")

            # Find and update activity
            found = False
            for i, activity in enumerate(updated_activities):
                if activity.get('id') == activity_id or activity.get('activityId') == activity_id:
                    print(f"   Found activity at index {i}: {activity.get('title')}")
                    # Apply changes
                    for key, value in proposed_changes.items():
                        if value is not None:  # Only update non-null values
                            activity[key] = value
                            print(f"   Updated {key}: {value}")
                    updated_activities[i] = activity
                    found = True
                    break

            if not found:
                print(f"❌ Activity {activity_id} not found in trip {trip_id}")
                return

        elif request_type == 'delete_activity':
            # Delete activity
            activity_id = activity_request['activity_id']
            print(f"   Looking for activity {activity_id} to delete")

            original_count = len(updated_activities)
            updated_activities = [a for a in updated_activities
                                if a.get('id') != activity_id and a.get('activityId') != activity_id]

            if len(updated_activities) < original_count:
                print(f"✅ Deleted activity {activity_id}")
            else:
                print(f"❌ Activity {activity_id} not found for deletion")
                return

        # Update the trip with new activities
        success = await firebase_service.update_trip_activities(trip_id, updated_activities)

        if success:
            print(f"✅ Successfully updated trip {trip_id} with {len(updated_activities)} activities")
        else:
            print(f"❌ Failed to update trip {trip_id} activities")

    except Exception as e:
        print(f"❌ APPLY_ACTIVITY_CHANGES_ERROR: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to apply activity changes: {str(e)}"
        )


@router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity_edit_request(
    request_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Delete an activity edit request (requester or owner only).

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
        activity_request = await firebase_service.get_activity_edit_request(request_id)
        if not activity_request:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Activity edit request {request_id} not found"
            )

        # Verify user is requester or owner
        if activity_request['requester_id'] != current_user.id and activity_request['owner_id'] != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own requests or requests on your trips"
            )

        # Delete request
        success = await firebase_service.delete_activity_edit_request(request_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete activity edit request"
            )

        return None

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ DELETE_ACTIVITY_EDIT_REQUEST_ERROR: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete activity edit request: {str(e)}"
        )
