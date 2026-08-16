import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class Geofence(Base):
    __tablename__ = "geofences"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    bike_id = Column(String(36), ForeignKey("bikes.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)  # e.g., "Home Garage", "Office Parking", "Parking Guard Zone"
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    radius_meters = Column(Float, default=100.0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    notify_on_exit = Column(Boolean, default=True, nullable=False)
    notify_on_enter = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    bike = relationship("Bike", back_populates="geofences")
