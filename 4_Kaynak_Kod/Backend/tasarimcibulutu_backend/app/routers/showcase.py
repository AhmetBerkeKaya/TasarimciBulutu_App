# app/routers/showcase.py

import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import List
import mimetypes
from urllib.parse import urljoin

from app import crud, schemas, models
from app.dependencies import get_db, get_current_user
from app.utils import s3 as s3_utils
from app.config import settings
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(
    prefix="/showcase",
    tags=["Showcase"]
)

@router.post("/upload-url", response_model=schemas.showcase.PresignedUrlResponse)
@limiter.limit("60/minute")
def create_upload_url(
    request: Request,
    url_request: schemas.showcase.PresignedUrlRequest,
    current_user: models.User = Depends(get_current_user)
):
    file_extension = mimetypes.guess_extension(url_request.content_type) or ''
    unique_filename = f"users/{current_user.id}/posts/{uuid.uuid4()}{file_extension}"
    
    conditions = [
        ["content-length-range", 1, 15728640],
        ["starts-with", "$Content-Type", "image/"]
    ]

    response_data = s3_utils.create_presigned_post_url(
        bucket_name=settings.AWS_S3_BUCKET_NAME,
        object_name=unique_filename,
        conditions=conditions
    )
    
    if response_data is None:
        raise HTTPException(status_code=500, detail="Could not generate upload URL")
        
    # --- SON DÜZELTME: URL BİRLEŞTİRME ---
    # URL'in sonunda / olduğundan emin oluyoruz.
    base_url = f"https://{settings.AWS_S3_BUCKET_NAME}.s3.{settings.AWS_REGION}.amazonaws.com/"
    
    # Python'un en güvenli yoluyla birleştiriyoruz.
    final_url = urljoin(base_url, unique_filename)
    
    response_data['url'] = base_url # Yükleme adresi / olmadan olabilir
    response_data['final_file_url'] = final_url
        
    return response_data


@router.post("/posts", response_model=schemas.showcase.ShowcasePost, status_code=status.HTTP_201_CREATED)
@limiter.limit("20/hour")
def create_post(
    request: Request,
    post: schemas.showcase.ShowcasePostCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Yeni bir vitrin gönderisi oluşturur."""
    return crud.showcase.create_showcase_post(db=db, post=post, user_id=current_user.id)

# ... (diğer tüm endpoint'leriniz aynı kalacak) ...
@router.get("/posts", response_model=List[schemas.showcase.ShowcasePost])
@limiter.limit("60/minute")
def read_all_posts(request: Request, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    return crud.showcase.get_all_showcase_posts(db=db, skip=skip, limit=limit)

@router.get("/posts/{post_id}", response_model=schemas.showcase.ShowcasePost)
@limiter.limit("120/minute")
def read_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db)):
    db_post = crud.showcase.get_showcase_post(db, post_id=post_id)
    if not db_post: raise HTTPException(status_code=404, detail="Post not found")
    return db_post

@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("10/hour")
def delete_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    deleted_post = crud.showcase.delete_showcase_post(db, post_id=post_id, user_id=current_user.id)
    if not deleted_post:
        raise HTTPException(status_code=403, detail="Post not found or you don't have permission to delete it")
    return

@router.post("/posts/{post_id}/like", response_model=schemas.showcase.PostLike, status_code=status.HTTP_201_CREATED)
@limiter.limit("100/minute")
def like_a_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    like = crud.showcase.like_post(db, post_id=post_id, user_id=current_user.id)
    if not like:
        raise HTTPException(status_code=404, detail="Post not found")
    return like

@router.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("100/minute")
def unlike_a_post(request: Request, post_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    success = crud.showcase.unlike_post(db, post_id=post_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Like not found")
    return

@router.post("/posts/{post_id}/comments", response_model=schemas.showcase.Comment, status_code=status.HTTP_201_CREATED)
@limiter.limit("30/hour")
def create_a_comment(request: Request, post_id: uuid.UUID, comment_data: schemas.showcase.CommentBase, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    comment_create_schema = schemas.showcase.CommentCreate(content=comment_data.content, post_id=post_id)
    return crud.showcase.create_comment(db, comment=comment_create_schema, user_id=current_user.id)

@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("20/hour")
def delete_a_comment(request: Request, comment_id: uuid.UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    deleted_comment = crud.showcase.delete_comment(db, comment_id=comment_id, user_id=current_user.id)
    if not deleted_comment:
        raise HTTPException(status_code=403, detail="Comment not found or you don't have permission to delete it")
    return
