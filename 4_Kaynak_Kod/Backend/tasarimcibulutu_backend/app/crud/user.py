# app/crud/user.py
from typing import Optional
from sqlalchemy.orm import Session
from app import models, schemas, security 
from passlib.context import CryptContext
from datetime import datetime, timezone # Bu import'un olduğundan emin ol
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import joinedload, subqueryload
from app.models.user import User
from app.models.skill import Skill

# Şifreleme context'i bir kere oluşturulur
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# ... (get_user, get_user_by_email, get_users fonksiyonları aynı kalabilir) ...
def get_user(db: Session, user_id: UUID) -> models.User | None:
    # options() ile ilişkili verilerin de ana sorguyla birlikte yüklenmesini sağlıyoruz
    return db.query(models.User).options(
        subqueryload(models.User.skills),
        subqueryload(models.User.portfolio_items),
        subqueryload(models.User.work_experiences),
        joinedload(models.User.reviews_received).joinedload(models.Review.project),
        joinedload(models.User.reviews_received).joinedload(models.Review.reviewer)
    ).filter(models.User.id == str(user_id)).first()

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
    hashed_password = security.get_password_hash(user.password)
    current_time = datetime.now(timezone.utc) # O anın zamanını al

    db_user = models.User(
        email=user.email,
        password_hash=hashed_password,
        role=user.role,
        name=user.name,

        # --- EKSİK OLAN SATIRLARI BURAYA GERİ EKLİYORUZ ---
        created_at=current_time,
        updated_at=current_time
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: UUID, user_update: schemas.UserUpdate) -> Optional[models.User]:
    db_user = get_user(db, user_id=user_id)
    if not db_user:
        return None

    # Gelen verileri bir sözlüğe çevir, None olanları atla
    update_data = user_update.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_user, key, value)

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

def update_user_password(db: Session, user: models.User, new_password: str):
    """Kullanıcının şifresini yeni hash ile günceller."""
    hashed_password = security.get_password_hash(new_password)
    user.password_hash = hashed_password
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def remove_skill_from_user(db: Session, user: User, skill: Skill):
    """Kullanıcının yetenek listesinden bir yeteneği kaldırır."""
    if skill in user.skills:
        user.skills.remove(skill)
        db.commit()
    return user