# app/schemas/application.py
from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import datetime
from enum import Enum
from .user import UserInResponse # user.py'den UserInResponse'u import ediyoruz
from .project import Project as ProjectSchema # Artık ana Project şemasını kullanıyoruz

# ApplicationStatus enum'ı burada tanımlanabilir
class ApplicationStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"

# Bu şema, yeni bir başvuru oluştururken kullanılır.
class ApplicationCreate(BaseModel):
    project_id: UUID4
    cover_letter: Optional[str] = None
    proposed_budget: Optional[float] = None
    proposed_duration: Optional[int] = None

# Bu şema, bir başvuruyu güncellerken kullanılır.
class ApplicationUpdate(BaseModel):
    status: Optional[ApplicationStatus] = None

# Bu şema, API'den bir başvuru verisi dönerken kullanılır.
class Application(BaseModel):
    id: UUID4
    project_id: UUID4
    cover_letter: Optional[str] = None
    proposed_budget: Optional[float] = None
    proposed_duration: Optional[int] = None
    status: ApplicationStatus
    created_at: datetime
    freelancer: UserInResponse # Artık yanıtımızda freelancer'ın temel bilgileri de olacak
    project: ProjectSchema # <-- Artık ProjectInApplicationResponse yerine bunu kullanıyoruz

    class Config:
        from_attributes = True