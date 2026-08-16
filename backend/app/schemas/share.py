from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field


class ShareCreateRequest(BaseModel):
    session_id: Optional[str] = None
    duration_hours: int = Field(12, ge=1, le=168)  # 1 hour to 7 days
    recipient_label: Optional[str] = "Family Live Link"


class ShareResponse(BaseModel):
    id: str
    session_id: str
    share_token: str
    share_url: str
    recipient_label: Optional[str] = None
    expires_at: datetime
    is_active: bool
    access_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class PublicLiveShareViewer(BaseModel):
    share_token: str
    is_active: bool
    is_expired: bool
    bike_name: str
    bike_manufacturer: str
    bike_model: str
    started_at: datetime
    last_latitude: Optional[float] = None
    last_longitude: Optional[float] = None
    last_speed_kmh: Optional[float] = None
    last_battery_pct: Optional[int] = None
    distance_km: float
    duration_seconds: int
    updated_at: Optional[datetime] = None
    route_points: List[dict] = []
