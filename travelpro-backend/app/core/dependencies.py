"""
Core dependencies for the TravelPro backend API.
"""
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import sys
import os

# Add parent directories to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from models.user import User
from services.firebase_service import firebase_service
from core.config import get_settings

settings = get_settings()

# Security scheme for Firebase token authentication
security = HTTPBearer()

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
    from datetime import datetime
    mock_user = User(
        id="user_123",
        email="user@example.com",
        username="testuser",
        is_active=True,
        is_admin=False,
        is_verified=True,
        created_at=datetime.now(),
        updated_at=datetime.now(),
        preferred_currency="VND",
        preferred_language="en",
        time_zone="UTC"
    )
    
    return mock_user

async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        HTTPBearer(auto_error=False)
    )
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

# Dependency for active users
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