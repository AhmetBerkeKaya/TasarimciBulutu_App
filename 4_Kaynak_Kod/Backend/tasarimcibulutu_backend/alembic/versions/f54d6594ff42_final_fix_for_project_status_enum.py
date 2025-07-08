"""Final fix for project status enum

Revision ID: f54d6594ff42
Revises: 2e48d59b93b9
Create Date: 2025-07-07 20:25:21.085417

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'f54d6594ff42'
down_revision: Union[str, Sequence[str], None] = '2e48d59b93b9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 'native_enum=False' ile uyumlu hale getirmek için ENUM tipini VARCHAR'a çeviriyoruz.
    # PostgreSQL'e bu çeviriyi nasıl yapacağını 'postgresql_using' ile söylüyoruz.
    op.alter_column(
        'projects',
        'status',
        existing_type=postgresql.ENUM('open', 'in_progress', 'completed', 'cancelled', name='projectstatus'),
        type_=sa.String(length=20), # Basit bir metin alanına çeviriyoruz
        existing_nullable=False,
        postgresql_using='status::text' # İşte sihirli kısım!
    )
    # Artık kullanılmayan eski ENUM tipini veritabanından silebiliriz.
    op.execute('DROP TYPE projectstatus;')


def downgrade() -> None:
    # Geri alma işlemi için önce ENUM tipini tekrar oluşturuyoruz
    project_status_enum = postgresql.ENUM('open', 'in_progress', 'completed', 'cancelled', name='projectstatus')
    project_status_enum.create(op.get_bind())
    
    # Sonra sütunun tipini yeni oluşturduğumuz ENUM'a geri çeviriyoruz
    op.alter_column(
        'projects',
        'status',
        existing_type=sa.String(length=20),
        type_=project_status_enum,
        existing_nullable=False,
        postgresql_using='status::projectstatus'
    )
