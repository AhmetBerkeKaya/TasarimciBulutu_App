from pydantic import BaseModel, UUID4
from typing import Optional
from enum import Enum
from datetime import datetime

class ProjectStatus(str, Enum):
    open = "open"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"

class ProjectBase(BaseModel):
    title: str
    description: Optional[str] = None
    category: Optional[str] = None
    budget_min: Optional[float] = None
    budget_max: Optional[float] = None
    deadline: Optional[datetime] = None
    status: Optional[ProjectStatus] = ProjectStatus.open

class ProjectCreate(BaseModel):
    # user_id: UUID4 
    title: str
    description: str
    category: str
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    deadline: Optional[datetime] = None
    # status: ProjectStatus # <--  OTOMATİK AYARLAYACAĞIZ

class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    budget_min: Optional[float] = None
    budget_max: Optional[float] = None
    deadline: Optional[datetime] = None
    status: Optional[ProjectStatus] = None

class Project(ProjectBase):
    id: UUID4
    user_id: UUID4  
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
