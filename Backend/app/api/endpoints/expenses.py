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
    planner_id: Optional[str] = None  # Add planner_id field
    budget_warning: Optional[dict] = None  # Add budget warning info
    
    class Config:
        from_attributes = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class BudgetCreateRequest(BaseModel):
    total_budget: float = Field(..., gt=0)
    daily_limit: Optional[float] = Field(None, gt=0)
    category_allocations: Optional[dict] = None
    trip_id: Optional[str] = Field(None, description="Trip ID to associate budget with")

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

# Import Firebase service
from app.services.firebase_service import firebase_service

# Trip Management Endpoints - Now use Firebase Firestore
@router.get("/trip/current", response_model=TripResponse)
async def get_current_trip(
    current_user: User = Depends(get_current_user)
):
    """Get the current active trip for the user (Firebase Firestore)"""
    try:
        # Get user's trips from Firestore
        trips = await firebase_service.get_user_trips(current_user.id)
        
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
async def create_trip_endpoint(
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
    trip_id: Optional[str] = Query(None, description="Trip ID to associate budget with (query param)"),
    current_user: User = Depends(get_current_user)
):
    """Create a budget for a specific trip - accepts trip_id from query param or request body"""
    try:
        # Accept trip_id from either query parameter or request body
        final_trip_id = trip_id or budget_request.trip_id
        
        print(f"💰 BUDGET_CREATE: User {current_user.id} creating budget")
        print(f"   Trip ID (query): {trip_id}")
        print(f"   Trip ID (body): {budget_request.trip_id}")
        print(f"   Final Trip ID: {final_trip_id}")
        print(f"   Total Budget: {budget_request.total_budget}")
        print(f"   Request body full: {budget_request.dict()}")
        
        if not final_trip_id:
            print(f"⚠️ BUDGET_CREATE_WARNING: No trip_id provided, attempting to find user's latest trip")
            
            # Try to get user's most recent trip as fallback
            try:
                from app.services.firebase_service import firebase_service
                
                # Get all user trips
                user_ref = firebase_service.db.collection('users').document(current_user.id)
                trips_ref = user_ref.collection('trips')
                trips_query = trips_ref.order_by('created_at', direction='DESCENDING').limit(1)
                trips_docs = trips_query.stream()
                
                latest_trip = None
                for doc in trips_docs:
                    latest_trip = doc
                    break
                
                if latest_trip:
                    final_trip_id = latest_trip.id
                    print(f"✅ AUTO_DETECTED: Using latest trip {final_trip_id}")
                else:
                    print(f"❌ BUDGET_CREATE_ERROR: No trips found for user")
                    raise HTTPException(
                        status_code=400,
                        detail="trip_id is required for budget creation. Please provide trip_id or create a trip first."
                    )
            except HTTPException:
                raise
            except Exception as e:
                print(f"❌ BUDGET_CREATE_ERROR: Could not auto-detect trip: {e}")
                raise HTTPException(
                    status_code=400,
                    detail="trip_id is required for budget creation (provide in query param or request body)."
                )
        
        # Verify trip exists and belongs to user
        print(f"🔍 Checking if trip {final_trip_id} exists for user {current_user.id}")
        trip = await firebase_service.get_trip(final_trip_id, current_user.id)
        if not trip:
            print(f"❌ BUDGET_CREATE_ERROR: Trip {final_trip_id} not found")
            raise HTTPException(
                status_code=404,
                detail="Trip not found or does not belong to user."
            )
        
        print(f"✅ Trip found: {trip.get('name')}")
        
        # Update trip budget in Firestore
        updates = {"total_budget": budget_request.total_budget}
        print(f"💾 Updating trip budget in Firestore...")
        updated_trip = await firebase_service.update_trip(final_trip_id, current_user.id, updates)
        
        print(f"✅ BUDGET_CREATED: Budget {budget_request.total_budget} VND for trip {final_trip_id}")
        
        return {
            "message": "Budget created successfully",
            "trip_id": final_trip_id,
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
        print(f"❌ BUDGET_CREATE_ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/budget/trip/{trip_id}", response_model=BudgetStatusResponse)
async def get_trip_budget_status(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get budget status for a specific trip (Firebase Firestore)"""
    try:
        # Get trip and expenses from Firestore
        trip = await firebase_service.get_trip(trip_id, current_user.id)
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")
        
        trip_expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        
        # Calculate budget statistics - handle both storage formats
        total_budget = 0.0
        if 'total_budget' in trip:
            total_budget = float(trip.get('total_budget', 0))
        elif 'budget' in trip and isinstance(trip['budget'], dict):
            total_budget = float(trip['budget'].get('estimated_cost', 0))
        total_spent = sum(float(exp['amount']) for exp in trip_expenses)
        
        # Parse dates - handle both ISO format with time and date-only format
        start_date_str = trip['start_date']
        end_date_str = trip['end_date']
        
        # Remove time component if present (handle .000 milliseconds)
        if 'T' in start_date_str:
            start_date_str = start_date_str.split('T')[0]
        if 'T' in end_date_str:
            end_date_str = end_date_str.split('T')[0]
        
        start_date = date.fromisoformat(start_date_str)
        end_date = date.fromisoformat(end_date_str)
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
    """Create a new expense with trip association (Firebase Firestore)"""
    try:
        print(f"💰 EXPENSE_CREATE: User {current_user.id} creating expense")
        print(f"   Amount: {expense_request.amount}")
        print(f"   Category: {expense_request.category}")
        print(f"   Description: {expense_request.description}")
        print(f"   Trip ID (query): {trip_id}")
        print(f"   Planner ID (body): {expense_request.planner_id}")
        
        # Validate input
        if expense_request.amount <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Amount must be greater than 0"
            )
            
        if not expense_request.category:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category is required"
            )
        
        # Determine trip_id
        final_trip_id = expense_request.planner_id or trip_id
            
        if not final_trip_id:
            trips = await firebase_service.get_user_trips(current_user.id)
            if not trips:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No trips found. Please create a trip first before adding expenses."
                )
            final_trip_id = trips[0]['id']
        
        # Create expense data
        expense_data = {
            "name": expense_request.description or f"{expense_request.category.value.title()} Expense",
            "amount": float(expense_request.amount),
            "currency": getattr(current_user, 'preferred_currency', 'VND') or 'VND',
            "category": expense_request.category.value,
            "date": (expense_request.expense_date or datetime.now()).isoformat()
        }
        
        # Create expense in Firestore
        print(f"💾 FIRESTORE_SAVE: Saving expense to trip {final_trip_id}")
        print(f"   Expense data: {expense_data}")
        try:
            expense = await firebase_service.create_expense(final_trip_id, expense_data)
            print(f"✅ SUCCESS: Created expense {expense['id']}")
            print(f"   Amount: {expense['amount']} {expense['currency']}")
            print(f"   Category: {expense['category']}")
            print(f"   Trip: {final_trip_id}")
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
        
        # Check budget after creating expense
        budget_warning = None
        try:
            trip = await firebase_service.get_trip(final_trip_id, current_user.id)

            # Get budget value - handle both storage formats
            # Regular trips: 'total_budget' field
            # Shared trips: 'budget.estimated_cost' sub-object
            total_budget = 0.0
            if trip:
                if 'total_budget' in trip:
                    total_budget = float(trip.get('total_budget', 0))
                elif 'budget' in trip and isinstance(trip['budget'], dict):
                    total_budget = float(trip['budget'].get('estimated_cost', 0))
            
            # Get all expenses for this trip
            trip_expenses = await firebase_service.get_trip_expenses(final_trip_id, current_user.id)
            total_spent = sum(float(exp['amount']) for exp in trip_expenses)
            
            percentage_used = (total_spent / total_budget * 100) if total_budget > 0 else 100.0
            
            print(f"📊 BUDGET_CHECK: Total budget: {total_budget}, Total spent: {total_spent}, Percentage: {percentage_used:.1f}%")
            
            # Check for overbudget
            if total_budget == 0:
                # No budget set - warn user to set budget
                budget_warning = {
                    "type": "NO_BUDGET",
                    "message": f"Chưa đặt ngân sách cho chuyến đi! Đã chi tiêu {total_spent:,.0f} {expense['currency']}",
                    "total_budget": 0.0,
                    "total_spent": total_spent,
                    "percentage_used": 0.0
                }
                print(f"⚠️ NO_BUDGET: Spent {total_spent} but no budget set")
            elif total_spent > total_budget:
                overage = total_spent - total_budget
                budget_warning = {
                    "type": "OVER_BUDGET",
                    "message": f"Vượt ngân sách {overage:,.0f} {expense['currency']}!",
                    "total_budget": total_budget,
                    "total_spent": total_spent,
                    "percentage_used": percentage_used,
                    "overage": overage
                }
                print(f"⚠️ OVER_BUDGET: Spent {total_spent} / Budget {total_budget} (vượt {overage})")
            elif percentage_used >= 80:
                remaining = total_budget - total_spent
                budget_warning = {
                    "type": "WARNING",
                    "message": f"Sắp hết ngân sách! Còn {remaining:,.0f} {expense['currency']}",
                    "total_budget": total_budget,
                    "total_spent": total_spent,
                    "percentage_used": percentage_used,
                    "remaining": remaining
                }
                print(f"⚠️ BUDGET_WARNING: {percentage_used:.1f}% used, remaining: {remaining}")
            else:
                print(f"✅ BUDGET_OK: {percentage_used:.1f}% used")
        except Exception as budget_check_error:
            print(f"⚠️ BUDGET_CHECK_ERROR: {budget_check_error}")
            import traceback
            traceback.print_exc()
            # Don't fail expense creation if budget check fails
        
        response = ExpenseResponse(
            id=expense["id"],
            amount=float(expense["amount"]),
            category=expense["category"],
            description=expense["name"],
            expense_date=datetime.fromisoformat(expense["date"]),
            currency=expense["currency"],
            planner_id=final_trip_id,
            budget_warning=budget_warning
        )
        
        print(f"🎉 EXPENSE_CREATED: {response.id} - {response.amount} {response.currency}")
        if budget_warning:
            print(f"   ⚠️ BUDGET_ALERT: {budget_warning['type']} - {budget_warning['message']}")
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
    planner_id: Optional[str] = Query(None, description="Filter by trip/planner ID"),
    current_user: User = Depends(get_current_user)
):
    """Get all expenses with optional filters (Firebase Firestore)"""
    try:
        print(f"📋 GET_EXPENSES: user={current_user.id}, planner_id={planner_id}, start_date={start_date}, end_date={end_date}")
        
        # Get expenses from Firestore - filter by trip if planner_id provided
        if planner_id:
            print(f"🔍 FILTER_BY_TRIP: Loading expenses for trip {planner_id}")
            expenses = await firebase_service.get_trip_expenses(planner_id, current_user.id)
            print(f"✅ TRIP_EXPENSES: Found {len(expenses)} expenses for trip {planner_id}")
        else:
            print(f"🔍 ALL_EXPENSES: Loading all user expenses (no trip filter)")
            expenses = await firebase_service.get_user_expenses(
                user_id=current_user.id,
                start_date=start_date.isoformat() if start_date else None,
                end_date=end_date.isoformat() if end_date else None,
                category=category.value if category else None
            )
            print(f"✅ USER_EXPENSES: Found {len(expenses)} total expenses")
        
        # Apply additional filters if needed
        filtered_expenses = expenses
        
        # Filter by date range if provided and not already filtered by trip
        if not planner_id and (start_date or end_date):
            filtered_expenses = [
                exp for exp in expenses
                if (not start_date or datetime.fromisoformat(exp["date"]).date() >= start_date) and
                   (not end_date or datetime.fromisoformat(exp["date"]).date() <= end_date)
            ]
            print(f"📅 DATE_FILTER: {len(filtered_expenses)} expenses after date filtering")
        
        # Filter by category if provided
        if category:
            filtered_expenses = [exp for exp in filtered_expenses if exp["category"] == category.value]
            print(f"🏷️ CATEGORY_FILTER: {len(filtered_expenses)} expenses after category filtering")
        
        result = [
            ExpenseResponse(
                id=expense["id"],
                amount=float(expense["amount"]),
                category=expense["category"],
                description=expense["name"],
                expense_date=datetime.fromisoformat(expense["date"]),
                currency=expense.get("currency", "VND"),
                planner_id=planner_id if planner_id else None  # Include planner_id in response
            )
            for expense in filtered_expenses
        ]
        
        print(f"🎯 FINAL_RESULT: Returning {len(result)} expenses")
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{expense_id}")
async def delete_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an expense by ID (SQLite database)"""
    try:
        success = await firebase_service.delete_expense(expense_id, current_user.id)
        
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
        print(f"📊 BUDGET_STATUS_REQUEST: trip_id={trip_id}, user={current_user.id}")
        
        if trip_id:
            # Redirect to the new trip-specific endpoint
            return await get_trip_budget_status(trip_id, current_user)
        else:
            # If no trip_id, get first trip
            trips = await firebase_service.get_user_trips(current_user.id)
            if not trips:
                print(f"⚠️ NO_TRIPS: User {current_user.id} has no trips")
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
            trip_id = trips[0]['id']
            print(f"📍 USING_FIRST_TRIP: {trip_id}")
            return await get_trip_budget_status(trip_id, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/categories/status", response_model=List[CategoryStatusResponse])
async def get_category_status(
    trip_id: Optional[str] = Query(None, description="Filter by trip ID"),
    current_user: User = Depends(get_current_user)
):
    """Get spending status by category with proper budget checking"""
    try:
        # Get expenses from Firestore
        if trip_id:
            expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
            # Get trip budget info - handle both storage formats
            trip = await firebase_service.get_trip(trip_id, current_user.id)
            total_budget = 0.0
            if trip:
                if 'total_budget' in trip:
                    total_budget = float(trip.get('total_budget', 0))
                elif 'budget' in trip and isinstance(trip['budget'], dict):
                    total_budget = float(trip['budget'].get('estimated_cost', 0))
        else:
            expenses = await firebase_service.get_user_expenses(current_user.id)
            total_budget = 0.0
        
        if not expenses:
            return []
        
        # Calculate category totals
        category_totals = {}
        for expense in expenses:
            category = expense['category']
            amount = float(expense['amount'])
            category_totals[category] = category_totals.get(category, 0) + amount
        
        # Get total spent across all categories
        total_spent = sum(category_totals.values())
        
        # Calculate per-category allocation (simple equal distribution for now)
        # You can improve this by storing category budgets in the trip document
        num_categories = len(category_totals) if category_totals else 1
        allocated_per_category = total_budget / num_categories if total_budget > 0 else 0.0
        
        # Convert to response format with proper overbudget checking
        result = []
        for category, spent in category_totals.items():
            allocated = allocated_per_category
            remaining = max(0, allocated - spent)
            percentage_used = (spent / allocated * 100) if allocated > 0 else 100.0
            is_over = spent > allocated if allocated > 0 else False
            
            result.append(CategoryStatusResponse(
                category=category,
                allocated=allocated,
                spent=spent,
                remaining=remaining,
                percentage_used=percentage_used,
                is_over_budget=is_over,
                status="OVER_BUDGET" if is_over else "WARNING" if percentage_used > 80 else "ACTIVE" if spent > 0 else "UNUSED"
            ))
        
        return result
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
        # Get expenses from Firestore
        if trip_id:
            expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        else:
            expenses = await firebase_service.get_user_expenses(current_user.id)
        
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
    """Get comprehensive expense summary (Firebase Firestore)"""
    try:
        # Get expenses from Firestore
        if trip_id:
            expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        else:
            expenses = await firebase_service.get_user_expenses(current_user.id)
        
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
        # Get expenses from Firestore
        if trip_id:
            expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        else:
            expenses = await firebase_service.get_user_expenses(current_user.id)
        
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
        
        # Get expenses from Firestore
        if trip_id:
            all_expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        else:
            all_expenses = await firebase_service.get_user_expenses(current_user.id)
        
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
        # Get expenses from Firestore
        if trip_id:
            all_expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        else:
            all_expenses = await firebase_service.get_user_expenses(current_user.id)
        
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
        # Get expenses from Firestore
        if trip_id:
            all_expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        else:
            all_expenses = await firebase_service.get_user_expenses(current_user.id)
        
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
        trip_expenses = await firebase_service.get_trip_expenses(trip_id, current_user.id)
        
        return [
            ExpenseResponse(
                id=expense["id"],
                amount=float(expense["amount"]),
                category=expense["category"],
                description=expense["name"],
                expense_date=datetime.fromisoformat(expense["date"]),
                currency=expense.get("currency", "VND"),
                planner_id=trip_id  # Include the trip ID
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
        deleted_count = await firebase_service.delete_trip_expenses(trip_id, current_user.id)
        
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
        # Delete all user expenses from Firestore
        trips = await firebase_service.get_user_trips(current_user.id)
        deleted_count = 0
        for trip in trips:
            count = await firebase_service.delete_trip_expenses(trip['id'], current_user.id)
            deleted_count += count
        
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
    """Health check for expenses service (Firebase Firestore)"""
    try:
        return {
            "status": "healthy",
            "service": "expenses",
            "storage": "Firebase Firestore",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "service": "expenses",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }
