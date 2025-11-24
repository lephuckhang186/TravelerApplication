from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, Field
import sys
import os

# Add parent directories to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

try:
    from services.annalytics_service import (
        ExpenseManager, ExpenseCategory, Expense, Budget, Trip
    )
except ImportError:
    from app.services.annalytics_service import (
        ExpenseManager, ExpenseCategory, Expense, Budget, Trip
    )
try:
    from core.dependencies import get_current_user
    from models.user import User
except ImportError:
    from app.core.dependencies import get_current_user
    from app.models.user import User

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
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class BudgetCreateRequest(BaseModel):
    total_budget: float = Field(..., gt=0)
    daily_limit: Optional[float] = Field(None, gt=0)
    category_allocations: Optional[dict] = None

class TripCreateRequest(BaseModel):
    start_date: date
    end_date: date
    
    class Config:
        from_attributes = True
        json_encoders = {
            date: lambda v: v.isoformat()
        }

class TripResponse(BaseModel):
    start_date: date
    end_date: date
    total_days: int
    days_remaining: int
    days_elapsed: int
    is_active: bool
    
    class Config:
        from_attributes = True
        json_encoders = {
            date: lambda v: v.isoformat()
        }

class BudgetStatusResponse(BaseModel):
    total_budget: float
    total_spent: float
    percentage_used: float
    remaining_budget: float
    start_date: date
    end_date: date
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
@router.get("/trip/current", response_model=TripResponse)
async def get_current_trip(
    current_user: User = Depends(get_current_user)
):
    """Get the current trip for the user"""
    try:
        manager = get_expense_manager(current_user.id)
        
        if not manager.trip:
            raise HTTPException(
                status_code=404, 
                detail="No active trip found. Please create a trip first."
            )
        
        trip = manager.trip
        return TripResponse(
            start_date=trip.start_date,
            end_date=trip.end_date,
            total_days=trip.total_days,
            days_remaining=trip.days_remaining,
            days_elapsed=trip.days_elapsed,
            is_active=trip.is_active
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/trip/create")
async def create_trip(
    trip_request: TripCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new trip for the user"""
    try:
        manager = get_expense_manager(current_user.id)
        trip = Trip(
            start_date=trip_request.start_date,
            end_date=trip_request.end_date
        )
        manager.set_trip(trip)
        
        return {
            "message": "Trip created successfully",
            "trip": {
                "start_date": trip.start_date.isoformat(),
                "end_date": trip.end_date.isoformat(),
                "duration_days": (trip.end_date - trip.start_date).days + 1
            }
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/budget/create")
async def create_budget(
    budget_request: BudgetCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a budget for the current trip"""
    try:
        manager = get_expense_manager(current_user.id)
        budget = Budget(
            total_budget=Decimal(str(budget_request.total_budget)),
            daily_limit=Decimal(str(budget_request.daily_limit)) if budget_request.daily_limit else None,
            category_allocations=budget_request.category_allocations or {}
        )
        manager.set_budget(budget)
        
        return {
            "message": "Budget created successfully",
            "budget": {
                "total_budget": float(budget.total_budget),
                "daily_limit": float(budget.daily_limit) if budget.daily_limit else None,
                "category_allocations": budget.category_allocations
            }
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Expense Management Endpoints
@router.post("/", response_model=ExpenseResponse)
async def create_expense(
    expense_request: ExpenseCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new expense"""
    try:
        manager = get_expense_manager(current_user.id)
        expense = Expense(
            amount=Decimal(str(expense_request.amount)),
            category=expense_request.category,
            description=expense_request.description,
            expense_date=expense_request.expense_date or datetime.now()
        )
        
        expense_id = manager.add_expense(expense)
        
        return ExpenseResponse(
            id=expense_id,
            amount=float(expense.amount),
            category=expense.category.value,
            description=expense.description,
            expense_date=expense.expense_date,
            currency=current_user.preferred_currency
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=List[ExpenseResponse])
async def get_expenses(
    category: Optional[ExpenseCategory] = Query(None, description="Filter by category"),
    start_date: Optional[date] = Query(None, description="Filter from date"),
    end_date: Optional[date] = Query(None, description="Filter to date"),
    current_user: User = Depends(get_current_user)
):
    """Get all expenses with optional filters"""
    try:
        manager = get_expense_manager(current_user.id)
        expenses = manager.get_expenses(
            category=category,
            start_date=start_date,
            end_date=end_date
        )
        
        return [
            ExpenseResponse(
                id=expense_id,
                amount=float(expense.amount),
                category=expense.category.value,
                description=expense.description,
                expense_date=expense.expense_date,
                currency=current_user.preferred_currency
            )
            for expense_id, expense in expenses.items()
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{expense_id}")
async def delete_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an expense by ID"""
    try:
        manager = get_expense_manager(current_user.id)
        success = manager.delete_expense(expense_id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Expense not found")
        
        return {"message": "Expense deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Analytics Endpoints
@router.get("/budget/status", response_model=BudgetStatusResponse)
async def get_budget_status(
    current_user: User = Depends(get_current_user)
):
    """Get current budget status and analytics"""
    try:
        manager = get_expense_manager(current_user.id)
        analytics = manager.get_analytics()
        
        if not analytics:
            raise HTTPException(status_code=404, detail="No budget or trip data found")
        
        budget_status = analytics.get_budget_status()
        
        return BudgetStatusResponse(
            total_budget=float(budget_status['total_budget']),
            total_spent=float(budget_status['total_spent']),
            percentage_used=budget_status['percentage_used'],
            remaining_budget=float(budget_status['remaining_budget']),
            days_remaining=budget_status['days_remaining'],
            days_total=budget_status['days_total'],
            recommended_daily_spending=float(budget_status['recommended_daily_spending']),
            average_daily_spending=float(budget_status['average_daily_spending']),
            burn_rate_status=budget_status['burn_rate_status'],
            is_over_budget=budget_status['is_over_budget'],
            category_overruns=budget_status['category_overruns']
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/categories/status", response_model=List[CategoryStatusResponse])
async def get_category_status(
    current_user: User = Depends(get_current_user)
):
    """Get spending status by category"""
    try:
        manager = get_expense_manager(current_user.id)
        analytics = manager.get_analytics()
        
        if not analytics:
            raise HTTPException(status_code=404, detail="No budget or trip data found")
        
        category_status = analytics.get_category_status()
        
        return [
            CategoryStatusResponse(
                category=category,
                allocated=float(data['allocated']),
                spent=float(data['spent']),
                remaining=float(data['remaining']),
                percentage_used=data['percentage_used'],
                is_over_budget=data['is_over_budget'],
                status=data['status']
            )
            for category, data in category_status.items()
        ]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/trends")
async def get_spending_trends(
    current_user: User = Depends(get_current_user)
):
    """Get spending trends and patterns"""
    try:
        manager = get_expense_manager(current_user.id)
        analytics = manager.get_analytics()
        
        if not analytics:
            return {"trends": [], "patterns": {}}
        
        trends = analytics.get_spending_trends()
        
        return {
            "daily_trends": trends.get('daily_spending', []),
            "category_trends": trends.get('category_trends', {}),
            "spending_patterns": trends.get('patterns', {}),
            "predictions": trends.get('predictions', {})
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/summary")
async def get_expense_summary(
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive expense summary"""
    try:
        manager = get_expense_manager(current_user.id)
        
        if not manager.expenses:
            return {
                "total_expenses": 0,
                "total_amount": 0.0,
                "category_breakdown": {},
                "daily_breakdown": {}
            }
        
        total_amount = sum(float(expense.amount) for expense in manager.expenses.values())
        
        # Category breakdown
        category_totals = {}
        for expense in manager.expenses.values():
            cat = expense.category.value
            category_totals[cat] = category_totals.get(cat, 0) + float(expense.amount)
        
        # Daily breakdown
        daily_totals = {}
        for expense in manager.expenses.values():
            day = expense.expense_date.date().isoformat()
            daily_totals[day] = daily_totals.get(day, 0) + float(expense.amount)
        
        return {
            "total_expenses": len(manager.expenses),
            "total_amount": total_amount,
            "category_breakdown": category_totals,
            "daily_breakdown": daily_totals
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/export")
async def export_data(
    current_user: User = Depends(get_current_user)
):
    """Export all expense data"""
    try:
        manager = get_expense_manager(current_user.id)
        
        expenses_data = [
            {
                "id": expense_id,
                "amount": float(expense.amount),
                "category": expense.category.value,
                "description": expense.description,
                "expense_date": expense.expense_date.isoformat(),
                "currency": getattr(expense, 'currency', 'VND')
            }
            for expense_id, expense in manager.expenses.items()
        ]
        
        return {
            "message": "Data exported successfully",
            "data": {
                "expenses": expenses_data,
                "summary": {
                    "total_count": len(expenses_data),
                    "total_amount": sum(exp["amount"] for exp in expenses_data)
                }
            },
            "exported_at": datetime.now().isoformat(),
            "user_id": current_user.id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Health check endpoint
@router.get("/health")
async def health_check():
    """Health check for expenses service"""
    return {
        "status": "healthy",
        "service": "expenses",
        "timestamp": datetime.now().isoformat(),
        "active_managers": len(expense_managers)
    }

# Development: Make this file runnable for testing
if __name__ == "__main__":
    print("Expenses API module loaded successfully!")
    print("Available endpoints:")
    for route in router.routes:
        print(f"  {getattr(route, 'methods', 'N/A')} {route.path}")
    