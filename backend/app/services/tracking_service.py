from datetime import datetime, timezone
from typing import List, Optional, Tuple, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from app.models.tracking_session import TrackingSession
from app.models.location_point import LocationPoint
from app.models.bike import Bike
from app.models.ride import Ride
from app.models.alert import Alert
from app.models.shared_session import SharedTrackingSession
from app.models.user import UserSettings
from app.schemas.location import LocationPointCreate
from app.utils.geo import (
    haversine_distance_meters,
    simplify_points_rdp,
    encode_polyline,
    points_to_geojson_linestring
)
from app.utils.filters import gps_filter
from app.services.geofence_service import check_geofences_for_point
from app.core.redis_client import state_store
from app.core.websocket_manager import ws_manager


async def start_tracking_session(
    db: AsyncSession,
    user_id: str,
    bike_id: Optional[str] = None,
    tracking_mode: str = "balanced",
    battery_pct: Optional[int] = None
) -> TrackingSession:
    # If bike_id not provided, find active bike for user
    if not bike_id:
        result = await db.execute(
            select(Bike).where(Bike.user_id == user_id, Bike.is_active == True)
        )
        active_bike = result.scalars().first()
        if not active_bike:
            # Fall back to first bike
            result = await db.execute(select(Bike).where(Bike.user_id == user_id))
            active_bike = result.scalars().first()
            if not active_bike:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please add a motorcycle to your garage before starting a ride."
                )
        bike_id = active_bike.id
    else:
        result = await db.execute(
            select(Bike).where(Bike.id == bike_id, Bike.user_id == user_id)
        )
        if not result.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Motorcycle not found."
            )

    # Check if there is already an active tracking session for this bike
    active_session_res = await db.execute(
        select(TrackingSession).where(
            TrackingSession.bike_id == bike_id,
            TrackingSession.status.in_(["active", "paused"])
        )
    )
    existing_session = active_session_res.scalars().first()
    if existing_session:
        return existing_session

    session = TrackingSession(
        user_id=user_id,
        bike_id=bike_id,
        status="active",
        tracking_mode=tracking_mode,
        battery_start_pct=battery_pct,
        battery_current_pct=battery_pct,
        started_at=datetime.now(timezone.utc),
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


async def ingest_location_points(
    db: AsyncSession,
    session_id: str,
    user_id: str,
    points_data: List[LocationPointCreate]
) -> Dict[str, Any]:
    # Validate session
    result = await db.execute(
        select(TrackingSession)
        .options(selectinload(TrackingSession.bike))
        .where(TrackingSession.id == session_id, TrackingSession.user_id == user_id)
    )
    session = result.scalars().first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tracking session not found."
        )

    if session.status != "active":
        return {"ingested_count": 0, "status": session.status, "message": "Session is not active."}

    # Fetch user overspeed settings
    settings_res = await db.execute(select(UserSettings).where(UserSettings.user_id == user_id))
    user_settings = settings_res.scalars().first()
    overspeed_limit = user_settings.overspeed_threshold_kmh if user_settings else 120.0

    # Fetch last known point for drift comparison
    last_pt_res = await db.execute(
        select(LocationPoint)
        .where(LocationPoint.session_id == session_id)
        .order_by(LocationPoint.timestamp.desc())
        .limit(1)
    )
    last_known_pt = last_pt_res.scalars().first()

    accepted_points: List[LocationPoint] = []
    last_lat = last_known_pt.latitude if last_known_pt else None
    last_lng = last_known_pt.longitude if last_known_pt else None
    last_time = last_known_pt.timestamp if last_known_pt else None

    for pt in points_data:
        pt_time = pt.timestamp or datetime.now(timezone.utc)
        if pt_time.tzinfo is None:
            pt_time = pt_time.replace(tzinfo=timezone.utc)

        time_delta = (pt_time - last_time).total_seconds() if last_time else None

        # Filter out GPS noise / teleportation jumps
        if not gps_filter.is_valid_point(
            lat=pt.latitude,
            lng=pt.longitude,
            accuracy_m=pt.accuracy_m,
            speed_kmh=pt.speed_kmh,
            last_lat=last_lat,
            last_lng=last_lng,
            time_delta_seconds=time_delta
        ):
            continue

        loc_entity = LocationPoint(
            session_id=session_id,
            latitude=round(pt.latitude, 7),
            longitude=round(pt.longitude, 7),
            altitude=round(pt.altitude, 1) if pt.altitude is not None else None,
            speed_kmh=round(pt.speed_kmh, 1),
            heading=round(pt.heading, 1) if pt.heading is not None else None,
            accuracy_m=round(pt.accuracy_m, 1) if pt.accuracy_m is not None else None,
            battery_pct=pt.battery_pct,
            network_status=pt.network_status or "online",
            timestamp=pt_time,
        )
        db.add(loc_entity)
        accepted_points.append(loc_entity)

        last_lat = pt.latitude
        last_lng = pt.longitude
        last_time = pt_time

        # Update session battery
        if pt.battery_pct is not None:
            session.battery_current_pct = pt.battery_pct

        # Check Overspeed Alert
        if pt.speed_kmh > overspeed_limit:
            alert = Alert(
                user_id=user_id,
                bike_id=session.bike_id,
                session_id=session_id,
                alert_type="overspeed",
                severity="warning",
                title="Overspeed Warning",
                message=f"Current speed {int(pt.speed_kmh)} km/h exceeds configured safety limit of {int(overspeed_limit)} km/h.",
                latitude=pt.latitude,
                longitude=pt.longitude,
                metadata_json={"speed_kmh": pt.speed_kmh, "limit_kmh": overspeed_limit}
            )
            db.add(alert)

    if accepted_points:
        await db.commit()

        # Check geofences with latest accepted point
        latest = accepted_points[-1]
        await check_geofences_for_point(
            db=db,
            user_id=user_id,
            bike_id=session.bike_id,
            session_id=session_id,
            lat=latest.latitude,
            lng=latest.longitude
        )

        # Update Redis/in-memory live state
        live_payload = {
            "session_id": session_id,
            "bike_id": session.bike_id,
            "bike_name": session.bike.name if session.bike else "Motorcycle",
            "bike_manufacturer": session.bike.manufacturer if session.bike else "",
            "bike_model": session.bike.model if session.bike else "",
            "status": session.status,
            "latitude": latest.latitude,
            "longitude": latest.longitude,
            "altitude": latest.altitude,
            "speed_kmh": latest.speed_kmh,
            "heading": latest.heading,
            "accuracy_m": latest.accuracy_m,
            "battery_pct": latest.battery_pct,
            "updated_at": latest.timestamp.isoformat(),
        }
        await state_store.set_live_point(session_id, live_payload)

        # Broadcast update to connected WebSockets
        ws_msg = {
            "type": "LOCATION_UPDATE",
            "data": live_payload
        }
        await ws_manager.broadcast_session_update(session_id, ws_msg)

        # Broadcast to active live share tokens
        shares_res = await db.execute(
            select(SharedTrackingSession).where(
                SharedTrackingSession.session_id == session_id,
                SharedTrackingSession.is_active == True,
                SharedTrackingSession.expires_at > datetime.now(timezone.utc)
            )
        )
        for share in shares_res.scalars().all():
            await ws_manager.broadcast_share_update(share.share_token, ws_msg)

    return {
        "ingested_count": len(accepted_points),
        "total_submitted": len(points_data),
        "status": session.status
    }


async def pause_tracking_session(db: AsyncSession, session_id: str, user_id: str) -> TrackingSession:
    result = await db.execute(
        select(TrackingSession).where(TrackingSession.id == session_id, TrackingSession.user_id == user_id)
    )
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    
    session.status = "paused"
    session.paused_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(session)
    await ws_manager.broadcast_session_update(session_id, {"type": "SESSION_PAUSED"})
    return session


async def resume_tracking_session(db: AsyncSession, session_id: str, user_id: str) -> TrackingSession:
    result = await db.execute(
        select(TrackingSession).where(TrackingSession.id == session_id, TrackingSession.user_id == user_id)
    )
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    
    session.status = "active"
    session.paused_at = None
    await db.commit()
    await db.refresh(session)
    await ws_manager.broadcast_session_update(session_id, {"type": "SESSION_RESUMED"})
    return session


async def stop_and_finalize_ride(db: AsyncSession, session_id: str, user_id: str) -> Ride:
    """Finalize tracking session and compute ride statistics transactionally."""
    result = await db.execute(
        select(TrackingSession)
        .options(selectinload(TrackingSession.bike))
        .where(TrackingSession.id == session_id, TrackingSession.user_id == user_id)
    )
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    if session.status == "stopped":
        # Already stopped, return existing ride
        ride_res = await db.execute(select(Ride).where(Ride.session_id == session_id))
        existing_ride = ride_res.scalars().first()
        if existing_ride:
            return existing_ride

    now_utc = datetime.now(timezone.utc)
    session.status = "stopped"
    session.stopped_at = now_utc
    session.battery_end_pct = session.battery_current_pct

    # Retrieve all ordered location points
    points_res = await db.execute(
        select(LocationPoint)
        .where(LocationPoint.session_id == session_id)
        .order_by(LocationPoint.timestamp.asc())
    )
    points = points_res.scalars().all()

    # Calculate metrics
    total_dist_meters = 0.0
    max_speed = 0.0
    speeds: List[float] = []
    elevation_gain = 0.0
    elevation_loss = 0.0
    moving_duration = 0

    coords_for_polyline: List[Tuple[float, float]] = []
    points_for_geojson: List[Tuple[float, float, Any]] = []

    for i in range(len(points)):
        pt = points[i]
        coords_for_polyline.append((pt.latitude, pt.longitude))
        points_for_geojson.append((pt.latitude, pt.longitude, pt.altitude))
        
        if pt.speed_kmh > max_speed:
            max_speed = pt.speed_kmh
        if pt.speed_kmh > 3.0:  # Moving threshold
            speeds.append(pt.speed_kmh)

        if i > 0:
            prev = points[i - 1]
            seg_dist = haversine_distance_meters(prev.latitude, prev.longitude, pt.latitude, pt.longitude)
            total_dist_meters += seg_dist

            # Time delta for moving duration
            t_delta = (pt.timestamp - prev.timestamp).total_seconds()
            if pt.speed_kmh > 3.0 and t_delta > 0:
                moving_duration += int(min(t_delta, 30))

            # Elevation deltas
            if pt.altitude is not None and prev.altitude is not None:
                elev_diff = pt.altitude - prev.altitude
                if elev_diff > 0:
                    elevation_gain += elev_diff
                else:
                    elevation_loss += abs(elev_diff)

    total_dist_km = round(total_dist_meters / 1000.0, 2)
    session_started = session.started_at
    if session_started and session_started.tzinfo is None:
        session_started = session_started.replace(tzinfo=timezone.utc)
    duration_seconds = int((now_utc - session_started).total_seconds())
    if duration_seconds < 0:
        duration_seconds = 0
    avg_speed = round(sum(speeds) / len(speeds), 1) if speeds else 0.0

    # Simplify route coordinates for fast web and mobile rendering
    simplified_coords = simplify_points_rdp(coords_for_polyline, epsilon=0.00005)
    encoded_poly = encode_polyline(simplified_coords) if simplified_coords else ""
    geojson_data = points_to_geojson_linestring(points_for_geojson)

    start_lat = points[0].latitude if points else None
    start_lng = points[0].longitude if points else None
    end_lat = points[-1].latitude if points else None
    end_lng = points[-1].longitude if points else None

    # Update bike odometer
    if session.bike:
        session.bike.odometer_km = round(session.bike.odometer_km + total_dist_km, 2)

    # Create finalized Ride
    ride = Ride(
        session_id=session.id,
        user_id=user_id,
        bike_id=session.bike_id,
        total_distance_km=total_dist_km,
        duration_seconds=duration_seconds,
        moving_duration_seconds=moving_duration if moving_duration > 0 else duration_seconds,
        average_speed_kmh=avg_speed,
        max_speed_kmh=round(max_speed, 1),
        elevation_gain_m=round(elevation_gain, 1),
        elevation_loss_m=round(elevation_loss, 1),
        start_latitude=start_lat,
        start_longitude=start_lng,
        end_latitude=end_lat,
        end_longitude=end_lng,
        encoded_polyline=encoded_poly,
        route_geojson=geojson_data,
        started_at=session.started_at,
        ended_at=now_utc,
    )
    db.add(ride)

    # Close active live sharing sessions
    shares_res = await db.execute(
        select(SharedTrackingSession).where(
            SharedTrackingSession.session_id == session_id,
            SharedTrackingSession.is_active == True
        )
    )
    for share in shares_res.scalars().all():
        share.is_active = False

    await db.commit()
    await db.refresh(ride)

    # Cleanup live state & broadcast STOP
    await state_store.remove_live_point(session_id)
    await ws_manager.broadcast_session_update(session_id, {"type": "SESSION_STOPPED", "ride_id": ride.id})

    return ride
