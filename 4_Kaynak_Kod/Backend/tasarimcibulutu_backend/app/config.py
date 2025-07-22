# config.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # Veritabanı URL'si
    DATABASE_URL: str
    
    # --- YENİ EKLENECEK ALANLAR ---
    # JWT (JSON Web Token) Ayarları
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    # --- BİTTİ ---

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = Settings()