"""
Comprehensive tests for Activities Management service
"""
import unittest
from datetime import datetime, date, timedelta
from decimal import Decimal
from unittest.mock import Mock, patch

from app.services.activities_management import (
    ActivityType, ActivityStatus, Priority, Location, Budget, Contact,
    Activity
)


class TestActivityType(unittest.TestCase):
    """Test cases for ActivityType enum"""
    
    def test_activity_types_exist(self):
        """Test that all activity types are defined"""
        self.assertEqual(ActivityType.FLIGHT.value, "flight")
        self.assertEqual(ActivityType.ACTIVITY.value, "activity")
        self.assertEqual(ActivityType.LODGING.value, "lodging")
        self.assertEqual(ActivityType.RESTAURANT.value, "restaurant")
    
    def test_activity_type_values(self):
        """Test activity type values"""
        activity_types = [t.value for t in ActivityType]
        self.assertIn("flight", activity_types)
        self.assertIn("lodging", activity_types)


class TestActivityStatus(unittest.TestCase):
    """Test cases for ActivityStatus enum"""
    
    def test_activity_status_planned(self):
        """Test planned status"""
        self.assertEqual(ActivityStatus.PLANNED.value, "planned")
    
    def test_activity_status_completed(self):
        """Test completed status"""
        self.assertEqual(ActivityStatus.COMPLETED.value, "completed")
    
    def test_activity_status_cancelled(self):
        """Test cancelled status"""
        self.assertEqual(ActivityStatus.CANCELLED.value, "cancelled")
    
    def test_all_statuses_exist(self):
        """Test that all statuses are defined"""
        statuses = [s.value for s in ActivityStatus]
        self.assertIn("planned", statuses)
        self.assertIn("confirmed", statuses)
        self.assertIn("completed", statuses)


class TestPriority(unittest.TestCase):
    """Test cases for Priority enum"""
    
    def test_priority_values(self):
        """Test priority values"""
        self.assertEqual(Priority.LOW.value, "low")
        self.assertEqual(Priority.MEDIUM.value, "medium")
        self.assertEqual(Priority.HIGH.value, "high")
        self.assertEqual(Priority.URGENT.value, "urgent")


class TestLocation(unittest.TestCase):
    """Test cases for Location dataclass"""
    
    def test_location_creation_minimal(self):
        """Test creating location with minimal fields"""
        loc = Location(name="Hanoi")
        self.assertEqual(loc.name, "Hanoi")
        self.assertIsNone(loc.address)
    
    def test_location_creation_full(self):
        """Test creating location with all fields"""
        loc = Location(
            name="Hanoi",
            address="123 Main Street",
            latitude=21.0285,
            longitude=105.8542,
            city="Hanoi",
            country="Vietnam",
            postal_code="10000"
        )
        self.assertEqual(loc.name, "Hanoi")
        self.assertEqual(loc.city, "Hanoi")
        self.assertEqual(loc.country, "Vietnam")
    
    def test_location_coordinates(self):
        """Test location with coordinates"""
        loc = Location(
            name="Museum",
            latitude=21.0285,
            longitude=105.8542
        )
        self.assertIsNotNone(loc.latitude)
        self.assertIsNotNone(loc.longitude)
        self.assertIsInstance(loc.latitude, float)


class TestBudget(unittest.TestCase):
    """Test cases for Budget dataclass"""
    
    def test_budget_creation_estimated(self):
        """Test creating budget with estimated cost"""
        budget = Budget(
            estimated_cost=Decimal("1000.00"),
            currency="USD"
        )
        self.assertEqual(budget.estimated_cost, Decimal("1000.00"))
        self.assertEqual(budget.currency, "USD")
    
    def test_budget_creation_with_actual_cost(self):
        """Test creating budget with actual cost"""
        budget = Budget(
            estimated_cost=Decimal("1000.00"),
            actual_cost=Decimal("950.00"),
            currency="USD",
            category="Flight"
        )
        self.assertEqual(budget.estimated_cost, Decimal("1000.00"))
        self.assertEqual(budget.actual_cost, Decimal("950.00"))
        self.assertEqual(budget.category, "Flight")
    
    def test_budget_default_currency(self):
        """Test budget with default currency"""
        budget = Budget(estimated_cost=Decimal("500.00"))
        self.assertEqual(budget.currency, "VND")


class TestContact(unittest.TestCase):
    """Test cases for Contact dataclass"""
    
    def test_contact_creation_minimal(self):
        """Test creating contact with minimal fields"""
        contact = Contact()
        self.assertIsNone(contact.name)
    
    def test_contact_creation_full(self):
        """Test creating contact with all fields"""
        contact = Contact(
            name="Hotel Reception",
            phone="+84123456789",
            email="hotel@example.com",
            website="https://hotel.example.com"
        )
        self.assertEqual(contact.name, "Hotel Reception")
        self.assertEqual(contact.phone, "+84123456789")


class TestActivity(unittest.TestCase):
    """Test cases for Activity dataclass"""
    
    def test_activity_creation_minimal(self):
        """Test creating activity with minimal fields"""
        today = date.today()
        activity = Activity(
            activity_type=ActivityType.ACTIVITY,
            name="Sightseeing",
            start_date=today,
            end_date=today
        )
        self.assertEqual(activity.name, "Sightseeing")
        self.assertEqual(activity.activity_type, ActivityType.ACTIVITY)
    
    def test_activity_creation_full(self):
        """Test creating activity with all fields"""
        today = date.today()
        now = datetime.now()
        
        activity = Activity(
            activity_type=ActivityType.FLIGHT,
            name="Flight to Bangkok",
            start_date=today,
            end_date=today,
            start_time=now,
            end_time=now + timedelta(hours=3),
            real_cost=Decimal("200.00"),
            expected_cost=Decimal("180.00"),
            currency="USD",
            status=ActivityStatus.CONFIRMED,
            priority=Priority.HIGH,
            trip_id="trip123"
        )
        self.assertEqual(activity.name, "Flight to Bangkok")
        self.assertEqual(activity.status, ActivityStatus.CONFIRMED)
        self.assertEqual(activity.priority, Priority.HIGH)
    
    def test_activity_with_location(self):
        """Test activity with location"""
        today = date.today()
        loc = Location(name="Bangkok Airport")
        
        activity = Activity(
            activity_type=ActivityType.ACTIVITY,
            name="Flight Departure",
            start_date=today,
            end_date=today,
            location=loc
        )
        self.assertIsNotNone(activity.location)
        self.assertEqual(activity.location.name, "Bangkok Airport")
    
    def test_activity_with_budget(self):
        """Test activity with budget"""
        today = date.today()
        budget = Budget(
            estimated_cost=Decimal("500.00"),
            actual_cost=Decimal("450.00"),
            currency="USD"
        )
        
        activity = Activity(
            activity_type=ActivityType.LODGING,
            name="Hotel Stay",
            start_date=today,
            end_date=today + timedelta(days=2),
            budget=budget
        )
        self.assertIsNotNone(activity.budget)
        self.assertEqual(activity.budget.estimated_cost, Decimal("500.00"))




if __name__ == '__main__':
    unittest.main(verbosity=2)
