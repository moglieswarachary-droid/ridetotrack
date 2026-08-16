from typing import Optional
from pydantic import BaseModel, Field


class UserSettingsUpdate(BaseModel):
    unit_system: Optional[str] = Field(None, description="'metric' or 'imperial'")
    tracking_quality_mode: Optional[str] = Field(None, description="'battery_saver', 'balanced', 'high_accuracy'")
    auto_pause_enabled: Optional[bool] = None
    overspeed_threshold_kmh: Optional[float] = Field(None, ge=30.0, le=300.0)
    crash_detection_enabled: Optional[bool] = None
    crash_countdown_seconds: Optional[int] = Field(None, ge=5, le=60)
    theme: Optional[str] = Field(None, description="'dark' or 'light'")
    allow_historical_storage: Optional[bool] = None


class UserSettingsResponse(BaseModel):
    unit_system: str
    tracking_quality_mode: str
    auto_pause_enabled: bool
    overspeed_threshold_kmh: float
    crash_detection_enabled: bool
    crash_countdown_seconds: int
    theme: str
    allow_historical_storage: bool

    class Config:
        from_attributes = True


class NotificationPreferencesUpdate(BaseModel):
    ride_alerts: Optional[bool] = None
    geofence_breach: Optional[bool] = None
    crash_alerts: Optional[bool] = None
    low_battery_warning: Optional[bool] = None
    share_updates: Optional[bool] = None
    long_stop_alerts: Optional[bool] = None


class NotificationPreferencesResponse(BaseModel):
    ride_alerts: bool
    geofence_breach: bool
    crash_alerts: bool
    low_battery_warning: bool
    share_updates: bool
    long_stop_alerts: bool

    class Config:
        from_attributes = True
