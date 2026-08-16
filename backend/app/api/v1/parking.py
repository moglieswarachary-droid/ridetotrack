from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.bike import Bike
from app.models.parking import ParkingLocation
from app.schemas.parking import (
    ParkingLocationCreate,
    ParkingLocationResponse,
    WalkingDirectionToBike
)
from app.utils.geo import (
    haversine_distance_meters,
    calculate_bearing_degrees,
    degrees_to_cardinal
)

router = APIRouter(prefix="/parking", tags=["Parking Guard"])


@router.post("", response_model=ParkingLocationResponse, status_code=status.HTTP_201_CREATED)
async def save_parking_spot(
    data: ParkingLocationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Save motorcycle's current parked location."""
    bike_id = data.bike_id
    if not bike_id:
        result = await db.execute(
            select(Bike).where(Bike.user_id == current_user.id, Bike.is_active == True)
        )
        active_bike = result.scalars().first()
        if not active_bike:
            # First bike
            res = await db.execute(select(Bike).where(Bike.user_id == current_user.id))
            active_bike = res.scalars().first()
            if not active_bike:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No motorcycle found.")
        bike_id = active_bike.id

    parking = ParkingLocation(
        user_id=current_user.id,
        bike_id=bike_id,
        latitude=data.latitude,
        longitude=data.longitude,
        accuracy_m=data.accuracy_m,
        address=data.address,
        note=data.note,
        photo_url=data.photo_url,
    )
    db.add(parking)
    await db.commit()
    await db.refresh(parking)
    return parking


@router.get("/current", response_model=Optional[ParkingLocationResponse])
async def get_current_parking_spot(
    bike_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve the latest saved parking location for the bike."""
    query = select(ParkingLocation).where(ParkingLocation.user_id == current_user.id)
    if bike_id:
        query = query.where(ParkingLocation.bike_id == bike_id)
    query = query.order_by(ParkingLocation.parked_at.desc()).limit(1)

    result = await db.execute(query)
    return result.scalars().first()


@router.get("/directions", response_model=WalkingDirectionToBike)
async def get_walking_directions_to_bike(
    current_lat: float = Query(..., ge=-90.0, le=90.0),
    current_lng: float = Query(..., ge=-180.0, le=180.0),
    bike_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Calculate direct distance, bearing, and compass heading back to parked bike."""
    query = select(ParkingLocation).where(ParkingLocation.user_id == current_user.id)
    if bike_id:
        query = query.where(ParkingLocation.bike_id == bike_id)
    query = query.order_by(ParkingLocation.parked_at.desc()).limit(1)

    result = await db.execute(query)
    parking = result.scalars().first()
    if not parking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No saved parking spot found.")

    dist = haversine_distance_meters(current_lat, current_lng, parking.latitude, parking.longitude)
    bearing = calculate_bearing_degrees(current_lat, current_lng, parking.latitude, parking.longitude)
    cardinal = degrees_to_cardinal(bearing)

    return WalkingDirectionToBike(
        distance_meters=round(dist, 1),
        bearing_degrees=bearing,
        cardinal_direction=cardinal,
        target_latitude=parking.latitude,
        target_longitude=parking.longitude,
    )


@router.delete("/{parking_id}", status_code=status.HTTP_200_OK)
async def delete_parking_spot(
    parking_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Remove saved parking location."""
    result = await db.execute(
        select(ParkingLocation).where(
            ParkingLocation.id == parking_id,
            ParkingLocation.user_id == current_user.id
        )
    )
    parking = result.scalars().first()
    if not parking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parking location not found.")

    await db.delete(parking)
    await db.commit()
    return {"message": "Parking location cleared successfully."}
