# app/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

# --- DEĞİŞEN KISIM BURASI ---
from app import database, security
from app.crud import user as user_crud # user'a user_crud takma adını verelim
from app.schemas.token import Token # Token şemasını doğrudan kendi dosyasından import edelim
# --- DEĞİŞİMİN SONU ---

router = APIRouter(
    tags=["authentication"]
)

# Dependency to get the DB session
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/token", response_model=Token) # response_model'i direkt Token olarak kullanabiliriz
def login_for_access_token(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    # Not: OAuth2PasswordRequestForm 'username' ve 'password' alanlarını kullanır.
    # Flutter'dan istek atarken e-posta adresini 'username' alanına göndereceğiz.
    user = user_crud.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )

    return {"access_token": access_token, "token_type": "bearer"}