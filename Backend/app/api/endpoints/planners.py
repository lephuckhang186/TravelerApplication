"""
API endpoints for planners
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
    Create new planner.
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
    Retrieve planners.
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
    Get planner by ID.
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
    """
    planner = planner_service.get(db=db, id=id)
    if not planner:
        raise HTTPException(status_code=404, detail="Planner not found")
    if planner.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    planner = planner_service.remove(db=db, id=id)
    return planner
