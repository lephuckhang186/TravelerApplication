from fastapi import APIRouter, HTTPException, Depends, Query, status
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
    
    class Config:
        from_attributes = True
        json_encoders = {
            date: lambda v: v.isoformat()
        }

class CategoryStatusResponse(BaseModel):
    category: str
    allocated: float
    spent: float
    remaining: float
    percentage_used: float
    is_over_budget: bool
    status: str

# User expense managers (replace with database in production)
expense_managers: dict = {}

def get_expense_manager(user_id: str) -> ExpenseManager:
    """Get or create expense manager for authenticated user"""
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User authentication required"
        )
    
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
            date=expense_request.expense_date or datetime.now(),
            description=expense_request.description
        )
        
        expense_id = manager.add_expense(expense)
        
        return ExpenseResponse(
            id=expense_id,
            amount=float(expense.amount),
            category=expense.category.value,
            description=expense.description,
            expense_date=expense.date,
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
                expense_date=expense.date,
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
        budget_status = manager.get_budget_status()
        
        if not budget_status:
            raise HTTPException(status_code=404, detail="No budget or trip data found")
        
        return BudgetStatusResponse(
            total_budget=float(budget_status.total_budget),
            total_spent=float(budget_status.total_spent),
            percentage_used=budget_status.percentage_used,
            remaining_budget=float(budget_status.remaining_budget),
            start_date=manager.trip.start_date if manager.trip else date.today(),
            end_date=manager.trip.end_date if manager.trip else date.today(),
            days_remaining=budget_status.days_remaining,
            days_total=budget_status.days_total,
            recommended_daily_spending=float(budget_status.recommended_daily_spending),
            average_daily_spending=float(budget_status.average_daily_spending),
            burn_rate_status=budget_status.burn_rate_status,
            is_over_budget=budget_status.is_over_budget,
            category_overruns=[cat.value for cat in budget_status.category_overruns]
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
        category_status = manager.get_category_status()
        
        if not category_status:
            raise HTTPException(status_code=404, detail="No budget or trip data found")
        
        return [
            CategoryStatusResponse(
                category=category.value,
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
        
        if not analytics or not manager.trip:
            return {"trends": [], "patterns": {}}
        
        trends = analytics.get_spending_trends(manager.trip)
        daily_totals = analytics.get_daily_totals()
        
        # Convert daily_totals to the expected format
        daily_trends = [
            {
                "date": date_obj.isoformat(),
                "amount": float(amount)
            }
            for date_obj, amount in daily_totals.items()
        ]
        
        return {
            "daily_trends": daily_trends,
            "category_trends": {cat.value: float(amount) for cat, amount in analytics.get_category_totals().items()},
            "spending_patterns": {
                "trend": trends.get('trend', 'STABLE'),
                "recent_average": float(trends.get('recent_average', 0)),
                "overall_average": float(trends.get('overall_average', 0))
            },
            "predictions": {}
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
        
        total_amount = sum(float(expense.amount) for expense in manager.expenses)
        
        # Category breakdown
        category_totals = {}
        for expense in manager.expenses:
            cat = expense.category.value
            category_totals[cat] = category_totals.get(cat, 0) + float(expense.amount)
        
        # Daily breakdown
        daily_totals = {}
        for expense in manager.expenses:
            day = expense.date.date().isoformat()
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
                "id": f"exp_{i}_{int(expense.date.timestamp())}",
                "amount": float(expense.amount),
                "category": expense.category.value,
                "description": expense.description,
                "expense_date": expense.date.isoformat(),
                "currency": getattr(expense, 'currency', 'VND')
            }
            for i, expense in enumerate(manager.expenses)
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

@router.get("/analytics/daily/{date_str}")
async def get_daily_analytics(
    date_str: str,
    current_user: User = Depends(get_current_user)
):
    """Get analytics for a specific date"""
    try:
        target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        manager = get_expense_manager(current_user.id)
        
        # Get expenses for the specific date
        daily_expenses = [
            exp for exp in manager.expenses 
            if exp.date.date() == target_date
        ]
        
        total_amount = sum(float(exp.amount) for exp in daily_expenses)
        
        # Category breakdown for the day
        category_breakdown = {}
        for expense in daily_expenses:
            cat = expense.category.value
            category_breakdown[cat] = category_breakdown.get(cat, 0) + float(expense.amount)
        
        return {
            "date": date_str,
            "total_amount": total_amount,
            "expense_count": len(daily_expenses),
            "category_breakdown": category_breakdown,
            "expenses": [
                {
                    "id": f"exp_{i}_{int(exp.date.timestamp())}",
                    "amount": float(exp.amount),
                    "category": exp.category.value,
                    "description": exp.description,
                    "time": exp.date.strftime("%H:%M:%S")
                }
                for i, exp in enumerate(daily_expenses)
            ]
        }
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/monthly/{year}/{month}")
async def get_monthly_analytics(
    year: int,
    month: int,
    current_user: User = Depends(get_current_user)
):
    """Get analytics for a specific month"""
    try:
        manager = get_expense_manager(current_user.id)
        
        # Get expenses for the specific month
        monthly_expenses = [
            exp for exp in manager.expenses 
            if exp.date.year == year and exp.date.month == month
        ]
        
        total_amount = sum(float(exp.amount) for exp in monthly_expenses)
        
        # Daily breakdown for the month
        daily_breakdown = {}
        for expense in monthly_expenses:
            day_key = expense.date.date().isoformat()
            daily_breakdown[day_key] = daily_breakdown.get(day_key, 0) + float(expense.amount)
        
        # Category breakdown for the month
        category_breakdown = {}
        for expense in monthly_expenses:
            cat = expense.category.value
            category_breakdown[cat] = category_breakdown.get(cat, 0) + float(expense.amount)
        
        return {
            "year": year,
            "month": month,
            "total_amount": total_amount,
            "expense_count": len(monthly_expenses),
            "daily_breakdown": daily_breakdown,
            "category_breakdown": category_breakdown,
            "average_daily": total_amount / max(1, len(set(exp.date.date() for exp in monthly_expenses)))
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/category/{category}")
async def get_category_analytics(
    category: ExpenseCategory,
    current_user: User = Depends(get_current_user)
):
    """Get analytics for a specific category"""
    try:
        manager = get_expense_manager(current_user.id)
        
        # Get expenses for the specific category
        category_expenses = [
            exp for exp in manager.expenses 
            if exp.category == category
        ]
        
        if not category_expenses:
            return {
                "category": category.value,
                "total_amount": 0.0,
                "expense_count": 0,
                "daily_breakdown": {},
                "recent_expenses": []
            }
        
        total_amount = sum(float(exp.amount) for exp in category_expenses)
        
        # Daily breakdown for the category
        daily_breakdown = {}
        for expense in category_expenses:
            day_key = expense.date.date().isoformat()
            daily_breakdown[day_key] = daily_breakdown.get(day_key, 0) + float(expense.amount)
        
        # Get recent expenses (last 10)
        recent_expenses = sorted(category_expenses, key=lambda x: x.date, reverse=True)[:10]
        
        return {
            "category": category.value,
            "total_amount": total_amount,
            "expense_count": len(category_expenses),
            "daily_breakdown": daily_breakdown,
            "average_amount": total_amount / len(category_expenses),
            "recent_expenses": [
                {
                    "id": f"exp_{i}_{int(exp.date.timestamp())}",
                    "amount": float(exp.amount),
                    "description": exp.description,
                    "date": exp.date.isoformat()
                }
                for i, exp in enumerate(recent_expenses)
            ]
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

    