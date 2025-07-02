from sqlalchemy.orm import Session
from uuid import UUID, uuid4 # uuid4'ü import et
from typing import List
from datetime import datetime, timezone

# app/crud/project.py
from sqlalchemy.orm import Session, joinedload # <-- joinedload'u import et
from uuid import UUID, uuid4
from typing import List
from datetime import datetime, timezone

from app import models, schemas
from app.models.project import ProjectStatus # <-- DÜZELTİLMİŞ IMPORT

def get_project(db: Session, project_id: UUID) -> models.Project | None:
    return db.query(models.Project).options(
        joinedload(models.Project.owner) # Tek bir projeyi çekerken bile sahibini getir
    ).filter(models.Project.id == str(project_id)).first()

def get_projects(db: Session, skip: int = 0, limit: int = 100) -> List[models.Project]:
    return db.query(models.Project).options(
        joinedload(models.Project.owner) # <-- EAGER LOADING
    ).order_by(models.Project.created_at.desc()).offset(skip).limit(limit).all()

def get_projects_by_user(db: Session, user_id: UUID) -> List[models.Project]:
    return db.query(models.Project).options(
        joinedload(models.Project.owner) # <-- EAGER LOADING
    ).filter(models.Project.user_id == user_id).order_by(models.Project.created_at.desc()).all()


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
        status=ProjectStatus.open,
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
