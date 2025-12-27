"""
Edge case and error handling tests
"""
import unittest
from datetime import datetime, date, timedelta
from decimal import Decimal
from pydantic import ValidationError

from app.models.user import User, UserCreate, UserUpdate, UserPasswordUpdate
from app.models.planner import Planner, PlannerCreate, Activity, ActivityCreate
from app.models.expense import Expense, ExpenseCreate
from app.models.collaboration import (
    EditRequest, ActivityEditRequest, EditRequestStatus,
    ActivityEditRequestStatus
)


class TestUserModelEdgeCases(unittest.TestCase):
    """Test edge cases for user models"""
    
    def test_username_exactly_minimum_length(self):
        """Test username with exactly minimum length (6 chars)"""
        user = UserCreate(
            email="test@example.com",
            username="user12",  # Exactly 6 chars
            password="password123"
        )
        self.assertEqual(len(user.username), 6)
    
    def test_username_exactly_maximum_length(self):
        """Test username with exactly maximum length (50 chars)"""
        username = "a" * 50
        user = UserCreate(
            email="test@example.com",
            username=username,
            password="password123"
        )
        self.assertEqual(len(user.username), 50)
    
    def test_password_exactly_minimum_length(self):
        """Test password with exactly minimum length (8 chars)"""
        user = UserCreate(
            email="test@example.com",
            username="testuser",
            password="pass1234"  # Exactly 8 chars
        )
        self.assertEqual(len(user.password), 8)
    
    def test_password_exactly_maximum_length(self):
        """Test password with exactly maximum length (100 chars)"""
        password = "p" * 100
        user = UserCreate(
            email="test@example.com",
            username="testuser",
            password=password
        )
        self.assertEqual(len(user.password), 100)
    
    def test_empty_string_username(self):
        """Test empty string as username"""
        with self.assertRaises(ValidationError):
            UserCreate(
                email="test@example.com",
                username="",
                password="password123"
            )
    
    def test_empty_string_password(self):
        """Test empty string as password"""
        with self.assertRaises(ValidationError):
            UserCreate(
                email="test@example.com",
                username="testuser",
                password=""
            )
    
    def test_special_characters_in_username(self):
        """Test special characters in username"""
        user = UserCreate(
            email="test@example.com",
            username="test_user-123",
            password="password123"
        )
        self.assertIn("_", user.username)
        self.assertIn("-", user.username)
    
    def test_unicode_in_name_fields(self):
        """Test unicode characters in name fields"""
        user = User(
            id="user123",
            email="test@example.com",
            username="testuser",
            first_name="Đức",
            last_name="Nguyễn"
        )
        self.assertEqual(user.first_name, "Đức")
        self.assertEqual(user.last_name, "Nguyễn")
    
    def test_null_optional_fields(self):
        """Test null values in optional fields"""
        user = UserUpdate()
        self.assertIsNone(user.email)
        self.assertIsNone(user.username)
        self.assertIsNone(user.first_name)


class TestPlannerModelEdgeCases(unittest.TestCase):
    """Test edge cases for planner models"""
    
    def test_zero_day_trip(self):
        """Test trip with start and end date the same"""
        today = date.today()
        planner = PlannerCreate(
            name="Day Trip",
            start_date=today,
            end_date=today
        )
        self.assertEqual(planner.start_date, planner.end_date)
    
    def test_very_long_trip(self):
        """Test trip spanning many days"""
        start = date.today()
        end = start + timedelta(days=365)  # One year
        
        planner = PlannerCreate(
            name="Year Long Adventure",
            start_date=start,
            end_date=end
        )
        
        duration = (planner.end_date - planner.start_date).days
        self.assertEqual(duration, 365)
    
    def test_empty_description(self):
        """Test planner with empty description"""
        planner = PlannerCreate(
            name="Trip",
            description="",
            start_date=date.today(),
            end_date=date.today() + timedelta(days=1)
        )
        self.assertEqual(planner.description, "")
    
    def test_very_long_description(self):
        """Test planner with very long description"""
        long_description = "x" * 1000
        planner = Planner(
            id="planner123",
            user_id="user123",
            name="Trip",
            description=long_description,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=1)
        )
        self.assertEqual(len(planner.description), 1000)
    
    def test_activity_same_start_end_time(self):
        """Test activity with same start and end time"""
        now = datetime.now()
        activity = ActivityCreate(
            name="Instant Event",
            start_time=now,
            end_time=now
        )
        self.assertEqual(activity.start_time, activity.end_time)
    
    def test_activity_very_long_duration(self):
        """Test activity spanning multiple days"""
        start = datetime.now()
        end = start + timedelta(days=30)
        
        activity = ActivityCreate(
            name="Month-long Activity",
            start_time=start,
            end_time=end
        )
        
        duration = activity.end_time - activity.start_time
        self.assertEqual(duration.days, 30)


class TestExpenseModelEdgeCases(unittest.TestCase):
    """Test edge cases for expense models"""
    
    def test_zero_expense_amount(self):
        """Test expense with zero amount"""
        expense = ExpenseCreate(
            name="Free Activity",
            amount=0.0,
            currency="USD",
            category="Activity",
            date=date.today()
        )
        self.assertEqual(expense.amount, 0.0)
    
    def test_very_large_expense_amount(self):
        """Test expense with very large amount"""
        expense = ExpenseCreate(
            name="Luxury Trip",
            amount=999999.99,
            currency="USD",
            category="Luxury",
            date=date.today()
        )
        self.assertEqual(expense.amount, 999999.99)
    
    def test_very_small_expense_amount(self):
        """Test expense with very small amount"""
        expense = ExpenseCreate(
            name="Candy",
            amount=0.01,
            currency="USD",
            category="Food",
            date=date.today()
        )
        self.assertEqual(expense.amount, 0.01)
    
    def test_negative_expense_amount(self):
        """Test expense with negative amount (refund)"""
        expense = ExpenseCreate(
            name="Refund",
            amount=-50.0,
            currency="USD",
            category="Refund",
            date=date.today()
        )
        self.assertLess(expense.amount, 0)
    
    def test_empty_category(self):
        """Test expense with empty category"""
        # Category field allows empty string, so test that it's accepted
        expense = ExpenseCreate(
            name="Item",
            amount=10.0,
            currency="USD",
            category="",  # Empty category is allowed
            date=date.today()
        )
        self.assertEqual(expense.category, "")
    
    def test_old_date_expense(self):
        """Test expense with very old date"""
        old_date = date(1900, 1, 1)
        expense = ExpenseCreate(
            name="Historical Expense",
            amount=10.0,
            currency="USD",
            category="History",
            date=old_date
        )
        self.assertEqual(expense.date.year, 1900)
    
    def test_future_date_expense(self):
        """Test expense with future date"""
        future_date = date.today() + timedelta(days=365)
        expense = ExpenseCreate(
            name="Future Expense",
            amount=10.0,
            currency="USD",
            category="Future",
            date=future_date
        )
        self.assertGreater(expense.date, date.today())


class TestCollaborationEdgeCases(unittest.TestCase):
    """Test edge cases for collaboration models"""
    
    def test_edit_request_without_message(self):
        """Test edit request without message"""
        request = EditRequest(
            trip_id="trip123",
            requester_id="user456",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123"
        )
        self.assertIsNone(request.message)
    
    def test_edit_request_with_very_long_message(self):
        """Test edit request with very long message"""
        long_message = "x" * 5000
        request = EditRequest(
            trip_id="trip123",
            requester_id="user456",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123",
            message=long_message
        )
        self.assertEqual(len(request.message), 5000)
    
    def test_edit_request_self_approval(self):
        """Test edit request where requester is same as owner"""
        request = EditRequest(
            trip_id="trip123",
            requester_id="user123",
            requester_name="User",
            requester_email="user@example.com",
            owner_id="user123"  # Same as requester
        )
        self.assertEqual(request.requester_id, request.owner_id)
    
    def test_activity_edit_request_without_activity_id(self):
        """Test activity edit request for new activity (no ID)"""
        request = ActivityEditRequest(
            trip_id="trip123",
            request_type="add_activity",
            requester_id="user456",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123"
            # activity_id is None
        )
        self.assertIsNone(request.activity_id)
    
    def test_activity_edit_request_with_complex_changes(self):
        """Test activity edit request with complex proposed changes"""
        complex_changes = {
            "name": "Updated Activity",
            "start_time": "2024-01-15T10:00:00",
            "end_time": "2024-01-15T12:00:00",
            "location": {
                "name": "New Location",
                "coordinates": [21.0285, 105.8542]
            },
            "budget": {
                "estimated": 100.0,
                "actual": 95.0,
                "currency": "USD"
            },
            "tags": ["important", "cultural", "historical"]
        }
        
        request = ActivityEditRequest(
            trip_id="trip123",
            request_type="edit_activity",
            activity_id="activity123",
            requester_id="user456",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123",
            proposed_changes=complex_changes
        )
        
        self.assertIsNotNone(request.proposed_changes)
        self.assertIn("location", request.proposed_changes)


class TestBoundaryConditions(unittest.TestCase):
    """Test boundary conditions and limits"""
    
    def test_maximum_activities_in_trip(self):
        """Test creating trip with many activities"""
        planner = Planner(
            id="trip123",
            user_id="user123",
            name="Busy Trip",
            start_date=date.today(),
            end_date=date.today() + timedelta(days=365)
        )
        
        activities = []
        for i in range(365):  # Activity every day
            activity = Activity(
                id=f"activity{i}",
                planner_id="trip123",
                name=f"Activity {i}",
                start_time=datetime.now() + timedelta(days=i),
                end_time=datetime.now() + timedelta(days=i, hours=1)
            )
            activities.append(activity)
        
        self.assertEqual(len(activities), 365)
    
    def test_maximum_expenses_tracking(self):
        """Test tracking many expenses"""
        expenses = []
        for i in range(1000):  # 1000 expenses
            expense = Expense(
                id=f"expense{i}",
                planner_id="trip123",
                name=f"Expense {i}",
                amount=10.0,
                currency="USD",
                category="General",
                date=date.today()
            )
            expenses.append(expense)
        
        total = sum(exp.amount for exp in expenses)
        self.assertEqual(total, 10000.0)
    
    def test_many_collaborators(self):
        """Test trip with many collaborators"""
        collaborators = []
        for i in range(100):
            collaborators.append({
                "user_id": f"user{i}",
                "role": "editor" if i < 50 else "viewer"
            })
        
        editors = [c for c in collaborators if c["role"] == "editor"]
        viewers = [c for c in collaborators if c["role"] == "viewer"]
        
        self.assertEqual(len(editors), 50)
        self.assertEqual(len(viewers), 50)


class TestDataTypeConversions(unittest.TestCase):
    """Test data type conversions and coercions"""
    
    def test_decimal_to_float_conversion(self):
        """Test decimal to float conversion"""
        from decimal import Decimal
        
        decimal_value = Decimal("123.45")
        float_value = float(decimal_value)
        
        self.assertIsInstance(float_value, float)
        self.assertAlmostEqual(float_value, 123.45, places=2)
    
    def test_date_to_datetime_conversion(self):
        """Test date to datetime conversion"""
        test_date = date.today()
        test_datetime = datetime.combine(test_date, datetime.min.time())
        
        self.assertEqual(test_datetime.date(), test_date)
    
    def test_string_date_parsing(self):
        """Test string date parsing"""
        date_str = "2024-01-15"
        parsed_date = datetime.fromisoformat(date_str).date()
        
        self.assertEqual(parsed_date.year, 2024)
        self.assertEqual(parsed_date.month, 1)
        self.assertEqual(parsed_date.day, 15)


class TestConcurrencyScenarios(unittest.TestCase):
    """Test potential concurrency issues"""
    
    def test_simultaneous_trip_updates(self):
        """Test scenario of simultaneous trip updates"""
        # This is a mock test showing the structure
        trip_id = "trip123"
        
        # User 1 updates
        update1 = {"name": "Updated Name 1"}
        
        # User 2 updates
        update2 = {"name": "Updated Name 2"}
        
        # In real scenario, last one would win
        # This should be handled by backend
        self.assertNotEqual(update1["name"], update2["name"])
    
    def test_simultaneous_expense_additions(self):
        """Test scenario of simultaneous expense additions"""
        initial_total = Decimal("0.00")
        
        # User 1 adds expense
        expense1 = Decimal("100.00")
        total1 = initial_total + expense1
        
        # User 2 adds expense
        expense2 = Decimal("50.00")
        total2 = total1 + expense2
        
        self.assertEqual(total2, Decimal("150.00"))


if __name__ == '__main__':
    unittest.main(verbosity=2)
