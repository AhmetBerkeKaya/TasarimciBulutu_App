# app/schemas/user.py
from pydantic import BaseModel, EmailStr, UUID4
from typing import List, Optional
from datetime import datetime
from enum import Enum
from .skill import Skill as SkillSchema
from .portfolio import PortfolioItem as PortfolioItemSchema
from .work_experience import WorkExperience as WorkExperienceSchema
from app.schemas.test_result import TestResult

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
    profile_picture_url: Optional[str] = None # <-- Buraya ekle
    phone_number: Optional[str] = None

# Kullanıcı oluşturma şeması
class UserCreate(UserBase):
    password: str
    role: UserRole = UserRole.freelancer # Varsayılan rol

# Kullanıcı güncelleme şeması
class UserUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    phone_number: Optional[str] = None
    profile_picture: Optional[str] = None

# API'den dönecek tam kullanıcı modeli
class User(UserBase):
    id: UUID4
    role: UserRole
    is_verified: bool
    created_at: datetime # Doğru tip
    updated_at: datetime # Doğru tip
    skills: List[SkillSchema] = []
    portfolio_items: List[PortfolioItemSchema] = [] 
    work_experiences: List[WorkExperienceSchema] = [] # <-- YENİ SATIR
    test_results: List[TestResult] = []

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

class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str