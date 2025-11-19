"""
Authentication endpoints for TravelPro backend
"""
from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPBearer
from pydantic import BaseModel
from typing import Optional
import secrets
import string

from ...models.user import (
    User, LoginRequest, LoginResponse, RefreshTokenRequest,
    PasswordResetRequest, EmailVerificationRequest
)
from ...services.firebase_service import firebase_service
from ...core.dependencies import get_current_user, get_active_user
from ...core.config import get_settings

router = APIRouter(prefix="/auth", tags=["authentication"])
settings = get_settings()
security = HTTPBearer()

class GoogleSignInRequest(BaseModel):
    """Google Sign-In request model"""
    id_token: str
    access_token: Optional[str] = None

class FirebaseSignInRequest(BaseModel):
    """Firebase Sign-In request model"""  
    id_token: str

class CustomTokenRequest(BaseModel):
    """Custom token request model"""
    uid: str
    additional_claims: Optional[dict] = None

# =============== FIREBASE/GOOGLE AUTHENTICATION ===============

@router.post("/google/signin", response_model=LoginResponse)
async def google_sign_in(request: GoogleSignInRequest):
    """
    Sign in with Google OAuth token
    """
    try:
        # Verify Google OAuth token
        google_user_data = await firebase_service.verify_google_token(request.id_token)
        
        if not google_user_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Google token"
            )
        
        # Get or create user
        user = await firebase_service.get_or_create_user(google_user_data)
        
        # Create custom Firebase token for the user
        custom_token = await firebase_service.create_custom_token(
            user.id, 
            {"provider": "google"}
        )
        
        # Update last login
        await firebase_service.update_user_login(user.id)
        
        return LoginResponse(
            access_token=custom_token,
            refresh_token=generate_refresh_token(),
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=user
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Google sign-in error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication failed"
        )

@router.post("/firebase/signin", response_model=LoginResponse)
async def firebase_sign_in(request: FirebaseSignInRequest):
    """
    Sign in with Firebase ID token
    """
    try:
        # Verify Firebase ID token
        firebase_user_data = await firebase_service.verify_id_token(request.id_token)
        
        if not firebase_user_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Firebase token"
            )
        
        # Get or create user
        user = await firebase_service.get_or_create_user(firebase_user_data)
        
        # Update last login
        await firebase_service.update_user_login(user.id)
        
        return LoginResponse(
            access_token=request.id_token,  # Use the original token
            refresh_token=generate_refresh_token(),
            token_type="bearer", 
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=user
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Firebase sign-in error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication failed"
        )

@router.post("/custom-token")
async def create_custom_token(
    request: CustomTokenRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Create custom Firebase token (admin only)
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required"
        )
    
    try:
        custom_token = await firebase_service.create_custom_token(
            request.uid,
            request.additional_claims
        )
        
        return {
            "custom_token": custom_token,
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
    except Exception as e:
        print(f"Custom token creation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token creation failed"
        )

# =============== TOKEN REFRESH ===============

@router.post("/refresh")
async def refresh_token(request: RefreshTokenRequest):
    """
    Refresh access token
    Note: In a full implementation, you'd verify the refresh token
    """
    try:
        # TODO: Verify refresh token from database/Redis
        # For now, return a simple response
        
        return {
            "message": "Token refresh not implemented yet",
            "detail": "Use Firebase SDK to refresh tokens on client side"
        }
        
    except Exception as e:
        print(f"Token refresh error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token refresh failed"
        )

# =============== USER INFO & PROFILE ===============

@router.get("/me", response_model=User)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """
    Get current authenticated user information
    """
    return current_user

@router.put("/me")
async def update_current_user(
    update_data: dict,
    current_user: User = Depends(get_active_user)
):
    """
    Update current user profile
    """
    try:
        # Remove sensitive fields
        allowed_fields = {
            'first_name', 'last_name', 'phone', 'profile_picture',
            'preferred_currency', 'preferred_language', 'time_zone',
            'travel_preferences'
        }
        
        filtered_data = {
            k: v for k, v in update_data.items() 
            if k in allowed_fields
        }
        
        if not filtered_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No valid fields to update"
            )
        
        success = await firebase_service.update_user_profile(
            current_user.id,
            filtered_data
        )
        
        if success:
            return {"message": "Profile updated successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"Profile update error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Profile update failed"
        )

# =============== LOGOUT ===============

@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user)):
    """
    Logout user
    Note: Firebase tokens are stateless, so logout is mainly client-side
    """
    try:
        # In a full implementation, you might:
        # 1. Blacklist the current token
        # 2. Clear refresh tokens from database
        # 3. Log the logout event
        
        return {
            "message": "Logged out successfully",
            "detail": "Clear tokens from client storage"
        }
        
    except Exception as e:
        print(f"Logout error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Logout failed"
        )

# =============== ACCOUNT MANAGEMENT ===============

@router.delete("/me")
async def delete_account(current_user: User = Depends(get_current_user)):
    """
    Delete current user account
    """
    try:
        success = await firebase_service.delete_user(current_user.id)
        
        if success:
            return {"message": "Account deleted successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete account"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"Account deletion error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Account deletion failed"
        )

# =============== HEALTH CHECK ===============

@router.get("/health")
async def auth_health_check():
    """
    Authentication service health check
    """
    return {
        "status": "healthy",
        "service": "authentication",
        "provider": "firebase",
        "features": [
            "google_signin",
            "firebase_signin", 
            "custom_tokens",
            "profile_management"
        ]
    }

# =============== UTILITY FUNCTIONS ===============

def generate_refresh_token() -> str:
    """
    Generate a random refresh token
    In production, store this in database with expiration
    """
    return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(64))

# =============== DEV/TESTING ENDPOINTS ===============

@router.post("/dev/mock-login")
async def mock_login_for_development():
    """
    Mock login for development/testing (remove in production)
    """
    if not settings.DEBUG:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Endpoint not available"
        )
    
    # Create mock user for development
    mock_user = User(
        id="dev_user_123",
        email="developer@travelpro.com",
        username="developer",
        first_name="Dev",
        last_name="User",
        is_active=True,
        is_verified=True,
        preferred_currency="VND"
    )
    
    # Create mock token
    mock_token = await firebase_service.create_custom_token(
        mock_user.id,
        {"provider": "mock", "env": "development"}
    )
    
    return LoginResponse(
        access_token=mock_token or "mock_token_123",
        refresh_token=generate_refresh_token(),
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=mock_user
    )