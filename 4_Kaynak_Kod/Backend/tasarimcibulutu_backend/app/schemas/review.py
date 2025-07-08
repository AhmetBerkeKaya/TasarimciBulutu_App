# app/schemas/review.py
import uuid
from pydantic import BaseModel, ConfigDict, Field, UUID4
from datetime import datetime
from .user import User  # Kullanıcı bilgilerini göstermek için

class ProjectInReview(BaseModel):
    id: UUID4
    title: str

    class Config:
        from_attributes = True
        
class ReviewBase(BaseModel):
    rating: int = Field(..., gt=0, lt=6) # 1-5 arası puanlama için
    comment: str | None = None

class ReviewCreate(ReviewBase):
    project_id: uuid.UUID
    reviewee_id: uuid.UUID # Değerlendirilen kişinin ID'si

# API'dan yanıt olarak dönecek tam Review modeli
class Review(ReviewBase):
    id: uuid.UUID
    reviewer: User # Değerlendirmeyi yapanın tüm bilgileri
    project: ProjectInReview
    model_config = ConfigDict(from_attributes=True)

