# app/models/question.py
from sqlalchemy import Column, Integer, String, Text, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True, index=True)
    test_id = Column(Integer, ForeignKey("skill_tests.id"))
    question_text = Column(Text, nullable=False)
    # Gelecekte farklı soru tipleri eklemek için (örn: pratik görev)
    question_type = Column(String, default="multiple_choice") 

    skill_test = relationship("SkillTest", back_populates="questions")
    choices = relationship("Choice", back_populates="question", cascade="all, delete-orphan")