from typing import List, Dict, Any
from datetime import date
from pydantic import BaseModel


class AnalyticsSummaryResponse(BaseModel):
    total_distance_km: float
    total_rides_count: int
    total_duration_hours: float
    average_speed_kmh: float
    max_speed_kmh: float
    average_ride_distance_km: float
    longest_ride_distance_km: float
    active_bikes_count: int


class DailyAnalyticsPoint(BaseModel):
    ride_date: date
    distance_km: float
    rides_count: int
    duration_minutes: int


class SpeedDistributionBucket(BaseModel):
    range_label: str  # e.g., "0-30 km/h", "30-60 km/h", "60-90 km/h", "90+ km/h"
    percentage: float
    total_minutes: int


class SmartRideIntelligenceResponse(BaseModel):
    summary: AnalyticsSummaryResponse
    daily_trend: List[DailyAnalyticsPoint]
    speed_distribution: List[SpeedDistributionBucket]
    riding_patterns: Dict[str, Any]
