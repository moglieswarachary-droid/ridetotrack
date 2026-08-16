from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class TrackingStartRequest(BaseModel):
    bike_id: Optional[str] = None
    tracking_mode: Optional[str] = "balanced"  # 'battery_saver', 'balanced', 'high_accuracy'
    battery_pct: Optional[int] = None


class TrackingSessionResponse(BaseModel):
    id: str
    user_id: str
    bike_id: str
    status: str
    tracking_mode: str
    battery_start_pct: Optional[int] = None
    battery_current_pct: Optional[int] = None
    started_at: datetime
    paused_at: Optional[datetime] = None
    stopped_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class LiveTelemetryResponse(BaseModel):
    session_id: str
    bike_id: str
    bike_name: str
    status: str
    latitude: float
    longitude: float
    speed_kmh: float
    heading: Optional[float] = None
    altitude: Optional[float] = None
    accuracy_m: Optional[float] = None
    battery_pct: Optional[int] = None
    distance_km: float
    duration_seconds: int
    avg_speed_kmh: float
    max_speed_kmh: float
    updated_at: datetime
