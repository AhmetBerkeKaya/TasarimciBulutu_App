# app/crud/message.py
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc, func, case, update
from app import models, schemas
from typing import List
from uuid import UUID
from datetime import datetime, timezone

def get_conversation(db: Session, user1_id: UUID, user2_id: UUID) -> List[models.Message]:
    """İki kullanıcı arasındaki, mevcut kullanıcının silmediği tüm mesajları getirir."""
    current_user_id = user1_id
    
    # Bu sorgu, mesajları getirirken silinme bayraklarını kontrol eder
    return db.query(models.Message).filter(
        or_(
            (models.Message.sender_id == user1_id) & (models.Message.receiver_id == user2_id),
            (models.Message.sender_id == user2_id) & (models.Message.receiver_id == user1_id)
        )
    ).filter(
        # Eğer mesajı ben gönderdiysem, benim tarafımdan silinmemiş olmalı
        (models.Message.sender_id == current_user_id) & (models.Message.deleted_by_sender == False) |
        # Eğer mesajı ben aldıysam, benim tarafımdan silinmemiş olmalı
        (models.Message.receiver_id == current_user_id) & (models.Message.deleted_by_receiver == False)
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
    Bir kullanıcının tüm konuşmalarından, kendisi için silinmemiş olan en son mesajı getirir.
    """
    # Her bir sohbet partneri ile olan en son mesajın ID'sini bulan bir alt sorgu
    # Sadece kullanıcının silmediği mesajları dikkate al
    latest_message_subquery = db.query(
        func.max(models.Message.created_at).label("latest_created_at")
    ).filter(
        or_(
            models.Message.sender_id == user_id,
            models.Message.receiver_id == user_id
        )
    ).filter(
        (models.Message.sender_id == user_id) & (models.Message.deleted_by_sender == False) |
        (models.Message.receiver_id == user_id) & (models.Message.deleted_by_receiver == False)
    ).group_by(
        func.least(models.Message.sender_id, models.Message.receiver_id),
        func.greatest(models.Message.sender_id, models.Message.receiver_id)
    ).subquery()

    conversations = db.query(models.Message).filter(
        models.Message.created_at.in_(latest_message_subquery)
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

def soft_delete_message(db: Session, message: models.Message, user_id: UUID):
    """Mesajı, silen kişiye göre işaretler."""
    if message.sender_id == user_id:
        message.deleted_by_sender = True
    elif message.receiver_id == user_id:
        message.deleted_by_receiver = True

    db.add(message)
    db.commit()
    return message

# --- GÜNCELLENMİŞ SİLME FONKSİYONU ---
def soft_delete_conversation(db: Session, user_id: UUID, other_user_id: UUID) -> bool:
    """
    Bir kullanıcının, diğer bir kullanıcıyla olan konuşmasındaki tüm mesajları
    kendisi için silinmiş olarak işaretler.
    """
    try:
        # Ben göndericiysem, deleted_by_sender'ı True yap
        db.query(models.Message).filter(
            models.Message.sender_id == user_id,
            models.Message.receiver_id == other_user_id
        ).update({"deleted_by_sender": True}, synchronize_session=False)

        # Ben alıcıysam, deleted_by_receiver'ı True yap
        db.query(models.Message).filter(
            models.Message.sender_id == other_user_id,
            models.Message.receiver_id == user_id
        ).update({"deleted_by_receiver": True}, synchronize_session=False)
        
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        print(f"An error occurred: {e}")
        return False