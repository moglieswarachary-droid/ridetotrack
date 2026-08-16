from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.ride import Ride
from app.models.location_point import LocationPoint
from app.schemas.ride import (
    RideSummaryResponse,
    RideDetailResponse,
    RideRouteResponse,
    RideRoutePoint
)
from app.services.export_service import export_ride_to_gpx, export_ride_to_geojson
from app.core.audit import record_audit_log

router = APIRouter(prefix="/rides", tags=["Ride History & Replay"])


@router.get("", response_model=List[RideSummaryResponse])
async def list_rides(
    bike_id: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List completed rides with pagination and optional bike filter."""
    query = select(Ride).where(Ride.user_id == current_user.id)
    if bike_id:
        query = query.where(Ride.bike_id == bike_id)
    query = query.order_by(Ride.started_at.desc()).offset(offset).limit(limit)
    
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{ride_id}", response_model=RideDetailResponse)
async def get_ride_detail(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve full ride metrics including simplified polyline and GeoJSON summary."""
    result = await db.execute(
        select(Ride).where(Ride.id == ride_id, Ride.user_id == current_user.id)
    )
    ride = result.scalars().first()
    if not ride:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ride not found.")
    return ride


@router.get("/{ride_id}/route", response_model=RideRouteResponse)
async def get_ride_route_for_replay(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve complete ordered GPS telemetry points for full interactive route replay."""
    result = await db.execute(
        select(Ride).where(Ride.id == ride_id, Ride.user_id == current_user.id)
    )
    ride = result.scalars().first()
    if not ride:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ride not found.")

    points_res = await db.execute(
        select(LocationPoint)
        .where(LocationPoint.session_id == ride.session_id)
        .order_by(LocationPoint.timestamp.asc())
    )
    points = points_res.scalars().all()

    route_pts = [
        RideRoutePoint(
            latitude=p.latitude,
            longitude=p.longitude,
            altitude=p.altitude,
            speed_kmh=p.speed_kmh,
            heading=p.heading,
            accuracy_m=p.accuracy_m,
            timestamp=p.timestamp,
        )
        for p in points
    ]

    return RideRouteResponse(
        ride_id=ride.id,
        total_points=len(route_pts),
        points=route_pts
    )


@router.get("/{ride_id}/export/gpx")
async def export_gpx(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Export ride as standardized GPX 1.1 file."""
    result = await db.execute(
        select(Ride).where(Ride.id == ride_id, Ride.user_id == current_user.id)
    )
    ride = result.scalars().first()
    if not ride:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ride not found.")

    points_res = await db.execute(
        select(LocationPoint)
        .where(LocationPoint.session_id == ride.session_id)
        .order_by(LocationPoint.timestamp.asc())
    )
    points = points_res.scalars().all()
    gpx_content = export_ride_to_gpx(ride, points)

    filename = f"ridetrack_ride_{ride.started_at.strftime('%Y%m%d_%H%M%S')}.gpx"
    return Response(
        content=gpx_content,
        media_type="application/gpx+xml",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.get("/{ride_id}/export/geojson")
async def export_geojson(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Export ride as GeoJSON FeatureCollection."""
    result = await db.execute(
        select(Ride).where(Ride.id == ride_id, Ride.user_id == current_user.id)
    )
    ride = result.scalars().first()
    if not ride:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ride not found.")

    points_res = await db.execute(
        select(LocationPoint)
        .where(LocationPoint.session_id == ride.session_id)
        .order_by(LocationPoint.timestamp.asc())
    )
    points = points_res.scalars().all()
    geojson_content = export_ride_to_geojson(ride, points)

    filename = f"ridetrack_ride_{ride.started_at.strftime('%Y%m%d_%H%M%S')}.geojson"
    return Response(
        content=geojson_content,
        media_type="application/geo+json",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.delete("/{ride_id}", status_code=status.HTTP_200_OK)
async def delete_ride(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Permanently delete a ride and associated location track points."""
    result = await db.execute(
        select(Ride).where(Ride.id == ride_id, Ride.user_id == current_user.id)
    )
    ride = result.scalars().first()
    if not ride:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ride not found.")

    await record_audit_log(db, action="RIDE_DELETED", user_id=current_user.id, details={"ride_id": ride_id})
    await db.delete(ride)
    await db.commit()
    return {"message": "Ride deleted successfully."}
