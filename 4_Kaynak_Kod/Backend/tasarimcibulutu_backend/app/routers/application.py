# app/routers/application.py

# --- YENİ İMPORTLAR ---
from fastapi import APIRouter, Depends, HTTPException, status, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
# --- BİTTİ ---

from sqlalchemy.orm import Session
from typing import List
from pydantic import UUID4
from app.dependencies import get_current_user
from app.models.user import User as UserModel
from app.models.user import UserRole
from app import crud, schemas, database
from uuid import UUID

# --- BU ROUTER'A ÖZEL LIMITER BAŞLATMA ---
limiter = Limiter(key_func=get_remote_address)
# --- BİTTİ ---

router = APIRouter(
    prefix="/applications",
    tags=["applications"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.Application, status_code=201)
# Bir freelancer'ın saatte 20'den fazla başvuru yapması spam sayılır.
@limiter.limit("20/hour")
def create_application(
    request: Request,
    application: schemas.ApplicationCreate, 
    db: Session = Depends(get_db), 
    current_user: UserModel = Depends(get_current_user)
):
    if current_user.role != UserRole.freelancer:
        raise HTTPException(
            status_code=403,
            detail="Only freelancers can submit applications."
        )
    return crud.application.create_application(
        db=db, application=application, freelancer_id=current_user.id
    )

@router.get("/", response_model=List[schemas.Application])
# Bu endpoint tüm başvuruları listeler, admin paneli için olabilir. Dikkatli kullanılmalı.
@limiter.limit("60/minute")
def read_applications(request: Request, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    applications = crud.application.get_applications(db, skip=skip, limit=limit)
    return applications

@router.get("/me", response_model=List[schemas.Application])
# Kullanıcının kendi başvurularını listelemesi.
@limiter.limit("60/minute")
def read_my_applications(
    request: Request,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    return crud.application.get_applications_by_freelancer(db, freelancer_id=current_user.id)

@router.get("/{application_id}", response_model=schemas.Application)
@limiter.limit("120/minute")
def read_application(request: Request, application_id: UUID4, db: Session = Depends(get_db)):
    db_application = crud.application.get_application(db, application_id=application_id)
    if not db_application:
        raise HTTPException(status_code=404, detail="Application not found")
    return db_application

@router.put("/{application_id}", response_model=schemas.Application)
# Başvuruyu güncellemek nadir bir eylemdir.
@limiter.limit("10/hour")
def update_application(request: Request, application_id: UUID4, application_update: schemas.ApplicationUpdate, db: Session = Depends(get_db)):
    updated_application = crud.application.update_application(db, application_id, application_update)
    if not updated_application:
        raise HTTPException(status_code=404, detail="Application not found")
    return updated_application

@router.delete("/{application_id}", response_model=schemas.Application)
# Başvuruyu silmek daha da nadir bir eylemdir.
@limiter.limit("5/hour")
def delete_application(request: Request, application_id: UUID4, db: Session = Depends(get_db)):
    deleted_application = crud.application.delete_application(db, application_id)
    if not deleted_application:
        raise HTTPException(status_code=404, detail="Application not found")
    return deleted_application

@router.put("/{application_id}/status", response_model=schemas.Application)
# Proje sahibinin başvuruları onaylama/reddetme hızı.
@limiter.limit("30/minute")
def update_application_status(
    request: Request,
    application_id: UUID,
    status_update: schemas.ApplicationStatusUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    updated_application = crud.application.update_application_status(
        db=db,
        application_id=application_id,
        new_status=status_update.status,
        current_user_id=current_user.id
    )
    if not updated_application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found or you don't have permission to update it"
        )
    return updated_application