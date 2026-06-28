"""
FarmSmart Mobile App API — auth, announcements, feedback, updates, analytics,
advisory, farm registration, market prices, task templates, pest detection, satellite.
"""

import io
import json
import logging
from datetime import datetime
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Header, UploadFile, File, Form, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database.models import init_db
from database.operations import (
    send_otp_code, verify_otp, get_or_create_app_user, verify_app_token,
    get_active_announcements, save_feedback, get_latest_release,
    log_analytics_event, get_analytics_summary,
    create_farmer, get_farmer_by_phone,
    upsert_market_prices, get_market_prices, get_latest_market_price,
    get_task_templates, seed_task_templates,
    get_satellite_cache, save_satellite_cache,
)
from database.advisory_rules import generate_daily_advisory, get_season, get_region
from database.market_scraper import scrape_all_prices, fetch_afex_prices, fetch_commodity_ng_prices
from database.pest_detector import detect_pest
from database.satellite import fetch_satellite_data
from utils.config import settings
from utils.helpers import generate_uuid, utcnow_iso

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api")

# ── Database dependency ─────────────────────────────────────────────────────────

def get_db():
    engine = init_db(settings.database_url)
    from sqlalchemy.orm import sessionmaker
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ── Models ──────────────────────────────────────────────────────────────────────

class OtpRequest(BaseModel):
    phone: str

class OtpVerify(BaseModel):
    phone: str
    code: str

class FeedbackRequest(BaseModel):
    phone: str
    token: str
    message: str
    category: str = "other"
    app_version: str = ""
    device_info: str = ""

class AnalyticsRequest(BaseModel):
    phone: str
    token: str
    event_type: str
    event_data: dict = {}


# ── Auth ─────────────────────────────────────────────────────────────────────────

@router.post("/auth/send-otp")
async def send_otp(req: OtpRequest, db: Session = Depends(get_db)):
    """Send OTP code to phone number via SMS."""
    code = send_otp_code(db, req.phone)

    # In production, send via Africa's Talking SMS
    # For now, return code directly for testing
    if settings.app_env == "development":
        return {"status": "ok", "code": code, "message": "OTP sent (dev mode — code shown)"}

    # Try sending via AT SMS
    try:
        from bot.sms_handler import send_sms
        send_sms(req.phone, f"FarmSmart verification code: {code}. Valid for 10 minutes.")
    except Exception as e:
        logger.warning(f"OTP SMS failed for {req.phone}: {e}")

    return {"status": "ok", "message": "OTP sent"}


@router.post("/auth/verify-otp")
async def verify_otp_endpoint(req: OtpVerify, db: Session = Depends(get_db)):
    """Verify OTP and get API token."""
    if not verify_otp(db, req.phone, req.code):
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")
    user = get_or_create_app_user(db, req.phone)
    return {"status": "ok", "phone": user.phone, "token": user.token}


# ── Announcements ──────────────────────────────────────────────────────────────

@router.get("/announcements")
async def get_announcements(
    phone: str = "", token: str = "",
    db: Session = Depends(get_db),
):
    """Get active announcements/broadcasts from admin."""
    if phone and token:
        if not verify_app_token(db, phone, token):
            raise HTTPException(status_code=401, detail="Invalid token")
    announcements = get_active_announcements(db)
    return {
        "status": "ok",
        "announcements": [
            {
                "id": a.id,
                "title": a.title,
                "body": a.body,
                "level": a.level,
                "created_at": a.created_at,
            }
            for a in announcements
        ],
    }


# ── Feedback → GitHub Issue via Cloudflare Worker ──────────────────────────────

@router.post("/feedback")
async def submit_feedback(req: FeedbackRequest, db: Session = Depends(get_db)):
    """Submit feedback — forwarded to GitHub Issues via Cloudflare Worker."""
    if not verify_app_token(db, req.phone, req.token):
        raise HTTPException(status_code=401, detail="Invalid token")

    # Save to DB first
    fb = save_feedback(
        db, req.phone, req.message, req.category,
        req.app_version, req.device_info,
    )

    # Forward to Cloudflare Worker if configured
    cf_worker = settings.feedback_webhook_url
    issue_url = None
    if cf_worker:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(cf_worker, json={
                    "phone": req.phone,
                    "category": req.category,
                    "message": req.message,
                    "app_version": req.app_version,
                    "device_info": req.device_info,
                    "feedback_id": fb.id,
                })
                if resp.status_code == 200:
                    data = resp.json()
                    issue_url = data.get("issue_url")
                    logger.info(f"Feedback {fb.id} → GitHub issue: {issue_url}")
        except Exception as e:
            logger.warning(f"Feedback webhook failed: {e}")

    return {
        "status": "ok",
        "feedback_id": fb.id,
        "github_issue_url": issue_url,
        "message": "Thank you! Your feedback helps improve FarmSmart.",
    }


# ── App Updates (OTA) ──────────────────────────────────────────────────────────

@router.get("/version/latest")
async def get_latest_version(db: Session = Depends(get_db)):
    """Check for latest app version (for in-app update)."""
    release = get_latest_release(db)
    if not release:
        return {
            "status": "ok",
            "version_name": "1.0.0",
            "version_code": 1,
            "apk_url": "",
            "changelog": "",
            "mandatory": False,
        }
    return {
        "status": "ok",
        "version_name": release.version_name,
        "version_code": release.version_code,
        "apk_url": release.apk_url,
        "changelog": release.changelog,
        "mandatory": bool(release.mandatory),
    }


# ── Analytics ──────────────────────────────────────────────────────────────────

@router.post("/analytics/event")
async def track_event(req: AnalyticsRequest, db: Session = Depends(get_db)):
    """Log anonymized analytics event."""
    if not verify_app_token(db, req.phone, req.token):
        raise HTTPException(status_code=401, detail="Invalid token")
    log_analytics_event(db, req.phone, req.event_type, req.event_data)
    return {"status": "ok"}


@router.post("/analytics/batch")
async def track_batch(events: list[AnalyticsRequest], db: Session = Depends(get_db)):
    """Batch upload offline analytics events."""
    count = 0
    for req in events:
        if verify_app_token(db, req.phone, req.token):
            log_analytics_event(db, req.phone, req.event_type, req.event_data)
            count += 1
    return {"status": "ok", "count": count}


@router.get("/analytics/summary")
async def analytics_summary(db: Session = Depends(get_db)):
    """Get aggregate stats (admin only)."""
    return get_analytics_summary(db)


# ── Farm Registration ──────────────────────────────────────────────────────────

class FarmRegisterRequest(BaseModel):
    phone: str
    token: str
    crop: str
    location_raw: str
    lat: float
    lon: float
    farm_size: str = "medium"
    name: str = ""


@router.post("/farm/register")
async def register_farm(req: FarmRegisterRequest, db: Session = Depends(get_db)):
    """Register a farm after onboarding."""
    if not verify_app_token(db, req.phone, req.token):
        raise HTTPException(status_code=401, detail="Invalid token")
    farmer = create_farmer(
        db, phone=req.phone, crop=req.crop,
        location_raw=req.location_raw, lat=req.lat, lon=req.lon,
        farm_size=req.farm_size, name=req.name or None,
    )
    return {
        "status": "ok",
        "farm": {
            "id": farmer.id,
            "phone": farmer.phone,
            "crop": farmer.crop,
            "location_raw": farmer.location_raw,
            "lat": farmer.lat,
            "lon": farmer.lon,
            "farm_size": farmer.farm_size,
            "registered": farmer.registered,
        },
    }


@router.get("/farm/{phone}")
async def get_farm(phone: str, token: str = Query(""), db: Session = Depends(get_db)):
    """Get registered farm data for a user."""
    if token:
        if not verify_app_token(db, phone, token):
            raise HTTPException(status_code=401, detail="Invalid token")
    farmer = get_farmer_by_phone(db, phone)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farm not registered yet")
    return {
        "status": "ok",
        "farm": {
            "id": farmer.id,
            "phone": farmer.phone,
            "crop": farmer.crop,
            "location_raw": farmer.location_raw,
            "lat": farmer.lat,
            "lon": farmer.lon,
            "farm_size": farmer.farm_size,
            "subscribed": farmer.subscribed,
            "daily_update": farmer.daily_update,
            "registered": farmer.registered,
        },
    }


# ── Advisory ────────────────────────────────────────────────────────────────────

class AdvisoryRequest(BaseModel):
    phone: str
    token: str
    crop: str
    days_since_planting: int = 30
    lat: float
    lon: float
    ndvi: Optional[float] = None
    evapotranspiration: Optional[float] = None
    soil_moisture: Optional[float] = None


@router.post("/advisory/generate")
async def get_advisory(req: AdvisoryRequest, db: Session = Depends(get_db)):
    """Generate real daily advisory using agronomic rules engine."""
    if not verify_app_token(db, req.phone, req.token):
        raise HTTPException(status_code=401, detail="Invalid token")

    advisory = generate_daily_advisory(
        crop=req.crop,
        days_since_planting=req.days_since_planting,
        lat=req.lat, lon=req.lon,
        ndvi=req.ndvi, evapotranspiration=req.evapotranspiration,
        soil_moisture=req.soil_moisture,
    )
    return {"status": "ok", "advisory": advisory}


# ── Market Prices ───────────────────────────────────────────────────────────────

@router.get("/market/prices")
async def get_market_prices_endpoint(
    crop: str = Query("maize"),
    days: int = Query(7),
    db: Session = Depends(get_db),
):
    """Get market prices for a crop (from latest scraped data)."""
    prices = get_market_prices(db, crop=crop, days=days)
    latest = get_latest_market_price(db, crop=crop)

    return {
        "status": "ok",
        "crop": crop,
        "prices": [
            {
                "crop": p.crop, "market": p.market,
                "price_ngn": p.price_ngn, "unit": p.unit,
                "price_date": p.price_date, "source": p.source,
            }
            for p in prices
        ],
        "latest_price": {
            "price_ngn": latest.price_ngn if latest else None,
            "market": latest.market if latest else None,
            "unit": latest.unit if latest else None,
            "price_date": latest.price_date if latest else None,
        } if latest else None,
    }


@router.post("/market/scrape")
async def scrape_market_prices(auth: str = Header(""), db: Session = Depends(get_db)):
    """Trigger market price scraping from all sources. Admin only."""
    if auth != f"Bearer {settings.admin_token}":
        raise HTTPException(status_code=403, detail="Forbidden")
    prices = await scrape_all_prices()
    count = upsert_market_prices(db, prices)
    return {"status": "ok", "sources_queried": len(prices), "inserted": count}


# ── Task Templates ──────────────────────────────────────────────────────────────

@router.get("/tasks")
async def get_task_templates_endpoint(
    crop: str = Query("maize"),
    region: str = Query("all"),
    season: str = Query("all"),
    db: Session = Depends(get_db),
):
    """Get farming task templates for a crop."""
    # Ensure templates are seeded
    seed_task_templates(db)
    templates = get_task_templates(db, crop=crop, region=region, season=season)
    return {
        "status": "ok",
        "crop": crop,
        "tasks": [
            {
                "id": t.id,
                "days_after_planting": t.days_after_planting,
                "task_type": t.task_type,
                "title": t.title,
                "description": t.description,
                "region": t.region,
                "season": t.season,
            }
            for t in templates
        ],
    }


# ── Pest Detection ──────────────────────────────────────────────────────────────

@router.post("/pest/detect")
async def detect_pest_endpoint(
    phone: str = Form(...),
    token: str = Form(...),
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Detect pest from uploaded image using HuggingFace Inference API."""
    if not verify_app_token(db, phone, token):
        raise HTTPException(status_code=401, detail="Invalid token")

    image_bytes = await image.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")

    result = await detect_pest(image_bytes)

    # Log analytics
    log_analytics_event(db, phone, "pest_scan", {
        "pest_id": result["pest_id"],
        "confidence": result["confidence"],
        "is_simulated": result.get("is_simulated", False),
    })

    return {"status": "ok", "result": result}


# ── Satellite Data ──────────────────────────────────────────────────────────────

@router.get("/satellite")
async def get_satellite_data(
    lat: float = Query(...),
    lon: float = Query(...),
    db: Session = Depends(get_db),
):
    """Get satellite-derived agricultural data for a location."""
    # Try cache first
    cached = get_satellite_cache(db, lat, lon, max_age_hours=24)
    if cached:
        return {
            "status": "ok",
            "data": {
                "ndvi": cached.ndvi,
                "evapotranspiration": cached.evapotranspiration,
                "drought_index": cached.drought_index,
                "soil_moisture": cached.soil_moisture,
                "date": cached.date,
                "cached": True,
            },
        }

    # Fetch fresh data
    data = await fetch_satellite_data(lat, lon)
    save_satellite_cache(db, lat, lon, data)

    return {
        "status": "ok",
        "data": {**data, "cached": False},
    }


# ── Task Sync (user task state) ─────────────────────────────────────────────────

class TaskState(BaseModel):
    phone: str
    token: str
    task_id: str
    done: bool = False
    custom_title: Optional[str] = None
    custom_description: Optional[str] = None
    due_date: Optional[str] = None  # ISO date


@router.post("/tasks/sync")
async def sync_task_state(req: TaskState, db: Session = Depends(get_db)):
    """Save user task state (done, custom edits)."""
    if not verify_app_token(db, req.phone, req.token):
        raise HTTPException(status_code=401, detail="Invalid token")
    # Store in analytics for now — dedicated table in Phase 2
    log_analytics_event(db, req.phone, "task_state", {
        "task_id": req.task_id,
        "done": req.done,
        "custom_title": req.custom_title,
        "custom_description": req.custom_description,
        "due_date": req.due_date,
    })
    return {"status": "ok"}


# ── Weather (Open-Meteo, no API key required) ────────────────────────────────

@router.get("/weather")
async def get_weather(
    lat: float = Query(...),
    lon: float = Query(...),
):
    """Get current weather for a location from Open-Meteo (free, no API key)."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                "https://api.open-meteo.com/v1/forecast",
                params={
                    "latitude": lat,
                    "longitude": lon,
                    "current": "temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m",
                    "timezone": "Africa/Lagos",
                },
            )
            resp.raise_for_status()
            data = resp.json()
            current = data.get("current", {})
            return {
                "status": "ok",
                "temperature": current.get("temperature_2m"),
                "humidity": current.get("relative_humidity_2m"),
                "precipitation": current.get("precipitation"),
                "wind_speed": current.get("wind_speed_10m"),
                "time": current.get("time"),
            }
    except Exception as e:
        logger.warning(f"Weather fetch failed for ({lat}, {lon}): {e}")
        return {
            "status": "error",
            "temperature": None,
            "humidity": None,
            "precipitation": None,
            "wind_speed": None,
        }


# ── Admin: Register new release (called by CI/CD) ────────────────────────────

class ReleaseRegister(BaseModel):
    version_name: str
    version_code: int
    apk_url: str
    changelog: str = ""
    mandatory: bool = False

@router.post("/version/release")
async def register_release(req: ReleaseRegister, auth: str = Header(""), db: Session = Depends(get_db)):
    """Register new app release. Called by GitHub Actions CI/CD."""
    # Simple bearer token check
    if auth != f"Bearer {settings.admin_token}":
        raise HTTPException(status_code=403, detail="Forbidden")
    from database.operations import generate_uuid, utcnow_iso
    from database.models import AppRelease
    release = AppRelease(
        version_name=req.version_name,
        version_code=req.version_code,
        apk_url=req.apk_url,
        changelog=req.changelog,
        mandatory=1 if req.mandatory else 0,
        release_date=utcnow_iso(),
    )
    # Upsert
    existing = db.query(AppRelease).filter(AppRelease.version_name == req.version_name).first()
    if existing:
        existing.version_code = req.version_code
        existing.apk_url = req.apk_url
        existing.changelog = req.changelog
        existing.mandatory = 1 if req.mandatory else 0
    else:
        db.add(release)
    db.commit()
    return {"status": "ok", "version_name": req.version_name}
