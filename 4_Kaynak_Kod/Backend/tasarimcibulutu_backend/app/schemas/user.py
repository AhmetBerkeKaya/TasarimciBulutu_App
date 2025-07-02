# app/schemas/user.py
from pydantic import BaseModel, EmailStr, UUID4
from typing import Optional
from datetime import datetime
from enum import Enum

# Bu enum, FastAPI'nin string'leri doğrulaması için kullanılır.
class UserRole(str, Enum):
    admin = "admin"
    freelancer = "freelancer"
    client = "client"

# Temel kullanıcı bilgileri
class UserBase(BaseModel):
    email: EmailStr
    name: str
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    phone_number: Optional[str] = None

# Kullanıcı oluşturma şeması
class UserCreate(UserBase):
    password: str
    role: UserRole = UserRole.freelancer # Varsayılan rol

# Kullanıcı güncelleme şeması
class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    phone_number: Optional[str] = None

# API'den dönecek tam kullanıcı modeli
class User(UserBase):
    id: UUID4
    role: UserRole
    is_verified: bool
    created_at: datetime # Doğru tip
    updated_at: datetime # Doğru tip

    # Bu ayar, SQLAlchemy modelinden Pydantic modeline otomatik dönüşüm yapılmasını sağlar.
    class Config:
        from_attributes = True

# app/schemas/user.py - Dosyanın en altına ekle

class UserInResponse(BaseModel):
    id: UUID4
    name: str
    profile_picture: Optional[str] = None

    class Config:
        from_attributes = True