# app/database.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import declarative_base
from .config import settings

# pool_recycle parametresi, belirli bir süre sonra bağlantıları yenileyerek
# "server closed connection" hatasını önler.
engine = create_engine(
    settings.DATABASE_URL,
    pool_recycle=3600  # Saniyede bir bağlantıyı yenile (1 saat)
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()