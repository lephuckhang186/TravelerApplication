"""
Database setup for user and trip data storage
"""
import sqlite3
import json
from datetime import datetime
from typing import Optional, List, Dict, Any
import os

class DatabaseManager:
    """SQLite database manager for travel application data"""
    
    def __init__(self, db_path: str = "travel_app.db"):
        self.db_path = db_path
        # Database is now initialized externally via db_setup
        self._ensure_connection()
    
    def _ensure_connection(self):
        """Ensure database file exists and is accessible"""
        if not os.path.exists(self.db_path):
            raise FileNotFoundError(f"Database file not found: {self.db_path}. Please run database setup first.")
    
    def get_connection(self):
        """Get a database connection with foreign key constraints enabled"""
        conn = sqlite3.connect(self.db_path)
        conn.execute("PRAGMA foreign_keys = ON;")
        conn.row_factory = sqlite3.Row
        return conn
    
    def create_user(self, user_id: str, email: str, username: str = None, first_name: str = None, last_name: str = None, profile_picture: str = None):
        """Create or update user in database"""
        with self.get_connection() as conn:
            conn.execute("""
                INSERT OR REPLACE INTO users (
                    id, email, username, first_name, last_name, profile_picture, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (user_id, email, username, first_name, last_name, profile_picture, datetime.now().isoformat()))
            conn.commit()
    
    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID"""
        with self.get_connection() as conn:
            cursor = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    # === PLANNER METHODS ===
    def create_planner(self, user_id: str, planner_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new planner"""
        planner_id = f"planner_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{user_id[:8]}"
        
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO planners (id, user_id, name, description, start_date, end_date)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                planner_id, user_id, planner_data["name"], 
                planner_data.get("description"), planner_data["start_date"], planner_data["end_date"]
            ))
            conn.commit()
        
        return self.get_planner(planner_id, user_id)
    
    def get_user_planners(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all planners for a user"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT * FROM planners WHERE user_id = ? ORDER BY created_at DESC
            """, (user_id,))
            return [dict(row) for row in cursor.fetchall()]
    
    def get_planner(self, planner_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Get specific planner for user"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT * FROM planners WHERE id = ? AND user_id = ?
            """, (planner_id, user_id))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    # === ACTIVITY METHODS ===
    def create_activity(self, planner_id: str, activity_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new activity"""
        activity_id = f"activity_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{planner_id[:8]}"
        
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO activities (id, planner_id, name, description, start_time, end_time, location)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                activity_id, planner_id, activity_data["name"], 
                activity_data.get("description"), activity_data["start_time"],
                activity_data["end_time"], activity_data.get("location")
            ))
            conn.commit()
        
        return self.get_activity(activity_id)
    
    def get_planner_activities(self, planner_id: str) -> List[Dict[str, Any]]:
        """Get all activities for a planner"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT * FROM activities WHERE planner_id = ? ORDER BY start_time
            """, (planner_id,))
            return [dict(row) for row in cursor.fetchall()]
    
    def get_activity(self, activity_id: str) -> Optional[Dict[str, Any]]:
        """Get specific activity"""
        with self.get_connection() as conn:
            cursor = conn.execute("SELECT * FROM activities WHERE id = ?", (activity_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    # === EXPENSE METHODS ===
    def create_expense(self, planner_id: str, expense_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new expense"""
        expense_id = f"expense_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{planner_id[:8]}"
        
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO expenses (id, planner_id, name, amount, currency, category, date)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                expense_id, planner_id, expense_data["name"], expense_data["amount"],
                expense_data.get("currency", "VND"), expense_data["category"], expense_data["date"]
            ))
            conn.commit()
        
        return self.get_expense(expense_id)
    
    def get_planner_expenses(self, planner_id: str) -> List[Dict[str, Any]]:
        """Get all expenses for a planner"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT * FROM expenses WHERE planner_id = ? ORDER BY date DESC
            """, (planner_id,))
            return [dict(row) for row in cursor.fetchall()]
    
    def get_expense(self, expense_id: str) -> Optional[Dict[str, Any]]:
        """Get specific expense"""
        with self.get_connection() as conn:
            cursor = conn.execute("SELECT * FROM expenses WHERE id = ?", (expense_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    # === LEGACY TRIP METHODS (for backward compatibility) ===
    def create_trip(self, user_id: str, trip_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new trip"""
        trip_id = f"trip_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{user_id[:8]}"
        
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO trips (
                    id, user_id, name, destination, description, 
                    start_date, end_date, total_budget, currency
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                trip_id, user_id, trip_data["name"], trip_data["destination"],
                trip_data.get("description"), trip_data["start_date"], 
                trip_data["end_date"], trip_data.get("total_budget"),
                trip_data.get("currency", "VND")
            ))
            conn.commit()
        
        return self.get_trip(trip_id, user_id)
    
    def get_user_trips(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all trips for a user"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT * FROM trips WHERE user_id = ? ORDER BY created_at DESC
            """, (user_id,))
            return [dict(row) for row in cursor.fetchall()]
    
    def get_trip(self, trip_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Get specific trip for user"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT * FROM trips WHERE id = ? AND user_id = ?
            """, (trip_id, user_id))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def update_trip(self, trip_id: str, user_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update trip if it belongs to user"""
        set_clauses = []
        values = []
        
        for key, value in updates.items():
            if key not in ['id', 'user_id', 'created_at']:
                set_clauses.append(f"{key} = ?")
                values.append(value)
        
        if not set_clauses:
            return self.get_trip(trip_id, user_id)
        
        set_clauses.append("updated_at = ?")
        values.extend([datetime.now().isoformat(), trip_id, user_id])
        
        with self.get_connection() as conn:
            conn.execute(f"""
                UPDATE trips SET {', '.join(set_clauses)}
                WHERE id = ? AND user_id = ?
            """, values)
            conn.commit()
        
        return self.get_trip(trip_id, user_id)
    
    def delete_trip(self, trip_id: str, user_id: str) -> bool:
        """Delete trip if it belongs to user"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                DELETE FROM trips WHERE id = ? AND user_id = ?
            """, (trip_id, user_id))
            conn.commit()
            return cursor.rowcount > 0

# Global database instance
db_manager = DatabaseManager()