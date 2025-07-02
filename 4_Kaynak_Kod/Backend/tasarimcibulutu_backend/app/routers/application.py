from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import UUID4
from app.dependencies import get_current_user
from app.models.user import User as UserModel
from app.models.user import UserRole
from app import crud, schemas, database

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
def create_application(
    application: schemas.ApplicationCreate, 
    db: Session = Depends(get_db), 
    current_user: UserModel = Depends(get_current_user)
):
    # Sadece freelancer'lar başvuru yapabilir
    if current_user.role != UserRole.freelancer:
        raise HTTPException(
            status_code=403,
            detail="Only freelancers can submit applications."
        )
    # freelancer_id olarak token'dan gelen kullanıcı ID'sini kullanıyoruz
    return crud.application.create_application(
        db=db, application=application, freelancer_id=current_user.id
    )


@router.get("/", response_model=List[schemas.Application])
def read_applications(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    applications = crud.get_applications(db, skip=skip, limit=limit)
    return applications

@router.get("/me", response_model=List[schemas.Application])
def read_my_applications(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Retrieve applications for the current logged in user.
    """
    # crud/application.py içindeki get_applications_by_freelancer fonksiyonunu kullanıyoruz
    return crud.application.get_applications_by_freelancer(db, freelancer_id=current_user.id)


@router.get("/{application_id}", response_model=schemas.Application)
def read_application(application_id: UUID4, db: Session = Depends(get_db)):
    db_application = crud.get_application(db, application_id=application_id)
    if not db_application:
        raise HTTPException(status_code=404, detail="Application not found")
    return db_application


@router.put("/{application_id}", response_model=schemas.Application)
def update_application(application_id: UUID4, application_update: schemas.ApplicationUpdate, db: Session = Depends(get_db)):
    updated_application = crud.update_application(db, application_id, application_update)
    if not updated_application:
        raise HTTPException(status_code=404, detail="Application not found")
    return updated_application


@router.delete("/{application_id}", response_model=schemas.Application)
def delete_application(application_id: UUID4, db: Session = Depends(get_db)):
    deleted_application = crud.delete_application(db, application_id)
    if not deleted_application:
        raise HTTPException(status_code=404, detail="Application not found")
    return deleted_application
