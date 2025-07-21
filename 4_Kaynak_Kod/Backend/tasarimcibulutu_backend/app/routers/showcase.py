# tasarimcibulutu_backend/app/routers/showcase.py

import uuid
import os
import shutil
from typing import List
from uuid import UUID
from app.services.aps_services import APSService 

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, BackgroundTasks
from sqlalchemy.orm import Session

# Projenizdeki diğer dosyalardan gerekli fonksiyonları ve modelleri import ediyoruz.
# Bu yolların projenizdeki yapıyla eşleştiğinden emin olun.
from app import models, schemas
from app.crud import showcase as crud
from app.dependencies import get_db
from app.dependencies import get_current_user # Kullanıcı doğrulama fonksiyonunuz

# --- Router Kurulumu ---
router = APIRouter(
    prefix="/showcase",
    tags=["Showcase"],
    responses={404: {"description": "Not found"}},
)

# --- Dosya Kaydetme için Ayarlar ---
# Yüklenen dosyaların kaydedileceği klasör
UPLOAD_DIRECTORY = "static/uploads/showcase"
# Klasörün var olduğundan emin olalım
os.makedirs(UPLOAD_DIRECTORY, exist_ok=True)


# --- ARKA PLAN GÖREVİ (APS için) ---
# Bu fonksiyon, API yanıtını bekletmeden APS çevirisini başlatacak.
def trigger_aps_translation(post_id: UUID, db: Session):
    # TODO: Bu kısım daha sonra APS servis mantığı ile doldurulacak.
    # 1. Post bilgisini DB'den al.
    # 2. Dosya yolunu al.
    # 3. ngrok URL'i ile birleştirip genel bir URL oluştur.
    # 4. APS'e "bu dosyayı çevir" isteği gönder.
    # 5. APS'ten gelen URN'yi DB'deki ilgili gönderiye kaydetmek için CRUD'u çağır.
    print(f"APS translation triggered in background for post ID: {post_id}")
    # Örnek: aps_service.start_translation(db_post=db_post, public_file_url=...)
    pass


# --- API ENDPOINT'LERİ ---

@router.post("/", response_model=schemas.ShowcasePostRead, status_code=status.HTTP_201_CREATED)
def create_showcase_post(
    background_tasks: BackgroundTasks,
    title: str = Form(...),
    description: str = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Yeni bir vitrin gönderisi oluşturur ve arka planda APS çeviri işlemini tetikler.
    """
    # ... (dosyayı sunucuya kaydetme ve veritabanı kaydı oluşturma kısımları aynı) ...
    # 1. Dosyayı sunucuya kaydet
    file_extension = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    storage_path = os.path.join(UPLOAD_DIRECTORY, unique_filename)
    
    try:
        with open(storage_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    finally:
        file.file.close()

    # 2. Veritabanına kaydet
    post_in = schemas.ShowcasePostCreate(title=title, description=description)
    db_post = crud.create_showcase_post(
        db=db,
        post_in=post_in,
        owner_id=current_user.id,
        original_filename=file.filename,
        storage_path=storage_path,
        file_format=file_extension.lstrip('.')
    )

    # --- DEĞİŞİKLİK BURADA ---
    # 3. Arka planda APS çevirisini tetikle
    # Artık placeholder yerine gerçek servis fonksiyonunu çağırıyoruz.
    aps_service = APSService()
    background_tasks.add_task(aps_service.trigger_translation, db, db_post)
    # --- DEĞİŞİKLİK SONU ---

    return db_post

@router.get("/", response_model=List[schemas.ShowcasePostRead])
def read_all_showcase_posts(
    skip: int = 0, limit: int = 20, db: Session = Depends(get_db)
):
    """
    Tüm vitrin gönderilerini sayfalamalı olarak listeler.
    """
    posts = crud.get_all_showcase_posts(db, skip=skip, limit=limit)
    return posts


@router.get("/{post_id}", response_model=schemas.ShowcasePostRead)
def read_showcase_post(post_id: UUID, db: Session = Depends(get_db)):
    """
    Belirli bir ID'ye sahip tek bir vitrin gönderisini getirir.
    """
    db_post = crud.get_showcase_post(db, post_id=post_id)
    if db_post is None:
        raise HTTPException(status_code=404, detail="Post not found")
    return db_post


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_showcase_post(
    post_id: UUID,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Bir vitrin gönderisini siler. Sadece gönderinin sahibi silebilir.
    """
    db_post = crud.get_showcase_post(db, post_id=post_id)
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
    if db_post.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")

    # Sunucudaki dosyayı sil
    if os.path.exists(db_post.storage_path):
        os.remove(db_post.storage_path)

    # Veritabanından kaydı sil
    crud.delete_showcase_post(db=db, db_post=db_post)
    # 204 yanıtı gövde içermez, bu yüzden bir şey return etmiyoruz.
    return