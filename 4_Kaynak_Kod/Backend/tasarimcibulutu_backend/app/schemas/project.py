# app/schemas/project.py

import uuid
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from ..models.project import ProjectStatus

# from .user import User, UserInResponse # <-- BU SATIRI TAMAMEN SİLİN

class ProjectBase(BaseModel):
    title: str
    description: str
    category: str
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    deadline: Optional[datetime] = None

class ProjectCreate(ProjectBase):
    pass

class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    deadline: Optional[datetime] = None
    status: Optional[ProjectStatus] = None

class ProjectInReview(BaseModel):
    id: uuid.UUID
    title: str
    
    model_config = ConfigDict(from_attributes=True)
    
class Project(ProjectBase):
    id: uuid.UUID
    user_id: uuid.UUID
    status: ProjectStatus
    created_at: datetime

    # --- DEĞİŞİKLİK BURADA ---
    # owner alanının tipini string olarak verin.
    owner: 'UserInResponse'

    # Bu ayar, SQLAlchemy modelinden Pydantic modeline otomatik dönüşümü sağlar.
    model_config = ConfigDict(from_attributes=True)