# routers/auth.py

# --- YENİ İMPORTLAR ---
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import timedelta
from jose import JWTError, jwt

from app import database, security
from app.crud import user as user_crud
# Token ve YENİ RefreshTokenRequest şemalarını import ediyoruz
from app.schemas.token import Token, RefreshTokenRequest, TokenData 
from app.config import settings # Ayarları import ediyoruz
from slowapi import Limiter # Limiter'ı import ediyoruz
from slowapi.util import get_remote_address # IP adresi için helper

# --- YENİ İMPORTLAR SONU ---

router = APIRouter(
    tags=["authentication"]
)

# --- YENİ: RATE LIMITER'I BU ROUTER İÇİN ÖZELLEŞTİRME ---
# Giriş denemelerini sınırlamak çok önemlidir.
limiter = Limiter(key_func=get_remote_address)
# --- YENİ: RATE LIMITER SONU ---

# Dependency to get the DB session
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- YENİ: REFRESH TOKEN'I DOĞRULAMAK İÇİN DEPENDENCY ---
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token") # Bu zaten vardı, şimdi kullanacağız

def get_current_user_from_refresh_token(
    db: Session = Depends(get_db), 
    token_data: RefreshTokenRequest = Depends()
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate refresh token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token_data.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        # Token'ın bir refresh token olduğunu doğrulayalım (isteğe bağlı ama güvenli)
        if payload.get("type") != "refresh":
            raise credentials_exception
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data_schema = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    
    user = user_crud.get_user_by_email(db, email=token_data_schema.email)
    if user is None:
        raise credentials_exception
    return user
# --- YENİ DEPENDENCY SONU ---


@router.post("/token", response_model=Token)
# YENİ: Bu endpoint'e özel rate limit ekliyoruz. 15 dakikada 5 deneme hakkı.
@limiter.limit("5/15minute")
def login_for_access_token(request: Request, db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = user_crud.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Hem access hem de refresh token oluşturuyoruz
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    refresh_token = security.create_refresh_token(
        data={"sub": user.email}
    )

    # İki token'ı da döndürüyoruz
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}


# --- YENİ ENDPOINT ---
@router.post("/token/refresh", response_model=Token)
# Bu endpoint'i de limitleyelim, kötüye kullanılmasın.
@limiter.limit("10/minute")
def refresh_access_token(request: Request, db: Session = Depends(get_db), token_data: RefreshTokenRequest = Depends()):
    """
    Geçerli bir refresh token ile yeni bir access ve refresh token çifti alır.
    Güvenlik için her refresh işleminde yeni bir refresh token da döndürmek iyi bir pratiktir.
    """
    user = get_current_user_from_refresh_token(db, token_data) # Dependency'yi burada çağırıyoruz
    if not user:
         raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Kullanıcı geçerliyse, yeni bir access token ve yeni bir refresh token oluştur
    new_access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    new_access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=new_access_token_expires
    )
    new_refresh_token = security.create_refresh_token(
        data={"sub": user.email}
    )
    
    return {"access_token": new_access_token, "refresh_token": new_refresh_token, "token_type": "bearer"}
# --- YENİ ENDPOINT SONU ---
