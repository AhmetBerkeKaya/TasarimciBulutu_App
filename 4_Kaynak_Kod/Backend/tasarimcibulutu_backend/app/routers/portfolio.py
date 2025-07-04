# app/routers/portfolio.py
import shutil
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from app.dependencies import get_db, get_current_user
from app.models.user import User as UserModel
from app.models.portfolio import PortfolioItem as PortfolioItemModel
from app.schemas.portfolio import PortfolioItem as PortfolioItemSchema, PortfolioItemCreate
from app.crud import portfolio as portfolio_crud

router = APIRouter(
    prefix="/portfolio",
    tags=["Portfolio"]
)

@router.post("/items", response_model=PortfolioItemSchema, status_code=status.HTTP_201_CREATED)
def create_portfolio_item_for_current_user(
    title: str = Form(...),
    description: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = f"static/images/{unique_filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    item_data = PortfolioItemCreate(title=title, description=description)
    
    return portfolio_crud.create_portfolio_item(
        db=db, item=item_data, user_id=current_user.id, image_url=file_path
    )

@router.delete("/items/{item_id}", response_model=PortfolioItemSchema)
def delete_portfolio_item_for_current_user(
    item_id: UUID,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    db_item = portfolio_crud.get_portfolio_item(db, item_id=item_id)
    if not db_item:
        raise HTTPException(status_code=404, detail="Portfolio item not found")
    if db_item.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this item")
    
    # TODO: Diskteki fiziksel dosyayı da silmek iyi bir pratiktir (os.remove(db_item.image_url))
    return portfolio_crud.delete_portfolio_item(db, db_item=db_item)

# Not: /users/{user_id}/items endpoint'i artık gereksiz, çünkü bu bilgiyi /users/me ile alıyoruz.
# İstersen bu endpoint'i silebilirsin.