import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class ParkingLocation(Base):
    __tablename__ = "parking_locations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    bike_id = Column(String(36), ForeignKey("bikes.id", ondelete="CASCADE"), nullable=False, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    accuracy_m = Column(Float, nullable=True)
    address = Column(String(255), nullable=True)
    note = Column(Text, nullable=True)  # e.g., "P2 Pillar 14B near elevator"
    photo_url = Column(String(500), nullable=True)
    parked_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    bike = relationship("Bike", back_populates="parking_locations")
