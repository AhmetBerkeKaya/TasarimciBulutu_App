from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import UUID4

from app import crud, schemas, database

router = APIRouter(
    prefix="/messages",
    tags=["messages"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.Message)
def create_message(message: schemas.MessageCreate, db: Session = Depends(get_db)):
    return crud.create_message(db, message=message)

@router.get("/", response_model=List[schemas.Message])
def read_messages(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    messages = crud.get_messages(db, skip=skip, limit=limit)
    return messages

@router.get("/{message_id}", response_model=schemas.Message)
def read_message(message_id: UUID4, db: Session = Depends(get_db)):
    db_message = crud.get_message(db, message_id=message_id)
    if not db_message:
        raise HTTPException(status_code=404, detail="Message not found")
    return db_message

@router.put("/{message_id}", response_model=schemas.Message)
def update_message(message_id: UUID4, message_update: schemas.MessageUpdate, db: Session = Depends(get_db)):
    updated_message = crud.update_message(db, message_id, message_update)
    if not updated_message:
        raise HTTPException(status_code=404, detail="Message not found")
    return updated_message

@router.delete("/{message_id}", response_model=schemas.Message)
def delete_message(message_id: UUID4, db: Session = Depends(get_db)):
    deleted_message = crud.delete_message(db, message_id)
    if not deleted_message:
        raise HTTPException(status_code=404, detail="Message not found")
    return deleted_message
