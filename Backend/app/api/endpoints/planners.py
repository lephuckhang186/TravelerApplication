"""
API endpoints for planners.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core import dependencies
from app.models import planner as planner_model
from app.models.user import User
from app.services.planner_service import planner as planner_service

router = APIRouter()


@router.post("/", response_model=planner_model.Planner)
def create_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    planner_in: planner_model.PlannerCreate,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Create a new planner.

    Args:
        db (Session): The database session.
        planner_in (planner_model.PlannerCreate): The planner creation data.
        current_user (User): The current authenticated user.

    Returns:
        planner_model.Planner: The created planner object.
    """
    planner = planner_service.create_with_owner(
        db=db, obj_in=planner_in, user_id=current_user.id
    )
    return planner


@router.get("/", response_model=List[planner_model.Planner])
def read_planners(
    db: Session = Depends(dependencies.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> List[planner_model.Planner]:
    """
    Retrieve planners belonging to the current user.

    Args:
        db (Session): The database session.
        skip (int): Number of planners to skip. Defaults to 0.
        limit (int): Maximum number of planners to return. Defaults to 100.
        current_user (User): The current authenticated user.

    Returns:
        List[planner_model.Planner]: A list of planner objects.
    """
    planners = planner_service.get_multi_by_owner(
        db=db, user_id=current_user.id, skip=skip, limit=limit
    )
    return planners


@router.get("/{id}", response_model=planner_model.Planner)
def read_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    id: int,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Get a specific planner by ID.

    Args:
        db (Session): The database session.
        id (int): The ID of the planner to retrieve.
        current_user (User): The current authenticated user.

    Returns:
        planner_model.Planner: The requested planner object.

    Raises:
        HTTPException(404): If the planner is not found.
        HTTPException(403): If the user does not have permission to access the planner.
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    if planner.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return planner


@router.put("/{id}", response_model=planner_model.Planner)
def update_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    id: int,
    planner_in: planner_model.PlannerUpdate,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Update a planner.

    Args:
        db (Session): The database session.
        id (int): The ID of the planner to update.
        planner_in (planner_model.PlannerUpdate): The planner update data.
        current_user (User): The current authenticated user.

    Returns:
        planner_model.Planner: The updated planner object.

    Raises:
        HTTPException(404): If the planner is not found.
        HTTPException(403): If the user does not have permission to update the planner.
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    if planner.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    planner = planner_service.update(db=db, db_obj=planner, obj_in=planner_in)
    return planner


@router.delete("/{id}", response_model=planner_model.Planner)
def delete_planner(
    *,
    db: Session = Depends(dependencies.get_db),
    id: int,
    current_user: User = Depends(dependencies.get_current_active_user),
) -> planner_model.Planner:
    """
    Delete a planner.

    Args:
        db (Session): The database session.
        id (int): The ID of the planner to delete.
        current_user (User): The current authenticated user.

    Returns:
        planner_model.Planner: The deleted planner object.

    Raises:
        HTTPException(404): If the planner is not found.
        HTTPException(403): If the user does not have permission to delete the planner.
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    if planner.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    planner = planner_service.remove(db=db, id=id)
    return planner
