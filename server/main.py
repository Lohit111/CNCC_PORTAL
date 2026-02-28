"""Main FastAPI Application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from firebase_admin import credentials, initialize_app, get_app
from models.user import Base
from config.database import engine
from api.router import api_router
import logging
import os


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event handler for startup and shutdown"""
    # Startup
    logger.info("Starting application...")

    # Initialize Firebase
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
    if not cred_path:
        raise ValueError(
            "FIREBASE_CREDENTIALS_PATH environment variable is not set")

    cred = credentials.Certificate(cred_path)
    try:
        get_app()
        logger.info("Firebase already initialized")
    except ValueError:
        initialize_app(cred)
        logger.info("Firebase initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {str(e)}")
        raise

    # Create database tables
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created")
    except Exception as e:
        logger.error(f"Failed to create database tables: {e}")

    logger.info("Application started successfully")

    yield

    # Shutdown
    logger.info("Shutting down application...")


# Create FastAPI app
app = FastAPI(
    description="Production-ready role-based ticket and equipment management system",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Ticket Management System API",
        "version": "1.0.0",
        "docs": "/api/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


# Include API router
app.include_router(api_router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
