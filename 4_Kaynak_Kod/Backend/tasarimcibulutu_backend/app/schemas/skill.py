# app/schemas/skill.py
from pydantic import BaseModel, UUID4

class SkillBase(BaseModel):
    name: str

class SkillCreate(SkillBase):
    pass

class Skill(SkillBase):
    id: UUID4

    class Config:
        from_attributes = True