"""Initial migration — create farmers, alerts, degree_days.

Revision ID: 001
Revises: None
Create Date: 2026-06-25
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, None] = None
depends_on: Union[str, None] = None


def upgrade() -> None:
    op.create_table(
        "farmers",
        sa.Column("id", sa.Text(), nullable=False),
        sa.Column("phone", sa.Text(), nullable=False),
        sa.Column("name", sa.Text(), nullable=True),
        sa.Column("crop", sa.Text(), nullable=False),
        sa.Column("location_raw", sa.Text(), nullable=False),
        sa.Column("lat", sa.Float(), nullable=False),
        sa.Column("lon", sa.Float(), nullable=False),
        sa.Column("farm_size", sa.Text(), nullable=True),
        sa.Column("subscribed", sa.Integer(), server_default="1"),
        sa.Column("daily_update", sa.Integer(), server_default="1"),
        sa.Column("registered", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("phone"),
    )
    op.create_table(
        "alerts",
        sa.Column("id", sa.Text(), nullable=False),
        sa.Column("farmer_id", sa.Text(), nullable=False),
        sa.Column("alert_type", sa.Text(), nullable=False),
        sa.Column("risk_level", sa.Text(), nullable=True),
        sa.Column("message_sent", sa.Text(), nullable=False),
        sa.Column("sent_at", sa.Text(), nullable=False),
        sa.Column("delivery", sa.Text(), server_default="whatsapp"),
        sa.ForeignKeyConstraint(
            ["farmer_id"], ["farmers.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "degree_days",
        sa.Column("id", sa.Text(), nullable=False),
        sa.Column("farmer_id", sa.Text(), nullable=False),
        sa.Column("pest_id", sa.Text(), nullable=False),
        sa.Column("season_start", sa.Text(), nullable=False),
        sa.Column("accumulated", sa.Float(), server_default="0.0"),
        sa.Column("generations", sa.Integer(), server_default="0"),
        sa.Column("last_updated", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(
            ["farmer_id"], ["farmers.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("degree_days")
    op.drop_table("alerts")
    op.drop_table("farmers")