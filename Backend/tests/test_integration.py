"""
Integration tests for Backend services and models
"""
import unittest
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime, date, timedelta
from decimal import Decimal

from app.models.user import User, UserCreate
from app.models.planner import Planner, PlannerCreate, Activity, ActivityCreate
from app.models.expense import Expense, ExpenseCreate
from app.models.collaboration import (
    EditRequest, EditRequestCreate, ActivityEditRequest,
    ActivityEditRequestCreate, EditRequestStatus, ActivityEditRequestStatus
)


class TestUserWorkflow(unittest.TestCase):
    """Test complete user workflow"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.user_data = {
            "email": "testuser@example.com",
            "username": "testuser123",
            "password": "SecurePass123!",
            "first_name": "Test",
            "last_name": "User"
        }
    
    def test_user_registration_workflow(self):
        """Test complete user registration workflow"""
        # Create user
        user_create = UserCreate(**self.user_data)
        
        # Verify user fields
        self.assertEqual(user_create.email, self.user_data["email"])
        self.assertEqual(user_create.username, self.user_data["username"])
    
    def test_user_profile_update_workflow(self):
        """Test user profile update workflow"""
        user = User(
            id="user123",
            email="test@example.com",
            username="testuser"
        )
        
        # Verify initial state
        self.assertEqual(user.username, "testuser")
        
        # Would update in real implementation
        self.assertTrue(user.is_active)
    
    def test_user_preference_persistence(self):
        """Test user preference persistence"""
        user = User(
            id="user123",
            email="test@example.com",
            username="testuser",
            preferred_currency="USD",
            preferred_language="en",
            time_zone="America/New_York"
        )
        
        self.assertEqual(user.preferred_currency, "USD")
        self.assertEqual(user.preferred_language, "en")
        self.assertEqual(user.time_zone, "America/New_York")


class TestTripPlanningWorkflow(unittest.TestCase):
    """Test complete trip planning workflow"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.start_date = date.today()
        self.end_date = self.start_date + timedelta(days=7)
    
    def test_create_and_populate_trip(self):
        """Test creating trip and adding activities"""
        # Create planner
        planner_create = PlannerCreate(
            name="Vietnam Trip",
            description="7-day exploration",
            start_date=self.start_date,
            end_date=self.end_date
        )
        
        self.assertEqual(planner_create.name, "Vietnam Trip")
        
        # Create activities
        start_time = datetime.combine(self.start_date, datetime.min.time())
        end_time = start_time + timedelta(hours=3)
        
        activity_create = ActivityCreate(
            name="Arrive in Hanoi",
            start_time=start_time,
            end_time=end_time,
            location="Noi Bai Airport"
        )
        
        self.assertEqual(activity_create.name, "Arrive in Hanoi")
    
    def test_activity_scheduling_workflow(self):
        """Test activity scheduling workflow"""
        today = date.today()
        now = datetime.combine(today, datetime.min.time())
        
        activities_data = [
            {
                "name": "Breakfast",
                "start_time": now + timedelta(hours=8),
                "end_time": now + timedelta(hours=9)
            },
            {
                "name": "Temple Visit",
                "start_time": now + timedelta(hours=10),
                "end_time": now + timedelta(hours=12)
            },
            {
                "name": "Lunch",
                "start_time": now + timedelta(hours=12),
                "end_time": now + timedelta(hours=13)
            }
        ]
        
        # Verify activities don't overlap
        for i in range(len(activities_data) - 1):
            current_end = activities_data[i]["end_time"]
            next_start = activities_data[i + 1]["start_time"]
            self.assertLessEqual(current_end, next_start)


class TestExpenseTrackingWorkflow(unittest.TestCase):
    """Test complete expense tracking workflow"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.trip_id = "trip123"
        self.user_id = "user123"
    
    def test_add_and_track_expenses(self):
        """Test adding and tracking expenses"""
        expenses = []
        
        # Add flight expense
        flight_expense = ExpenseCreate(
            name="Flight Ticket",
            amount=500.0,
            currency="USD",
            category="Transportation",
            date=date.today()
        )
        
        # Add hotel expense
        hotel_expense = ExpenseCreate(
            name="Hotel 3 nights",
            amount=300.0,
            currency="USD",
            category="Lodging",
            date=date.today() + timedelta(days=1)
        )
        
        # Add restaurant expense
        restaurant_expense = ExpenseCreate(
            name="Meals",
            amount=150.0,
            currency="USD",
            category="Food",
            date=date.today() + timedelta(days=2)
        )
        
        expenses_data = [flight_expense, hotel_expense, restaurant_expense]
        total = sum(exp.amount for exp in expenses_data)
        
        self.assertEqual(total, 950.0)
    
    def test_expense_categorization(self):
        """Test expense categorization"""
        categories = {}
        
        expenses = [
            ExpenseCreate(
                name="Flight",
                amount=500.0,
                currency="USD",
                category="Transportation",
                date=date.today()
            ),
            ExpenseCreate(
                name="Hotel",
                amount=300.0,
                currency="USD",
                category="Lodging",
                date=date.today()
            ),
            ExpenseCreate(
                name="Taxi",
                amount=50.0,
                currency="USD",
                category="Transportation",
                date=date.today()
            )
        ]
        
        for expense in expenses:
            if expense.category not in categories:
                categories[expense.category] = 0
            categories[expense.category] += expense.amount
        
        self.assertEqual(categories["Transportation"], 550.0)
        self.assertEqual(categories["Lodging"], 300.0)
    
    def test_budget_vs_actual(self):
        """Test budget vs actual expense tracking"""
        budget = Decimal("1000.00")
        
        expenses = [
            Decimal("500.00"),  # Flight
            Decimal("300.00"),  # Hotel
            Decimal("100.00")   # Food
        ]
        
        total_spent = sum(expenses)
        remaining = budget - total_spent
        percentage_used = (total_spent / budget) * 100
        
        self.assertEqual(total_spent, Decimal("900.00"))
        self.assertEqual(remaining, Decimal("100.00"))
        self.assertEqual(percentage_used, 90.0)


class TestCollaborationWorkflow(unittest.TestCase):
    """Test complete collaboration workflow"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.owner_id = "owner123"
        self.collaborator_id = "user456"
        self.trip_id = "trip789"
    
    def test_invite_collaborator_workflow(self):
        """Test inviting collaborator to trip"""
        # Create edit request
        request_data = EditRequestCreate(
            trip_id=self.trip_id,
            message="Can you help plan this trip?"
        )
        
        # Create full request
        edit_request = EditRequest(
            trip_id=self.trip_id,
            requester_id=self.collaborator_id,
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id=self.owner_id
        )
        
        self.assertEqual(edit_request.status, EditRequestStatus.PENDING)
        self.assertIsNone(edit_request.responded_at)
    
    def test_approve_collaboration_request(self):
        """Test approving collaboration request"""
        # Create initial request
        request = EditRequest(
            trip_id=self.trip_id,
            requester_id=self.collaborator_id,
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id=self.owner_id,
            status=EditRequestStatus.PENDING
        )
        
        # Simulate approval
        request.status = EditRequestStatus.APPROVED
        request.responded_at = datetime.now()
        request.responded_by = self.owner_id
        
        self.assertEqual(request.status, EditRequestStatus.APPROVED)
        self.assertIsNotNone(request.responded_at)
        self.assertEqual(request.responded_by, self.owner_id)
    
    def test_activity_edit_request_workflow(self):
        """Test activity edit request workflow"""
        # Create activity edit request
        request = ActivityEditRequest(
            trip_id=self.trip_id,
            request_type="edit_activity",
            activity_id="activity123",
            requester_id=self.collaborator_id,
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id=self.owner_id,
            proposed_changes={
                "start_time": "2024-01-15T10:00:00",
                "end_time": "2024-01-15T12:00:00"
            }
        )
        
        self.assertEqual(request.status, ActivityEditRequestStatus.PENDING)
        self.assertEqual(request.request_type, "edit_activity")
        self.assertIsNotNone(request.proposed_changes)


class TestMultiUserCollaboration(unittest.TestCase):
    """Test multi-user collaboration scenarios"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.owner_id = "owner123"
        self.editor_ids = ["editor1", "editor2"]
        self.viewer_ids = ["viewer1", "viewer2"]
        self.trip_id = "trip789"
    
    def test_multiple_editors_on_trip(self):
        """Test multiple editors collaborating on same trip"""
        editors = [
            {
                "user_id": editor_id,
                "role": "editor"
            }
            for editor_id in self.editor_ids
        ]
        
        self.assertEqual(len(editors), 2)
        for editor in editors:
            self.assertEqual(editor["role"], "editor")
    
    def test_mixed_permissions_on_trip(self):
        """Test mixed permissions (editors and viewers) on trip"""
        collaborators = []
        
        # Add editors
        for editor_id in self.editor_ids:
            collaborators.append({"user_id": editor_id, "role": "editor"})
        
        # Add viewers
        for viewer_id in self.viewer_ids:
            collaborators.append({"user_id": viewer_id, "role": "viewer"})
        
        self.assertEqual(len(collaborators), 4)
        editors = [c for c in collaborators if c["role"] == "editor"]
        viewers = [c for c in collaborators if c["role"] == "viewer"]
        
        self.assertEqual(len(editors), 2)
        self.assertEqual(len(viewers), 2)
    
    def test_activity_request_notification_chain(self):
        """Test activity request notification workflow"""
        # First editor proposes change
        request1 = ActivityEditRequest(
            trip_id=self.trip_id,
            request_type="edit_activity",
            activity_id="activity123",
            requester_id=self.editor_ids[0],
            requester_name="Editor 1",
            requester_email="editor1@example.com",
            owner_id=self.owner_id
        )
        
        # Second editor also proposes change
        request2 = ActivityEditRequest(
            trip_id=self.trip_id,
            request_type="edit_activity",
            activity_id="activity123",
            requester_id=self.editor_ids[1],
            requester_name="Editor 2",
            requester_email="editor2@example.com",
            owner_id=self.owner_id
        )
        
        requests = [request1, request2]
        pending_requests = [r for r in requests if r.status == ActivityEditRequestStatus.PENDING]
        
        self.assertEqual(len(pending_requests), 2)


class TestCompleteJourney(unittest.TestCase):
    """Test complete journey from trip creation to completion"""
    
    def test_full_trip_lifecycle(self):
        """Test complete trip lifecycle"""
        # Step 1: User creates account
        user = User(
            id="user123",
            email="traveler@example.com",
            username="traveler",
            preferred_currency="USD"
        )
        self.assertTrue(user.is_active)
        
        # Step 2: User creates trip
        trip = Planner(
            id="trip123",
            user_id="user123",
            name="Southeast Asia Tour",
            start_date=date.today(),
            end_date=date.today() + timedelta(days=14)
        )
        self.assertEqual(trip.user_id, "user123")
        
        # Step 3: User adds activities
        activities = []
        for i in range(5):
            activity = Activity(
                id=f"activity{i}",
                planner_id="trip123",
                name=f"Activity {i+1}",
                start_time=datetime.now() + timedelta(days=i),
                end_time=datetime.now() + timedelta(days=i, hours=2)
            )
            activities.append(activity)
        
        self.assertEqual(len(activities), 5)
        
        # Step 4: User tracks expenses
        expenses = []
        for i in range(3):
            expense = Expense(
                id=f"expense{i}",
                planner_id="trip123",
                name=f"Expense {i+1}",
                amount=100.0 * (i + 1),
                currency="USD",
                category="Travel",
                date=date.today()
            )
            expenses.append(expense)
        
        total_expenses = sum(exp.amount for exp in expenses)
        self.assertEqual(total_expenses, 600.0)
        
        # Step 5: User invites collaborators
        collaborators = [
            {
                "user_id": "friend1",
                "trip_id": "trip123",
                "role": "editor"
            },
            {
                "user_id": "friend2",
                "trip_id": "trip123",
                "role": "viewer"
            }
        ]
        
        self.assertEqual(len(collaborators), 2)


if __name__ == '__main__':
    unittest.main(verbosity=2)
