import os
import http.client
import json
import time
from typing import List, Dict, Any, Optional
from langchain.tools import tool
from urllib.parse import quote

class HotelFinder:
  """
  Finds top hotels for a given destination using the Booking.com API via RapidAPI.
  """

  @staticmethod
  @tool
  def find_hotels(destination: str, checkin: str, checkout: str, guests: int = 1, max_results: int = 10) -> List[Dict[str, Any]]:
    """
    Searches for top hotels in the specified destination using Booking.com API.

    Args:
      destination (str): The city or location to search hotels in.
      checkin (str): Check-in date in 'YYYY-MM-DD' format.
      checkout (str): Check-out date in 'YYYY-MM-DD' format.
      guests (int): Number of guests (default 1).
      max_results (int): Maximum number of hotels to return (default 5).

    Returns:
      List[Dict[str, Any]]: A list of hotel options with name, price, reviews, and rating.

    Raises:
      ValueError: If no hotels are found or search fails.
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
      data = res.read()
      location_data = json.loads(data.decode("utf-8"))
      
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
            raise ValueError(f"No location found for destination: {destination}")
        else:
          raise ValueError(f"No location found for destination: {destination}")

      location_id = location_data["data"][0]["id"]
      
      # Step 2: Add delay to respect rate limits
      time.sleep(2)
      
      # Step 3: Search for hotels
      conn = http.client.HTTPSConnection("booking-com18.p.rapidapi.com")
      search_url = f"/stays/search?locationId={location_id}&checkinDate={checkin}&checkoutDate={checkout}&units=metric&temperature=c&adults={guests}"
      conn.request("GET", search_url, headers=headers)
      res = conn.getresponse()
      data = res.read()
      search_data = json.loads(data.decode("utf-8"))
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
