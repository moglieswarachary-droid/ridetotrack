from typing import Optional, Dict, Any
from datetime import datetime
from pydantic import BaseModel


class AlertCreate(BaseModel):
    bike_id: Optional[str] = None
    session_id: Optional[str] = None
    alert_type: str  # 'crash', 'overspeed', 'geofence_exit', 'low_battery', 'long_stop', 'sos'
    severity: str = "warning"  # 'info', 'warning', 'critical', 'emergency'
    title: str
    message: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    metadata_json: Optional[Dict[str, Any]] = None


class CrashReportRequest(BaseModel):
    bike_id: Optional[str] = None
    session_id: Optional[str] = None
    latitude: float
    longitude: float
    impact_g: float
    speed_before_impact_kmh: float
    cancellation_timed_out: bool = True


class AlertResponse(BaseModel):
    id: str
    user_id: str
    bike_id: str
    session_id: Optional[str] = None
    alert_type: str
    severity: str
    title: str
    message: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    metadata_json: Optional[Dict[str, Any]] = None
    is_read: bool
    is_acknowledged: bool
    created_at: datetime

    class Config:
        from_attributes = True
