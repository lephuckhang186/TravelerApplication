"""
Expense models for the TravelPro backend API.
"""
from typing import Optional
from datetime import date
from pydantic import BaseModel, Field


class ExpenseBase(BaseModel):
    """Base expense model with common fields."""
    name: str = Field(..., max_length=100)
    amount: float
    currency: str = Field("VND", max_length=10)
    category: str = Field(..., max_length=50)
    date: date


class ExpenseCreate(ExpenseBase):
    """Expense creation model."""
    pass


class ExpenseUpdate(BaseModel):
    """Expense update model - all fields optional."""
    name: Optional[str] = Field(None, max_length=100)
    amount: Optional[float] = None
    currency: Optional[str] = Field(None, max_length=10)
    category: Optional[str] = Field(None, max_length=50)
    date: Optional[date] = None


class Expense(ExpenseBase):
    """Complete expense model with database fields."""
    id: str
    planner_id: str

    class Config:
        """Pydantic configuration."""
        from_attributes = True
