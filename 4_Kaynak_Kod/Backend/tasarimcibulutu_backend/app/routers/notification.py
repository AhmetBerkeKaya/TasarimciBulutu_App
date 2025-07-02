from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import UUID4

from app import crud, schemas, database

router = APIRouter(
    prefix="/notifications",
    tags=["notifications"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=schemas.Notification)
def create_notification(notification: schemas.NotificationCreate, db: Session = Depends(get_db)):
    return crud.create_notification(db, notification=notification)


@router.get("/", response_model=List[schemas.Notification])
def read_notifications(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    notifications = crud.get_notifications(db, skip=skip, limit=limit)
    return notifications


@router.get("/{notification_id}", response_model=schemas.Notification)
def read_notification(notification_id: UUID4, db: Session = Depends(get_db)):
    db_notification = crud.get_notification(db, notification_id=notification_id)
    if not db_notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return db_notification


@router.put("/{notification_id}", response_model=schemas.Notification)
def update_notification(notification_id: UUID4, notification_update: schemas.NotificationUpdate, db: Session = Depends(get_db)):
    updated_notification = crud.update_notification(db, notification_id, notification_update)
    if not updated_notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return updated_notification


@router.delete("/{notification_id}", response_model=schemas.Notification)
def delete_notification(notification_id: UUID4, db: Session = Depends(get_db)):
    deleted_notification = crud.delete_notification(db, notification_id)
    if not deleted_notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return deleted_notification
