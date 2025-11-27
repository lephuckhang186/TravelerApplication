from typing import List
from sqlalchemy.orm import Session
from app.services.base_service import CRUDBase
from app.models.expense import Expense, ExpenseCreate, ExpenseUpdate


class CRUDExpense(CRUDBase[Expense, ExpenseCreate, ExpenseUpdate]):
    def create_with_owner(
        self, db: Session, *, obj_in: ExpenseCreate, user_id: int
    ) -> Expense:
        db_obj = Expense(**obj_in.dict(), user_id=user_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_owner(
        self, db: Session, *, user_id: int, skip: int = 0, limit: int = 100
    ) -> List[Expense]:
        return (
            db.query(self.model)
            .filter(Expense.user_id == user_id)
            .offset(skip)
            .limit(limit)
            .all()
        )


expense = CRUDExpense(Expense)
