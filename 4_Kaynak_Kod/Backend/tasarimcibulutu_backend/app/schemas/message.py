from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import datetime

class MessageBase(BaseModel):
    sender_id: UUID4
    receiver_id: UUID4
    content: str

class MessageCreate(MessageBase):
    pass

class MessageUpdate(BaseModel):
    content: Optional[str] = None
    is_read: Optional[bool] = None

class Message(MessageBase):
    id: UUID4
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
