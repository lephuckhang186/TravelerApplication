"""
Comprehensive tests for Travel Agent models
"""
import unittest
from datetime import datetime, date, timedelta
from pydantic import ValidationError

from models import TripPlan, QueryAnalysisResult, WorkflowState, HotelInfo


class TestTripPlan(unittest.TestCase):
    """Test cases for TripPlan model"""
    
    def test_trip_plan_minimal(self):
        """Test TripPlan with minimal fields"""
        plan = TripPlan()
        self.assertIsNone(plan.destination)
        self.assertIsNone(plan.budget)
    
    def test_trip_plan_all_fields(self):
        """Test TripPlan with all fields"""
        plan = TripPlan(
            destination="Ha Noi",
            budget="10000000",
            native_currency="VND",
            days="7",
            group_size="3",
            activity_preferences="culture,history",
            accommodation_type="hotel",
            dietary_restrictions="vegetarian",
            transportation_preferences="taxi,bus"
        )
        
        self.assertEqual(plan.destination, "Ha Noi")
        self.assertEqual(plan.budget, "10000000")
        self.assertEqual(plan.native_currency, "VND")
        self.assertEqual(plan.days, "7")
        self.assertEqual(plan.group_size, "3")
    
    def test_trip_plan_default_group_size(self):
        """Test TripPlan default group size"""
        plan = TripPlan(destination="Bangkok")
        self.assertEqual(plan.group_size, "1")
    
    def test_trip_plan_with_unicode_destination(self):
        """Test TripPlan with unicode destination name"""
        plan = TripPlan(destination="Đà Nẵng")
        self.assertEqual(plan.destination, "Đà Nẵng")
    
    def test_trip_plan_with_large_budget(self):
        """Test TripPlan with large budget"""
        plan = TripPlan(budget="1000000000")
        self.assertEqual(plan.budget, "1000000000")
    
    def test_trip_plan_with_zero_budget(self):
        """Test TripPlan with zero budget"""
        plan = TripPlan(budget="0")
        self.assertEqual(plan.budget, "0")
    
    def test_trip_plan_with_negative_budget(self):
        """Test TripPlan with negative budget"""
        plan = TripPlan(budget="-1000")
        self.assertEqual(plan.budget, "-1000")
    
    def test_trip_plan_multiple_currencies(self):
        """Test TripPlan with various currency codes"""
        currencies = ["USD", "EUR", "GBP", "JPY", "VND", "THB"]
        for currency in currencies:
            plan = TripPlan(native_currency=currency)
            self.assertEqual(plan.native_currency, currency)
    
    def test_trip_plan_decimal_days(self):
        """Test TripPlan with decimal days"""
        plan = TripPlan(days="3.5")
        self.assertEqual(plan.days, "3.5")
    
    def test_trip_plan_multiple_preferences(self):
        """Test TripPlan with multiple activity preferences"""
        prefs = "adventure,culture,relaxation,nightlife,history,art"
        plan = TripPlan(activity_preferences=prefs)
        self.assertEqual(plan.activity_preferences, prefs)
    
    def test_trip_plan_accommodation_types(self):
        """Test TripPlan with various accommodation types"""
        types = ["hotel", "hostel", "airbnb", "resort", "villa", "cottage"]
        for acc_type in types:
            plan = TripPlan(accommodation_type=acc_type)
            self.assertEqual(plan.accommodation_type, acc_type)
    
    def test_trip_plan_dietary_restrictions(self):
        """Test TripPlan with dietary restrictions"""
        restrictions = "vegetarian,no seafood,gluten-free"
        plan = TripPlan(dietary_restrictions=restrictions)
        self.assertEqual(plan.dietary_restrictions, restrictions)


class TestQueryAnalysisResult(unittest.TestCase):
    """Test cases for QueryAnalysisResult model"""
    
    def test_query_analysis_result_minimal(self):
        """Test QueryAnalysisResult with minimal fields"""
        result = QueryAnalysisResult()
        self.assertEqual(result.missing_fields, [])
    
    def test_query_analysis_result_with_missing_fields(self):
        """Test QueryAnalysisResult with missing fields"""
        result = QueryAnalysisResult(
            destination="Bangkok",
            missing_fields=["budget", "days"]
        )
        
        self.assertEqual(result.destination, "Bangkok")
        self.assertEqual(len(result.missing_fields), 2)
        self.assertIn("budget", result.missing_fields)
        self.assertIn("days", result.missing_fields)
    
    def test_query_analysis_result_all_fields_provided(self):
        """Test QueryAnalysisResult with all fields provided"""
        result = QueryAnalysisResult(
            destination="Ho Chi Minh City",
            budget="5000000",
            native_currency="VND",
            days="5",
            group_size="2",
            activity_preferences="food,shopping",
            missing_fields=[]
        )
        
        self.assertEqual(result.destination, "Ho Chi Minh City")
        self.assertEqual(len(result.missing_fields), 0)
    
    def test_query_analysis_result_multiple_missing_fields(self):
        """Test QueryAnalysisResult with multiple missing fields"""
        missing = ["budget", "days", "accommodation_type", "dietary_restrictions"]
        result = QueryAnalysisResult(
            destination="Paris",
            missing_fields=missing
        )
        
        self.assertEqual(len(result.missing_fields), 4)
        for field in missing:
            self.assertIn(field, result.missing_fields)
    
    def test_query_analysis_result_inherits_trip_plan_fields(self):
        """Test that QueryAnalysisResult inherits from TripPlan"""
        result = QueryAnalysisResult(
            destination="Rome",
            budget="3000",
            activity_preferences="history,art"
        )
        
        self.assertEqual(result.destination, "Rome")
        self.assertEqual(result.budget, "3000")
        self.assertEqual(result.activity_preferences, "history,art")


class TestWorkflowState(unittest.TestCase):
    """Test cases for WorkflowState model"""
    
    def test_workflow_state_minimal(self):
        """Test WorkflowState with minimal fields"""
        state = WorkflowState()
        self.assertEqual(state.messages, [])
        self.assertIsNone(state.hotels)
        self.assertIsNone(state.attractions)
    
    def test_workflow_state_with_messages(self):
        """Test WorkflowState with messages"""
        messages = [
            {"role": "user", "content": "Plan a trip to Vietnam"},
            {"role": "assistant", "content": "Sure! Let me help you plan."}
        ]
        state = WorkflowState(messages=messages)
        
        self.assertEqual(len(state.messages), 2)
        self.assertEqual(state.messages[0]["role"], "user")
    
    def test_workflow_state_with_hotel_data(self):
        """Test WorkflowState with hotel data"""
        hotels = [
            {"name": "Hanoi Hotel", "price_per_night": 50.0},
            {"name": "Luxury Resort", "price_per_night": 150.0}
        ]
        state = WorkflowState(
            destination="Hanoi",
            hotels=hotels
        )
        
        self.assertEqual(len(state.hotels), 2)
        self.assertEqual(state.hotels[0]["name"], "Hanoi Hotel")
    
    def test_workflow_state_with_weather(self):
        """Test WorkflowState with weather data"""
        weather = "Sunny, 25-30°C"
        state = WorkflowState(
            destination="Bangkok",
            weather=weather
        )
        
        self.assertEqual(state.weather, weather)
    
    def test_workflow_state_with_itinerary(self):
        """Test WorkflowState with itinerary"""
        itinerary = {
            "day1": "Arrive and explore",
            "day2": "Visit temples",
            "day3": "Shopping"
        }
        state = WorkflowState(
            destination="Bangkok",
            itinerary=itinerary
        )
        
        self.assertIsNotNone(state.itinerary)
        self.assertEqual(len(state.itinerary), 3)
    
    def test_workflow_state_with_summary(self):
        """Test WorkflowState with summary"""
        summary = {
            "total_cost": 5000.0,
            "duration_days": 5,
            "highlights": ["Temple visit", "Beach day"]
        }
        state = WorkflowState(summary=summary)
        
        self.assertIsNotNone(state.summary)
        self.assertEqual(state.summary["total_cost"], 5000.0)
    
    def test_workflow_state_with_currency_rates(self):
        """Test WorkflowState with currency rates"""
        rates = "USD to VND: 25000"
        state = WorkflowState(currency_rates=rates)
        
        self.assertEqual(state.currency_rates, rates)
    
    def test_workflow_state_with_calculator_result(self):
        """Test WorkflowState with calculator result"""
        result = "Total budget: 10,000,000 VND"
        state = WorkflowState(calculator_result=result)
        
        self.assertEqual(state.calculator_result, result)
    
    def test_workflow_state_complete(self):
        """Test WorkflowState with all fields"""
        messages = [{"role": "user", "content": "help"}]
        hotels = [{"name": "Hotel A", "price_per_night": 100}]
        
        state = WorkflowState(
            destination="Hanoi",
            budget="10000000",
            days="7",
            group_size="3",
            messages=messages,
            hotels=hotels,
            attractions="Attractions list",
            weather="Sunny 25°C",
            itinerary={"day1": "explore"},
            summary={"cost": 5000},
            currency_rates="1 USD = 25000 VND",
            calculator_result="Total: 5000",
            prompt="What to do?"
        )
        
        self.assertEqual(state.destination, "Hanoi")
        self.assertEqual(len(state.messages), 1)
        self.assertEqual(len(state.hotels), 1)


class TestHotelInfo(unittest.TestCase):
    """Test cases for HotelInfo model"""
    
    def test_hotel_info_minimal(self):
        """Test HotelInfo with only required fields"""
        hotel = HotelInfo(
            name="Simple Hotel",
            price_per_night=50.0,
            review_count=10
        )
        
        self.assertEqual(hotel.name, "Simple Hotel")
        self.assertEqual(hotel.price_per_night, 50.0)
        self.assertEqual(hotel.review_count, 10)
        self.assertIsNone(hotel.rating)
        self.assertIsNone(hotel.url)
    
    def test_hotel_info_all_fields(self):
        """Test HotelInfo with all fields"""
        hotel = HotelInfo(
            name="Luxury Resort",
            price_per_night=200.0,
            review_count=500,
            rating=4.8,
            url="https://hotel.com"
        )
        
        self.assertEqual(hotel.name, "Luxury Resort")
        self.assertEqual(hotel.price_per_night, 200.0)
        self.assertEqual(hotel.review_count, 500)
        self.assertEqual(hotel.rating, 4.8)
        self.assertEqual(hotel.url, "https://hotel.com")
    
    def test_hotel_info_zero_price(self):
        """Test HotelInfo with zero price"""
        hotel = HotelInfo(
            name="Free Accommodation",
            price_per_night=0.0,
            review_count=0
        )
        
        self.assertEqual(hotel.price_per_night, 0.0)
    
    def test_hotel_info_very_high_price(self):
        """Test HotelInfo with very high price"""
        hotel = HotelInfo(
            name="5-Star Luxury",
            price_per_night=10000.0,
            review_count=100
        )
        
        self.assertEqual(hotel.price_per_night, 10000.0)
    
    def test_hotel_info_no_reviews(self):
        """Test HotelInfo with no reviews"""
        hotel = HotelInfo(
            name="New Hotel",
            price_per_night=75.0,
            review_count=0
        )
        
        self.assertEqual(hotel.review_count, 0)
    
    def test_hotel_info_many_reviews(self):
        """Test HotelInfo with many reviews"""
        hotel = HotelInfo(
            name="Popular Hotel",
            price_per_night=100.0,
            review_count=5000
        )
        
        self.assertEqual(hotel.review_count, 5000)
    
    def test_hotel_info_rating_range(self):
        """Test HotelInfo with various rating values"""
        ratings = [1.0, 2.5, 3.0, 4.0, 4.5, 5.0]
        for rating in ratings:
            hotel = HotelInfo(
                name="Rated Hotel",
                price_per_night=80.0,
                review_count=100,
                rating=rating
            )
            self.assertEqual(hotel.rating, rating)
    
    def test_hotel_info_with_unicode_name(self):
        """Test HotelInfo with unicode hotel name"""
        hotel = HotelInfo(
            name="Khách Sạn Hà Nội",
            price_per_night=60.0,
            review_count=50
        )
        
        self.assertEqual(hotel.name, "Khách Sạn Hà Nội")
    
    def test_hotel_info_url_validation(self):
        """Test HotelInfo with various URL formats"""
        urls = [
            "https://hotel.com",
            "http://booking.com/hotel",
            "https://example.com/hotel?id=123"
        ]
        
        for url in urls:
            hotel = HotelInfo(
                name="Hotel",
                price_per_night=100.0,
                review_count=50,
                url=url
            )
            self.assertEqual(hotel.url, url)
    
    def test_hotel_info_negative_price_allowed(self):
        """Test HotelInfo allows negative prices (for special cases)"""
        hotel = HotelInfo(
            name="Discount Hotel",
            price_per_night=-10.0,
            review_count=20
        )
        
        self.assertEqual(hotel.price_per_night, -10.0)


class TestModelIntegration(unittest.TestCase):
    """Integration tests for multiple models"""
    
    def test_query_analysis_to_trip_plan(self):
        """Test converting QueryAnalysisResult to TripPlan"""
        analysis = QueryAnalysisResult(
            destination="Bangkok",
            budget="5000000",
            days="5",
            missing_fields=["accommodation_type"]
        )
        
        # Convert to TripPlan-like dict
        plan_dict = analysis.dict()
        
        self.assertIn("destination", plan_dict)
        self.assertIn("budget", plan_dict)
        self.assertEqual(plan_dict["destination"], "Bangkok")
    
    def test_workflow_state_with_hotel_info(self):
        """Test WorkflowState with HotelInfo objects"""
        hotels_data = [
            {"name": "Hotel A", "price_per_night": 100.0, "review_count": 50},
            {"name": "Hotel B", "price_per_night": 150.0, "review_count": 200}
        ]
        
        hotels = [HotelInfo(**h) for h in hotels_data]
        state = WorkflowState(
            destination="Hanoi",
            hotels=[h.dict() for h in hotels]
        )
        
        self.assertEqual(len(state.hotels), 2)
    
    def test_complete_workflow_simulation(self):
        """Test simulating complete workflow with models"""
        # Start with query analysis
        analysis = QueryAnalysisResult(
            destination="Paris",
            budget="10000",
            days="7",
            group_size="2",
            missing_fields=[]
        )
        
        # Create workflow state
        state = WorkflowState(
            destination=analysis.destination,
            budget=analysis.budget,
            days=analysis.days,
            group_size=analysis.group_size,
            messages=[{"role": "system", "content": "Trip planned"}]
        )
        
        self.assertEqual(state.destination, "Paris")
        self.assertEqual(len(state.messages), 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
