# config.py
import os
from pydantic import EmailStr
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=dotenv_path)

class Settings(BaseSettings):
    """
    Uygulama genelindeki ayarları .env dosyasından okuyan Pydantic modeli.
    """
    # Veritabanı Ayarları
    DATABASE_URL: str

    # JWT Ayarları
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # --- YENİ: ŞİFRE SIFIRLAMA AYARI ---
    RESET_TOKEN_EXPIRE_MINUTES: int = 60 # Token'ın geçerlilik süresi (dakika)

    # --- YENİ: E-POSTA AYARLARI ---
    MAIL_USERNAME: str
    MAIL_PASSWORD: str
    MAIL_FROM: EmailStr
    MAIL_PORT: int
    MAIL_SERVER: str
    MAIL_STARTTLS: bool = True
    MAIL_SSL_TLS: bool = False

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
