from sqlalchemy.orm import Session
from app import models, schemas
from uuid import uuid4
from typing import List

def get_message(db: Session, message_id: str):
    return db.query(models.Message).filter(models.Message.id == message_id).first()

def get_messages(db: Session, skip: int = 0, limit: int = 100) -> List[models.Message]:
    return db.query(models.Message).offset(skip).limit(limit).all()

def get_messages_by_sender(db: Session, sender_id: str) -> List[models.Message]:
    return db.query(models.Message).filter(models.Message.sender_id == sender_id).all()

def get_messages_by_receiver(db: Session, receiver_id: str) -> List[models.Message]:
    return db.query(models.Message).filter(models.Message.receiver_id == receiver_id).all()

def create_message(db: Session, message: schemas.MessageCreate):
    db_message = models.Message(
        id=uuid4(),
        sender_id=message.sender_id,
        receiver_id=message.receiver_id,
        content=message.content,
        is_read=False,
        created_at=None,  # default olarak DB'de datetime.utcnow() atanacak
    )
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    return db_message

def update_message(db: Session, message_id: str, message_update: schemas.MessageUpdate):
    db_message = get_message(db, message_id)
    if not db_message:
        return None
    update_data = message_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_message, key, value)
    db.commit()
    db.refresh(db_message)
    return db_message

def delete_message(db: Session, message_id: str):
    db_message = get_message(db, message_id)
    if not db_message:
        return None
    db.delete(db_message)
    db.commit()
    return db_message
