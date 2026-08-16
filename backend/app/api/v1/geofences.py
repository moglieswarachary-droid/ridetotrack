from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.bike import Bike
from app.models.geofence import Geofence
from app.schemas.geofence import GeofenceCreate, GeofenceUpdate, GeofenceResponse

router = APIRouter(prefix="/geofences", tags=["Geofencing"])


@router.get("", response_model=List[GeofenceResponse])
async def list_geofences(
    bike_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all configured geofences."""
    query = select(Geofence).where(Geofence.user_id == current_user.id)
    if bike_id:
        query = query.where(Geofence.bike_id == bike_id)
    result = await db.execute(query)
    return result.scalars().all()


@router.post("", response_model=GeofenceResponse, status_code=status.HTTP_201_CREATED)
async def create_geofence(
    data: GeofenceCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new safe zone geofence for motorcycle."""
    bike_id = data.bike_id
    if not bike_id:
        res = await db.execute(
            select(Bike).where(Bike.user_id == current_user.id, Bike.is_active == True)
        )
        active_bike = res.scalars().first()
        if not active_bike:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No active bike found.")
        bike_id = active_bike.id

    geofence = Geofence(
        user_id=current_user.id,
        bike_id=bike_id,
        name=data.name,
        latitude=data.latitude,
        longitude=data.longitude,
        radius_meters=data.radius_meters,
        is_active=data.is_active,
        notify_on_exit=data.notify_on_exit,
        notify_on_enter=data.notify_on_enter,
    )
    db.add(geofence)
    await db.commit()
    await db.refresh(geofence)
    return geofence


@router.put("/{geofence_id}", response_model=GeofenceResponse)
async def update_geofence(
    geofence_id: str,
    update_data: GeofenceUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update geofence radius or active toggle."""
    result = await db.execute(
        select(Geofence).where(
            Geofence.id == geofence_id,
            Geofence.user_id == current_user.id
        )
    )
    geofence = result.scalars().first()
    if not geofence:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Geofence not found.")

    for field, val in update_data.model_dump(exclude_unset=True).items():
        setattr(geofence, field, val)

    await db.commit()
    await db.refresh(geofence)
    return geofence


@router.delete("/{geofence_id}", status_code=status.HTTP_200_OK)
async def delete_geofence(
    geofence_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a geofence."""
    result = await db.execute(
        select(Geofence).where(
            Geofence.id == geofence_id,
            Geofence.user_id == current_user.id
        )
    )
    geofence = result.scalars().first()
    if not geofence:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Geofence not found.")

    await db.delete(geofence)
    await db.commit()
    return {"message": "Geofence deleted successfully."}
