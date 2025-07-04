# app/crud/work_experience.py
from sqlalchemy.orm import Session
from uuid import UUID
from app import models, schemas

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

# --- YENİ EKLENEN FONKSİYONLAR ---
def update_experience(db: Session, db_experience: models.WorkExperience, experience_in: schemas.WorkExperienceUpdate) -> models.WorkExperience:
    update_data = experience_in.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_experience, key, value)
    db.add(db_experience)
    db.commit()
    db.refresh(db_experience)
    return db_experience

def delete_experience(db: Session, db_experience: models.WorkExperience) -> models.WorkExperience:
    db.delete(db_experience)
    db.commit()
    return db_experience