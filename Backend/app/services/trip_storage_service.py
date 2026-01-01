"""
Trip storage service for managing trip data persistence
"""
import json
import os
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel

class TripStorageService:
    """
    Service for storing and retrieving trip data using a JSON file.
    
    This service provides a simple file-based persistence mechanism for trip data,
    useful for development or standalone usage where a full database might not be required.
    """
    
    def __init__(self, storage_file: str = "trips_data.json"):
        """
        Initialize the TripStorageService.

        Args:
            storage_file (str): Path to the JSON file for storing trip data. Defaults to "trips_data.json".
        """
        self.storage_file = storage_file
        self._ensure_storage_file()
    
    def _ensure_storage_file(self):
        """
        Ensure the storage file exists.
        
        Creates the file with an empty structure if it does not exist.
        """
        if not os.path.exists(self.storage_file):
            with open(self.storage_file, 'w') as f:
                json.dump({"trips": {}, "user_trips": {}}, f)
    
    def _load_data(self) -> Dict[str, Any]:
        """
        Load data from the storage file.

        Returns:
            Dict[str, Any]: The loaded data containing 'trips' and 'user_trips'.
                            Returns an empty structure if file not found or corrupted.
        """
        try:
            with open(self.storage_file, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {"trips": {}, "user_trips": {}}
    
    def _save_data(self, data: Dict[str, Any]):
        """
        Save data to the storage file.

        Args:
            data (Dict[str, Any]): The data to save.
        """
        with open(self.storage_file, 'w') as f:
            json.dump(data, f, indent=2, default=str)
    
    def create_trip(self, user_id: str, trip_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new trip for a user.

        Args:
            user_id (str): The ID of the user creating the trip.
            trip_data (Dict[str, Any]): Dictionary containing trip details (name, destination, dates, etc.).

        Returns:
            Dict[str, Any]: The created trip record including generated ID and timestamps.
        """
        data = self._load_data()
        
        # Generate trip ID
        trip_id = f"trip_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{user_id}"
        
        # Create trip record
        trip_record = {
            "id": trip_id,
            "user_id": user_id,
            "name": trip_data["name"],
            "destination": trip_data["destination"],
            "description": trip_data.get("description"),
            "start_date": trip_data["start_date"],
            "end_date": trip_data["end_date"],
            "total_budget": trip_data.get("total_budget"),
            "currency": trip_data.get("currency", "VND"),
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "created_by": user_id
        }
        
        # Store trip
        data["trips"][trip_id] = trip_record
        
        # Add to user's trip list
        if user_id not in data["user_trips"]:
            data["user_trips"][user_id] = []
        data["user_trips"][user_id].append(trip_id)
        
        self._save_data(data)
        return trip_record
    
    def get_user_trips(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Get all trips for a specific user.

        Args:
            user_id (str): The user's ID.

        Returns:
            List[Dict[str, Any]]: A list of trip records belonging to the user.
        """
        data = self._load_data()
        user_trip_ids = data["user_trips"].get(user_id, [])
        
        trips = []
        for trip_id in user_trip_ids:
            if trip_id in data["trips"]:
                trips.append(data["trips"][trip_id])
        
        return trips
    
    def get_trip(self, trip_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a specific trip if it belongs to the user.

        Args:
            trip_id (str): The ID of the trip.
            user_id (str): The ID of the requesting user.

        Returns:
            Optional[Dict[str, Any]]: The trip record if found and owned by user, None otherwise.
        """
        data = self._load_data()
        trip = data["trips"].get(trip_id)
        
        if trip and trip["user_id"] == user_id:
            return trip
        return None
    
    def update_trip(self, trip_id: str, user_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Update a trip if it belongs to the user.

        Args:
            trip_id (str): The ID of the trip to update.
            user_id (str): The ID of the requesting user.
            updates (Dict[str, Any]): Dictionary of fields to update.

        Returns:
            Optional[Dict[str, Any]]: The updated trip record if successful, None otherwise.
        """
        data = self._load_data()
        
        if trip_id in data["trips"] and data["trips"][trip_id]["user_id"] == user_id:
            trip = data["trips"][trip_id]
            trip.update(updates)
            trip["updated_at"] = datetime.now().isoformat()
            
            data["trips"][trip_id] = trip
            self._save_data(data)
            return trip
        
        return None
    
    def delete_trip(self, trip_id: str, user_id: str) -> bool:
        """
        Delete a trip if it belongs to the user.

        Args:
            trip_id (str): The ID of the trip to delete.
            user_id (str): The ID of the requesting user.

        Returns:
            bool: True if deletion was successful, False otherwise.
        """
        data = self._load_data()
        
        # Check if trip exists and belongs to user
        if trip_id in data["trips"] and data["trips"][trip_id]["user_id"] == user_id:
            # Remove from trips
            del data["trips"][trip_id]
            
            # Remove from user's trip list
            if user_id in data["user_trips"]:
                data["user_trips"][user_id] = [
                    tid for tid in data["user_trips"][user_id] if tid != trip_id
                ]
            
            self._save_data(data)
            return True
        
        return False

# Global instance
trip_storage = TripStorageService()