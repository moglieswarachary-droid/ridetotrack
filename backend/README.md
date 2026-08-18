# RideTrack Backend

FastAPI asynchronous backend for RideTrack — smartphone-only motorcycle GPS and sensor tracking pipeline.

## Features
- **High-Rate GNSS/Sensor Pipeline**: Sub-second GPS ingestion, Kalman drift filtering, accuracy gating.
- **Fast Ride Finalization**: Polyline compression, elevation profile analysis, speed distribution.
- **Live Ephemeral Tracking**: Zero-auth share links, real-time Leaflet map viewer, live WebSocket broadcasts.
- **Parking Memory & Security**: Auto-park detection, compass bearing retrieval, geofence breach alerting.
- **Crash Detection & Emergency**: High-G impact detection, 30-second cancellation countdown, emergency SMS/WhatsApp dispatch.
- **Dual Database Support**: SQLite (local development) and PostgreSQL with PostGIS (production).
- **Redis State Store**: Real-time location pub/sub with resilient in-memory fallback.

## Quick Start (Local)
```bash
uv venv
source .venv/bin/activate  # Or .venv\Scripts\activate on Windows
uv pip install -e .
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Production Deployment (Docker Compose)
```bash
docker compose up -d
```
The API is served at `http://localhost:8000`, docs at `http://localhost:8000/docs`, and live share viewer at `http://localhost:8000/live/{share_token}`.
