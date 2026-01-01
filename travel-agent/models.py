from typing import List, Optional
import re

from pydantic import BaseModel, Field, field_validator, ValidationError


# Valid currency codes (ISO 4217)
VALID_CURRENCIES = {
    'USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD', 'CNY', 'INR', 'KRW',
    'BRL', 'MXN', 'RUB', 'ZAR', 'SGD', 'HKD', 'NOK', 'SEK', 'DKK', 'PLN',
    'TRY', 'THB', 'MYR', 'IDR', 'PHP', 'VND', 'TWD', 'SAR', 'AED', 'ILS'
}


class TripPlan(BaseModel):
  """
  Data model for the user's trip plan with validation.

  This model captures all essential details required for planning a trip,
  including destination, dates, budget, and preferences. It includes
  validation logic for budget and days.

  Attributes:
      destination (str): Destination city/country.
      budget (str): Budget for the trip (raw user input).
      native_currency (str): User's native currency.
      start_date (str): Start date in YYYY-MM-DD format.
      end_date (str): End date in YYYY-MM-DD format.
      days (str): Duration of the trip in days (raw user input).
      group_size (str): Number of people traveling (raw user input).
      activity_preferences (str): Preferences like adventure, culture, relaxation.
      accommodation_type (str): Preferred accommodation type.
      dietary_restrictions (str): Any dietary restrictions.
      transportation_preferences (str): Preferred mode of transport.
  """

  destination: Optional[str] = Field(None, description="Destination city/country")
  budget: Optional[str] = Field(
    None, description="Budget for the trip (raw user input)"
  )
  native_currency: Optional[str] = Field(None, description="User's native currency")
  start_date: Optional[str] = Field(None, description="Start date in YYYY-MM-DD format")
  end_date: Optional[str] = Field(None, description="End date in YYYY-MM-DD format")
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

  @field_validator('budget')
  @classmethod
  def validate_budget(cls, v):
    """Validates that the budget is a string or positive number."""
    if v is None:
      return v
    if isinstance(v, str):
      # Allow strings like "500 EUR" or numbers as strings
      return v
    if isinstance(v, (int, float)):
      if v <= 0:
        raise ValueError('Budget must be a positive number.')
      return str(v)
    raise ValueError('Invalid budget format. Must be a string or positive number.')

  @field_validator('days')
  @classmethod
  def validate_days(cls, v):
    """Validates that days is a string or positive integer."""
    if v is None:
      return v
    if isinstance(v, str):
      # Allow strings like "weekend" or numbers as strings
      return v
    if isinstance(v, int):
      if v <= 0:
        raise ValueError('Days must be a positive integer.')
      return str(v)
    raise ValueError('Invalid days format. Must be a string or positive integer.')


class QueryAnalysisResult(TripPlan):
  """
  Data model for the output of the QueryAnalyzer.

  Attributes:
      missing_fields (List[str]): List of required fields that are missing from the user query.
  """

  missing_fields: List[str] = Field(
    default_factory=list,
    description="List of required fields that are missing from the user query",
  )

# default_factory=list means that if missing_fields is not provided
# when creating a QueryAnalysisResult, it will default to [] (a new, empty list).
# This avoids potential issues with all instances sharing the same list.

class WorkflowState(TripPlan):
    """
    State for the workflow, including conversation history and all planning fields.

    Attributes:
        messages (list): List of conversation messages.
        hotels (list): List of found hotels.
        attractions (str): Formatted string of attractions.
        weather (str): Weather forecast information.
        itinerary (dict): Generated itinerary structure.
        summary (dict): Final trip summary.
        currency_rates (str): Exchange rate info.
        missing_fields (list): Fields currently missing.
        calculator_result (str): Result of budget calculations.
        prompt (str): Prompt used for generation (internal).
    """
    messages: list = Field(default_factory=list)  # Accept any objects, including LangChain BaseMessage
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
    """
    Minimal hotel info for workflow use.

    Attributes:
        name (str): Hotel name.
        price_per_night (float): Price per night.
        review_count (int): Number of reviews.
        rating (Optional[float]): Hotel rating.
        url (Optional[str]): Booking URL.
    """
    name: str
    price_per_night: float
    review_count: int
    rating: Optional[float] = None
    url: Optional[str] = None

#<eof>
