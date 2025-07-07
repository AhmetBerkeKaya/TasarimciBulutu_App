"""Manually make score column nullable

Revision ID: cd404ed3b6c7
Revises: 794f1ac14f04
Create Date: 2025-07-07 17:05:30.158437

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'cd404ed3b6c7'
down_revision: Union[str, Sequence[str], None] = '794f1ac14f04'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Sadece score sütununu boş bırakılabilir (nullable) yapıyoruz.
    op.alter_column('test_results', 'score',
                    existing_type=sa.NUMERIC(),
                    nullable=True)


def downgrade() -> None:
    # İşlemi geri almak için score sütununu tekrar boş bırakılamaz yapıyoruz.
    op.alter_column('test_results', 'score',
                    existing_type=sa.NUMERIC(),
                    nullable=False)