from typing import List, Optional

from pydantic import BaseModel, Field


class TripPlan(BaseModel):
  """Data model for the user's trip plan. Now stores raw user inputs as strings."""

  destination: Optional[str] = Field(None, description="Destination city/country")
  budget: Optional[str] = Field(
    None, description="Budget for the trip (raw user input)"
  )
  native_currency: Optional[str] = Field(None, description="User's native currency")
  days: Optional[str] = Field(
    None, description="Duration of the trip in days (raw user input)"
  )
  group_size: Optional[str] = Field(
    "1", description="Number of people traveling (raw user input)"
  )
  activity_preferences: Optional[str] = Field(
    None,
    description="Preferences like adventure, culture, relaxation (raw user input)",
  )
  accommodation_type: Optional[str] = Field(
    None,
    description="Preferred accommodation type (e.g., hotel, hostel, airbnb)",
  )
  dietary_restrictions: Optional[str] = Field(
    None, description="Any dietary restrictions (raw user input)"
  )
  transportation_preferences: Optional[str] = Field(
    None, description="Preferred mode of transport (raw user input)"
  )


class QueryAnalysisResult(TripPlan):
  """Data model for the output of the QueryAnalyzer."""

  missing_fields: List[str] = Field(
    default_factory=list,
    description="List of required fields that are missing from the user query",
  )

# default_factory=list means that if missing_fields is not provided
# when creating a QueryAnalysisResult, it will default to [] (a new, empty list).
# This avoids potential issues with all instances sharing the same list.

class WorkflowState(TripPlan):
    """State for the workflow, including conversation history and all planning fields."""
    messages: list = []
    hotels: Optional[list] = None
    attractions: Optional[str] = None
    weather: Optional[str] = None
    itinerary: Optional[dict] = None
    summary: Optional[dict] = None
    currency_rates: Optional[str] = None
    missing_fields: Optional[list] = None
    calculator_result: Optional[str] = None
    prompt: Optional[str] = None

class HotelInfo(BaseModel):
    """Minimal hotel info for workflow use."""
    name: str
    price_per_night: float
    review_count: int
    rating: Optional[float] = None
    url: Optional[str] = None

#<eof>