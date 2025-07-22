# app/schemas/showcase.py

import uuid
from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime
from .user import UserSummary

# --- GÜNCELLENEN ŞEMA ---
class PresignedUrlResponse(BaseModel):
    url: str
    fields: dict
    final_file_url: str # YENİ: Dosyanın S3'teki nihai erişim URL'si

# ... (diğer şemalar aynı kalacak) ...
class PresignedUrlRequest(BaseModel):
    filename: str; content_type: str
class CommentBase(BaseModel):
    content: str
class CommentCreate(CommentBase):
    post_id: uuid.UUID; parent_comment_id: Optional[uuid.UUID] = None
class Comment(CommentBase):
    id: uuid.UUID; user_id: uuid.UUID; post_id: uuid.UUID; created_at: datetime; author: UserSummary
    model_config = ConfigDict(from_attributes=True)
class PostLike(BaseModel):
    user_id: uuid.UUID; post_id: uuid.UUID
    model_config = ConfigDict(from_attributes=True)
class ShowcasePostBase(BaseModel):
    title: str; description: Optional[str] = None
class ShowcasePostCreate(BaseModel):
    title: str; description: Optional[str] = None
    file_url: Optional[str] = None; thumbnail_url: Optional[str] = None
class ShowcasePostUpdate(ShowcasePostBase):
    pass
class ShowcasePost(ShowcasePostBase):
    id: uuid.UUID; user_id: uuid.UUID; created_at: datetime; updated_at: datetime
    file_url: Optional[str] = None; thumbnail_url: Optional[str] = None
    owner: UserSummary; likes: List[PostLike] = []; comments: List[Comment] = []
    model_config = ConfigDict(from_attributes=True)
