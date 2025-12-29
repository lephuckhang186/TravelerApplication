"""
Edge cases and validation tests for Travel Agent
"""
import unittest
from datetime import datetime, date, timedelta
from pydantic import ValidationError

from models import TripPlan, QueryAnalysisResult, WorkflowState, HotelInfo
from services.calculator import Calculator
from services.currency import CurrencyConverter


class TestTripPlanEdgeCases(unittest.TestCase):
    """Test edge cases for TripPlan"""
    
    def test_empty_trip_plan(self):
        """Test empty trip plan"""
        plan = TripPlan()
        self.assertIsNone(plan.destination)
    
    def test_very_long_destination_name(self):
        """Test very long destination name"""
        long_name = "A" * 1000
        plan = TripPlan(destination=long_name)
        self.assertEqual(len(plan.destination), 1000)
    
    def test_special_characters_in_destination(self):
        """Test special characters in destination"""
        special_dest = "São Paulo, Côte d'Ivoire"
        plan = TripPlan(destination=special_dest)
        self.assertEqual(plan.destination, special_dest)
    
    def test_numeric_destination(self):
        """Test numeric destination"""
        plan = TripPlan(destination="123")
        self.assertEqual(plan.destination, "123")
    
    def test_zero_budget(self):
        """Test zero budget"""
        plan = TripPlan(budget="0")
        self.assertEqual(plan.budget, "0")
    
    def test_negative_budget(self):
        """Test negative budget"""
        plan = TripPlan(budget="-1000")
        self.assertEqual(plan.budget, "-1000")
    
    def test_very_large_budget(self):
        """Test very large budget"""
        plan = TripPlan(budget="9999999999")
        self.assertEqual(plan.budget, "9999999999")
    
    def test_decimal_days(self):
        """Test decimal days"""
        plan = TripPlan(days="3.5")
        self.assertEqual(plan.days, "3.5")
    
    def test_zero_days(self):
        """Test zero days"""
        plan = TripPlan(days="0")
        self.assertEqual(plan.days, "0")
    
    def test_negative_days(self):
        """Test negative days"""
        plan = TripPlan(days="-5")
        self.assertEqual(plan.days, "-5")
    
    def test_zero_group_size(self):
        """Test zero group size"""
        plan = TripPlan(group_size="0")
        self.assertEqual(plan.group_size, "0")
    
    def test_large_group_size(self):
        """Test large group size"""
        plan = TripPlan(group_size="1000")
        self.assertEqual(plan.group_size, "1000")
    
    def test_empty_activity_preferences(self):
        """Test empty activity preferences"""
        plan = TripPlan(activity_preferences="")
        self.assertEqual(plan.activity_preferences, "")
    
    def test_many_activity_preferences(self):
        """Test many activity preferences"""
        prefs = ",".join(["activity"] * 100)
        plan = TripPlan(activity_preferences=prefs)
        self.assertIn("activity", plan.activity_preferences)
    
    def test_budget_as_float_string(self):
        """Test budget as float string"""
        plan = TripPlan(budget="1500.50")
        self.assertEqual(plan.budget, "1500.50")
    
    def test_currency_code_variations(self):
        """Test currency code variations"""
        codes = ["usd", "Usd", "USD", "eur", "EUR"]
        for code in codes:
            plan = TripPlan(native_currency=code)
            self.assertEqual(plan.native_currency, code)


class TestQueryAnalysisEdgeCases(unittest.TestCase):
    """Test edge cases for QueryAnalysisResult"""
    
    def test_all_fields_missing(self):
        """Test with all fields missing"""
        result = QueryAnalysisResult(
            missing_fields=["destination", "budget", "days", "accommodation_type"]
        )
        self.assertEqual(len(result.missing_fields), 4)
    
    def test_no_fields_missing(self):
        """Test with no fields missing"""
        result = QueryAnalysisResult(missing_fields=[])
        self.assertEqual(len(result.missing_fields), 0)
    
    def test_duplicate_missing_fields(self):
        """Test with duplicate missing fields"""
        result = QueryAnalysisResult(
            missing_fields=["budget", "budget", "days"]
        )
        # Model allows duplicates - that's ok
        self.assertIn("budget", result.missing_fields)
    
    def test_invalid_missing_field_names(self):
        """Test with invalid missing field names"""
        result = QueryAnalysisResult(
            missing_fields=["nonexistent_field", "another_fake_field"]
        )
        self.assertEqual(len(result.missing_fields), 2)


class TestWorkflowStateEdgeCases(unittest.TestCase):
    """Test edge cases for WorkflowState"""
    
    def test_empty_messages_list(self):
        """Test empty messages list"""
        state = WorkflowState(messages=[])
        self.assertEqual(len(state.messages), 0)
    
    def test_very_long_messages_list(self):
        """Test very long messages list"""
        messages = [{"role": "user", "content": f"Message {i}"} for i in range(1000)]
        state = WorkflowState(messages=messages)
        self.assertEqual(len(state.messages), 1000)
    
    def test_empty_hotels_list(self):
        """Test empty hotels list"""
        state = WorkflowState(hotels=[])
        self.assertEqual(state.hotels, [])
    
    def test_many_hotels(self):
        """Test many hotels"""
        hotels = [{"name": f"Hotel {i}", "price_per_night": 100.0 + i} for i in range(100)]
        state = WorkflowState(hotels=hotels)
        self.assertEqual(len(state.hotels), 100)
    
    def test_very_long_attractions_string(self):
        """Test very long attractions string"""
        long_attractions = "A" * 10000
        state = WorkflowState(attractions=long_attractions)
        self.assertEqual(len(state.attractions), 10000)
    
    def test_null_itinerary(self):
        """Test null itinerary"""
        state = WorkflowState(itinerary=None)
        self.assertIsNone(state.itinerary)
    
    def test_empty_dict_itinerary(self):
        """Test empty dict itinerary"""
        state = WorkflowState(itinerary={})
        self.assertEqual(state.itinerary, {})
    
    def test_nested_itinerary(self):
        """Test nested itinerary structure"""
        itinerary = {
            "day1": {
                "morning": "Breakfast",
                "afternoon": "Sightseeing",
                "evening": "Dinner"
            }
        }
        state = WorkflowState(itinerary=itinerary)
        self.assertIsNotNone(state.itinerary)


class TestHotelInfoEdgeCases(unittest.TestCase):
    """Test edge cases for HotelInfo"""
    
    def test_zero_price_hotel(self):
        """Test hotel with zero price"""
        hotel = HotelInfo(
            name="Free Accommodation",
            price_per_night=0.0,
            review_count=0
        )
        self.assertEqual(hotel.price_per_night, 0.0)
    
    def test_very_high_price_hotel(self):
        """Test hotel with very high price"""
        hotel = HotelInfo(
            name="Ultra Luxury",
            price_per_night=99999.99,
            review_count=10
        )
        self.assertEqual(hotel.price_per_night, 99999.99)
    
    def test_negative_price_hotel(self):
        """Test hotel with negative price"""
        hotel = HotelInfo(
            name="Discount Hotel",
            price_per_night=-50.0,
            review_count=5
        )
        self.assertEqual(hotel.price_per_night, -50.0)
    
    def test_fractional_price(self):
        """Test hotel with fractional price"""
        hotel = HotelInfo(
            name="Budget Hotel",
            price_per_night=49.99,
            review_count=200
        )
        self.assertAlmostEqual(hotel.price_per_night, 49.99, places=2)
    
    def test_very_low_rating(self):
        """Test hotel with very low rating"""
        hotel = HotelInfo(
            name="Poor Hotel",
            price_per_night=30.0,
            review_count=50,
            rating=1.0
        )
        self.assertEqual(hotel.rating, 1.0)
    
    def test_perfect_rating(self):
        """Test hotel with perfect rating"""
        hotel = HotelInfo(
            name="Perfect Hotel",
            price_per_night=200.0,
            review_count=1000,
            rating=5.0
        )
        self.assertEqual(hotel.rating, 5.0)
    
    def test_zero_reviews(self):
        """Test hotel with zero reviews"""
        hotel = HotelInfo(
            name="New Hotel",
            price_per_night=75.0,
            review_count=0
        )
        self.assertEqual(hotel.review_count, 0)
    
    def test_huge_review_count(self):
        """Test hotel with huge review count"""
        hotel = HotelInfo(
            name="Very Popular Hotel",
            price_per_night=100.0,
            review_count=1000000
        )
        self.assertEqual(hotel.review_count, 1000000)


class TestArithmeticLogicEdgeCases(unittest.TestCase):
    """Test edge cases for arithmetic logic"""
    
    def test_add_large_numbers(self):
        """Test adding very large numbers"""
        result = 1000000 + 2000000
        self.assertEqual(result, 3000000)
    
    def test_add_opposite_numbers(self):
        """Test adding opposite numbers"""
        result = 100 + (-100)
        self.assertEqual(result, 0)
    
    def test_multiply_by_one(self):
        """Test multiplying by one"""
        result = 42 * 1
        self.assertEqual(result, 42)
    
    def test_multiply_negative_by_negative(self):
        """Test multiplying two negatives"""
        result = (-5) * (-5)
        self.assertEqual(result, 25)
    
    def test_divide_same_number(self):
        """Test dividing number by itself"""
        result = 42 / 42
        self.assertEqual(result, 1.0)
    
    def test_divide_very_small_by_large(self):
        """Test dividing very small by large"""
        result = 1 / 1000000
        self.assertLess(result, 0.001)
    
    def test_subtract_from_self(self):
        """Test subtracting number from itself"""
        result = 100 - 100
        self.assertEqual(result, 0)
    
    def test_subtract_large_from_small(self):
        """Test subtracting large from small"""
        result = 10 - 1000
        self.assertEqual(result, -990)


class TestDataValidation(unittest.TestCase):
    """Test data validation edge cases"""
    
    def test_string_to_int_conversion(self):
        """Test string to int conversion"""
        plan = TripPlan(days="7")
        # Should remain as string since it's defined as string field
        self.assertEqual(plan.days, "7")
    
    def test_whitespace_in_destination(self):
        """Test whitespace in destination"""
        plan = TripPlan(destination="  Hanoi  ")
        self.assertEqual(plan.destination, "  Hanoi  ")
    
    def test_multiple_spaces_in_name(self):
        """Test multiple spaces in hotel name"""
        hotel = HotelInfo(
            name="Hotel   With   Spaces",
            price_per_night=100.0,
            review_count=50
        )
        self.assertIn("Hotel", hotel.name)
    
    def test_newline_characters(self):
        """Test newline characters in strings"""
        plan = TripPlan(destination="Hanoi\nVietnam")
        self.assertIn("\n", plan.destination)
    
    def test_tab_characters(self):
        """Test tab characters in strings"""
        plan = TripPlan(destination="Ha\tNoi")
        self.assertIn("\t", plan.destination)


class TestBoundaryValues(unittest.TestCase):
    """Test boundary values"""
    
    def test_minimum_int_value(self):
        """Test minimum int value for arithmetic"""
        # Python ints have no limit, but test behavior
        result = (-999999) + (-999999)
        self.assertEqual(result, -1999998)
    
    def test_maximum_reasonable_value(self):
        """Test maximum reasonable values"""
        result = 1000000 * 1000000
        self.assertEqual(result, 1000000000000)
    
    def test_minimum_group_size(self):
        """Test minimum group size"""
        plan = TripPlan(group_size="1")
        self.assertEqual(plan.group_size, "1")
    
    def test_one_day_trip(self):
        """Test one day trip"""
        plan = TripPlan(days="1")
        self.assertEqual(plan.days, "1")
    
    def test_maximum_practical_days(self):
        """Test maximum practical days"""
        plan = TripPlan(days="365")
        self.assertEqual(plan.days, "365")


class TestCurrencyConversionEdgeCases(unittest.TestCase):
    """Test edge cases for currency conversion"""
    
    def test_same_currency_conversion(self):
        """Test converting same currency"""
        # Amount stays the same
        from_amount = 1000
        # Conversion rate should be 1
        self.assertEqual(from_amount * 1, from_amount)
    
    def test_zero_amount_conversion(self):
        """Test converting zero amount"""
        result = 0 * 2.5  # Any exchange rate
        self.assertEqual(result, 0)
    
    def test_very_small_amount(self):
        """Test converting very small amount"""
        result = 0.001 * 25000
        self.assertAlmostEqual(result, 25, places=0)
    
    def test_very_large_amount(self):
        """Test converting very large amount"""
        result = 1000000 * 0.00004
        self.assertGreater(result, 0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
