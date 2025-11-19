from enum import Enum
from typing import List, Optional, Dict, Tuple
from datetime import datetime, date, timedelta
from decimal import Decimal, getcontext
from dataclasses import dataclass
from collections import defaultdict
import json

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
            ExpenseCategory.ACCOMMODATION: 35,
            ExpenseCategory.FOOD_BEVERAGE: 25,
            ExpenseCategory.TRANSPORTATION: 20,
            ExpenseCategory.ACTIVITIES: 10,
            ExpenseCategory.SHOPPING: 5,
            ExpenseCategory.MISCELLANEOUS: 3,
            ExpenseCategory.EMERGENCY: 2
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
    """Enhanced expense manager with comprehensive budget tracking"""
    def __init__(self):
        self.trip_budget: Optional[Budget] = None
        self.expenses: List[Expense] = []
        self.analytics: Optional[Analytics] = None
        self.trip: Optional[Trip] = None
    
    def create_budget_plan(self, trip: Trip, budget: Budget):
        """Initialize trip with budget plan"""
        self.trip = trip
        self.trip_budget = budget
        self.analytics = Analytics(self.expenses)
    
    def add_expense(self, amount: Decimal, category: ExpenseCategory, 
                   description: str = "", expense_date: Optional[datetime] = None) -> Expense:
        """Add expense with proper validation and budget tracking"""
        if isinstance(amount, (int, float)):
            amount = Decimal(str(amount))
        
        if expense_date is None:
            expense_date = datetime.now()
        
        expense = Expense(amount, category, expense_date, description)
        self.expenses.append(expense)
        
        # Update category budget spending
        if self.trip_budget:
            category_budget = self.trip_budget.get_category_budget(category)
            category_budget.spent_amount += amount
        
        # Invalidate analytics cache
        if self.analytics:
            self.analytics.expenses = self.expenses
            self.analytics.invalidate_cache()
        
        return expense
    
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

if __name__ == "__main__":
    print("Travel Expense Analytics Service")
    interactive_mode()
    