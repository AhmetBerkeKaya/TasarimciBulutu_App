import enum
import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Numeric, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from sqlalchemy import Enum as SQLAlchemyEnum
from .application import ApplicationStatus 
class ProjectStatus(str, enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    PENDING_REVIEW = "pending_review"  # <-- YENİ DURUM: Freelancer işi teslim etti, firma onayını bekliyor.
    COMPLETED = "completed"
    CANCELLED = "cancelled"

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
        SQLAlchemyEnum(ProjectStatus, name="projectstatus", native_enum=False, length=20),
        default=ProjectStatus.OPEN.value, # Varsayılan değer "open" olarak kalır
        nullable=False
    )
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    # onupdate'i on_update olarak düzeltmek daha standarttır, ama mevcut hali de çalışır
    updated_at = Column(DateTime(timezone=True), onupdate=datetime.utcnow) 

    owner = relationship("User", back_populates="projects")
    # applications ilişkisine, freelancer'a kolayca erişmek için bir 'lazy loading' stratejisi ekleyelim
    applications = relationship("Application", back_populates="project", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="project", cascade="all, delete-orphan")

    # Kolay erişim için bir property: Bu projede kabul edilen freelancer'ı döndürür
    @property
    def accepted_freelancer_id(self):
        print(f"\n--- accepted_freelancer_id özelliği çalıştı. Proje '{self.title}' için... ---")
        print(f"--- Projeye bağlı başvuru sayısı: {len(self.applications)} ---")
        for app in self.applications:
            print(f"  -> Kontrol edilen başvuru: ID={app.id}, Durum='{app.status}', FreelancerID={app.freelancer_id}")
            # Hem string hem de enum durumuna karşı kontrol edelim, ne olur ne olmaz.
            if app.status == 'accepted' or app.status == ApplicationStatus.accepted:
                print(f"  --> KABUL EDİLMİŞ BAŞVURU BULUNDU! Dönen Freelancer ID: {app.freelancer_id}")
                return app.freelancer_id
        print("--- Kabul edilmiş başvuru bulunamadı, None dönülüyor. ---")
        return None