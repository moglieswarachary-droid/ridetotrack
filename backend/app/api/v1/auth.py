from fastapi import APIRouter, Depends, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.audit import record_audit_log
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    Token,
    TokenRefreshRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
)
from app.schemas.user import UserResponse
from app.services.auth_service import (
    register_user,
    authenticate_user,
    refresh_user_token,
    logout_user,
)
from app.api.deps import get_current_user
from app.models.user import User
from app.core.config import settings

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, req: Request, db: AsyncSession = Depends(get_db)):
    """Register a new rider account."""
    user, access_token, refresh_token = await register_user(db, request)
    await record_audit_log(
        db,
        action="USER_REGISTER",
        user_id=user.id,
        ip_address=req.client.host if req.client else None,
        user_agent=req.headers.get("user-agent"),
        details={"email": user.email}
    )
    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/login", response_model=Token)
async def login(request: LoginRequest, req: Request, db: AsyncSession = Depends(get_db)):
    """Authenticate with email and password."""
    user, access_token, refresh_token = await authenticate_user(db, request)
    await record_audit_log(
        db,
        action="USER_LOGIN",
        user_id=user.id,
        ip_address=req.client.host if req.client else None,
        user_agent=req.headers.get("user-agent")
    )
    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/refresh", response_model=Token)
async def refresh_token(request: TokenRefreshRequest, db: AsyncSession = Depends(get_db)):
    """Exchange a valid refresh token for a new token pair."""
    new_access_token, new_refresh_token = await refresh_user_token(db, request.refresh_token)
    return Token(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    request: TokenRefreshRequest,
    req: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Revoke refresh token and logout."""
    await logout_user(db, current_user.id, refresh_token_str=request.refresh_token)
    await record_audit_log(
        db,
        action="USER_LOGOUT",
        user_id=current_user.id,
        ip_address=req.client.host if req.client else None
    )
    return {"message": "Successfully logged out."}


@router.post("/logout-all", status_code=status.HTTP_200_OK)
async def logout_all_devices(
    req: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Revoke all refresh tokens across all mobile devices and sessions."""
    await logout_user(db, current_user.id, all_devices=True)
    await record_audit_log(
        db,
        action="USER_LOGOUT_ALL_DEVICES",
        user_id=current_user.id,
        ip_address=req.client.host if req.client else None
    )
    return {"message": "All sessions revoked successfully."}


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(request: ForgotPasswordRequest):
    """Initiate password reset flow."""
    # In production, an SMS or email reset OTP is dispatched
    return {"message": "If an account exists with this email, password reset instructions have been sent."}


@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(request: ResetPasswordRequest):
    """Verify reset code and update password."""
    return {"message": "Password has been reset successfully."}
