# app/crud/user.py

from typing import Optional
from sqlalchemy.orm import Session
from app import models, schemas, security 
from passlib.context import CryptContext
from datetime import datetime, timezone, timedelta # timedelta'yı import et
import secrets # Güvenli token üretimi için
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import joinedload, subqueryload
from app.models.user import User
from app.models.skill import Skill
from app.config import settings # Ayarları import et

# ... (get_password_hash, verify_password, get_user, vs. aynı kalacak) ...
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_user(db: Session, user_id: UUID) -> models.User | None:
    return db.query(models.User).options(
        subqueryload(models.User.skills),
        subqueryload(models.User.portfolio_items),
        subqueryload(models.User.work_experiences),
        joinedload(models.User.reviews_received).joinedload(models.Review.project),
        joinedload(models.User.reviews_received).joinedload(models.Review.reviewer)
    ).filter(models.User.id == str(user_id)).first()

def get_user_by_phone_number(db: Session, phone_number: str) -> models.User | None:
    return db.query(models.User).filter(models.User.phone_number == phone_number).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()

def authenticate_user(db: Session, email: str, password: str) -> models.User | None:
    user = get_user_by_email(db, email=email)
    if not user or not security.verify_password(password, user.password_hash):
        return None
    return user

def create_user(db: Session, user: schemas.UserCreate) -> models.User:
    hashed_password = security.get_password_hash(user.password)
    current_time = datetime.now(timezone.utc)
    db_user = models.User(
        email=user.email,
        password_hash=hashed_password,
        role=user.role,
        name=user.name,
        phone_number=user.phone_number,
        created_at=current_time,
        updated_at=current_time
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: UUID, user_update: schemas.UserUpdate) -> Optional[models.User]:
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        return None
    update_data = user_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_user, key, value)
    db_user.updated_at = datetime.now(timezone.utc)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def delete_user(db: Session, user_id: str) -> models.User | None:
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    db.delete(db_user)
    db.commit()
    return db_user

def update_user_password(db: Session, user: models.User, new_password: str):
    hashed_password = security.get_password_hash(new_password)
    user.password_hash = hashed_password
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

# --- YENİ: ŞİFRE SIFIRLAMA FONKSİYONLARI ---

def create_password_reset_token(db: Session, user: models.User) -> str:
    """
    Kullanıcı için güvenli bir şifre sıfırlama token'ı oluşturur,
    veritabanına kaydeder ve ham token'ı döndürür.
    """
    # 6 haneli, okunması kolay bir kod üretiyoruz.
    reset_code = ''.join(secrets.choice('0123456789') for _ in range(6))
    
    user.reset_password_token = reset_code # Token'ı doğrudan kaydediyoruz
    user.reset_password_token_expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.RESET_TOKEN_EXPIRE_MINUTES)
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return reset_code

def get_user_by_reset_token(db: Session, token: str) -> models.User | None:
    """
    Verilen token'a sahip ve süresi dolmamış kullanıcıyı bulur.
    """
    user = db.query(models.User).filter(models.User.reset_password_token == token).first()
    if not user:
        return None
    if user.reset_password_token_expires_at < datetime.now(timezone.utc):
        # Token süresi dolmuşsa, temizleyelim
        user.reset_password_token = None
        user.reset_password_token_expires_at = None
        db.commit()
        return None
    return user

def reset_user_password(db: Session, user: models.User, new_password: str) -> models.User:
    """
    Kullanıcının şifresini günceller ve reset token'ını temizler.
    """
    user.password_hash = security.get_password_hash(new_password)
    user.reset_password_token = None
    user.reset_password_token_expires_at = None
    user.updated_at = datetime.now(timezone.utc)
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return user

# --- BİTTİ ---

def remove_skill_from_user(db: Session, user: User, skill: Skill):
    if skill in user.skills:
        user.skills.remove(skill)
        db.commit()
    return user
