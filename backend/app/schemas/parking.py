from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class ParkingLocationCreate(BaseModel):
    bike_id: Optional[str] = None
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    accuracy_m: Optional[float] = None
    address: Optional[str] = None
    note: Optional[str] = None
    photo_url: Optional[str] = None


class ParkingLocationResponse(BaseModel):
    id: str
    user_id: str
    bike_id: str
    latitude: float
    longitude: float
    accuracy_m: Optional[float] = None
    address: Optional[str] = None
    note: Optional[str] = None
    photo_url: Optional[str] = None
    parked_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class WalkingDirectionToBike(BaseModel):
    distance_meters: float
    bearing_degrees: float
    cardinal_direction: str
    target_latitude: float
    target_longitude: float
