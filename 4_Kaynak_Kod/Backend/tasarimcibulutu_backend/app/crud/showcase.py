# tasarimcibulutu_backend/app/crud/showcase.py

from sqlalchemy.orm import Session, joinedload
from uuid import UUID

from app.models import showcase as models
from app.schemas import showcase as schemas


def get_showcase_post(db: Session, *, post_id: UUID) -> models.ShowcasePost | None:
    """ID'ye göre tek bir vitrin gönderisini getirir."""
    return db.query(models.ShowcasePost).filter(models.ShowcasePost.id == post_id).first()


def get_all_showcase_posts(db: Session, *, skip: int = 0, limit: int = 20) -> list[models.ShowcasePost]:
    """
    Tüm vitrin gönderilerini sayfalamalı olarak getirir.
    En yeni gönderi en üstte olacak şekilde sıralar.
    'joinedload' kullanarak N+1 sorgu problemini önleriz (performans için).
    """
    return (
        db.query(models.ShowcasePost)
        .order_by(models.ShowcasePost.created_at.desc())
        .options(joinedload(models.ShowcasePost.owner))
        .offset(skip)
        .limit(limit)
        .all()
    )


def create_showcase_post(
    db: Session,
    *,
    post_in: schemas.ShowcasePostCreate,
    owner_id: UUID,
    original_filename: str,
    storage_path: str,
    file_format: str,
) -> models.ShowcasePost:
    """Veritabanında yeni bir vitrin gönderisi oluşturur."""
    # Pydantic V2'de .dict() yerine .model_dump() kullanılır.
    db_post = models.ShowcasePost(
        **post_in.model_dump(),
        owner_id=owner_id,
        original_filename=original_filename,
        storage_path=storage_path,
        file_format=file_format
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    return db_post


def update_showcase_post(
    db: Session, *, db_post: models.ShowcasePost, post_in: schemas.ShowcasePostUpdate
) -> models.ShowcasePost:
    """Mevcut bir gönderiyi günceller."""
    # .model_dump(exclude_unset=True) sadece gönderilen alanları alır.
    update_data = post_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_post, key, value)

    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    return db_post


def delete_showcase_post(db: Session, *, db_post: models.ShowcasePost) -> models.ShowcasePost:
    """Bir gönderiyi veritabanından siler."""
    db.delete(db_post)
    db.commit()
    return db_post

# --- APS için Özel Fonksiyonlar ---

def update_post_urn_and_status(db: Session, *, db_post: models.ShowcasePost, urn: str, status: str = "inprogress") -> models.ShowcasePost:
    db_post.aps_urn = urn
    db_post.aps_translation_status = status # Artık status parametresini kullanıyor
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    return db_post

def get_post_by_urn(db: Session, *, urn: str) -> models.ShowcasePost | None:
    """URN'ye göre tek bir vitrin gönderisini getirir."""
    return db.query(models.ShowcasePost).filter(models.ShowcasePost.aps_urn == urn).first()


def update_post_translation_status(db: Session, *, db_post: models.ShowcasePost, status: str) -> models.ShowcasePost:
    """Bir gönderinin sadece çeviri durumunu günceller."""
    db_post.aps_translation_status = status
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    return db_post