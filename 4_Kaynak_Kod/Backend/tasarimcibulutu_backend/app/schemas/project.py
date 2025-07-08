# app/schemas/project.py

from pydantic import BaseModel, ConfigDict, UUID4
from typing import Optional, List
from datetime import datetime
from app.models.project import ProjectStatus
from .user import User, UserInResponse # User ve UserInResponse'u import et
from .review import Review

# --- YENİ EKLENEN BASİT ŞEMA ---
# Bu şema, bir projenin içinde başvuru listelerken döngüye girmeyi engeller.
class ApplicationInProject(BaseModel):
    id: UUID4
    status: str # enum yerine basit string kullanabiliriz
    freelancer: UserInResponse # Başvuranın sadece temel bilgisi

    class Config:
        from_attributes = True
# --- BİTTİ ---

class ProjectBase(BaseModel):
    title: str
    description: Optional[str] = None
    category: Optional[str] = None
    budget_min: Optional[float] = None
    budget_max: Optional[float] = None
    deadline: Optional[datetime] = None

class ProjectCreate(ProjectBase):
    pass

class ProjectUpdate(ProjectBase):
    pass

class Project(ProjectBase):
    id: UUID4
    user_id: UUID4
    status: ProjectStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    owner: User
    
    # --- DEĞİŞİKLİK BURADA ---
    # Artık tam Application listesi yerine, döngüye neden olmayan basit listeyi kullanıyoruz.
    applications: List[ApplicationInProject] = []
    reviews: List[Review] = []

    class Config:
        from_attributes = True

# Dosyanın sonundaki .model_rebuild() satırlarını siliyoruz, bunu __init__.py'de yapacağız.