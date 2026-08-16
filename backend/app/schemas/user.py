from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr


class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    phone_number: Optional[str] = None
    avatar_url: Optional[str] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    avatar_url: Optional[str] = None


class UserResponse(UserBase):
    id: str
    is_active: bool
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True
