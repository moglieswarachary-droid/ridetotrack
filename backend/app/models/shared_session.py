import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer
from sqlalchemy.orm import relationship
from app.core.database import Base


class SharedTrackingSession(Base):
    __tablename__ = "shared_tracking_sessions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    session_id = Column(String(36), ForeignKey("tracking_sessions.id", ondelete="CASCADE"), nullable=False, index=True)
    share_token = Column(String(64), unique=True, nullable=False, index=True)
    recipient_label = Column(String(100), nullable=True)  # e.g., "Family Live Link"
    expires_at = Column(DateTime(timezone=True), nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    access_count = Column(Integer, default=0, nullable=False)
    revoked_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    session = relationship("TrackingSession", back_populates="shared_sessions")
