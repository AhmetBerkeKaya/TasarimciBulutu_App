# tasarimcibulutu_backend/app/routers/aps.py (NİHAİ DOĞRU HALİ)

import httpx
from fastapi import APIRouter, HTTPException, status, Depends

# Ayarlarımızı ve veritabanı bağımlılığımızı import edelim
from app.config import settings
from app.dependencies import get_db
from sqlalchemy.orm import Session

router = APIRouter(
    prefix="/aps",
    tags=["Autodesk Platform Services (APS)"],
    responses={404: {"description": "Not found"}},
)

# APS'in token almak için kullanılacak adresi
# --- DÜZELTME BURADA ---
APS_TOKEN_URL = "https://developer.api.autodesk.com/authentication/v2/token"

@router.get("/viewer-token", response_model=dict)
async def get_viewer_token():
    """
    Frontend'in 3D görüntüleyiciyi (viewer) başlatması için gerekli olan
    2-ayaklı (2-legged) ve sadece okuma yetkisine sahip geçici bir APS token'ı alır.
    Client ID ve Secret gibi hassas bilgiler sunucuda güvende kalır.
    """
    try:
        # APS'e asenkron bir POST isteği göndereceğiz
        async with httpx.AsyncClient() as client:
            response = await client.post(
                APS_TOKEN_URL,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                data={
                    "grant_type": "client_credentials",
                    "client_id": settings.APS_CLIENT_ID,
                    "client_secret": settings.APS_CLIENT_SECRET,
                    "scope": "viewables:read",  # Sadece görüntüleme yetkisi istiyoruz
                },
            )

            # Eğer Autodesk'ten bir hata dönerse, biz de bir hata döndürelim
            response.raise_for_status()

            # Başarılı olursa, gelen JSON yanıtını doğrudan frontend'e geri döndür
            return response.json()

    except httpx.HTTPStatusError as e:
        # APS'den gelen hatayı loglayıp, istemciye genel bir hata mesajı verelim
        print(f"APS API Error: {e.response.status_code} - {e.response.text}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Görüntüleyici servisine bağlanılamadı.",
        )
    except Exception as e:
        print(f"APS TOKEN ALINIRKEN BEKLENMEDİK HATA: {e!r}") 
        print(f"An unexpected error occurred: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Sunucuda beklenmedik bir hata oluştu.",
        )