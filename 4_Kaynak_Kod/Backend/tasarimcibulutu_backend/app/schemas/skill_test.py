from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import datetime


class SkillTestBase(BaseModel):
    title: str
    description: Optional[str] = None
    software: Optional[str] = None


class SkillTestCreate(SkillTestBase):
    pass


class SkillTestUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    software: Optional[str] = None


class SkillTest(SkillTestBase):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True
