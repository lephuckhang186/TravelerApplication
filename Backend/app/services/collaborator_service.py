from typing import List
from sqlalchemy.orm import Session
from app.services.base_service import CRUDBase
from app.models.collaboration import Collaborator, CollaboratorCreate


class CRUDCollaborator(CRUDBase[Collaborator, CollaboratorCreate, None]):
    """
    CRUD operations for Collaborator model.
    """

    def get_by_user_and_planner(
        self, db: Session, *, user_id: int, planner_id: int
    ) -> Collaborator:
        """
        Get a collaborator by user ID and planner ID.

        Args:
            db (Session): The database session.
            user_id (int): The user's ID.
            planner_id (int): The planner's ID.

        Returns:
            Collaborator: The collaborator object if found, None otherwise.
        """
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
        """
        Get all collaborators for a specific planner.

        Args:
            db (Session): The database session.
            planner_id (int): The planner's ID.

        Returns:
            List[Collaborator]: A list of collaborator objects.
        """
        return (
            db.query(self.model)
            .filter(Collaborator.planner_id == planner_id)
            .all()
        )
    
    def get_multi_by_user(
        self, db: Session, *, user_id: int
    ) -> List[Collaborator]:
        """
        Get all collaborations for a specific user.

        Args:
            db (Session): The database session.
            user_id (int): The user's ID.

        Returns:
            List[Collaborator]: A list of collaborator objects associated with the user.
        """
        return (
            db.query(self.model)
            .filter(Collaborator.user_id == user_id)
            .all()
        )

    def remove(self, db: Session, *, user_id: int, planner_id: int) -> Collaborator:
        """
        Remove a collaborator from a planner.

        Args:
            db (Session): The database session.
            user_id (int): The ID of the user to remove.
            planner_id (int): The ID of the planner.

        Returns:
            Collaborator: The removed collaborator object.
        """
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
    
    def remove_all_by_planner(self, db: Session, *, planner_id: int) -> int:
        """
        Remove all collaborators for a specific planner.

        Args:
            db (Session): The database session.
            planner_id (int): The ID of the planner.

        Returns:
            int: The number of collaborators removed.
        """
        count = (
            db.query(self.model)
            .filter(Collaborator.planner_id == planner_id)
            .delete()
        )
        db.commit()
        return count


collaborator = CRUDCollaborator(Collaborator)
