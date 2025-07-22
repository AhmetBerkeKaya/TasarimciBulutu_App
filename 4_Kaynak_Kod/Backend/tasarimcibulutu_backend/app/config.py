# config.py
import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

# .env dosyasının yolunu projenin kök dizinine göre ayarla
# Bu, uygulamanın herhangi bir yerden çalıştırıldığında .env dosyasını bulmasını sağlar.
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
    # YENİ: Refresh token için geçerlilik süresi (gün olarak)
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    class Config:
        # Pydantic'in .env dosyasını okumasını sağlar
        env_file = ".env"
        # .env dosyasında büyük/küçük harf duyarlılığını kaldırır
        case_sensitive = False

# Ayarları global olarak kullanılabilir hale getirmek için bir instance oluşturuyoruz.
settings = Settings()
