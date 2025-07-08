# app/schemas/application.py

from pydantic import BaseModel, UUID4, ConfigDict
from typing import Optional
from datetime import datetime
from enum import Enum
from .user import UserInResponse

# --- YENİ EKLENEN BASİT ŞEMA ---
# Bu şema, bir başvurunun içinde proje bilgisi gösterirken döngüye girmeyi engeller.
class ProjectInApplication(BaseModel):
    id: UUID4
    title: str
    owner: UserInResponse # Proje sahibinin sadece temel bilgisi yeterli

    class Config:
        from_attributes = True
# --- BİTTİ ---

class ApplicationStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"

class ApplicationCreate(BaseModel):
    project_id: UUID4
    cover_letter: Optional[str] = None
    proposed_budget: Optional[float] = None
    proposed_duration: Optional[int] = None

class ApplicationUpdate(BaseModel):
    status: Optional[ApplicationStatus] = None

class ApplicationStatusUpdate(BaseModel):
    status: ApplicationStatus

class Application(BaseModel):
    id: UUID4
    project_id: UUID4
    cover_letter: Optional[str] = None
    proposed_budget: Optional[float] = None
    proposed_duration: Optional[int] = None
    status: ApplicationStatus
    created_at: datetime
    freelancer: UserInResponse
    
    # --- DEĞİŞİKLİK BURADA ---
    # Artık tam Project şeması yerine, döngüye neden olmayan basit şemayı kullanıyoruz.
    project: ProjectInApplication

    class Config:
        from_attributes = True
