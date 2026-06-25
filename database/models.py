"""
SQLAlchemy ORM models for FarmSmart.
Tables: farmers, alerts, degree_days
"""

from sqlalchemy import (
    Column, Text, Integer, ForeignKey, create_engine, Float
)
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()


class Farmer(Base):
    __tablename__ = "farmers"

    id           = Column(Text, primary_key=True)          # UUID
    phone        = Column(Text, unique=True, nullable=False)
    name         = Column(Text)
    crop         = Column(Text, nullable=False)
    location_raw = Column(Text, nullable=False)            # e.g. 'Sabon Gari, Kaduna'
    lat          = Column(Float, nullable=False)
    lon          = Column(Float, nullable=False)
    farm_size    = Column(Text)                            # 'small' | 'medium' | 'large'
    subscribed   = Column(Integer, default=1)              # 1=active, 0=STOP
    daily_update = Column(Integer, default=1)              # 1=receives 6AM daily
    registered   = Column(Text, nullable=False)            # ISO timestamp

    alerts      = relationship("Alert", back_populates="farmer", cascade="all, delete")
    degree_days = relationship("DegreeDay", back_populates="farmer", cascade="all, delete")


class Alert(Base):
    __tablename__ = "alerts"

    id           = Column(Text, primary_key=True)
    farmer_id    = Column(Text, ForeignKey("farmers.id"), nullable=False)
    alert_type   = Column(Text, nullable=False)            # 'soil' | 'weather' | 'pest'
    risk_level   = Column(Text)                            # 'HIGH' | 'MEDIUM' | 'LOW'
    message_sent = Column(Text, nullable=False)
    sent_at      = Column(Text, nullable=False)            # ISO timestamp
    delivery     = Column(Text, default="whatsapp")

    farmer = relationship("Farmer", back_populates="alerts")


class DegreeDay(Base):
    __tablename__ = "degree_days"

    id           = Column(Text, primary_key=True)
    farmer_id    = Column(Text, ForeignKey("farmers.id"), nullable=False)
    pest_id      = Column(Text, nullable=False)            # e.g. 'fall_armyworm'
    season_start = Column(Text, nullable=False)            # ISO date
    accumulated  = Column(Float, default=0.0)
    generations  = Column(Integer, default=0)
    last_updated = Column(Text, nullable=False)            # ISO timestamp

    farmer = relationship("Farmer", back_populates="degree_days")


class RegistrationState(Base):
    """Persistent multi-step registration state — survives restarts."""
    __tablename__ = "registration_states"

    phone = Column(Text, primary_key=True)
    step  = Column(Integer, nullable=False, default=1)
    data  = Column(Text, nullable=True)                   # JSON-encoded dict


def init_db(database_url: str, **kwargs):
    """Create all tables if they don't exist."""
    engine = create_engine(database_url, **kwargs)
    Base.metadata.create_all(engine)
    return engine
