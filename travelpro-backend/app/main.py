"""
TravelPro Backend API Main Application
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import time
import logging

from .api.endpoints import expenses, auth
from .core.config import get_settings

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

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Trusted host middleware (security)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.ALLOWED_HOSTS
)

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
            "Budget Analytics",
            "Multi-currency Support"
        ],
        "endpoints": {
            "docs": "/docs" if settings.DEBUG else "disabled",
            "auth": f"{settings.API_V1_STR}/auth",
            "expenses": f"{settings.API_V1_STR}/expenses"
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
    logger.info("🚀 TravelPro Backend API is starting up...")
    logger.info(f"📊 Debug mode: {settings.DEBUG}")
    logger.info(f"🔥 Firebase integration enabled")
    logger.info(f"🌐 API available at: {settings.API_V1_STR}")

@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown tasks"""
    logger.info("🛑 TravelPro Backend API is shutting down...")

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
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )