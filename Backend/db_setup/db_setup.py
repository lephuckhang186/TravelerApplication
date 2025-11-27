import os
import psycopg2
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv(dotenv_path='./Backend/db_setup/.env')

def drop_tables():
    """Drop all tables in the correct order."""
    conn = None
    try:
        result = urlparse(os.getenv("DATABASE_URL"))
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port
        conn = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=hostname,
            port=port
        )
        cur = conn.cursor()
        cur.execute("DROP TABLE IF EXISTS collaborators, bookings, expenses, activities, planners, users CASCADE;")
        conn.commit()
        cur.close()
        print("All tables dropped successfully.")
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()


def create_users_table():
    """Create the users table in the PostgreSQL database."""
    conn = None
    try:
        result = urlparse(os.getenv("DATABASE_URL"))
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port
        conn = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=hostname,
            port=port
        )
        cur = conn.cursor()
        cur.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto;")
        cur.execute("""
            CREATE TABLE users (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                email VARCHAR(255) UNIQUE NOT NULL,
                username VARCHAR(50) UNIQUE NOT NULL,
                hashed_password VARCHAR(255) NOT NULL,
                first_name VARCHAR(50),
                last_name VARCHAR(50),
                profile_picture VARCHAR(255),
                is_active BOOLEAN DEFAULT TRUE,
                is_admin BOOLEAN DEFAULT FALSE,
                is_verified BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMPTZ DEFAULT NOW(),
                updated_at TIMESTAMPTZ DEFAULT NOW(),
                last_login TIMESTAMPTZ,
                preferred_currency VARCHAR(10) DEFAULT 'VND',
                preferred_language VARCHAR(10) DEFAULT 'en',
                time_zone VARCHAR(50) DEFAULT 'UTC',
                travel_preferences JSONB
            )
        """)
        conn.commit()
        cur.close()
        print("Users table created successfully.")
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

def create_planners_table():
    """Create the planners table in the PostgreSQL database."""
    conn = None
    try:
        result = urlparse(os.getenv("DATABASE_URL"))
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port
        conn = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=hostname,
            port=port
        )
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE planners (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                name VARCHAR(100) NOT NULL,
                description TEXT,
                start_date DATE NOT NULL,
                end_date DATE NOT NULL
            )
        """)
        conn.commit()
        cur.close()
        print("Planners table created successfully.")
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

def create_activities_table():
    """Create the activities table in the PostgreSQL database."""
    conn = None
    try:
        result = urlparse(os.getenv("DATABASE_URL"))
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port
        conn = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=hostname,
            port=port
        )
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE activities (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                planner_id UUID REFERENCES planners(id) ON DELETE CASCADE,
                name VARCHAR(100) NOT NULL,
                description TEXT,
                start_time TIMESTAMPTZ NOT NULL,
                end_time TIMESTAMPTZ NOT NULL,
                location VARCHAR(255)
            )
        """)
        conn.commit()
        cur.close()
        print("Activities table created successfully.")
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

def create_expenses_table():
    """Create the expenses table in the PostgreSQL database."""
    conn = None
    try:
        result = urlparse(os.getenv("DATABASE_URL"))
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port
        conn = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=hostname,
            port=port
        )
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE expenses (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                planner_id UUID REFERENCES planners(id) ON DELETE CASCADE,
                name VARCHAR(100) NOT NULL,
                amount FLOAT NOT NULL,
                currency VARCHAR(10) NOT NULL,
                category VARCHAR(50) NOT NULL,
                date DATE NOT NULL
            )
        """)
        conn.commit()
        cur.close()
        print("Expenses table created successfully.")
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()


def create_collaborators_table():
    """Create the collaborators table in the PostgreSQL database."""
    conn = None
    try:
        result = urlparse(os.getenv("DATABASE_URL"))
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port
        conn = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=hostname,
            port=port
        )
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE collaborators (
                user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                planner_id UUID REFERENCES planners(id) ON DELETE CASCADE,
                PRIMARY KEY (user_id, planner_id)
            )
        """)
        conn.commit()
        cur.close()
        print("Collaborators table created successfully.")
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

if __name__ == '__main__':
    drop_tables()
    create_users_table()
    create_planners_table()
    create_activities_table()
    create_expenses_table()
    create_collaborators_table()
