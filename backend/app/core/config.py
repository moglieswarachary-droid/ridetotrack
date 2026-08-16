import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "RideTrack API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"
    
    # Security & Tokens
    SECRET_KEY: str = os.getenv("SECRET_KEY", "ridetrack-super-secret-production-key-change-in-prod-7829471923")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))
    SHARE_TOKEN_DEFAULT_HOURS: int = int(os.getenv("SHARE_TOKEN_DEFAULT_HOURS", "12"))
    
    # Database
    # Supports SQLite (default for instant portable local dev) or PostgreSQL with PostGIS
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./ridetrack.db")
    
    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    USE_REDIS_FALLBACK: bool = True
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:3000",
        "*"
    ]
    
    # Tracking & GPS Filtering Parameters
    MAX_VALID_SPEED_KMH: float = 300.0   # Outlier rejection for impossible jumps
    MAX_ALLOWED_ACCURACY_M: float = 80.0 # Drop points with worse than 80m GPS radius
    DEFAULT_GEOFENCE_RADIUS_M: float = 100.0
    DEFAULT_OVERSPEED_THRESHOLD_KMH: float = 120.0
    
    model_config = SettingsConfigDict(
        case_sensitive=True,
        env_file=".env",
        extra="ignore"
    )


settings = Settings()

