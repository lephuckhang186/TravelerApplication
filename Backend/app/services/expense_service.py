from typing import List
from sqlalchemy.orm import Session
from app.services.base_service import CRUDBase
from app.models.expense import Expense, ExpenseCreate, ExpenseUpdate


class CRUDExpense(CRUDBase[Expense, ExpenseCreate, ExpenseUpdate]):
    """
    CRUD operations for Expense model.
    """

    def create_with_owner(
        self, db: Session, *, obj_in: ExpenseCreate, user_id: int
    ) -> Expense:
        """
        Create a new expense associated with an owner.

        Args:
            db (Session): The database session.
            obj_in (ExpenseCreate): The expense creation data.
            user_id (int): The ID of the owner/user.

        Returns:
            Expense: The created expense object.
        """
        db_obj = Expense(**obj_in.dict(), user_id=user_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_owner(
        self, db: Session, *, user_id: int, skip: int = 0, limit: int = 100
    ) -> List[Expense]:
        """
        Get all expenses for a specific owner.

        Args:
            db (Session): The database session.
            user_id (int): The owner's user ID.
            skip (int): Number of records to skip. Defaults to 0.
            limit (int): Maximum number of records to return. Defaults to 100.

        Returns:
            List[Expense]: A list of expense objects associated with the user.
        """
        return (
            db.query(self.model)
            .filter(Expense.user_id == user_id)
            .offset(skip)
            .limit(limit)
            .all()
        )


expense = CRUDExpense(Expense)
