"""
Firebase Authentication Service for TravelPro
"""
import os
import json
from typing import Optional, Dict, Any
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, auth, firestore
from google.oauth2 import id_token
from google.auth.transport import requests

from ..models.user import User, UserCreate, UserInDB
from ..core.config import get_settings

settings = get_settings()

class FirebaseService:
    """Firebase authentication and Firestore service"""
    
    def __init__(self):
        self.app = None
        self.db = None
        self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK"""
        try:
            # Option 1: Use service account key file
            if hasattr(settings, 'FIREBASE_SERVICE_ACCOUNT_PATH') and settings.FIREBASE_SERVICE_ACCOUNT_PATH:
                cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
                self.app = firebase_admin.initialize_app(cred)
            
            # Option 2: Use service account key from environment variable  
            elif hasattr(settings, 'FIREBASE_SERVICE_ACCOUNT_KEY') and settings.FIREBASE_SERVICE_ACCOUNT_KEY:
                service_account_info = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_KEY)
                cred = credentials.Certificate(service_account_info)
                self.app = firebase_admin.initialize_app(cred)
            
            # Option 3: Use default credentials (Google Cloud environment)
            else:
                cred = credentials.ApplicationDefault()
                self.app = firebase_admin.initialize_app(cred)
            
            # Initialize Firestore
            self.db = firestore.client()
            print("Firebase initialized successfully")
            
        except Exception as e:
            print(f"Firebase initialization failed: {e}")
            # In development, use mock service
            self.app = None
            self.db = None
    
    async def verify_id_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Verify Firebase ID token from client
        """
        try:
            # Verify the ID token
            decoded_token = auth.verify_id_token(token)
            return decoded_token
        except Exception as e:
            print(f"Token verification failed: {e}")
            return None
    
    async def verify_google_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Verify Google OAuth token directly
        """
        try:
            # Verify Google OAuth token
            idinfo = id_token.verify_oauth2_token(
                token, 
                requests.Request(), 
                settings.GOOGLE_CLIENT_ID
            )
            
            # Verify the issuer
            if idinfo['iss'] not in ['accounts.google.com', 'https://accounts.google.com']:
                raise ValueError('Wrong issuer.')
            
            return idinfo
        except ValueError as e:
            print(f"Google token verification failed: {e}")
            return None
    
    async def get_or_create_user(self, firebase_user_data: Dict[str, Any]) -> User:
        """
        Get existing user or create new user from Firebase data
        """
        uid = firebase_user_data['uid']
        email = firebase_user_data.get('email')
        name = firebase_user_data.get('name', '')
        picture = firebase_user_data.get('picture')
        
        try:
            # Try to get user from Firestore
            user_doc = self.db.collection('users').document(uid).get()
            
            if user_doc.exists:
                # User exists, return user data
                user_data = user_doc.to_dict()
                return User(
                    id=uid,
                    email=email,
                    username=user_data.get('username', email.split('@')[0]),
                    first_name=user_data.get('first_name', ''),
                    last_name=user_data.get('last_name', ''),
                    profile_picture=picture,
                    is_active=True,
                    is_verified=firebase_user_data.get('email_verified', False),
                    created_at=user_data.get('created_at', datetime.utcnow()),
                    last_login=datetime.utcnow(),
                    preferred_currency=user_data.get('preferred_currency', 'VND'),
                    preferred_language=user_data.get('preferred_language', 'en'),
                )
            else:
                # Create new user
                name_parts = name.split(' ', 1) if name else ['', '']
                first_name = name_parts[0] if name_parts else ''
                last_name = name_parts[1] if len(name_parts) > 1 else ''
                
                user_data = {
                    'email': email,
                    'username': email.split('@')[0] if email else f'user_{uid[:8]}',
                    'first_name': first_name,
                    'last_name': last_name,
                    'profile_picture': picture,
                    'is_active': True,
                    'is_verified': firebase_user_data.get('email_verified', False),
                    'created_at': datetime.utcnow(),
                    'last_login': datetime.utcnow(),
                    'preferred_currency': 'VND',
                    'preferred_language': 'en',
                    'travel_preferences': {}
                }
                
                # Save to Firestore
                self.db.collection('users').document(uid).set(user_data)
                
                return User(id=uid, **user_data)
                
        except Exception as e:
            print(f"Error getting/creating user: {e}")
            # Fallback: create minimal user object
            return User(
                id=uid,
                email=email or f'user_{uid}@firebase.local',
                username=email.split('@')[0] if email else f'user_{uid[:8]}',
                first_name=name.split(' ')[0] if name else '',
                last_name=' '.join(name.split(' ')[1:]) if name and ' ' in name else '',
                profile_picture=picture,
                is_active=True,
                is_verified=firebase_user_data.get('email_verified', False),
                created_at=datetime.utcnow(),
                last_login=datetime.utcnow()
            )
    
    async def update_user_login(self, user_id: str):
        """Update user's last login timestamp"""
        try:
            if self.db:
                self.db.collection('users').document(user_id).update({
                    'last_login': datetime.utcnow()
                })
        except Exception as e:
            print(f"Error updating user login: {e}")
    
    async def create_custom_token(self, uid: str, additional_claims: Optional[Dict] = None) -> str:
        """
        Create custom Firebase token for user
        """
        try:
            custom_token = auth.create_custom_token(uid, additional_claims)
            return custom_token.decode('utf-8')
        except Exception as e:
            print(f"Error creating custom token: {e}")
            return ""
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by Firebase UID"""
        try:
            if self.db:
                user_doc = self.db.collection('users').document(user_id).get()
                if user_doc.exists:
                    user_data = user_doc.to_dict()
                    return User(id=user_id, **user_data)
            return None
        except Exception as e:
            print(f"Error getting user by ID: {e}")
            return None
    
    async def update_user_profile(self, user_id: str, update_data: Dict[str, Any]) -> bool:
        """Update user profile in Firestore"""
        try:
            if self.db:
                update_data['updated_at'] = datetime.utcnow()
                self.db.collection('users').document(user_id).update(update_data)
                return True
            return False
        except Exception as e:
            print(f"Error updating user profile: {e}")
            return False
    
    async def delete_user(self, user_id: str) -> bool:
        """Delete user from Firebase Auth and Firestore"""
        try:
            # Delete from Firebase Auth
            auth.delete_user(user_id)
            
            # Delete from Firestore
            if self.db:
                self.db.collection('users').document(user_id).delete()
            
            return True
        except Exception as e:
            print(f"Error deleting user: {e}")
            return False

# Global Firebase service instance
firebase_service = FirebaseService()