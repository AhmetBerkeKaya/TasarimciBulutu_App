# app/crud/test_result.py
import uuid
from sqlalchemy.orm import Session
from app import models, schemas
from datetime import datetime
from decimal import Decimal
from sqlalchemy import and_

def create_test_result(db: Session, user_id: uuid.UUID, test_id: uuid.UUID):
    """
    Kullanıcı bir teste başladığında yeni bir TestResult kaydı oluşturur.
    """
    db_test_result = models.TestResult(
        user_id=user_id,
        test_id=test_id,
        status=models.TestStatus.IN_PROGRESS
    )
    db.add(db_test_result)
    db.commit()
    db.refresh(db_test_result)
    return db_test_result

def get_test_result(db: Session, result_id: uuid.UUID):
    """
    ID'ye göre tek bir test sonucunu getirir.
    """
    return db.query(models.TestResult).filter(models.TestResult.id == result_id).first()

def calculate_and_complete_test(db: Session, result_id: uuid.UUID, submission: schemas.TestSubmission):
    """
    Kullanıcının gönderdiği cevapları alır, puanı hesaplar ve test sonucunu günceller.
    """
    db_test_result = get_test_result(db, result_id)
    if not db_test_result:
        return None

    # 1. Adım: Testteki tüm soruların doğru cevaplarını al
    correct_answers = db.query(models.Choice).join(models.Question).filter(
        models.Question.test_id == db_test_result.test_id,
        models.Choice.is_correct == True
    ).all()
    
    # Hızlı arama için doğru cevapları bir sözlüğe (dictionary) atayalım
    correct_choices_map = {choice.question_id: choice.id for choice in correct_answers}
    
    # 2. Adım: Puanı hesapla
    score = 0
    total_questions = len(correct_choices_map)
    
    for answer in submission.answers:
        # Kullanıcının cevabının doğru olup olmadığını kontrol et
        if correct_choices_map.get(answer.question_id) == answer.selected_choice_id:
            score += 1
            
    # Yüzdelik puanı hesapla (Numeric/Decimal olarak)
    final_score = (Decimal(score) / Decimal(total_questions)) * 100 if total_questions > 0 else 0

    # 3. Adım: Test sonucunu güncelle
    db_test_result.score = final_score
    db_test_result.status = models.TestStatus.COMPLETED
    db_test_result.completed_at = datetime.utcnow()
    
    db.add(db_test_result)
    db.commit()
    db.refresh(db_test_result)
    
    return db_test_result

def get_completed_test_by_user_and_test(db: Session, user_id: uuid.UUID, test_id: uuid.UUID):
    """
    Belirli bir kullanıcının, belirli bir testi daha önce tamamlayıp tamamlamadığını kontrol eder.
    """
    return db.query(models.TestResult).filter(
        and_(
            models.TestResult.user_id == user_id,
            models.TestResult.test_id == test_id,
            models.TestResult.status == models.TestStatus.COMPLETED
        )
    ).first()