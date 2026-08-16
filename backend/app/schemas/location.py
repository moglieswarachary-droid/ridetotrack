from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field


class LocationPointCreate(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    altitude: Optional[float] = None
    speed_kmh: float = Field(0.0, ge=0.0)
    heading: Optional[float] = Field(None, ge=0.0, le=360.0)
    accuracy_m: Optional[float] = None
    battery_pct: Optional[int] = Field(None, ge=0, le=100)
    network_status: Optional[str] = "online"
    timestamp: Optional[datetime] = None


class LocationBatchIngest(BaseModel):
    points: List[LocationPointCreate]


class LocationPointResponse(LocationPointCreate):
    id: str
    session_id: str
    timestamp: datetime

    class Config:
        from_attributes = True
