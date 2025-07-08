import shutil
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Response, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
# --- GEREKLİ TÜM MODÜLLERİ VE FONKSİYONLARI DOĞRU BİR ŞEKİLDE IMPORT EDİYORUZ ---
from app.crud import user as user_crud, skill as skill_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.schemas.user import User as UserSchema, UserCreate, UserUpdate, PasswordUpdate

router = APIRouter(
    prefix="/users",
    tags=["users"]
)

# --- PUBLIC ENDPOINT (Herkesin erişebileceği) ---

@router.post("/", response_model=UserSchema, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """
    Yeni bir kullanıcı oluşturur (Signup).
    """
    db_user = user_crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user_by_phone = user_crud.get_user_by_phone_number(db, phone_number=user.phone_number)
    if db_user_by_phone:
        raise HTTPException(status_code=400, detail="Bu telefon numarası zaten kayıtlı.")
    return user_crud.create_user(db=db, user=user)



# --- PROTECTED ENDPOINTS (Sadece giriş yapmış kullanıcıların kendileri için erişebileceği) ---
# ÖNEMLİ: Spesifik yollar (örn: "/me") her zaman genel yollardan (örn: "/{user_id}") önce gelmelidir.

@router.get("/me", response_model=UserSchema)
def read_users_me(current_user: UserModel = Depends(get_current_user)):
    """
    Giriş yapmış olan mevcut kullanıcının tüm bilgilerini döndürür.
    """
    return current_user

@router.put("/me", response_model=UserSchema)
def update_current_user(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış olan mevcut kullanıcının profilini (isim, bio vb.) günceller.
    """
    return user_crud.update_user(db=db, user_id=current_user.id, user_update=user_update)

@router.put("/me/password", status_code=status.HTTP_204_NO_CONTENT)
def change_current_user_password(
    password_update: PasswordUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış olan mevcut kullanıcının şifresini değiştirir.
    """
    if not user_crud.verify_password(password_update.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    user_crud.update_user_password(db, user=current_user, new_password=password_update.new_password)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.put("/me/picture", response_model=UserSchema)
def update_profile_picture(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış olan mevcut kullanıcının profil fotoğrafını günceller.
    """
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    unique_filename = f"profile_{current_user.id}_{uuid.uuid4()}.{file_extension}"
    file_path = f"static/images/{unique_filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    current_user.profile_picture_url = file_path
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/me/skills/{skill_id}", response_model=UserSchema)
def add_skill_to_current_user(
    skill_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış olan mevcut kullanıcıya bir yetenek ekler.
    """
    skill = skill_crud.get_skill(db, skill_id=str(skill_id))
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    return skill_crud.add_skill_to_user(db=db, user=current_user, skill=skill)

@router.delete("/me/skills/{skill_id}", response_model=UserSchema)
def remove_skill_from_current_user(
    skill_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """
    Giriş yapmış olan mevcut kullanıcının bir yeteneğini kaldırır.
    """
    skill = skill_crud.get_skill(db, skill_id=str(skill_id))
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    return user_crud.remove_skill_from_user(db=db, user=current_user, skill=skill)

# --- PUBLIC ENDPOINTS (Devamı) ---

@router.get("/", response_model=List[UserSchema])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Sistemdeki tüm kullanıcıları listeler.
    """
    users = user_crud.get_users(db, skip=skip, limit=limit)
    return users

@router.get("/{user_id}", response_model=UserSchema)
def read_user(user_id: UUID, db: Session = Depends(get_db)):
    """
    Belirli bir kullanıcının public profilini ID ile getirir.
    """
    db_user = user_crud.get_user(db, user_id=str(user_id))
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user