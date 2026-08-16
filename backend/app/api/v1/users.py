from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate
from app.schemas.auth import PasswordChangeRequest
from app.core.security import verify_password, get_password_hash
from app.core.audit import record_audit_log

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Retrieve current authenticated user profile."""
    return current_user


@router.put("/me", response_model=UserResponse)
async def update_profile(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update profile details (name, phone, avatar)."""
    if update_data.full_name is not None:
        current_user.full_name = update_data.full_name
    if update_data.phone_number is not None:
        current_user.phone_number = update_data.phone_number
    if update_data.avatar_url is not None:
        current_user.avatar_url = update_data.avatar_url

    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.put("/me/password", status_code=status.HTTP_200_OK)
async def change_password(
    request: PasswordChangeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Change account password."""
    if not verify_password(request.old_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password does not match."
        )

    current_user.hashed_password = get_password_hash(request.new_password)
    await db.commit()
    await record_audit_log(db, action="PASSWORD_CHANGE", user_id=current_user.id)
    return {"message": "Password changed successfully."}


@router.delete("/me", status_code=status.HTTP_200_OK)
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Permanently delete user account and cascade delete all ride history and bikes."""
    await record_audit_log(db, action="ACCOUNT_DELETED", user_id=current_user.id)
    await db.delete(current_user)
    await db.commit()
    return {"message": "Account and all associated location/ride data have been permanently deleted."}
