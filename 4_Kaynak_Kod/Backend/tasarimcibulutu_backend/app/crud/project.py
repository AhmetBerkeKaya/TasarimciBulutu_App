from sqlalchemy.orm import Session
from uuid import UUID, uuid4 # uuid4'ü import et
from typing import List
from datetime import datetime, timezone
from sqlalchemy import or_
import uuid
# app/crud/project.py
from sqlalchemy.orm import Session, joinedload # <-- joinedload'u import et
from typing import List
from datetime import datetime, timezone

from app import models, schemas
from app.models.project import ProjectStatus # <-- DÜZELTİLMİŞ IMPORT

def get_project(db: Session, project_id: UUID) -> models.Project | None:
    """
    ID'ye göre tek bir projeyi getirir.
    İlişkili olduğu tüm verileri (sahibi, başvurular, yorumlar) tek bir sorguda çeker.
    """
    return db.query(models.Project).options(
        # joinedload kullanarak N+1 sorgu problemini önlüyoruz
        joinedload(models.Project.owner),
        joinedload(models.Project.applications).joinedload(models.Application.freelancer), # Başvuruları ve başvuran freelancer'ı çek
        joinedload(models.Project.reviews).joinedload(models.Review.reviewer) # Yorumları ve yorum yapanı çek
    ).filter(models.Project.id == project_id).first()

def get_projects(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    search: str | None = None,
    category: str | None = None
) -> List[models.Project]:
    # Ana sorguyu başlat
    query = db.query(models.Project).options(joinedload(models.Project.owner))

    # Eğer arama metni varsa, başlıkta veya açıklamada ara
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                models.Project.title.ilike(search_term),
                models.Project.description.ilike(search_term)
            )
        )

    # Eğer kategori filtresi varsa, uygula
    if category:
        query = query.filter(models.Project.category == category)

    # Sonuçları sırala, sayfalama yap ve döndür
    projects = query.order_by(models.Project.created_at.desc()).offset(skip).limit(limit).all()
    # Her proje için status'u string olarak ayarla
    for project in projects:
        project.status = project.status.value if hasattr(project.status, 'value') else project.status
    
    return projects

def get_projects_by_user(db: Session, user_id: UUID) -> List[models.Project]:
    projects = db.query(models.Project).options(
        joinedload(models.Project.owner)
    ).filter(models.Project.user_id == user_id).order_by(models.Project.created_at.desc()).all()
    
    return projects

# --- YENİ EKLENECEK FONKSİYON ---
def get_projects_for_freelancer(db: Session, user_id: UUID) -> List[models.Project]:
    """
    Bir freelancer'ın başvurusunun kabul edildiği tüm projeleri getirir.
    """
    # Application tablosu üzerinden Project tablosuna bir join işlemi yapıyoruz.
    return db.query(models.Project).join(models.Application).filter(
        models.Application.freelancer_id == user_id,
        models.Application.status == 'accepted'
    ).order_by(models.Project.updated_at.desc()).all()
# --- BİTTİ ---


def create_project(db: Session, project: schemas.ProjectCreate, owner_id: UUID) -> models.Project:
    # ... (bu fonksiyon aynı kalır)
    current_time = datetime.now(timezone.utc)
    db_project = models.Project(
        user_id=owner_id,
        title=project.title,
        description=project.description,
        category=project.category,
        budget_min=project.budget_min,
        budget_max=project.budget_max,
        deadline=project.deadline,
        status=models.ProjectStatus.OPEN.value,
        created_at=current_time,
        updated_at=current_time,
    )
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

# ... (update ve delete fonksiyonları)
def update_project(db: Session, project_id: str, project_update: schemas.ProjectUpdate):
    db_project = get_project(db, project_id)
    if not db_project:
        return None
    update_data = project_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_project, key, value)
    db.commit()
    db.refresh(db_project)
    return db_project

def delete_project(db: Session, project_id: str):
    db_project = get_project(db, project_id)
    if not db_project:
        return None
    db.delete(db_project)
    db.commit()
    return db_project

def complete_project(db: Session, project_id: uuid.UUID, owner_id: uuid.UUID) -> models.Project | None:
    """
    Bir projeyi 'completed' olarak işaretler. Sadece projenin sahibi bu işlemi yapabilir.
    """
    db_project = db.query(models.Project).filter(models.Project.id == project_id).first()
    
    if db_project and db_project.user_id == owner_id:
        db_project.status = models.ProjectStatus.COMPLETED
        db.commit()
        db.refresh(db_project)
        
        # Status'u string olarak ayarla
        db_project.status = db_project.status.value if hasattr(db_project.status, 'value') else db_project.status
        
        return db_project
        
    return None