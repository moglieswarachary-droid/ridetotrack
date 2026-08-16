from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.tracking_session import TrackingSession
from app.models.location_point import LocationPoint
from app.schemas.tracking import (
    TrackingStartRequest,
    TrackingSessionResponse,
    LiveTelemetryResponse,
)
from app.schemas.location import LocationBatchIngest, LocationPointCreate
from app.schemas.ride import RideSummaryResponse
from app.services.tracking_service import (
    start_tracking_session,
    ingest_location_points,
    pause_tracking_session,
    resume_tracking_session,
    stop_and_finalize_ride,
)
from app.core.redis_client import state_store
from app.core.audit import record_audit_log

router = APIRouter(prefix="/tracking", tags=["Tracking Core"])


@router.post("/start", response_model=TrackingSessionResponse, status_code=status.HTTP_201_CREATED)
async def start_ride(
    request: TrackingStartRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Start a new motorcycle tracking session using smartphone sensors."""
    session = await start_tracking_session(
        db=db,
        user_id=current_user.id,
        bike_id=request.bike_id,
        tracking_mode=request.tracking_mode or "balanced",
        battery_pct=request.battery_pct
    )
    await record_audit_log(
        db,
        action="RIDE_STARTED",
        user_id=current_user.id,
        details={"session_id": session.id, "bike_id": session.bike_id}
    )
    return session


@router.get("/active", response_model=Optional[TrackingSessionResponse])
async def get_active_ride(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Check if the rider has an active or paused ride session."""
    result = await db.execute(
        select(TrackingSession)
        .where(
            TrackingSession.user_id == current_user.id,
            TrackingSession.status.in_(["active", "paused"])
        )
        .order_by(TrackingSession.started_at.desc())
    )
    return result.scalars().first()


@router.post("/{session_id}/locations")
async def send_location_batch(
    session_id: str,
    payload: LocationBatchIngest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Ingest a batch of GPS and sensor location points from smartphone."""
    res = await ingest_location_points(
        db=db,
        session_id=session_id,
        user_id=current_user.id,
        points_data=payload.points
    )
    return res


@router.post("/{session_id}/pause", response_model=TrackingSessionResponse)
async def pause_ride(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Pause ride tracking during stops/breaks."""
    session = await pause_tracking_session(db, session_id, current_user.id)
    return session


@router.post("/{session_id}/resume", response_model=TrackingSessionResponse)
async def resume_ride(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Resume ride tracking."""
    session = await resume_tracking_session(db, session_id, current_user.id)
    return session


@router.post("/{session_id}/stop", response_model=RideSummaryResponse)
async def stop_ride(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Stop tracking session, compute full ride telemetry metrics, and finalize trip."""
    ride = await stop_and_finalize_ride(db, session_id, current_user.id)
    await record_audit_log(
        db,
        action="RIDE_STOPPED",
        user_id=current_user.id,
        details={"session_id": session_id, "ride_id": ride.id, "distance_km": ride.total_distance_km}
    )
    return ride


@router.get("/{session_id}/live", response_model=LiveTelemetryResponse)
async def get_live_telemetry(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Fetch instantaneous live telemetry for an active ride."""
    session_res = await db.execute(
        select(TrackingSession)
        .options(selectinload(TrackingSession.bike))
        .where(TrackingSession.id == session_id, TrackingSession.user_id == current_user.id)
    )
    session = session_res.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    cached = await state_store.get_live_point(session_id)
    
    # Calculate live distance so far
    points_res = await db.execute(
        select(LocationPoint)
        .where(LocationPoint.session_id == session_id)
        .order_by(LocationPoint.timestamp.asc())
    )
    points = points_res.scalars().all()

    dist_km = 0.0
    speeds = [p.speed_kmh for p in points if p.speed_kmh > 0]
    max_spd = max((p.speed_kmh for p in points), default=0.0)
    avg_spd = sum(speeds) / len(speeds) if speeds else 0.0

    from app.utils.geo import haversine_distance_meters
    for i in range(1, len(points)):
        dist_km += haversine_distance_meters(
            points[i-1].latitude, points[i-1].longitude,
            points[i].latitude, points[i].longitude
        ) / 1000.0

    from datetime import datetime, timezone
    now_utc = datetime.now(timezone.utc)
    started_at = session.started_at
    if started_at and started_at.tzinfo is None:
        started_at = started_at.replace(tzinfo=timezone.utc)
    dur_sec = int((now_utc - started_at).total_seconds()) if started_at else 0

    latest_pt = points[-1] if points else None

    lat = cached.get("latitude", latest_pt.latitude if latest_pt else 0.0) if cached else (latest_pt.latitude if latest_pt else 0.0)
    lng = cached.get("longitude", latest_pt.longitude if latest_pt else 0.0) if cached else (latest_pt.longitude if latest_pt else 0.0)
    speed = cached.get("speed_kmh", latest_pt.speed_kmh if latest_pt else 0.0) if cached else (latest_pt.speed_kmh if latest_pt else 0.0)

    return LiveTelemetryResponse(
        session_id=session.id,
        bike_id=session.bike_id,
        bike_name=session.bike.name if session.bike else "Motorcycle",
        status=session.status,
        latitude=lat,
        longitude=lng,
        speed_kmh=speed,
        heading=cached.get("heading") if cached else (latest_pt.heading if latest_pt else None),
        altitude=cached.get("altitude") if cached else (latest_pt.altitude if latest_pt else None),
        accuracy_m=cached.get("accuracy_m") if cached else (latest_pt.accuracy_m if latest_pt else None),
        battery_pct=session.battery_current_pct,
        distance_km=round(dist_km, 2),
        duration_seconds=dur_sec,
        avg_speed_kmh=round(avg_spd, 1),
        max_speed_kmh=round(max_spd, 1),
        updated_at=now_utc,
    )
