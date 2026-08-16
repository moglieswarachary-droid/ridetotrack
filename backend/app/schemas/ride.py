from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel


class RideSummaryResponse(BaseModel):
    id: str
    session_id: str
    bike_id: str
    total_distance_km: float
    duration_seconds: int
    moving_duration_seconds: int
    average_speed_kmh: float
    max_speed_kmh: float
    elevation_gain_m: float
    elevation_loss_m: float
    start_address: Optional[str] = None
    end_address: Optional[str] = None
    started_at: datetime
    ended_at: datetime

    class Config:
        from_attributes = True


class RideDetailResponse(RideSummaryResponse):
    start_latitude: Optional[float] = None
    start_longitude: Optional[float] = None
    end_latitude: Optional[float] = None
    end_longitude: Optional[float] = None
    encoded_polyline: Optional[str] = None
    route_geojson: Optional[Dict[str, Any]] = None


class RideRoutePoint(BaseModel):
    latitude: float
    longitude: float
    altitude: Optional[float] = None
    speed_kmh: float
    heading: Optional[float] = None
    accuracy_m: Optional[float] = None
    timestamp: datetime


class RideRouteResponse(BaseModel):
    ride_id: str
    total_points: int
    points: List[RideRoutePoint]
