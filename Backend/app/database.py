"""
Database setup for user and trip data storage
"""
import sqlite3
import json
from datetime import datetime
from typing import Optional, List, Dict, Any
import os

class DatabaseManager:
    """SQLite database manager for user and trip data"""
    
    def __init__(self, db_path: str = "travel_app.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize database with required tables"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    email TEXT UNIQUE NOT NULL,
                    display_name TEXT,
                    photo_url TEXT,
                    is_active BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS trips (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    destination TEXT NOT NULL,
                    description TEXT,
                    start_date DATE NOT NULL,
                    end_date DATE NOT NULL,
                    total_budget REAL,
                    currency TEXT DEFAULT 'VND',
                    is_active BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users (id)
                )
            """)
            
            conn.commit()
    
    def create_user(self, user_id: str, email: str, display_name: str = None, photo_url: str = None):
        """Create or update user in database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO users (id, email, display_name, photo_url, updated_at)
                VALUES (?, ?, ?, ?, ?)
            """, (user_id, email, display_name, photo_url, datetime.now().isoformat()))
            conn.commit()
    
    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM users WHERE id = ?
            """, (user_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def create_trip(self, user_id: str, trip_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new trip"""
        trip_id = f"trip_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{user_id[:8]}"
        
        with sqlite3.connect(self.db_path) as conn:
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
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM trips WHERE user_id = ? ORDER BY created_at DESC
            """, (user_id,))
            return [dict(row) for row in cursor.fetchall()]
    
    def get_trip(self, trip_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Get specific trip for user"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM trips WHERE id = ? AND user_id = ?
            """, (trip_id, user_id))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def update_trip(self, trip_id: str, user_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update trip if it belongs to user"""
        # Build dynamic update query
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
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(f"""
                UPDATE trips SET {', '.join(set_clauses)}
                WHERE id = ? AND user_id = ?
            """, values)
            conn.commit()
        
        return self.get_trip(trip_id, user_id)
    
    def delete_trip(self, trip_id: str, user_id: str) -> bool:
        """Delete trip if it belongs to user"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                DELETE FROM trips WHERE id = ? AND user_id = ?
            """, (trip_id, user_id))
            conn.commit()
            return cursor.rowcount > 0

# Global database instance
db_manager = DatabaseManager()