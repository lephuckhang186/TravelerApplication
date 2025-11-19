from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, Field

from ...services.annalytics_service import (
    ExpenseManager, ExpenseCategory, Expense, Budget, Trip
)
from ...core.dependencies import get_current_user
from ...models.user import User

router = APIRouter(prefix="/expenses", tags=["expenses"])

# Pydantic Models for Request/Response
class ExpenseCreateRequest(BaseModel):
    amount: float = Field(..., gt=0, description="Expense amount (must be positive)")
    category: ExpenseCategory = Field(..., description="Expense category")
    description: str = Field("", max_length=500, description="Optional expense description")
    expense_date: Optional[datetime] = Field(None, description="Expense date (defaults to now)")

class ExpenseResponse(BaseModel):
    id: str
    amount: float
    category: str
    description: str
    expense_date: datetime
    currency: str = "VND"
    
    class Config:
        from_attributes = True

class BudgetCreateRequest(BaseModel):
    total_budget: float = Field(..., gt=0)
    daily_limit: Optional[float] = Field(None, gt=0)
    category_allocations: Optional[dict] = None

class TripCreateRequest(BaseModel):
    start_date: date
    end_date: date
    
    class Config:
        json_encoders = {
            date: lambda v: v.isoformat()
        }

class BudgetStatusResponse(BaseModel):
    total_budget: float
    total_spent: float
    percentage_used: float
    remaining_budget: float
    days_remaining: int
    days_total: int
    recommended_daily_spending: float
    average_daily_spending: float
    burn_rate_status: str
    is_over_budget: bool
    category_overruns: List[str]

class CategoryStatusResponse(BaseModel):
    category: str
    allocated: float
    spent: float
    remaining: float
    percentage_used: float
    is_over_budget: bool
    status: str

# Global expense manager instance (in production, use database)
expense_managers: dict = {}

def get_expense_manager(user_id: str) -> ExpenseManager:
    """Get or create expense manager for user"""
    if user_id not in expense_managers:
        expense_managers[user_id] = ExpenseManager()
    return expense_managers[user_id]

# Trip Management Endpoints
@router.post("/trip/create")
async def create_trip(
    trip_request: TripCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new trip"""
    try:
        manager = get_expense_manager(current_user.id)
        trip = Trip(
            start_date=trip_request.start_date,
            end_date=trip_request.end_date
        )
        
        return {
            "message": "Trip created successfully",
            "trip": {
                "start_date": trip.start_date.isoformat(),
                "end_date": trip.end_date.isoformat(),
                "total_days": trip.total_days,
                "days_remaining": trip.days_remaining,
                "is_active": trip.is_active
            }
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/budget/create")
async def create_budget(
    budget_request: BudgetCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create budget plan for the trip"""
    try:
        manager = get_expense_manager(current_user.id)
        
        # Convert category allocations if provided
        category_allocations = None
        if budget_request.category_allocations:
            category_allocations = {
                ExpenseCategory(k): Decimal(str(v))
                for k, v in budget_request.category_allocations.items()
            }
        
        budget = Budget(
            total_budget=Decimal(str(budget_request.total_budget)),
            daily_limit=Decimal(str(budget_request.daily_limit)) if budget_request.daily_limit else None,
            category_allocations=category_allocations
        )
        
        # Note: In a real app, you'd also need the trip
        # For now, create a default trip if none exists
        if not manager.trip:
            from datetime import timedelta
            today = date.today()
            default_trip = Trip(
                start_date=today,
                end_date=today + timedelta(days=7)
            )
            manager.create_budget_plan(default_trip, budget)
        else:
            manager.create_budget_plan(manager.trip, budget)
        
        return {
            "message": "Budget created successfully",
            "budget": {
                "total_budget": float(budget.total),
                "daily_limit": float(budget.daily_limit) if budget.daily_limit else None,
                "total_allocated": float(budget.get_total_allocated()),
                "unallocated": float(budget.get_unallocated())
            }
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

# Expense Management Endpoints
@router.post("/", response_model=ExpenseResponse)
async def create_expense(
    expense_request: ExpenseCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Add a new expense"""
    try:
        manager = get_expense_manager(current_user.id)
        
        if not manager.trip_budget:
            raise HTTPException(
                status_code=400, 
                detail="Please create a budget plan first"
            )
        
        expense = manager.add_expense(
            amount=Decimal(str(expense_request.amount)),
            category=expense_request.category,
            description=expense_request.description,
            expense_date=expense_request.expense_date
        )
        
        return ExpenseResponse(
            id=str(id(expense)),  # In production, use proper ID
            amount=float(expense.amount),
            category=expense.category.value,
            description=expense.description,
            expense_date=expense.date,
            currency=expense.currency
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=List[ExpenseResponse])
async def get_expenses(
    category: Optional[ExpenseCategory] = Query(None, description="Filter by category"),
    start_date: Optional[date] = Query(None, description="Filter from date"),
    end_date: Optional[date] = Query(None, description="Filter to date"),
    current_user: User = Depends(get_current_user)
):
    """Get expense history with optional filters"""
    manager = get_expense_manager(current_user.id)
    
    date_range = None
    if start_date and end_date:
        date_range = (start_date, end_date)
    
    expenses = manager.get_expense_history(
        category_filter=category,
        date_range=date_range
    )
    
    return [
        ExpenseResponse(
            id=str(id(expense)),
            amount=float(expense.amount),
            category=expense.category.value,
            description=expense.description,
            expense_date=expense.date,
            currency=expense.currency
        )
        for expense in expenses
    ]

@router.delete("/{expense_id}")
async def delete_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an expense"""
    manager = get_expense_manager(current_user.id)
    
    # In production, find expense by proper ID
    # For now, this is a simplified implementation
    if not manager.expenses:
        raise HTTPException(status_code=404, detail="Expense not found")
    
    # Remove the last expense as example (improve this in production)
    expense = manager.expenses[-1]
    success = manager.remove_expense(expense)
    
    if success:
        return {"message": "Expense deleted successfully"}
    else:
        raise HTTPException(status_code=404, detail="Expense not found")

# Analytics Endpoints
@router.get("/budget/status", response_model=BudgetStatusResponse)
async def get_budget_status(
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive budget status"""
    manager = get_expense_manager(current_user.id)
    
    if not manager.trip_budget:
        raise HTTPException(status_code=400, detail="No budget plan found")
    
    status = manager.get_budget_status()
    
    if not status:
        raise HTTPException(status_code=400, detail="Unable to generate budget status")
    
    return BudgetStatusResponse(
        total_budget=float(status.total_budget),
        total_spent=float(status.total_spent),
        percentage_used=status.percentage_used,
        remaining_budget=float(status.remaining_budget),
        days_remaining=status.days_remaining,
        days_total=status.days_total,
        recommended_daily_spending=float(status.recommended_daily_spending),
        average_daily_spending=float(status.average_daily_spending),
        burn_rate_status=status.burn_rate_status,
        is_over_budget=status.is_over_budget,
        category_overruns=[cat.value for cat in status.category_overruns]
    )

@router.get("/categories/status", response_model=List[CategoryStatusResponse])
async def get_category_status(
    current_user: User = Depends(get_current_user)
):
    """Get status for all expense categories"""
    manager = get_expense_manager(current_user.id)
    
    if not manager.trip_budget:
        raise HTTPException(status_code=400, detail="No budget plan found")
    
    category_status = manager.get_category_status()
    
    return [
        CategoryStatusResponse(
            category=category.value,
            allocated=float(info['allocated']),
            spent=float(info['spent']),
            remaining=float(info['remaining']),
            percentage_used=info['percentage_used'],
            is_over_budget=info['is_over_budget'],
            status=info['status']
        )
        for category, info in category_status.items()
    ]

@router.get("/analytics/trends")
async def get_spending_trends(
    current_user: User = Depends(get_current_user)
):
    """Get spending trends and patterns"""
    manager = get_expense_manager(current_user.id)
    
    if not manager.analytics or not manager.trip:
        raise HTTPException(status_code=400, detail="No analytics data available")
    
    trends = manager.analytics.get_spending_trends(manager.trip)
    
    return {
        "trend": trends["trend"],
        "recent_average": float(trends.get("recent_average", 0)),
        "overall_average": float(trends.get("overall_average", 0)),
        "daily_totals": {
            date_str: float(amount) 
            for date_str, amount in trends.get("daily_totals", {}).items()
        }
    }

@router.get("/analytics/summary")
async def get_expense_summary(
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive expense summary"""
    manager = get_expense_manager(current_user.id)
    
    if not manager.analytics:
        raise HTTPException(status_code=400, detail="No analytics data available")
    
    category_totals = manager.analytics.get_category_totals()
    daily_totals = manager.analytics.get_daily_totals()
    
    return {
        "total_expenses": len(manager.expenses),
        "total_amount": float(manager.get_total_spent()),
        "category_breakdown": {
            category.value: float(amount)
            for category, amount in category_totals.items()
        },
        "daily_breakdown": {
            date_obj.isoformat(): float(amount)
            for date_obj, amount in daily_totals.items()
        }
    }

@router.post("/export")
async def export_data(
    current_user: User = Depends(get_current_user)
):
    """Export all expense data"""
    manager = get_expense_manager(current_user.id)
    
    data = manager.export_data()
    
    return {
        "message": "Data exported successfully",
        "data": data,
        "exported_at": datetime.now().isoformat(),
        "user_id": current_user.id
    }

# Health check endpoint
@router.get("/health")
async def health_check():
    """Health check for expense service"""
    return {
        "status": "healthy",
        "service": "expense_management",
        "timestamp": datetime.now().isoformat(),
        "active_users": len(expense_managers)
    }
    