import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Integer, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


class TrackingSession(Base):
    __tablename__ = "tracking_sessions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    bike_id = Column(String(36), ForeignKey("bikes.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(String(20), default="active", nullable=False, index=True)  # 'active', 'paused', 'stopped'
    tracking_mode = Column(String(20), default="balanced", nullable=False)
    battery_start_pct = Column(Integer, nullable=True)
    battery_current_pct = Column(Integer, nullable=True)
    battery_end_pct = Column(Integer, nullable=True)
    started_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    paused_at = Column(DateTime(timezone=True), nullable=True)
    stopped_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    bike = relationship("Bike", back_populates="tracking_sessions")
    location_points = relationship("LocationPoint", back_populates="session", cascade="all, delete-orphan", order_by="LocationPoint.timestamp")
    ride = relationship("Ride", back_populates="session", uselist=False, cascade="all, delete-orphan")
    shared_sessions = relationship("SharedTrackingSession", back_populates="session", cascade="all, delete-orphan")
