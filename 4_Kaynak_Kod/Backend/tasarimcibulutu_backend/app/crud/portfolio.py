from sqlalchemy.orm import Session
from uuid import UUID

from app.models.portfolio import PortfolioItem
from app.schemas.portfolio import PortfolioItemCreate

# --- EKSİK OLAN FONKSİYON ---
def get_portfolio_item(db: Session, item_id: UUID) -> PortfolioItem | None:
    return db.query(PortfolioItem).filter(PortfolioItem.id == str(item_id)).first()
# --- BİTTİ ---

def create_portfolio_item(db: Session, item: PortfolioItemCreate, user_id: UUID, image_url: str) -> PortfolioItem:
    # Pydantic modelindeki verileri ve ek verileri birleştirerek
    # SQLAlchemy modelini oluşturuyoruz.
    # --- DOĞRU KULLANIM AŞAĞIDAKİ GİBİDİR ---
    db_item = PortfolioItem(
        **item.model_dump(), 
        user_id=user_id, 
        image_url=image_url
    )
    # --- BİTTİ ---
    
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

def delete_portfolio_item(db: Session, db_item: PortfolioItem) -> PortfolioItem:
    # TODO: Fiziksel dosyayı da diskten silmek için buraya bir os.remove(db_item.image_url) eklenebilir.
    db.delete(db_item)
    db.commit()
    return db_item