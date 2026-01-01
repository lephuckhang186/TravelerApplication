"""
User models for the TravelPro backend API.
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    """
    Base user model with common fields.

    Attributes:
        email (EmailStr): User's email address.
        username (str): Unique username (6-50 characters).
        first_name (Optional[str]): User's first name.
        last_name (Optional[str]): User's last name.
        profile_picture (Optional[str]): URL to profile picture.
    """
    email: EmailStr
    username: str = Field(..., min_length=6, max_length=50)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    profile_picture: Optional[str] = None


class UserCreate(UserBase):
    """
    User creation model with password.

    Attributes:
        password (str): User's password (8-100 characters).
    """
    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """
    User update model - all fields optional.

    Attributes:
        email (Optional[EmailStr]): New email address.
        username (Optional[str]): New username.
        first_name (Optional[str]): New first name.
        last_name (Optional[str]): New last name.
        profile_picture (Optional[str]): New profile picture URL.
    """
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=6, max_length=50)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    profile_picture: Optional[str] = None


class UserPasswordUpdate(BaseModel):
    """
    Model for password updates.

    Attributes:
        current_password (str): The user's current password.
        new_password (str): The new password (8-100 characters).
    """
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=100)


class User(UserBase):
    """
    Complete user model with database fields.

    Attributes:
        id (str): Unique user ID (e.g., Firebase UID).
        is_active (bool): Whether the account is active.
        is_admin (bool): Whether the user has admin privileges.
        is_verified (bool): Whether the email is verified.
        created_at (datetime): Account creation timestamp.
        updated_at (datetime): Last update timestamp.
        last_login (Optional[datetime]): Timestamp of last login.
        preferred_currency (str): User's preferred currency (default: VND).
        preferred_language (str): User's preferred language (default: en).
        time_zone (str): User's time zone (default: UTC).
        travel_preferences (Optional[dict]): Dictionary of travel preferences.
    """
    id: str
    is_active: bool = True
    is_admin: bool = False
    is_verified: bool = False
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    last_login: Optional[datetime] = None
    
    # Travel-specific fields
    preferred_currency: str = "VND"
    preferred_language: str = "en"
    time_zone: str = "UTC"
    travel_preferences: Optional[dict] = None
    
    class Config:
        """Pydantic configuration."""
        from_attributes = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class UserInDB(User):
    """
    User model with sensitive fields for database storage.

    Attributes:
        hashed_password (str): The hashed password.
    """
    hashed_password: str


class UserProfile(BaseModel):
    """
    Public user profile model.

    Attributes:
        id (str): User ID.
        username (str): Username.
        first_name (Optional[str]): First name.
        last_name (Optional[str]): Last name.
        profile_picture (Optional[str]): Profile picture URL.
        created_at (datetime): Account creation date.
    """
    id: str
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    profile_picture: Optional[str] = None
    created_at: datetime
    
    @property
    def display_name(self) -> str:
        """
        Get the user's display name.

        Returns:
            str: Full name if available, otherwise first name or username.
        """
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        elif self.first_name:
            return self.first_name
        else:
            return self.username


class UserStats(BaseModel):
    """
    User statistics model.

    Attributes:
        total_trips (int): Total number of trips created.
        total_expenses (float): Total expenses tracked.
        total_distance_traveled (float): Estimated distance traveled.
        countries_visited (List[str]): List of countries visited.
        favorite_destinations (List[str]): List of favorite destinations.
        average_trip_duration (float): Average duration of trips in days.
        most_expensive_trip (Optional[str]): Name of the most expensive trip.
        budget_accuracy (float): Percentage of how close to budget user typically stays.
    """
    total_trips: int = 0
    total_expenses: float = 0.0
    total_distance_traveled: float = 0.0
    countries_visited: List[str] = []
    favorite_destinations: List[str] = []
    average_trip_duration: float = 0.0
    most_expensive_trip: Optional[str] = None
    budget_accuracy: float = 0.0  # Percentage of how close to budget user typically stays


class LoginRequest(BaseModel):
    """
    Login request model.

    Attributes:
        email (EmailStr): User's email.
        password (str): User's password.
    """
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """
    Login response model.

    Attributes:
        access_token (str): OAuth2 access token.
        refresh_token (str): OAuth2 refresh token.
        token_type (str): Token type (default: bearer).
        expires_in (int): Token expiration time in seconds.
        user (User): The authenticated user object.
    """
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: User


class RefreshTokenRequest(BaseModel):
    """
    Refresh token request model.

    Attributes:
        refresh_token (str): The refresh token to use.
    """
    refresh_token: str


class PasswordResetRequest(BaseModel):
    """
    Password reset request model.
    
    Attributes:
        email (EmailStr): Email to send reset link to.
    """
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """
    Password reset confirmation model.

    Attributes:
        token (str): The reset token.
        new_password (str): The new password.
    """
    token: str
    new_password: str = Field(..., min_length=8, max_length=100)


class EmailVerificationRequest(BaseModel):
    """
    Email verification request model.

    Attributes:
        token (str): The verification token.
    """
    token: str