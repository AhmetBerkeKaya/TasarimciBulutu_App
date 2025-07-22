# app/schemas/user.py

import uuid
from pydantic import BaseModel, ConfigDict, EmailStr, field_validator
from typing import List, Optional
from datetime import datetime
import phonenumbers
from .skill import Skill as SkillSchema
from .portfolio import PortfolioItem as PortfolioItemSchema
from .work_experience import WorkExperience as WorkExperienceSchema
from .test_result import TestResult as TestResultSchema
from ..models.user import UserRole 

# ... (Mevcut şemalarınızda değişiklik yok) ...
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
    phone_number: str
    @field_validator('phone_number')
    def validate_phone_number(cls, v):
        try:
            parsed_number = phonenumbers.parse(v, None)
            if not phonenumbers.is_valid_number(parsed_number):
                raise ValueError("Geçersiz telefon numarası formatı.")
            return phonenumbers.format_number(
                parsed_number, phonenumbers.PhoneNumberFormat.E164
            )
        except phonenumbers.phonenumberutil.NumberParseException:
            raise ValueError("Geçersiz telefon numarası formatı.")
        except Exception as e:
            raise ValueError(f"Telefon numarası doğrulanırken bir hata oluştu: {e}")

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    phone_number: Optional[str] = None

class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str

# --- YENİ: ŞİFRE SIFIRLAMA İÇİN ŞEMALAR ---
class PasswordRecoveryRequest(BaseModel):
    email: EmailStr

class PasswordResetRequest(BaseModel):
    token: str
    new_password: str
# --- BİTTİ ---

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
    reviews_received: List['Review'] = []
    model_config = ConfigDict(from_attributes=True)

class UserInResponse(UserSummary):
    pass
