# app/schemas/showcase.py

import uuid
from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime
from .user import UserSummary

class CommentCreateBody(BaseModel):
    content: str
    # --- NİHAİ DÜZELTME: Veri tipini UUID yerine string olarak kabul et ---
    parent_comment_id: Optional[str] = None

class CommentLike(BaseModel):
    user_id: uuid.UUID
    comment_id: uuid.UUID
    model_config = ConfigDict(from_attributes=True)

class CommentBase(BaseModel):
    content: str

class CommentCreate(CommentBase):
    post_id: uuid.UUID
    parent_comment_id: Optional[str] = None # Burayı da string yapıyoruz

class Comment(CommentBase):
    id: uuid.UUID
    user_id: uuid.UUID
    post_id: uuid.UUID
    created_at: datetime
    author: UserSummary
    replies: List['Comment'] = []
    likes: List[CommentLike] = []
    model_config = ConfigDict(from_attributes=True)

class PostLike(BaseModel):
    user_id: uuid.UUID
    post_id: uuid.UUID
    model_config = ConfigDict(from_attributes=True)

class ShowcasePost(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    file_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    owner: UserSummary
    likes: List[PostLike] = []
    comments: List[Comment] = []
    model_config = ConfigDict(from_attributes=True)

class PresignedUrlResponse(BaseModel):
    url: str
    fields: dict
    final_file_url: str

class PresignedUrlRequest(BaseModel):
    filename: str
    content_type: str
    
class ShowcasePostBase(BaseModel):
    title: str
    description: Optional[str] = None

class ShowcasePostCreate(BaseModel):
    title: str
    description: Optional[str] = None
    file_url: Optional[str] = None
    thumbnail_url: Optional[str] = None

class ShowcasePostUpdate(ShowcasePostBase):
    pass

Comment.model_rebuild()