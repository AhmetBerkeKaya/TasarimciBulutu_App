# app/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

# --- DOĞRU IMPORT'LAR ---
from app import database, security
from app.crud import user as user_crud
from app.schemas.token import TokenData # <-- TokenData'yı doğrudan kendi dosyasından alıyoruz
# --- BİTTİ ---

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Bu fonksiyonun adını eski haline getirelim, çünkü router'larda bunu kullanıyorduk.
def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, security.SECRET_KEY, algorithms=[security.ALGORITHM])
        email: str | None = payload.get("sub")
        if email is None:
            raise credentials_exception
        # TokenData'yı burada artık tanıyor
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception

    user = user_crud.get_user_by_email(db, email=token_data.email)
    if user is None:
        raise credentials_exception
    return user