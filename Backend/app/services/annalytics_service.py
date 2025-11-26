from enum import Enum
from typing import List, Optional, Dict, Tuple
from datetime import datetime, date, timedelta
from decimal import Decimal, getcontext
from dataclasses import dataclass
from collections import defaultdict
import json
from .activities_management import ActivityManager, Activity, ActivityType

# Set high precision for financial calculations
getcontext().prec = 10

class ExpenseCategory(str, Enum):
    TRANSPORTATION = "transportation"
    ACCOMMODATION = "accommodation" 
    FOOD_BEVERAGE = "food_beverage"
    ACTIVITIES = "activities"
    SHOPPING = "shopping"
    MISCELLANEOUS = "miscellaneous"
    EMERGENCY = "emergency"

@dataclass
class Expense:
    """Immutable expense record with proper decimal handling"""
    amount: Decimal
    category: ExpenseCategory
    date: datetime
    description: str = ""
    currency: str = "VND"
    
    def __post_init__(self):
        if isinstance(self.amount, (int, float)):
            self.amount = Decimal(str(self.amount))
        if self.amount < 0:
            raise ValueError("Expense amount cannot be negative")

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
    def __init__(self, total_budget: Decimal, daily_limit: Optional[Decimal] = None, 
                 category_allocations: Optional[Dict[ExpenseCategory, Decimal]] = None):
        if isinstance(total_budget, (int, float)):
            total_budget = Decimal(str(total_budget))
        if total_budget <= 0:
            raise ValueError("Total budget must be positive")
            
        self.total = total_budget
        self.daily_limit = Decimal(str(daily_limit)) if daily_limit else None
        self.category_budgets: Dict[ExpenseCategory, CategoryBudget] = {}
        
        if category_allocations:
            self._set_category_allocations(category_allocations)
        else:
            self._set_default_allocations()
    
    def _set_category_allocations(self, allocations: Dict[ExpenseCategory, Decimal]):
        """Set custom category allocations"""
        total_allocated = sum(Decimal(str(amount)) for amount in allocations.values())
        if total_allocated > self.total:
            raise ValueError(f"Total allocations ({total_allocated}) exceed budget ({self.total})")
        
        for category, amount in allocations.items():
            self.category_budgets[category] = CategoryBudget(Decimal(str(amount)))
    
    def _set_default_allocations(self):
        """Set default percentage-based allocations"""
        default_percentages = {
            ExpenseCategory.ACCOMMODATION: 0,
            ExpenseCategory.FOOD_BEVERAGE: 0,
            ExpenseCategory.TRANSPORTATION: 0,
            ExpenseCategory.ACTIVITIES: 0,
            ExpenseCategory.SHOPPING: 0,
            ExpenseCategory.MISCELLANEOUS: 0,
            ExpenseCategory.EMERGENCY: 0
        }
        
        for category, percentage in default_percentages.items():
            allocation = self.total * Decimal(str(percentage)) / Decimal('100')
            self.category_budgets[category] = CategoryBudget(allocation)
    
    def get_category_budget(self, category: ExpenseCategory) -> CategoryBudget:
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
    category_overruns: List[ExpenseCategory]
    
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
    
    def get_expenses_by_category(self) -> Dict[ExpenseCategory, List[Expense]]:
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
    
    def get_category_totals(self) -> Dict[ExpenseCategory, Decimal]:
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
    """Enhanced expense manager with comprehensive budget tracking and activity integration"""
    def __init__(self, activity_manager: Optional[ActivityManager] = None):
        self.trip_budget: Optional[Budget] = None
        self.expenses: List[Expense] = []
        self.analytics: Optional[Analytics] = None
        self.trip: Optional[Trip] = None
        self.activity_manager = activity_manager or ActivityManager()
        self._activity_expense_map: Dict[str, str] = {}  # activity_id -> expense_id mapping
    
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
        
    def _map_activity_type_to_expense_category(self, activity_type: ActivityType) -> ExpenseCategory:
        """Map activity type to expense category"""
        mapping = {
            ActivityType.TRANSPORTATION: ExpenseCategory.TRANSPORTATION,
            ActivityType.ACCOMMODATION: ExpenseCategory.ACCOMMODATION,
            ActivityType.DINING: ExpenseCategory.FOOD_BEVERAGE,
            ActivityType.SIGHTSEEING: ExpenseCategory.ACTIVITIES,
            ActivityType.ENTERTAINMENT: ExpenseCategory.ACTIVITIES,
            ActivityType.ADVENTURE: ExpenseCategory.ACTIVITIES,
            ActivityType.CULTURAL: ExpenseCategory.ACTIVITIES,
            ActivityType.SHOPPING: ExpenseCategory.SHOPPING,
            ActivityType.BUSINESS: ExpenseCategory.MISCELLANEOUS,
            ActivityType.MEDICAL: ExpenseCategory.EMERGENCY,
            ActivityType.OTHER: ExpenseCategory.MISCELLANEOUS,
        }
        return mapping.get(activity_type, ExpenseCategory.MISCELLANEOUS)
        
    def sync_activity_to_expense(self, activity: Activity) -> Optional[str]:
        """Create or update expense from activity"""
        if not activity.budget or not activity.budget.actual_cost:
            return None
            
        category = self._map_activity_type_to_expense_category(activity.activity_type)
        expense_date = activity.start_date or datetime.now()
        description = f"Activity: {activity.title}"
        
        # Check if expense already exists for this activity
        if activity.id in self._activity_expense_map:
            return self._update_expense_from_activity(activity)
        else:
            return self._create_expense_from_activity(activity)
    
    def _create_expense_from_activity(self, activity: Activity) -> str:
        """Create new expense from activity"""
        if not activity.budget or not activity.budget.actual_cost:
            return ""
            
        category = self._map_activity_type_to_expense_category(activity.activity_type)
        expense_date = activity.start_date or datetime.now()
        description = f"Activity: {activity.title}"
        
        expense = Expense(
            amount=activity.budget.actual_cost,
            category=category,
            date=expense_date,
            description=description,
            currency=activity.budget.currency
        )
        
        expense_id = self.add_expense(expense)
        self._activity_expense_map[activity.id] = expense_id
        return expense_id
    
    def _update_expense_from_activity(self, activity: Activity) -> str:
        """Update existing expense from activity"""
        if activity.id not in self._activity_expense_map:
            return ""
            
        expense_id = self._activity_expense_map[activity.id]
        
        # Find and update the expense
        for i, expense in enumerate(self.expenses):
            if f"exp_{i+1}_{int(expense.date.timestamp())}" == expense_id:
                # Remove old expense
                old_expense = self.expenses.pop(i)
                
                # Update category budget
                if self.trip_budget:
                    old_category_budget = self.trip_budget.get_category_budget(old_expense.category)
                    old_category_budget.spent_amount = max(Decimal('0'), 
                                                         old_category_budget.spent_amount - old_expense.amount)
                
                # Create new expense with updated values
                if activity.budget and activity.budget.actual_cost:
                    category = self._map_activity_type_to_expense_category(activity.activity_type)
                    expense_date = activity.start_date or datetime.now()
                    description = f"Activity: {activity.title}"
                    
                    new_expense = Expense(
                        amount=activity.budget.actual_cost,
                        category=category,
                        date=expense_date,
                        description=description,
                        currency=activity.budget.currency
                    )
                    
                    new_expense_id = self.add_expense(new_expense)
                    self._activity_expense_map[activity.id] = new_expense_id
                    return new_expense_id
                else:
                    # Remove mapping if no budget
                    del self._activity_expense_map[activity.id]
                
                break
        
        return expense_id
    
    def remove_activity_expense(self, activity_id: str) -> bool:
        """Remove expense associated with an activity"""
        if activity_id not in self._activity_expense_map:
            return False
            
        expense_id = self._activity_expense_map[activity_id]
        
        # Find and remove the expense
        for i, expense in enumerate(self.expenses):
            if f"exp_{i+1}_{int(expense.date.timestamp())}" == expense_id:
                removed_expense = self.expenses.pop(i)
                
                # Update category budget
                if self.trip_budget:
                    category_budget = self.trip_budget.get_category_budget(removed_expense.category)
                    category_budget.spent_amount = max(Decimal('0'), 
                                                     category_budget.spent_amount - removed_expense.amount)
                
                # Invalidate analytics cache
                if self.analytics:
                    self.analytics.expenses = self.expenses
                    self.analytics.invalidate_cache()
                
                # Remove mapping
                del self._activity_expense_map[activity_id]
                return True
        
        return False
    
    def sync_all_activities(self, trip_id: Optional[str] = None) -> Dict[str, str]:
        """Sync all activities with expenses"""
        activities = self.activity_manager.get_activities_by_trip(trip_id) if trip_id else list(self.activity_manager.activities.values())
        synced_activities = {}
        
        for activity in activities:
            if activity.budget and activity.budget.actual_cost:
                expense_id = self.sync_activity_to_expense(activity)
                if expense_id:
                    synced_activities[activity.id] = expense_id
        
        return synced_activities
    
    def add_expense(self, expense: Expense) -> str:
        """Add expense with proper validation and budget tracking"""
        # Generate unique ID for expense
        expense_id = f"exp_{len(self.expenses) + 1}_{int(expense.date.timestamp())}"
        
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
    
    def get_category_spending(self, category: ExpenseCategory) -> Decimal:
        """Get total spending for a specific category"""
        return sum(exp.amount for exp in self.expenses if exp.category == category)
    
    def get_expenses(self, category: Optional[ExpenseCategory] = None, 
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
            category for category in ExpenseCategory
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
    
    def get_category_status(self) -> Dict[ExpenseCategory, Dict[str, any]]:
        """Get detailed status for each budget category"""
        if not self.trip_budget:
            return {}
        
        status = {}
        for category in ExpenseCategory:
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
    
    def get_expense_history(self, category_filter: Optional[ExpenseCategory] = None,
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
    
    def print_expense_history(self, category_filter: Optional[ExpenseCategory] = None):
        """Print formatted expense history"""
        expenses = self.get_expense_history(category_filter)
        
        print("\n=== EXPENSE HISTORY ===")
        if category_filter:
            print(f"Category: {category_filter.value.title()}")
        
        if not expenses:
            print("No expenses found.")
            return
        
        total = sum(exp.amount for exp in expenses)
        print(f"Total: {total:,.0f} VND ({len(expenses)} transactions)\n")
        
        for expense in expenses:
            print(f"- {expense.date.strftime('%Y-%m-%d %H:%M')} | "
                  f"{expense.category.value.title()} | "
                  f"{expense.amount:,.0f} VND")
            if expense.description:
                print(f"  Description: {expense.description}")
    
    def print_budget_summary(self):
        """Print comprehensive budget summary"""
        if not self.trip_budget or not self.trip:
            print("No budget plan configured.")
            return
        
        status = self.get_budget_status()
        category_status = self.get_category_status()
        
        print("\n" + "="*50)
        print("BUDGET SUMMARY")
        print("="*50)
        
        print(f"Trip: {self.trip.start_date} to {self.trip.end_date}")
        print(f"Total Budget: {status.total_budget:,.0f} VND")
        print(f"Total Spent: {status.total_spent:,.0f} VND ({status.percentage_used:.1f}%)")
        print(f"Remaining: {status.remaining_budget:,.0f} VND")
        print(f"Days Remaining: {status.days_remaining}")
        print(f"Burn Rate: {status.burn_rate_status}")
        
        if status.days_remaining > 0:
            print(f"Recommended Daily: {status.recommended_daily_spending:,.0f} VND")
            print(f"Average Daily: {status.average_daily_spending:,.0f} VND")
        
        print("\nCATEGORY BREAKDOWN:")
        print("-" * 50)
        
        for category, info in category_status.items():
            status_symbol = "[X]" if info['status'] == 'OVER_BUDGET' else "[!]" if info['status'] == 'WARNING' else "[OK]"
            print(f"{status_symbol} {category.value.title():<15} | "
                  f"{info['spent']:>8,.0f} / {info['allocated']:>8,.0f} VND ({info['percentage_used']:>5.1f}%)")
        
        if status.category_overruns:
            print(f"\nWARNING: Over-budget categories: {', '.join(cat.value for cat in status.category_overruns)}")


class IntegratedTravelManager:
    """Integrated manager that automatically syncs activities with expenses"""
    
    def __init__(self):
        self.activity_manager = ActivityManager()
        self.expense_manager = ExpenseManager(self.activity_manager)
        
    def create_activity_with_expense(self, title: str, activity_type: ActivityType, 
                                   created_by: str, estimated_cost: Optional[Decimal] = None,
                                   actual_cost: Optional[Decimal] = None, **kwargs) -> Activity:
        """Create activity and automatically create associated expense if actual_cost is provided"""
        # Prepare budget data
        budget_data = None
        if estimated_cost is not None:
            budget_data = {
                "estimated_cost": estimated_cost,
                "actual_cost": actual_cost,
                "currency": kwargs.get("currency", "VND")
            }
            
        activity = self.activity_manager.create_activity(
            title=title,
            activity_type=activity_type,
            created_by=created_by,
            budget=budget_data,
            **kwargs
        )
        
        # Auto-sync expense if actual cost is provided
        if actual_cost is not None:
            self.expense_manager.sync_activity_to_expense(activity)
            
        return activity
    
    def update_activity_with_expense_sync(self, activity_id: str, **updates) -> Optional[Activity]:
        """Update activity and automatically sync with expenses"""
        activity = self.activity_manager.update_activity(activity_id, **updates)
        
        if activity:
            # Check if budget was updated
            if any(key.startswith('budget') for key in updates.keys()) or 'budget' in updates:
                if activity.budget and activity.budget.actual_cost:
                    self.expense_manager.sync_activity_to_expense(activity)
                else:
                    # Remove expense if no actual cost
                    self.expense_manager.remove_activity_expense(activity_id)
                    
        return activity
    
    def delete_activity_with_expense_sync(self, activity_id: str) -> bool:
        """Delete activity and automatically remove associated expense"""
        # Remove expense first
        self.expense_manager.remove_activity_expense(activity_id)
        
        # Then delete activity
        return self.activity_manager.delete_activity(activity_id)
    
    def set_activity_actual_cost(self, activity_id: str, actual_cost: Decimal, 
                               currency: str = "VND") -> bool:
        """Set actual cost for activity and automatically create/update expense"""
        activity = self.activity_manager.get_activity(activity_id)
        if not activity:
            return False
            
        # Update or create budget
        if activity.budget:
            activity.budget.actual_cost = actual_cost
            activity.budget.currency = currency
        else:
            activity.budget = Budget(
                estimated_cost=actual_cost,  # Use actual as estimated if no budget exists
                actual_cost=actual_cost,
                currency=currency
            )
        
        activity.updated_at = datetime.now()
        
        # Sync with expense
        self.expense_manager.sync_activity_to_expense(activity)
        return True
    
    def get_activity_expense_summary(self, trip_id: Optional[str] = None) -> Dict[str, any]:
        """Get comprehensive summary of activities and their associated expenses"""
        activities = (self.activity_manager.get_activities_by_trip(trip_id) 
                     if trip_id else list(self.activity_manager.activities.values()))
        
        total_estimated = Decimal('0')
        total_actual = Decimal('0')
        synced_activities = 0
        unsynced_activities = 0
        
        activity_expense_details = []
        
        for activity in activities:
            activity_detail = {
                'activity_id': activity.id,
                'title': activity.title,
                'type': activity.activity_type.value,
                'status': activity.status.value,
                'estimated_cost': None,
                'actual_cost': None,
                'has_expense': False,
                'expense_category': None
            }
            
            if activity.budget:
                activity_detail['estimated_cost'] = float(activity.budget.estimated_cost)
                total_estimated += activity.budget.estimated_cost
                
                if activity.budget.actual_cost:
                    activity_detail['actual_cost'] = float(activity.budget.actual_cost)
                    total_actual += activity.budget.actual_cost
                    
                    # Check if expense exists
                    if activity.id in self.expense_manager._activity_expense_map:
                        activity_detail['has_expense'] = True
                        category = self.expense_manager._map_activity_type_to_expense_category(activity.activity_type)
                        activity_detail['expense_category'] = category.value
                        synced_activities += 1
                    else:
                        unsynced_activities += 1
            
            activity_expense_details.append(activity_detail)
        
        return {
            'summary': {
                'total_activities': len(activities),
                'synced_activities': synced_activities,
                'unsynced_activities': unsynced_activities,
                'total_estimated_cost': float(total_estimated),
                'total_actual_cost': float(total_actual),
                'budget_variance': float(total_actual - total_estimated)
            },
            'activities': activity_expense_details,
            'budget_status': self.expense_manager.get_budget_status(),
            'category_status': self.expense_manager.get_category_status()
        }
    
    def sync_all_activities_with_expenses(self, trip_id: Optional[str] = None) -> Dict[str, str]:
        """Force sync all activities with expenses"""
        return self.expense_manager.sync_all_activities(trip_id)
    
    def setup_trip_with_budget(self, start_date: date, end_date: date, 
                             total_budget: Decimal, 
                             category_allocations: Optional[Dict[ExpenseCategory, Decimal]] = None):
        """Setup trip and budget for integrated management"""
        trip = Trip(start_date, end_date)
        budget = Budget(total_budget, category_allocations=category_allocations)
        
        self.expense_manager.set_trip(trip)
        self.expense_manager.set_budget(budget)

def interactive_mode():
    """Interactive mode for manual expense tracking"""
    try:
        # Get trip details
        print("Trip Setup:")
        start_input = input("Enter start date (YYYY-MM-DD): ")
        end_input = input("Enter end date (YYYY-MM-DD): ")
        
        start_date = datetime.strptime(start_input, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_input, '%Y-%m-%d').date()
        trip = Trip(start_date=start_date, end_date=end_date)
        
        # Get budget
        budget_input = input("Enter total budget (VND): ")
        total_budget = Decimal(budget_input)
        
        # Ask for custom allocations
        use_custom = input("Use custom category allocations? (y/n): ").lower() == 'y'
        
        if use_custom:
            print("\nEnter budget allocation for each category:")
            allocations = {}
            for category in ExpenseCategory:
                while True:
                    try:
                        amount_input = input(f"{category.value.title()} budget (VND): ")
                        allocations[category] = Decimal(amount_input)
                        break
                    except:
                        print("Invalid amount. Please try again.")
            
            budget = Budget(total_budget, category_allocations=allocations)
        else:
            budget = Budget(total_budget)
        
        # Initialize manager
        manager = ExpenseManager()
        manager.create_budget_plan(trip, budget)
        
        print(f"\nTrip setup complete! {trip.total_days} days, {total_budget:,.0f} VND budget")
        
        # Expense entry loop
        while True:
            print("\n" + "="*30)
            print("Add Expense")
            print("1. Add expense")
            print("2. View budget status")
            print("3. View expense history")
            print("4. Export data")
            print("5. Exit")
            
            choice = input("Choose option (1-5): ").strip()
            
            if choice == '1':
                try:
                    print("\nCategories:")
                    for i, cat in enumerate(ExpenseCategory, 1):
                        print(f"{i}. {cat.value.title()}")
                    
                    cat_choice = int(input("Choose category (1-7): ")) - 1
                    category = list(ExpenseCategory)[cat_choice]
                    
                    amount = Decimal(input("Amount (VND): "))
                    description = input("Description (optional): ")
                    
                    expense = manager.add_expense(amount, category, description)
                    print(f"Added expense: {amount:,.0f} VND - {category.value}")
                    
                except (ValueError, IndexError):
                    print("Invalid input. Please try again.")
            
            elif choice == '2':
                manager.print_budget_summary()
            
            elif choice == '3':
                manager.print_expense_history()
            
            elif choice == '4':
                data = manager.export_data()
                print("\nExport Data:")
                print(json.dumps(data, indent=2, default=str))
            
            elif choice == '5':
                print("Thanks for using the expense manager!")
                break
            
            else:
                print("Invalid choice. Please try again.")
    
    except Exception as e:
        print(f"Error: {str(e)}")

def demo_integrated_manager():
    """Demo function to show integrated activity-expense management"""
    print("=== INTEGRATED TRAVEL MANAGER DEMO ===\n")
    
    # Initialize integrated manager
    manager = IntegratedTravelManager()
    
    # Setup trip and budget
    start_date = date(2024, 1, 15)
    end_date = date(2024, 1, 20)
    total_budget = Decimal('5000000')  # 5M VND
    
    # Setup category allocations
    allocations = {
        ExpenseCategory.ACCOMMODATION: Decimal('2000000'),
        ExpenseCategory.FOOD_BEVERAGE: Decimal('1500000'),
        ExpenseCategory.TRANSPORTATION: Decimal('800000'),
        ExpenseCategory.ACTIVITIES: Decimal('700000'),
    }
    
    manager.setup_trip_with_budget(start_date, end_date, total_budget, allocations)
    print(f"Trip setup: {start_date} to {end_date}, Budget: {total_budget:,} VND")
    
    # Create activities with expenses
    activities = []
    
    # Hotel booking
    hotel = manager.create_activity_with_expense(
        title="Hotel Booking - Luxury Resort",
        activity_type=ActivityType.ACCOMMODATION,
        created_by="user1",
        estimated_cost=Decimal('2000000'),
        actual_cost=Decimal('1800000'),  # Saved 200k
        start_date=datetime(2024, 1, 15, 14, 0),
        end_date=datetime(2024, 1, 20, 11, 0)
    )
    activities.append(hotel)
    
    # Restaurant dinner
    dinner = manager.create_activity_with_expense(
        title="Fine Dining Restaurant",
        activity_type=ActivityType.DINING,
        created_by="user1",
        estimated_cost=Decimal('500000'),
        actual_cost=Decimal('650000'),  # Over budget
        start_date=datetime(2024, 1, 16, 19, 0)
    )
    activities.append(dinner)
    
    # Sightseeing tour
    tour = manager.create_activity_with_expense(
        title="City Walking Tour",
        activity_type=ActivityType.SIGHTSEEING,
        created_by="user1",
        estimated_cost=Decimal('300000'),
        actual_cost=Decimal('280000'),
        start_date=datetime(2024, 1, 17, 9, 0)
    )
    activities.append(tour)
    
    # Transportation
    taxi = manager.create_activity_with_expense(
        title="Airport Transfer",
        activity_type=ActivityType.TRANSPORTATION,
        created_by="user1",
        estimated_cost=Decimal('200000'),
        actual_cost=Decimal('250000'),
        start_date=datetime(2024, 1, 15, 10, 0)
    )
    activities.append(taxi)
    
    print(f"\nCreated {len(activities)} activities with expenses")
    
    # Show summary
    summary = manager.get_activity_expense_summary()
    print(f"\n=== ACTIVITY-EXPENSE SUMMARY ===")
    print(f"Total Activities: {summary['summary']['total_activities']}")
    print(f"Synced with Expenses: {summary['summary']['synced_activities']}")
    print(f"Total Estimated: {summary['summary']['total_estimated_cost']:,.0f} VND")
    print(f"Total Actual: {summary['summary']['total_actual_cost']:,.0f} VND")
    print(f"Budget Variance: {summary['summary']['budget_variance']:,.0f} VND")
    
    # Show budget status
    print(f"\n=== BUDGET STATUS ===")
    manager.expense_manager.print_budget_summary()
    
    # Update activity cost and see automatic sync
    print(f"\n=== UPDATING ACTIVITY COST ===")
    print("Updating dinner cost from 650k to 700k VND...")
    manager.set_activity_actual_cost(dinner.id, Decimal('700000'))
    
    # Show updated summary
    updated_summary = manager.get_activity_expense_summary()
    print(f"New Total Actual: {updated_summary['summary']['total_actual_cost']:,.0f} VND")
    
    # Delete an activity and see expense removal
    print(f"\n=== DELETING ACTIVITY ===")
    print("Deleting city tour...")
    manager.delete_activity_with_expense_sync(tour.id)
    
    final_summary = manager.get_activity_expense_summary()
    print(f"Final Total Activities: {final_summary['summary']['total_activities']}")
    print(f"Final Total Actual: {final_summary['summary']['total_actual_cost']:,.0f} VND")
    
    return manager

if __name__ == "__main__":
    print("Travel Expense Analytics Service with Activity Integration")
    print("1. Run integrated demo")
    print("2. Run original interactive mode")
    
    choice = input("Choose option (1 or 2): ").strip()
    
    if choice == "1":
        demo_integrated_manager()
    else:
        interactive_mode()
    