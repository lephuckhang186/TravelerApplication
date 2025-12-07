"""
Configuration settings for TravelPro backend
"""
import os
from typing import Optional
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings"""
    
    # App configuration
    APP_NAME: str = "TravelPro Backend API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-super-secret-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Database
    DATABASE_URL: Optional[str] = os.getenv("DATABASE_URL")
    
    # Firebase Configuration
    FIREBASE_SERVICE_ACCOUNT_PATH: Optional[str] = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    FIREBASE_SERVICE_ACCOUNT_KEY: Optional[str] = os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY")
    FIREBASE_PROJECT_ID: Optional[str] = os.getenv("FIREBASE_PROJECT_ID")
    FIREBASE_PROJECT_NUMBER: Optional[str] = os.getenv("FIREBASE_PROJECT_NUMBER")
    FIREBASE_STORAGE_BUCKET: Optional[str] = os.getenv("FIREBASE_STORAGE_BUCKET")
    FIREBASE_API_KEY: Optional[str] = os.getenv("FIREBASE_API_KEY")
    
    # Google OAuth Configuration  
    GOOGLE_CLIENT_ID: Optional[str] = os.getenv("GOOGLE_CLIENT_ID")
    GOOGLE_CLIENT_SECRET: Optional[str] = os.getenv("GOOGLE_CLIENT_SECRET")
    
    # CORS settings
    ALLOWED_HOSTS: list = ["*"]
    CORS_ORIGINS: list = [
        "http://localhost:3000",
        "http://localhost:8080", 
        "http://localhost:8000",
        "http://localhost:8001",
        "http://localhost:4200",
        "http://localhost:5000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8001",
        "http://127.0.0.1:4200",
        "http://127.0.0.1:5000",
        "https://your-frontend-domain.com"
    ]
    
    # API Configuration
    API_V1_STR: str = "/api/v1"
    
    # File upload settings
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_FILE_TYPES: list = ["image/jpeg", "image/png", "image/gif", "application/pdf"]
    
    # Email settings (if needed)
    SMTP_HOST: Optional[str] = os.getenv("SMTP_HOST")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: Optional[str] = os.getenv("SMTP_USER")
    SMTP_PASSWORD: Optional[str] = os.getenv("SMTP_PASSWORD")
    
    # Redis settings (for caching)
    REDIS_URL: Optional[str] = os.getenv("REDIS_URL", "redis://localhost:6379")
    
    # Weather API settings
    WEATHER_API_KEY: Optional[str] = os.getenv("WEATHER_API_KEY")
    
    # Development flags
    ENABLE_DOCS: bool = os.getenv("ENABLE_DOCS", "true").lower() == "true"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

def get_settings() -> Settings:
    """Get application settings"""
    return Settings()

# Global settings instance
settings = get_settings()