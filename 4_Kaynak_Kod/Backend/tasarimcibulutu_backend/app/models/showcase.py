# app/models/showcase.py

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class ShowcasePost(Base):
    """
    Kullanıcıların projelerini veya tasarımlarını sergilediği gönderileri temsil eder.
    """
    __tablename__ = "showcase_posts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    file_url = Column(String, nullable=True)
    thumbnail_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    owner = relationship("User", back_populates="showcase_posts")
    likes = relationship("PostLike", back_populates="post", cascade="all, delete-orphan")
    
    # --- NİHAİ DÜZELTME ---
    # Bu ilişkiyi, sadece ana yorumları (parent_comment_id'si NULL olanları)
    # getirecek şekilde güncelliyoruz. SQLAlchemy, bu ana yorumlara bağlı
    # yanıtları (replies) otomatik olarak iç içe getirecektir.
    comments = relationship(
        "PostComment", 
        primaryjoin="and_(ShowcasePost.id==PostComment.post_id, PostComment.parent_comment_id==None)",
        back_populates="post", 
        cascade="all, delete-orphan", 
        order_by="PostComment.created_at"
    )
    # --- DÜZELTMENİN SONU ---

class PostLike(Base):
    # ... (içeriği aynı kalacak)
    __tablename__ = "post_likes"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    post_id = Column(UUID(as_uuid=True), ForeignKey("showcase_posts.id"), primary_key=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    user = relationship("User", back_populates="likes")
    post = relationship("ShowcasePost", back_populates="likes")

class PostComment(Base):
    # ... (içeriği aynı kalacak)
    __tablename__ = "post_comments"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    post_id = Column(UUID(as_uuid=True), ForeignKey("showcase_posts.id"), nullable=False, index=True)
    parent_comment_id = Column(UUID(as_uuid=True), ForeignKey("post_comments.id"), nullable=True)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    author = relationship("User", back_populates="comments")
    post = relationship("ShowcasePost", back_populates="comments")
    parent = relationship("PostComment", remote_side=[id], back_populates="replies")
    replies = relationship("PostComment", back_populates="parent", cascade="all, delete-orphan")
    likes = relationship("CommentLike", back_populates="comment", cascade="all, delete-orphan")

class CommentLike(Base):
    # ... (içeriği aynı kalacak)
    __tablename__ = "comment_likes"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    comment_id = Column(UUID(as_uuid=True), ForeignKey("post_comments.id"), primary_key=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    user = relationship("User", back_populates="comment_likes")
    comment = relationship("PostComment", back_populates="likes")
