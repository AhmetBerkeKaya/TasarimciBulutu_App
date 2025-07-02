# app/routers/user.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app import crud, schemas, database, models # <-- models'ı buraya import et
from app.dependencies import get_current_user

router = APIRouter(
    prefix="/users",
    tags=["users"]
)

# Dependency to get the DB session
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ... (create_user, read_users, update_user, delete_user aynı kalır) ...
@router.post("/", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.user.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.user.create_user(db=db, user=user)

# ...

@router.get("/me", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    """
    Get current logged in user.
    """
    return current_user

# SONRA genel olan "/{user_id}" yolu gelir
@router.get("/{user_id}", response_model=schemas.User)
def read_user(user_id: UUID, db: Session = Depends(get_db)):
    db_user = crud.user.get_user(db, user_id=str(user_id))
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user