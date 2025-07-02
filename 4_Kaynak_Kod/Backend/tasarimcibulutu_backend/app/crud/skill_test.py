from sqlalchemy.orm import Session
from app import models, schemas
from uuid import uuid4
from typing import List


def get_skill_test(db: Session, test_id: str):
    return db.query(models.SkillTest).filter(models.SkillTest.id == test_id).first()


def get_skill_tests(db: Session, skip: int = 0, limit: int = 100) -> List[models.SkillTest]:
    return db.query(models.SkillTest).offset(skip).limit(limit).all()


def create_skill_test(db: Session, test: schemas.SkillTestCreate):
    db_test = models.SkillTest(
        id=uuid4(),
        title=test.title,
        description=test.description,
        software=test.software,
        # created_at veritabanı default, burada vermeye gerek yok
    )
    db.add(db_test)
    db.commit()
    db.refresh(db_test)
    return db_test


def update_skill_test(db: Session, test_id: str, test_update: schemas.SkillTestUpdate):
    db_test = get_skill_test(db, test_id)
    if not db_test:
        return None
    update_data = test_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_test, key, value)
    db.commit()
    db.refresh(db_test)
    return db_test


def delete_skill_test(db: Session, test_id: str):
    db_test = get_skill_test(db, test_id)
    if not db_test:
        return None
    db.delete(db_test)
    db.commit()
    return db_test
