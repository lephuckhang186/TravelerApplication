"""
API endpoints for shared planners - collaboration mode
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session # type: ignore
from app.core import dependencies
from app.models import planner as planner_model
from app.models.user import User
from app.services.planner_service import planner as planner_service
from app.services.collaborator_service import collaborator as collaborator_service

router = APIRouter()


@router.post("/", response_model=planner_model.Planner)
def create_shared_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    planner_in: planner_model.PlannerCreate,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Create new shared planner (collaboration mode).
    """
    # Create planner with current user as owner
    planner = planner_service.create_with_owner(
        db=db, obj_in=planner_in, user_id=current_user.id
    )
    return planner


@router.get("/my-planners", response_model=List[planner_model.Planner])
def read_my_shared_planners(
    db: Session = Depends(dependencies.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> List[planner_model.Planner]:
    """
    Retrieve shared planners owned by current user.
    """
    planners = planner_service.get_multi_by_owner(
        db=db, user_id=current_user.id, skip=skip, limit=limit
    )
    return planners


@router.get("/shared-with-me", response_model=List[planner_model.Planner])
def read_shared_planners(
    db: Session = Depends(dependencies.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> List[planner_model.Planner]:
    """
    Retrieve planners shared with current user (as collaborator).
    """
    # Get all planners where user is a collaborator
    collaborations = collaborator_service.get_multi_by_user(
        db=db, user_id=current_user.id
    )
    
    planner_ids = [collab.planner_id for collab in collaborations]
    if not planner_ids:
        return []
    
    planners = planner_service.get_multi_by_ids(
        db=db, ids=planner_ids, skip=skip, limit=limit
    )
    return planners


@router.get("/all", response_model=List[planner_model.Planner])
def read_all_accessible_planners(
    db: Session = Depends(dependencies.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> List[planner_model.Planner]:
    """
    Retrieve all planners accessible to current user (owned + shared).
    """
    # Get owned planners
    owned_planners = planner_service.get_multi_by_owner(
        db=db, user_id=current_user.id
    )
    
    # Get shared planners
    collaborations = collaborator_service.get_multi_by_user(
        db=db, user_id=current_user.id
    )
    shared_planner_ids = [collab.planner_id for collab in collaborations]
    shared_planners = []
    if shared_planner_ids:
        shared_planners = planner_service.get_multi_by_ids(
            db=db, ids=shared_planner_ids
        )
    
    # Combine and sort by creation date
    all_planners = owned_planners + shared_planners
    all_planners.sort(key=lambda x: x.created_at, reverse=True)
    
    # Apply pagination
    return all_planners[skip:skip + limit]


@router.get("/{id}", response_model=planner_model.Planner)
def read_shared_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    id: int,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Get shared planner by ID (if user has access).
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    
    # Check if user is owner or collaborator
    is_owner = planner.user_id == current_user.id
    is_collaborator = collaborator_service.get_by_user_and_planner(
        db=db, user_id=current_user.id, planner_id=id
    ) is not None
    
    if not (is_owner or is_collaborator):
        raise HTTPException(status_code=403, detail="You don't have access to this planner")
    
    return planner


@router.put("/{id}", response_model=planner_model.Planner)
def update_shared_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    id: int,
    planner_in: planner_model.PlannerUpdate,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Update a shared planner (owner or collaborator can update).
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    
    # Check if user is owner or collaborator
    is_owner = planner.user_id == current_user.id
    is_collaborator = collaborator_service.get_by_user_and_planner(
        db=db, user_id=current_user.id, planner_id=id
    ) is not None
    
    if not (is_owner or is_collaborator):
        raise HTTPException(status_code=403, detail="You don't have access to this planner")
    
    planner = planner_service.update(db=db, db_obj=planner, obj_in=planner_in)
    return planner


@router.delete("/{id}", response_model=planner_model.Planner)
def delete_shared_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    id: int,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Delete a shared planner (only owner can delete).
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    
    # Only owner can delete
    if planner.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the planner owner can delete the planner")
    
    # Remove all collaborators first
    collaborator_service.remove_all_by_planner(db=db, planner_id=id)
    
    # Delete the planner
    planner = planner_service.remove(db=db, id=id)
    return planner


@router.post("/{id}/leave")
def leave_shared_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    id: int,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> dict:
    """
    Leave a shared planner (collaborator leaves).
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    
    # Owner cannot leave their own planner
    if planner.user_id == current_user.id:
        raise HTTPException(
            status_code=400, 
            detail="Planner owner cannot leave. Transfer ownership or delete the planner instead."
        )
    
    # Check if user is a collaborator
    collaborator = collaborator_service.get_by_user_and_planner(
        db=db, user_id=current_user.id, planner_id=id
    )
    if not collaborator:
        raise HTTPException(status_code=404, detail="You are not a collaborator on this planner")
    
    # Remove the collaboration
    collaborator_service.remove(
        db=db, user_id=current_user.id, planner_id=id
    )
    
    return {"message": "Successfully left the planner"}