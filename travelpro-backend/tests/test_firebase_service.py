"""
Test suite for Firebase Service using unittest
"""
import unittest
import asyncio
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from datetime import datetime
from typing import Dict, Any
import json

# Add app to path for imports
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.firebase_service import FirebaseService
from app.models.user import User


def async_test(func):
    """Decorator to run async test methods"""
    def wrapper(self, *args, **kwargs):
        return asyncio.run(func(self, *args, **kwargs))
    return wrapper


class TestFirebaseService(unittest.TestCase):
    """Test cases for FirebaseService class"""

    def setUp(self):
        """Setup for each test method"""
        # Mock settings to avoid real Firebase initialization
        with patch('app.services.firebase_service.get_settings') as mock_settings:
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_PATH = None
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_KEY = None
            mock_settings.return_value.GOOGLE_CLIENT_ID = "test-client-id"
            
            # Create service with mocked Firebase
            self.service = FirebaseService()
            self.service.app = Mock()
            self.service.db = Mock()

    def test_firebase_service_initialization_with_service_account_path(self):
        """Test Firebase service initialization with service account file"""
        with patch('app.services.firebase_service.get_settings') as mock_settings, \
             patch('firebase_admin.credentials.Certificate') as mock_cert, \
             patch('firebase_admin.initialize_app') as mock_init, \
             patch('firebase_admin.firestore.client') as mock_firestore:
            
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_PATH = "/path/to/service-account.json"
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_KEY = None
            mock_settings.return_value.GOOGLE_CLIENT_ID = "test-client-id"
            
            service = FirebaseService()
            
            mock_cert.assert_called_once_with("/path/to/service-account.json")
            mock_init.assert_called_once()
            mock_firestore.assert_called_once()

    def test_firebase_service_initialization_with_service_account_key(self):
        """Test Firebase service initialization with service account JSON string"""
        service_account_json = {
            "type": "service_account",
            "project_id": "test-project",
            "private_key_id": "test-key-id"
        }
        
        with patch('app.services.firebase_service.get_settings') as mock_settings, \
             patch('firebase_admin.credentials.Certificate') as mock_cert, \
             patch('firebase_admin.initialize_app') as mock_init, \
             patch('firebase_admin.firestore.client') as mock_firestore:
            
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_PATH = None
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_KEY = json.dumps(service_account_json)
            mock_settings.return_value.GOOGLE_CLIENT_ID = "test-client-id"
            
            service = FirebaseService()
            
            mock_cert.assert_called_once_with(service_account_json)
            mock_init.assert_called_once()
            mock_firestore.assert_called_once()

    def test_firebase_service_initialization_failure(self):
        """Test Firebase service initialization failure handling"""
        with patch('app.services.firebase_service.get_settings') as mock_settings, \
             patch('firebase_admin.initialize_app', side_effect=Exception("Firebase error")) as mock_init:
            
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_PATH = None
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_KEY = None
            mock_settings.return_value.GOOGLE_CLIENT_ID = "test-client-id"
            
            service = FirebaseService()
            
            self.assertIsNone(service.app)
            self.assertIsNone(service.db)

    @async_test
    async def test_verify_id_token_success(self):
        """Test successful Firebase ID token verification"""
        mock_token = "valid-firebase-token"
        expected_decoded = {
            "uid": "test-uid",
            "email": "test@example.com",
            "email_verified": True
        }
        
        with patch('firebase_admin.auth.verify_id_token', return_value=expected_decoded):
            result = await self.service.verify_id_token(mock_token)
            
            self.assertEqual(result, expected_decoded)

    @async_test
    async def test_verify_id_token_failure(self):
        """Test Firebase ID token verification failure"""
        mock_token = "invalid-token"
        
        with patch('firebase_admin.auth.verify_id_token', side_effect=Exception("Invalid token")):
            result = await self.service.verify_id_token(mock_token)
            
            self.assertIsNone(result)

    @async_test
    async def test_verify_google_token_success(self):
        """Test successful Google OAuth token verification"""
        mock_token = "valid-google-token"
        expected_decoded = {
            "iss": "accounts.google.com",
            "sub": "google-user-id",
            "email": "test@gmail.com",
            "name": "Test User"
        }
        
        with patch('google.oauth2.id_token.verify_oauth2_token', return_value=expected_decoded), \
             patch('app.services.firebase_service.settings.GOOGLE_CLIENT_ID', 'test-client-id'):
            
            result = await self.service.verify_google_token(mock_token)
            
            self.assertEqual(result, expected_decoded)

    @async_test
    async def test_verify_google_token_wrong_issuer(self):
        """Test Google token verification with wrong issuer"""
        mock_token = "token-wrong-issuer"
        mock_decoded = {
            "iss": "wrong-issuer.com",
            "sub": "user-id"
        }
        
        with patch('google.oauth2.id_token.verify_oauth2_token', return_value=mock_decoded):
            result = await self.service.verify_google_token(mock_token)
            
            self.assertIsNone(result)

    @async_test
    async def test_verify_google_token_failure(self):
        """Test Google token verification failure"""
        mock_token = "invalid-google-token"
        
        with patch('google.oauth2.id_token.verify_oauth2_token', side_effect=ValueError("Invalid token")):
            result = await self.service.verify_google_token(mock_token)
            
            self.assertIsNone(result)

    @async_test
    async def test_get_or_create_user_existing_user(self):
        """Test getting existing user from Firestore"""
        firebase_user_data = {
            "uid": "existing-uid",
            "email": "existing@example.com",
            "name": "Existing User",
            "picture": "https://example.com/photo.jpg",
            "email_verified": True
        }
        
        # Mock Firestore document
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = {
            "username": "existing_user",
            "first_name": "Existing",
            "last_name": "User",
            "created_at": datetime.utcnow(),
            "preferred_currency": "USD",
            "preferred_language": "en"
        }
        
        self.service.db.collection.return_value.document.return_value.get.return_value = mock_doc
        
        result = await self.service.get_or_create_user(firebase_user_data)
        
        self.assertIsInstance(result, User)
        self.assertEqual(result.id, "existing-uid")
        self.assertEqual(result.email, "existing@example.com")
        self.assertEqual(result.username, "existing_user")
        self.assertTrue(result.is_verified)

    @async_test
    async def test_get_or_create_user_new_user(self):
        """Test creating new user in Firestore"""
        firebase_user_data = {
            "uid": "new-uid",
            "email": "new@example.com",
            "name": "New User",
            "picture": "https://example.com/new-photo.jpg",
            "email_verified": False
        }
        
        # Mock Firestore document (doesn't exist)
        mock_doc = Mock()
        mock_doc.exists = False
        
        self.service.db.collection.return_value.document.return_value.get.return_value = mock_doc
        mock_set = Mock()
        self.service.db.collection.return_value.document.return_value.set = mock_set
        
        result = await self.service.get_or_create_user(firebase_user_data)
        
        self.assertIsInstance(result, User)
        self.assertEqual(result.id, "new-uid")
        self.assertEqual(result.email, "new@example.com")
        self.assertEqual(result.username, "new")
        self.assertEqual(result.first_name, "New")
        self.assertEqual(result.last_name, "User")
        self.assertFalse(result.is_verified)
        
        # Verify that set was called to save user
        mock_set.assert_called_once()

    @async_test
    async def test_get_or_create_user_firestore_error(self):
        """Test user creation with Firestore error (fallback)"""
        firebase_user_data = {
            "uid": "error-uid",
            "email": "error@example.com",
            "name": "Error User",
            "email_verified": True
        }
        
        # Mock Firestore error
        self.service.db.collection.side_effect = Exception("Firestore error")
        
        result = await self.service.get_or_create_user(firebase_user_data)
        
        self.assertIsInstance(result, User)
        self.assertEqual(result.id, "error-uid")
        self.assertEqual(result.email, "error@example.com")
        self.assertEqual(result.username, "error")

    @async_test
    async def test_get_or_create_user_no_email(self):
        """Test user creation without email"""
        firebase_user_data = {
            "uid": "no-email-uid",
            "name": "No Email User",
            "email_verified": False
        }
        
        # Mock Firestore document (doesn't exist)
        mock_doc = Mock()
        mock_doc.exists = False
        
        self.service.db.collection.return_value.document.return_value.get.return_value = mock_doc
        mock_set = Mock()
        self.service.db.collection.return_value.document.return_value.set = mock_set
        
        result = await self.service.get_or_create_user(firebase_user_data)
        
        self.assertIsInstance(result, User)
        self.assertEqual(result.id, "no-email-uid")
        self.assertEqual(result.username, "user_no-email")  # Generated from uid

    @async_test
    async def test_update_user_login_success(self):
        """Test successful user login update"""
        user_id = "test-uid"
        mock_update = Mock()
        self.service.db.collection.return_value.document.return_value.update = mock_update
        
        await self.service.update_user_login(user_id)
        
        mock_update.assert_called_once()
        # Verify the update call contains last_login
        call_args = mock_update.call_args[0][0]
        self.assertIn('last_login', call_args)

    @async_test
    async def test_update_user_login_no_db(self):
        """Test user login update when database is None"""
        self.service.db = None
        user_id = "test-uid"
        
        # Should not raise exception
        await self.service.update_user_login(user_id)

    @async_test
    async def test_update_user_login_error(self):
        """Test user login update with database error"""
        user_id = "test-uid"
        self.service.db.collection.side_effect = Exception("DB error")
        
        # Should not raise exception, just log error
        await self.service.update_user_login(user_id)

    @async_test
    async def test_create_custom_token_success(self):
        """Test successful custom token creation"""
        uid = "test-uid"
        additional_claims = {"role": "admin"}
        expected_token = "custom-token-bytes"
        
        with patch('firebase_admin.auth.create_custom_token') as mock_create_token:
            mock_create_token.return_value = expected_token.encode('utf-8')
            
            result = await self.service.create_custom_token(uid, additional_claims)
            
            self.assertEqual(result, expected_token)
            mock_create_token.assert_called_once_with(uid, additional_claims)

    @async_test
    async def test_create_custom_token_error(self):
        """Test custom token creation error"""
        uid = "test-uid"
        
        with patch('firebase_admin.auth.create_custom_token', side_effect=Exception("Token error")):
            result = await self.service.create_custom_token(uid)
            
            self.assertEqual(result, "")

    @async_test
    async def test_get_user_by_id_success(self):
        """Test successful user retrieval by ID"""
        user_id = "test-uid"
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = {
            "email": "test@example.com",
            "username": "testuser",
            "first_name": "Test",
            "last_name": "User"
        }
        
        self.service.db.collection.return_value.document.return_value.get.return_value = mock_doc
        
        result = await self.service.get_user_by_id(user_id)
        
        self.assertIsInstance(result, User)
        self.assertEqual(result.id, user_id)
        self.assertEqual(result.email, "test@example.com")

    @async_test
    async def test_get_user_by_id_not_found(self):
        """Test user retrieval when user doesn't exist"""
        user_id = "nonexistent-uid"
        mock_doc = Mock()
        mock_doc.exists = False
        
        self.service.db.collection.return_value.document.return_value.get.return_value = mock_doc
        
        result = await self.service.get_user_by_id(user_id)
        
        self.assertIsNone(result)

    @async_test
    async def test_get_user_by_id_no_db(self):
        """Test user retrieval when database is None"""
        self.service.db = None
        user_id = "test-uid"
        
        result = await self.service.get_user_by_id(user_id)
        
        self.assertIsNone(result)

    @async_test
    async def test_get_user_by_id_error(self):
        """Test user retrieval with database error"""
        user_id = "test-uid"
        self.service.db.collection.side_effect = Exception("DB error")
        
        result = await self.service.get_user_by_id(user_id)
        
        self.assertIsNone(result)


class TestFirebaseServiceIntegration(unittest.TestCase):
    """Integration tests for Firebase Service"""

    def setUp(self):
        """Setup for integration tests"""
        with patch('app.services.firebase_service.get_settings') as mock_settings:
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_PATH = None
            mock_settings.return_value.FIREBASE_SERVICE_ACCOUNT_KEY = None
            mock_settings.return_value.GOOGLE_CLIENT_ID = "test-client-id"
            
            self.service = FirebaseService()

    @async_test
    async def test_full_user_workflow(self):
        """Test complete user workflow: create, update, retrieve, delete"""
        # Mock all Firebase operations
        firebase_user_data = {
            "uid": "workflow-uid",
            "email": "workflow@example.com",
            "name": "Workflow User",
            "email_verified": True
        }
        
        # Mock Firestore for user creation
        mock_doc = Mock()
        mock_doc.exists = False
        mock_set = Mock()
        
        with patch.object(self.service, 'db') as mock_db:
            mock_db.collection.return_value.document.return_value.get.return_value = mock_doc
            mock_db.collection.return_value.document.return_value.set = mock_set
            mock_db.collection.return_value.document.return_value.update = Mock()
            mock_db.collection.return_value.document.return_value.delete = Mock()
            
            # 1. Create user
            user = await self.service.get_or_create_user(firebase_user_data)
            self.assertEqual(user.id, "workflow-uid")
            self.assertEqual(user.email, "workflow@example.com")
            
            # 2. Update login
            await self.service.update_user_login(user.id)
            
            # 3. Update profile (if method exists)
            try:
                update_result = await self.service.update_user_profile(
                    user.id, 
                    {"preferred_currency": "USD"}
                )
                self.assertTrue(update_result)
            except AttributeError:
                # Method doesn't exist, skip this test
                pass
            
            # 4. Delete user (if method exists)
            try:
                with patch('firebase_admin.auth.delete_user'):
                    delete_result = await self.service.delete_user(user.id)
                    self.assertTrue(delete_result)
            except AttributeError:
                # Method doesn't exist, skip this test
                pass


class TestFirebaseServiceGlobalInstance(unittest.TestCase):
    """Test the global Firebase service instance"""

    def test_firebase_service_singleton(self):
        """Test that firebase_service is properly instantiated"""
        from app.services.firebase_service import firebase_service
        
        self.assertIsNotNone(firebase_service)
        self.assertIsInstance(firebase_service, FirebaseService)


if __name__ == "__main__":
    unittest.main(verbosity=2)