# tasarimcibulutu_backend/app/schemas/showcase.py

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID  # Pydantic'te UUID tipini kullanabilmek için import ediyoruz.

# --- KULLANICI ÖZET ŞEMASI (UUID'li) ---
# Bu şema, bir vitrin gönderisiyle birlikte sahibinin temel bilgilerini
# (şifre gibi hassas veriler olmadan) göstermek için kullanılır.
class _UserSummary(BaseModel):
    # --- DEĞİŞİKLİK BURADA ---
    # ID tipini 'int' yerine 'UUID' olarak güncelledik.
    id: UUID
    
    # User modelinizde 'full_name' gibi bir alan olduğunu varsayıyorum.
    # Yoksa 'username' veya başka bir alanla değiştirebilirsiniz.
    name: str
    
    class Config:
        # SQLAlchemy model nesnelerinden Pydantic şemalarına otomatik
        # dönüşüm yapılmasını sağlar.
        from_attributes = True


# --- TEMEL ŞEMA (BASE SCHEMA) ---
# Diğer şemaların miras alacağı ortak alanları içerir. Değişiklik yok.
class ShowcasePostBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=150, description="Gönderinin başlığı")
    description: Optional[str] = Field(None, max_length=2000, description="Gönderi hakkında detaylı açıklama")


# --- OLUŞTURMA ŞEMASI (CREATE SCHEMA) ---
# Yeni gönderi oluştururken kullanılır. Değişiklik yok.
class ShowcasePostCreate(ShowcasePostBase):
    pass


# --- GÜNCELLEME ŞEMASI (UPDATE SCHEMA) ---
# Gönderi güncellerken kullanılır. Değişiklik yok.
class ShowcasePostUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=150)
    description: Optional[str] = Field(None, max_length=2000)


# --- OKUMA ŞEMASI (READ SCHEMA) ---
# API'den istemciye veri döndürürken kullanılır.
class ShowcasePostRead(ShowcasePostBase):
    # --- DEĞİŞİKLİK BURADA ---
    # ID tipini 'int' yerine 'UUID' olarak güncelledik.
    id: UUID
    
    original_filename: str
    file_format: Optional[str]
    aps_urn: Optional[str]
    aps_translation_status: str
    created_at: datetime
    updated_at: Optional[datetime]
    
    # `owner` alanı artık UUID'li `_UserSummary` şemasını kullanıyor.
    owner: _UserSummary

    class Config:
        from_attributes = True