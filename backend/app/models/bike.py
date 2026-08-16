import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


class Bike(Base):
    __tablename__ = "bikes"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)  # e.g. "My Street Triple" or "KTM Duke 390"
    manufacturer = Column(String(100), nullable=False)  # e.g. "Triumph", "Yamaha", "Ducati", "Honda"
    model = Column(String(100), nullable=False)  # e.g. "Street Triple RS", "MT-09", "Panigale V4"
    variant = Column(String(50), nullable=True)  # e.g. "RS", "SP", "ABS"
    registration_number = Column(String(50), nullable=False, index=True)  # e.g. "KA-01-EQ-9988"
    year = Column(Integer, nullable=False)
    odometer_km = Column(Float, default=0.0, nullable=False)
    photo_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=False, nullable=False, index=True)  # Primary bike for tracking
    preferred_tracking_mode = Column(String(20), default="balanced", nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    owner = relationship("User", back_populates="bikes")
    tracking_sessions = relationship("TrackingSession", back_populates="bike", cascade="all, delete-orphan")
    rides = relationship("Ride", back_populates="bike", cascade="all, delete-orphan")
    parking_locations = relationship("ParkingLocation", back_populates="bike", cascade="all, delete-orphan")
    geofences = relationship("Geofence", back_populates="bike", cascade="all, delete-orphan")
    alerts = relationship("Alert", back_populates="bike", cascade="all, delete-orphan")
