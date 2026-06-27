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


# ── App Auth ────────────────────────────────────────────────────────────────────

class AppUser(Base):
    """FarmSmart mobile app user (phone-based auth)."""
    __tablename__ = "app_users"

    phone      = Column(Text, primary_key=True)
    name       = Column(Text)
    token      = Column(Text, nullable=False)             # JWT or API token
    created_at = Column(Text, nullable=False)             # ISO timestamp
    last_login = Column(Text, nullable=False)             # ISO timestamp
    data_consent = Column(Integer, default=0)             # 1=consented to data collection


class OtpCode(Base):
    """One-time password for phone verification."""
    __tablename__ = "otp_codes"

    phone      = Column(Text, primary_key=True)
    code       = Column(Text, nullable=False)
    expires_at = Column(Text, nullable=False)             # ISO timestamp
    used       = Column(Integer, default=0)


# ── Announcements ───────────────────────────────────────────────────────────────

class Announcement(Base):
    """In-app broadcast messages from admin."""
    __tablename__ = "announcements"

    id         = Column(Text, primary_key=True)
    title      = Column(Text, nullable=False)
    body       = Column(Text, nullable=False)
    level      = Column(Text, default="info")            # 'info' | 'warning' | 'update'
    active     = Column(Integer, default=1)              # 1=show, 0=archived
    created_at = Column(Text, nullable=False)


# ── Feedback ────────────────────────────────────────────────────────────────────

class AppFeedback(Base):
    """User feedback → forwarded to GitHub Issues."""
    __tablename__ = "app_feedback"

    id         = Column(Text, primary_key=True)
    phone      = Column(Text, nullable=False)
    category   = Column(Text)                            # 'bug' | 'feature' | 'other'
    message    = Column(Text, nullable=False)
    app_version = Column(Text)
    device_info = Column(Text)
    github_issue_url = Column(Text)
    created_at = Column(Text, nullable=False)


# ── App Releases (for OTA update) ─────────────────────────────────────────────

class AppRelease(Base):
    """Latest app version for in-app update check."""
    __tablename__ = "app_releases"

    version_name = Column(Text, primary_key=True)        # e.g. "1.0.0"
    version_code = Column(Integer, nullable=False)
    apk_url      = Column(Text, nullable=False)          # GitHub release URL
    changelog    = Column(Text)
    release_date = Column(Text, nullable=False)
    mandatory    = Column(Integer, default=0)             # 1=force update


# ── Analytics Events ────────────────────────────────────────────────────────────

class AnalyticsEvent(Base):
    """Anonymized usage data for ML/product improvement."""
    __tablename__ = "analytics_events"

    id          = Column(Text, primary_key=True)
    phone       = Column(Text, nullable=False)
    event_type  = Column(Text, nullable=False)            # 'advisory_view' | 'scan' | 'login' | etc
    event_data  = Column(Text)                            # JSON blob
    created_at  = Column(Text, nullable=False)
    synced_at   = Column(Text)                            # when uploaded from offline


# ── Market Prices (scraped) ──────────────────────────────────────────────────────

class MarketPrice(Base):
    """Live commodity prices scraped from Nigerian markets."""
    __tablename__ = "market_prices"

    id         = Column(Text, primary_key=True)
    crop       = Column(Text, nullable=False)             # e.g. 'maize', 'rice'
    market     = Column(Text, nullable=False)             # e.g. 'Dawanau', 'Mile 12'
    price_ngn  = Column(Float, nullable=False)            # price in Naira
    unit       = Column(Text, nullable=False)             # '50kg bag', '1 kg', 'basket'
    price_date = Column(Text, nullable=False)             # ISO date
    source     = Column(Text, default="afex")             # 'afex' | 'commodity.ng' | 'farmlink.ng'


# ── Farming Task Templates ─────────────────────────────────────────────────────

class FarmingTaskTemplate(Base):
    """Agronomic task templates — generated by rules engine."""
    __tablename__ = "farming_task_templates"

    id                 = Column(Text, primary_key=True)
    crop               = Column(Text, nullable=False)
    region             = Column(Text, nullable=False)     # 'north' | 'south' | 'all'
    days_after_planting = Column(Integer, nullable=False)  # 0 = planting day
    task_type          = Column(Text, nullable=False)     # 'plant' | 'fertilize' | 'irrigate' | 'spray' | 'harvest'
    title              = Column(Text, nullable=False)
    description        = Column(Text)
    season             = Column(Text, default="all")      # 'wet' | 'dry' | 'all'


# ── Satellite Data Cache ───────────────────────────────────────────────────────

class SatelliteCache(Base):
    """Cached FAO WaPOR / ASIS satellite data per location."""
    __tablename__ = "satellite_cache"

    id               = Column(Text, primary_key=True)
    lat              = Column(Float, nullable=False)
    lon              = Column(Float, nullable=False)
    ndvi             = Column(Float)                      # Normalized Difference Vegetation Index
    evapotranspiration = Column(Float)                     # mm/day
    drought_index    = Column(Float)                      # ASIS drought index
    soil_moisture    = Column(Float)                      # m³/m³
    date             = Column(Text, nullable=False)        # ISO date
    created_at       = Column(Text, nullable=False)


def init_db(database_url: str, **kwargs):
    """Create all tables if they don't exist."""
    engine = create_engine(database_url, **kwargs)
    Base.metadata.create_all(engine)
    return engine
