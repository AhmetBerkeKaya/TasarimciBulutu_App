from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app import crud, schemas
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel, UserRole

router = APIRouter(
    prefix="/projects",
    tags=["projects"]
)

# --- Proje Oluşturma ve Listeleme Endpoint'leri ---
@router.post("/", response_model=schemas.Project, status_code=status.HTTP_201_CREATED)
def create_project(project: schemas.ProjectCreate, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can create projects.")
    return crud.project.create_project(db=db, project=project, owner_id=current_user.id)

@router.get("/me", response_model=List[schemas.Project])
def read_my_projects(db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role == UserRole.client:
        return crud.project.get_projects_by_user(db, user_id=current_user.id)
    elif current_user.role == UserRole.freelancer:
        return crud.project.get_projects_for_freelancer(db, user_id=current_user.id)
    return []

@router.get("/", response_model=List[schemas.Project])
def read_projects(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), search: Optional[str] = None, category: Optional[str] = None):
    return crud.project.get_projects(db=db, skip=skip, limit=limit, search=search, category=category)

@router.get("/{project_id}", response_model=schemas.Project)
def read_project(project_id: UUID, db: Session = Depends(get_db)):
    db_project = crud.project.get_project(db=db, project_id=project_id)
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project

@router.get("/{project_id}/applications", response_model=List[schemas.Application])
def get_project_applications(project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    project = crud.project.get_project(db, project_id=project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view applications for your own projects")
    return crud.application.get_applications_by_project(db, project_id=project_id)


# --- Proje Yaşam Döngüsü Endpoint'leri (Teslim Et, Onayla, Revizyon İste) ---

@router.put("/{project_id}/deliver", response_model=schemas.Project, summary="Freelancer işi teslim eder")
def deliver_project_as_freelancer(project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    
    # --- YENİ TANI KOYMA SATIRI ---
    print(f"\n✅✅✅ /deliver ENDPOINT'İ BAŞARIYLA TETİKLENDİ! Proje ID: {project_id} ✅✅✅\n")
    # --- BİTTİ ---

    if current_user.role != UserRole.freelancer:
        raise HTTPException(status_code=403, detail="Only freelancers can deliver projects.")
    
    updated_project = crud.project.deliver_project(db=db, project_id=project_id, freelancer_id=current_user.id)
    
    if not updated_project:
        raise HTTPException(status_code=404, detail="Project not found, not in progress, or you are not the assigned freelancer.")
        
    return updated_project
@router.put("/{project_id}/accept", response_model=schemas.Project, summary="Firma teslimatı onaylar ve projeyi tamamlar")
def accept_delivery_and_complete_project(project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=403, detail="Only clients can accept deliveries.")
    updated_project = crud.project.accept_and_complete_project(db=db, project_id=project_id, owner_id=current_user.id)
    if not updated_project:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Project is not in progress or you are not the assigned freelancer."
        )
    return updated_project

@router.put("/{project_id}/request-revision", response_model=schemas.Project, summary="Firma revizyon talep eder")
def request_revision_as_client(project_id: UUID, db: Session = Depends(get_db), current_user: UserModel = Depends(get_current_user)):
    if current_user.role != UserRole.client:
        raise HTTPException(status_code=403, detail="Only clients can request revisions.")
    updated_project = crud.project.request_revision(db=db, project_id=project_id, owner_id=current_user.id)
    if not updated_project:
        raise HTTPException(status_code=404, detail="Project not found, not pending review, or you are not the owner.")
    return updated_project