import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, JSON
from app.core.database import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), index=True, nullable=True)
    action = Column(String(100), nullable=False, index=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(255), nullable=True)
    details = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)
