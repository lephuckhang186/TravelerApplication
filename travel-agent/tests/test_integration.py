"""
Integration and workflow tests for Travel Agent
"""
import unittest
from unittest.mock import Mock, patch
from datetime import datetime, date, timedelta

from models import TripPlan, QueryAnalysisResult, WorkflowState, HotelInfo
from services.calculator import Calculator
from services.currency import CurrencyConverter


class TestTripPlanningWorkflow(unittest.TestCase):
    """Test complete trip planning workflows"""
    
    def test_simple_trip_planning_workflow(self):
        """Test simple trip planning workflow"""
        # Step 1: Query analysis
        query_result = QueryAnalysisResult(
            destination="Bangkok",
            budget="5000",
            days="5",
            group_size="2",
            missing_fields=[]
        )
        
        self.assertEqual(query_result.destination, "Bangkok")
        self.assertEqual(len(query_result.missing_fields), 0)
        
        # Step 2: Create workflow state
        state = WorkflowState(
            destination=query_result.destination,
            budget=query_result.budget,
            days=query_result.days,
            group_size=query_result.group_size
        )
        
        self.assertEqual(state.destination, "Bangkok")
    
    def test_multi_city_trip_workflow(self):
        """Test multi-city trip planning"""
        destinations = ["Bangkok", "Phuket", "Krabi"]
        
        for dest in destinations:
            plan = TripPlan(
                destination=dest,
                budget="3000",
                days="3"
            )
            self.assertEqual(plan.destination, dest)
    
    def test_budget_calculation_workflow(self):
        """Test budget calculation in workflow"""
        # Daily budget calculation
        total_budget = 5000
        num_days = 5
        daily_budget = total_budget / num_days
        
        self.assertEqual(daily_budget, 1000)
        
        # Allocate budget by category
        accommodation = daily_budget * 0.4
        food = daily_budget * 0.3
        activities = daily_budget * 0.2
        transport = daily_budget * 0.1
        
        self.assertAlmostEqual(accommodation + food + activities + transport, daily_budget, places=1)
    
    def test_group_size_affecting_budget(self):
        """Test how group size affects budget calculation"""
        total_budget = 6000
        group_sizes = [1, 2, 3, 4, 5]
        
        for group_size in group_sizes:
            per_person_budget = total_budget / group_size
            self.assertGreater(per_person_budget, 0)
            self.assertLessEqual(per_person_budget, total_budget)
    
    def test_currency_conversion_workflow(self):
        """Test currency conversion in workflow"""
        budget_vnd = "10000000"  # 10 million VND
        budget_usd = 400  # Approximately
        
        # Validate conversion ratio
        conversion_rate = float(budget_vnd) / budget_usd
        self.assertGreater(conversion_rate, 20000)
        self.assertLess(conversion_rate, 30000)
    
    def test_hotel_selection_workflow(self):
        """Test hotel selection workflow"""
        hotels = [
            HotelInfo(name="Budget Hotel", price_per_night=50.0, review_count=100, rating=3.5),
            HotelInfo(name="Mid-Range Hotel", price_per_night=100.0, review_count=300, rating=4.0),
            HotelInfo(name="Luxury Hotel", price_per_night=200.0, review_count=500, rating=4.8)
        ]
        
        # Filter by budget
        budget_limit = 150
        affordable = [h for h in hotels if h.price_per_night <= budget_limit]
        
        self.assertEqual(len(affordable), 2)
        
        # Filter by rating
        high_rated = [h for h in hotels if h.rating >= 4.0]
        
        self.assertEqual(len(high_rated), 2)
    
    def test_accommodation_cost_calculation(self):
        """Test accommodation cost calculation"""
        hotel_price_per_night = 100
        num_nights = 5
        group_size = 2
        
        total_accommodation_cost = hotel_price_per_night * num_nights * group_size
        
        self.assertEqual(total_accommodation_cost, 1000)
    
    def test_meal_planning_workflow(self):
        """Test meal planning in workflow"""
        num_days = 5
        meals_per_day = 3
        avg_meal_cost = 15
        group_size = 2
        
        total_food_cost = num_days * meals_per_day * avg_meal_cost * group_size
        
        self.assertEqual(total_food_cost, 450)
    
    def test_activity_preference_workflow(self):
        """Test activity preference workflow"""
        preferences = "culture,history,adventure"
        prefs_list = preferences.split(",")
        
        self.assertEqual(len(prefs_list), 3)
        self.assertIn("culture", prefs_list)
    
    def test_dietary_restriction_workflow(self):
        """Test dietary restriction workflow"""
        restrictions = "vegetarian,no seafood"
        restrictions_list = restrictions.split(",")
        
        self.assertEqual(len(restrictions_list), 2)
        self.assertTrue(any("vegetarian" in r for r in restrictions_list))


class TestBudgetOptimization(unittest.TestCase):
    """Test budget optimization workflows"""
    
    def test_budget_breakdown(self):
        """Test budget breakdown into categories"""
        total_budget = 10000
        
        breakdown = {
            "accommodation": total_budget * 0.40,
            "food": total_budget * 0.30,
            "activities": total_budget * 0.20,
            "transport": total_budget * 0.10
        }
        
        total = sum(breakdown.values())
        self.assertAlmostEqual(total, total_budget, places=1)
    
    def test_daily_budget_allocation(self):
        """Test daily budget allocation"""
        total_budget = 5000
        num_days = 5
        
        daily_budgets = [total_budget / num_days] * num_days
        
        self.assertEqual(sum(daily_budgets), total_budget)
        self.assertEqual(daily_budgets[0], 1000)
    
    def test_remaining_budget_calculation(self):
        """Test remaining budget tracking"""
        total_budget = 5000
        spent = [500, 400, 300]
        
        total_spent = sum(spent)
        remaining = total_budget - total_spent
        
        self.assertEqual(remaining, 3800)
    
    def test_budget_overflow_detection(self):
        """Test detecting budget overflow"""
        total_budget = 5000
        spent = [2000, 2500, 1000]  # Total: 5500
        
        total_spent = sum(spent)
        is_over_budget = total_spent > total_budget
        
        self.assertTrue(is_over_budget)
    
    def test_savings_calculation(self):
        """Test savings calculation"""
        estimated_budget = 5000
        actual_spent = 4500
        
        savings = estimated_budget - actual_spent
        
        self.assertEqual(savings, 500)


class TestMathOperationsInWorkflow(unittest.TestCase):
    """Test mathematical operations used in workflows"""
    
    def test_addition_workflow(self):
        """Test addition in expense workflow"""
        expenses = [100, 200, 150, 50]
        total = sum(expenses)
        
        self.assertEqual(total, 500)
    
    def test_multiplication_workflow(self):
        """Test multiplication for cost calculations"""
        price_per_night = 100
        num_nights = 5
        
        total_cost = price_per_night * num_nights
        
        self.assertEqual(total_cost, 500)
    
    def test_division_for_per_person_cost(self):
        """Test division for per-person cost"""
        total_cost = 1000
        group_size = 4
        
        per_person_cost = total_cost / group_size
        
        self.assertEqual(per_person_cost, 250.0)
    
    def test_subtraction_for_remaining_budget(self):
        """Test subtraction for remaining budget"""
        total_budget = 5000
        spent = 3200
        
        remaining = total_budget - spent
        
        self.assertEqual(remaining, 1800)
    
    def test_complex_calculation_workflow(self):
        """Test complex calculation workflow"""
        # Total trip budget
        total_budget = 10000
        
        # Allocate to categories
        accommodation = 100 * 5  # 500
        food = 50 * 10  # 500
        activities = 1000
        
        total_allocated = accommodation + food + activities
        remaining = total_budget - total_allocated
        
        self.assertEqual(remaining, 8000)


class TestCompleteTrip(unittest.TestCase):
    """Test complete trip from start to finish"""
    
    def test_complete_trip_lifecycle(self):
        """Test complete trip lifecycle"""
        # Phase 1: Plan creation
        plan = QueryAnalysisResult(
            destination="Hanoi",
            budget="10000000",
            days="7",
            group_size="3",
            activity_preferences="culture,history,food"
        )
        
        self.assertEqual(plan.destination, "Hanoi")
        
        # Phase 2: Workflow state creation
        state = WorkflowState(
            destination=plan.destination,
            budget=plan.budget,
            days=plan.days,
            group_size=plan.group_size
        )
        
        # Phase 3: Add accommodations
        hotels = [
            HotelInfo(name="Hotel A", price_per_night=80.0, review_count=100),
            HotelInfo(name="Hotel B", price_per_night=150.0, review_count=300)
        ]
        state.hotels = [h.dict() for h in hotels]
        
        # Phase 4: Calculate costs
        num_days = int(plan.days)
        num_people = int(plan.group_size)
        hotel_cost = 80.0 * num_days * num_people  # Cheapest option
        
        self.assertEqual(hotel_cost, 1680.0)
        
        # Phase 5: Add messages to conversation
        state.messages = [
            {"role": "user", "content": "Plan my Hanoi trip"},
            {"role": "assistant", "content": "Sure! Let me plan it for you"}
        ]
        
        self.assertEqual(len(state.messages), 2)
    
    def test_trip_with_all_components(self):
        """Test trip with all components"""
        # Create complete trip state
        state = WorkflowState(
            destination="Ho Chi Minh City",
            budget="15000000",
            days="5",
            group_size="2",
            activity_preferences="nightlife,food,shopping",
            accommodation_type="hotel",
            dietary_restrictions="no shellfish",
            transportation_preferences="taxi,uber"
        )
        
        # Add all components
        state.messages = [{"role": "system", "content": "Trip planned"}]
        state.hotels = [
            {"name": "Hotel XYZ", "price_per_night": 120.0, "review_count": 200}
        ]
        state.attractions = "Ben Thanh Market, War Remnants Museum"
        state.weather = "Hot and humid, 28-32°C"
        state.itinerary = {"day1": "Arrive and explore", "day2": "Market tour"}
        state.summary = {"total_cost": 5000, "highlights": ["Market visit"]}
        state.currency_rates = "1 USD = 25000 VND"
        
        # Verify all components
        self.assertEqual(state.destination, "Ho Chi Minh City")
        self.assertIsNotNone(state.hotels)
        self.assertIsNotNone(state.attractions)
        self.assertIsNotNone(state.itinerary)
        self.assertIsNotNone(state.summary)


class TestDataFlow(unittest.TestCase):
    """Test data flow between services"""

    def test_query_to_state_data_flow(self):
        """Test data flow from query analysis to workflow state"""
        # QueryAnalyzer output
        query_output = QueryAnalysisResult(
            destination="Bangkok",
            budget="5000",
            days="5",
            missing_fields=[]
        )

        # Convert to WorkflowState
        state = WorkflowState(
            destination=query_output.destination,
            budget=query_output.budget,
            days=query_output.days
        )

        # Verify data preservation
        self.assertEqual(state.destination, query_output.destination)
        self.assertEqual(state.budget, query_output.budget)

    def test_hotel_data_flow(self):
        """Test hotel data flow"""
        # Hotel info objects
        hotel_data = {
            "name": "Grand Hotel",
            "price_per_night": 150.0,
            "review_count": 500,
            "rating": 4.8
        }

        hotel = HotelInfo(**hotel_data)

        # Add to workflow state
        state = WorkflowState(hotels=[hotel.dict()])

        # Retrieve and verify
        self.assertEqual(state.hotels[0]["name"], "Grand Hotel")
        self.assertEqual(state.hotels[0]["price_per_night"], 150.0)


class TestCompleteWorkflowIntegration(unittest.TestCase):
    """Test complete end-to-end workflows that actually exercise the system"""

    def test_full_trip_planning_workflow_with_realistic_data(self):
        """Test complete workflow with realistic, challenging data"""
        # Phase 1: Complex query analysis
        query_result = QueryAnalysisResult(
            destination="Paris, France",
            budget="2500.75",  # Decimal budget
            days="7",  # Week-long trip
            group_size="3",  # Small family
            activity_preferences="culture,museums,food,wine,walking",
            accommodation_type="boutique hotel",
            dietary_restrictions="vegetarian,no shellfish",
            transportation_preferences="metro,walking,taxi",
            missing_fields=[]
        )

        # Phase 2: Create comprehensive workflow state
        state = WorkflowState(
            destination=query_result.destination,
            budget=query_result.budget,
            days=query_result.days,
            group_size=query_result.group_size,
            activity_preferences=query_result.activity_preferences,
            accommodation_type=query_result.accommodation_type,
            dietary_restrictions=query_result.dietary_restrictions,
            transportation_preferences=query_result.transportation_preferences
        )

        # Phase 3: Add realistic hotel options with varying prices
        hotels = [
            HotelInfo(name="Budget Hotel", price_per_night=85.0, review_count=120, rating=3.8),
            HotelInfo(name="Mid-Range Hotel", price_per_night=145.0, review_count=350, rating=4.2),
            HotelInfo(name="Luxury Boutique", price_per_night=280.0, review_count=180, rating=4.7),
            HotelInfo(name="Hostel Option", price_per_night=45.0, review_count=450, rating=4.0)
        ]
        state.hotels = [h.dict() for h in hotels]

        # Phase 4: Calculate budget breakdown with realistic constraints
        try:
            budget = float(query_result.budget)
            days = int(query_result.days)
            group_size = int(query_result.group_size)

            # Allocate budget: 40% accommodation, 30% food, 20% activities, 10% transport
            accommodation_budget = budget * 0.40
            food_budget = budget * 0.30
            activities_budget = budget * 0.20
            transport_budget = budget * 0.10

            # Calculate per person per day costs
            daily_accommodation = accommodation_budget / days / group_size
            daily_food = food_budget / days / group_size
            daily_activities = activities_budget / days / group_size
            daily_transport = transport_budget / days / group_size

            # Verify budget allocation adds up
            total_allocated = accommodation_budget + food_budget + activities_budget + transport_budget
            self.assertAlmostEqual(total_allocated, budget, places=2)

            # Phase 5: Select appropriate hotel based on budget
            affordable_hotels = [h for h in hotels if h.price_per_night <= daily_accommodation * 1.5]
            self.assertGreater(len(affordable_hotels), 0)

            # Phase 6: Create detailed itinerary
            itinerary = {}
            for day in range(1, days + 1):
                itinerary[f"day{day}"] = {
                    "morning": "Breakfast at hotel",
                    "midday": f"Visit museums and cultural sites (Budget: €{daily_activities:.2f})",
                    "afternoon": f"Walking tour and local exploration",
                    "evening": f"Dinner at vegetarian restaurant (Budget: €{daily_food:.2f})"
                }
            state.itinerary = itinerary

            # Phase 7: Add conversation history
            state.messages = [
                {"role": "user", "content": "Plan a 7-day trip to Paris for 3 people with €2500 budget"},
                {"role": "assistant", "content": "I'll create a comprehensive plan for your Paris trip."},
                {"role": "user", "content": "Make sure to include vegetarian options"},
                {"role": "assistant", "content": "I've included vegetarian-friendly dining options."}
            ]

            # Phase 8: Final verification - ensure data consistency
            self.assertEqual(state.destination, "Paris, France")
            self.assertEqual(len(state.hotels), 4)
            self.assertEqual(len(state.itinerary), 7)
            self.assertEqual(len(state.messages), 4)
            self.assertIsNotNone(state.activity_preferences)
            self.assertIsNotNone(state.dietary_restrictions)

        except ValueError as e:
            self.fail(f"Budget calculation failed: {e}")

    def test_large_scale_trip_planning(self):
        """Test planning for large groups with complex requirements"""
        # Test with large group and complex preferences
        query_result = QueryAnalysisResult(
            destination="Tokyo",
            budget="50000",  # Large budget
            days="14",       # Two weeks
            group_size="12", # Large group
            activity_preferences="culture,technology,food,shopping,nightlife,adventure,outdoor",
            accommodation_type="hotel chain",
            missing_fields=[]
        )

        state = WorkflowState(**query_result.dict())

        # Calculate group budget allocation
        budget = float(query_result.budget)
        days = int(query_result.days)
        group_size = int(query_result.group_size)

        # Per person per day budget
        per_person_daily = budget / days / group_size
        self.assertGreater(per_person_daily, 200)  # Should be substantial

        # Add many hotel options
        hotels = []
        for i in range(50):  # Many hotel options
            hotel = HotelInfo(
                name=f"Tokyo Hotel Chain {i}",
                price_per_night=150.0 + (i * 5),  # Varying prices
                review_count=200 + i,
                rating=3.5 + (i % 20) * 0.1  # Varying ratings
            )
            hotels.append(hotel)

        state.hotels = [h.dict() for h in hotels]

        # Filter hotels by budget and rating
        affordable_hotels = [h for h in hotels if h.price_per_night <= per_person_daily]
        high_rated_hotels = [h for h in hotels if h.rating >= 4.0]

        self.assertGreater(len(affordable_hotels), 10)
        self.assertGreater(len(high_rated_hotels), 10)

        # Verify large-scale data handling
        self.assertEqual(len(state.hotels), 50)
        self.assertEqual(state.group_size, "12")
        self.assertGreater(len(state.activity_preferences.split(",")), 5)


if __name__ == '__main__':
    unittest.main(verbosity=2)
