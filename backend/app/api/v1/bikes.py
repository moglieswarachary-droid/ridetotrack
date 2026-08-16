from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.bike import Bike
from app.schemas.bike import BikeCreate, BikeUpdate, BikeResponse

router = APIRouter(prefix="/bikes", tags=["My Bikes"])


@router.get("", response_model=List[BikeResponse])
async def list_bikes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve all motorcycles in rider's garage."""
    result = await db.execute(
        select(Bike).where(Bike.user_id == current_user.id).order_by(Bike.created_at.desc())
    )
    return result.scalars().all()


@router.post("", response_model=BikeResponse, status_code=status.HTTP_201_CREATED)
async def add_bike(
    bike_data: BikeCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add a new motorcycle to rider's garage."""
    # If set as active or first bike, deactivate others
    result = await db.execute(select(Bike).where(Bike.user_id == current_user.id))
    existing_bikes = result.scalars().all()

    should_be_active = bike_data.is_active or len(existing_bikes) == 0
    if should_be_active:
        for b in existing_bikes:
            b.is_active = False

    new_bike = Bike(
        user_id=current_user.id,
        name=bike_data.name,
        manufacturer=bike_data.manufacturer,
        model=bike_data.model,
        variant=bike_data.variant,
        registration_number=bike_data.registration_number,
        year=bike_data.year,
        odometer_km=bike_data.odometer_km,
        photo_url=bike_data.photo_url,
        preferred_tracking_mode=bike_data.preferred_tracking_mode,
        is_active=should_be_active,
    )
    db.add(new_bike)
    await db.commit()
    await db.refresh(new_bike)
    return new_bike


@router.get("/{bike_id}", response_model=BikeResponse)
async def get_bike(
    bike_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get single motorcycle details."""
    result = await db.execute(
        select(Bike).where(Bike.id == bike_id, Bike.user_id == current_user.id)
    )
    bike = result.scalars().first()
    if not bike:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Motorcycle not found.")
    return bike


@router.put("/{bike_id}", response_model=BikeResponse)
async def update_bike(
    bike_id: str,
    update_data: BikeUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update motorcycle specifications or set as primary active bike."""
    result = await db.execute(
        select(Bike).where(Bike.id == bike_id, Bike.user_id == current_user.id)
    )
    bike = result.scalars().first()
    if not bike:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Motorcycle not found.")

    if update_data.is_active is True:
        # Set all other bikes for this user to inactive
        other_bikes = await db.execute(
            select(Bike).where(Bike.user_id == current_user.id, Bike.id != bike_id)
        )
        for b in other_bikes.scalars().all():
            b.is_active = False
        bike.is_active = True

    for field, val in update_data.model_dump(exclude_unset=True).items():
        if field != "is_active":
            setattr(bike, field, val)

    await db.commit()
    await db.refresh(bike)
    return bike


@router.delete("/{bike_id}", status_code=status.HTTP_200_OK)
async def delete_bike(
    bike_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Remove motorcycle from garage."""
    result = await db.execute(
        select(Bike).where(Bike.id == bike_id, Bike.user_id == current_user.id)
    )
    bike = result.scalars().first()
    if not bike:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Motorcycle not found.")

    was_active = bike.is_active
    await db.delete(bike)

    if was_active:
        # Pick another bike to make active if exists
        remaining = await db.execute(select(Bike).where(Bike.user_id == current_user.id))
        next_bike = remaining.scalars().first()
        if next_bike:
            next_bike.is_active = True

    await db.commit()
    return {"message": "Motorcycle removed from garage successfully."}
