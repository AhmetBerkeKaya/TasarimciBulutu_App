from sqlalchemy.orm import Session
from app import models, schemas
from uuid import uuid4
from typing import List


def get_notification(db: Session, notification_id: str):
    return db.query(models.Notification).filter(models.Notification.id == notification_id).first()


def get_notifications(db: Session, skip: int = 0, limit: int = 100) -> List[models.Notification]:
    return db.query(models.Notification).offset(skip).limit(limit).all()


def get_notifications_by_user(db: Session, user_id: str) -> List[models.Notification]:
    return db.query(models.Notification).filter(models.Notification.user_id == user_id).all()


def create_notification(db: Session, notification: schemas.NotificationCreate):
    db_notification = models.Notification(
        id=uuid4(),
        user_id=notification.user_id,
        message=notification.message,
        is_read=notification.is_read,
        # created_at default zaten veritabanında atanıyor
    )
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)
    return db_notification


def update_notification(db: Session, notification_id: str, notification_update: schemas.NotificationUpdate):
    db_notification = get_notification(db, notification_id)
    if not db_notification:
        return None
    update_data = notification_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_notification, key, value)
    db.commit()
    db.refresh(db_notification)
    return db_notification


def delete_notification(db: Session, notification_id: str):
    db_notification = get_notification(db, notification_id)
    if not db_notification:
        return None
    db.delete(db_notification)
    db.commit()
    return db_notification
