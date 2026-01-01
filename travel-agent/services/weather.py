import os
import requests
from typing import Dict, Any
from datetime import datetime
from langchain.tools import tool

class WeatherService:
    """
    A simplified weather service using OpenWeatherMap's 5-day/3-hour forecast.

    This service fetches weather forecasts for a specific destination and processes
    the raw data into a daily summary including min/max temperatures and general conditions.
    """
    API_URL = "http://api.openweathermap.org/data/2.5/forecast"
    GEO_URL = "http://api.openweathermap.org/geo/1.0/direct"

    @staticmethod
    @tool
    def get_weather(destination: str, days: int = 5) -> Dict[str, Any]:
        """
        Fetches the weather forecast for a given destination.

        Retrieves coordinates for the destination and then queries the OpenWeatherMap
        API for a forecast, which is simplified into a daily summary.

        Args:
            destination (str): The city or location (e.g., "Paris, France") to get the weather for.
            days (int, optional): Number of days to forecast (maximum 5 due to API limits). Defaults to 5.

        Returns:
            Dict[str, Any]: A dictionary containing:
                - 'destination': Name of the location.
                - 'forecast': List of daily summaries (date, temp_min, temp_max, condition, description).
                - 'summary': A readable string summary.

        Raises:
            ValueError: If the API key is missing, coordinates cannot be found, or no data is returned.
            requests.exceptions.RequestException: If the API request fails.
        """
        api_key = os.getenv("OPENWEATHER_API_KEY")
        if not api_key:
            raise ValueError("OPENWEATHER_API_KEY not set. Weather service cannot function.")
        coords = WeatherService._get_coordinates(destination, api_key)
        if not coords:
            raise ValueError(f"Could not find coordinates for {destination}.")
        params = {
            "lat": coords["lat"],
            "lon": coords["lon"],
            "appid": api_key,
            "units": "metric",
            "cnt": min(days, 5) * 8
        }
        response = requests.get(WeatherService.API_URL, params=params, timeout=10)
        response.raise_for_status()
        return WeatherService._process_weather_data(response.json(), destination)

    @staticmethod
    def _get_coordinates(destination: str, api_key: str) -> Dict[str, float] | None:
        """
        Retrieves the latitude and longitude for a given destination name.

        Args:
            destination (str): The name of the city or place.
            api_key (str): OpenWeatherMap API key.

        Returns:
            Dict[str, float] | None: A dictionary with 'lat' and 'lon' keys, or None if not found.

        Raises:
            requests.exceptions.RequestException: If the API request fails.
        """
        params = {"q": destination, "limit": 1, "appid": api_key}
        response = requests.get(WeatherService.GEO_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data:
            return {"lat": data[0]["lat"], "lon": data[0]["lon"]}
        return None

    @staticmethod
    def _process_weather_data(data: Dict[str, Any], destination: str) -> Dict[str, Any]:
        """
        Processes raw API response data into a daily forecast summary.

        Aggregates 3-hour forecast segments into daily highs, lows, and dominant conditions.

        Args:
            data (Dict[str, Any]): Raw JSON response from OpenWeatherMap Forecast API.
            destination (str): The name of the destination.

        Returns:
            Dict[str, Any]: Processed forecast data.

        Raises:
            ValueError: If the API response contains no weather list data.
        """
        if not data.get("list"):
            raise ValueError("No weather data found in API response.")
        daily_forecasts: Dict[str, dict] = {}
        for item in data["list"]:
            date = datetime.fromtimestamp(item["dt"]).strftime('%Y-%m-%d')
            if date not in daily_forecasts:
                daily_forecasts[date] = {
                    "temps": [],
                    "conditions": [],
                    "descriptions": []
                }
            daily_forecasts[date]["temps"].append(item["main"]["temp"])
            daily_forecasts[date]["conditions"].append(item["weather"][0]["main"])
            daily_forecasts[date]["descriptions"].append(item["weather"][0]["description"])
        processed_forecast = []
        for date, daily_data in daily_forecasts.items():
            processed_forecast.append({
                "date": date,
                "temp_min": min(daily_data["temps"]),
                "temp_max": max(daily_data["temps"]),
                "condition": max(set(daily_data["conditions"]), key=daily_data["conditions"].count),
                "description": max(set(daily_data["descriptions"]), key=daily_data["descriptions"].count),
            })
        return {
            "destination": data.get("city", {}).get("name", destination),
            "forecast": processed_forecast,
            "summary": f"Weather forecast for {len(processed_forecast)} days in {destination}."
        } 