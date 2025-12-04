from fastapi import APIRouter, HTTPException, Depends, Query, status
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, Field
import sys
import os

from app.services.annalytics_service import (
    ExpenseManager, Expense, Budget, Trip
)
from app.services.activities_management import (
    ActivityManager, Activity, ActivityType
)
from app.core.dependencies import get_current_user
from app.models.user import User

router = APIRouter(prefix="/expenses", tags=["expenses"])

# Pydantic Models for Request/Response
class ExpenseCreateRequest(BaseModel):
    amount: float = Field(..., gt=0, description="Expense amount (must be positive)")
    category: ActivityType  = Field(..., description="Expense category")
    description: str = Field("", max_length=500, description="Optional expense description")
    expense_date: Optional[datetime] = Field(None, description="Expense date (defaults to now)")
    planner_id: Optional[str] = Field(None, description="Trip/Planner ID to associate expense with")

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

# Import database manager
from app.database import db_manager

# Remove in-memory expense managers - everything is now in SQLite database
# expense_managers: dict = {} - REMOVED
# def get_expense_manager() - REMOVED

# Trip Management Endpoints - Now use SQLite database
@router.get("/trip/current", response_model=TripResponse)
async def get_current_trip(
    current_user: User = Depends(get_current_user)
):
    """Get the current active trip for the user (SQLite database)"""
    try:
        # Get user's trips from database
        trips = db_manager.get_user_trips(current_user.id)
        
        if not trips:
            raise HTTPException(
                status_code=404, 
                detail="No trips found. Please create a trip first."
            )
        
        # Get the most recent active trip
        active_trip = next((trip for trip in trips if trip.get('is_active', True)), trips[0])
        
        start_date = date.fromisoformat(active_trip['start_date'])
        end_date = date.fromisoformat(active_trip['end_date'])
        today = date.today()
        
        total_days = (end_date - start_date).days + 1
        days_elapsed = max(0, (today - start_date).days)
        days_remaining = max(0, (end_date - today).days)
        is_active = start_date <= today <= end_date
        
        return TripResponse(
            start_date=start_date,
            end_date=end_date,
            total_days=total_days,
            days_remaining=days_remaining,
            days_elapsed=days_elapsed,
            is_active=is_active
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
    """Create a new trip for the user - DEPRECATED: Use /activities/trips instead"""
    try:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="This endpoint is deprecated. Use POST /api/v1/activities/trips instead for trip creation."
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create trip: {str(e)}"
        )

@router.post("/budget/create")
async def create_budget(
    budget_request: BudgetCreateRequest,
    trip_id: Optional[str] = Query(None, description="Trip ID to associate budget with"),
    current_user: User = Depends(get_current_user)
):
    """Create a budget for a specific trip - SIMPLIFIED VERSION"""
    try:
        if not trip_id:
            raise HTTPException(
                status_code=400,
                detail="trip_id is required for budget creation."
            )
        
        # Verify trip exists and belongs to user
        trip = db_manager.get_trip(trip_id, current_user.id)
        if not trip:
            raise HTTPException(
                status_code=404,
                detail="Trip not found or does not belong to user."
            )
        
        # Update trip budget in database
        updates = {"total_budget": budget_request.total_budget}
        updated_trip = db_manager.update_trip(trip_id, current_user.id, updates)
        
        return {
            "message": "Budget created successfully",
            "trip_id": trip_id,
            "budget": {
                "total_budget": budget_request.total_budget,
                "daily_limit": budget_request.daily_limit,
                "trip_name": updated_trip['name'] if updated_trip else None,
                "currency": updated_trip.get('currency', 'VND') if updated_trip else 'VND'
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/budget/trip/{trip_id}", response_model=BudgetStatusResponse)
async def get_trip_budget_status(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get budget status for a specific trip (SQLite database)"""
    try:
        # Get trip and expenses from database
        trip = db_manager.get_trip(trip_id, current_user.id)
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")
        
        trip_expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        
        # Calculate budget statistics
        total_budget = float(trip.get('total_budget', 0))
        total_spent = sum(float(exp['amount']) for exp in trip_expenses)
        
        start_date = date.fromisoformat(trip['start_date'])
        end_date = date.fromisoformat(trip['end_date'])
        today = date.today()
        
        days_total = (end_date - start_date).days + 1
        days_elapsed = max(0, (today - start_date).days + 1)
        days_remaining = max(0, (end_date - today).days)
        
        percentage_used = (total_spent / total_budget * 100) if total_budget > 0 else 0
        remaining_budget = max(0, total_budget - total_spent)
        
        average_daily_spending = total_spent / max(1, days_elapsed)
        recommended_daily_spending = remaining_budget / max(1, days_remaining) if days_remaining > 0 else 0
        
        # Simple burn rate calculation
        if total_budget > 0 and days_total > 0:
            expected_daily = total_budget / days_total
            if average_daily_spending > expected_daily * 1.2:
                burn_rate_status = "OVER_BUDGET"
            elif average_daily_spending > expected_daily * 1.1:
                burn_rate_status = "WARNING"
            else:
                burn_rate_status = "ON_TRACK"
        else:
            burn_rate_status = "ON_TRACK"
        
        return BudgetStatusResponse(
            total_budget=total_budget,
            total_spent=total_spent,
            percentage_used=percentage_used,
            remaining_budget=remaining_budget,
            start_date=start_date,
            end_date=end_date,
            days_remaining=days_remaining,
            days_total=days_total,
            recommended_daily_spending=recommended_daily_spending,
            average_daily_spending=average_daily_spending,
            burn_rate_status=burn_rate_status,
            is_over_budget=total_spent > total_budget,
            category_overruns=[]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Expense Management Endpoints
@router.post("/", response_model=ExpenseResponse)
async def create_expense(
    expense_request: ExpenseCreateRequest,
    trip_id: Optional[str] = Query(None, description="Associate expense with trip"),
    current_user: User = Depends(get_current_user)
):
    """Create a new expense with trip association (SQLite database)"""
    try:
        print(f"💰 EXPENSE_CREATE: User {current_user.id} creating expense")
        print(f"  Amount: {expense_request.amount}")
        print(f"  Category: {expense_request.category}")
        print(f"  Trip ID provided: {trip_id}")
        print(f"  Planner ID in request: {expense_request.planner_id}")
        print(f"  Full request object: {expense_request.__dict__}")
        
        # Validate input
        if expense_request.amount <= 0:
            print(f"❌ VALIDATION_ERROR: Invalid amount {expense_request.amount}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Amount must be greater than 0"
            )
            
        if not expense_request.category:
            print(f"❌ VALIDATION_ERROR: Missing category")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category is required"
            )
        
        # Determine trip_id: prioritize request body planner_id, then query parameter, then fallback
        final_trip_id = expense_request.planner_id or trip_id
            
        if not final_trip_id:
            print(f"📍 TRIP_LOOKUP: No trip_id provided, looking for user trips...")
            # Get user's most recent trip as fallback
            trips = db_manager.get_user_trips(current_user.id)
            print(f"📍 TRIP_LOOKUP: Found {len(trips)} trips for user")
            if not trips:
                print(f"❌ NO_TRIPS: No trips found for user {current_user.id}")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No trips found. Please create a trip first before adding expenses."
                )
            else:
                final_trip_id = trips[0]['id']  # Use most recent trip
                print(f"📝 AUTO_ASSIGN: Using most recent trip {final_trip_id} for expense")
        else:
            print(f"📝 TRIP_ASSIGNED: Using specified trip {final_trip_id} for expense")
        
        # Create expense data
        expense_data = {
            "name": expense_request.description or f"{expense_request.category.value.title()} Expense",
            "amount": float(expense_request.amount),
            "currency": getattr(current_user, 'preferred_currency', 'VND') or 'VND',
            "category": expense_request.category.value,
            "date": (expense_request.expense_date or datetime.now()).isoformat()
        }
        
        # Create expense in database
        print(f"💾 DATABASE_CREATE: Creating expense for trip {final_trip_id}")
        try:
            expense = db_manager.create_expense_for_trip(final_trip_id, current_user.id, expense_data)
            print(f"✅ SUCCESS: Created expense {expense['id']} for trip {final_trip_id}")
        except ValueError as ve:
            print(f"❌ DATABASE_ERROR: {ve}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(ve)
            )
        except Exception as db_error:
            print(f"❌ UNEXPECTED_DB_ERROR: {db_error}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error: {str(db_error)}"
            )
        
        response = ExpenseResponse(
            id=expense["id"],
            amount=float(expense["amount"]),
            category=expense["category"],
            description=expense["name"],
            expense_date=datetime.fromisoformat(expense["date"]),
            currency=expense["currency"]
        )
        
        print(f"🎉 EXPENSE_CREATED: {response.id} - {response.amount} {response.currency}")
        return response
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create expense: {str(e)}"
        )

@router.get("/", response_model=List[ExpenseResponse])
async def get_expenses(
    category: Optional[ActivityType] = Query(None, description="Filter by category"),
    start_date: Optional[date] = Query(None, description="Filter from date"),
    end_date: Optional[date] = Query(None, description="Filter to date"),
    current_user: User = Depends(get_current_user)
):
    """Get all expenses with optional filters (SQLite database)"""
    try:
        # Get expenses from database
        expenses = db_manager.get_user_expenses(
            user_id=current_user.id,
            start_date=start_date.isoformat() if start_date else None,
            end_date=end_date.isoformat() if end_date else None,
            category=category.value if category else None
        )
        
        return [
            ExpenseResponse(
                id=expense["id"],
                amount=float(expense["amount"]),
                category=expense["category"],
                description=expense["name"],
                expense_date=datetime.fromisoformat(expense["date"]),
                currency=expense.get("currency", "VND")
            )
            for expense in expenses
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{expense_id}")
async def delete_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an expense by ID (SQLite database)"""
    try:
        success = db_manager.delete_expense(expense_id, current_user.id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Expense not found or does not belong to user")
        
        print(f"🗑️ EXPENSE_DELETE: User {current_user.id} deleted expense {expense_id}")
        return {"message": "Expense deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Analytics Endpoints
@router.get("/budget/status", response_model=BudgetStatusResponse)
async def get_budget_status(
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get current budget status - DEPRECATED: Use /budget/trip/{trip_id} instead"""
    try:
        if trip_id:
            # Redirect to the new trip-specific endpoint
            return await get_trip_budget_status(trip_id, current_user)
        else:
            # Return default values when no trip specified
            return BudgetStatusResponse(
                total_budget=0.0,
                total_spent=0.0,
                percentage_used=0.0,
                remaining_budget=0.0,
                start_date=date.today(),
                end_date=date.today(),
                days_remaining=0,
                days_total=0,
                recommended_daily_spending=0.0,
                average_daily_spending=0.0,
                burn_rate_status="ON_TRACK",
                is_over_budget=False,
                category_overruns=[]
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/categories/status", response_model=List[CategoryStatusResponse])
async def get_category_status(
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get spending status by category (SQLite database)"""
    try:
        # Get expenses from database
        if trip_id:
            expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        else:
            expenses = db_manager.get_user_expenses(current_user.id)
        
        if not expenses:
            return []
        
        # Calculate category totals
        category_totals = {}
        for expense in expenses:
            category = expense['category']
            amount = float(expense['amount'])
            category_totals[category] = category_totals.get(category, 0) + amount
        
        # Convert to response format
        return [
            CategoryStatusResponse(
                category=category,
                allocated=0.0,  # No allocation data available in simplified version
                spent=spent,
                remaining=0.0,  # No allocation data available
                percentage_used=100.0 if spent > 0 else 0.0,
                is_over_budget=False,  # No budget data to compare
                status="ACTIVE" if spent > 0 else "UNUSED"
            )
            for category, spent in category_totals.items()
        ]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/trends")
async def get_spending_trends(
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get spending trends and patterns (SQLite database)"""
    try:
        # Get expenses from database
        if trip_id:
            expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        else:
            expenses = db_manager.get_user_expenses(current_user.id)
        
        if not expenses:
            return {"daily_trends": [], "category_trends": {}, "spending_patterns": {}, "predictions": {}}
        
        # Calculate daily totals
        daily_totals = {}
        category_totals = {}
        
        for expense in expenses:
            expense_date = datetime.fromisoformat(expense['date']).date()
            amount = float(expense['amount'])
            category = expense['category']
            
            # Daily totals
            day_key = expense_date.isoformat()
            daily_totals[day_key] = daily_totals.get(day_key, 0) + amount
            
            # Category totals
            category_totals[category] = category_totals.get(category, 0) + amount
        
        # Convert to expected format
        daily_trends = [
            {"date": date_str, "amount": amount}
            for date_str, amount in sorted(daily_totals.items())
        ]
        
        # Simple trend analysis
        if len(daily_trends) > 1:
            recent_days = daily_trends[-3:] if len(daily_trends) >= 3 else daily_trends
            overall_average = sum(dt['amount'] for dt in daily_trends) / len(daily_trends)
            recent_average = sum(dt['amount'] for dt in recent_days) / len(recent_days)
            
            if recent_average > overall_average * 1.2:
                trend = "INCREASING"
            elif recent_average < overall_average * 0.8:
                trend = "DECREASING"
            else:
                trend = "STABLE"
        else:
            trend = "STABLE"
            recent_average = daily_trends[0]['amount'] if daily_trends else 0
            overall_average = recent_average
        
        return {
            "daily_trends": daily_trends,
            "category_trends": category_totals,
            "spending_patterns": {
                "trend": trend,
                "recent_average": recent_average,
                "overall_average": overall_average
            },
            "predictions": {}
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/summary")
async def get_expense_summary(
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive expense summary (SQLite database)"""
    try:
        # Get expenses from database
        if trip_id:
            expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        else:
            expenses = db_manager.get_user_expenses(current_user.id)
        
        if not expenses:
            return {
                "total_expenses": 0,
                "total_amount": 0.0,
                "category_breakdown": {},
                "daily_breakdown": {}
            }
        
        total_amount = sum(float(expense['amount']) for expense in expenses)
        
        # Category breakdown
        category_totals = {}
        daily_totals = {}
        
        for expense in expenses:
            amount = float(expense['amount'])
            category = expense['category']
            expense_date = datetime.fromisoformat(expense['date']).date().isoformat()
            
            # Category breakdown
            category_totals[category] = category_totals.get(category, 0) + amount
            
            # Daily breakdown
            daily_totals[expense_date] = daily_totals.get(expense_date, 0) + amount
        
        return {
            "total_expenses": len(expenses),
            "total_amount": total_amount,
            "category_breakdown": category_totals,
            "daily_breakdown": daily_totals
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/export")
async def export_data(
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Export expense data (SQLite database)"""
    try:
        # Get expenses from database
        if trip_id:
            expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        else:
            expenses = db_manager.get_user_expenses(current_user.id)
        
        expenses_data = [
            {
                "id": expense["id"],
                "amount": float(expense["amount"]),
                "category": expense["category"],
                "description": expense["name"],
                "expense_date": expense["date"],
                "currency": expense.get("currency", "VND")
            }
            for expense in expenses
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
            "user_id": current_user.id,
            "trip_id": trip_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/daily/{date_str}")
async def get_daily_analytics(
    date_str: str,
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get analytics for a specific date (SQLite database)"""
    try:
        target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        
        # Get expenses from database
        if trip_id:
            all_expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        else:
            all_expenses = db_manager.get_user_expenses(current_user.id)
        
        # Filter for the specific date
        daily_expenses = [
            exp for exp in all_expenses 
            if datetime.fromisoformat(exp['date']).date() == target_date
        ]
        
        total_amount = sum(float(exp['amount']) for exp in daily_expenses)
        
        # Category breakdown for the day
        category_breakdown = {}
        for expense in daily_expenses:
            category = expense['category']
            amount = float(expense['amount'])
            category_breakdown[category] = category_breakdown.get(category, 0) + amount
        
        return {
            "date": date_str,
            "total_amount": total_amount,
            "expense_count": len(daily_expenses),
            "category_breakdown": category_breakdown,
            "expenses": [
                {
                    "id": exp['id'],
                    "amount": float(exp['amount']),
                    "category": exp['category'],
                    "description": exp['name'],
                    "time": datetime.fromisoformat(exp['date']).strftime("%H:%M:%S")
                }
                for exp in daily_expenses
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
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get analytics for a specific month (SQLite database)"""
    try:
        # Get expenses from database
        if trip_id:
            all_expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        else:
            all_expenses = db_manager.get_user_expenses(current_user.id)
        
        # Filter for the specific month
        monthly_expenses = [
            exp for exp in all_expenses 
            if datetime.fromisoformat(exp['date']).year == year 
            and datetime.fromisoformat(exp['date']).month == month
        ]
        
        total_amount = sum(float(exp['amount']) for exp in monthly_expenses)
        
        # Daily breakdown for the month
        daily_breakdown = {}
        category_breakdown = {}
        unique_dates = set()
        
        for expense in monthly_expenses:
            amount = float(expense['amount'])
            expense_date = datetime.fromisoformat(expense['date']).date()
            category = expense['category']
            
            # Daily breakdown
            day_key = expense_date.isoformat()
            daily_breakdown[day_key] = daily_breakdown.get(day_key, 0) + amount
            unique_dates.add(expense_date)
            
            # Category breakdown
            category_breakdown[category] = category_breakdown.get(category, 0) + amount
        
        return {
            "year": year,
            "month": month,
            "total_amount": total_amount,
            "expense_count": len(monthly_expenses),
            "daily_breakdown": daily_breakdown,
            "category_breakdown": category_breakdown,
            "average_daily": total_amount / max(1, len(unique_dates))
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics/category/{category}")
async def get_category_analytics(
    category: ActivityType,
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get analytics for a specific category (SQLite database)"""
    try:
        # Get expenses from database
        if trip_id:
            all_expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        else:
            all_expenses = db_manager.get_user_expenses(current_user.id)
        
        # Filter for the specific category
        category_expenses = [
            exp for exp in all_expenses 
            if exp['category'] == category.value
        ]
        
        if not category_expenses:
            return {
                "category": category.value,
                "total_amount": 0.0,
                "expense_count": 0,
                "daily_breakdown": {},
                "recent_expenses": []
            }
        
        total_amount = sum(float(exp['amount']) for exp in category_expenses)
        
        # Daily breakdown for the category
        daily_breakdown = {}
        for expense in category_expenses:
            day_key = datetime.fromisoformat(expense['date']).date().isoformat()
            amount = float(expense['amount'])
            daily_breakdown[day_key] = daily_breakdown.get(day_key, 0) + amount
        
        # Get recent expenses (last 10)
        recent_expenses = sorted(category_expenses, 
                               key=lambda x: datetime.fromisoformat(x['date']), 
                               reverse=True)[:10]
        
        return {
            "category": category.value,
            "total_amount": total_amount,
            "expense_count": len(category_expenses),
            "daily_breakdown": daily_breakdown,
            "average_amount": total_amount / len(category_expenses),
            "recent_expenses": [
                {
                    "id": exp['id'],
                    "amount": float(exp['amount']),
                    "description": exp['name'],
                    "date": exp['date']
                }
                for exp in recent_expenses
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Duplicate endpoint removed - using the existing get_expenses endpoint above

# Trip-specific expense endpoints
@router.get("/trip/{trip_id}", response_model=List[ExpenseResponse])
async def get_trip_expenses(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get all expenses for a specific trip (SQLite database)"""
    try:
        trip_expenses = db_manager.get_trip_expenses(trip_id, current_user.id)
        
        return [
            ExpenseResponse(
                id=expense["id"],
                amount=float(expense["amount"]),
                category=expense["category"],
                description=expense["name"],
                expense_date=datetime.fromisoformat(expense["date"]),
                currency=expense.get("currency", "VND")
            )
            for expense in trip_expenses
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/trip/{trip_id}")
async def delete_trip_expenses(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete all expenses associated with a trip (SQLite database)"""
    try:
        deleted_count = db_manager.delete_trip_expenses(trip_id, current_user.id)
        
        print(f"🗑️ EXPENSE_CLEANUP: User {current_user.id} deleted {deleted_count} expenses for trip {trip_id}")
        
        return {
            "message": f"Successfully deleted {deleted_count} expenses for trip {trip_id}",
            "deleted_count": deleted_count,
            "trip_id": trip_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/clear-all")
async def clear_all_expense_data(
    current_user: User = Depends(get_current_user)
):
    """Clear all expense data for the current user (SQLite database)"""
    try:
        # Delete all expenses for the user across all their trips
        with db_manager.get_connection() as conn:
            cursor = conn.execute("""
                DELETE FROM expenses 
                WHERE planner_id IN (SELECT id FROM trips WHERE user_id = ?)
            """, (current_user.id,))
            deleted_count = cursor.rowcount
            conn.commit()
        
        print(f"🧹 CLEAR_ALL: User {current_user.id} cleared {deleted_count} expenses")
        
        return {
            "message": f"All expense data cleared successfully - deleted {deleted_count} expenses",
            "user_id": current_user.id,
            "deleted_count": deleted_count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Health check endpoint
@router.get("/health")
async def health_check():
    """Health check for expenses service (SQLite database)"""
    try:
        # Check database connectivity
        with db_manager.get_connection() as conn:
            cursor = conn.execute("SELECT COUNT(*) FROM expenses")
            total_expenses = cursor.fetchone()[0]
            
            cursor = conn.execute("SELECT COUNT(*) FROM trips")
            total_trips = cursor.fetchone()[0]
        
        return {
            "status": "healthy",
            "service": "expenses",
            "storage": "SQLite database",
            "timestamp": datetime.now().isoformat(),
            "database_stats": {
                "total_expenses": total_expenses,
                "total_trips": total_trips,
                "connection": "ok"
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "service": "expenses",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

    