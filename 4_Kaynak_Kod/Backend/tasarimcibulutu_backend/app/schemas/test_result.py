from pydantic import BaseModel, UUID4
from typing import Optional
from datetime import datetime

class TestResultBase(BaseModel):
    user_id: UUID4
    test_id: UUID4
    score: int
    completed_at: Optional[datetime] = None

class TestResultCreate(TestResultBase):
    pass

class TestResultUpdate(BaseModel):
    score: Optional[int] = None
    completed_at: Optional[datetime] = None

class TestResult(TestResultBase):
    id: UUID4

    class Config:
        from_attributes = True
