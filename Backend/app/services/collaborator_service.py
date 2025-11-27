from typing import List
from sqlalchemy.orm import Session
from app.services.base_service import CRUDBase
from app.models.collaboration import Collaborator, CollaboratorCreate


class CRUDCollaborator(CRUDBase[Collaborator, CollaboratorCreate, None]):
    def get_by_user_and_planner(
        self, db: Session, *, user_id: int, planner_id: int
    ) -> Collaborator:
        return (
            db.query(self.model)
            .filter(
                Collaborator.user_id == user_id,
                Collaborator.planner_id == planner_id,
            )
            .first()
        )

    def get_multi_by_planner(
        self, db: Session, *, planner_id: int
    ) -> List[Collaborator]:
        return (
            db.query(self.model)
            .filter(Collaborator.planner_id == planner_id)
            .all()
        )

    def remove(self, db: Session, *, user_id: int, planner_id: int) -> Collaborator:
        obj = (
            db.query(self.model)
            .filter(
                Collaborator.user_id == user_id,
                Collaborator.planner_id == planner_id,
            )
            .first()
        )
        db.delete(obj)
        db.commit()
        return obj


collaborator = CRUDCollaborator(Collaborator)
