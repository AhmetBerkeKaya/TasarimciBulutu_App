# app/schemas/user.py

import uuid
from pydantic import BaseModel, ConfigDict, EmailStr
from typing import List, Optional
from datetime import datetime
# from .review import Review as ReviewSchema # <-- BU SATIRI SİLİN VEYA YORUMA ALIN
from .skill import Skill as SkillSchema
from .portfolio import PortfolioItem as PortfolioItemSchema
from .work_experience import WorkExperience as WorkExperienceSchema
from .test_result import TestResult as TestResultSchema
from ..models.user import UserRole 

# Önce diğerlerinden bağımsız olan şemaları tanımlayın
class UserSummary(BaseModel):
    id: uuid.UUID
    name: str
    profile_picture_url: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

class UserBase(BaseModel):
    email: EmailStr
    name: str
    role: UserRole
    bio: Optional[str] = None
    profile_picture_url: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    phone_number: Optional[str] = None

class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str

class User(UserBase):
    id: uuid.UUID
    is_verified: bool
    phone_number: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    skills: List[SkillSchema] = []
    portfolio_items: List[PortfolioItemSchema] = []
    work_experiences: List[WorkExperienceSchema] = []
    test_results: List[TestResultSchema] = []
    
    # --- DEĞİŞİKLİK BURADA ---
    # Review şemasını import etmek yerine string olarak referans verin.
    reviews_received: List['Review'] = []

    model_config = ConfigDict(from_attributes=True)

class UserInResponse(UserSummary):
    # UserSummary'den miras alması yeterli.
    # Gelecekte farklı alanlar eklemek isterseniz buraya ekleyebilirsiniz.
    pass