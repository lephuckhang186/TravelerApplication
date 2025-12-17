"""
Firebase Authentication and Firestore Service for TravelPro
"""
import os
import json
import sys
from typing import Optional, Dict, Any, List
from datetime import datetime, date
from decimal import Decimal

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import firebase_admin
from firebase_admin import credentials, auth, firestore
from google.oauth2 import id_token
from google.auth.transport import requests

from models.user import User, UserCreate, UserInDB
from core.config import get_settings

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
            # Check if Firebase app is already initialized
            try:
                self.app = firebase_admin.get_app()
                print("Using existing Firebase app")
            except ValueError:
                # App doesn't exist, create new one
                # Option 1: Use service account key file
                if hasattr(settings, 'FIREBASE_SERVICE_ACCOUNT_PATH') and settings.FIREBASE_SERVICE_ACCOUNT_PATH:
                    if os.path.exists(settings.FIREBASE_SERVICE_ACCOUNT_PATH):
                        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
                        self.app = firebase_admin.initialize_app(cred)
                    else:
                        raise FileNotFoundError(f"Firebase service account file not found: {settings.FIREBASE_SERVICE_ACCOUNT_PATH}")
                
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
            print("WARNING: Firebase credentials not found, using fallback mode")
            self.app = None
            self.db = None
    
    async def verify_id_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Verify Firebase ID token from client
        """
        try:
            # Ensure Firebase is properly initialized
            if self.app is None:
                return None
            
            # Verify the ID token with Firebase
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
    
    # ============= TRIP MANAGEMENT =============
    
    async def create_trip(self, user_id: str, trip_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new trip in Firestore"""
        try:
            trip_id = f"trip_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{user_id[:8]}"
            
            trip_doc = {
                'id': trip_id,
                'user_id': user_id,
                'name': trip_data['name'],
                'destination': trip_data['destination'],
                'description': trip_data.get('description', ''),
                'start_date': trip_data['start_date'],
                'end_date': trip_data['end_date'],
                'total_budget': trip_data.get('total_budget', 0.0),
                'currency': trip_data.get('currency', 'VND'),
                'is_active': True,
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }
            
            self.db.collection('trips').document(trip_id).set(trip_doc)
            print(f"✅ FIRESTORE: Created trip {trip_id}")
            return trip_doc
        except Exception as e:
            print(f"❌ FIRESTORE_TRIP_ERROR: {e}")
            raise
    
    async def get_user_trips(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all trips for a user - supports multiple storage patterns"""
        try:
            trips = []
            
            # Pattern 1: users/{userId}/trips/{tripId} (Flutter app structure)
            try:
                user_trips_ref = (self.db.collection('users')
                                 .document(user_id)
                                 .collection('trips')
                                 .stream())
                user_trips = []
                for doc in user_trips_ref:
                    trip_data = doc.to_dict()
                    trip_data['id'] = doc.id  # Ensure ID is set
                    user_trips.append(trip_data)
                
                if user_trips:
                    print(f"✅ FOUND_USER_TRIPS: Found {len(user_trips)} trips in users/{user_id}/trips")
                    trips.extend(user_trips)
            except Exception as e:
                print(f"⚠️ Error loading from users/{user_id}/trips: {e}")
            
            # Pattern 2: trips/{tripId} with user_id field (Backend structure)
            try:
                backend_trips_ref = self.db.collection('trips').where('user_id', '==', user_id).stream()
                backend_trips = [doc.to_dict() for doc in backend_trips_ref]
                if backend_trips:
                    print(f"✅ FOUND_BACKEND_TRIPS: Found {len(backend_trips)} trips in trips collection")
                    trips.extend(backend_trips)
            except Exception as e:
                print(f"⚠️ Error loading from trips collection: {e}")
            
            # Remove duplicates based on trip ID
            unique_trips = {}
            for trip in trips:
                trip_id = trip.get('id')
                if trip_id and trip_id not in unique_trips:
                    unique_trips[trip_id] = trip
            
            result = list(unique_trips.values())
            print(f"📊 GET_USER_TRIPS: Returning {len(result)} unique trips for user {user_id}")
            return sorted(result, key=lambda x: x.get('created_at', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_TRIPS_ERROR: {e}")
            return []
    
    async def get_trip(self, trip_id: str, user_id: str = None) -> Optional[Dict[str, Any]]:
        """Get specific trip - supports multiple storage patterns"""
        try:
            print(f"🔍 FIRESTORE_GET_TRIP: Looking for trip {trip_id}, user={user_id}")
            
            # Pattern 1: users/{userId}/trips/{tripId} (Flutter app structure)
            if user_id:
                user_trip_doc = self.db.collection('users').document(user_id).collection('trips').document(trip_id).get()
                if user_trip_doc.exists:
                    trip_data = user_trip_doc.to_dict()
                    trip_data['id'] = trip_id  # Ensure ID is set
                    print(f"✅ TRIP_FOUND in users/{user_id}/trips: {trip_data.get('name')}")
                    return trip_data
            
            # Pattern 2: trips/{tripId} (Backend structure)
            trip_doc = self.db.collection('trips').document(trip_id).get()
            if trip_doc.exists:
                trip_data = trip_doc.to_dict()
                print(f"✅ TRIP_FOUND in trips collection: {trip_data.get('name')} - Owner: {trip_data.get('user_id')}")
                if user_id and trip_data.get('user_id') != user_id:
                    print(f"❌ TRIP_OWNER_MISMATCH: Trip belongs to {trip_data.get('user_id')}, not {user_id}")
                    return None
                return trip_data
            
            # Pattern 3: planners/{plannerId} (Alternative structure)
            planner_doc = self.db.collection('planners').document(trip_id).get()
            if planner_doc.exists:
                planner_data = planner_doc.to_dict()
                print(f"✅ FOUND_AS_PLANNER: Trip {trip_id} exists in 'planners' collection")
                if user_id and planner_data.get('user_id') != user_id:
                    print(f"❌ PLANNER_OWNER_MISMATCH: Planner belongs to {planner_data.get('user_id')}, not {user_id}")
                    return None
                return planner_data
            
            # Pattern 4: shared_trips/{tripId} (Collaboration mode)
            shared_trip_doc = self.db.collection('shared_trips').document(trip_id).get()
            if shared_trip_doc.exists:
                shared_trip_data = shared_trip_doc.to_dict()
                print(f"✅ FOUND_AS_SHARED_TRIP: Trip {trip_id} exists in 'shared_trips' collection")
                shared_trip_data['id'] = trip_id  # Ensure ID is set
                # For shared trips, check if user is owner or collaborator
                if user_id:
                    owner_id = shared_trip_data.get('ownerId') or shared_trip_data.get('owner_id')
                    if owner_id == user_id:
                        print(f"✅ USER_IS_OWNER: User {user_id} is owner of shared trip")
                        return shared_trip_data
                    
                    # Check if user is collaborator
                    collaborators = shared_trip_data.get('sharedCollaborators', [])
                    is_collaborator = any(
                        c.get('userId') == user_id or c.get('user_id') == user_id 
                        for c in collaborators
                    )
                    if is_collaborator:
                        print(f"✅ USER_IS_COLLABORATOR: User {user_id} is collaborator on shared trip")
                        return shared_trip_data
                    
                    print(f"❌ USER_NO_ACCESS: User {user_id} has no access to shared trip")
                    return None
                
                # If no user_id provided, return the trip (for public access check later)
                return shared_trip_data
            
            print(f"❌ TRIP_NOT_FOUND: Trip {trip_id} not found in any collection")
            return None
        except Exception as e:
            print(f"❌ FIRESTORE_GET_TRIP_ERROR: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    async def update_trip(self, trip_id: str, user_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update trip - supports multiple storage patterns"""
        try:
            updates['updated_at'] = datetime.utcnow().isoformat()
            updated = False
            
            # Pattern 1: Update users/{userId}/trips/{tripId} (Flutter app structure)
            if user_id:
                try:
                    user_trip_ref = self.db.collection('users').document(user_id).collection('trips').document(trip_id)
                    user_trip_doc = user_trip_ref.get()
                    if user_trip_doc.exists:
                        user_trip_ref.update(updates)
                        print(f"✅ UPDATED: users/{user_id}/trips/{trip_id}")
                        updated = True
                except Exception as e:
                    print(f"⚠️ Could not update users/{user_id}/trips/{trip_id}: {e}")
            
            # Pattern 2: Update trips/{tripId} (Backend structure)
            try:
                trip_ref = self.db.collection('trips').document(trip_id)
                trip_doc = trip_ref.get()
                
                if trip_doc.exists:
                    trip_data = trip_doc.to_dict()
                    if not user_id or trip_data.get('user_id') == user_id:
                        trip_ref.update(updates)
                        print(f"✅ UPDATED: trips/{trip_id}")
                        updated = True
            except Exception as e:
                print(f"⚠️ Could not update trips/{trip_id}: {e}")
            
            if updated:
                return await self.get_trip(trip_id, user_id)
            else:
                print(f"❌ UPDATE_TRIP_FAILED: Trip {trip_id} not found in any collection")
                return None
                
        except Exception as e:
            print(f"❌ FIRESTORE_UPDATE_TRIP_ERROR: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    async def delete_trip(self, trip_id: str, user_id: str) -> bool:
        """Delete trip and all related data"""
        try:
            trip_doc = await self.get_trip(trip_id, user_id)
            if not trip_doc:
                return False
            
            # Delete related expenses
            expenses_ref = self.db.collection('expenses').where('planner_id', '==', trip_id).stream()
            for exp_doc in expenses_ref:
                exp_doc.reference.delete()
            
            # Delete related activities
            activities_ref = self.db.collection('activities').where('planner_id', '==', trip_id).stream()
            for act_doc in activities_ref:
                act_doc.reference.delete()
            
            # Delete trip
            self.db.collection('trips').document(trip_id).delete()
            
            print(f"✅ FIRESTORE: Deleted trip {trip_id}")
            return True
        except Exception as e:
            print(f"❌ FIRESTORE_DELETE_TRIP_ERROR: {e}")
            return False
    
    # ============= PLANNER MANAGEMENT =============
    
    async def create_planner(self, user_id: str, planner_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new planner in Firestore"""
        try:
            planner_id = f"planner_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{user_id[:8]}"
            
            planner_doc = {
                'id': planner_id,
                'user_id': user_id,
                'name': planner_data['name'],
                'description': planner_data.get('description', ''),
                'start_date': planner_data['start_date'],
                'end_date': planner_data['end_date'],
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }
            
            self.db.collection('planners').document(planner_id).set(planner_doc)
            print(f"✅ FIRESTORE: Created planner {planner_id}")
            return planner_doc
        except Exception as e:
            print(f"❌ FIRESTORE_PLANNER_ERROR: {e}")
            raise
    
    async def get_user_planners(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all planners for a user"""
        try:
            planners_ref = self.db.collection('planners').where('user_id', '==', user_id).stream()
            planners = [doc.to_dict() for doc in planners_ref]
            return sorted(planners, key=lambda x: x.get('created_at', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_PLANNERS_ERROR: {e}")
            return []
    
    async def get_planner(self, planner_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Get specific planner"""
        try:
            planner_doc = self.db.collection('planners').document(planner_id).get()
            if planner_doc.exists:
                planner_data = planner_doc.to_dict()
                if planner_data.get('user_id') != user_id:
                    return None
                return planner_data
            return None
        except Exception as e:
            print(f"❌ FIRESTORE_GET_PLANNER_ERROR: {e}")
            return None
    
    # ============= ACTIVITY MANAGEMENT =============
    
    async def create_activity(self, planner_id: str, activity_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new activity"""
        try:
            activity_id = f"activity_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{planner_id[:8]}"
            
            activity_doc = {
                'id': activity_id,
                'planner_id': planner_id,
                'name': activity_data['name'],
                'description': activity_data.get('description', ''),
                'start_time': activity_data['start_time'],
                'end_time': activity_data['end_time'],
                'location': activity_data.get('location', ''),
                'check_in': activity_data.get('check_in', False),
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }
            
            self.db.collection('activities').document(activity_id).set(activity_doc)
            print(f"✅ FIRESTORE: Created activity {activity_id}")
            return activity_doc
        except Exception as e:
            print(f"❌ FIRESTORE_ACTIVITY_ERROR: {e}")
            raise
    
    async def get_planner_activities(self, planner_id: str) -> List[Dict[str, Any]]:
        """Get all activities for a planner"""
        try:
            activities_ref = self.db.collection('activities').where('planner_id', '==', planner_id).stream()
            activities = [doc.to_dict() for doc in activities_ref]
            return sorted(activities, key=lambda x: x.get('start_time', ''))
        except Exception as e:
            print(f"❌ FIRESTORE_GET_ACTIVITIES_ERROR: {e}")
            return []
    
    async def get_activity(self, activity_id: str) -> Optional[Dict[str, Any]]:
        """Get specific activity"""
        try:
            activity_doc = self.db.collection('activities').document(activity_id).get()
            if activity_doc.exists:
                return activity_doc.to_dict()
            return None
        except Exception as e:
            print(f"❌ FIRESTORE_GET_ACTIVITY_ERROR: {e}")
            return None
    
    async def update_activity(self, activity_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update activity"""
        try:
            activity_ref = self.db.collection('activities').document(activity_id)
            activity_doc = activity_ref.get()
            
            if not activity_doc.exists:
                return None
            
            updates['updated_at'] = datetime.utcnow().isoformat()
            activity_ref.update(updates)
            
            return await self.get_activity(activity_id)
        except Exception as e:
            print(f"❌ FIRESTORE_UPDATE_ACTIVITY_ERROR: {e}")
            return None
    
    async def get_all_activities(self) -> List[Dict[str, Any]]:
        """Get all activities"""
        try:
            activities_ref = self.db.collection('activities').stream()
            activities = [doc.to_dict() for doc in activities_ref]
            return sorted(activities, key=lambda x: x.get('created_at', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_ALL_ACTIVITIES_ERROR: {e}")
            return []
    
    # ============= EXPENSE MANAGEMENT =============
    
    async def create_expense(self, planner_id: str, expense_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new expense - supports multiple storage patterns"""
        try:
            expense_id = f"expense_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{planner_id[:8]}"
            
            expense_doc = {
                'id': expense_id,
                'planner_id': planner_id,
                'name': expense_data['name'],
                'amount': float(expense_data['amount']),
                'currency': expense_data.get('currency', 'VND'),
                'category': expense_data['category'],
                'date': expense_data['date'],
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }
            
            # Save to main expenses collection
            self.db.collection('expenses').document(expense_id).set(expense_doc)
            print(f"✅ FIRESTORE: Created expense {expense_id} in expenses collection")
            print(f"   - Amount: {expense_doc['amount']} {expense_doc['currency']}")
            print(f"   - Category: {expense_doc['category']}")
            print(f"   - Planner ID: {planner_id}")
            
            return expense_doc
        except Exception as e:
            print(f"❌ FIRESTORE_EXPENSE_ERROR: {e}")
            import traceback
            traceback.print_exc()
            raise
    
    async def get_trip_expenses(self, trip_id: str, user_id: str = None) -> List[Dict[str, Any]]:
        """Get all expenses for a trip - supports multiple storage patterns"""
        try:
            print(f"📊 FIRESTORE_GET_EXPENSES: Loading expenses for trip {trip_id}, user={user_id}")
            
            # Verify trip belongs to user if user_id provided
            if user_id:
                trip = await self.get_trip(trip_id, user_id)
                if not trip:
                    print(f"⚠️ TRIP_VERIFICATION_FAILED: Trip {trip_id} not found for user {user_id}")
                    print(f"   Trying to load expenses anyway (trip might exist in different collection)...")
            
            # Pattern 1: Load from main expenses collection
            expenses_ref = self.db.collection('expenses').where('planner_id', '==', trip_id).stream()
            expenses = [doc.to_dict() for doc in expenses_ref]
            print(f"✅ LOADED_EXPENSES from expenses collection: Found {len(expenses)} expenses")
            
            # Pattern 2: Also check users/{userId}/trips/{tripId}/expenses if user_id provided
            if user_id and len(expenses) == 0:
                print(f"🔍 CHECKING ALTERNATIVE: users/{user_id}/trips/{trip_id}/expenses")
                user_expenses_ref = (self.db.collection('users')
                                    .document(user_id)
                                    .collection('trips')
                                    .document(trip_id)
                                    .collection('expenses')
                                    .stream())
                user_expenses = [doc.to_dict() for doc in user_expenses_ref]
                if user_expenses:
                    print(f"✅ FOUND_ALTERNATIVE: Found {len(user_expenses)} expenses in user's trip subcollection")
                    expenses.extend(user_expenses)
            
            if expenses:
                for exp in expenses:
                    print(f"   - {exp.get('id')}: {exp.get('amount')} {exp.get('currency')} - {exp.get('name')}")
            else:
                print(f"   ⚠️ No expenses found for trip {trip_id}")
                print(f"   💡 TIP: Create an expense through the API: POST /api/v1/expenses/")
                print(f"         with planner_id={trip_id}")
            
            return sorted(expenses, key=lambda x: x.get('date', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_EXPENSES_ERROR: {e}")
            import traceback
            traceback.print_exc()
            return []
    
    async def get_user_expenses(self, user_id: str, start_date: str = None, end_date: str = None, category: str = None) -> List[Dict[str, Any]]:
        """Get all expenses for a user across all trips"""
        try:
            # Get all user trips
            trips = await self.get_user_trips(user_id)
            trip_ids = [trip['id'] for trip in trips]
            
            if not trip_ids:
                return []
            
            # Get expenses for all trips
            all_expenses = []
            for trip_id in trip_ids:
                expenses_ref = self.db.collection('expenses').where('planner_id', '==', trip_id).stream()
                for doc in expenses_ref:
                    expense = doc.to_dict()
                    
                    # Apply filters
                    if start_date and expense.get('date', '') < start_date:
                        continue
                    if end_date and expense.get('date', '') > end_date:
                        continue
                    if category and expense.get('category') != category:
                        continue
                    
                    all_expenses.append(expense)
            
            return sorted(all_expenses, key=lambda x: x.get('date', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_USER_EXPENSES_ERROR: {e}")
            return []
    
    async def get_expense(self, expense_id: str) -> Optional[Dict[str, Any]]:
        """Get specific expense"""
        try:
            expense_doc = self.db.collection('expenses').document(expense_id).get()
            if expense_doc.exists:
                return expense_doc.to_dict()
            return None
        except Exception as e:
            print(f"❌ FIRESTORE_GET_EXPENSE_ERROR: {e}")
            return None
    
    async def delete_expense(self, expense_id: str, user_id: str) -> bool:
        """Delete expense with user verification"""
        try:
            expense = await self.get_expense(expense_id)
            if not expense:
                return False
            
            # Verify trip belongs to user
            trip = await self.get_trip(expense['planner_id'], user_id)
            if not trip:
                return False
            
            self.db.collection('expenses').document(expense_id).delete()
            print(f"✅ FIRESTORE: Deleted expense {expense_id}")
            return True
        except Exception as e:
            print(f"❌ FIRESTORE_DELETE_EXPENSE_ERROR: {e}")
            return False
    
    async def delete_trip_expenses(self, trip_id: str, user_id: str) -> int:
        """Delete all expenses for a trip"""
        try:
            trip = await self.get_trip(trip_id, user_id)
            if not trip:
                return 0
            
            expenses_ref = self.db.collection('expenses').where('planner_id', '==', trip_id).stream()
            count = 0
            for doc in expenses_ref:
                doc.reference.delete()
                count += 1
            
            print(f"✅ FIRESTORE: Deleted {count} expenses for trip {trip_id}")
            return count
        except Exception as e:
            print(f"❌ FIRESTORE_DELETE_EXPENSES_ERROR: {e}")
            return 0
    
    async def get_planner_expenses(self, planner_id: str) -> List[Dict[str, Any]]:
        """Get all expenses for a planner"""
        try:
            expenses_ref = self.db.collection('expenses').where('planner_id', '==', planner_id).stream()
            expenses = [doc.to_dict() for doc in expenses_ref]
            return sorted(expenses, key=lambda x: x.get('date', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_PLANNER_EXPENSES_ERROR: {e}")
            return []
    
    # ============= COLLABORATOR MANAGEMENT =============
    
    async def create_collaborator(self, planner_id: str, user_id: str, role: str = 'viewer') -> Dict[str, Any]:
        """Create a new collaborator"""
        try:
            collab_id = f"collab_{planner_id}_{user_id}"
            
            collab_doc = {
                'id': collab_id,
                'planner_id': planner_id,
                'user_id': user_id,
                'role': role,
                'created_at': datetime.utcnow().isoformat()
            }
            
            self.db.collection('collaborators').document(collab_id).set(collab_doc)
            print(f"✅ FIRESTORE: Created collaborator {collab_id}")
            return collab_doc
        except Exception as e:
            print(f"❌ FIRESTORE_COLLABORATOR_ERROR: {e}")
            raise
    
    async def get_planner_collaborators(self, planner_id: str) -> List[Dict[str, Any]]:
        """Get all collaborators for a planner"""
        try:
            collabs_ref = self.db.collection('collaborators').where('planner_id', '==', planner_id).stream()
            return [doc.to_dict() for doc in collabs_ref]
        except Exception as e:
            print(f"❌ FIRESTORE_GET_COLLABORATORS_ERROR: {e}")
            return []
    
    async def delete_collaborator(self, planner_id: str, user_id: str) -> bool:
        """Delete a collaborator"""
        try:
            collab_id = f"collab_{planner_id}_{user_id}"
            self.db.collection('collaborators').document(collab_id).delete()
            print(f"✅ FIRESTORE: Deleted collaborator {collab_id}")
            return True
        except Exception as e:
            print(f"❌ FIRESTORE_DELETE_COLLABORATOR_ERROR: {e}")
            return False
    
    async def update_collaborator_role(self, planner_id: str, user_id: str, new_role: str) -> bool:
        """Update a collaborator's role"""
        try:
            collab_id = f"collab_{planner_id}_{user_id}"
            self.db.collection('collaborators').document(collab_id).update({
                'role': new_role,
                'updated_at': datetime.utcnow().isoformat()
            })
            print(f"✅ FIRESTORE: Updated collaborator {collab_id} role to {new_role}")
            return True
        except Exception as e:
            print(f"❌ FIRESTORE_UPDATE_COLLABORATOR_ERROR: {e}")
            return False
    
    # ============= EDIT REQUEST MANAGEMENT =============
    
    async def create_edit_request(self, trip_id: str, requester_id: str, requester_name: str, 
                                  requester_email: str, owner_id: str, message: str = None) -> Dict[str, Any]:
        """Create a new edit access request"""
        try:
            request_id = f"edit_req_{trip_id}_{requester_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            
            request_doc = {
                'id': request_id,
                'trip_id': trip_id,
                'requester_id': requester_id,
                'requester_name': requester_name,
                'requester_email': requester_email,
                'owner_id': owner_id,
                'status': 'pending',
                'message': message,
                'requested_at': datetime.utcnow().isoformat(),
                'responded_at': None,
                'responded_by': None
            }
            
            self.db.collection('edit_requests').document(request_id).set(request_doc)
            print(f"✅ FIRESTORE: Created edit request {request_id}")
            return request_doc
        except Exception as e:
            print(f"❌ FIRESTORE_EDIT_REQUEST_ERROR: {e}")
            raise
    
    async def get_trip_edit_requests(self, trip_id: str, status: str = None) -> List[Dict[str, Any]]:
        """Get all edit requests for a trip"""
        try:
            query = self.db.collection('edit_requests').where('trip_id', '==', trip_id)
            if status:
                query = query.where('status', '==', status)
            
            requests_ref = query.stream()
            requests = [doc.to_dict() for doc in requests_ref]
            return sorted(requests, key=lambda x: x.get('requested_at', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_EDIT_REQUESTS_ERROR: {e}")
            return []
    
    async def get_user_edit_requests(self, user_id: str, status: str = None) -> List[Dict[str, Any]]:
        """Get all edit requests by a user"""
        try:
            query = self.db.collection('edit_requests').where('requester_id', '==', user_id)
            if status:
                query = query.where('status', '==', status)
            
            requests_ref = query.stream()
            requests = [doc.to_dict() for doc in requests_ref]
            return sorted(requests, key=lambda x: x.get('requested_at', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_USER_EDIT_REQUESTS_ERROR: {e}")
            return []
    
    async def get_owner_edit_requests(self, owner_id: str, status: str = None) -> List[Dict[str, Any]]:
        """Get all edit requests for trips owned by a user"""
        try:
            query = self.db.collection('edit_requests').where('owner_id', '==', owner_id)
            if status:
                query = query.where('status', '==', status)
            
            requests_ref = query.stream()
            requests = [doc.to_dict() for doc in requests_ref]
            return sorted(requests, key=lambda x: x.get('requested_at', ''), reverse=True)
        except Exception as e:
            print(f"❌ FIRESTORE_GET_OWNER_EDIT_REQUESTS_ERROR: {e}")
            return []
    
    async def get_edit_request(self, request_id: str) -> Optional[Dict[str, Any]]:
        """Get specific edit request"""
        try:
            request_doc = self.db.collection('edit_requests').document(request_id).get()
            if request_doc.exists:
                return request_doc.to_dict()
            return None
        except Exception as e:
            print(f"❌ FIRESTORE_GET_EDIT_REQUEST_ERROR: {e}")
            return None
    
    async def update_edit_request(self, request_id: str, status: str, responded_by: str) -> Optional[Dict[str, Any]]:
        """Update edit request status"""
        try:
            request_ref = self.db.collection('edit_requests').document(request_id)
            request_doc = request_ref.get()
            
            if not request_doc.exists:
                return None
            
            updates = {
                'status': status,
                'responded_by': responded_by,
                'responded_at': datetime.utcnow().isoformat()
            }
            
            request_ref.update(updates)
            print(f"✅ FIRESTORE: Updated edit request {request_id} to {status}")
            
            return await self.get_edit_request(request_id)
        except Exception as e:
            print(f"❌ FIRESTORE_UPDATE_EDIT_REQUEST_ERROR: {e}")
            return None
    
    async def delete_edit_request(self, request_id: str) -> bool:
        """Delete an edit request"""
        try:
            self.db.collection('edit_requests').document(request_id).delete()
            print(f"✅ FIRESTORE: Deleted edit request {request_id}")
            return True
        except Exception as e:
            print(f"❌ FIRESTORE_DELETE_EDIT_REQUEST_ERROR: {e}")
            return False
    
    async def check_pending_edit_request(self, trip_id: str, requester_id: str) -> Optional[Dict[str, Any]]:
        """Check if user has a pending edit request for this trip"""
        try:
            requests_ref = (self.db.collection('edit_requests')
                          .where('trip_id', '==', trip_id)
                          .where('requester_id', '==', requester_id)
                          .where('status', '==', 'pending')
                          .stream())
            
            for doc in requests_ref:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"❌ FIRESTORE_CHECK_PENDING_REQUEST_ERROR: {e}")
            return None

# Global Firebase service instance
firebase_service = FirebaseService()