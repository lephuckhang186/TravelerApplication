import unittest
from datetime import datetime, date, timedelta
from decimal import Decimal
from annalytics_service import (
    ExpenseCategory, Expense, CategoryBudget, Budget, BudgetStatus,
    Trip, Analytics, ExpenseManager
)


class TestExpenseCategory(unittest.TestCase):
    """Test cases for ExpenseCategory enum"""
    
    def test_all_categories_exist(self):
        """Test that all expected categories are defined"""
        expected_categories = [
            "transportation", "accommodation", "food_beverage",
            "activities", "shopping", "miscellaneous", "emergency"
        ]
        actual_categories = [cat.value for cat in ExpenseCategory]
        self.assertEqual(set(expected_categories), set(actual_categories))


class TestExpense(unittest.TestCase):
    """Test cases for Expense dataclass"""
    
    def setUp(self):
        self.test_date = datetime(2024, 3, 1, 10, 30)
    
    def test_expense_creation_with_decimal(self):
        """Test creating expense with Decimal amount"""
        expense = Expense(
            amount=Decimal('100000'),
            category=ExpenseCategory.FOOD_BEVERAGE,
            date=self.test_date,
            description="Lunch"
        )
        self.assertEqual(expense.amount, Decimal('100000'))
        self.assertEqual(expense.category, ExpenseCategory.FOOD_BEVERAGE)
        self.assertEqual(expense.date, self.test_date)
        self.assertEqual(expense.description, "Lunch")
        self.assertEqual(expense.currency, "VND")
    
    def test_expense_creation_with_int(self):
        """Test creating expense with integer amount (auto-converted to Decimal)"""
        expense = Expense(
            amount=100000,
            category=ExpenseCategory.TRANSPORTATION,
            date=self.test_date
        )
        self.assertEqual(expense.amount, Decimal('100000'))
        self.assertIsInstance(expense.amount, Decimal)
    
    def test_expense_creation_with_float(self):
        """Test creating expense with float amount (auto-converted to Decimal)"""
        expense = Expense(
            amount=100000.50,
            category=ExpenseCategory.ACCOMMODATION,
            date=self.test_date
        )
        self.assertEqual(expense.amount, Decimal('100000.5'))
        self.assertIsInstance(expense.amount, Decimal)
    
    def test_negative_amount_raises_error(self):
        """Test that negative amounts raise ValueError"""
        with self.assertRaises(ValueError) as context:
            Expense(
                amount=Decimal('-100'),
                category=ExpenseCategory.FOOD_BEVERAGE,
                date=self.test_date
            )
        self.assertIn("cannot be negative", str(context.exception))
    
    def test_default_values(self):
        """Test expense creation with default values"""
        expense = Expense(
            amount=Decimal('50000'),
            category=ExpenseCategory.SHOPPING,
            date=self.test_date
        )
        self.assertEqual(expense.description, "")
        self.assertEqual(expense.currency, "VND")


class TestCategoryBudget(unittest.TestCase):
    """Test cases for CategoryBudget dataclass"""
    
    def test_category_budget_creation(self):
        """Test creating a category budget"""
        budget = CategoryBudget(allocated_amount=Decimal('1000000'))
        self.assertEqual(budget.allocated_amount, Decimal('1000000'))
        self.assertEqual(budget.spent_amount, Decimal('0'))
    
    def test_remaining_property(self):
        """Test remaining amount calculation"""
        budget = CategoryBudget(
            allocated_amount=Decimal('1000000'),
            spent_amount=Decimal('300000')
        )
        self.assertEqual(budget.remaining, Decimal('700000'))
    
    def test_percentage_used_property(self):
        """Test percentage used calculation"""
        budget = CategoryBudget(
            allocated_amount=Decimal('1000000'),
            spent_amount=Decimal('250000')
        )
        self.assertEqual(budget.percentage_used, 25.0)
    
    def test_percentage_used_zero_allocation(self):
        """Test percentage used when allocation is zero"""
        budget = CategoryBudget(
            allocated_amount=Decimal('0'),
            spent_amount=Decimal('100000')
        )
        self.assertEqual(budget.percentage_used, 0.0)
    
    def test_is_over_budget_false(self):
        """Test is_over_budget when under budget"""
        budget = CategoryBudget(
            allocated_amount=Decimal('1000000'),
            spent_amount=Decimal('500000')
        )
        self.assertFalse(budget.is_over_budget)
    
    def test_is_over_budget_true(self):
        """Test is_over_budget when over budget"""
        budget = CategoryBudget(
            allocated_amount=Decimal('1000000'),
            spent_amount=Decimal('1200000')
        )
        self.assertTrue(budget.is_over_budget)


class TestBudget(unittest.TestCase):
    """Test cases for Budget class"""
    
    def test_budget_creation_with_decimal(self):
        """Test creating budget with Decimal total"""
        budget = Budget(total_budget=Decimal('5000000'))
        self.assertEqual(budget.total, Decimal('5000000'))
        self.assertIsNone(budget.daily_limit)
    
    def test_budget_creation_with_int(self):
        """Test creating budget with integer total (auto-converted)"""
        budget = Budget(total_budget=5000000)
        self.assertEqual(budget.total, Decimal('5000000'))
        self.assertIsInstance(budget.total, Decimal)
    
    def test_budget_creation_with_daily_limit(self):
        """Test creating budget with daily limit"""
        budget = Budget(total_budget=Decimal('5000000'), daily_limit=500000)
        self.assertEqual(budget.daily_limit, Decimal('500000'))
    
    def test_negative_budget_raises_error(self):
        """Test that negative budget raises ValueError"""
        with self.assertRaises(ValueError) as context:
            Budget(total_budget=Decimal('-1000'))
        self.assertIn("must be positive", str(context.exception))
    
    def test_zero_budget_raises_error(self):
        """Test that zero budget raises ValueError"""
        with self.assertRaises(ValueError) as context:
            Budget(total_budget=0)
        self.assertIn("must be positive", str(context.exception))
    
    def test_default_allocations(self):
        """Test that default allocations are created"""
        budget = Budget(total_budget=Decimal('5000000'))
        
        # Check that all categories have allocations
        for category in ExpenseCategory:
            self.assertIn(category, budget.category_budgets)
            self.assertGreater(budget.category_budgets[category].allocated_amount, 0)
        
        # Check total allocation equals budget
        total_allocated = budget.get_total_allocated()
        self.assertEqual(total_allocated, budget.total)
    
    def test_custom_allocations(self):
        """Test creating budget with custom allocations"""
        custom_allocations = {
            ExpenseCategory.ACCOMMODATION: Decimal('2000000'),
            ExpenseCategory.FOOD_BEVERAGE: Decimal('1500000'),
            ExpenseCategory.TRANSPORTATION: Decimal('1000000')
        }
        budget = Budget(
            total_budget=Decimal('5000000'),
            category_allocations=custom_allocations
        )
        
        for category, amount in custom_allocations.items():
            self.assertEqual(
                budget.category_budgets[category].allocated_amount,
                amount
            )
    
    def test_custom_allocations_exceed_budget(self):
        """Test that allocations exceeding budget raise error"""
        custom_allocations = {
            ExpenseCategory.ACCOMMODATION: Decimal('3000000'),
            ExpenseCategory.FOOD_BEVERAGE: Decimal('3000000')
        }
        
        with self.assertRaises(ValueError) as context:
            Budget(
                total_budget=Decimal('5000000'),
                category_allocations=custom_allocations
            )
        self.assertIn("exceed budget", str(context.exception))
    
    def test_get_category_budget(self):
        """Test getting budget for specific category"""
        budget = Budget(total_budget=Decimal('5000000'))
        accommodation_budget = budget.get_category_budget(ExpenseCategory.ACCOMMODATION)
        self.assertIsInstance(accommodation_budget, CategoryBudget)
        self.assertGreater(accommodation_budget.allocated_amount, 0)
    
    def test_get_unallocated(self):
        """Test getting unallocated budget amount"""
        custom_allocations = {
            ExpenseCategory.ACCOMMODATION: Decimal('2000000'),
            ExpenseCategory.FOOD_BEVERAGE: Decimal('1500000')
        }
        budget = Budget(
            total_budget=Decimal('5000000'),
            category_allocations=custom_allocations
        )
        
        expected_unallocated = Decimal('5000000') - Decimal('3500000')
        self.assertEqual(budget.get_unallocated(), expected_unallocated)


class TestTrip(unittest.TestCase):
    """Test cases for Trip class"""
    
    def test_trip_creation(self):
        """Test creating a trip"""
        start = date(2024, 3, 1)
        end = date(2024, 3, 10)
        trip = Trip(start_date=start, end_date=end)
        
        self.assertEqual(trip.start_date, start)
        self.assertEqual(trip.end_date, end)
    
    def test_invalid_date_range_raises_error(self):
        """Test that end date before start date raises error"""
        start = date(2024, 3, 10)
        end = date(2024, 3, 1)
        
        with self.assertRaises(ValueError) as context:
            Trip(start_date=start, end_date=end)
        self.assertIn("must be after start date", str(context.exception))
    
    def test_same_start_end_date_raises_error(self):
        """Test that same start and end date raises error"""
        same_date = date(2024, 3, 1)
        
        with self.assertRaises(ValueError):
            Trip(start_date=same_date, end_date=same_date)
    
    def test_total_days(self):
        """Test total days calculation"""
        start = date(2024, 3, 1)
        end = date(2024, 3, 10)
        trip = Trip(start_date=start, end_date=end)
        
        self.assertEqual(trip.total_days, 10)  # Inclusive of both dates
    
    def test_get_date_range(self):
        """Test getting all dates in trip"""
        start = date(2024, 3, 1)
        end = date(2024, 3, 3)
        trip = Trip(start_date=start, end_date=end)
        
        expected_dates = [
            date(2024, 3, 1),
            date(2024, 3, 2),
            date(2024, 3, 3)
        ]
        self.assertEqual(trip.get_date_range(), expected_dates)


class TestAnalytics(unittest.TestCase):
    """Test cases for Analytics class"""
    
    def setUp(self):
        """Set up test data"""
        self.expenses = [
            Expense(
                amount=Decimal('500000'),
                category=ExpenseCategory.ACCOMMODATION,
                date=datetime(2024, 3, 1, 15, 0),
                description="Hotel night 1"
            ),
            Expense(
                amount=Decimal('150000'),
                category=ExpenseCategory.FOOD_BEVERAGE,
                date=datetime(2024, 3, 1, 19, 30),
                description="Dinner"
            ),
            Expense(
                amount=Decimal('200000'),
                category=ExpenseCategory.TRANSPORTATION,
                date=datetime(2024, 3, 2, 10, 0),
                description="Taxi"
            ),
            Expense(
                amount=Decimal('80000'),
                category=ExpenseCategory.FOOD_BEVERAGE,
                date=datetime(2024, 3, 2, 8, 0),
                description="Breakfast"
            )
        ]
        self.analytics = Analytics(self.expenses)
        self.trip = Trip(start_date=date(2024, 3, 1), end_date=date(2024, 3, 5))
    
    def test_get_expenses_by_category(self):
        """Test grouping expenses by category"""
        by_category = self.analytics.get_expenses_by_category()
        
        self.assertIn(ExpenseCategory.ACCOMMODATION, by_category)
        self.assertIn(ExpenseCategory.FOOD_BEVERAGE, by_category)
        self.assertIn(ExpenseCategory.TRANSPORTATION, by_category)
        
        self.assertEqual(len(by_category[ExpenseCategory.ACCOMMODATION]), 1)
        self.assertEqual(len(by_category[ExpenseCategory.FOOD_BEVERAGE]), 2)
        self.assertEqual(len(by_category[ExpenseCategory.TRANSPORTATION]), 1)
    
    def test_get_expenses_by_date(self):
        """Test grouping expenses by date"""
        by_date = self.analytics.get_expenses_by_date()
        
        march_1 = date(2024, 3, 1)
        march_2 = date(2024, 3, 2)
        
        self.assertIn(march_1, by_date)
        self.assertIn(march_2, by_date)
        
        self.assertEqual(len(by_date[march_1]), 2)  # Hotel + Dinner
        self.assertEqual(len(by_date[march_2]), 2)  # Taxi + Breakfast
    
    def test_get_category_totals(self):
        """Test getting total spending by category"""
        category_totals = self.analytics.get_category_totals()
        
        self.assertEqual(category_totals[ExpenseCategory.ACCOMMODATION], Decimal('500000'))
        self.assertEqual(category_totals[ExpenseCategory.FOOD_BEVERAGE], Decimal('230000'))
        self.assertEqual(category_totals[ExpenseCategory.TRANSPORTATION], Decimal('200000'))
    
    def test_get_daily_totals(self):
        """Test getting total spending by date"""
        daily_totals = self.analytics.get_daily_totals()
        
        march_1 = date(2024, 3, 1)
        march_2 = date(2024, 3, 2)
        
        self.assertEqual(daily_totals[march_1], Decimal('650000'))  # 500000 + 150000
        self.assertEqual(daily_totals[march_2], Decimal('280000'))  # 200000 + 80000
    
    def test_get_average_daily_spending(self):
        """Test calculating average daily spending"""
        # Mock today's date to control days_elapsed calculation
        from unittest.mock import patch
        from datetime import date
        
        # Set "today" to be 2024-03-05 (5 days into the trip)
        with patch('annalytics_service.date') as mock_date:
            mock_date.today.return_value = date(2024, 3, 5)
            mock_date.side_effect = lambda *args, **kw: date(*args, **kw)
            
            average = self.analytics.get_average_daily_spending(self.trip)
            
            total_spent = sum(exp.amount for exp in self.expenses)  # 930000
            days_elapsed = 5  # March 1-5 = 5 days
            expected_average = total_spent / Decimal(str(days_elapsed))
            
            self.assertEqual(average, expected_average)
    
    def test_cache_invalidation(self):
        """Test that cache is properly invalidated"""
        # Get cached result
        first_result = self.analytics.get_expenses_by_category()
        
        # Check cache exists
        self.assertIn("expenses_by_category", self.analytics._expense_cache)
        
        # Invalidate cache
        self.analytics.invalidate_cache()
        
        # Check cache is cleared
        self.assertEqual(len(self.analytics._expense_cache), 0)


class TestBudgetStatus(unittest.TestCase):
    """Test cases for BudgetStatus dataclass"""
    
    def setUp(self):
        self.budget_status = BudgetStatus(
            total_budget=Decimal('5000000'),
            total_spent=Decimal('2000000'),
            percentage_used=40.0,
            days_remaining=6,
            days_total=10,
            recommended_daily_spending=Decimal('500000'),
            average_daily_spending=Decimal('500000'),
            category_overruns=[]
        )
    
    def test_remaining_budget_property(self):
        """Test remaining budget calculation"""
        expected_remaining = Decimal('5000000') - Decimal('2000000')
        self.assertEqual(self.budget_status.remaining_budget, expected_remaining)
    
    def test_is_over_budget_false(self):
        """Test is_over_budget when under budget"""
        self.assertFalse(self.budget_status.is_over_budget)
    
    def test_is_over_budget_true(self):
        """Test is_over_budget when over budget"""
        over_budget_status = BudgetStatus(
            total_budget=Decimal('5000000'),
            total_spent=Decimal('6000000'),
            percentage_used=120.0,
            days_remaining=2,
            days_total=10,
            recommended_daily_spending=Decimal('0'),
            average_daily_spending=Decimal('750000'),
            category_overruns=[]
        )
        self.assertTrue(over_budget_status.is_over_budget)
    
    def test_burn_rate_status_on_track(self):
        """Test burn rate status when on track"""
        self.assertEqual(self.budget_status.burn_rate_status, "ON_TRACK")
    
    def test_burn_rate_status_high_burn(self):
        """Test burn rate status when burning too fast"""
        high_burn_status = BudgetStatus(
            total_budget=Decimal('5000000'),
            total_spent=Decimal('4000000'),
            percentage_used=80.0,  # 80% spent in 40% of time
            days_remaining=6,
            days_total=10,
            recommended_daily_spending=Decimal('166667'),
            average_daily_spending=Decimal('1000000'),
            category_overruns=[]
        )
        self.assertEqual(high_burn_status.burn_rate_status, "HIGH_BURN")
    
    def test_burn_rate_status_completed(self):
        """Test burn rate status when trip is completed"""
        completed_status = BudgetStatus(
            total_budget=Decimal('5000000'),
            total_spent=Decimal('4500000'),
            percentage_used=90.0,
            days_remaining=0,
            days_total=10,
            recommended_daily_spending=Decimal('0'),
            average_daily_spending=Decimal('450000'),
            category_overruns=[]
        )
        self.assertEqual(completed_status.burn_rate_status, "COMPLETED")


class TestExpenseManager(unittest.TestCase):
    """Test cases for ExpenseManager class"""
    
    def setUp(self):
        """Set up test expense manager"""
        self.manager = ExpenseManager()
        self.trip = Trip(
            start_date=date(2024, 3, 1),
            end_date=date(2024, 3, 10)
        )
        self.budget = Budget(total_budget=Decimal('5000000'))
        self.manager.create_budget_plan(self.trip, self.budget)
    
    def test_create_budget_plan(self):
        """Test creating a budget plan"""
        self.assertEqual(self.manager.trip, self.trip)
        self.assertEqual(self.manager.trip_budget, self.budget)
        self.assertIsNotNone(self.manager.analytics)
    
    def test_add_expense(self):
        """Test adding an expense"""
        expense = self.manager.add_expense(
            amount=Decimal('500000'),
            category=ExpenseCategory.ACCOMMODATION,
            description="Hotel night"
        )
        
        self.assertIn(expense, self.manager.expenses)
        self.assertEqual(expense.amount, Decimal('500000'))
        self.assertEqual(expense.category, ExpenseCategory.ACCOMMODATION)
        self.assertEqual(expense.description, "Hotel night")
    
    def test_add_expense_updates_budget(self):
        """Test that adding expense updates category budget"""
        initial_spent = self.budget.get_category_budget(ExpenseCategory.ACCOMMODATION).spent_amount
        
        self.manager.add_expense(
            amount=Decimal('500000'),
            category=ExpenseCategory.ACCOMMODATION
        )
        
        updated_spent = self.budget.get_category_budget(ExpenseCategory.ACCOMMODATION).spent_amount
        self.assertEqual(updated_spent, initial_spent + Decimal('500000'))
    
    def test_remove_expense(self):
        """Test removing an expense"""
        expense = self.manager.add_expense(
            amount=Decimal('500000'),
            category=ExpenseCategory.ACCOMMODATION
        )
        
        result = self.manager.remove_expense(expense)
        
        self.assertTrue(result)
        self.assertNotIn(expense, self.manager.expenses)
    
    def test_remove_expense_updates_budget(self):
        """Test that removing expense updates category budget"""
        expense = self.manager.add_expense(
            amount=Decimal('500000'),
            category=ExpenseCategory.ACCOMMODATION
        )
        
        spent_after_add = self.budget.get_category_budget(ExpenseCategory.ACCOMMODATION).spent_amount
        
        self.manager.remove_expense(expense)
        
        spent_after_remove = self.budget.get_category_budget(ExpenseCategory.ACCOMMODATION).spent_amount
        self.assertEqual(spent_after_remove, spent_after_add - Decimal('500000'))
    
    def test_remove_nonexistent_expense(self):
        """Test removing an expense that doesn't exist"""
        fake_expense = Expense(
            amount=Decimal('100000'),
            category=ExpenseCategory.FOOD_BEVERAGE,
            date=datetime.now()
        )
        
        result = self.manager.remove_expense(fake_expense)
        self.assertFalse(result)
    
    def test_get_total_spent(self):
        """Test getting total amount spent"""
        self.manager.add_expense(Decimal('500000'), ExpenseCategory.ACCOMMODATION)
        self.manager.add_expense(Decimal('150000'), ExpenseCategory.FOOD_BEVERAGE)
        self.manager.add_expense(Decimal('200000'), ExpenseCategory.TRANSPORTATION)
        
        total = self.manager.get_total_spent()
        self.assertEqual(total, Decimal('850000'))
    
    def test_get_category_spending(self):
        """Test getting spending for specific category"""
        self.manager.add_expense(Decimal('150000'), ExpenseCategory.FOOD_BEVERAGE)
        self.manager.add_expense(Decimal('80000'), ExpenseCategory.FOOD_BEVERAGE)
        self.manager.add_expense(Decimal('200000'), ExpenseCategory.TRANSPORTATION)
        
        food_spending = self.manager.get_category_spending(ExpenseCategory.FOOD_BEVERAGE)
        self.assertEqual(food_spending, Decimal('230000'))
        
        transport_spending = self.manager.get_category_spending(ExpenseCategory.TRANSPORTATION)
        self.assertEqual(transport_spending, Decimal('200000'))
    
    def test_get_budget_status(self):
        """Test getting budget status"""
        self.manager.add_expense(Decimal('2000000'), ExpenseCategory.ACCOMMODATION)
        
        status = self.manager.get_budget_status()
        
        self.assertIsNotNone(status)
        self.assertEqual(status.total_budget, Decimal('5000000'))
        self.assertEqual(status.total_spent, Decimal('2000000'))
        self.assertEqual(status.percentage_used, 40.0)
    
    def test_get_budget_status_no_plan(self):
        """Test getting budget status when no plan is set"""
        manager = ExpenseManager()
        status = manager.get_budget_status()
        self.assertIsNone(status)
    
    def test_get_category_status(self):
        """Test getting status for all categories"""
        self.manager.add_expense(Decimal('1000000'), ExpenseCategory.ACCOMMODATION)
        
        status = self.manager.get_category_status()
        
        self.assertIn(ExpenseCategory.ACCOMMODATION, status)
        accommodation_status = status[ExpenseCategory.ACCOMMODATION]
        
        self.assertEqual(accommodation_status['spent'], Decimal('1000000'))
        self.assertIn('allocated', accommodation_status)
        self.assertIn('remaining', accommodation_status)
        self.assertIn('percentage_used', accommodation_status)
        self.assertIn('is_over_budget', accommodation_status)
        self.assertIn('status', accommodation_status)
    
    def test_get_expense_history_no_filter(self):
        """Test getting expense history without filters"""
        expense1 = self.manager.add_expense(Decimal('500000'), ExpenseCategory.ACCOMMODATION)
        expense2 = self.manager.add_expense(Decimal('150000'), ExpenseCategory.FOOD_BEVERAGE)
        
        history = self.manager.get_expense_history()
        
        self.assertEqual(len(history), 2)
        # Should be sorted by date (most recent first)
        self.assertEqual(history[0], expense2)
        self.assertEqual(history[1], expense1)
    
    def test_get_expense_history_category_filter(self):
        """Test getting expense history with category filter"""
        self.manager.add_expense(Decimal('500000'), ExpenseCategory.ACCOMMODATION)
        food_expense = self.manager.add_expense(Decimal('150000'), ExpenseCategory.FOOD_BEVERAGE)
        
        history = self.manager.get_expense_history(
            category_filter=ExpenseCategory.FOOD_BEVERAGE
        )
        
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0], food_expense)
    
    def test_get_expense_history_date_filter(self):
        """Test getting expense history with date filter"""
        expense_date1 = datetime(2024, 3, 1, 10, 0)
        expense_date2 = datetime(2024, 3, 5, 10, 0)
        
        self.manager.add_expense(
            Decimal('500000'), 
            ExpenseCategory.ACCOMMODATION, 
            expense_date=expense_date1
        )
        filtered_expense = self.manager.add_expense(
            Decimal('150000'), 
            ExpenseCategory.FOOD_BEVERAGE, 
            expense_date=expense_date2
        )
        
        history = self.manager.get_expense_history(
            date_range=(date(2024, 3, 3), date(2024, 3, 7))
        )
        
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0], filtered_expense)
    
    def test_export_data(self):
        """Test exporting data"""
        self.manager.add_expense(Decimal('500000'), ExpenseCategory.ACCOMMODATION, "Hotel")
        
        data = self.manager.export_data()
        
        self.assertIn('trip', data)
        self.assertIn('budget', data)
        self.assertIn('expenses', data)
        
        self.assertEqual(data['trip']['start_date'], '2024-03-01')
        self.assertEqual(data['trip']['end_date'], '2024-03-10')
        self.assertEqual(data['budget']['total'], '5000000')
        self.assertEqual(len(data['expenses']), 1)
        
        expense_data = data['expenses'][0]
        self.assertEqual(expense_data['amount'], '500000')
        self.assertEqual(expense_data['category'], 'accommodation')
        self.assertEqual(expense_data['description'], 'Hotel')


if __name__ == '__main__':
    unittest.main(verbosity=2)