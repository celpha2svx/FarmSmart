"""
Database CRUD operations for FarmSmart.
All DB access goes through these functions — no raw SQL elsewhere.
"""

import json
import logging
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from database.models import (
    Farmer, Alert, DegreeDay, RegistrationState,
    AppUser, OtpCode, Announcement, AppFeedback, AppRelease, AnalyticsEvent,
)
from utils.helpers import generate_uuid, utcnow_iso

logger = logging.getLogger(__name__)


# ── Farmer ────────────────────────────────────────────────────────────────────

def create_farmer(
    db: Session,
    phone: str,
    crop: str,
    location_raw: str,
    lat: float,
    lon: float,
    farm_size: str,
    name: str = None,
) -> Farmer:
    farmer = Farmer(
        id=generate_uuid(),
        phone=phone,
        name=name,
        crop=crop.lower(),
        location_raw=location_raw,
        lat=lat,
        lon=lon,
        farm_size=farm_size,
        subscribed=1,
        daily_update=1,
        registered=utcnow_iso(),
    )
    db.add(farmer)
    try:
        db.commit()
        db.refresh(farmer)
        logger.info(f"Registered new farmer: {phone} ({crop} at {location_raw})")
    except IntegrityError:
        db.rollback()
        logger.warning(f"Farmer already exists: {phone}")
        farmer = get_farmer_by_phone(db, phone)
    return farmer


def get_farmer_by_phone(db: Session, phone: str) -> Optional[Farmer]:
    return db.query(Farmer).filter(Farmer.phone == phone).first()


def update_farmer(db: Session, phone: str, **kwargs) -> Optional[Farmer]:
    farmer = get_farmer_by_phone(db, phone)
    if not farmer:
        return None
    for key, value in kwargs.items():
        if hasattr(farmer, key):
            setattr(farmer, key, value)
    db.commit()
    db.refresh(farmer)
    return farmer


def get_all_subscribed_farmers(db: Session) -> list[Farmer]:
    return db.query(Farmer).filter(Farmer.subscribed == 1).all()


def get_daily_update_farmers(db: Session) -> list[Farmer]:
    return (
        db.query(Farmer)
        .filter(Farmer.subscribed == 1, Farmer.daily_update == 1)
        .all()
    )


# ── Alert ─────────────────────────────────────────────────────────────────────

def log_alert(
    db: Session,
    farmer_id: str,
    alert_type: str,
    message_sent: str,
    risk_level: str = None,
    delivery: str = "whatsapp",
) -> Alert:
    alert = Alert(
        id=generate_uuid(),
        farmer_id=farmer_id,
        alert_type=alert_type,
        risk_level=risk_level,
        message_sent=message_sent,
        sent_at=utcnow_iso(),
        delivery=delivery,
    )
    db.add(alert)
    db.commit()
    return alert


# ── DegreeDay ─────────────────────────────────────────────────────────────────

def get_or_create_degree_day(
    db: Session,
    farmer_id: str,
    pest_id: str,
    season_start: str,
) -> DegreeDay:
    record = (
        db.query(DegreeDay)
        .filter(
            DegreeDay.farmer_id == farmer_id,
            DegreeDay.pest_id == pest_id,
            DegreeDay.season_start == season_start,
        )
        .first()
    )
    if not record:
        record = DegreeDay(
            id=generate_uuid(),
            farmer_id=farmer_id,
            pest_id=pest_id,
            season_start=season_start,
            accumulated=0.0,
            generations=0,
            last_updated=utcnow_iso(),
        )
        db.add(record)
        db.commit()
        db.refresh(record)
    return record


def update_degree_day(
    db: Session,
    record: DegreeDay,
    accumulated: float,
    generations: int,
) -> DegreeDay:
    record.accumulated  = accumulated
    record.generations  = generations
    record.last_updated = utcnow_iso()
    db.commit()
    db.refresh(record)
    return record


# ── RegistrationState ──────────────────────────────────────────────────────────

def get_registration_state(db: Session, phone: str) -> Optional[RegistrationState]:
    return db.query(RegistrationState).filter(RegistrationState.phone == phone).first()


def save_registration_state(db: Session, phone: str, step: int, data: dict = None) -> RegistrationState:
    import json
    record = get_registration_state(db, phone)
    if record:
        record.step = step
        record.data  = json.dumps(data) if data else None
    else:
        record = RegistrationState(
            phone=phone,
            step=step,
            data=json.dumps(data) if data else None,
        )
        db.add(record)
    db.commit()
    return record


def delete_registration_state(db: Session, phone: str) -> None:
    record = get_registration_state(db, phone)
    if record:
        db.delete(record)
        db.commit()


# ── App Auth ─────────────────────────────────────────────────────────────────────

import hashlib, random, string
from datetime import datetime, timedelta

def generate_otp(length: int = 6) -> str:
    return ''.join(random.choices(string.digits, k=length))

def send_otp_code(db: Session, phone: str) -> str:
    """Generate OTP, store it, return the code (for SMS sending)."""
    code = generate_otp()
    expires = (datetime.utcnow() + timedelta(minutes=10)).isoformat()
    existing = db.query(OtpCode).filter(OtpCode.phone == phone).first()
    if existing:
        existing.code = code
        existing.expires_at = expires
        existing.used = 0
    else:
        db.add(OtpCode(phone=phone, code=code, expires_at=expires))
    db.commit()
    return code

def verify_otp(db: Session, phone: str, code: str) -> bool:
    record = db.query(OtpCode).filter(
        OtpCode.phone == phone,
        OtpCode.code == code,
        OtpCode.used == 0,
        OtpCode.expires_at > datetime.utcnow().isoformat(),
    ).first()
    if not record:
        return False
    record.used = 1
    db.commit()
    return True

def get_or_create_app_user(db: Session, phone: str) -> AppUser:
    user = db.query(AppUser).filter(AppUser.phone == phone).first()
    if not user:
        token = hashlib.sha256(f"{phone}:{datetime.utcnow().isoformat()}".encode()).hexdigest()
        now = datetime.utcnow().isoformat()
        user = AppUser(phone=phone, token=token, created_at=now, last_login=now)
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.last_login = datetime.utcnow().isoformat()
        db.commit()
    return user

def verify_app_token(db: Session, phone: str, token: str) -> bool:
    user = db.query(AppUser).filter(AppUser.phone == phone, AppUser.token == token).first()
    return user is not None


# ── Announcements ───────────────────────────────────────────────────────────────

def get_active_announcements(db: Session) -> list[Announcement]:
    return db.query(Announcement).filter(Announcement.active == 1).order_by(Announcement.created_at.desc()).all()

def create_announcement(db: Session, title: str, body: str, level: str = "info") -> Announcement:
    a = Announcement(
        id=generate_uuid(), title=title, body=body,
        level=level, active=1, created_at=utcnow_iso(),
    )
    db.add(a)
    db.commit()
    return a


# ── Feedback ────────────────────────────────────────────────────────────────────

def save_feedback(db: Session, phone: str, message: str, category: str = None,
                  app_version: str = None, device_info: str = None,
                  github_issue_url: str = None) -> AppFeedback:
    fb = AppFeedback(
        id=generate_uuid(), phone=phone, category=category, message=message,
        app_version=app_version, device_info=device_info,
        github_issue_url=github_issue_url, created_at=utcnow_iso(),
    )
    db.add(fb)
    db.commit()
    return fb


# ── App Release ─────────────────────────────────────────────────────────────────

def get_latest_release(db: Session) -> Optional[AppRelease]:
    return db.query(AppRelease).order_by(AppRelease.version_code.desc()).first()


# ── Analytics ────────────────────────────────────────────────────────────────────

def log_analytics_event(db: Session, phone: str, event_type: str, event_data: dict = None) -> AnalyticsEvent:
    ev = AnalyticsEvent(
        id=generate_uuid(), phone=phone, event_type=event_type,
        event_data=json.dumps(event_data) if event_data else None,
        created_at=utcnow_iso(), synced_at=utcnow_iso(),
    )
    db.add(ev)
    db.commit()
    return ev

def get_analytics_summary(db: Session, days: int = 30) -> dict:
    """Return anonymized aggregate stats for ML/product insights."""
    from sqlalchemy import func
    total_farmers = db.query(Farmer).count()
    top_crops = db.query(Farmer.crop, func.count(Farmer.crop).label('count')).group_by(Farmer.crop).order_by(func.count(Farmer.crop).desc()).limit(5).all()
    total_alerts = db.query(Alert).count()
    return {
        "total_farmers": total_farmers,
        "top_crops": [{"crop": c, "count": cnt} for c, cnt in top_crops],
        "total_alerts": total_alerts,
    }
