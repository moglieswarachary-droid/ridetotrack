from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class BikeBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    manufacturer: str = Field(..., min_length=1, max_length=100)
    model: str = Field(..., min_length=1, max_length=100)
    variant: Optional[str] = None
    registration_number: str = Field(..., min_length=1, max_length=50)
    year: int = Field(..., ge=1900, le=2100)
    odometer_km: float = Field(0.0, ge=0.0)
    photo_url: Optional[str] = None
    preferred_tracking_mode: str = "balanced"


class BikeCreate(BikeBase):
    is_active: bool = False


class BikeUpdate(BaseModel):
    name: Optional[str] = None
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    variant: Optional[str] = None
    registration_number: Optional[str] = None
    year: Optional[int] = None
    odometer_km: Optional[float] = None
    photo_url: Optional[str] = None
    is_active: Optional[bool] = None
    preferred_tracking_mode: Optional[str] = None


class BikeResponse(BikeBase):
    id: str
    user_id: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
