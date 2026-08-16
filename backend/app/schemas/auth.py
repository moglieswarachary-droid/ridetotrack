from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class TokenRefreshRequest(BaseModel):
    refresh_token: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, description="Password must be at least 6 characters")
    full_name: str = Field(..., min_length=2, max_length=100)
    phone_number: Optional[str] = None


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    reset_code: str
    new_password: str = Field(..., min_length=6)


class PasswordChangeRequest(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6)
