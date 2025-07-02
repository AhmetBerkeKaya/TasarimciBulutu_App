from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import datetime


class NotificationBase(BaseModel):
    user_id: UUID4
    message: str
    is_read: bool = False


class NotificationCreate(NotificationBase):
    pass


class NotificationUpdate(BaseModel):
    message: Optional[str] = None
    is_read: Optional[bool] = None


class Notification(NotificationBase):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True
