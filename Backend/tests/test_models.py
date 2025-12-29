"""
Comprehensive tests for all Backend models
"""
import unittest
from datetime import datetime, date, timedelta
from pydantic import ValidationError, EmailStr
from app.models.user import (
    UserBase, UserCreate, UserUpdate, UserPasswordUpdate, User, UserInDB,
    UserProfile, UserStats, LoginRequest, LoginResponse, RefreshTokenRequest,
    PasswordResetRequest, PasswordResetConfirm, EmailVerificationRequest
)
from app.models.planner import (
    ActivityBase, ActivityCreate, Activity, PlannerBase, PlannerCreate,
    PlannerUpdate, Planner
)
from app.models.expense import ExpenseBase, ExpenseCreate, Expense
from app.models.collaboration import (
    InvitationStatus, CollaboratorRole, EditRequestStatus,
    CollaboratorBase, CollaboratorCreate, Collaborator,
    EditRequest, EditRequestCreate, EditRequestResponse, EditRequestUpdate,
    ActivityEditRequestStatus, ActivityEditRequest, ActivityEditRequestCreate,
    ActivityEditRequestResponse, ActivityEditRequestUpdate
)


class TestUserModels(unittest.TestCase):
    """Test cases for User models"""
    
    def test_user_base_creation(self):
        """Test UserBase model creation with valid data"""
        user = UserBase(
            email="test@example.com",
            username="testuser123",
            first_name="Test",
            last_name="User",
            profile_picture="https://example.com/pic.jpg"
        )
        self.assertEqual(user.email, "test@example.com")
        self.assertEqual(user.username, "testuser123")
        self.assertEqual(user.first_name, "Test")
        self.assertEqual(user.last_name, "User")
    
    def test_user_base_invalid_email(self):
        """Test UserBase model with invalid email"""
        with self.assertRaises(ValidationError):
            UserBase(
                email="invalid-email",
                username="testuser123"
            )
    
    def test_user_base_username_too_short(self):
        """Test UserBase model with username too short"""
        with self.assertRaises(ValidationError):
            UserBase(
                email="test@example.com",
                username="short"
            )
    
    def test_user_base_username_too_long(self):
        """Test UserBase model with username too long"""
        with self.assertRaises(ValidationError):
            UserBase(
                email="test@example.com",
                username="a" * 51
            )
    
    def test_user_create_with_password(self):
        """Test UserCreate model with valid password"""
        user = UserCreate(
            email="test@example.com",
            username="testuser123",
            password="securepassword123"
        )
        self.assertEqual(user.email, "test@example.com")
        self.assertEqual(user.password, "securepassword123")
    
    def test_user_create_password_too_short(self):
        """Test UserCreate model with password too short"""
        with self.assertRaises(ValidationError):
            UserCreate(
                email="test@example.com",
                username="testuser123",
                password="short"
            )
    
    def test_user_update_partial(self):
        """Test UserUpdate model with partial data"""
        user = UserUpdate(
            first_name="Updated",
            last_name="Name"
        )
        self.assertEqual(user.first_name, "Updated")
        self.assertEqual(user.last_name, "Name")
        self.assertIsNone(user.email)
    
    def test_user_password_update(self):
        """Test UserPasswordUpdate model"""
        pwd_update = UserPasswordUpdate(
            current_password="oldpassword123",
            new_password="newpassword123"
        )
        self.assertEqual(pwd_update.current_password, "oldpassword123")
        self.assertEqual(pwd_update.new_password, "newpassword123")
    
    def test_user_full_model(self):
        """Test User model with all fields"""
        now = datetime.now()
        user = User(
            id="user123",
            email="test@example.com",
            username="testuser123",
            first_name="Test",
            last_name="User",
            is_active=True,
            is_admin=False,
            is_verified=True,
            created_at=now,
            updated_at=now,
            preferred_currency="USD",
            preferred_language="en",
            time_zone="America/New_York"
        )
        self.assertEqual(user.id, "user123")
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_admin)
        self.assertTrue(user.is_verified)
    
    def test_user_in_db(self):
        """Test UserInDB model with hashed password"""
        now = datetime.now()
        user = UserInDB(
            id="user123",
            email="test@example.com",
            username="testuser123",
            hashed_password="$2b$12$hashedpassword"
        )
        self.assertEqual(user.hashed_password, "$2b$12$hashedpassword")
    
    def test_user_profile(self):
        """Test UserProfile model"""
        now = datetime.now()
        profile = UserProfile(
            id="user123",
            username="testuser123",
            first_name="Test",
            last_name="User",
            created_at=now
        )
        self.assertEqual(profile.display_name, "Test User")
    
    def test_user_profile_display_name_first_name_only(self):
        """Test UserProfile display_name with only first name"""
        now = datetime.now()
        profile = UserProfile(
            id="user123",
            username="testuser123",
            first_name="Test",
            created_at=now
        )
        self.assertEqual(profile.display_name, "Test")
    
    def test_user_profile_display_name_username_fallback(self):
        """Test UserProfile display_name with username as fallback"""
        now = datetime.now()
        profile = UserProfile(
            id="user123",
            username="testuser123",
            created_at=now
        )
        self.assertEqual(profile.display_name, "testuser123")
    
    def test_user_stats(self):
        """Test UserStats model"""
        stats = UserStats(
            total_trips=5,
            total_expenses=10000.0,
            total_distance_traveled=5000.0,
            countries_visited=["Vietnam", "Thailand"],
            favorite_destinations=["Bangkok", "Hanoi"],
            average_trip_duration=7.5,
            budget_accuracy=85.5
        )
        self.assertEqual(stats.total_trips, 5)
        self.assertEqual(len(stats.countries_visited), 2)
    
    def test_login_request(self):
        """Test LoginRequest model"""
        login = LoginRequest(
            email="test@example.com",
            password="password123"
        )
        self.assertEqual(login.email, "test@example.com")
    
    def test_login_response(self):
        """Test LoginResponse model"""
        now = datetime.now()
        user = User(
            id="user123",
            email="test@example.com",
            username="testuser123"
        )
        response = LoginResponse(
            access_token="access_token_xyz",
            refresh_token="refresh_token_xyz",
            expires_in=3600,
            user=user
        )
        self.assertEqual(response.access_token, "access_token_xyz")
        self.assertEqual(response.token_type, "bearer")
    
    def test_refresh_token_request(self):
        """Test RefreshTokenRequest model"""
        request = RefreshTokenRequest(refresh_token="refresh_token_xyz")
        self.assertEqual(request.refresh_token, "refresh_token_xyz")
    
    def test_password_reset_request(self):
        """Test PasswordResetRequest model"""
        request = PasswordResetRequest(email="test@example.com")
        self.assertEqual(request.email, "test@example.com")
    
    def test_password_reset_confirm(self):
        """Test PasswordResetConfirm model"""
        confirm = PasswordResetConfirm(
            token="reset_token_xyz",
            new_password="newpassword123"
        )
        self.assertEqual(confirm.token, "reset_token_xyz")
    
    def test_email_verification_request(self):
        """Test EmailVerificationRequest model"""
        request = EmailVerificationRequest(token="verify_token_xyz")
        self.assertEqual(request.token, "verify_token_xyz")


class TestPlannerModels(unittest.TestCase):
    """Test cases for Planner models"""
    
    def test_activity_base(self):
        """Test ActivityBase model"""
        start = datetime.now()
        end = start + timedelta(hours=2)
        activity = ActivityBase(
            name="Museum Visit",
            description="Visit local museum",
            start_time=start,
            end_time=end,
            location="Museum Street"
        )
        self.assertEqual(activity.name, "Museum Visit")
        self.assertEqual(activity.location, "Museum Street")
    
    def test_activity_create(self):
        """Test ActivityCreate model"""
        start = datetime.now()
        end = start + timedelta(hours=2)
        activity = ActivityCreate(
            name="Museum Visit",
            start_time=start,
            end_time=end
        )
        self.assertEqual(activity.name, "Museum Visit")
    
    def test_activity_full(self):
        """Test Activity model with all fields"""
        start = datetime.now()
        end = start + timedelta(hours=2)
        activity = Activity(
            id="activity123",
            planner_id="planner123",
            name="Museum Visit",
            start_time=start,
            end_time=end
        )
        self.assertEqual(activity.id, "activity123")
        self.assertEqual(activity.planner_id, "planner123")
    
    def test_planner_base(self):
        """Test PlannerBase model"""
        start_date = date.today()
        end_date = start_date + timedelta(days=7)
        planner = PlannerBase(
            name="Vietnam Trip",
            description="Exploring Vietnam",
            start_date=start_date,
            end_date=end_date
        )
        self.assertEqual(planner.name, "Vietnam Trip")
    
    def test_planner_create(self):
        """Test PlannerCreate model"""
        start_date = date.today()
        end_date = start_date + timedelta(days=7)
        planner = PlannerCreate(
            name="Vietnam Trip",
            start_date=start_date,
            end_date=end_date
        )
        self.assertEqual(planner.name, "Vietnam Trip")
    
    def test_planner_update(self):
        """Test PlannerUpdate model with partial fields"""
        planner = PlannerUpdate(name="Updated Trip")
        self.assertEqual(planner.name, "Updated Trip")
        self.assertIsNone(planner.description)
    
    def test_planner_full(self):
        """Test Planner model with activities"""
        start_date = date.today()
        end_date = start_date + timedelta(days=7)
        start_time = datetime.now()
        end_time = start_time + timedelta(hours=2)
        
        activity = Activity(
            id="activity123",
            planner_id="planner123",
            name="Museum Visit",
            start_time=start_time,
            end_time=end_time
        )
        
        planner = Planner(
            id="planner123",
            user_id="user123",
            name="Vietnam Trip",
            start_date=start_date,
            end_date=end_date,
            activities=[activity]
        )
        self.assertEqual(planner.id, "planner123")
        self.assertEqual(len(planner.activities), 1)


class TestExpenseModels(unittest.TestCase):
    """Test cases for Expense models"""
    
    def test_expense_base(self):
        """Test ExpenseBase model"""
        expense = ExpenseBase(
            name="Hotel",
            amount=150.0,
            currency="USD",
            category="Lodging",
            date=date.today()
        )
        self.assertEqual(expense.name, "Hotel")
        self.assertEqual(expense.amount, 150.0)
    
    def test_expense_create(self):
        """Test ExpenseCreate model"""
        expense = ExpenseCreate(
            name="Flight",
            amount=500.0,
            currency="USD",
            category="Transportation",
            date=date.today()
        )
        self.assertEqual(expense.name, "Flight")
    
    def test_expense_full(self):
        """Test Expense model with ID"""
        expense = Expense(
            id="expense123",
            planner_id="planner123",
            name="Restaurant",
            amount=50.0,
            currency="USD",
            category="Food",
            date=date.today()
        )
        self.assertEqual(expense.id, "expense123")
        self.assertEqual(expense.planner_id, "planner123")


class TestCollaborationModels(unittest.TestCase):
    """Test cases for Collaboration models"""
    
    def test_invitation_status_enum(self):
        """Test InvitationStatus enum"""
        self.assertEqual(InvitationStatus.PENDING.value, "pending")
        self.assertEqual(InvitationStatus.ACCEPTED.value, "accepted")
        self.assertEqual(InvitationStatus.REJECTED.value, "rejected")
    
    def test_collaborator_role_enum(self):
        """Test CollaboratorRole enum"""
        self.assertEqual(CollaboratorRole.OWNER.value, "owner")
        self.assertEqual(CollaboratorRole.EDITOR.value, "editor")
        self.assertEqual(CollaboratorRole.VIEWER.value, "viewer")
    
    def test_edit_request_status_enum(self):
        """Test EditRequestStatus enum"""
        self.assertEqual(EditRequestStatus.PENDING.value, "pending")
        self.assertEqual(EditRequestStatus.APPROVED.value, "approved")
        self.assertEqual(EditRequestStatus.REJECTED.value, "rejected")
    
    def test_collaborator_base(self):
        """Test CollaboratorBase model"""
        collab = CollaboratorBase(
            user_id="user123",
            planner_id="planner123"
        )
        self.assertEqual(collab.user_id, "user123")
    
    def test_collaborator_create(self):
        """Test CollaboratorCreate model"""
        collab = CollaboratorCreate(
            user_id="user123",
            planner_id="planner123"
        )
        self.assertEqual(collab.user_id, "user123")
    
    def test_collaborator_full(self):
        """Test Collaborator model"""
        collab = Collaborator(
            user_id="user123",
            planner_id="planner123"
        )
        self.assertEqual(collab.user_id, "user123")
    
    def test_edit_request(self):
        """Test EditRequest model"""
        now = datetime.now()
        request = EditRequest(
            trip_id="trip123",
            requester_id="user123",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123"
        )
        self.assertEqual(request.trip_id, "trip123")
        self.assertEqual(request.status, EditRequestStatus.PENDING)
    
    def test_edit_request_create(self):
        """Test EditRequestCreate model"""
        request = EditRequestCreate(
            trip_id="trip123",
            message="Please grant me edit access"
        )
        self.assertEqual(request.trip_id, "trip123")
    
    def test_edit_request_response(self):
        """Test EditRequestResponse model"""
        now = datetime.now()
        response = EditRequestResponse(
            id="request123",
            trip_id="trip123",
            requester_id="user123",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123",
            status=EditRequestStatus.PENDING,
            requested_at=now
        )
        self.assertEqual(response.id, "request123")
    
    def test_edit_request_update(self):
        """Test EditRequestUpdate model"""
        update = EditRequestUpdate(
            status=EditRequestStatus.APPROVED,
            promote_to_editor=True
        )
        self.assertEqual(update.status, EditRequestStatus.APPROVED)
        self.assertTrue(update.promote_to_editor)
    
    def test_activity_edit_request_status_enum(self):
        """Test ActivityEditRequestStatus enum"""
        self.assertEqual(ActivityEditRequestStatus.PENDING.value, "pending")
        self.assertEqual(ActivityEditRequestStatus.APPROVED.value, "approved")
        self.assertEqual(ActivityEditRequestStatus.REJECTED.value, "rejected")
    
    def test_activity_edit_request(self):
        """Test ActivityEditRequest model"""
        now = datetime.now()
        request = ActivityEditRequest(
            trip_id="trip123",
            request_type="add_activity",
            requester_id="user123",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123",
            proposed_changes={"name": "New Activity"}
        )
        self.assertEqual(request.trip_id, "trip123")
        self.assertEqual(request.status, ActivityEditRequestStatus.PENDING)
    
    def test_activity_edit_request_create(self):
        """Test ActivityEditRequestCreate model"""
        request = ActivityEditRequestCreate(
            trip_id="trip123",
            request_type="edit_activity",
            activity_id="activity123",
            proposed_changes={"start_time": "2024-01-01"}
        )
        self.assertEqual(request.request_type, "edit_activity")
    
    def test_activity_edit_request_response(self):
        """Test ActivityEditRequestResponse model"""
        now = datetime.now()
        response = ActivityEditRequestResponse(
            id="request123",
            trip_id="trip123",
            request_type="add_activity",
            requester_id="user123",
            requester_name="Test User",
            requester_email="test@example.com",
            owner_id="owner123",
            status=ActivityEditRequestStatus.PENDING,
            requested_at=now
        )
        self.assertEqual(response.id, "request123")
    
    def test_activity_edit_request_update(self):
        """Test ActivityEditRequestUpdate model"""
        update = ActivityEditRequestUpdate(
            status=ActivityEditRequestStatus.APPROVED
        )
        self.assertEqual(update.status, ActivityEditRequestStatus.APPROVED)


if __name__ == '__main__':
    unittest.main(verbosity=2)
