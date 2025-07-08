# app/routers/review.py
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import crud, models, schemas
from app.dependencies import get_db, get_current_user

router = APIRouter(
    prefix="/reviews",
    tags=["Reviews"]
)

@router.post("/", response_model=schemas.Review, status_code=status.HTTP_201_CREATED)
def create_review(
    review: schemas.ReviewCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Yeni bir değerlendirme oluşturur.
    - Sadece tamamlanmış projeler için değerlendirme yapılabilir.
    - Kullanıcılar sadece dahil oldukları projeler için yorum yapabilir.
    - Bir proje için sadece bir kez yorum yapılabilir.
    - Kullanıcı kendine yorum yapamaz.
    """
    reviewer_id = current_user.id
    
    # 1. Doğrulama: Kullanıcı kendine yorum yapamaz.
    if reviewer_id == review.reviewee_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot review yourself."
        )

    # 2. Doğrulama: Proje var mı ve tamamlanmış mı?
    project = crud.project.get_project(db, project_id=review.project_id)
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found.")
    
    if project.status != models.ProjectStatus.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reviews can only be submitted for completed projects."
        )

    # 3. Doğrulama: Değerlendirmeyi yapan ve yapılan kişiler projeye dahil mi?
    # Proje sahibi (firma) ve kabul edilen freelancer ID'lerini bul.
    project_owner_id = project.user_id
    accepted_freelancer = crud.application.get_accepted_application_for_project(db, project_id=project.id)
    
    if not accepted_freelancer:
         raise HTTPException(status_code=404, detail="No accepted freelancer found for this project.")

    freelancer_id = accepted_freelancer.freelancer_id
    
    # Değerlendirmeyi yapan ve yapılan kişilerin ID'leri, proje sahibi ve freelancer ID'leri ile eşleşmeli.
    valid_parties = {project_owner_id, freelancer_id}
    if not {reviewer_id, review.reviewee_id}.issubset(valid_parties):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to review this user for this project."
        )

    # 4. Doğrulama: Bu proje için daha önce yorum yapılmış mı?
    existing_review = crud.review.get_review_by_reviewer_and_project(
        db, reviewer_id=reviewer_id, project_id=review.project_id
    )
    if existing_review:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already submitted a review for this project."
        )

    # Tüm doğrulamalar geçerliyse, değerlendirmeyi oluştur.
    return crud.review.create_review(db=db, review=review, reviewer_id=reviewer_id)