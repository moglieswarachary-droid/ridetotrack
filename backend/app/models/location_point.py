import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.core.database import Base


class LocationPoint(Base):
    __tablename__ = "location_points"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String(36), ForeignKey("tracking_sessions.id", ondelete="CASCADE"), nullable=False, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    altitude = Column(Float, nullable=True)
    speed_kmh = Column(Float, default=0.0, nullable=False)
    heading = Column(Float, nullable=True)
    accuracy_m = Column(Float, nullable=True)
    battery_pct = Column(Integer, nullable=True)
    network_status = Column(String(20), nullable=True)  # 'online', 'synced_offline'
    timestamp = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)

    session = relationship("TrackingSession", back_populates="location_points")

    __table_args__ = (
        Index("ix_location_session_timestamp", "session_id", "timestamp"),
    )
