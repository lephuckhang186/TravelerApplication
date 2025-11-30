"""
User models for the TravelPro backend API.
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    """Base user model with common fields."""
    email: EmailStr
    username: str = Field(..., min_length=6, max_length=50)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    profile_picture: Optional[str] = None


class UserCreate(UserBase):
    """User creation model with password."""
    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """User update model - all fields optional."""
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=6, max_length=50)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    profile_picture: Optional[str] = None
    full_name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = Field(None, max_length=200)
    gender: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[datetime] = None


class UserPasswordUpdate(BaseModel):
    """Model for password updates."""
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=100)


class User(UserBase):
    """Complete user model with database fields."""
    id: str
    is_active: bool = True
    is_admin: bool = False
    is_verified: bool = False
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    last_login: Optional[datetime] = None
    
    # Extended profile fields
    full_name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = Field(None, max_length=200)
    gender: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[datetime] = None
    
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
    """User model with sensitive fields for database storage."""
    hashed_password: str


class UserProfile(BaseModel):
    """Public user profile model."""
    id: str
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    profile_picture: Optional[str] = None
    created_at: datetime
    
    @property
    def display_name(self) -> str:
        """Get the user's display name."""
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        elif self.first_name:
            return self.first_name
        else:
            return self.username


class UserStats(BaseModel):
    """User statistics model."""
    total_trips: int = 0
    total_expenses: float = 0.0
    total_distance_traveled: float = 0.0
    countries_visited: List[str] = []
    favorite_destinations: List[str] = []
    average_trip_duration: float = 0.0
    most_expensive_trip: Optional[str] = None
    budget_accuracy: float = 0.0  # Percentage of how close to budget user typically stays


class LoginRequest(BaseModel):
    """Login request model."""
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """Login response model."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: User


class RefreshTokenRequest(BaseModel):
    """Refresh token request model."""
    refresh_token: str


class PasswordResetRequest(BaseModel):
    """Password reset request model."""
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """Password reset confirmation model."""
    token: str
    new_password: str = Field(..., min_length=8, max_length=100)


class EmailVerificationRequest(BaseModel):
    """Email verification request model."""
    token: str