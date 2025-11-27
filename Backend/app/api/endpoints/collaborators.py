"""
API endpoints for collaborators
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core import dependencies
from app.models import collaborator as collaborator_model
from app.services import collaborator as collaborator_service

router = APIRouter()


@router.post("/", response_model=collaborator_model.Collaborator)
def add_collaborator(
    *,
    db: Session = Depends(dependencies.get_db),
    collaborator_in: collaborator_model.CollaboratorCreate,
    current_user: collaborator_model.User = Depends(dependencies.get_current_active_user),
) -> collaborator_model.Collaborator:
    """
    Add a collaborator to a planner.
    """
    # TODO: Add logic to check if the current user is the owner of the planner
    collaborator = collaborator_service.create(db=db, obj_in=collaborator_in)
    return collaborator


@router.get(
    "/{planner_id}", response_model=List[collaborator_model.Collaborator]
)
def read_collaborators(
    *,
    db: Session = Depends(dependencies.get_db),
    planner_id: int,
    current_user: collaborator_model.User = Depends(dependencies.get_current_active_user),
) -> List[collaborator_model.Collaborator]:
    """
    Get collaborators for a planner.
    """
    # TODO: Add logic to check if the current user is a collaborator on the planner
    collaborators = collaborator_service.get_multi_by_planner(
        db=db, planner_id=planner_id
    )
    return collaborators


@router.delete("/")
def remove_collaborator(
    *,
    db: Session = Depends(dependencies.get_db),
    collaborator_in: collaborator_model.CollaboratorCreate,
    current_user: collaborator_model.User = Depends(dependencies.get_current_active_user),
) -> None:
    """
    Remove a collaborator from a planner.
    """
    # TODO: Add logic to check if the current user is the owner of the planner
    collaborator = collaborator_service.get_by_user_and_planner(
        db=db, user_id=collaborator_in.user_id, planner_id=collaborator_in.planner_id
    )
    if not collaborator:
        raise HTTPException(status_code=404, detail="Collaborator not found")
    collaborator_service.remove(
        db=db, user_id=collaborator_in.user_id, planner_id=collaborator_in.planner_id
    )
    return None
