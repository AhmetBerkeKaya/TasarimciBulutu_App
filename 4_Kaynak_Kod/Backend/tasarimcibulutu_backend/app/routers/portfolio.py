import shutil
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
import uuid # uuid'yi de import edelim

# --- DOĞRU IMPORT'LAR ---
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.models.portfolio import PortfolioItem as PortfolioItemModel
from app.schemas.portfolio import PortfolioItem as PortfolioItemSchema
from app.schemas.portfolio import PortfolioItemCreate
# --- BİTTİ ---

router = APIRouter(
    prefix="/portfolio",
    tags=["portfolio"]
)

@router.post("/users/me/items", response_model=PortfolioItemSchema, status_code=201)
def create_portfolio_item_for_current_user(
    title: str = Form(...),
    description: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    # Dosya adını güvenli hale getir ve benzersiz bir isim oluştur
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = f"static/images/{unique_filename}"

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    item_data = PortfolioItemCreate(title=title, description=description)

    # CRUD işlemini burada yapalım
    db_item = PortfolioItemModel(
        **item_data.dict(), 
        user_id=current_user.id, 
        image_url=file_path # Veritabanına kaydedilecek yol
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@router.get("/users/{user_id}/items", response_model=List[PortfolioItemSchema])
def read_user_portfolio_items(user_id: UUID, db: Session = Depends(get_db)):
    items = db.query(PortfolioItemModel).filter(PortfolioItemModel.user_id == str(user_id)).all()
    return items