from typing import List
from sqlalchemy.orm import Session
from app.services.base_service import CRUDBase
from app.models.planner import Planner, PlannerCreate, PlannerUpdate


class CRUDPlanner(CRUDBase[Planner, PlannerCreate, PlannerUpdate]):
    def create_with_owner(
        self, db: Session, *, obj_in: PlannerCreate, user_id: int
    ) -> Planner:
        db_obj = Planner(**obj_in.dict(), user_id=user_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_owner(
        self, db: Session, *, user_id: int, skip: int = 0, limit: int = 100
    ) -> List[Planner]:
        return (
            db.query(self.model)
            .filter(Planner.user_id == user_id)
            .offset(skip)
            .limit(limit)
            .all()
        )


planner = CRUDPlanner(Planner)
