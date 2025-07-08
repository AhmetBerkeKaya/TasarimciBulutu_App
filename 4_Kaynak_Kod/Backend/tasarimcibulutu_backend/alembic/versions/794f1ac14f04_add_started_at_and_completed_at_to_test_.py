"""Add started_at and completed_at to test_results

Revision ID: 794f1ac14f04
Revises: cd736a287149
Create Date: 2025-07-07 16:50:08.042970

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '794f1ac14f04'
down_revision: Union[str, Sequence[str], None] = 'cd736a287149'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Sadece eksik olan iki sütunu ekler
    op.add_column('test_results', sa.Column('started_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('test_results', sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    # Sadece eklenen iki sütunu geri alır
    op.drop_column('test_results', 'completed_at')
    op.drop_column('test_results', 'started_at')