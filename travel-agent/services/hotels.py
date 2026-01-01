import os
import http.client
import json
import time
import requests
from typing import List, Dict, Any, Optional
from langchain.tools import tool
from urllib.parse import quote

class HotelFinder:
  """
  Finds top hotels for a given destination using the Booking.com API via RapidAPI.

  This class manages the interaction with the Booking.com API to search for locations
  and retrieve hotel details including prices, ratings, and reviews.
  """

  def find_hotels_direct(self, destination: str, checkin: str = None, checkout: str = None, guests: int = 1, max_results: int = 10) -> List[Dict[str, Any]]:
    """
    Direct method for finding hotels based on destination and optional parameters.

    This method is primarily used for testing or direct invocation where a workflow state
    might not be available or needed. It handles input normalization for backward compatibility.

    Args:
      destination (str or WorkflowState): The destination city name or a WorkflowState object containing the destination.
      checkin (str, optional): The check-in date in 'YYYY-MM-DD' format. Defaults to tomorrow if not provided.
      checkout (str, optional): The check-out date in 'YYYY-MM-DD' format. Defaults to 4 days from today if not provided.
      guests (int, optional): The number of guests. Defaults to 1.
      max_results (int, optional): The maximum number of hotels to return. Defaults to 10.

    Returns:
      List[Dict[str, Any]]: A list of dictionaries, where each dictionary represents a hotel
                            containing 'name', 'price_per_night', 'review_count', and 'rating'.
    """
    # Handle WorkflowState input for backward compatibility
    if hasattr(destination, 'destination'):
      # It's a WorkflowState object
      state = destination
      destination = state.destination
      checkin = getattr(state, 'checkin_date', checkin)
      checkout = getattr(state, 'checkout_date', checkout)
      guests = getattr(state, 'group_size', guests) or 1
      max_results = getattr(state, 'max_results', max_results) or 10

    # Set default dates if not provided
    if not checkin or not checkout:
      from datetime import datetime, timedelta
      today = datetime.now().date()
      checkin = checkin or (today + timedelta(days=1)).isoformat()
      checkout = checkout or (today + timedelta(days=4)).isoformat()

    return self._find_hotels_impl(destination, checkin, checkout, guests, max_results)

  def _find_hotels_impl(self, destination: str, checkin: str, checkout: str, guests: int = 1, max_results: int = 10) -> List[Dict[str, Any]]:
    """
    Internal implementation of the hotel search logic using RapidAPI.

    Steps:
    1. specifices the API key and headers.
    2. Searches for the location ID using the 'auto-complete' endpoint.
    3. Retries with simplified queries if the initial location search fails.
    4. Searches for hotels using the retrieved location ID.
    5. Parses the response and extracts relevant hotel information.

    Args:
      destination (str): The city or location to search for.
      checkin (str): Check-in date (YYYY-MM-DD).
      checkout (str): Check-out date (YYYY-MM-DD).
      guests (int): Number of adults.
      max_results (int): Limit on the number of results.

    Returns:
      List[Dict[str, Any]]: A list of valid hotel options.

    Raises:
      ValueError: If individual API calls fail, keys are missing, or no hotels are found.
    """
    api_key = os.environ.get("RAPIDAPI_KEY")
    if not api_key:
      raise ValueError("RAPIDAPI_KEY environment variable not set.")

    headers = {
      'x-rapidapi-key': api_key,
      'x-rapidapi-host': "booking-com18.p.rapidapi.com"
    }

    try:
      # Step 1: Get location ID for the city
      conn = http.client.HTTPSConnection("booking-com18.p.rapidapi.com")
      encoded_destination = quote(destination)

      conn.request("GET", f"/stays/auto-complete?query={encoded_destination}", headers=headers)
      res = conn.getresponse()
      print(f"DEBUG: Hotel Location Search status: {res.status}, headers: {res.getheaders()}")
      data = res.read()
      location_data = json.loads(data.decode("utf-8"))
      print(f"DEBUG: Hotel Location Search response: {data.decode('utf-8')[:500]}")

      if not location_data.get("data"):
        # If no location is found, try to simplify the destination
        simplified_destination = destination.split(",")[0].strip()
        if simplified_destination != destination:
          encoded_simplified_destination = quote(simplified_destination)
          conn.request("GET", f"/stays/auto-complete?query={encoded_simplified_destination}", headers=headers)
          res = conn.getresponse()
          data = res.read()
          location_data = json.loads(data.decode("utf-8"))

          if not location_data.get("data"):
            # Try a very simple query as a last resort
            simple_query = destination.split(",")[0].split()[0].strip()
            if simple_query != destination:
              encoded_simple_query = quote(simple_query)
              conn.request("GET", f"/stays/auto-complete?query={encoded_simple_query}", headers=headers)
              res = conn.getresponse()
              data = res.read()
              location_data = json.loads(data.decode("utf-8"))

            if not location_data.get("data"):
              raise ValueError(f"No location found for destination: {destination}. API Response: {data.decode('utf-8')[:200]}")

      location_id = location_data["data"][0]["id"]

      # Step 2: Add delay to respect rate limits
      time.sleep(2)

      # Step 3: Search for hotels
      conn = http.client.HTTPSConnection("booking-com18.p.rapidapi.com")
      search_url = f"/stays/search?locationId={location_id}&checkinDate={checkin}&checkoutDate={checkout}&units=metric&temperature=c&adults={guests}"
      conn.request("GET", search_url, headers=headers)
      res = conn.getresponse()
      print(f"DEBUG: Hotel Search status: {res.status}, headers: {res.getheaders()}")
      data = res.read()
      search_data = json.loads(data.decode("utf-8"))
      print(f"DEBUG: Hotel Search response: {data.decode('utf-8')[:500]}")
      # Fixed: hotels are directly in the data array
      hotels = search_data.get("data", [])
      if not hotels:
        raise ValueError(f"No hotels found for {destination}")

      results = []
      for hotel in hotels[:max_results]:
        name = hotel.get("name")
        if not name:
          continue

        # Extract price from priceBreakdown.grossPrice.value
        price = None
        if "priceBreakdown" in hotel:
          price_breakdown = hotel["priceBreakdown"]
          if "grossPrice" in price_breakdown:
            price = price_breakdown["grossPrice"].get("value")

        # Extract reviews and rating
        review_count = hotel.get("reviewCount", 0)
        rating = hotel.get("reviewScore", 0)

        results.append({
          "name": name,
          "price_per_night": float(price) if price else None,
          "review_count": review_count,
          "rating": float(rating) if rating else None
        })

      if not results:
        raise ValueError(f"No valid hotels found for {destination}")

      return results

    except Exception as e:
      raise ValueError(f"API request failed: {str(e)}")

  def find_hotels(self, destination, checkin: str = None, checkout: str = None, guests: int = 1, max_results: int = 10) -> List[Dict[str, Any]]:
    """
    Instance method that delegates hotel search using the direct implementation.

    Args:
      destination (str or WorkflowState): Destination or state object.
      checkin (str, optional): Check-in date.
      checkout (str, optional): Check-out date.
      guests (int, optional): Number of guests.
      max_results (int, optional): Max results to return.

    Returns:
      List[Dict[str, Any]]: List of hotel options.
    """
    return self.find_hotels_direct(destination, checkin, checkout, guests, max_results)

  @staticmethod
  @tool
  def find_hotels_static(destination, checkin: str = None, checkout: str = None, guests: int = 1, max_results: int = 10) -> List[Dict[str, Any]]:
    """
    Searches for top hotels in the specified destination using Booking.com API.

    Args:
      destination (str or WorkflowState): The city or location to search hotels in, or a WorkflowState object.
      checkin (str): Check-in date in 'YYYY-MM-DD' format.
      checkout (str): Check-out date in 'YYYY-MM-DD' format.
      guests (int): Number of guests (default 1).
      max_results (int): Maximum number of hotels to return (default 5).

    Returns:
      List[Dict[str, Any]]: A list of hotel options with name, price, reviews, and rating.

    Raises:
      ValueError: If no hotels are found or search fails.
    """
    finder = HotelFinder()
    return finder.find_hotels_direct(destination, checkin, checkout, guests, max_results)

#   @staticmethod
#   @tool
#   def estimate_total_cost(price_per_night: float, total_days: int) -> float:
#     """
#     Estimate total hotel cost based on price per night and number of days.

#     Args:
#       price_per_night (float): Price per night of the selected hotel in USD.
#       total_days (int): Total number of days the user will stay.

#     Returns:
#       float: Total estimated hotel cost for the stay.
#     """
#     return round(price_per_night * total_days, 2)
