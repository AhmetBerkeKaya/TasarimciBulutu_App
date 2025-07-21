# tasarimcibulutu_backend/app/routers/webhook.py

import base64
from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy.orm import Session
from app.dependencies import get_db
from app.crud import showcase as showcase_crud

router = APIRouter(
    prefix="/webhooks",
    tags=["Webhooks"],
    responses={404: {"description": "Not found"}},
)

@router.post("/aps")
async def aps_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Autodesk Platform Services (APS) tarafından çeviri işlemi tamamlandığında
    veya başarısız olduğunda tetiklenen webhook.
    """
    try:
        payload = await request.json()
        print("APS Webhook'tan bildirim alındı:", payload)

        # Gelen bildirimde 'urn' var mı ve 'status' başarılı mı kontrol et
        if "urn" in payload and "status" in payload.get("payload", {}):
            urn = payload["urn"]
            status = payload["payload"]["status"]

            # Gelen URN'ye sahip gönderiyi veritabanında bul
            db_post = showcase_crud.get_post_by_urn(db, urn=urn)

            if db_post:
                # Durumu 'success' veya 'failed' olarak güncelle
                if status == "success":
                    print(f"URN '{urn}' için çeviri başarılı. Durum güncelleniyor.")
                    showcase_crud.update_post_translation_status(db, db_post=db_post, status="success")
                else:
                    print(f"URN '{urn}' için çeviri başarısız. Durum güncelleniyor.")
                    showcase_crud.update_post_translation_status(db, db_post=db_post, status="failed")
            else:
                print(f"Veritabanında URN '{urn}' ile eşleşen gönderi bulunamadı.")

        return {"status": "received"}

    except Exception as e:
        print(f"APS webhook işlenirken hata oluştu: {e!r}")
        raise HTTPException(status_code=400, detail="Geçersiz payload")