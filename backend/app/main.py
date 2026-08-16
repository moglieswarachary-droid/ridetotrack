from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.core.config import settings
from app.core.database import init_db
from app.core.redis_client import state_store
from app.api.v1 import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    await state_store.connect()
    yield
    # Shutdown
    await state_store.disconnect()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=(
        "RideTrack Production API - Smartphone-Only Motorcycle/Bike Tracking System.\n\n"
        "Features: High-rate GPS and sensor ingestion, Kalman drift filtering, "
        "instant ride finalization with elevation & polyline compression, "
        "live WebSocket streaming, ephemeral public live sharing links, "
        "parking guard memory with compass bearing, geofencing breach alerts, "
        "motorcycle crash detection telemetry, and emergency SOS broadcasting."
    ),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API routers
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/health", tags=["Health & Readiness"])
async def health_check():
    """System health check endpoint for container orchestrators and load balancers."""
    return {
        "status": "healthy",
        "service": "RideTrack Backend",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "redis_connected": state_store.is_connected,
    }


@app.get("/ready", tags=["Health & Readiness"])
async def readiness_check():
    """System readiness check probe."""
    return {"status": "ready"}


# Mount standalone Web Live Viewer static files if folder exists
viewer_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "web_viewer"))
if os.path.exists(viewer_dir):
    app.mount("/static", StaticFiles(directory=viewer_dir), name="static")

    @app.get("/live/{share_token}", response_class=HTMLResponse, tags=["Live Ride Sharing"])
    async def serve_live_viewer(share_token: str):
        """Serve the high-contrast standalone Leaflet live tracking map interface."""
        index_file = os.path.join(viewer_dir, "index.html")
        if os.path.exists(index_file):
            return FileResponse(index_file)
        return HTMLResponse("<h3>RideTrack Live Viewer is initializing...</h3>")
