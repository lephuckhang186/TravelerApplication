"""
TravelPro Backend API Main Application
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import time
import logging
import os
from dotenv import load_dotenv

# Travel-agent environment is loaded in the travel_agent endpoint module

# Handle both relative and absolute imports
try:
    from .api.endpoints import expenses, auth, activities
    from .core.config import get_settings
except ImportError:
    # Fallback for direct execution or ASGI
    import sys
    import os
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from api.endpoints import expenses, auth, activities
    from core.config import get_settings

# Import travel_agent
try:
    from .api.endpoints import travel_agent
    print("Successfully imported travel_agent from relative import")
except ImportError:
    try:
        from api.endpoints import travel_agent
        print("Successfully imported travel_agent from absolute import")
    except ImportError as e:
        print(f"Warning: Could not import travel_agent endpoint: {e}")
        travel_agent = None

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()

# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="Advanced Travel Expense Management API with Firebase Authentication",
    version=settings.APP_VERSION,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# ============= MIDDLEWARE =============

# CORS middleware - Enhanced configuration for Flutter/Web app support
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS if not settings.DEBUG else ["*"],  # Allow all origins in debug mode
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"],
    allow_headers=[
        "Accept",
        "Accept-Language",
        "Content-Language", 
        "Content-Type",
        "Authorization",
        "X-Requested-With",
        "X-CSRFToken",
        "X-Process-Time",
        "Origin",
        "Cache-Control",
        "Pragma"
    ],
    expose_headers=["X-Process-Time"],
    max_age=3600,  # Cache preflight requests for 1 hour
)

# Trusted host middleware (security)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.ALLOWED_HOSTS
)

# CORS preflight middleware - Handle OPTIONS requests before authentication
@app.middleware("http") 
async def cors_preflight_handler(request: Request, call_next):
    """Handle CORS preflight OPTIONS requests"""
    if request.method == "OPTIONS":
        response = JSONResponse(content={}, status_code=200)
        # Set CORS headers for preflight response
        origin = request.headers.get("origin")
        if settings.DEBUG or not origin or origin in settings.CORS_ORIGINS:
            response.headers["Access-Control-Allow-Origin"] = origin or "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD"
            response.headers["Access-Control-Allow-Headers"] = "Accept, Accept-Language, Content-Language, Content-Type, Authorization, X-Requested-With, X-CSRFToken, Origin, Cache-Control, Pragma"
            response.headers["Access-Control-Allow-Credentials"] = "true"
            response.headers["Access-Control-Max-Age"] = "3600"
        return response
    
    return await call_next(request)

# Request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """Add processing time to response headers"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# Error handling middleware
@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=404,
        content={
            "error": "Not Found",
            "message": "The requested resource was not found",
            "path": str(request.url.path)
        }
    )

@app.exception_handler(500)
async def internal_error_handler(request: Request, exc):
    logger.error(f"Internal server error: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error", 
            "message": "An unexpected error occurred",
            "path": str(request.url.path)
        }
    )

# ============= ROUTES =============

# Include API routers
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(expenses.router, prefix=settings.API_V1_STR)
app.include_router(activities.router, prefix=settings.API_V1_STR)
if travel_agent:
    app.include_router(travel_agent.router, prefix=settings.API_V1_STR)
    logger.info("Travel agent endpoints enabled")
else:
    logger.warning("Travel agent endpoints disabled due to import errors")

# ============= ROOT ENDPOINTS =============

@app.get("/")
async def root():
    """API root endpoint"""
    return {
        "message": "TravelPro Backend API",
        "version": settings.APP_VERSION,
        "status": "running",
        "features": [
            "Firebase Authentication",
            "Google OAuth Integration", 
            "Expense Management",
            "Activities Management",
            "Budget Analytics",
            "Multi-currency Support",
            "AI Travel Agent"
        ],
        "endpoints": {
            "docs": "/docs" if settings.DEBUG else "disabled",
            "auth": f"{settings.API_V1_STR}/auth",
            "expenses": f"{settings.API_V1_STR}/expenses",
            "activities": f"{settings.API_V1_STR}/activities",
            "travel-agent": f"{settings.API_V1_STR}/travel-agent"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "travelpro-backend",
        "version": settings.APP_VERSION,
        "timestamp": time.time(),
        "debug_mode": settings.DEBUG
    }

@app.get("/version")
async def get_version():
    """Get API version information"""
    return {
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "api_version": settings.API_V1_STR
    }

# ============= STARTUP/SHUTDOWN EVENTS =============

@app.on_event("startup")
async def startup_event():
    """Application startup tasks"""
    logger.info("TravelPro Backend API is starting up...")
    logger.info(f"Debug mode: {settings.DEBUG}")
    logger.info(f"Firebase integration enabled")
    logger.info(f"API available at: {settings.API_V1_STR}")

@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown tasks"""
    logger.info("TravelPro Backend API is shutting down...")

# ============= DEVELOPMENT HELPERS =============

if settings.DEBUG:
    @app.get("/debug/routes")
    async def debug_routes():
        """Debug endpoint to list all routes (dev only)"""
        routes = []
        for route in app.routes:
            if hasattr(route, 'methods'):
                routes.append({
                    "path": route.path,
                    "methods": list(route.methods),
                    "name": route.name
                })
        return {"routes": routes}
    
    @app.get("/debug/settings")
    async def debug_settings():
        """Debug endpoint to show non-sensitive settings (dev only)"""
        safe_settings = {
            "APP_NAME": settings.APP_NAME,
            "APP_VERSION": settings.APP_VERSION,
            "DEBUG": settings.DEBUG,
            "API_V1_STR": settings.API_V1_STR,
            "CORS_ORIGINS": settings.CORS_ORIGINS,
            "ACCESS_TOKEN_EXPIRE_MINUTES": settings.ACCESS_TOKEN_EXPIRE_MINUTES
        }
        return {"settings": safe_settings}

# ============= MAIN =============

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        app,  # Pass the app directly instead of string reference
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )