"""
API endpoints for collaborators
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core import dependencies
from app.models import collaboration as collaborator_model
from app.models.user import User
from app.services.collaborator_service import collaborator as collaborator_service

router = APIRouter()


@router.post("/", response_model=collaborator_model.Collaborator)
def add_collaborator(
    *,
    db: Session = Depends(dependencies.get_db),
    collaborator_in: collaborator_model.CollaboratorCreate,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> collaborator_model.Collaborator:
    """
    Add a collaborator to a planner.
    """
    # Check if the current user is the owner of the planner
    from app.services.planner_service import planner as planner_service
    planner = planner_service.get(db=db, id=collaborator_in.planner_id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    if planner.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the planner owner can add collaborators")
    
    collaborator = collaborator_service.create(db=db, obj_in=collaborator_in)
    return collaborator


@router.get(
    "/{planner_id}", response_model=List[collaborator_model.Collaborator]
)
def read_collaborators(
    *,
    db: Session = Depends(dependencies.get_db),
    planner_id: int,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> List[collaborator_model.Collaborator]:
    """
    Get collaborators for a planner.
    """
    # Check if the current user is the owner or a collaborator on the planner
    from app.services.planner_service import planner as planner_service
    planner = planner_service.get(db=db, id=planner_id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    
    # Check if user is owner or collaborator
    is_owner = planner.user_id == current_user.id
    is_collaborator = collaborator_service.get_by_user_and_planner(
        db=db, user_id=current_user.id, planner_id=planner_id
    ) is not None
    
    if not (is_owner or is_collaborator):
        raise HTTPException(status_code=403, detail="You don't have access to this planner")
    
    collaborators = collaborator_service.get_multi_by_planner(
        db=db, planner_id=planner_id
    )
    return collaborators


@router.delete("/")
def remove_collaborator(
    *,
    db: Session = Depends(dependencies.get_db),
    collaborator_in: collaborator_model.CollaboratorCreate,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> None:
    """
    Remove a collaborator from a planner.
    """
    # Check if the current user is the owner of the planner
    from app.services.planner_service import planner as planner_service
    planner = planner_service.get(db=db, id=collaborator_in.planner_id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    if planner.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the planner owner can remove collaborators")
    
    collaborator = collaborator_service.get_by_user_and_planner(
        db=db, user_id=collaborator_in.user_id, planner_id=collaborator_in.planner_id
    )
    if not collaborator:
        raise HTTPException(status_code=404, detail="Collaborator not found")
    collaborator_service.remove(
        db=db, user_id=collaborator_in.user_id, planner_id=collaborator_in.planner_id
    )
    return None
