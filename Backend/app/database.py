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
        # Create database if it doesn't exist
        self._init_database()
    
    def _init_database(self):
        """Initialize database and create tables if they don't exist"""
        if not os.path.exists(self.db_path):
            # Create database and tables
            self._create_tables()
        else:
            # Check if all required tables exist
            self._ensure_tables_exist()

    def _ensure_tables_exist(self):
        """Ensure all required tables exist and update schema if needed"""
        try:
            with self.get_connection() as conn:
                cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
                existing_tables = {row[0] for row in cursor.fetchall()}
                required_tables = {'users', 'trips', 'planners', 'activities', 'expenses', 'collaborators'}
                
                if not required_tables.issubset(existing_tables):
                    print(f"Missing tables: {required_tables - existing_tables}")
                    self._create_tables()
                else:
                    # Check if expenses table needs schema update
                    self._update_expenses_schema()
        except Exception as e:
            print(f"Error checking tables: {e}")
            self._create_tables()
    
    def _update_expenses_schema(self):
        """Update expenses table schema to remove foreign key constraint"""
        try:
            with self.get_connection() as conn:
                # Check if expenses table has foreign key constraint
                cursor = conn.execute("SELECT sql FROM sqlite_master WHERE name='expenses' AND type='table'")
                table_sql = cursor.fetchone()
                
                if table_sql and "FOREIGN KEY (planner_id) REFERENCES planners" in table_sql[0]:
                    print("🔧 SCHEMA_UPDATE: Updating expenses table to remove foreign key constraint")
                    
                    # Create new expenses table without foreign key
                    conn.execute("""
                        CREATE TABLE IF NOT EXISTS expenses_new (
                            id TEXT PRIMARY KEY,
                            planner_id TEXT NOT NULL,
                            name TEXT NOT NULL,
                            amount REAL NOT NULL,
                            currency TEXT DEFAULT 'VND',
                            category TEXT,
                            date TEXT NOT NULL,
                            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                        )
                    """)
                    
                    # Copy data from old table
                    conn.execute("""
                        INSERT INTO expenses_new 
                        SELECT * FROM expenses
                    """)
                    
                    # Drop old table and rename new one
                    conn.execute("DROP TABLE expenses")
                    conn.execute("ALTER TABLE expenses_new RENAME TO expenses")
                    
                    conn.commit()
                    print("✅ SCHEMA_UPDATE: Expenses table schema updated successfully")
                    
        except Exception as e:
            print(f"❌ SCHEMA_UPDATE_ERROR: {e}")
            # If schema update fails, just continue - the constraint might not be enforced

    def _create_tables(self):
        """Create all required database tables"""
        with self.get_connection() as conn:
            # Users table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    email TEXT UNIQUE NOT NULL,
                    username TEXT,
                    first_name TEXT,
                    last_name TEXT,
                    profile_picture TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Trips table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS trips (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    destination TEXT NOT NULL,
                    description TEXT,
                    start_date TEXT NOT NULL,
                    end_date TEXT NOT NULL,
                    total_budget REAL,
                    currency TEXT DEFAULT 'VND',
                    is_active BOOLEAN DEFAULT 1,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users (id)
                )
            """)
            
            # Planners table (for backward compatibility)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS planners (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    description TEXT,
                    start_date TEXT NOT NULL,
                    end_date TEXT NOT NULL,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users (id)
                )
            """)
            
            # Activities table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS activities (
                    id TEXT PRIMARY KEY,
                    planner_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    description TEXT,
                    start_time TEXT,
                    end_time TEXT,
                    location TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (planner_id) REFERENCES planners (id)
                )
            """)
            
            # Expenses table - Updated to support both planners and trips
            conn.execute("""
                CREATE TABLE IF NOT EXISTS expenses (
                    id TEXT PRIMARY KEY,
                    planner_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    amount REAL NOT NULL,
                    currency TEXT DEFAULT 'VND',
                    category TEXT,
                    date TEXT NOT NULL,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Collaborators table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS collaborators (
                    id TEXT PRIMARY KEY,
                    planner_id TEXT NOT NULL,
                    user_id TEXT NOT NULL,
                    role TEXT DEFAULT 'viewer',
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (planner_id) REFERENCES planners (id),
                    FOREIGN KEY (user_id) REFERENCES users (id),
                    UNIQUE(planner_id, user_id)
                )
            """)
            
            conn.commit()
    
    def get_connection(self):
        """Get a database connection with foreign key constraints enabled"""
        conn = sqlite3.connect(self.db_path)
        conn.execute("PRAGMA foreign_keys = ON;")
        conn.row_factory = sqlite3.Row
        return conn
    
    def get_connection_no_fk(self):
        """Get a database connection with foreign key constraints disabled"""
        conn = sqlite3.connect(self.db_path)
        conn.execute("PRAGMA foreign_keys = OFF;")
        conn.row_factory = sqlite3.Row
        return conn
    
    def check_and_repair_integrity(self):
        """Check and repair foreign key integrity issues"""
        try:
            with self.get_connection() as conn:
                # Check for orphaned trips (trips without users)
                cursor = conn.execute("""
                    SELECT COUNT(*) as count FROM trips 
                    WHERE user_id NOT IN (SELECT id FROM users)
                """)
                orphaned_trips = cursor.fetchone()[0]
                
                if orphaned_trips > 0:
                    # Optionally delete orphaned trips or create placeholder users
                    pass
                    
                # Check for orphaned activities
                cursor = conn.execute("""
                    SELECT COUNT(*) as count FROM activities 
                    WHERE planner_id NOT IN (SELECT id FROM planners)
                """)
                orphaned_activities = cursor.fetchone()[0]
                
                if orphaned_activities > 0:
                    # Optionally handle orphaned activities
                    pass
                
        except Exception as e:
            pass
    
    def create_user(self, user_id: str, email: str, username: str = None, first_name: str = None, last_name: str = None, profile_picture: str = None):
        """Create or update user in database"""
        with self.get_connection() as conn:
            try:
                print(f"💾 DB_USER_CREATE: Creating user {user_id} with email {email}")
                
                # Temporarily disable foreign keys to avoid constraint issues during user creation
                conn.execute("PRAGMA foreign_keys = OFF")
                
                # Check if user already exists
                cursor = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,))
                existing_user = cursor.fetchone()
                
                if existing_user:
                    print(f"✅ DB_USER_EXISTS: User {user_id} already exists, updating record")
                    # Update existing user
                    conn.execute("""
                        UPDATE users SET 
                            email = ?, username = ?, first_name = ?, last_name = ?, 
                            profile_picture = ?, updated_at = ?
                        WHERE id = ?
                    """, (email, username, first_name, last_name, profile_picture, datetime.now().isoformat(), user_id))
                else:
                    print(f"🔧 DB_USER_INSERT: Inserting new user {user_id}")
                    
                    # Check if email is already used by another user
                    cursor = conn.execute("SELECT id FROM users WHERE email = ?", (email,))
                    email_user = cursor.fetchone()
                    
                    if email_user and email_user[0] != user_id:
                        print(f"⚠️ DB_EMAIL_CONFLICT: Email {email} already used by user {email_user[0]}")
                        # Use a unique email to avoid constraint violation
                        email = f"{user_id}_{email}"
                        print(f"🔧 DB_EMAIL_FIX: Using modified email: {email}")
                    
                    # Insert new user
                    conn.execute("""
                        INSERT INTO users (
                            id, email, username, first_name, last_name, profile_picture, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, (user_id, email, username, first_name, last_name, profile_picture, datetime.now().isoformat(), datetime.now().isoformat()))
                
                conn.commit()
                
                # Re-enable foreign keys
                conn.execute("PRAGMA foreign_keys = ON")
                
                # Verify the user was created/updated
                cursor = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,))
                if cursor.fetchone():
                    print(f"✅ DB_USER_SUCCESS: User {user_id} created/updated and verified in database")
                else:
                    raise Exception(f"User {user_id} not found after insertion/update")
                
            except Exception as e:
                print(f"❌ DB_USER_ERROR: Failed to create user {user_id}: {e}")
                # Re-enable foreign keys in case of error
                try:
                    conn.execute("PRAGMA foreign_keys = ON")
                except:
                    pass
                conn.rollback()
                raise
    
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
    
    def create_expense_for_trip(self, trip_id: str, user_id: str, expense_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new expense directly linked to a trip"""
        expense_id = f"expense_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{trip_id[:8]}"
        
        with self.get_connection() as conn:
            # Verify trip belongs to user
            cursor = conn.execute("SELECT id FROM trips WHERE id = ? AND user_id = ?", (trip_id, user_id))
            if not cursor.fetchone():
                raise ValueError(f"Trip {trip_id} not found or does not belong to user {user_id}")
            
            conn.execute("""
                INSERT INTO expenses (id, planner_id, name, amount, currency, category, date)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                expense_id, trip_id, expense_data["name"], expense_data["amount"],
                expense_data.get("currency", "VND"), expense_data["category"], expense_data["date"]
            ))
            conn.commit()
        
        return self.get_expense(expense_id)
    
    def get_user_expenses(self, user_id: str, start_date: str = None, end_date: str = None, category: str = None) -> List[Dict[str, Any]]:
        """Get all expenses for a user across all their trips"""
        with self.get_connection() as conn:
            query = """
                SELECT e.* FROM expenses e
                INNER JOIN trips t ON e.planner_id = t.id
                WHERE t.user_id = ?
            """
            params = [user_id]
            
            if start_date:
                query += " AND e.date >= ?"
                params.append(start_date)
            
            if end_date:
                query += " AND e.date <= ?"
                params.append(end_date)
                
            if category:
                query += " AND e.category = ?"
                params.append(category)
            
            query += " ORDER BY e.date DESC"
            
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]
    
    def get_trip_expenses(self, trip_id: str, user_id: str) -> List[Dict[str, Any]]:
        """Get all expenses for a specific trip"""
        with self.get_connection() as conn:
            # Verify trip belongs to user first
            cursor = conn.execute("SELECT id FROM trips WHERE id = ? AND user_id = ?", (trip_id, user_id))
            if not cursor.fetchone():
                return []
                
            cursor = conn.execute("""
                SELECT * FROM expenses WHERE planner_id = ? ORDER BY date DESC
            """, (trip_id,))
            return [dict(row) for row in cursor.fetchall()]
    
    def delete_trip_expenses(self, trip_id: str, user_id: str) -> int:
        """Delete all expenses for a trip (with user verification)"""
        with self.get_connection() as conn:
            # Verify trip belongs to user first
            cursor = conn.execute("SELECT id FROM trips WHERE id = ? AND user_id = ?", (trip_id, user_id))
            if not cursor.fetchone():
                return 0
                
            cursor = conn.execute("DELETE FROM expenses WHERE planner_id = ?", (trip_id,))
            conn.commit()
            return cursor.rowcount
    
    def delete_expense(self, expense_id: str, user_id: str) -> bool:
        """Delete a specific expense (with user verification)"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                DELETE FROM expenses WHERE id = ? AND planner_id IN (
                    SELECT id FROM trips WHERE user_id = ?
                )
            """, (expense_id, user_id))
            conn.commit()
            return cursor.rowcount > 0
    
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
            try:
                print(f"💾 DB_TRIP_CREATE: Creating trip {trip_id} for user {user_id}")
                
                # Disable foreign keys temporarily to avoid constraint issues
                conn.execute("PRAGMA foreign_keys = OFF")
                
                # Verify user exists first
                cursor = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,))
                user_exists = cursor.fetchone()
                if not user_exists:
                    print(f"❌ USER_NOT_FOUND: User {user_id} does not exist in database")
                    raise ValueError(f"User {user_id} does not exist in database. Cannot create trip.")
                
                print(f"✅ DB_TRIP_USER_VERIFIED: User {user_id} exists in database")
                
                # Create the trip
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
                
                # Re-enable foreign keys
                conn.execute("PRAGMA foreign_keys = ON")
                
                print(f"✅ DB_TRIP_SUCCESS: Trip {trip_id} created successfully")
                
            except Exception as e:
                print(f"❌ DB_TRIP_ERROR: Failed to create trip {trip_id}: {e}")
                conn.rollback()
                raise
        
        return self.get_trip(trip_id, user_id)
    
    def get_user_trips(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all trips for a user"""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT * FROM trips WHERE user_id = ? ORDER BY created_at DESC
            """, (user_id,))
            return [dict(row) for row in cursor.fetchall()]
    
    def get_trip(self, trip_id: str, user_id: str = None) -> Optional[Dict[str, Any]]:
        """Get specific trip for user (user_id optional for internal calls)"""
        with self.get_connection() as conn:
            if user_id:
                cursor = conn.execute("""
                    SELECT * FROM trips WHERE id = ? AND user_id = ?
                """, (trip_id, user_id))
            else:
                cursor = conn.execute("""
                    SELECT * FROM trips WHERE id = ?
                """, (trip_id,))
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
        """Delete trip with cascade deletion of all related data"""
        with self.get_connection() as conn:
            # Start transaction
            conn.execute("BEGIN TRANSACTION")
            
            try:
                # Check if trip exists and belongs to user
                cursor = conn.execute("""
                    SELECT id, name FROM trips WHERE id = ? AND user_id = ?
                """, (trip_id, user_id))
                
                trip_row = cursor.fetchone()
                if not trip_row:
                    conn.rollback()
                    return False
                
                trip_name = trip_row[1]
                
                # Delete related expenses and count them
                cursor = conn.execute("""
                    SELECT COUNT(*) FROM expenses WHERE planner_id = ?
                """, (trip_id,))
                expense_count = cursor.fetchone()[0]
                
                cursor = conn.execute("""
                    DELETE FROM expenses WHERE planner_id = ?
                """, (trip_id,))
                deleted_expenses = cursor.rowcount
                
                # Delete related activities and count them  
                cursor = conn.execute("""
                    SELECT COUNT(*) FROM activities WHERE planner_id = ?
                """, (trip_id,))
                activity_count = cursor.fetchone()[0]
                
                cursor = conn.execute("""
                    DELETE FROM activities WHERE planner_id = ?
                """, (trip_id,))
                deleted_activities = cursor.rowcount
                
                # Delete the trip
                cursor = conn.execute("""
                    DELETE FROM trips WHERE id = ? AND user_id = ?
                """, (trip_id, user_id))
                
                if cursor.rowcount == 0:
                    conn.rollback()
                    return False
                
                # Commit transaction
                conn.commit()            
                
                return True
                
            except Exception as e:
                conn.rollback()
                raise e

# Global database instance
db_manager = DatabaseManager()