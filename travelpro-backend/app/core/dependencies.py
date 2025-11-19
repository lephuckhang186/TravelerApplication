"""
Core dependencies for the TravelPro backend API.
"""
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from ..models.user import User
from ..services.firebase_service import firebase_service
from .config import get_settings

settings = get_settings()

# Security scheme for Firebase token authentication
security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """
    Get current authenticated user from Firebase ID token
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Extract token from credentials
        token = credentials.credentials
        
        if not token:
            raise credentials_exception
        
        # Verify Firebase ID token
        decoded_token = await firebase_service.verify_id_token(token)
        
        if not decoded_token:
            # Try Google OAuth token as fallback
            decoded_token = await firebase_service.verify_google_token(token)
        
        if not decoded_token:
            raise credentials_exception
        
        # Get or create user from Firebase data
        user = await firebase_service.get_or_create_user(decoded_token)
        
        if not user:
            raise credentials_exception
        
        # Update last login
        await firebase_service.update_user_login(user.id)
        
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Authentication error: {e}")
        raise credentials_exception

async def get_admin_user(current_user: User = Depends(get_current_user)) -> User:
    """
    Dependency to require admin privileges
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

async def get_active_user(current_user: User = Depends(get_current_user)) -> User:
    """
    Dependency to require active user status
    """
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is disabled"
        )
    return current_user

# Optional: For endpoints that work with or without authentication
async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        HTTPBearer(auto_error=False)
    )
) -> Optional[User]:
    """
    Optional authentication - returns None if no valid token
    """
    if not credentials:
        return None
    
    try:
        token = credentials.credentials
        decoded_token = await firebase_service.verify_id_token(token)
        
        if decoded_token:
            user = await firebase_service.get_or_create_user(decoded_token)
            return user
    except Exception:
        pass  # Silently fail for optional auth
    
    return None

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """
    Get the current authenticated user from the JWT token.
    
    Args:
        credentials: HTTP authorization credentials containing the JWT token
        
    Returns:
        User: The authenticated user object
        
    Raises:
        HTTPException: If the token is invalid or user not found
    """
    token = credentials.credentials
    
    # TODO: Implement JWT token verification
    # For now, return a mock user for development
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Mock user for development - replace with actual JWT verification
    mock_user = User(
        id="user_123",
        email="user@example.com",
        username="testuser",
        is_active=True
    )
    
    return mock_user

async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[User]:
    """
    Get the current user if authenticated, otherwise return None.
    
    Args:
        credentials: Optional HTTP authorization credentials
        
    Returns:
        Optional[User]: The authenticated user or None
    """
    if not credentials:
        return None
    
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None

# Dependency for admin users
async def get_admin_user(current_user: User = Depends(get_current_user)) -> User:
    """
    Get the current user and verify they have admin privileges.
    
    Args:
        current_user: The currently authenticated user
        
    Returns:
        User: The admin user
        
    Raises:
        HTTPException: If user is not an admin
    """
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user