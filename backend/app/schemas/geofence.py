from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class GeofenceCreate(BaseModel):
    bike_id: Optional[str] = None
    name: str = Field(..., min_length=1, max_length=100)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    radius_meters: float = Field(100.0, ge=10.0, le=50000.0)
    is_active: bool = True
    notify_on_exit: bool = True
    notify_on_enter: bool = False


class GeofenceUpdate(BaseModel):
    name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_meters: Optional[float] = None
    is_active: Optional[bool] = None
    notify_on_exit: Optional[bool] = None
    notify_on_enter: Optional[bool] = None


class GeofenceResponse(BaseModel):
    id: str
    user_id: str
    bike_id: str
    name: str
    latitude: float
    longitude: float
    radius_meters: float
    is_active: bool
    notify_on_exit: bool
    notify_on_enter: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
