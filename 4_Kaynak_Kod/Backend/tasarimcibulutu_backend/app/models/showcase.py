# tasarimcibulutu_backend/app/models/showcase.py

import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID # PostgreSQL için UUID tipini import ediyoruz

# Projenizdeki ana veritabanı Base modelini import ediyoruz.
from app.database import Base

class ShowcasePost(Base):
    """
    Freelancer'ların proje vitrininde paylaşacağı her bir gönderiyi temsil eden
    veritabanı modeli (UUID'li primary key ile).
    """
    __tablename__ = "showcase_posts"

    # --- DEĞİŞİKLİK BURADA ---
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # --- Temel Gönderi Bilgileri ---
    title = Column(String, nullable=False, index=True, comment="Gönderinin başlığı")
    description = Column(String, nullable=True, comment="Gönderi hakkında detaylı açıklama")

    # --- Dosya ve Depolama Bilgileri ---
    original_filename = Column(String, nullable=False, comment="Kullanıcının yüklediği dosyanın orijinal adı")
    file_format = Column(String(10), nullable=True, comment="Dosya uzantısı (örn: dwg, stp, rvt)")
    storage_path = Column(String, nullable=False, unique=True, comment="Dosyanın sunucuda saklandığı göreceli yol (örn: static/uploads/uuid.stp)")

    # --- Autodesk Platform Services (APS) Bilgileri ---
    aps_urn = Column(String, nullable=True, unique=True, comment="APS Viewer için modelin Base64 formatındaki kimliği (URN)")
    aps_translation_status = Column(String, default="pending", comment="APS'teki çeviri işleminin durumu: pending, inprogress, success, failed")

    thumbnail_path = Column(String, nullable=True, comment="APS tarafından oluşturulan önizleme resminin yolu")
    # --- İlişki ve Zaman Damgaları ---
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, comment="Bu gönderiyi oluşturan freelancer'ın ID'si")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), comment="Gönderinin oluşturulma zamanı")
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), comment="Gönderinin son güncellenme zamanı")

    # --- SQLAlchemy İlişkisi ---
    owner = relationship("User", back_populates="showcase_posts")

    def __repr__(self):
        return f"<ShowcasePost(title='{self.title}', owner_id={self.owner_id})>"