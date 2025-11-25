"""
API endpoints package
"""

# Import all endpoint modules
from . import auth
from . import expenses
from . import activities

# Import travel_agent endpoint
try:
    from . import travel_agent
    __all__ = ["auth", "expenses", "activities", "travel_agent"]
except ImportError as e:
    print(f"Warning: Could not import travel_agent endpoint: {e}")
    __all__ = ["auth", "expenses", "activities"]