import os
import requests
from typing import List, Dict, Any, Optional
from langchain.tools import tool

class AttractionFinder:
    """
    Finds attractions and activities using the Geoapify Places API.

    This service searches for tourist attractions based on a destination and user preferences like 'culture',
    'adventure', etc. It also estimates attraction costs.
    """
    API_URL = "https://api.geoapify.com/v2/places"
    GEOCODE_URL = "https://api.geoapify.com/v1/geocode/search"

    @staticmethod
    @tool
    def find_attractions(destination: str, activity_preferences: List[str]) -> List[Dict[str, Any]]:
        """
        Finds attractions for a given destination and preferences.

        Args:
            destination (str): The city or country to search for attractions.
            activity_preferences (List[str]): List of activity types (e.g., 'culture', 'art').

        Returns:
            List[Dict[str, Any]]: A list of attractions, each as a dictionary with 'name', 'address', and 'category'.

        Raises:
            ValueError: If the API key is missing or coordinates cannot be found.
            requests.exceptions.RequestException: If the API request fails.
        """
        api_key = os.getenv("GEOAPIFY_API_KEY")
        if not api_key:
            raise ValueError("GEOAPIFY_API_KEY not set. Attraction finder cannot function.")
        coords = AttractionFinder._get_coordinates(destination, api_key)
        if not coords:
            raise ValueError(f"Could not find coordinates for {destination}.")
        categories = AttractionFinder._map_preferences_to_categories(activity_preferences)
        params = {
            "categories": ",".join(categories),
            "filter": f"circle:{coords['lon']},{coords['lat']},5000",
            "limit": 10,
            "apiKey": api_key
        }
        response = requests.get(AttractionFinder.API_URL, params=params, timeout=10)
        response.raise_for_status()
        return AttractionFinder._process_attractions(response.json())

    @staticmethod
    def _get_coordinates(destination: str, api_key: str) -> Dict[str, float] | None:
        """
        Retrieves the coordinates for a destination using Geoapify Geocoding API.

        Args:
            destination (str): The place name to geocode.
            api_key (str): Geoapify API Key.

        Returns:
            Dict[str, float] | None: Dictionary with 'lat' and 'lon', or None if not found.

        Raises:
            requests.exceptions.RequestException: If the API request fails.
        """
        params = {"text": destination, "apiKey": api_key, "limit": 1}
        response = requests.get(AttractionFinder.GEOCODE_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data.get("features"):
            props = data["features"][0]["properties"]
            return {"lat": props["lat"], "lon": props["lon"]}
        return None

    @staticmethod
    def _map_preferences_to_categories(preferences: List[str]) -> List[str]:
        """
        Maps user's high-level preferences to specific Geoapify categories.

        Args:
            preferences (List[str]): User preferences like 'culture', 'nature'.

        Returns:
            List[str]: A list of Geoapify category strings (e.g., 'entertainment.culture.theatre').
        """
        category_map = {
            "culture": ["entertainment.culture.theatre", "entertainment.culture.arts_centre", "entertainment.culture.gallery"],
            "adventure": ["natural.forest", "natural.mountain.peak", "entertainment.theme_park"],
            "relaxation": ["leisure.park", "leisure.spa"],
            "nightlife": ["catering.bar", "adult.nightclub"],
            "history": ["heritage.unesco", "tourism.sights.castle", "tourism.sights.archaeological_site", "tourism.sights.monastery"],
            "art": ["entertainment.culture.gallery"]
        }
        # Default to tourism.attraction if no preferences match
        if not preferences:
            return ["tourism.attraction"]

        selected_categories = set()
        for pref in preferences:
            selected_categories.update(category_map.get(pref.lower(), []))
        
        return list(selected_categories) if selected_categories else ["tourism.attraction"]

    @staticmethod
    def _process_attractions(data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Processes the raw API response into a clean list of attractions.

        Args:
            data (Dict[str, Any]): Raw JSON response from Places API.

        Returns:
            List[Dict[str, Any]]: List of simplified attraction objects.
        """
        attractions = []
        for feature in data.get("features", []):
            props = feature.get("properties", {})
            attractions.append({
                "name": props.get("name"),
                "address": props.get("formatted"),
                "category": props.get("categories")[0] if props.get("categories") else "unknown"
            })
        return attractions

    @staticmethod
    @tool
    def estimate_attractions_cost(destination: str, group_size: int, days: int) -> float:
        """
        Estimate average attractions cost using Tavily search.

        Attempts to find ticket prices via web search and estimates total cost.

        Args:
          destination (str): City or country.
          group_size (int): Number of people.
          days (int): Number of days.

        Returns:
          float: Estimated total attractions cost.

        Raises:
            ValueError: If Tavily API Key is missing or search fails.
        """
        try:
            from tavily import TavilyClient  # type: ignore
            api_key = os.getenv("TAVILY_API_KEY")
            if not api_key:
                raise ValueError("TAVILY_API_KEY not set.")
            client = TavilyClient(api_key)
            response = client.search(
                query=f"average ticket price for attractions in {destination}",
                max_results=3,
                search_depth="advanced"
            )
            results = response.get("results", [])
        except ImportError:
            # Fallback to requests if SDK not available
            api_key = os.getenv("TAVILY_API_KEY")
            if not api_key:
                raise ValueError("TAVILY_API_KEY not set.")
            url = "https://api.tavily.com/search"
            headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
            payload = {"query": f"average ticket price for attractions in {destination}", "num_results": 3, "search_depth": "advanced"}
            resp = requests.post(url, headers=headers, json=payload, timeout=15)
            if resp.status_code != 200:
                raise ValueError(f"Tavily search failed: {resp.status_code} {resp.text}")
            data = resp.json()
            results = data.get("results", [])

        import re
        price = None
        for item in results:
            snippet = item.get("snippet") or item.get("description") or item.get("content") or ""
            match = re.search(r"([\u20ac$\u00a3])\s?([0-9]{1,4})", snippet)
            if match:
                price = float(match.group(2))
                break
        if price is None:
            price = 20.0  # fallback USD
        return round(price * group_size * days, 2) 