# app/crud/user.py
from sqlalchemy.orm import Session
from app import models, schemas, security 
from passlib.context import CryptContext
from datetime import datetime, timezone # Bu import'un olduğundan emin ol

# Şifreleme context'i bir kere oluşturulur
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# ... (get_user, get_user_by_email, get_users fonksiyonları aynı kalabilir) ...
def get_user(db: Session, user_id: str):
    return db.query(models.User).filter(models.User.id == str(user_id)).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()

# --- YENİ EKLENEN FONKSİYON ---
def authenticate_user(db: Session, email: str, password: str) -> models.User | None:
    user = get_user_by_email(db, email=email)
    if not user:
        return None
    if not security.verify_password(password, user.password_hash):
        return None
    return user

# --- DEĞİŞEN FONKSİYONLAR ---
def create_user(db: Session, user: schemas.UserCreate) -> models.User:
    hashed_password = security.get_password_hash(user.password) # security'den çağır
    
    # Zaman damgalarını burada, Python içinde oluşturuyoruz
    current_time = datetime.now(timezone.utc)
    
    db_user = models.User(
        email=user.email,
        password_hash=hashed_password,
        role=user.role,
        name=user.name,
        bio=user.bio,
        profile_picture=user.profile_picture,
        phone_number=user.phone_number,
        created_at=current_time,
        updated_at=current_time, # İlk oluşturmada ikisi de aynıdır
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: str, user_update: schemas.UserUpdate) -> models.User | None:
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    
    update_data = user_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_user, key, value)
    
    # updated_at alanını manuel olarak güncelliyoruz
    db_user.updated_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(db_user)
    return db_user

# ... (delete_user fonksiyonu aynı kalabilir) ...
def delete_user(db: Session, user_id: str) -> models.User | None:
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    db.delete(db_user)
    db.commit()
    return db_user