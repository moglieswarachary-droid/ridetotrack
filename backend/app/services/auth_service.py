from datetime import datetime, timezone, timedelta
from typing import Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status
from app.models.user import User, RefreshToken, UserSettings, NotificationPreferences
from app.schemas.auth import RegisterRequest, LoginRequest, PasswordChangeRequest
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, decode_token
from app.core.config import settings


async def register_user(db: AsyncSession, request: RegisterRequest) -> Tuple[User, str, str]:
    # Check if email exists
    result = await db.execute(select(User).where(User.email == request.email.lower()))
    if result.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email address already exists."
        )

    # Check phone number if provided
    if request.phone_number:
        phone_result = await db.execute(select(User).where(User.phone_number == request.phone_number))
        if phone_result.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this phone number already exists."
            )

    new_user = User(
        email=request.email.lower(),
        phone_number=request.phone_number,
        full_name=request.full_name,
        hashed_password=get_password_hash(request.password),
        is_active=True,
        is_verified=True,
    )
    db.add(new_user)
    await db.flush()

    # Create default user settings & notification preferences
    settings_entry = UserSettings(user_id=new_user.id)
    notif_entry = NotificationPreferences(user_id=new_user.id)
    db.add(settings_entry)
    db.add(notif_entry)

    # Issue tokens
    access_token = create_access_token(new_user.id)
    refresh_token = create_refresh_token(new_user.id)

    refresh_entry = RefreshToken(
        user_id=new_user.id,
        token=refresh_token,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(refresh_entry)
    await db.commit()
    await db.refresh(new_user)

    return new_user, access_token, refresh_token


async def authenticate_user(db: AsyncSession, request: LoginRequest) -> Tuple[User, str, str]:
    result = await db.execute(select(User).where(User.email == request.email.lower()))
    user = result.scalars().first()

    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This user account has been deactivated.",
        )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    refresh_entry = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(refresh_entry)
    await db.commit()

    return user, access_token, refresh_token


async def refresh_user_token(db: AsyncSession, refresh_token_str: str) -> Tuple[str, str]:
    payload = decode_token(refresh_token_str)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token.",
        )

    user_id = payload.get("sub")
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token == refresh_token_str,
            RefreshToken.user_id == user_id,
            RefreshToken.is_revoked == False
        )
    )
    token_record = result.scalars().first()
    if not token_record:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has been revoked or is not recognized.",
        )

    # Revoke old refresh token and issue a fresh pair
    token_record.is_revoked = True
    new_access_token = create_access_token(user_id)
    new_refresh_token = create_refresh_token(user_id)

    new_token_record = RefreshToken(
        user_id=user_id,
        token=new_refresh_token,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(new_token_record)
    await db.commit()

    return new_access_token, new_refresh_token


async def logout_user(db: AsyncSession, user_id: str, refresh_token_str: Optional[str] = None, all_devices: bool = False):
    if all_devices:
        result = await db.execute(
            select(RefreshToken).where(RefreshToken.user_id == user_id, RefreshToken.is_revoked == False)
        )
        for token in result.scalars().all():
            token.is_revoked = True
    elif refresh_token_str:
        result = await db.execute(
            select(RefreshToken).where(RefreshToken.token == refresh_token_str)
        )
        token_record = result.scalars().first()
        if token_record:
            token_record.is_revoked = True
    await db.commit()
