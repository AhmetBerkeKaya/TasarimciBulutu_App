from sqlalchemy.orm import Session
from app import models, schemas
import uuid
from app.models.showcase import ProcessingStatus
from . import audit as audit_crud # <-- YENİ: Denetim CRUD'unu import ediyoruz


def create_showcase_post(db: Session, post: schemas.showcase.ShowcasePostCreate | schemas.showcase.ShowcasePostInit, user_id: uuid.UUID, status: ProcessingStatus = ProcessingStatus.COMPLETED) -> models.showcase.ShowcasePost:
    
    db_post = models.showcase.ShowcasePost(
        title=post.title,
        description=post.description,
        user_id=user_id,
        processing_status=status
    )
    
    if isinstance(post, schemas.showcase.ShowcasePostCreate):
        db_post.file_url=post.file_url
        db_post.thumbnail_url=post.thumbnail_url
        db_post.model_url=post.model_url
        db_post.model_format=post.model_format

    db.add(db_post)
    
    # ================== DENETİM KAYDI EKLENDİ ==================
    # Commit'ten hemen önce, post ID'si oluştuktan sonra loglama yapıyoruz.
    # Flush, ID'nin veritabanı tarafından atanmasını sağlar ama işlemi sonlandırmaz.
    db.flush() 
    
    audit_crud.create_audit_log(
        db,
        user_id=user_id, # İşlemden etkilenen kullanıcı (gönderi sahibi)
        action="SHOWCASE_POST_CREATED",
        details={"post_id": str(db_post.id), "title": db_post.title}
    )
    # ==========================================================

    db.commit()
    db.refresh(db_post)
    return db_post

def get_showcase_post(db: Session, post_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    return db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()

def get_all_showcase_posts(db: Session, skip: int = 0, limit: int = 100) -> list[models.showcase.ShowcasePost]:
    return db.query(models.showcase.ShowcasePost).order_by(models.showcase.ShowcasePost.created_at.desc()).offset(skip).limit(limit).all()

# ================== BU FONKSİYON GÜNCELLENDİ ==================
def delete_showcase_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    
    # Silme yetkisi kontrolü
    if db_post and db_post.user_id == user_id:
        
        # ================== DENETİM KAYDI EKLENDİ ==================
        # Gönderi silinmeden hemen önce neyin silindiğini kaydediyoruz.
        audit_crud.create_audit_log(
            db,
            user_id=db_post.user_id, # İşlemden etkilenen kullanıcı (gönderi sahibi)
            actor_id=user_id, # İşlemi yapan kullanıcı
            action="SHOWCASE_POST_DELETED",
            details={"post_id": str(db_post.id), "title": db_post.title}
        )
        # ==========================================================

        db.delete(db_post)
        db.commit()
        return db_post
        
    return None
# =============================================================

def like_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostLike | None:
    db_post = get_showcase_post(db, post_id)
    if not db_post: return None
    db_like = db.query(models.showcase.PostLike).filter(models.showcase.PostLike.post_id == post_id, models.showcase.PostLike.user_id == user_id).first()
    if db_like: return db_like
    new_like = models.showcase.PostLike(post_id=post_id, user_id=user_id); db.add(new_like); db.commit(); db.refresh(new_like); return new_like

def unlike_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    db_like = db.query(models.showcase.PostLike).filter(models.showcase.PostLike.post_id == post_id, models.showcase.PostLike.user_id == user_id).first()
    if db_like: db.delete(db_like); db.commit(); return True
    return False

def create_comment(db: Session, comment: schemas.showcase.CommentCreate, user_id: uuid.UUID) -> models.showcase.PostComment:
    
    db_comment = models.showcase.PostComment(
        content=comment.content,
        post_id=comment.post_id,
        parent_comment_id=comment.parent_comment_id,
        user_id=user_id
    )
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)
    return db_comment

def get_comments_for_post(db: Session, post_id: uuid.UUID) -> list[models.showcase.PostComment]:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.post_id == post_id).order_by(models.showcase.PostComment.created_at.asc()).all()

def delete_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostComment | None:
    db_comment = db.query(models.showcase.PostComment).filter(models.showcase.PostComment.id == comment_id).first()
    if db_comment and (db_comment.user_id == user_id or db_comment.post.user_id == user_id):
        db.delete(db_comment); db.commit(); return db_comment
    return None

def get_comment(db: Session, comment_id: uuid.UUID) -> models.showcase.PostComment | None:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.id == comment_id).first()

def like_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.CommentLike | None:
    if not get_comment(db, comment_id):
        return None
    
    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    if db_like:
        return db_like
        
    new_like = models.showcase.CommentLike(comment_id=comment_id, user_id=user_id)
    db.add(new_like)
    db.commit()
    db.refresh(new_like)
    return new_like

def unlike_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    db_like = db.query(models.showcase.CommentLike).filter_by(comment_id=comment_id, user_id=user_id).first()
    if db_like:
        db.delete(db_like)
        db.commit()
        return True
    return False

def update_post_raw_file_url(db: Session, post_id: uuid.UUID, file_url: str):
    db_post = db.query(models.ShowcasePost).filter(models.ShowcasePost.id == post_id).first()
    if db_post:
        db_post.file_url = file_url
        db.commit()
        db.refresh(db_post)
    return db_post
