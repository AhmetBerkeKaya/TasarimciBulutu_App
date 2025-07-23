# app/crud/showcase.py

from sqlalchemy.orm import Session
from app import models, schemas
import uuid

from urllib.parse import urljoin
from app.config import settings

def create_showcase_post(db: Session, post: schemas.showcase.ShowcasePostCreate, user_id: uuid.UUID) -> models.showcase.ShowcasePost:
    # Eğer mobil taraf URL göndermiyorsa backend'te oluştur
    if post.file_url:
        base_url = f"https://{settings.AWS_S3_BUCKET_NAME}.s3.{settings.AWS_REGION}.amazonaws.com/"
        corrected_file_url = urljoin(base_url, post.file_url) if not post.file_url.startswith("http") else post.file_url
    else:
        corrected_file_url = None

    db_post = models.showcase.ShowcasePost(
        title=post.title,
        description=post.description,
        file_url=corrected_file_url,
        thumbnail_url=None,
        user_id=user_id
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    return db_post

# ... (diğer tüm CRUD fonksiyonları aynı kalacak) ...
def get_showcase_post(db: Session, post_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    return db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
def get_all_showcase_posts(db: Session, skip: int = 0, limit: int = 100) -> list[models.showcase.ShowcasePost]:
    return db.query(models.showcase.ShowcasePost).order_by(models.showcase.ShowcasePost.created_at.desc()).offset(skip).limit(limit).all()
def delete_showcase_post(db: Session, post_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.ShowcasePost | None:
    db_post = db.query(models.showcase.ShowcasePost).filter(models.showcase.ShowcasePost.id == post_id).first()
    if db_post and db_post.user_id == user_id:
        db.delete(db_post)
        db.commit()
        return db_post
    return None
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
    db_comment = models.showcase.PostComment(content=comment.content, post_id=comment.post_id, parent_comment_id=comment.parent_comment_id, user_id=user_id)
    db.add(db_comment); db.commit(); db.refresh(db_comment); return db_comment
def get_comments_for_post(db: Session, post_id: uuid.UUID) -> list[models.showcase.PostComment]:
    return db.query(models.showcase.PostComment).filter(models.showcase.PostComment.post_id == post_id).order_by(models.showcase.PostComment.created_at.asc()).all()
def delete_comment(db: Session, comment_id: uuid.UUID, user_id: uuid.UUID) -> models.showcase.PostComment | None:
    db_comment = db.query(models.showcase.PostComment).filter(models.showcase.PostComment.id == comment_id).first()
    if db_comment and (db_comment.user_id == user_id or db_comment.post.user_id == user_id):
        db.delete(db_comment); db.commit(); return db_comment
    return None
