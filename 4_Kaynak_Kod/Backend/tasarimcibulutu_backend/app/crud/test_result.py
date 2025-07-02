from sqlalchemy.orm import Session
from app import models, schemas
from uuid import uuid4
from typing import List

def get_test_result(db: Session, result_id: str):
    return db.query(models.TestResult).filter(models.TestResult.id == result_id).first()

def get_test_results(db: Session, skip: int = 0, limit: int = 100) -> List[models.TestResult]:
    return db.query(models.TestResult).offset(skip).limit(limit).all()

def get_results_by_user(db: Session, user_id: str) -> List[models.TestResult]:
    return db.query(models.TestResult).filter(models.TestResult.user_id == user_id).all()

def get_results_by_test(db: Session, test_id: str) -> List[models.TestResult]:
    return db.query(models.TestResult).filter(models.TestResult.test_id == test_id).all()

def create_test_result(db: Session, result: schemas.TestResultCreate):
    db_result = models.TestResult(
        id=uuid4(),
        user_id=result.user_id,
        test_id=result.test_id,
        score=result.score,
        completed_at=result.completed_at,
    )
    db.add(db_result)
    db.commit()
    db.refresh(db_result)
    return db_result

def update_test_result(db: Session, result_id: str, result_update: schemas.TestResultUpdate):
    db_result = get_test_result(db, result_id)
    if not db_result:
        return None
    update_data = result_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_result, key, value)
    db.commit()
    db.refresh(db_result)
    return db_result

def delete_test_result(db: Session, result_id: str):
    db_result = get_test_result(db, result_id)
    if not db_result:
        return None
    db.delete(db_result)
    db.commit()
    return db_result
