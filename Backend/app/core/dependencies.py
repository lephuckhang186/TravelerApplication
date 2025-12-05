"""
Core dependencies for the TravelPro backend API.
"""
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import sys
import os

from sqlalchemy.orm import Session
from app.models.user import User
from app.services.firebase_service import firebase_service
from app.core.config import get_settings
# Database removed - using Firebase only

settings = get_settings()

# Security scheme for Firebase token authentication
security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """
    Get the current authenticated user from Firebase ID token.
    
    Args:
        credentials: HTTP authorization credentials containing Firebase ID token
        
    Returns:
        User: The authenticated user object
        
    Raises:
        HTTPException: If the token is invalid or user not found
    """
    token = credentials.credentials
    
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        # Verify Firebase ID token
        decoded_token = await firebase_service.verify_id_token(token)
        
        if not decoded_token:
                raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Firebase token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Get or create user from Firebase data
        user = await firebase_service.get_or_create_user(decoded_token)
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is inactive"
            )
        
        # Update last login timestamp
        await firebase_service.update_user_login(user.id)
        
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Authentication error: {e}")
        
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )

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

# Alias for Firebase user (same as current user)
async def get_firebase_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """
    Get Firebase authenticated user (alias for get_current_user)
    """
    return await get_current_user(credentials)


def get_db() -> Session:
    """
    Database dependency for SQLAlchemy sessions
    Note: This is a placeholder. In a real app, you'd create a proper SQLAlchemy session.
    For now, we'll return None as the database operations use Firebase and db_manager.
    """
    return None


async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """
    Get current active user (alias for get_active_user for compatibility)
    """
    return await get_active_user(current_user)