"""
Authentication endpoints for TravelPro backend.
"""
from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPBearer
from pydantic import BaseModel
from typing import Optional
import secrets
import string

from app.models.user import (
    User, LoginRequest, LoginResponse, RefreshTokenRequest,
    PasswordResetRequest, EmailVerificationRequest
)
from app.services.firebase_service import firebase_service
from app.core.dependencies import get_current_user, get_active_user
from app.core.config import get_settings

router = APIRouter(prefix="/auth", tags=["authentication"])
settings = get_settings()
security = HTTPBearer()

class GoogleSignInRequest(BaseModel):
    """
    Google Sign-In request model.

    Attributes:
        id_token (str): The Google ID token.
        access_token (Optional[str]): The Google Access Token (optional).
    """
    id_token: str
    access_token: Optional[str] = None

class FirebaseSignInRequest(BaseModel):
    """
    Firebase Sign-In request model.

    Attributes:
        id_token (str): The Firebase ID token.
    """
    id_token: str

class CustomTokenRequest(BaseModel):
    """
    Custom token request model.

    Attributes:
        uid (str): The specific user ID.
        additional_claims (Optional[dict]): Additional custom claims for the token.
    """
    uid: str
    additional_claims: Optional[dict] = None

class SyncUserRequest(BaseModel):
    """
    Sync user data request model.

    Attributes:
        uid (str): The user ID (Firebase UID).
        email (str): The user's email address.
        display_name (Optional[str]): The user's display name.
        photo_url (Optional[str]): The URL to the user's photo.
    """
    uid: str
    email: str
    display_name: Optional[str] = None
    photo_url: Optional[str] = None

# =============== FIREBASE/GOOGLE AUTHENTICATION ===============

@router.post("/google/signin", response_model=LoginResponse)
async def google_sign_in(request: GoogleSignInRequest):
    """
    Sign in with Google OAuth token.

    Verifies the Google ID token, retrieves or creates the user, and issues a custom access token.

    Args:
        request (GoogleSignInRequest): The Google sign-in request containing the ID token.

    Returns:
        LoginResponse: An object containing tokens and user information.

    Raises:
        HTTPException(401): If the Google token is invalid.
        HTTPException(500): If authentication fails.
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
    Sign in with Firebase ID token.

    Verifies a standard Firebase ID token, ensuring the user exists.

    Args:
        request (FirebaseSignInRequest): The Firebase sign-in request containing the ID token.

    Returns:
        LoginResponse: An object containing tokens and user information.

    Raises:
        HTTPException(401): If the Firebase token is invalid.
        HTTPException(500): If authentication fails.
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

@router.post("/sync-user")
async def sync_user(request: SyncUserRequest):
    """
    Sync user data with backend (called from Flutter app).

    Updates the user's profile information in the backend database based on FirebaseAuth user data.

    Args:
        request (SyncUserRequest): The user data to sync.

    Returns:
        dict: A success message and the user UID.

    Raises:
        HTTPException(500): If the sync operation fails.
    """
    try:
        # Update user profile with data from Firebase
        update_data = {
            "display_name": request.display_name,
            "photo_url": request.photo_url,
            "email": request.email
        }
        
        # Filter out None values
        filtered_data = {k: v for k, v in update_data.items() if v is not None}
        
        success = await firebase_service.update_user_profile(
            request.uid,
            filtered_data
        )
        
        if success:
            return {
                "message": "User data synced successfully",
                "uid": request.uid
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to sync user data"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"User sync error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="User sync failed"
        )

@router.post("/custom-token")
async def create_custom_token(
    request: CustomTokenRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Create custom Firebase token (admin only).

    Args:
        request (CustomTokenRequest): The request details for the custom token.
        current_user (User): The current authenticated user (must be admin).

    Returns:
        dict: The custom token and its expiration details.

    Raises:
        HTTPException(403): If the user is not an admin.
        HTTPException(500): If token creation fails.
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
    Refresh access token using Firebase Admin SDK.

    Note: This validates the refresh token (acting as an ID token here for simplicity) and returns user info.
    In a full production flow, this would handle actual refresh token rotation.

    Args:
        request (RefreshTokenRequest): The request containing the refresh token.

    Returns:
        dict: Status message and user ID.

    Raises:
        HTTPException(500): If token refresh fails.
    """
    try:
        # Verify the refresh token is actually a valid Firebase ID token
        # In production, you would store refresh tokens in Redis/database
        # For now, we validate the token with Firebase
        from firebase_admin import auth as firebase_auth
        
        decoded_token = firebase_auth.verify_id_token(request.refresh_token)
        user_id = decoded_token['uid']
        
        return {
            "message": "Token is valid",
            "user_id": user_id,
            "detail": "Use Firebase SDK to refresh tokens on client side for new access tokens"
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
    Get current authenticated user information.

    Args:
        current_user (User): The current authenticated user.

    Returns:
        User: The user profile information.
    """
    return current_user

@router.put("/me")
async def update_current_user(
    update_data: dict,
    current_user: User = Depends(get_active_user)
):
    """
    Update current user profile.

    Filtering limits updates to allowed fields only.

    Args:
        update_data (dict): The fields to update.
        current_user (User): The current authenticated user.

    Returns:
        dict: Success message.

    Raises:
        HTTPException(400): If no valid fields are provided.
        HTTPException(500): If the profile update fails.
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
    Logout user.
    
    Note: Firebase tokens are stateless, so logout is mainly client-side clearing.

    Args:
        current_user (User): The current authenticated user.

    Returns:
        dict: Logout success message.

    Raises:
        HTTPException(500): If the logout process fails.
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
    Delete current user account.

    Removes the user from both the application database and Firebase Authentication.

    Args:
        current_user (User): The current authenticated user.

    Returns:
        dict: Success message.

    Raises:
        HTTPException(500): If account deletion fails.
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
    Authentication service health check.

    Returns:
        dict: Health status and capabilities.
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
    Generate a random refresh token.

    Returns:
        str: A random string to be used as a refresh token.
    """
    return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(64))

