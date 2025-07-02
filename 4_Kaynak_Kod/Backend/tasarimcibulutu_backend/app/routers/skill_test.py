from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import UUID4

from app import crud, schemas, database

router = APIRouter(
    prefix="/skill_tests",
    tags=["skill_tests"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=schemas.SkillTest)
def create_skill_test(skill_test: schemas.SkillTestCreate, db: Session = Depends(get_db)):
    return crud.create_skill_test(db, test=skill_test)


@router.get("/", response_model=List[schemas.SkillTest])
def read_skill_tests(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    skill_tests = crud.get_skill_tests(db, skip=skip, limit=limit)
    return skill_tests


@router.get("/{skill_test_id}", response_model=schemas.SkillTest)
def read_skill_test(skill_test_id: UUID4, db: Session = Depends(get_db)):
    db_skill_test = crud.get_skill_test(db, test_id=skill_test_id)
    if not db_skill_test:
        raise HTTPException(status_code=404, detail="Skill test not found")
    return db_skill_test


@router.put("/{skill_test_id}", response_model=schemas.SkillTest)
def update_skill_test(skill_test_id: UUID4, skill_test_update: schemas.SkillTestUpdate, db: Session = Depends(get_db)):
    updated_skill_test = crud.update_skill_test(db, test_id=skill_test_id, test_update=skill_test_update)
    if not updated_skill_test:
        raise HTTPException(status_code=404, detail="Skill test not found")
    return updated_skill_test


@router.delete("/{skill_test_id}", response_model=schemas.SkillTest)
def delete_skill_test(skill_test_id: UUID4, db: Session = Depends(get_db)):
    deleted_skill_test = crud.delete_skill_test(db, test_id=skill_test_id)
    if not deleted_skill_test:
        raise HTTPException(status_code=404, detail="Skill test not found")
    return deleted_skill_test
