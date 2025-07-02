from sqlalchemy.orm import Session
from app import models, schemas
from uuid import UUID
from typing import List
from datetime import timezone, datetime

def get_application(db: Session, application_id: str):
    return db.query(models.Application).filter(models.Application.id == application_id).first()


def get_applications(db: Session, skip: int = 0, limit: int = 100) -> List[models.Application]:
    return db.query(models.Application).offset(skip).limit(limit).all()


def get_applications_by_project(db: Session, project_id: str) -> List[models.Application]:
    return db.query(models.Application).filter(models.Application.project_id == project_id).all()


def get_applications_by_freelancer(db: Session, freelancer_id: str) -> List[models.Application]:
    return db.query(models.Application).filter(models.Application.freelancer_id == freelancer_id).all()


def create_application(db: Session, application: schemas.ApplicationCreate, freelancer_id: UUID) -> models.Application:
    db_application = models.Application(
        project_id=application.project_id,
        freelancer_id=freelancer_id,
        cover_letter=application.cover_letter,
        proposed_budget=application.proposed_budget,
        proposed_duration=application.proposed_duration,
        # status modelde default olarak 'pending'
        created_at=datetime.now(timezone.utc) # <-- BU SATIRIN MEVCUT OLDUĞUNDAN EMİN OL
    )
    db.add(db_application)
    db.commit()
    db.refresh(db_application)
    return db_application

def update_application(db: Session, application_id: str, application_update: schemas.ApplicationUpdate):
    db_application = get_application(db, application_id)
    if not db_application:
        return None
    update_data = application_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_application, key, value)
    db.commit()
    db.refresh(db_application)
    return db_application


def delete_application(db: Session, application_id: str):
    db_application = get_application(db, application_id)
    if not db_application:
        return None
    db.delete(db_application)
    db.commit()
    return db_application
