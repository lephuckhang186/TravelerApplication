"""
Test suite for User Models using unittest
"""
import unittest
from datetime import datetime
from pydantic import ValidationError
import sys
import os

# Add app to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.models.user import (
    UserBase, UserCreate, UserUpdate, UserPasswordUpdate,
    User, UserInDB, UserProfile, UserStats,
    LoginRequest, LoginResponse, RefreshTokenRequest,
    PasswordResetRequest, PasswordResetConfirm, EmailVerificationRequest
)


class TestUserBase(unittest.TestCase):
    """Test cases for UserBase model"""

    def test_valid_user_base(self):
        """Test creating valid UserBase"""
        user_data = {
            "email": "test@example.com",
            "username": "testuser123",
            "first_name": "Test",
            "last_name": "User",
            "phone": "+1234567890"
        }
        user = UserBase(**user_data)
        
        self.assertEqual(user.email, "test@example.com")
        self.assertEqual(user.username, "testuser123")
        self.assertEqual(user.first_name, "Test")
        self.assertEqual(user.last_name, "User")
        self.assertEqual(user.phone, "+1234567890")

    def test_user_base_minimal_fields(self):
        """Test UserBase with only required fields"""
        user_data = {
            "email": "minimal@example.com",
            "username": "minimal123"
        }
        user = UserBase(**user_data)
        
        self.assertEqual(user.email, "minimal@example.com")
        self.assertEqual(user.username, "minimal123")
        self.assertIsNone(user.first_name)
        self.assertIsNone(user.last_name)
        self.assertIsNone(user.phone)
        self.assertIsNone(user.profile_picture)

    def test_user_base_invalid_email(self):
        """Test UserBase with invalid email"""
        user_data = {
            "email": "invalid-email",
            "username": "testuser"
        }
        
        with self.assertRaises(ValidationError):
            UserBase(**user_data)

    def test_user_base_short_username(self):
        """Test UserBase with username too short"""
        user_data = {
            "email": "test@example.com",
            "username": "short"  # Less than 6 characters - FIXED: was "hello"
        }
        
        # FIXED: Use correct variable and class
        with self.assertRaises(ValidationError):
            UserBase(**user_data) 

    def test_user_base_long_username(self):
        """Test UserBase with username too long"""
        user_data = {
            "email": "test@example.com",
            "username": "a" * 51  # More than 50 characters
        }
        
        with self.assertRaises(ValidationError):
            UserBase(**user_data)


class TestUserCreate(unittest.TestCase):
    """Test cases for UserCreate model"""

    def test_valid_user_create(self):
        """Test creating valid UserCreate"""
        user_data = {
            "email": "create@example.com",
            "username": "createuser",
            "password": "strongpassword123",
            "first_name": "Create",
            "last_name": "User"
        }
        user = UserCreate(**user_data)
        
        self.assertEqual(user.email, "create@example.com")
        self.assertEqual(user.username, "createuser")
        self.assertEqual(user.password, "strongpassword123")
        self.assertEqual(user.first_name, "Create")
        self.assertEqual(user.last_name, "User")

    def test_user_create_short_password(self):
        """Test UserCreate with password too short"""
        user_data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "short"  # Less than 8 characters
        }
        
        with self.assertRaises(ValidationError):
            UserCreate(**user_data)

    def test_user_create_long_password(self):
        """Test UserCreate with password too long"""
        user_data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "a" * 101  # More than 100 characters
        }
        
        with self.assertRaises(ValidationError):
            UserCreate(**user_data)


class TestUserUpdate(unittest.TestCase):
    """Test cases for UserUpdate model"""

    def test_valid_user_update(self):
        """Test creating valid UserUpdate"""
        update_data = {
            "first_name": "Updated",
            "last_name": "Name",
            "phone": "+9876543210"
        }
        user_update = UserUpdate(**update_data)
        
        self.assertEqual(user_update.first_name, "Updated")
        self.assertEqual(user_update.last_name, "Name")
        self.assertEqual(user_update.phone, "+9876543210")
        self.assertIsNone(user_update.email)
        self.assertIsNone(user_update.username)

    def test_user_update_empty(self):
        """Test UserUpdate with no fields"""
        user_update = UserUpdate()
        
        self.assertIsNone(user_update.email)
        self.assertIsNone(user_update.username)
        self.assertIsNone(user_update.first_name)
        self.assertIsNone(user_update.last_name)
        self.assertIsNone(user_update.phone)
        self.assertIsNone(user_update.profile_picture)

    def test_user_update_invalid_username(self):
        """Test UserUpdate with invalid username"""
        update_data = {
            "username": "short"  # Less than 6 characters
        }
        
        # FIXED: Use correct variable and class
        with self.assertRaises(ValidationError):
            UserUpdate(**update_data) 


class TestUserPasswordUpdate(unittest.TestCase):
    """Test cases for UserPasswordUpdate model"""

    def test_valid_password_update(self):
        """Test valid password update"""
        password_data = {
            "current_password": "currentpass123",
            "new_password": "newstrongpass456"
        }
        password_update = UserPasswordUpdate(**password_data)
        
        self.assertEqual(password_update.current_password, "currentpass123")
        self.assertEqual(password_update.new_password, "newstrongpass456")

    def test_password_update_short_new_password(self):
        """Test password update with short new password"""
        password_data = {
            "current_password": "currentpass123",
            "new_password": "short"
        }
        
        with self.assertRaises(ValidationError):
            UserPasswordUpdate(**password_data)


class TestUser(unittest.TestCase):
    """Test cases for User model"""

    def test_valid_user(self):
        """Test creating valid User"""
        user_data = {
            "id": "user123",
            "email": "user@example.com",
            "username": "usertest",
            "first_name": "User",
            "last_name": "Test",
            "is_active": True,
            "is_admin": False,
            "is_verified": True,
            "preferred_currency": "USD",
            "preferred_language": "en",
            "time_zone": "UTC"
        }
        user = User(**user_data)
        
        self.assertEqual(user.id, "user123")
        self.assertEqual(user.email, "user@example.com")
        self.assertEqual(user.username, "usertest")
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_admin)
        self.assertTrue(user.is_verified)
        self.assertEqual(user.preferred_currency, "USD")
        self.assertEqual(user.preferred_language, "en")
        self.assertEqual(user.time_zone, "UTC")

    def test_user_with_defaults(self):
        """Test User with default values"""
        user_data = {
            "id": "user456",
            "email": "defaults@example.com",
            "username": "defaultuser"
        }
        user = User(**user_data)
        
        self.assertEqual(user.id, "user456")
        self.assertTrue(user.is_active)  # Default True
        self.assertFalse(user.is_admin)  # Default False
        self.assertFalse(user.is_verified)  # Default False
        self.assertEqual(user.preferred_currency, "USD")  # Default USD
        self.assertEqual(user.preferred_language, "en")  # Default en
        self.assertEqual(user.time_zone, "UTC")  # Default UTC
        self.assertIsInstance(user.created_at, datetime)
        self.assertIsInstance(user.updated_at, datetime)

    def test_user_travel_preferences(self):
        """Test User with travel preferences"""
        travel_prefs = {
            "budget_level": "medium",
            "accommodation_type": "hotel",
            "transport_mode": "flight"
        }
        user_data = {
            "id": "traveler123",
            "email": "traveler@example.com",
            "username": "globetrotter",
            "travel_preferences": travel_prefs
        }
        user = User(**user_data)
        
        self.assertEqual(user.travel_preferences, travel_prefs)


class TestUserInDB(unittest.TestCase):
    """Test cases for UserInDB model"""

    def test_valid_user_in_db(self):
        """Test creating valid UserInDB"""
        user_data = {
            "id": "db_user123",
            "email": "dbuser@example.com",
            "username": "databaseuser",
            "hashed_password": "$2b$12$hashedpasswordexample"
        }
        user_in_db = UserInDB(**user_data)
        
        self.assertEqual(user_in_db.id, "db_user123")
        self.assertEqual(user_in_db.email, "dbuser@example.com")
        self.assertEqual(user_in_db.username, "databaseuser")
        self.assertEqual(user_in_db.hashed_password, "$2b$12$hashedpasswordexample")


class TestUserProfile(unittest.TestCase):
    """Test cases for UserProfile model"""

    def test_valid_user_profile(self):
        """Test creating valid UserProfile"""
        profile_data = {
            "id": "profile123",
            "username": "profileuser",
            "first_name": "Profile",
            "last_name": "User",
            "profile_picture": "https://example.com/photo.jpg",
            "created_at": datetime.now()
        }
        profile = UserProfile(**profile_data)
        
        self.assertEqual(profile.id, "profile123")
        self.assertEqual(profile.username, "profileuser")
        self.assertEqual(profile.first_name, "Profile")
        self.assertEqual(profile.last_name, "User")

    def test_user_profile_display_name_full(self):
        """Test display_name property with first and last name"""
        profile_data = {
            "id": "profile123",
            "username": "testuser",
            "first_name": "John",
            "last_name": "Doe",
            "created_at": datetime.now()
        }
        profile = UserProfile(**profile_data)
        
        self.assertEqual(profile.display_name, "John Doe")

    def test_user_profile_display_name_first_only(self):
        """Test display_name property with first name only"""
        profile_data = {
            "id": "profile123",
            "username": "testuser",
            "first_name": "John",
            "created_at": datetime.now()
        }
        profile = UserProfile(**profile_data)
        
        self.assertEqual(profile.display_name, "John")

    def test_user_profile_display_name_username_fallback(self):
        """Test display_name property falling back to username"""
        profile_data = {
            "id": "profile123",
            "username": "testuser",
            "created_at": datetime.now()
        }
        profile = UserProfile(**profile_data)
        
        self.assertEqual(profile.display_name, "testuser")


class TestUserStats(unittest.TestCase):
    """Test cases for UserStats model"""

    def test_valid_user_stats(self):
        """Test creating valid UserStats"""
        stats_data = {
            "total_trips": 5,
            "total_expenses": 15000.50,
            "total_distance_traveled": 25000.0,
            "countries_visited": ["Vietnam", "Thailand", "Japan"],
            "favorite_destinations": ["Tokyo", "Bangkok"],
            "average_trip_duration": 7.5,
            "most_expensive_trip": "Japan Adventure",
            "budget_accuracy": 85.5
        }
        stats = UserStats(**stats_data)
        
        self.assertEqual(stats.total_trips, 5)
        self.assertEqual(stats.total_expenses, 15000.50)
        self.assertEqual(stats.total_distance_traveled, 25000.0)
        self.assertEqual(stats.countries_visited, ["Vietnam", "Thailand", "Japan"])
        self.assertEqual(stats.favorite_destinations, ["Tokyo", "Bangkok"])
        self.assertEqual(stats.average_trip_duration, 7.5)
        self.assertEqual(stats.most_expensive_trip, "Japan Adventure")
        self.assertEqual(stats.budget_accuracy, 85.5)

    def test_user_stats_defaults(self):
        """Test UserStats with default values"""
        stats = UserStats()
        
        self.assertEqual(stats.total_trips, 0)
        self.assertEqual(stats.total_expenses, 0.0)
        self.assertEqual(stats.total_distance_traveled, 0.0)
        self.assertEqual(stats.countries_visited, [])
        self.assertEqual(stats.favorite_destinations, [])
        self.assertEqual(stats.average_trip_duration, 0.0)
        self.assertIsNone(stats.most_expensive_trip)
        self.assertEqual(stats.budget_accuracy, 0.0)


class TestAuthenticationModels(unittest.TestCase):
    """Test cases for authentication-related models"""

    def test_login_request(self):
        """Test LoginRequest model"""
        login_data = {
            "email": "login@example.com",
            "password": "loginpassword123"
        }
        login_request = LoginRequest(**login_data)
        
        self.assertEqual(login_request.email, "login@example.com")
        self.assertEqual(login_request.password, "loginpassword123")

    def test_login_response(self):
        """Test LoginResponse model"""
        user = User(
            id="user123",
            email="user@example.com",
            username="testuser"
        )
        
        login_response_data = {
            "access_token": "jwt_access_token",
            "refresh_token": "jwt_refresh_token",
            "expires_in": 3600,
            "user": user
        }
        login_response = LoginResponse(**login_response_data)
        
        self.assertEqual(login_response.access_token, "jwt_access_token")
        self.assertEqual(login_response.refresh_token, "jwt_refresh_token")
        self.assertEqual(login_response.token_type, "bearer")  # Default value
        self.assertEqual(login_response.expires_in, 3600)
        self.assertEqual(login_response.user.id, "user123")

    def test_refresh_token_request(self):
        """Test RefreshTokenRequest model"""
        refresh_data = {
            "refresh_token": "valid_refresh_token"
        }
        refresh_request = RefreshTokenRequest(**refresh_data)
        
        self.assertEqual(refresh_request.refresh_token, "valid_refresh_token")

    def test_password_reset_request(self):
        """Test PasswordResetRequest model"""
        reset_data = {
            "email": "reset@example.com"
        }
        reset_request = PasswordResetRequest(**reset_data)
        
        self.assertEqual(reset_request.email, "reset@example.com")

    def test_password_reset_confirm(self):
        """Test PasswordResetConfirm model"""
        confirm_data = {
            "token": "reset_token_123",
            "new_password": "newpassword123"
        }
        reset_confirm = PasswordResetConfirm(**confirm_data)
        
        self.assertEqual(reset_confirm.token, "reset_token_123")
        self.assertEqual(reset_confirm.new_password, "newpassword123")

    def test_email_verification_request(self):
        """Test EmailVerificationRequest model"""
        verification_data = {
            "token": "verification_token_456"
        }
        verification_request = EmailVerificationRequest(**verification_data)
        
        self.assertEqual(verification_request.token, "verification_token_456")


class TestUserModelValidation(unittest.TestCase):
    """Test validation edge cases for user models"""

    def test_user_empty_email(self):
        """Test user with empty email"""
        user_data = {
            "email": "",
            "username": "testuser"
        }
        
        with self.assertRaises(ValidationError):
            UserBase(**user_data)

    def test_user_invalid_email_format(self):
        """Test user with various invalid email formats"""
        invalid_emails = [
            "not_an_email",
            "@domain.com",
            "user@",
            "user space@domain.com",
            "user..double@domain.com"
        ]
        
        for email in invalid_emails:
            user_data = {
                "email": email,
                "username": "testuser"
            }
            
            with self.assertRaises(ValidationError, msg=f"Email {email} should be invalid"):
                UserBase(**user_data)

    def test_user_edge_case_usernames(self):
        """Test edge case usernames"""
        # Valid edge cases
        valid_usernames = ["user12", "a" * 50, "user_123", "user-name"]
        
        for username in valid_usernames:
            user_data = {
                "email": "test@example.com",
                "username": username
            }
            try:
                user = UserBase(**user_data)
                self.assertEqual(user.username, username)
            except ValidationError:
                self.fail(f"Username {username} should be valid")

    def test_user_phone_validation(self):
        """Test phone number validation"""
        # Valid phone numbers
        valid_phones = ["+1234567890", "+84987654321", "+447911123456"]
        
        for phone in valid_phones:
            user_data = {
                "email": "test@example.com",
                "username": "testuser",
                "phone": phone
            }
            try:
                user = UserBase(**user_data)
                self.assertEqual(user.phone, phone)
            except ValidationError:
                self.fail(f"Phone {phone} should be valid")


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)