import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.database import init_db
from app.core.redis_client import state_store
from app.api.v1 import api_router
from app.api.v1.websocket import router as websocket_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Initializing RideTrack database schema...")
    await init_db()
    logger.info("Connecting to Redis state store...")
    await state_store.connect()
    yield
    # Shutdown
    logger.info("Disconnecting Redis state store...")
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

# CORS configuration - Allow configured origins (supports "*" wildcard or specific domains)
allow_all = "*" in settings.CORS_ORIGINS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if allow_all else settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API routers under prefix (e.g., /api/v1)
app.include_router(api_router, prefix=settings.API_V1_STR)

# Also mount direct WebSocket routes at root /ws for flexible reverse proxy routing
app.include_router(websocket_router)


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


# Resolve web_viewer static files from multiple candidate deployment paths
candidate_dirs = [
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "web_viewer")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "web_viewer")),
    os.path.abspath(os.path.join(os.getcwd(), "web_viewer")),
    "/app/web_viewer",
    "/app/backend/web_viewer",
]

viewer_dir = None
for c in candidate_dirs:
    if os.path.exists(c) and os.path.exists(os.path.join(c, "index.html")):
        viewer_dir = c
        logger.info(f"Web viewer mounted from: {viewer_dir}")
        break

if viewer_dir and os.path.exists(viewer_dir):
    app.mount("/static", StaticFiles(directory=viewer_dir), name="static")

    @app.get("/live/{share_token}", response_class=HTMLResponse, tags=["Live Ride Sharing"])
    async def serve_live_viewer(share_token: str):
        """Serve the high-contrast standalone Leaflet live tracking map interface."""
        index_file = os.path.join(viewer_dir, "index.html")
        if os.path.exists(index_file):
            return FileResponse(index_file)
        return HTMLResponse("<h3>RideTrack Live Viewer is initializing...</h3>")
else:
    @app.get("/live/{share_token}", response_class=HTMLResponse, tags=["Live Ride Sharing"])
    async def serve_live_viewer_fallback(share_token: str):
        """Fallback live viewer page when static assets directory is not found."""
        return HTMLResponse(
            f"<!DOCTYPE html><html><head><title>RideTrack • Live Tracker</title>"
            f"<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
            f"<style>body{{margin:0;padding:40px;background:#0A0D14;color:#FFF;font-family:sans-serif;text-align:center;}}"
            f"h1{{color:#00E5FF;}}code{{color:#00E676;background:#121620;padding:4px 8px;border-radius:6px;}}</style></head>"
            f"<body><h1>RideTrack Live Tracking Feed</h1>"
            f"<p>Connected to live ride session token: <code>{share_token}</code></p>"
            f"<p style='color:#8E9BAE;'>Initializing map telemetry display...</p></body></html>"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=True)
