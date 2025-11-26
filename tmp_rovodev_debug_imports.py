#!/usr/bin/env python3
"""
Debug script to test travel-agent imports step by step
"""
import sys
import os

# Add travel-agent path
travel_agent_path = os.path.join(os.path.dirname(__file__), 'travel-agent')
print(f"Travel agent path: {travel_agent_path}")
print(f"Path exists: {os.path.exists(travel_agent_path)}")

if os.path.exists(travel_agent_path):
    sys.path.insert(0, travel_agent_path)
    print(f"Added to sys.path: {travel_agent_path}")

# Load environment
from dotenv import load_dotenv
backend_env = os.path.join('Backend', 'travel_agent.env')
if os.path.exists(backend_env):
    load_dotenv(backend_env)
    print(f"Loaded Backend env: {backend_env}")

travel_env = os.path.join(travel_agent_path, '.env')
if os.path.exists(travel_env):
    load_dotenv(travel_env, override=False)
    print(f"Loaded travel-agent env: {travel_env}")

# Test imports one by one
print("\n=== Testing imports ===")

try:
    print("1. Testing workflow import...")
    from workflow import app as travel_workflow
    print("✓ Workflow imported successfully")
except Exception as e:
    print(f"❌ Workflow import failed: {e}")
    import traceback
    traceback.print_exc()

try:
    print("\n2. Testing models import with importlib...")
    import importlib.util
    travel_agent_models_path = os.path.join(travel_agent_path, 'models.py')
    print(f"Models path: {travel_agent_models_path}")
    print(f"Models file exists: {os.path.exists(travel_agent_models_path)}")
    
    spec = importlib.util.spec_from_file_location("travel_agent_models", travel_agent_models_path)
    travel_agent_models = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(travel_agent_models)
    
    WorkflowState = travel_agent_models.WorkflowState
    print("✓ Models imported successfully")
    print(f"✓ WorkflowState class: {WorkflowState}")
except Exception as e:
    print(f"❌ Models import failed: {e}")
    import traceback
    traceback.print_exc()

try:
    print("\n3. Testing langchain import...")
    from langchain_core.messages import HumanMessage, AIMessage
    print("✓ Langchain imported successfully")
except Exception as e:
    print(f"❌ Langchain import failed: {e}")
    import traceback
    traceback.print_exc()

try:
    print("\n4. Testing greeting_handler import...")
    from services.greeting_handler import greeting_handler
    print("✓ Greeting handler imported successfully")
except Exception as e:
    print(f"❌ Greeting handler import failed: {e}")
    import traceback
    traceback.print_exc()

print("\n=== Import test completed ===")