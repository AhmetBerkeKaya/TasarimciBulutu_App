# app/routers/project.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

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
    Retrieve projects for the current logged in user.
    """
    # crud/project.py içindeki get_projects_by_user fonksiyonunu kullanıyoruz
    return crud.project.get_projects_by_user(db, user_id=current_user.id)


@router.get("/", response_model=List[schemas.Project])
def read_projects(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    projects = crud.get_projects(db=db, skip=skip, limit=limit)
    return projects


@router.get("/{project_id}", response_model=schemas.Project)
def read_project(project_id: UUID, db: Session = Depends(get_db)):
    db_project = crud.get_project(db=db, project_id=project_id)
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project


@router.get("/{project_id}/applications", response_model=List[schemas.Application])
def read_project_applications(
    project_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Retrieve all applications for a specific project.
    Only the project owner can view applications.
    """
    # Önce projenin var olup olmadığını ve sahibini kontrol et
    db_project = crud.project.get_project(db, project_id=project_id)
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")

    # Giriş yapan kullanıcı projenin sahibi değilse, yetkisi yok hatası ver
    if db_project.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view these applications")

    # crud/application.py içindeki fonksiyonu kullanarak başvuruları getir
    return crud.application.get_applications_by_project(db, project_id=project_id)

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
