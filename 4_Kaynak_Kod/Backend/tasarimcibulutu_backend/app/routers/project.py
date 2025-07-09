# app/routers/project.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from typing import Optional
from pydantic import UUID4

from app import crud, schemas, database
from app.dependencies import get_current_user
from app.models.user import User as UserModel, UserRole # <-- DÜZELTİLMİŞ IMPORT

router = APIRouter(
    prefix="/projects",
    tags=["projects"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.Project, status_code=status.HTTP_201_CREATED)
def create_project(
    project: schemas.ProjectCreate, 
    db: Session = Depends(get_db), 
    current_user: UserModel = Depends(get_current_user)
):
    if current_user.role != UserRole.client:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Only clients can create projects."
        )
    return crud.project.create_project(db=db, project=project, owner_id=current_user.id)

@router.get("/me", response_model=List[schemas.Project])
def read_my_projects(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış kullanıcının projelerini rolüne göre getirir.
    - Eğer kullanıcı bir 'client' (firma) ise, kendi oluşturduğu projeleri getirir.
    - Eğer kullanıcı bir 'freelancer' ise, başvurusunun kabul edildiği projeleri getirir.
    """
    if current_user.role == UserRole.client:
        return crud.project.get_projects_by_user(db, user_id=current_user.id)
    elif current_user.role == UserRole.freelancer:
        return crud.project.get_projects_for_freelancer(db, user_id=current_user.id)
    else:
        # Diğer roller (örn: admin) için boş liste dönebilir veya farklı bir mantık uygulanabilir
        return []


@router.get("/", response_model=List[schemas.Project])
def read_projects(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    # Yeni opsiyonel filtreleme parametreleri
    search: Optional[str] = None,
    category: Optional[str] = None
):
    projects = crud.project.get_projects(
        db=db, skip=skip, limit=limit, search=search, category=category
    )
    return projects

@router.get("/{project_id}", response_model=schemas.Project)
def read_project(project_id: UUID, db: Session = Depends(get_db)):
    db_project = crud.get_project(db=db, project_id=project_id)
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project


@router.get("/{project_id}/applications", response_model=List[schemas.Application])
def get_project_applications(
    project_id: UUID4,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Belirli bir projeye gelen başvuruları getirir.
    Sadece proje sahibi bu endpoint'i kullanabilir.
    """
    # Önce projeyi bul
    project = crud.project.get_project(db, project_id=project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    # Sadece proje sahibi başvuruları görebilir
    if project.user_id != current_user.id:
        raise HTTPException(
            status_code=403, 
            detail="You can only view applications for your own projects"
        )
    
    # Projeye gelen başvuruları getir
    return crud.application.get_applications_by_project(db, project_id=str(project_id))

@router.put("/{project_id}", response_model=schemas.Project)
def update_project(project_id: UUID, project_update: schemas.ProjectUpdate, db: Session = Depends(get_db)):
    updated_project = crud.update_project(db=db, project_id=project_id, project_update=project_update)
    if not updated_project:
        raise HTTPException(status_code=404, detail="Project not found")
    return updated_project

@router.delete("/{project_id}", response_model=schemas.Project)
def delete_project(project_id: UUID, db: Session = Depends(get_db)):
    deleted_project = crud.delete_project(db=db, project_id=project_id)
    if not deleted_project:
        raise HTTPException(status_code=404, detail="Project not found")
    return deleted_project

@router.put("/{project_id}/complete", response_model=schemas.Project)
def mark_project_as_completed(
    project_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Bir projeyi 'Tamamlandı' olarak işaretler.
    Bu işlemi sadece projeyi oluşturan kullanıcı (firma) yapabilir.
    """
    updated_project = crud.project.complete_project(
        db=db, project_id=project_id, owner_id=current_user.id
    )
    
    if not updated_project:
        # Ya proje bulunamadı ya da kullanıcı projenin sahibi değil
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found or you are not the owner."
        )
        
    return updated_project