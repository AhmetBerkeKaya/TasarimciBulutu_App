# app/schemas/portfolio.py
from pydantic import BaseModel, UUID4
from typing import Optional

class PortfolioItemBase(BaseModel):
    title: str
    description: Optional[str] = None

class PortfolioItemCreate(PortfolioItemBase):
    pass

class PortfolioItem(PortfolioItemBase):
    id: UUID4
    image_url: str

    class Config:
        from_attributes = True