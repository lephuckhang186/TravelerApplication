from enum import Enum
from typing import List, Optional, Dict, Tuple
from datetime import datetime, date, timedelta
from decimal import Decimal, getcontext
from dataclasses import dataclass
from collections import defaultdict
from app.services.activities_management import ActivityManager, Activity, ActivityType
import json

# Set high precision for financial calculations
getcontext().prec = 10


@dataclass
class Expense:
    """Immutable expense record with proper decimal handling"""
    amount: Decimal
    category: ActivityType
    description: str = ""
    date: datetime = None
    currency: str = "VND"
    date: Optional[datetime] = None
    
    def __post_init__(self):
        if isinstance(self.amount, (int, float)):
            self.amount = Decimal(str(self.amount))
        if self.amount < 0:
            raise ValueError("Expense amount cannot be negative")
        if self.date is None:
            self.date = datetime.now()

@dataclass
class CategoryBudget:
    """Individual category budget allocation"""
    allocated_amount: Decimal
    spent_amount: Decimal = Decimal('0')
    
    @property
    def remaining(self) -> Decimal:
        return self.allocated_amount - self.spent_amount
    
    @property
    def percentage_used(self) -> float:
        if self.allocated_amount == 0:
            return 0.0
        return float((self.spent_amount / self.allocated_amount) * 100)
    
    @property
    def is_over_budget(self) -> bool:
        return self.spent_amount > self.allocated_amount

class Budget:
    """Enhanced budget management with category allocations"""
    def __init__(self, total_budget: Decimal, daily_limit: Optional[Decimal] = None, category_allocations: Optional[Dict[ActivityType, Decimal]] = None):
        if isinstance(total_budget, (int, float)):
            total_budget = Decimal(str(total_budget))
        if total_budget <= 0:
            raise ValueError("Total budget must be positive")
            
        self.total = total_budget
        self.daily_limit = Decimal(str(daily_limit)) if daily_limit else None
        self.category_budgets: Dict[ActivityType, CategoryBudget] = {}
        
        if category_allocations:
            self._set_category_allocations(category_allocations)
        else:
            self._set_default_allocations()
    
    def _set_category_allocations(self, allocations: Dict[ActivityType, Decimal]):
        """Set custom category allocations"""
        total_allocated = sum(Decimal(str(amount)) for amount in allocations.values())
        if total_allocated > self.total:
            raise ValueError(f"Total allocations ({total_allocated}) exceed budget ({self.total})")
        
        for category, amount in allocations.items():
            self.category_budgets[category] = CategoryBudget(Decimal(str(amount)))
    
    def _set_default_allocations(self):
        """Set default percentage-based allocations"""
        default_percentages = {
            ActivityType.FLIGHT: 0,
            ActivityType.ACTIVITY: 0,
            ActivityType.LODGING: 0,
            ActivityType.CAR_RENTAL: 0,
            ActivityType.CONCERT: 0,
            ActivityType.CRUISING: 0,
            ActivityType.DIRECTION: 0,
            ActivityType.FERRY: 0,
            ActivityType.GROUND_TRANSPORTATION: 0,
            ActivityType.MAP: 0,
            ActivityType.MEETING: 0,
            ActivityType.NOTE: 0,
            ActivityType.PARKING: 0,
            ActivityType.RAIL: 0,
            ActivityType.RESTAURANT: 0,
            ActivityType.THEATER: 0,
            ActivityType.TOUR: 0,
            ActivityType.TRANSPORTATION: 0
        }
        
        for category, percentage in default_percentages.items():
            allocation = self.total * Decimal(str(percentage)) / Decimal('100')
            self.category_budgets[category] = CategoryBudget(allocation)
    
    def get_category_budget(self, category: ActivityType) -> CategoryBudget:
        """Get budget information for a specific category"""
        return self.category_budgets.get(category, CategoryBudget(Decimal('0')))
    
    def get_total_allocated(self) -> Decimal:
        """Get total allocated across all categories"""
        return sum(budget.allocated_amount for budget in self.category_budgets.values())
    
    def get_unallocated(self) -> Decimal:
        """Get unallocated budget amount"""
        return self.total - self.get_total_allocated()
     
@dataclass
class BudgetStatus:
    """Comprehensive budget status with enhanced analytics"""
    total_budget: Decimal
    total_spent: Decimal
    percentage_used: float
    days_remaining: int
    days_total: int
    recommended_daily_spending: Decimal
    average_daily_spending: Decimal
    category_overruns: List[ActivityType]
    
    @property
    def remaining_budget(self) -> Decimal:
        return self.total_budget - self.total_spent
    
    @property
    def is_over_budget(self) -> bool:
        return self.total_spent > self.total_budget
    
    @property
    def burn_rate_status(self) -> str:
        """Analyze spending burn rate"""
        if self.days_total == 0 or self.days_remaining <= 0:
            return "COMPLETED"
        
        expected_percentage = ((self.days_total - self.days_remaining) / self.days_total) * 100
        
        if self.percentage_used > expected_percentage * 1.2:
            return "HIGH_BURN"
        elif self.percentage_used > expected_percentage * 1.1:
            return "MODERATE_BURN"
        else:
            return "ON_TRACK"

class Trip:
    """Enhanced trip management with validation"""
    def __init__(self, start_date: date, end_date: date):
        if end_date <= start_date:
            raise ValueError("End date must be after start date")
        
        self.start_date = start_date
        self.end_date = end_date
    
    @property
    def total_days(self) -> int:
        return (self.end_date - self.start_date).days + 1
    
    @property
    def days_remaining(self) -> int:
        today = date.today()
        if self.end_date > today:
            return (self.end_date - today).days
        return 0
    
    @property
    def days_elapsed(self) -> int:
        today = date.today()
        if today < self.start_date:
            return 0
        elif today > self.end_date:
            return self.total_days
        else:
            return (today - self.start_date).days + 1
    
    @property
    def is_active(self) -> bool:
        today = date.today()
        return self.start_date <= today <= self.end_date
    
    def get_date_range(self) -> List[date]:
        """Get all dates in the trip"""
        dates = []
        current = self.start_date
        while current <= self.end_date:
            dates.append(current)
            current += timedelta(days=1)
        return dates
    def __getattribute__(self, name):
        if name in ['start_date', 'end_date']:
            value = super().__getattribute__(name)
            if not isinstance(value, date):
                raise TypeError(f"{name} must be a date object")
            return value
        return object.__getattribute__(self, name)

class Analytics:
    """Advanced analytics engine for expense tracking"""
    def __init__(self, expenses: List[Expense]):
        self.expenses = expenses
        self._expense_cache: Dict[str, any] = {}
    
    def get_expenses_by_category(self) -> Dict[ActivityType, List[Expense]]:
        """Group expenses by category with caching"""
        cache_key = "expenses_by_category"
        if cache_key not in self._expense_cache:
            categorized = defaultdict(list)
            for expense in self.expenses:
                categorized[expense.category].append(expense)
            self._expense_cache[cache_key] = dict(categorized)
        return self._expense_cache[cache_key]
    
    def get_expenses_by_date(self) -> Dict[date, List[Expense]]:
        """Group expenses by date with caching"""
        cache_key = "expenses_by_date"
        if cache_key not in self._expense_cache:
            by_date = defaultdict(list)
            for expense in self.expenses:
                expense_date = expense.date.date()
                by_date[expense_date].append(expense)
            self._expense_cache[cache_key] = dict(by_date)
        return self._expense_cache[cache_key]
    
    def get_category_totals(self) -> Dict[ActivityType, Decimal]:
        """Get total spending by category"""
        totals = defaultdict(lambda: Decimal('0'))
        for expense in self.expenses:
            totals[expense.category] += expense.amount
        return dict(totals)
    
    def get_daily_totals(self) -> Dict[date, Decimal]:
        """Get total spending by date"""
        daily_expenses = self.get_expenses_by_date()
        return {
            day: sum(exp.amount for exp in expenses) 
            for day, expenses in daily_expenses.items()
        }
    
    def get_average_daily_spending(self, trip: Trip) -> Decimal:
        """Calculate average daily spending over elapsed days"""
        if trip.days_elapsed == 0:
            return Decimal('0')
        
        total_spent = sum(expense.amount for expense in self.expenses)
        return total_spent / Decimal(str(trip.days_elapsed))
    
    def get_spending_trends(self, trip: Trip) -> Dict[str, any]:
        """Analyze spending trends and patterns"""
        daily_totals = self.get_daily_totals()
        
        if len(daily_totals) < 2:
            return {"trend": "INSUFFICIENT_DATA"}
        
        # Calculate 3-day moving average
        dates = sorted(daily_totals.keys())
        recent_days = dates[-3:] if len(dates) >= 3 else dates
        recent_avg = sum(daily_totals.get(d, Decimal('0')) for d in recent_days) / len(recent_days)
        
        # Compare with overall average
        overall_avg = self.get_average_daily_spending(trip)
        
        trend = "STABLE"
        if recent_avg > overall_avg * Decimal('1.2'):
            trend = "INCREASING"
        elif recent_avg < overall_avg * Decimal('0.8'):
            trend = "DECREASING"
        
        return {
            "trend": trend,
            "recent_average": recent_avg,
            "overall_average": overall_avg,
            "daily_totals": daily_totals
        }
    
    def invalidate_cache(self):
        """Clear analytics cache when expenses are modified"""
        self._expense_cache.clear()

class ExpenseManager:
    """Enhanced expense manager with comprehensive budget tracking"""
    def __init__(self):
        self.trip_budget: Optional[Budget] = None
        self.expenses: List[Expense] = []
        self.analytics: Optional[Analytics] = None
        self.trip: Optional[Trip] = None
        self._activity_expense_map: Dict[str, List[Expense]] = {}  # Fix: Initialize missing attribute
    
    def set_trip(self, trip: Trip):
        """Set the current trip"""
        self.trip = trip
        if self.analytics is None:
            self.analytics = Analytics(self.expenses)
    
    def set_budget(self, budget: Budget):
        """Set the budget for the current trip"""
        self.trip_budget = budget
        if self.analytics is None:
            self.analytics = Analytics(self.expenses)
    
    def create_budget_plan(self, trip: Trip, budget: Budget):
        """Initialize trip with budget plan"""
        self.trip = trip
        self.trip_budget = budget
        self.analytics = Analytics(self.expenses)
    
    def add_expense(self, expense: Expense) -> str:
        """Add expense with proper validation and budget tracking"""
        # Generate unique ID for expense  
        from datetime import datetime
        expense_id = f"exp_{len(self.expenses) + 1}_{int(datetime.now().timestamp())}"
        
        self.expenses.append(expense)
        
        # Update category budget spending
        if self.trip_budget:
            category_budget = self.trip_budget.get_category_budget(expense.category)
            category_budget.spent_amount += expense.amount
        
        # Invalidate analytics cache
        if self.analytics:
            self.analytics.expenses = self.expenses
            self.analytics.invalidate_cache()
        
        return expense_id
    
    def remove_expense(self, expense: Expense) -> bool:
        """Remove expense and update budget tracking"""
        if expense in self.expenses:
            self.expenses.remove(expense)
            
            # Update category budget spending
            if self.trip_budget:
                category_budget = self.trip_budget.get_category_budget(expense.category)
                category_budget.spent_amount = max(Decimal('0'), 
                                                 category_budget.spent_amount - expense.amount)
            
            # Invalidate analytics cache
            if self.analytics:
                self.analytics.expenses = self.expenses
                self.analytics.invalidate_cache()
            
            return True
        return False
    
    def get_total_spent(self) -> Decimal:
        """Get total amount spent across all categories"""
        return sum(expense.amount for expense in self.expenses)
    
    def get_category_spending(self, category: ActivityType) -> Decimal:
        """Get total spending for a specific category"""
        return sum(exp.amount for exp in self.expenses if exp.category == category)
    
    def get_expenses(self, category: Optional[ActivityType] = None, 
                   start_date: Optional[date] = None, 
                   end_date: Optional[date] = None) -> Dict[str, Expense]:
        """Get expenses with optional filters"""
        filtered_expenses = self.expenses
        
        if category:
            filtered_expenses = [exp for exp in filtered_expenses if exp.category == category]
        
        if start_date:
            filtered_expenses = [exp for exp in filtered_expenses if exp.date.date() >= start_date]
        
        if end_date:
            filtered_expenses = [exp for exp in filtered_expenses if exp.date.date() <= end_date]
        
        # Return as dictionary with generated IDs
        return {
            f"exp_{i}_{int(exp.date.timestamp())}": exp 
            for i, exp in enumerate(filtered_expenses)
        }
    
    def get_budget_status(self) -> Optional[BudgetStatus]:
        """Generate comprehensive budget status report"""
        if not self.trip_budget or not self.trip:
            return None
        
        total_spent = self.get_total_spent()
        percentage_used = float((total_spent / self.trip_budget.total) * 100) if self.trip_budget.total > 0 else 0.0
        
        # Find category overruns
        category_overruns = [
            category for category in ActivityType
            if self.trip_budget.get_category_budget(category).is_over_budget
        ]
        
        # Calculate recommended daily spending
        remaining_budget = self.trip_budget.total - total_spent
        recommended_daily = (remaining_budget / Decimal(str(self.trip.days_remaining)) 
                           if self.trip.days_remaining > 0 else Decimal('0'))
        
        # Calculate average daily spending
        average_daily = (self.analytics.get_average_daily_spending(self.trip) 
                        if self.analytics else Decimal('0'))
        
        return BudgetStatus(
            total_budget=self.trip_budget.total,
            total_spent=total_spent,
            percentage_used=percentage_used,
            days_remaining=self.trip.days_remaining,
            days_total=self.trip.total_days,
            recommended_daily_spending=recommended_daily,
            average_daily_spending=average_daily,
            category_overruns=category_overruns
        )
    
    def get_category_status(self) -> Dict[ActivityType, Dict[str, any]]:
        """Get detailed status for each budget category"""
        if not self.trip_budget:
            return {}
        
        status = {}
        for category in ActivityType:
            budget = self.trip_budget.get_category_budget(category)
            spent = self.get_category_spending(category)
            
            status[category] = {
                'allocated': budget.allocated_amount,
                'spent': spent,
                'remaining': budget.remaining,
                'percentage_used': budget.percentage_used,
                'is_over_budget': budget.is_over_budget,
                'status': 'OVER_BUDGET' if budget.is_over_budget 
                         else 'WARNING' if budget.percentage_used > 80 
                         else 'OK'
            }
        
        return status
    
    def get_expense_history(self, category_filter: Optional[ActivityType] = None,
                           date_range: Optional[Tuple[date, date]] = None) -> List[Expense]:
        """Get filtered expense history"""
        filtered_expenses = self.expenses
        
        if category_filter:
            filtered_expenses = [exp for exp in filtered_expenses if exp.category == category_filter]
        
        if date_range:
            start_date, end_date = date_range
            filtered_expenses = [
                exp for exp in filtered_expenses 
                if start_date <= exp.date.date() <= end_date
            ]
        
        return sorted(filtered_expenses, key=lambda x: x.date, reverse=True)
    
    def delete_expense(self, expense_id: str) -> bool:
        """Delete expense by ID"""
        # Simple implementation - in production use proper ID mapping
        if self.expenses:
            # Remove the first expense (simplified for demo)
            removed_expense = self.expenses.pop(0)
            
            # Update category budget spending
            if self.trip_budget:
                category_budget = self.trip_budget.get_category_budget(removed_expense.category)
                category_budget.spent_amount = max(Decimal('0'), 
                                                 category_budget.spent_amount - removed_expense.amount)
            
            # Invalidate analytics cache
            if self.analytics:
                self.analytics.expenses = self.expenses
                self.analytics.invalidate_cache()
            
            return True
        return False
    
    def get_analytics(self) -> Optional[Analytics]:
        """Get analytics instance"""
        if self.analytics is None and self.expenses:
            self.analytics = Analytics(self.expenses)
        return self.analytics
    
    def sync_activity_to_expense(self, activity: Activity) -> Optional[str]:
        """Sync activity to expense and return expense ID"""
        if not activity.budget or not activity.budget.actual_cost:
            return None
        
        # Create expense from activity
        expense = Expense(
            amount=activity.budget.actual_cost,
            category=activity.activity_type,
            description=f"{activity.name} [Activity: {activity.id}]",
            date=activity.start_time or datetime.now()
        )
        
        # Add expense
        expense_id = self.add_expense(expense)
        
        # Map activity to expense
        self._activity_expense_map[activity.id] = expense_id
        
        return expense_id
    
    def _map_activity_type_to_expense_category(self, activity_type: ActivityType) -> ActivityType:
        """Map activity type to expense category"""
        return activity_type  # Direct mapping for now
    
    def export_data(self) -> Dict[str, any]:
        """Export all data for persistence or analysis"""
        return {
            'trip': {
                'start_date': self.trip.start_date.isoformat() if self.trip else None,
                'end_date': self.trip.end_date.isoformat() if self.trip else None
            },
            'budget': {
                'total': str(self.trip_budget.total) if self.trip_budget else None,
                'daily_limit': str(self.trip_budget.daily_limit) if self.trip_budget and self.trip_budget.daily_limit else None,
                'category_allocations': {
                    category.value: str(budget.allocated_amount)
                    for category, budget in self.trip_budget.category_budgets.items()
                } if self.trip_budget else {}
            },
            'expenses': [
                {
                    'amount': str(exp.amount),
                    'category': exp.category.value,
                    'date': exp.date.isoformat(),
                    'description': exp.description,
                    'currency': exp.currency
                }
                for exp in self.expenses
            ]
        }
    
    def get_history_expenses(self) -> List[Expense]:
        """Get all historical expenses sorted by date"""
        return sorted(self.expenses, key=lambda x: x.date, reverse=True)
    
    def _map_activity_type_to_expense_category(self, activity_type):
        """Map activity type to expense category"""
        return activity_type  # Simple mapping for now
    
    def sync_activity_to_expense(self, activity) -> Optional[str]:
        """Sync activity to expense tracking"""
        if not activity.budget or not activity.budget.actual_cost:
            return None
            
        # Create expense from activity
        expense = Expense(
            amount=activity.budget.actual_cost,
            category=activity.activity_type,
            description=f"Expense for {activity.name}",
            currency=activity.budget.currency,
            date=datetime.now()
        )
        
        expense_id = self.add_expense(expense)
        
        # Map activity to expense
        if activity.id not in self._activity_expense_map:
            self._activity_expense_map[activity.id] = []
        self._activity_expense_map[activity.id].append(expense)
        
        return expense_id


class IntegratedTravelManager:
    """Integrated manager combining activity and expense management"""
    
    def __init__(self):
        from .activities_management import ActivityManager
        self.activity_manager = ActivityManager()
        self.expense_manager = ExpenseManager()
    
    def get_activity_expense_summary(self, trip_id: str = None) -> dict:
        """Get summary of activities and their associated expenses"""
        activities = list(self.activity_manager.activities.values())
        if trip_id:
            activities = [a for a in activities if getattr(a, 'trip_id', None) == trip_id]
        
        total_estimated_cost = sum(
            float(a.expected_cost or 0) for a in activities 
        )
        total_actual_cost = sum(
            float(a.real_cost or 0) for a in activities
        )
        synced_activities = len([
            a for a in activities 
            if a.id in self.expense_manager._activity_expense_map
        ])
        
        summary = {
            'total_activities': len(activities),
            'synced_activities': synced_activities,
            'unsynced_activities': len(activities) - synced_activities,
            'total_estimated_cost': total_estimated_cost,
            'total_actual_cost': total_actual_cost,
            'budget_variance': total_actual_cost - total_estimated_cost,
            'budget_status': None,
            'category_status': None
        }
        
        activities_detail = []
        for activity in activities:
            activity_expenses = self.expense_manager._activity_expense_map.get(activity.id, [])
            activity_cost = sum(float(exp.amount) for exp in activity_expenses)
            
            activities_detail.append({
                'id': activity.id,
                'title': activity.name,
                'type': activity.activity_type.value if hasattr(activity.activity_type, 'value') else str(activity.activity_type),
                'status': activity.status.value if hasattr(activity.status, 'value') else str(activity.status),
                'expense_count': len(activity_expenses),
                'total_cost': activity_cost,
                'estimated_cost': float(activity.expected_cost or 0),
                'actual_cost': float(activity.real_cost or 0),
                'has_expense': len(activity_expenses) > 0,
                'expense_category': activity.activity_type.value if hasattr(activity.activity_type, 'value') else str(activity.activity_type)
            })
        
        return {
            'summary': summary,
            'activities': activities_detail
        }
    
    def create_activity_with_expense(self, title: str, activity_type, created_by: str, 
                                   estimated_cost=None, actual_cost=None, **kwargs):
        """Create an activity with expense tracking"""
        from .activities_management import Activity
        import uuid
        from datetime import datetime, date
        
        # Create activity with proper field mapping
        activity_kwargs = {
            'name': title,
            'activity_type': activity_type,
            'created_by': created_by,
            'start_date': kwargs.get('start_time', datetime.now()).date() if kwargs.get('start_time') else date.today(),
            'end_date': kwargs.get('end_time', datetime.now()).date() if kwargs.get('end_time') else date.today(),
            'id': str(uuid.uuid4()),
            'created_at': datetime.now(),
            'updated_at': datetime.now()
        }
        
        # Add optional fields if provided
        if kwargs.get('details'):
            activity_kwargs['details'] = kwargs['details']
        if kwargs.get('status'):
            activity_kwargs['status'] = kwargs['status']
        if kwargs.get('priority'):
            activity_kwargs['priority'] = kwargs['priority']
        if kwargs.get('start_time'):
            activity_kwargs['start_time'] = kwargs['start_time']
        if kwargs.get('end_time'):
            activity_kwargs['end_time'] = kwargs['end_time']
        if kwargs.get('trip_id'):
            activity_kwargs['trip_id'] = kwargs['trip_id']
        if kwargs.get('notes'):
            activity_kwargs['notes'] = kwargs['notes']
        if kwargs.get('tags'):
            activity_kwargs['tags'] = kwargs['tags']
        if kwargs.get('check_in') is not None:
            activity_kwargs['check_in'] = kwargs['check_in']
        if estimated_cost:
            activity_kwargs['expected_cost'] = estimated_cost
        if actual_cost:
            activity_kwargs['real_cost'] = actual_cost
        if kwargs.get('currency'):
            activity_kwargs['currency'] = kwargs['currency']
        
        # Handle location
        if kwargs.get('location'):
            from .activities_management import Location
            loc_data = kwargs['location']
            activity_kwargs['location'] = Location(**loc_data)
            
        # Handle contact
        if kwargs.get('contact'):
            from .activities_management import Contact
            contact_data = kwargs['contact']
            activity_kwargs['contact'] = Contact(**contact_data)
            
        # Handle budget
        if estimated_cost or actual_cost:
            from .activities_management import Budget
            activity_kwargs['budget'] = Budget(
                estimated_cost=estimated_cost or Decimal('0'),
                actual_cost=actual_cost,
                currency=kwargs.get('currency', 'VND')
            )
        
        # Create activity
        activity = Activity(**activity_kwargs)
        
        # Add to manager
        self.activity_manager.activities[activity.id] = activity
        
        return activity
    
    def update_activity_with_expense_sync(self, activity_id: str, **updates):
        """Update activity with expense sync"""
        activity = self.activity_manager.activities.get(activity_id)
        if not activity:
            return None
            
        # Update fields
        for key, value in updates.items():
            if hasattr(activity, key):
                setattr(activity, key, value)
        
        activity.updated_at = datetime.now()
        return activity
    
    def delete_activity_with_expense_sync(self, activity_id: str) -> bool:
        """Delete activity with expense sync"""
        if activity_id in self.activity_manager.activities:
            del self.activity_manager.activities[activity_id]
            # Remove from expense mapping if exists
            if activity_id in self.expense_manager._activity_expense_map:
                del self.expense_manager._activity_expense_map[activity_id]
            return True
        return False
    
    def set_activity_actual_cost(self, activity_id: str, actual_cost: Decimal, currency: str = "VND") -> bool:
        """Set actual cost for activity"""
        activity = self.activity_manager.activities.get(activity_id)
        if not activity:
            return False
            
        activity.real_cost = actual_cost
        activity.currency = currency
        
        # Update budget if exists
        if activity.budget:
            activity.budget.actual_cost = actual_cost
            activity.budget.currency = currency
        
        activity.updated_at = datetime.now()
        return True
    
    def setup_trip_with_budget(self, start_date: date, end_date: date, 
                             total_budget: Decimal, category_allocations=None):
        """Setup trip with budget"""
        trip = Trip(start_date=start_date, end_date=end_date)
        budget = Budget(total_budget=total_budget, category_allocations=category_allocations)
        
        self.expense_manager.set_trip(trip)
        self.expense_manager.set_budget(budget)
        
        return trip