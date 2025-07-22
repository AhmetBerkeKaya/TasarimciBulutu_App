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
    
    # Dosyaların kendisi S3 gibi bir bulut servisinde saklanacak,
    # burada sadece URL'lerini tutacağız.
    file_url = Column(String, nullable=True)
    thumbnail_url = Column(String, nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # İlişkiler
    owner = relationship("User", back_populates="showcase_posts")
    likes = relationship("PostLike", back_populates="post", cascade="all, delete-orphan")
    comments = relationship("PostComment", back_populates="post", cascade="all, delete-orphan", order_by="PostComment.created_at")

class PostLike(Base):
    """
    Bir kullanıcının bir gönderiyi beğendiğini belirten ilişki tablosu.
    """
    __tablename__ = "post_likes"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    post_id = Column(UUID(as_uuid=True), ForeignKey("showcase_posts.id"), primary_key=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # İlişkiler
    user = relationship("User", back_populates="likes")
    post = relationship("ShowcasePost", back_populates="likes")

class PostComment(Base):
    """
    Bir gönderiye yapılan yorumları temsil eder.
    """
    __tablename__ = "post_comments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    post_id = Column(UUID(as_uuid=True), ForeignKey("showcase_posts.id"), nullable=False, index=True)
    
    # Gelecekte yorumlara yanıt (thread) sistemi için altyapı
    parent_comment_id = Column(UUID(as_uuid=True), ForeignKey("post_comments.id"), nullable=True)
    
    content = Column(Text, nullable=False)
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # İlişkiler
    author = relationship("User", back_populates="comments")
    post = relationship("ShowcasePost", back_populates="comments")
    parent = relationship("PostComment", remote_side=[id], back_populates="replies")
    replies = relationship("PostComment", back_populates="parent", cascade="all, delete-orphan")

