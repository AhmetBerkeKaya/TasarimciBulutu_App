from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

# --- DOĞRU IMPORT'LAR ---
from app.crud import user as user_crud, skill as skill_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
# İhtiyacımız olan tüm şemaları doğrudan kendi dosyalarından import edelim
from app.schemas.user import User as UserSchema, UserCreate, UserUpdate, PasswordUpdate
# --- BİTTİ ---

router = APIRouter(
    prefix="/users",
    tags=["users"]
)

@router.post("/", response_model=UserSchema, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = user_crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return user_crud.create_user(db=db, user=user)

# --- PROTECTED ENDPOINTS ---
@router.get("/me", response_model=UserSchema)
def read_users_me(current_user: UserModel = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserSchema)
def update_current_user(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    return user_crud.update_user(db=db, user_id=current_user.id, user_update=user_update)

@router.put("/me/password", status_code=status.HTTP_204_NO_CONTENT)
def change_current_user_password(
    password_update: PasswordUpdate, # <-- Artık bu şemayı tanıyor
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    if not user_crud.verify_password(password_update.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect current password")

    user_crud.update_user_password(db, user=current_user, new_password=password_update.new_password)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/me/skills/{skill_id}", response_model=UserSchema)
def add_skill_to_current_user(
    skill_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    skill = skill_crud.get_skill(db, skill_id=str(skill_id))
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    return user_crud.add_skill_to_user(db=db, user=current_user, skill=skill)

# --- PUBLIC ENDPOINTS (Devamı) ---
@router.get("/", response_model=List[UserSchema])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = user_crud.get_users(db, skip=skip, limit=limit)
    return users

@router.get("/{user_id}", response_model=UserSchema)
def read_user(user_id: UUID, db: Session = Depends(get_db)):
    db_user = user_crud.get_user(db, user_id=str(user_id))
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user