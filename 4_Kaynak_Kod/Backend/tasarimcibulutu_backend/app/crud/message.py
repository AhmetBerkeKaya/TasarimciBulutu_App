# app/crud/message.py
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc, func
from app import models, schemas
from typing import List
from uuid import UUID
from datetime import datetime, timezone

def get_conversation(db: Session, user1_id: UUID, user2_id: UUID) -> List[models.Message]:
    """İki kullanıcı arasındaki tüm mesajları, eskiden yeniye sıralı olarak getirir."""
    return db.query(models.Message).filter(
        or_(
            (models.Message.sender_id == user1_id) & (models.Message.receiver_id == user2_id),
            (models.Message.sender_id == user2_id) & (models.Message.receiver_id == user1_id)
        )
    ).order_by(models.Message.created_at.asc()).all()

def create_message(db: Session, message: schemas.MessageCreate, sender_id: UUID) -> models.Message:
    """Güvenli bir şekilde yeni bir mesaj oluşturur."""
    db_message = models.Message(
        sender_id=sender_id,
        receiver_id=message.receiver_id,
        content=message.content,
        # created_at ve id gibi alanlar DB'de otomatik oluşmaz, burada atamalıyız.
        # is_read zaten modelde default=False olarak ayarlı.
        created_at=datetime.now(timezone.utc) # <-- EKSİK OLAN KRİTİK SATIR
    )
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    return db_message
def get_conversations(db: Session, user_id: UUID) -> List[models.Message]:
    """
    Bir kullanıcının tüm konuşmalarından en son mesajı getirir.
    """
    # Her bir sohbet partneri ve o sohbetteki en son mesajın zamanını bulan alt sorgu
    latest_subquery = db.query(
        func.least(models.Message.sender_id, models.Message.receiver_id).label("user_a"),
        func.greatest(models.Message.sender_id, models.Message.receiver_id).label("user_b"),
        func.max(models.Message.created_at).label("latest_created_at")
    ).filter(
        or_(
            models.Message.sender_id == user_id,
            models.Message.receiver_id == user_id
        )
    ).group_by("user_a", "user_b").subquery()

    # Alt sorgudaki bu bilgilere uyan tam Mesaj nesnelerini getir
    conversations = db.query(models.Message).join(
        latest_subquery,
        or_(
            (func.least(models.Message.sender_id, models.Message.receiver_id) == latest_subquery.c.user_a) &
            (func.greatest(models.Message.sender_id, models.Message.receiver_id) == latest_subquery.c.user_b) &
            (models.Message.created_at == latest_subquery.c.latest_created_at),

            (func.least(models.Message.sender_id, models.Message.receiver_id) == latest_subquery.c.user_b) &
            (func.greatest(models.Message.sender_id, models.Message.receiver_id) == latest_subquery.c.user_a) &
            (models.Message.created_at == latest_subquery.c.latest_created_at)
        )
    ).order_by(desc(models.Message.created_at)).all()

    return conversations

def mark_messages_as_read(db: Session, sender_id: UUID, receiver_id: UUID):
    """Bir kullanıcıdan diğerine gönderilen okunmamış mesajları okundu olarak işaretler."""
    db.query(models.Message).filter(
        models.Message.sender_id == sender_id,
        models.Message.receiver_id == receiver_id,
        models.Message.is_read == False
    ).update({"is_read": True})

    db.commit()