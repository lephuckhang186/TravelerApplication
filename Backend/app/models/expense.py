"""
Expense models for the TravelPro backend API.
"""
from typing import Optional
from datetime import date
from pydantic import BaseModel, Field


class ExpenseBase(BaseModel):
    """
    Base expense model with common fields.

    Attributes:
        name (str): Name or description of the expense.
        amount (float): Cost amount.
        currency (str): Currency code (default: VND).
        category (str): Category of the expense (e.g., food, transport).
        date (date): Date the expense was incurred.
    """
    name: str = Field(..., max_length=100)
    amount: float
    currency: str = Field("VND", max_length=10)
    category: str = Field(..., max_length=50)
    date: date


class ExpenseCreate(ExpenseBase):
    """
    Expense creation model.
    Inherits all fields from ExpenseBase.
    """
    pass


class ExpenseUpdate(BaseModel):
    """
    Expense update model - all fields optional.

    Attributes:
        name (Optional[str]): New name.
        amount (Optional[float]): New amount.
        currency (Optional[str]): New currency code.
        category (Optional[str]): New category.
        date (Optional[date]): New date.
    """
    name: Optional[str] = Field(None, max_length=100)
    amount: Optional[float] = None
    currency: Optional[str] = Field(None, max_length=10)
    category: Optional[str] = Field(None, max_length=50)
    date: Optional[date] = None


class Expense(ExpenseBase):
    """
    Complete expense model with database fields.

    Attributes:
        id (str): Unique expense ID.
        planner_id (str): ID of the parent planner/trip.
    """
    id: str
    planner_id: str

    class Config:
        """Pydantic configuration."""
        from_attributes = True
