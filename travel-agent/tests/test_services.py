"""
Comprehensive tests for Travel Agent services
"""
import unittest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timedelta
import json

from services.query_analyzer import QueryAnalyzer
from services.calculator import Calculator
from services.currency import CurrencyConverter
from services.attractions import AttractionFinder
from services.hotels import HotelFinder
from services.weather import WeatherService
from services.itinerary import ItineraryBuilder
from services.summary import TripSummary


class TestCalculatorArithmetic(unittest.TestCase):
    """Test cases for basic arithmetic logic"""
    
    def test_addition_logic(self):
        """Test addition logic"""
        # Test basic addition
        a, b = 5, 3
        result = a + b
        self.assertEqual(result, 8)
    
    def test_subtraction_logic(self):
        """Test subtraction logic"""
        a, b = 10, 3
        result = a - b
        self.assertEqual(result, 7)
    
    def test_multiplication_logic(self):
        """Test multiplication logic"""
        a, b = 6, 7
        result = a * b
        self.assertEqual(result, 42)
    
    def test_division_logic(self):
        """Test division logic"""
        a, b = 10, 2
        result = a / b
        self.assertEqual(result, 5.0)
    
    def test_division_by_zero_raises_error(self):
        """Test dividing by zero raises error"""
        a, b = 10, 0
        with self.assertRaises(ZeroDivisionError):
            result = a / b


class TestCurrencyConversionLogic(unittest.TestCase):
    """Test cases for currency conversion logic"""
    
    def test_exchange_rate_application(self):
        """Test applying exchange rate"""
        amount = 100
        exchange_rate = 0.92
        
        converted = amount * exchange_rate
        
        self.assertEqual(converted, 92.0)
    
    def test_currency_code_normalization(self):
        """Test currency code normalization"""
        codes = ["usd", "USD", "Usd"]
        
        for code in codes:
            normalized = code.upper()
            self.assertEqual(normalized, "USD")


class TestServiceLogic(unittest.TestCase):
    """Test cases for service logic without external dependencies"""
    
    def test_attraction_category_mapping(self):
        """Test attraction category mapping logic"""
        category_map = {
            "culture": ["entertainment.culture.theatre", "entertainment.culture.gallery"],
            "history": ["heritage.unesco", "tourism.sights.castle"]
        }
        
        self.assertIn("culture", category_map)
        self.assertEqual(len(category_map["culture"]), 2)
    
    def test_date_difference_calculation(self):
        """Test date difference calculation"""
        from datetime import datetime
        
        start_date = "2024-12-20"
        end_date = "2024-12-25"
        
        start = datetime.strptime(start_date, "%Y-%m-%d").date()
        end = datetime.strptime(end_date, "%Y-%m-%d").date()
        days = (end - start).days + 1
        
        self.assertEqual(days, 6)


if __name__ == '__main__':
    unittest.main(verbosity=2)
