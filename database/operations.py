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
    MarketPrice, FarmingTaskTemplate, SatelliteCache,
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

# ── Market Prices ──────────────────────────────────────────────────────────────

def upsert_market_prices(db: Session, prices: list[dict]) -> int:
    """Bulk upsert market prices. Returns count of inserted/updated rows."""
    count = 0
    for p in prices:
        existing = db.query(MarketPrice).filter(
            MarketPrice.crop == p["crop"],
            MarketPrice.market == p["market"],
            MarketPrice.unit == p["unit"],
            MarketPrice.price_date == p["price_date"],
        ).first()
        if existing:
            existing.price_ngn = p["price_ngn"]
            existing.source = p.get("source", "afex")
        else:
            db.add(MarketPrice(
                id=generate_uuid(),
                crop=p["crop"],
                market=p["market"],
                price_ngn=p["price_ngn"],
                unit=p["unit"],
                price_date=p["price_date"],
                source=p.get("source", "afex"),
            ))
        count += 1
    db.commit()
    return count


def get_market_prices(db: Session, crop: str, days: int = 7) -> list[MarketPrice]:
    """Get latest market prices for a crop, ordered by date desc."""
    from datetime import datetime, timedelta
    cutoff = (datetime.utcnow() - timedelta(days=days)).isoformat()
    return (
        db.query(MarketPrice)
        .filter(MarketPrice.crop == crop, MarketPrice.price_date >= cutoff)
        .order_by(MarketPrice.price_date.desc())
        .all()
    )


def get_latest_market_price(db: Session, crop: str, market: str = None) -> Optional[MarketPrice]:
    """Get the single most recent price entry for a crop."""
    q = db.query(MarketPrice).filter(MarketPrice.crop == crop)
    if market:
        q = q.filter(MarketPrice.market == market)
    return q.order_by(MarketPrice.price_date.desc()).first()


# ── Farming Task Templates ─────────────────────────────────────────────────────

def get_task_templates(db: Session, crop: str, region: str = "all", season: str = "all") -> list[FarmingTaskTemplate]:
    """Get task templates for a crop, filtered by region and season."""
    q = db.query(FarmingTaskTemplate).filter(FarmingTaskTemplate.crop == crop)
    if region != "all":
        q = q.filter(
            (FarmingTaskTemplate.region == region) |
            (FarmingTaskTemplate.region == "all")
        )
    if season != "all":
        q = q.filter(
            (FarmingTaskTemplate.season == season) |
            (FarmingTaskTemplate.season == "all")
        )
    return q.order_by(FarmingTaskTemplate.days_after_planting).all()


def seed_task_templates(db: Session):
    """Seed default task templates for supported crops."""
    count = db.query(FarmingTaskTemplate).count()
    if count > 0:
        return  # already seeded

    templates = [
        # Maize - Northern Nigeria (wet season)
        {"crop": "maize", "region": "north", "days_after_planting": 0,  "task_type": "plant",   "title": "Plant maize seeds",                "description": "Space seeds 25cm apart in rows 75cm apart. 2-3 seeds per hole.", "season": "wet"},
        {"crop": "maize", "region": "north", "days_after_planting": 3,  "task_type": "irrigate","title": "First irrigation",                 "description": "Irrigate immediately after planting if soil is dry.", "season": "dry"},
        {"crop": "maize", "region": "north", "days_after_planting": 7,  "task_type": "fertilize","title": "Apply NPK 15:15:15",               "description": "Apply 200kg/ha NPK 15:15:15. Place 5cm from plant base.", "season": "all"},
        {"crop": "maize", "region": "north", "days_after_planting": 14, "task_type": "irrigate","title": "Second irrigation",                "description": "Maintain soil moisture. Irrigate if no rain in 5 days.", "season": "dry"},
        {"crop": "maize", "region": "north", "days_after_planting": 21, "task_type": "spray",   "title": "Scout for fall armyworm",          "description": "Check for leaf damage and frass. Apply Emamectin Benzoate if FAW detected.", "season": "all"},
        {"crop": "maize", "region": "north", "days_after_planting": 28, "task_type": "fertilize","title": "Apply Urea top-dressing",          "description": "Apply 200kg/ha Urea (46% N). Side-dress 10cm from plants.", "season": "all"},
        {"crop": "maize", "region": "north", "days_after_planting": 45, "task_type": "spray",   "title": "Second pest scouting",             "description": "Check for stem borers and FAW. Spray if threshold reached.", "season": "all"},
        {"crop": "maize", "region": "north", "days_after_planting": 60, "task_type": "fertilize","title": "Apply potassium (MOP)",            "description": "Apply 100kg/ha Muriate of Potash for grain filling.", "season": "all"},
        {"crop": "maize", "region": "north", "days_after_planting": 75, "task_type": "irrigate","title": "Final irrigation",                  "description": "Last irrigation before drying. Reduce water from now.", "season": "dry"},
        {"crop": "maize", "region": "north", "days_after_planting": 90, "task_type": "harvest", "title": "Harvest maize",                     "description": "Harvest when husks are brown and kernels are hard. Moisture < 20%.", "season": "all"},
        # Rice - Northern Nigeria
        {"crop": "rice", "region": "north", "days_after_planting": 0,  "task_type": "plant",   "title": "Transplant rice seedlings",         "description": "Transplant 3-week-old seedlings 20cm x 20cm spacing.", "season": "wet"},
        {"crop": "rice", "region": "north", "days_after_planting": 7,  "task_type": "fertilize","title": "Apply basal NPK",                   "description": "Apply 150kg/ha NPK 15:15:15. Maintain 5cm water level.", "season": "all"},
        {"crop": "rice", "region": "north", "days_after_planting": 30, "task_type": "fertilize","title": "Apply Urea",                         "description": "Apply 100kg/ha Urea. Drain field, apply, re-flood after 2 days.", "season": "all"},
        {"crop": "rice", "region": "north", "days_after_planting": 45, "task_type": "spray",   "title": "Weed control + pest check",         "description": "Remove weeds manually. Check for rice blast and stem borers.", "season": "all"},
        {"crop": "rice", "region": "north", "days_after_planting": 60, "task_type": "fertilize","title": "Apply Urea (panicle initiation)",   "description": "Apply 50kg/ha Urea at panicle initiation stage.", "season": "all"},
        {"crop": "rice", "region": "north", "days_after_planting": 90, "task_type": "irrigate","title": "Drain field for harvest",           "description": "Drain water 2 weeks before harvest.", "season": "all"},
        {"crop": "rice", "region": "north", "days_after_planting": 105,"task_type": "harvest", "title": "Harvest rice",                       "description": "Harvest when 80% of grains are golden. Moisture 20-25%.", "season": "all"},
        # Cassava - all regions
        {"crop": "cassava","region": "all", "days_after_planting": 0,  "task_type": "plant",   "title": "Plant cassava cuttings",            "description": "Use 25cm stem cuttings with 5-7 nodes. Plant at 45° angle.", "season": "wet"},
        {"crop": "cassava","region": "all", "days_after_planting": 30, "task_type": "fertilize","title": "Apply NPK 15:15:15",                "description": "Apply 200kg/ha NPK 15:15:15. 10cm from stem base.", "season": "all"},
        {"crop": "cassava","region": "all", "days_after_planting": 60, "task_type": "spray",   "title": "Weed control",                      "description": "Remove weeds manually or apply pre-emergence herbicide.", "season": "all"},
        {"crop": "cassava","region": "all", "days_after_planting": 90, "task_type": "fertilize","title": "Apply KCl (potassium)",             "description": "Apply 100kg/ha KCl for tuber development.", "season": "all"},
        {"crop": "cassava","region": "all", "days_after_planting": 180,"task_type": "harvest", "title": "Harvest cassava (early)",           "description": "Early-maturing varieties ready at 6-8 months.", "season": "all"},
        {"crop": "cassava","region": "all", "days_after_planting": 365,"task_type": "harvest", "title": "Harvest cassava (full)",            "description": "Full maturity at 12 months. Check tuber size before harvest.", "season": "all"},
        # Beans
        {"crop": "beans", "region": "north", "days_after_planting": 0,  "task_type": "plant",   "title": "Plant beans",                       "description": "Sow 2 seeds per hole, 5cm deep. Rows 50cm apart.", "season": "wet"},
        {"crop": "beans", "region": "north", "days_after_planting": 14, "task_type": "fertilize","title": "Apply NPK 15:15:15",                "description": "Apply 150kg/ha NPK. Beans fix nitrogen — minimal N needed.", "season": "all"},
        {"crop": "beans", "region": "north", "days_after_planting": 30, "task_type": "spray",   "title": "Check for aphids + pod borers",      "description": "Scout for aphids on young leaves. Spray neem oil or dimethoate if present.", "season": "all"},
        {"crop": "beans", "region": "north", "days_after_planting": 60, "task_type": "harvest", "title": "Harvest beans",                      "description": "Harvest when pods turn brown and beans rattle inside.", "season": "all"},
        # Cocoa
        {"crop": "cocoa", "region": "south", "days_after_planting": 0,  "task_type": "plant",   "title": "Plant cocoa seedlings",             "description": "Space 3m x 3m. Provide shade using plantain or banana.", "season": "wet"},
        {"crop": "cocoa", "region": "south", "days_after_planting": 30, "task_type": "spray",   "title": "Check for black pod disease",        "description": "Remove infected pods. Spray copper-based fungicide.", "season": "wet"},
        {"crop": "cocoa", "region": "south", "days_after_planting": 60, "task_type": "fertilize","title": "Apply cocoa NPK",                    "description": "Apply cocoa-specific NPK 20:10:10. 250g per tree.", "season": "all"},
    ]
    for t in templates:
        db.add(FarmingTaskTemplate(
            id=generate_uuid(),
            crop=t["crop"], region=t["region"],
            days_after_planting=t["days_after_planting"],
            task_type=t["task_type"], title=t["title"],
            description=t["description"], season=t.get("season", "all"),
        ))
    db.commit()
    logger.info(f"Seeded {len(templates)} task templates")


# ── Satellite Cache ────────────────────────────────────────────────────────────

def get_satellite_cache(db: Session, lat: float, lon: float, max_age_hours: int = 24) -> Optional[SatelliteCache]:
    """Get cached satellite data for a location. Returns None if stale or missing."""
    from datetime import datetime, timedelta
    cutoff = (datetime.utcnow() - timedelta(hours=max_age_hours)).isoformat()
    return (
        db.query(SatelliteCache)
        .filter(SatelliteCache.lat == lat, SatelliteCache.lon == lon, SatelliteCache.created_at >= cutoff)
        .order_by(SatelliteCache.created_at.desc())
        .first()
    )


def save_satellite_cache(db: Session, lat: float, lon: float, data: dict) -> SatelliteCache:
    """Save satellite data to cache."""
    record = SatelliteCache(
        id=generate_uuid(), lat=lat, lon=lon,
        ndvi=data.get("ndvi"),
        evapotranspiration=data.get("evapotranspiration"),
        drought_index=data.get("drought_index"),
        soil_moisture=data.get("soil_moisture"),
        date=data.get("date", utcnow_iso().split("T")[0]),
        created_at=utcnow_iso(),
    )
    db.add(record)
    db.commit()
    return record


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
