from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class EmergencyContactCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    phone_number: str = Field(..., min_length=5, max_length=30)
    relationship_type: str = Field(..., min_length=1, max_length=50)
    notify_on_crash: bool = True
    notify_on_sos: bool = True


class EmergencyContactUpdate(BaseModel):
    name: Optional[str] = None
    phone_number: Optional[str] = None
    relationship_type: Optional[str] = None
    notify_on_crash: Optional[bool] = None
    notify_on_sos: Optional[bool] = None


class EmergencyContactResponse(BaseModel):
    id: str
    user_id: str
    name: str
    phone_number: str
    relationship_type: str
    is_verified: bool
    notify_on_crash: bool
    notify_on_sos: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class SOSTriggerRequest(BaseModel):
    latitude: float
    longitude: float
    message: Optional[str] = "Emergency SOS Alert triggered by rider on RideTrack"
    battery_pct: Optional[int] = None
