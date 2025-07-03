from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

# --- DOĞRU IMPORT'LAR ---
from app.schemas import work_experience as work_experience_schema
from app.crud import work_experience as work_experience_crud
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
# --- BİTTİ ---

router = APIRouter(
    prefix="/work-experiences",
    tags=["Work Experiences"]
)

@router.post("/me", response_model=work_experience_schema.WorkExperience, status_code=status.HTTP_201_CREATED)
def add_experience_for_current_user(
    experience: work_experience_schema.WorkExperienceCreate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    return work_experience_crud.create_user_experience(db=db, experience=experience, user_id=current_user.id)

# TODO: Get, Update, Delete endpoint'leri buraya eklenebilir.