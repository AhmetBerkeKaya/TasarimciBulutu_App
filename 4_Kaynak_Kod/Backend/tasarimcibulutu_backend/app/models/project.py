import enum
import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Numeric, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy import Enum as SQLAlchemyEnum

class ProjectStatus(str, enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
# --- KONTROL BİTTİ ---

class Project(Base):
    __tablename__ = "projects"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=True)
    budget_min = Column(Numeric, nullable=True)
    budget_max = Column(Numeric, nullable=True)
    deadline = Column(DateTime(timezone=True), nullable=True)
    status = Column(
        SQLAlchemyEnum(ProjectStatus, name="projectstatus", native_enum=False),
        default=ProjectStatus.OPEN.value,
        nullable=False
    )
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), onupdate=datetime.utcnow)

    owner = relationship("User", back_populates="projects")
    applications = relationship("Application", back_populates="project")
    reviews = relationship("Review", back_populates="project")
