import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base


class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    bike_id = Column(String(36), ForeignKey("bikes.id", ondelete="CASCADE"), nullable=False, index=True)
    session_id = Column(String(36), ForeignKey("tracking_sessions.id", ondelete="SET NULL"), nullable=True, index=True)
    
    alert_type = Column(String(30), nullable=False, index=True)  # 'crash', 'overspeed', 'geofence_exit', 'low_battery', 'long_stop', 'sos'
    severity = Column(String(20), default="warning", nullable=False)  # 'info', 'warning', 'critical', 'emergency'
    title = Column(String(100), nullable=False)
    message = Column(String(500), nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    metadata_json = Column(JSON, nullable=True)
    is_read = Column(Boolean, default=False, nullable=False, index=True)
    is_acknowledged = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)

    bike = relationship("Bike", back_populates="alerts")
