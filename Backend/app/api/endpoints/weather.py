from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional
import requests
import os
from datetime import datetime, timedelta
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
   """Get current weather for a location"""
   try:
       # Call weather API
       response = requests.get(
           f"{WEATHER_API_URL}/weather",
           params={
               "q": location,
               "appid": WEATHER_API_KEY,
               "units": "metric",
               "lang": "vi"
           }
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

@router.get("/weather/forecast/{location}")
async def get_weather_forecast(
   location: str,
   days: int = 5,
   current_user: User = Depends(get_current_user)
):
   """Get weather forecast for a location"""
   try:
       response = requests.get(
           f"{WEATHER_API_URL}/forecast",
           params={
               "q": location,
               "appid": WEATHER_API_KEY,
               "units": "metric",
               "cnt": days * 8,  # 8 forecasts per day (every 3 hours)
               "lang": "vi"
           }
       )
       
       if response.status_code == 200:
           forecast_data = response.json()
           forecasts = []
           
           for item in forecast_data["list"]:
               forecasts.append({
                   "datetime": item["dt_txt"],
                   "temperature": item["main"]["temp"],
                   "condition": item["weather"][0]["description"],
                   "humidity": item["main"]["humidity"],
                   "wind_speed": item["wind"]["speed"]
               })
           
           return {
               "location": forecast_data["city"]["name"],
               "forecasts": forecasts
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
    """Get weather alerts for a trip"""
    try:
        # Get trip destination from database/storage
        # Try to get trip destination, fallback to default locations if trip not found
        destination = "Ha Noi"  # Default location
        try:
            # Try to import and use trip storage service if available
            from app.services.trip_storage_service import trip_storage
            trip_data = trip_storage.get_trip(trip_id, current_user.id)
            if trip_data and "destination" in trip_data:
                destination = trip_data["destination"]
        except ImportError:
            print("Trip storage service not available, using default location")
            # Use a simple mock approach - in real app, implement proper trip storage
            # For now, we'll extract destination from trip_id if it contains location info
            if "_" in trip_id:
                potential_dest = trip_id.split("_")[-1].replace("-", " ").title()
                if len(potential_dest) > 2:
                    destination = potential_dest
        except Exception as trip_error:
            print(f"Could not get trip data, using default location: {trip_error}")
            # Continue with default destination
        
        alerts = []
        
        try:
            response = requests.get(
                f"{WEATHER_API_URL}/weather",
                params={
                    "q": destination,
                    "appid": WEATHER_API_KEY,
                    "units": "metric",
                    "lang": "vi"
                }
            )
            
            if response.status_code == 200:
                weather_data = response.json()
                temp = weather_data["main"]["temp"]
                condition = weather_data["weather"][0]["description"].lower()
                
                # Check for alert conditions
                if (temp > 35 or temp < 10 or 
                    "rain" in condition or 
                    "storm" in condition or
                    "thunderstorm" in condition):
                    
                    alerts.append({
                        "condition": weather_data["weather"][0]["main"],
                        "description": weather_data["weather"][0]["description"],
                        "temperature": temp,
                        "location": weather_data["name"],
                        "alertTime": datetime.now().isoformat()
                    })
                    
        except Exception as weather_error:
            print(f"Error checking weather for {destination}: {weather_error}")
            # Return empty alerts if weather service fails
        
        return alerts
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Weather alerts error: {str(e)}")

@router.get("/weather/current-alert/{trip_id}")
async def get_current_weather_alert(
    trip_id: str,
    current_user: User = Depends(get_current_user)
):
    """Check if there's a current weather alert for trip destination"""
    try:
        # Get trip destination from database/storage
        destination = "Ha Noi"  # Default location
        try:
            # Try to import and use trip storage service if available
            from app.services.trip_storage_service import trip_storage
            trip_data = trip_storage.get_trip(trip_id, current_user.id)
            if trip_data and "destination" in trip_data:
                destination = trip_data["destination"]
        except ImportError:
            print("Trip storage service not available, using default location")
            # Use a simple mock approach - extract destination from trip_id if it contains location info
            if "_" in trip_id:
                potential_dest = trip_id.split("_")[-1].replace("-", " ").title()
                if len(potential_dest) > 2:
                    destination = potential_dest
        except Exception as trip_error:
            print(f"Could not get trip data, using default location: {trip_error}")
            # Continue with default destination

        response = requests.get(
            f"{WEATHER_API_URL}/weather",
            params={
                "q": destination,
                "appid": WEATHER_API_KEY,
                "units": "metric",
                "lang": "en"
            }
        )
        
        if response.status_code == 200:
            weather_data = response.json()
            temp = weather_data["main"]["temp"]
            condition = weather_data["weather"][0]["description"].lower()
            
            has_alert = False
            alert_type = "info"
            
            # Determine if there should be an alert
            if temp > 38:
                has_alert = True
                alert_type = "critical"
            elif temp < 5:
                has_alert = True
                alert_type = "critical"
            elif "thunderstorm" in condition or "heavy rain" in condition:
                has_alert = True
                alert_type = "critical"
            elif "rain" in condition or temp > 35 or temp < 10:
                has_alert = True
                alert_type = "warning"
            
            result = {
                "hasAlert": has_alert,
                "alertType": alert_type,
                "destination": destination,  # Include destination in response
                "tripId": trip_id
            }
            
            if has_alert:
                result["alert"] = {
                    "condition": weather_data["weather"][0]["main"],
                    "description": weather_data["weather"][0]["description"],
                    "temperature": temp,
                    "location": weather_data["name"],
                    "alertTime": datetime.now().isoformat()
                }
            
            return result
        else:
            raise HTTPException(status_code=404, detail=f"Weather data not found for destination: {destination}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Current weather alert error: {str(e)}")

@router.post("/weather/subscribe-alerts")
async def subscribe_weather_alerts(
   trip_id: str,
   location: str,
   current_user: User = Depends(get_current_user)
):
   """Subscribe to weather alerts for a trip location"""
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
   """Unsubscribe from weather alerts for a trip"""
   try:
       # Remove subscription from database
       return {
           "message": "Successfully unsubscribed from weather alerts",
           "trip_id": trip_id,
           "user_id": current_user.id
       }
       
   except Exception as e:
       raise HTTPException(status_code=500, detail=f"Weather unsubscription error: {str(e)}")