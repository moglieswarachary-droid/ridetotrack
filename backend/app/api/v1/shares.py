from datetime import datetime, timezone, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.tracking_session import TrackingSession
from app.models.shared_session import SharedTrackingSession
from app.models.location_point import LocationPoint
from app.schemas.share import (
    ShareCreateRequest,
    ShareResponse,
    PublicLiveShareViewer,
)
from app.core.security import generate_share_token
from app.core.redis_client import state_store
from app.core.audit import record_audit_log

router = APIRouter(tags=["Live Ride Sharing"])


@router.post("/shares", response_model=ShareResponse, status_code=status.HTTP_201_CREATED)
async def create_share_link(
    data: ShareCreateRequest,
    req: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate a secure, time-limited live tracking link for family or friends."""
    session_id = data.session_id
    if not session_id:
        # Find active session
        res = await db.execute(
            select(TrackingSession).where(
                TrackingSession.user_id == current_user.id,
                TrackingSession.status == "active"
            )
        )
        active_sess = res.scalars().first()
        if not active_sess:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No active ride tracking session to share. Start a ride first."
            )
        session_id = active_sess.id
    else:
        # Verify ownership
        res = await db.execute(
            select(TrackingSession).where(
                TrackingSession.id == session_id,
                TrackingSession.user_id == current_user.id
            )
        )
        if not res.scalars().first():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    token = generate_share_token()
    expires_at = datetime.now(timezone.utc) + timedelta(hours=data.duration_hours)

    shared_session = SharedTrackingSession(
        user_id=current_user.id,
        session_id=session_id,
        share_token=token,
        recipient_label=data.recipient_label or "Live Link",
        expires_at=expires_at,
        is_active=True,
    )
    db.add(shared_session)
    await db.commit()
    await db.refresh(shared_session)

    base_url = str(req.base_url).rstrip("/")
    share_url = f"{base_url}/live/{token}"

    await record_audit_log(
        db,
        action="SHARE_CREATED",
        user_id=current_user.id,
        details={"session_id": session_id, "token": token, "expires_at": expires_at.isoformat()}
    )

    return ShareResponse(
        id=shared_session.id,
        session_id=shared_session.session_id,
        share_token=shared_session.share_token,
        share_url=share_url,
        recipient_label=shared_session.recipient_label,
        expires_at=shared_session.expires_at,
        is_active=shared_session.is_active,
        access_count=shared_session.access_count,
        created_at=shared_session.created_at,
    )


@router.get("/shares", response_model=List[ShareResponse])
async def list_shares(
    req: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all created live tracking links."""
    result = await db.execute(
        select(SharedTrackingSession)
        .where(SharedTrackingSession.user_id == current_user.id)
        .order_by(SharedTrackingSession.created_at.desc())
    )
    shares = result.scalars().all()
    base_url = str(req.base_url).rstrip("/")
    return [
        ShareResponse(
            id=s.id,
            session_id=s.session_id,
            share_token=s.share_token,
            share_url=f"{base_url}/live/{s.share_token}",
            recipient_label=s.recipient_label,
            expires_at=s.expires_at,
            is_active=s.is_active,
            access_count=s.access_count,
            created_at=s.created_at,
        )
        for s in shares
    ]


@router.post("/shares/{share_id}/stop", status_code=status.HTTP_200_OK)
async def stop_sharing(
    share_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Instantly revoke a live sharing link."""
    result = await db.execute(
        select(SharedTrackingSession).where(
            SharedTrackingSession.id == share_id,
            SharedTrackingSession.user_id == current_user.id
        )
    )
    share = result.scalars().first()
    if not share:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share session not found.")

    share.is_active = False
    share.revoked_at = datetime.now(timezone.utc)
    await db.commit()
    await record_audit_log(db, action="SHARE_REVOKED", user_id=current_user.id, details={"share_id": share_id})
    return {"message": "Live share link revoked."}


@router.get("/shares/view/{token}", response_model=PublicLiveShareViewer)
async def get_public_live_viewer(
    token: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Public zero-auth endpoint for family/friends to view live tracking telemetry.
    Never exposes owner emails, IDs, passwords, or personal account information.
    """
    result = await db.execute(
        select(SharedTrackingSession)
        .options(
            selectinload(SharedTrackingSession.session)
            .selectinload(TrackingSession.bike)
        )
        .where(SharedTrackingSession.share_token == token)
    )
    share = result.scalars().first()
    if not share:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Live share link not found or expired.")

    now_utc = datetime.now(timezone.utc)
    expires_at = share.expires_at
    if expires_at and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    is_expired = expires_at < now_utc
    if is_expired or not share.is_active:
        started_at = share.session.started_at if share.session else now_utc
        if started_at and started_at.tzinfo is None:
            started_at = started_at.replace(tzinfo=timezone.utc)
        return PublicLiveShareViewer(
            share_token=token,
            is_active=False,
            is_expired=is_expired,
            bike_name=share.session.bike.name if share.session and share.session.bike else "Motorcycle",
            bike_manufacturer=share.session.bike.manufacturer if share.session and share.session.bike else "",
            bike_model=share.session.bike.model if share.session and share.session.bike else "",
            started_at=started_at,
            distance_km=0.0,
            duration_seconds=0,
            route_points=[],
        )

    # Increment access count
    share.access_count += 1
    await db.commit()

    # Fetch ordered track points
    points_res = await db.execute(
        select(LocationPoint)
        .where(LocationPoint.session_id == share.session_id)
        .order_by(LocationPoint.timestamp.asc())
    )
    points = points_res.scalars().all()

    # Calculate distance
    from app.utils.geo import haversine_distance_meters
    dist_km = 0.0
    for i in range(1, len(points)):
        dist_km += haversine_distance_meters(
            points[i-1].latitude, points[i-1].longitude,
            points[i].latitude, points[i].longitude
        ) / 1000.0

    started_at = share.session.started_at if share.session else now_utc
    if started_at and started_at.tzinfo is None:
        started_at = started_at.replace(tzinfo=timezone.utc)
    dur_sec = int((now_utc - started_at).total_seconds())
    latest = points[-1] if points else None

    # Sample route points if large to preserve browser performance
    step = max(1, len(points) // 200)
    sampled = [
        {"lat": p.latitude, "lng": p.longitude, "speed": p.speed_kmh, "t": p.timestamp.isoformat()}
        for p in points[::step]
    ]
    if latest and (not sampled or sampled[-1]["lat"] != latest.latitude):
        sampled.append({"lat": latest.latitude, "lng": latest.longitude, "speed": latest.speed_kmh, "t": latest.timestamp.isoformat()})

    return PublicLiveShareViewer(
        share_token=token,
        is_active=share.is_active and not is_expired,
        is_expired=is_expired,
        bike_name=share.session.bike.name if share.session and share.session.bike else "Motorcycle",
        bike_manufacturer=share.session.bike.manufacturer if share.session and share.session.bike else "",
        bike_model=share.session.bike.model if share.session and share.session.bike else "",
        started_at=share.session.started_at if share.session else now_utc,
        last_latitude=latest.latitude if latest else None,
        last_longitude=latest.longitude if latest else None,
        last_speed_kmh=latest.speed_kmh if latest else 0.0,
        last_battery_pct=latest.battery_pct if latest else None,
        distance_km=round(dist_km, 2),
        duration_seconds=dur_sec,
        updated_at=latest.timestamp if latest else None,
        route_points=sampled,
    )
