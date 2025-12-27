"""
Main entry point for the FastAPI application
Run this file to start the backend server
"""
import uvicorn
import firebase_admin
from firebase_admin import credentials

# Initialize Firebase Admin SDK
cred = credentials.Certificate('Backend/service-account.json')
firebase_admin.initialize_app(cred)

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )