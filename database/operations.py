"""
Database CRUD operations for FarmSmart.
All DB access goes through these functions — no raw SQL elsewhere.
"""

import logging
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from database.models import Farmer, Alert, DegreeDay, RegistrationState
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
