import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    phone_number = Column(String(30), nullable=False)
    relationship_type = Column(String(50), nullable=False)  # 'spouse', 'parent', 'sibling', 'friend', 'riding_buddy'
    is_verified = Column(Boolean, default=True, nullable=False)
    notify_on_crash = Column(Boolean, default=True, nullable=False)
    notify_on_sos = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="emergency_contacts")
