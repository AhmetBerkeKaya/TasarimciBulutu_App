# app/crud/review.py
import uuid
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app import models, schemas

def get_review_by_reviewer_and_project(db: Session, reviewer_id: uuid.UUID, project_id: uuid.UUID):
    """Kullanıcının bir proje için daha önce yorum yapıp yapmadığını kontrol eder."""
    return db.query(models.Review).filter(
        and_(
            models.Review.reviewer_id == reviewer_id,
            models.Review.project_id == project_id
        )
    ).first()

def create_review(db: Session, review: schemas.ReviewCreate, reviewer_id: uuid.UUID) -> models.Review:
    """Yeni bir değerlendirme oluşturur."""
    db_review = models.Review(
        **review.model_dump(),
        reviewer_id=reviewer_id
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review