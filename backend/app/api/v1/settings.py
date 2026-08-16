from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, UserSettings, NotificationPreferences
from app.schemas.settings import (
    UserSettingsResponse,
    UserSettingsUpdate,
    NotificationPreferencesResponse,
    NotificationPreferencesUpdate,
)

router = APIRouter(prefix="/settings", tags=["Settings & Privacy"])


@router.get("", response_model=UserSettingsResponse)
async def get_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve rider tracking preferences and unit configuration."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == current_user.id)
    )
    settings = result.scalars().first()
    if not settings:
        settings = UserSettings(user_id=current_user.id)
        db.add(settings)
        await db.commit()
        await db.refresh(settings)
    return settings


@router.put("", response_model=UserSettingsResponse)
async def update_settings(
    update_data: UserSettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update tracking quality profile, units, crash sensitivity, or privacy mode."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == current_user.id)
    )
    settings = result.scalars().first()
    if not settings:
        settings = UserSettings(user_id=current_user.id)
        db.add(settings)

    for field, val in update_data.model_dump(exclude_unset=True).items():
        setattr(settings, field, val)

    await db.commit()
    await db.refresh(settings)
    return settings


@router.get("/notifications", response_model=NotificationPreferencesResponse)
async def get_notification_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve notification channel preferences."""
    result = await db.execute(
        select(NotificationPreferences).where(NotificationPreferences.user_id == current_user.id)
    )
    prefs = result.scalars().first()
    if not prefs:
        prefs = NotificationPreferences(user_id=current_user.id)
        db.add(prefs)
        await db.commit()
        await db.refresh(prefs)
    return prefs


@router.put("/notifications", response_model=NotificationPreferencesResponse)
async def update_notification_preferences(
    update_data: NotificationPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update notification preferences."""
    result = await db.execute(
        select(NotificationPreferences).where(NotificationPreferences.user_id == current_user.id)
    )
    prefs = result.scalars().first()
    if not prefs:
        prefs = NotificationPreferences(user_id=current_user.id)
        db.add(prefs)

    for field, val in update_data.model_dump(exclude_unset=True).items():
        setattr(prefs, field, val)

    await db.commit()
    await db.refresh(prefs)
    return prefs
