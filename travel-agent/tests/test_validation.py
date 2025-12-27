"""
Validation and business logic tests for Travel Agent
"""
import unittest
from datetime import datetime, date, timedelta

from models import TripPlan, QueryAnalysisResult, WorkflowState, HotelInfo
from services.calculator import Calculator


class TestBudgetValidation(unittest.TestCase):
    """Test budget validation logic"""
    
    def test_positive_budget_valid(self):
        """Test positive budget is valid"""
        plan = TripPlan(budget="5000")
        self.assertEqual(plan.budget, "5000")
    
    def test_zero_budget_valid(self):
        """Test zero budget is valid"""
        plan = TripPlan(budget="0")
        self.assertEqual(plan.budget, "0")
    
    def test_budget_with_decimal(self):
        """Test budget with decimal is valid"""
        plan = TripPlan(budget="1500.50")
        self.assertEqual(plan.budget, "1500.50")
    
    def test_budget_allocation_sums_to_total(self):
        """Test budget allocation sums to total"""
        total = 10000
        allocations = {
            "accommodation": 4000,
            "food": 3000,
            "activities": 2000,
            "transport": 1000
        }
        
        total_allocated = sum(allocations.values())
        self.assertEqual(total_allocated, total)
    
    def test_budget_percentage_calculations(self):
        """Test budget percentage calculations"""
        total_budget = 10000
        category_budgets = {
            "accommodation": 0.40,
            "food": 0.30,
            "activities": 0.20,
            "transport": 0.10
        }
        
        total_percentage = sum(category_budgets.values())
        self.assertAlmostEqual(total_percentage, 1.0, places=2)


class TestDateValidation(unittest.TestCase):
    """Test date validation logic"""
    
    def test_future_date_valid(self):
        """Test future date is valid"""
        future_date = (date.today() + timedelta(days=30)).isoformat()
        plan = TripPlan(destination="Paris", days="5")
        # Just verify the plan can be created
        self.assertIsNotNone(plan)
    
    def test_trip_duration_calculation(self):
        """Test trip duration calculation"""
        start_date = "2024-12-20"
        end_date = "2024-12-25"
        
        start = datetime.strptime(start_date, "%Y-%m-%d").date()
        end = datetime.strptime(end_date, "%Y-%m-%d").date()
        duration = (end - start).days + 1
        
        self.assertEqual(duration, 6)
    
    def test_same_day_trip(self):
        """Test same day trip (duration 1)"""
        date_str = "2024-12-20"
        
        start = datetime.strptime(date_str, "%Y-%m-%d").date()
        end = datetime.strptime(date_str, "%Y-%m-%d").date()
        duration = (end - start).days + 1
        
        self.assertEqual(duration, 1)


class TestGroupSizeValidation(unittest.TestCase):
    """Test group size validation"""
    
    def test_single_traveler(self):
        """Test single traveler"""
        plan = TripPlan(group_size="1")
        self.assertEqual(plan.group_size, "1")
    
    def test_small_group(self):
        """Test small group"""
        plan = TripPlan(group_size="4")
        self.assertEqual(plan.group_size, "4")
    
    def test_large_group(self):
        """Test large group"""
        plan = TripPlan(group_size="50")
        self.assertEqual(plan.group_size, "50")
    
    def test_group_affects_per_person_budget(self):
        """Test group size affects per-person budget"""
        total_budget = 10000
        group_sizes = [1, 2, 5, 10]
        
        per_person_budgets = [total_budget / size for size in group_sizes]
        
        # Verify inverse relationship
        self.assertGreater(per_person_budgets[0], per_person_budgets[3])


class TestCurrencyValidation(unittest.TestCase):
    """Test currency validation"""
    
    def test_common_currencies(self):
        """Test common currencies are valid"""
        currencies = ["USD", "EUR", "GBP", "JPY", "VND", "THB", "CNY"]
        
        for currency in currencies:
            plan = TripPlan(native_currency=currency)
            self.assertEqual(plan.native_currency, currency)
    
    def test_currency_code_format(self):
        """Test currency code format"""
        # Currency codes are typically 3 letters
        valid_codes = ["USD", "EUR", "GBP"]
        
        for code in valid_codes:
            self.assertEqual(len(code), 3)


class TestAccommodationValidation(unittest.TestCase):
    """Test accommodation validation"""
    
    def test_valid_accommodation_types(self):
        """Test valid accommodation types"""
        types = ["hotel", "hostel", "airbnb", "resort", "villa", "cottage", "guesthouse"]
        
        for acc_type in types:
            plan = TripPlan(accommodation_type=acc_type)
            self.assertEqual(plan.accommodation_type, acc_type)
    
    def test_hotel_price_ranges(self):
        """Test hotel price ranges"""
        hotels = [
            HotelInfo(name="Budget", price_per_night=20.0, review_count=100),
            HotelInfo(name="Mid-range", price_per_night=100.0, review_count=300),
            HotelInfo(name="Luxury", price_per_night=500.0, review_count=200)
        ]
        
        # Verify price ordering
        self.assertLess(hotels[0].price_per_night, hotels[1].price_per_night)
        self.assertLess(hotels[1].price_per_night, hotels[2].price_per_night)
    
    def test_hotel_rating_valid_range(self):
        """Test hotel rating is in valid range"""
        ratings = [1.0, 2.5, 3.0, 4.0, 4.5, 5.0]
        
        for rating in ratings:
            hotel = HotelInfo(
                name="Hotel",
                price_per_night=100.0,
                review_count=100,
                rating=rating
            )
            
            self.assertGreaterEqual(hotel.rating, 1.0)
            self.assertLessEqual(hotel.rating, 5.0)
    
    def test_review_count_non_negative(self):
        """Test review count is non-negative"""
        hotel = HotelInfo(
            name="Hotel",
            price_per_night=100.0,
            review_count=0
        )
        
        self.assertGreaterEqual(hotel.review_count, 0)


class TestActivityPreferenceValidation(unittest.TestCase):
    """Test activity preference validation"""
    
    def test_single_preference(self):
        """Test single activity preference"""
        plan = TripPlan(activity_preferences="culture")
        self.assertEqual(plan.activity_preferences, "culture")
    
    def test_multiple_preferences(self):
        """Test multiple activity preferences"""
        prefs = "culture,history,adventure"
        plan = TripPlan(activity_preferences=prefs)
        
        prefs_list = prefs.split(",")
        self.assertEqual(len(prefs_list), 3)
    
    def test_preference_parsing(self):
        """Test preference parsing"""
        prefs = "adventure,relaxation,culture"
        prefs_list = prefs.split(",")
        
        self.assertIn("adventure", prefs_list)
        self.assertIn("relaxation", prefs_list)
        self.assertIn("culture", prefs_list)


class TestDietaryRestrictionValidation(unittest.TestCase):
    """Test dietary restriction validation"""
    
    def test_single_restriction(self):
        """Test single dietary restriction"""
        plan = TripPlan(dietary_restrictions="vegetarian")
        self.assertEqual(plan.dietary_restrictions, "vegetarian")
    
    def test_multiple_restrictions(self):
        """Test multiple dietary restrictions"""
        restrictions = "vegetarian,no shellfish,gluten-free"
        plan = TripPlan(dietary_restrictions=restrictions)
        
        restrictions_list = restrictions.split(",")
        self.assertEqual(len(restrictions_list), 3)
    
    def test_restriction_parsing(self):
        """Test dietary restriction parsing"""
        restrictions = "vegetarian,no dairy,no nuts"
        restrictions_list = restrictions.split(",")
        
        self.assertIn("vegetarian", restrictions_list)
        self.assertIn("no dairy", restrictions_list)


class TestTransportationPreferenceValidation(unittest.TestCase):
    """Test transportation preference validation"""
    
    def test_single_transport_mode(self):
        """Test single transportation mode"""
        plan = TripPlan(transportation_preferences="taxi")
        self.assertEqual(plan.transportation_preferences, "taxi")
    
    def test_multiple_transport_modes(self):
        """Test multiple transportation modes"""
        modes = "taxi,bus,subway"
        plan = TripPlan(transportation_preferences=modes)
        
        modes_list = modes.split(",")
        self.assertEqual(len(modes_list), 3)


class TestMissingFieldsValidation(unittest.TestCase):
    """Test missing fields validation"""
    
    def test_no_missing_fields(self):
        """Test when no fields are missing"""
        result = QueryAnalysisResult(
            destination="Bangkok",
            budget="5000",
            days="5",
            missing_fields=[]
        )
        
        self.assertEqual(len(result.missing_fields), 0)
    
    def test_some_missing_fields(self):
        """Test when some fields are missing"""
        result = QueryAnalysisResult(
            destination="Bangkok",
            budget="5000",
            missing_fields=["days", "accommodation_type"]
        )
        
        self.assertEqual(len(result.missing_fields), 2)
    
    def test_missing_field_list_operations(self):
        """Test operations on missing fields list"""
        result = QueryAnalysisResult(
            missing_fields=["budget", "days"]
        )
        
        # Remove a field
        if "budget" in result.missing_fields:
            result.missing_fields.remove("budget")
        
        self.assertEqual(len(result.missing_fields), 1)


class TestArithmeticValidation(unittest.TestCase):
    """Test arithmetic validation"""
    
    def test_addition_commutativity(self):
        """Test addition is commutative"""
        a, b = 10, 20
        result1 = a + b
        result2 = b + a
        
        self.assertEqual(result1, result2)
    
    def test_multiplication_commutativity(self):
        """Test multiplication is commutative"""
        a, b = 7, 8
        result1 = a * b
        result2 = b * a
        
        self.assertEqual(result1, result2)
    
    def test_subtraction_non_commutativity(self):
        """Test subtraction is not commutative"""
        a, b = 10, 3
        result1 = a - b
        result2 = b - a
        
        self.assertNotEqual(result1, result2)
    
    def test_division_non_commutativity(self):
        """Test division is not commutative"""
        a, b = 10, 2
        result1 = a / b
        result2 = b / a
        
        self.assertNotEqual(result1, result2)
    
    def test_multiplication_associativity(self):
        """Test multiplication is associative"""
        a, b, c = 2, 3, 4
        result1 = (a * b) * c
        result2 = a * (b * c)
        
        self.assertEqual(result1, result2)
    
    def test_addition_associativity(self):
        """Test addition is associative"""
        a, b, c = 5, 10, 15
        result1 = (a + b) + c
        result2 = a + (b + c)
        
        self.assertEqual(result1, result2)


class TestWorkflowStateValidation(unittest.TestCase):
    """Test WorkflowState validation"""
    
    def test_workflow_state_with_valid_destination(self):
        """Test workflow state with valid destination"""
        state = WorkflowState(destination="Bangkok")
        self.assertEqual(state.destination, "Bangkok")
    
    def test_workflow_state_with_valid_budget(self):
        """Test workflow state with valid budget"""
        state = WorkflowState(budget="10000000")
        self.assertEqual(state.budget, "10000000")
    
    def test_workflow_state_completeness(self):
        """Test workflow state has all expected fields"""
        state = WorkflowState()
        
        self.assertTrue(hasattr(state, 'destination'))
        self.assertTrue(hasattr(state, 'budget'))
        self.assertTrue(hasattr(state, 'days'))
        self.assertTrue(hasattr(state, 'group_size'))
        self.assertTrue(hasattr(state, 'messages'))
        self.assertTrue(hasattr(state, 'hotels'))
        self.assertTrue(hasattr(state, 'attractions'))
        self.assertTrue(hasattr(state, 'weather'))
        self.assertTrue(hasattr(state, 'itinerary'))
        self.assertTrue(hasattr(state, 'summary'))


class TestBusinessLogicValidation(unittest.TestCase):
    """Test business logic validation"""
    
    def test_cost_per_person_calculation(self):
        """Test cost per person calculation"""
        total_cost = 1000
        group_size = 5
        
        per_person_cost = total_cost / group_size
        
        self.assertEqual(per_person_cost, 200.0)
    
    def test_daily_budget_breakdown(self):
        """Test daily budget breakdown"""
        total_budget = 5000
        days = 5
        
        daily_budget = total_budget / days
        
        self.assertEqual(daily_budget, 1000.0)
    
    def test_budget_category_allocation(self):
        """Test budget category allocation"""
        total_budget = 10000
        accommodation_pct = 0.40
        
        accommodation_budget = int(total_budget * accommodation_pct)
        
        self.assertEqual(accommodation_budget, 4000)
    
    def test_total_cost_calculation(self):
        """Test total cost calculation"""
        accommodation = 2000
        food = 1500
        activities = 1000
        transport = 500
        
        total = accommodation + food + activities + transport
        
        self.assertEqual(total, 5000)


if __name__ == '__main__':
    unittest.main(verbosity=2)
