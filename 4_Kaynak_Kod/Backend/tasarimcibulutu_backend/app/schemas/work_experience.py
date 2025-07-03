# app/schemas/work_experience.py
from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import date # Sadece tarih için

class WorkExperienceBase(BaseModel):
    title: str
    company_name: str
    start_date: date
    end_date: Optional[date] = None
    description: Optional[str] = None

class WorkExperienceCreate(WorkExperienceBase):
    pass

class WorkExperience(WorkExperienceBase):
    id: UUID4
    user_id: UUID4

    class Config:
        from_attributes = True