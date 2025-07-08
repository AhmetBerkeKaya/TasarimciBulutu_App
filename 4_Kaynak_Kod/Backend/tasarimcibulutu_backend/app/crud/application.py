from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from uuid import UUID
from typing import List
from datetime import timezone, datetime
from app.models.application import ApplicationStatus
from app.models.project import ProjectStatus

def get_application(db: Session, application_id: str):
    return db.query(models.Application).filter(models.Application.id == application_id).first()


def get_applications(db: Session, skip: int = 0, limit: int = 100) -> List[models.Application]:
    return db.query(models.Application).offset(skip).limit(limit).all()

def update_application_status(
    db: Session,
    application_id: UUID,
    new_status: ApplicationStatus,
    current_user_id: UUID
) -> models.Application | None:
    """
    Bir başvurunun durumunu günceller.
    Sadece proje sahibi bu işlemi yapabilir.
    """
    # Başvuruyu bul
    application = db.query(models.Application).filter(
        models.Application.id == application_id
    ).first()
    
    if not application:
        return None
    
    # Projeyi de getir
    project = db.query(models.Project).filter(
        models.Project.id == application.project_id
    ).first()
    
    if not project:
        return None
    
    # Sadece proje sahibi başvuru durumunu değiştirebilir
    if project.user_id != current_user_id:
        return None
    
    # Başvuru durumunu güncelle
    application.status = new_status
    
    # *** ÖNEMLİ: Eğer başvuru KABUL edilirse proje durumunu IN_PROGRESS yap ***
    if new_status == ApplicationStatus.accepted:
        # DÜZELTME: Enum value'yu string olarak kaydet
        project.status = models.ProjectStatus.IN_PROGRESS.value
        
        # Diğer tüm bekleyen başvuruları otomatik olarak reddet
        other_applications = db.query(models.Application).filter(
            models.Application.project_id == application.project_id,
            models.Application.id != application_id,
            models.Application.status == ApplicationStatus.pending
        ).all()
        
        for other_app in other_applications:
            other_app.status = ApplicationStatus.rejected
    
    # Değişiklikleri kaydet
    db.commit()
    db.refresh(application)
    db.refresh(project)
    
    return application

def get_applications_by_project(db: Session, project_id: str) -> List[models.Application]:
    """
    Belirli bir projeye gelen tüm başvuruları getirir.
    Freelancer ve proje bilgilerini de dahil eder.
    """
    return db.query(models.Application).options(
        joinedload(models.Application.freelancer),  # Freelancer bilgilerini getir
        joinedload(models.Application.project)      # Proje bilgilerini getir
    ).filter(models.Application.project_id == project_id).all()

def get_applications_by_freelancer(db: Session, freelancer_id: str) -> List[models.Application]:
    """
    Belirli bir freelancer'ın tüm başvurularını getirir.
    """
    return db.query(models.Application).options(
        joinedload(models.Application.project),
        joinedload(models.Application.freelancer)
    ).filter(models.Application.freelancer_id == freelancer_id).all()


def create_application(db: Session, application: schemas.ApplicationCreate, freelancer_id: UUID) -> models.Application:
    db_application = models.Application(
        project_id=application.project_id,
        freelancer_id=freelancer_id,
        cover_letter=application.cover_letter,
        proposed_budget=application.proposed_budget,
        proposed_duration=application.proposed_duration,
        status=ApplicationStatus.PENDING,
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

def get_accepted_application_for_project(db: Session, project_id: UUID) -> models.Application | None:
    """
    Belirli bir proje için kabul edilmiş ('accepted') başvuruyu getirir.
    """
    return db.query(models.Application).filter(
        models.Application.project_id == project_id,
        models.Application.status == models.ApplicationStatus.accepted
    ).first()