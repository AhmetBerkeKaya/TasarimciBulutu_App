# app/crud/work_experience.py
from sqlalchemy.orm import Session
from uuid import UUID

# --- DOĞRU IMPORT'LAR ---
from app.models import work_experience as work_experience_model
from app.schemas import work_experience as work_experience_schema
# --- BİTTİ ---

def create_user_experience(db: Session, experience: work_experience_schema.WorkExperienceCreate, user_id: UUID) -> work_experience_model.WorkExperience:
    db_experience = work_experience_model.WorkExperience(
        **experience.dict(), 
        user_id=user_id
    )
    db.add(db_experience)
    db.commit()
    db.refresh(db_experience)
    return db_experience

# TODO: get, update, delete fonksiyonları buraya eklenebilir.