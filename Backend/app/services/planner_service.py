from typing import List
from sqlalchemy.orm import Session
from app.services.base_service import CRUDBase
from app.models.planner import Planner, PlannerCreate, PlannerUpdate


class CRUDPlanner(CRUDBase[Planner, PlannerCreate, PlannerUpdate]):
    """
    CRUD operations for Planner model.
    """

    def create_with_owner(
        self, db: Session, *, obj_in: PlannerCreate, user_id: int
    ) -> Planner:
        """
        Create a new planner with an owner.

        Args:
            db (Session): The database session.
            obj_in (PlannerCreate): The planner creation data.
            user_id (int): The ID of the user creating the planner.

        Returns:
            Planner: The created planner object.
        """
        db_obj = Planner(**obj_in.dict(), user_id=user_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_owner(
        self, db: Session, *, user_id: int, skip: int = 0, limit: int = 100
    ) -> List[Planner]:
        """
        Get multiple planners belonging to a specific owner.

        Args:
            db (Session): The database session.
            user_id (int): The owner's user ID.
            skip (int): Number of records to skip. Defaults to 0.
            limit (int): Maximum number of records to return. Defaults to 100.

        Returns:
            List[Planner]: A list of planner objects.
        """
        return (
            db.query(self.model)
            .filter(Planner.user_id == user_id)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def get_multi_by_ids(
        self, db: Session, *, ids: List[int], skip: int = 0, limit: int = 100
    ) -> List[Planner]:
        """
        Get multiple planners by a list of IDs.

        Args:
            db (Session): The database session.
            ids (List[int]): A list of planner IDs to retrieve.
            skip (int): Number of records to skip. Defaults to 0.
            limit (int): Maximum number of records to return. Defaults to 100.

        Returns:
            List[Planner]: A list of planner objects.
        """
        return (
            db.query(self.model)
            .filter(Planner.id.in_(ids))
            .offset(skip)
            .limit(limit)
            .all()
        )


planner = CRUDPlanner(Planner)
