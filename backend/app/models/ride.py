import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base


class Ride(Base):
    __tablename__ = "rides"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String(36), ForeignKey("tracking_sessions.id", ondelete="CASCADE"), unique=True, nullable=False)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    bike_id = Column(String(36), ForeignKey("bikes.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Ride Core Metrics
    total_distance_km = Column(Float, default=0.0, nullable=False)
    duration_seconds = Column(Integer, default=0, nullable=False)
    moving_duration_seconds = Column(Integer, default=0, nullable=False)
    average_speed_kmh = Column(Float, default=0.0, nullable=False)
    max_speed_kmh = Column(Float, default=0.0, nullable=False)
    elevation_gain_m = Column(Float, default=0.0, nullable=False)
    elevation_loss_m = Column(Float, default=0.0, nullable=False)
    
    # Locations
    start_latitude = Column(Float, nullable=True)
    start_longitude = Column(Float, nullable=True)
    start_address = Column(String(255), nullable=True)
    end_latitude = Column(Float, nullable=True)
    end_longitude = Column(Float, nullable=True)
    end_address = Column(String(255), nullable=True)
    
    # Polyline & GeoJSON for fast map rendering
    encoded_polyline = Column(Text, nullable=True)
    route_geojson = Column(JSON, nullable=True)
    
    # Timestamps
    started_at = Column(DateTime(timezone=True), nullable=False, index=True)
    ended_at = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    session = relationship("TrackingSession", back_populates="ride")
    bike = relationship("Bike", back_populates="rides")
