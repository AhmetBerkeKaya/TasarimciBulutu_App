"""add phone_number to users

Revision ID: 9ddde942428d
Revises: 239429989df3
Create Date: 2025-06-28 20:59:57.561225

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9ddde942428d'
down_revision: Union[str, Sequence[str], None] = '239429989df3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade():
    # users tablosuna phone_number sütunu ekle, nullable ve varchar(20) olsun
    op.add_column('users', sa.Column('phone_number', sa.String(length=20), nullable=True))

def downgrade():
    # downgrade işleminde phone_number sütununu kaldır
    op.drop_column('users', 'phone_number')