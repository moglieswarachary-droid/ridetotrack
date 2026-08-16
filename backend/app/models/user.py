import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Float, Integer
from sqlalchemy.orm import relationship
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone_number = Column(String(30), unique=True, index=True, nullable=True)
    full_name = Column(String(100), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    avatar_url = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    bikes = relationship("Bike", back_populates="owner", cascade="all, delete-orphan")
    settings = relationship("UserSettings", back_populates="user", uselist=False, cascade="all, delete-orphan")
    notification_prefs = relationship("NotificationPreferences", back_populates="user", uselist=False, cascade="all, delete-orphan")
    emergency_contacts = relationship("EmergencyContact", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String(500), unique=True, nullable=False, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="refresh_tokens")


class UserSettings(Base):
    __tablename__ = "user_settings"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    unit_system = Column(String(10), default="metric", nullable=False)  # 'metric' (km/kmh) or 'imperial' (mi/mph)
    tracking_quality_mode = Column(String(20), default="balanced", nullable=False)  # 'battery_saver', 'balanced', 'high_accuracy'
    auto_pause_enabled = Column(Boolean, default=True, nullable=False)
    overspeed_threshold_kmh = Column(Float, default=120.0, nullable=False)
    crash_detection_enabled = Column(Boolean, default=True, nullable=False)
    crash_countdown_seconds = Column(Integer, default=15, nullable=False)
    theme = Column(String(10), default="dark", nullable=False)  # 'dark' or 'light'
    allow_historical_storage = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="settings")


class NotificationPreferences(Base):
    __tablename__ = "notification_preferences"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    ride_alerts = Column(Boolean, default=True, nullable=False)
    geofence_breach = Column(Boolean, default=True, nullable=False)
    crash_alerts = Column(Boolean, default=True, nullable=False)
    low_battery_warning = Column(Boolean, default=True, nullable=False)
    share_updates = Column(Boolean, default=True, nullable=False)
    long_stop_alerts = Column(Boolean, default=False, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="notification_prefs")
