# app/models/user.py
import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import (Column, String, Boolean, DateTime, Enum as SQLAlchemyEnum, Text, func)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from .skill import user_skill_association # Yeni ara tabloyu import et

class UserRole(enum.Enum):
    admin = "admin"
    freelancer = "freelancer"
    client = "client"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    role = Column(SQLAlchemyEnum(UserRole), nullable=False, default=UserRole.freelancer)
    name = Column(String, nullable=False)
    bio = Column(Text, nullable=True)
    profile_picture_url = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False, nullable=False)
    phone_number = Column(String(20), nullable=True)
    # YENİ HALLERİ
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)

    # Relationships
    projects = relationship("Project", back_populates="owner")
    applications = relationship("Application", back_populates="freelancer")
    notifications = relationship("Notification", back_populates="user")
    sent_messages = relationship("Message", back_populates="sender", foreign_keys="Message.sender_id")
    received_messages = relationship("Message", back_populates="receiver", foreign_keys="Message.receiver_id")
    test_results = relationship("TestResult", back_populates="user")
    skills = relationship(
        "Skill",
        secondary=user_skill_association,
        back_populates="users"
    )
    portfolio_items = relationship("PortfolioItem", back_populates="owner", cascade="all, delete-orphan")
    work_experiences = relationship("WorkExperience", back_populates="owner", cascade="all, delete-orphan")
