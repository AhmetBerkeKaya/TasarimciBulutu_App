from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import datetime
from enum import Enum

# user.py'den bu şemayı import ettiğimizden emin olalım
from .user import UserInResponse

# ProjectStatus enum'ı, projenin durumunu belirtir
class ProjectStatus(str, Enum):
    open = "open"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"

# Projelerin ortak temel alanlarını tutan şema
class ProjectBase(BaseModel):
    title: str
    description: Optional[str] = None
    category: Optional[str] = None
    budget_min: Optional[float] = None
    budget_max: Optional[float] = None
    deadline: Optional[datetime] = None

# Yeni bir proje oluştururken istemciden (Flutter'dan) alınacak veriler
class ProjectCreate(ProjectBase):
    # Base'deki tüm alanları alır, ek olarak bir şeye gerek yok
    pass

# Bir projeyi güncellerken alınacak veriler. Hepsi opsiyonel.
class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    budget_min: Optional[float] = None
    budget_max: Optional[float] = None
    deadline: Optional[datetime] = None
    status: Optional[ProjectStatus] = None

# API'den bir proje verisi döndürülürken kullanılacak tam şema
class Project(ProjectBase):
    id: UUID4
    status: ProjectStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    owner: UserInResponse # Proje sahibinin temel bilgilerini de içerir

    class Config:
        from_attributes = True