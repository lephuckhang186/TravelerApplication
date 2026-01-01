"""
Weather API endpoints for weather information and alerts.
"""
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional, Dict, Any
import requests
import os
from datetime import datetime, timedelta, date
import json
from app.core.dependencies import get_current_user
from app.core.config import settings
from app.models.user import User

router = APIRouter()

# Weather API configuration - you can use OpenWeatherMap or similar
WEATHER_API_KEY = settings.WEATHER_API_KEY or "your_api_key_here"
WEATHER_API_URL = "http://api.openweathermap.org/data/2.5"

@router.get("/weather/current/{location}")
async def get_current_weather(
   location: str,
   current_user: User = Depends(get_current_user)
):
   """
   Get current weather for a location.

   Fetches current weather data from OpenWeatherMap API.

   Args:
       location (str): The location name (e.g., "Ha Noi").
       current_user (User): The current authenticated user.

   Returns:
       dict: Weather data including temperature, condition, humidity, etc.

   Raises:
       HTTPException(404): If location is not found.
       HTTPException(500): If the weather service fails.
   """
   try:
       # Call weather API
       response = requests.get(
           f"{WEATHER_API_URL}/weather",
           params={
               "q": location,
               "appid": WEATHER_API_KEY,
               "units": "metric",
               "lang": "vi"
           },
           timeout=10
       )
       
       if response.status_code == 200:
           weather_data = response.json()
           return {
               "location": weather_data["name"],
               "temperature": weather_data["main"]["temp"],
               "condition": weather_data["weather"][0]["description"],
               "humidity": weather_data["main"]["humidity"],
               "wind_speed": weather_data["wind"]["speed"],
               "timestamp": datetime.now().isoformat()
           }
       else:
           raise HTTPException(status_code=404, detail="Location not found")
           
   except Exception as e:
       raise HTTPException(status_code=500, detail=f"Weather service error: {str(e)}")

@router.get("/weather/alerts/{trip_id}")
async def get_weather_alerts(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get weather alerts for a trip.

    Checks if today is within the trip's date range. If so, fetches weather info
    for the trip's destination. Currently returns weather info as "alerts" regardless
    of severity during the trip.

    Args:
        trip_id (str): The ID of the trip.
        current_user (User): The current authenticated user.

    Returns:
        List[dict]: A list of weather alert objects. Returns empty list if not finding alerts.

    Raises:
        HTTPException(404): Trip not found.
        HTTPException(500): Server error.
    """
    try:
        from app.services.firebase_service import firebase_service
        
        print(f"🔍 Weather alerts check for trip {trip_id}, user: {current_user.id}")
        
        # Get trip data from Firebase
        trip_data = await firebase_service.get_trip(trip_id, current_user.id)
        if not trip_data:
            print(f"❌ Trip {trip_id} not found")
            raise HTTPException(status_code=404, detail="Trip not found")
        
        destination = trip_data.get("destination") or trip_data.get("name", "Ha Noi")
        print(f"📍 Trip destination: {destination}")
        
        # Parse trip dates
        start_date_str = trip_data.get('start_date', '')
        end_date_str = trip_data.get('end_date', '')
        
        # Handle different date formats
        if 'T' in start_date_str:
            start_date_str = start_date_str.split('T')[0]
        if 'T' in end_date_str:
            end_date_str = end_date_str.split('T')[0]
        
        try:
            start_date = date.fromisoformat(start_date_str)
            end_date = date.fromisoformat(end_date_str)
            today = date.today()
            
            print(f"📅 Trip dates: {start_date} to {end_date}")
            print(f"📅 Today: {today}")
            
            # Check if today is within trip dates
            if not (start_date <= today <= end_date):
                print(f"⏭️ Today is not within trip dates - skipping weather check")
                return []
            
            print(f"✅ Today is within trip dates - checking weather for {destination}")
            
        except Exception as date_error:
            print(f"⚠️ Could not parse trip dates: {date_error}")
            return []
        
        alerts = []
        
        try:
            response = requests.get(
                f"{WEATHER_API_URL}/weather",
                params={
                    "q": destination,
                    "appid": WEATHER_API_KEY,
                    "units": "metric",
                    "lang": "vi"
                },
                timeout=10
            )
            print(f"🌤️ Weather API response status: {response.status_code}")
            
            if response.status_code == 200:
                weather_data = response.json()
                temp = weather_data["main"]["temp"]
                condition = weather_data["weather"][0]["description"].lower()
                
                print(f"🌡️ Current weather: {temp}°C, {condition}")
                
                # Always return weather info when today is within trip dates
                # No conditions needed - just show current weather
                alerts.append({
                    "condition": weather_data["weather"][0]["main"],
                    "description": weather_data["weather"][0]["description"],
                    "temperature": temp,
                    "location": weather_data["name"],
                    "alertTime": datetime.now().isoformat(),
                    "tripDates": {
                        "start": start_date.isoformat(),
                        "end": end_date.isoformat(),
                        "today": today.isoformat()
                    },
                    "isWarning": (temp > 35 or temp < 10 or 
                                 "rain" in condition or 
                                 "storm" in condition or
                                 "thunderstorm" in condition)
                })
                print(f"📋 Weather notification created: {condition}, {temp}°C (always show during trip)")
                    
        except Exception as weather_error:
            print(f"❌ Error checking weather for {destination}: {weather_error}")
            # Return empty alerts if weather service fails
        
        return alerts
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Weather alerts error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Weather alerts error: {str(e)}")

@router.get("/weather/current-alert/{trip_id}")
async def get_current_weather_alert(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Check if there's a current weather alert for trip destination.

    Checks if today is within trip dates and returns weather status/alerts.
    Provides alert severity level (info, warning, critical).

    Args:
        trip_id (str): The ID of the trip.
        current_user (User): The current authenticated user.

    Returns:
        dict: Alert status object.

    Raises:
        HTTPException(404): Trip or weather data not found.
        HTTPException(500): Server error.
    """
    try:
        from app.services.firebase_service import firebase_service
        
        print(f"🔍 Current weather alert check for trip {trip_id}, user: {current_user.id}")
        
        # Get trip data from Firebase
        trip_data = await firebase_service.get_trip(trip_id, current_user.id)
        if not trip_data:
            print(f"❌ Trip {trip_id} not found")
            raise HTTPException(status_code=404, detail="Trip not found")
        
        destination = trip_data.get("destination") or trip_data.get("name", "Ha Noi")
        print(f"📍 Trip destination: {destination}")
        
        # Parse trip dates
        start_date_str = trip_data.get('start_date', '')
        end_date_str = trip_data.get('end_date', '')
        
        # Handle different date formats
        if 'T' in start_date_str:
            start_date_str = start_date_str.split('T')[0]
        if 'T' in end_date_str:
            end_date_str = end_date_str.split('T')[0]
        
        try:
            start_date = date.fromisoformat(start_date_str)
            end_date = date.fromisoformat(end_date_str)
            today = date.today()
            
            print(f"📅 Trip dates: {start_date} to {end_date}")
            print(f"📅 Today: {today}")
            
            # Check if today is within trip dates
            if not (start_date <= today <= end_date):
                print(f"⏭️ Today is not within trip dates - no weather alerts needed")
                return {
                    "hasAlert": False,
                    "alertType": "info",
                    "destination": destination,
                    "tripId": trip_id,
                    "tripDates": {
                        "start": start_date.isoformat(),
                        "end": end_date.isoformat(),
                        "today": today.isoformat()
                    }
                }
            
            print(f"✅ Today is within trip dates - checking weather for {destination}")
            
        except Exception as date_error:
            print(f"⚠️ Could not parse trip dates: {date_error}")
            return {
                "hasAlert": False,
                "alertType": "info",
                "destination": destination,
                "tripId": trip_id
            }

        response = requests.get(
            f"{WEATHER_API_URL}/weather",
            params={
                "q": destination,
                "appid": WEATHER_API_KEY,
                "units": "metric",
                "lang": "en"
            },
            timeout=10
        )
        print(f"🌤️ Weather API response status: {response.status_code}")
        
        if response.status_code == 200:
            weather_data = response.json()
            temp = weather_data["main"]["temp"]
            condition = weather_data["weather"][0]["description"].lower()
            
            print(f"🌡️ Current weather: {temp}°C, {condition}")
            
            # Always show weather info when today is within trip dates
            # Determine severity level for display purposes
            has_alert = True  # Always true when within trip dates
            alert_type = "info"
            
            if temp > 38:
                alert_type = "critical"
            elif temp < 5:
                alert_type = "critical"
            elif "thunderstorm" in condition or "heavy rain" in condition:
                alert_type = "critical"
            elif "rain" in condition or temp > 35 or temp < 10:
                alert_type = "warning"
            
            result = {
                "hasAlert": has_alert,
                "alertType": alert_type,
                "destination": destination,
                "tripId": trip_id,
                "tripDates": {
                    "start": start_date.isoformat(),
                    "end": end_date.isoformat(),
                    "today": today.isoformat()
                },
                "alert": {
                    "condition": weather_data["weather"][0]["main"],
                    "description": weather_data["weather"][0]["description"],
                    "temperature": temp,
                    "location": weather_data["name"],
                    "alertTime": datetime.now().isoformat()
                }
            }
            
            print(f"📋 Weather notification: {alert_type} - {condition}, {temp}°C (always show during trip)")
            
            return result
        else:
            raise HTTPException(status_code=404, detail=f"Weather data not found for destination: {destination}")
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Current weather alert error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Current weather alert error: {str(e)}")

@router.post("/weather/subscribe-alerts")
async def subscribe_weather_alerts(
   trip_id: str,
   location: str,
   current_user: User = Depends(get_current_user)
):
   """
   Subscribe to weather alerts for a trip location.

   Args:
       trip_id (str): The trip ID.
       location (str): The location/destination.
       current_user (User): The current authenticated user.

   Returns:
       dict: Subscription confirmation.

   Raises:
       HTTPException(500): Server error.
   """
   try:
       # In a real implementation, you would save the subscription to database
       # and set up periodic checks or webhooks
       
       return {
           "message": "Successfully subscribed to weather alerts",
           "trip_id": trip_id,
           "location": location,
           "user_id": current_user.id
       }
       
   except Exception as e:
       raise HTTPException(status_code=500, detail=f"Weather subscription error: {str(e)}")

@router.delete("/weather/unsubscribe-alerts/{trip_id}")
async def unsubscribe_weather_alerts(
   trip_id: str,
   current_user: User = Depends(get_current_user)
):
   """
   Unsubscribe from weather alerts for a trip.

   Args:
       trip_id (str): The trip ID.
       current_user (User): The current authenticated user.

   Returns:
       dict: Unsubscription confirmation.

   Raises:
       HTTPException(500): Server error.
   """
   try:
       # Remove subscription from database
       return {
           "message": "Successfully unsubscribed from weather alerts",
           "trip_id": trip_id,
           "user_id": current_user.id
       }
       
   except Exception as e:
       raise HTTPException(status_code=500, detail=f"Weather unsubscription error: {str(e)}")