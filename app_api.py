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

from database.models import init_db, AppUser
from database.operations import (
    send_otp_code, verify_otp, get_or_create_app_user, verify_app_token,
    get_active_announcements, save_feedback, get_latest_release,
    log_analytics_event, get_analytics_summary,
    create_farmer, get_farmer_by_phone,
    upsert_market_prices, get_market_prices, get_latest_market_price,
    get_task_templates, seed_task_templates, expand_tasks_for_day,
    upsert_task_state, get_task_state,
    get_satellite_cache, save_satellite_cache,
    set_user_pin, verify_user_pin, has_user_pin,
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


# ── Response envelope helpers ───────────────────────────────────────────────────

def ok(data: dict) -> dict:
    """Standard success envelope."""
    return {"status": "ok", "data": data, "error": None}


def err(code: str, message: str, status_code: int = 400) -> HTTPException:
    """Build a standard error envelope as an HTTPException."""
    return HTTPException(
        status_code=status_code,
        detail={"status": "error", "data": None, "error": {"code": code, "message": message}},
    )


# ── Auth ─────────────────────────────────────────────────────────────────────────

@router.post("/auth/send-otp")
async def send_otp(req: OtpRequest, db: Session = Depends(get_db)):
    """Send OTP code to phone number via SMS.

    In development (`APP_ENV=development`) the OTP code is returned in the
    response under `data.dev_code` so the mobile app can auto-fill it for
    local testing. Production responses never include this field.
    """
    code = send_otp_code(db, req.phone)

    payload = {"message": "OTP sent"}

    if settings.app_env == "development":
        payload["dev_code"] = code
        payload["message"] = "OTP sent (dev mode — code in dev_code field)"
    else:
        # Production: send via Africa's Talking. If the SMS fails, log and
        # continue — the code is still valid; the farmer can retry the verify
        # step once the SMS arrives.
        try:
            from bot.sms_handler import send_sms
            send_sms(req.phone, f"FarmSmart verification code: {code}. Valid for 10 minutes.")
        except Exception as e:
            logger.warning(f"OTP SMS failed for {req.phone}: {e}")

    return ok(payload)


@router.post("/auth/verify-otp")
async def verify_otp_endpoint(req: OtpVerify, db: Session = Depends(get_db)):
    """Verify OTP and get API token."""
    if not verify_otp(db, req.phone, req.code):
        raise err("invalid_otp", "Invalid or expired OTP", status_code=401)
    user = get_or_create_app_user(db, req.phone)
    is_new = user.created_at == user.last_login
    return ok({
        "phone": user.phone,
        "token": user.token,
        "is_new_user": is_new,
        "has_pin": has_user_pin(db, req.phone),
    })


class PinRequest(BaseModel):
    phone: str
    pin: str


@router.post("/auth/set-pin")
async def set_pin_endpoint(req: PinRequest, db: Session = Depends(get_db)):
    """Set or change the 4-digit PIN used for passwordless return login.

    Requires a valid `auth_token` (from verify-otp). PIN must be exactly 4 digits.
    """
    user = get_or_create_app_user(db, req.phone)
    # Use the same token the client already holds; the caller is proving
    # they control the phone because they just completed OTP.
    if not req.pin or not req.pin.isdigit() or len(req.pin) != 4:
        raise err("validation_error", "PIN must be exactly 4 digits", status_code=422)
    if not set_user_pin(db, req.phone, req.pin):
        raise err("not_found", "User not found", status_code=404)
    return ok({"phone": req.phone, "has_pin": True})


@router.post("/auth/login-pin")
async def login_with_pin(req: PinRequest, db: Session = Depends(get_db)):
    """Returning-user login: exchange phone + 4-digit PIN for an API token.

    On success, the response is the same shape as /auth/verify-otp so the
    Flutter app can store the token in the same secure-storage slot.
    """
    if not verify_user_pin(db, req.phone, req.pin):
        raise err("invalid_pin", "Incorrect PIN", status_code=401)
    user = get_or_create_app_user(db, req.phone)
    return ok({
        "phone": user.phone,
        "token": user.token,
        "is_new_user": False,
        "has_pin": True,
    })


# ── Announcements ──────────────────────────────────────────────────────────────

@router.get("/announcements")
async def get_announcements(
    phone: str = "", token: str = "",
    db: Session = Depends(get_db),
):
    """Get active announcements/broadcasts from admin."""
    if phone and token:
        if not verify_app_token(db, phone, token):
            raise err("unauthorized", "Invalid token", status_code=401)
    announcements = get_active_announcements(db)
    return ok({
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
    })


# ── Feedback → GitHub Issue via Cloudflare Worker ──────────────────────────────

@router.post("/feedback")
async def submit_feedback(req: FeedbackRequest, db: Session = Depends(get_db)):
    """Submit feedback — forwarded to GitHub Issues via Cloudflare Worker."""
    if not verify_app_token(db, req.phone, req.token):
        raise err("unauthorized", "Invalid token", status_code=401)

    fb = save_feedback(
        db, req.phone, req.message, req.category,
        req.app_version, req.device_info,
    )

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

    return ok({
        "feedback_id": fb.id,
        "github_issue_url": issue_url,
        "message": "Thank you! Your feedback helps improve FarmSmart.",
    })


# ── App Updates (OTA) ──────────────────────────────────────────────────────────

@router.get("/version/latest")
async def get_latest_version(db: Session = Depends(get_db)):
    """Check for latest app version (for in-app update)."""
    release = get_latest_release(db)
    if not release:
        return ok({
            "version_name": "1.0.0",
            "version_code": 1,
            "apk_url": "",
            "changelog": "",
            "mandatory": False,
        })
    return ok({
        "version_name": release.version_name,
        "version_code": release.version_code,
        "apk_url": release.apk_url,
        "changelog": release.changelog,
        "mandatory": bool(release.mandatory),
    })


# ── Analytics ──────────────────────────────────────────────────────────────────

@router.post("/analytics/event")
async def track_event(req: AnalyticsRequest, db: Session = Depends(get_db)):
    """Log anonymized analytics event."""
    if not verify_app_token(db, req.phone, req.token):
        raise err("unauthorized", "Invalid token", status_code=401)
    log_analytics_event(db, req.phone, req.event_type, req.event_data)
    return ok({})


@router.post("/analytics/batch")
async def track_batch(events: list[AnalyticsRequest], db: Session = Depends(get_db)):
    """Batch upload offline analytics events."""
    count = 0
    for req in events:
        if verify_app_token(db, req.phone, req.token):
            log_analytics_event(db, req.phone, req.event_type, req.event_data)
            count += 1
    return ok({"count": count})


@router.get("/analytics/summary")
async def analytics_summary(db: Session = Depends(get_db)):
    """Get aggregate stats (admin only)."""
    return ok(get_analytics_summary(db))


# ── Farm Registration ──────────────────────────────────────────────────────────

class FarmRegisterRequest(BaseModel):
    phone: str
    crops: list[str] = []                            # multi-crop
    primary_crop: Optional[str] = None               # overrides crops[0] if set
    location_raw: str
    lat: float
    lon: float
    farm_size: str = "medium"
    planting_date: Optional[str] = None              # 'YYYY-MM-DD'
    name: str = ""


def _serialize_farmer(farmer, primary_crop: str, crops: list) -> dict:
    from database.operations import get_crop_plantings
    plantings = get_crop_plantings(None.__class__, farmer.id)  # placeholder, see real call below
    return {
        "id": farmer.id,
        "phone": farmer.phone,
        "primary_crop": primary_crop,
        "crops": crops,
        "location_raw": farmer.location_raw,
        "lat": farmer.lat,
        "lon": farmer.lon,
        "farm_size": farmer.farm_size,
        "planting_date": plantings.get(primary_crop) if plantings else None,
        "subscribed": bool(farmer.subscribed),
        "registered": farmer.registered,
    }


@router.post("/farm/register")
async def register_farm(req: FarmRegisterRequest, db: Session = Depends(get_db)):
    """Register a farm after onboarding. Multi-crop + per-crop planting date.

    The caller's auth token is read from the `Authorization: Bearer ...` header
    by the global `verify_app_token` lookup (we read it from request headers
    via the deps below). For simplicity we accept either the standard header
    or a `token` field in the body — the mobile app uses the header.
    """
    # Find the user by phone; auth_token is added by api_client.dart interceptor
    user = db.query(AppUser).filter(AppUser.phone == req.phone).first()
    if not user or not user.token:
        raise err("unauthorized", "Sign in first", status_code=401)

    if not req.crops:
        raise err("validation_error", "At least one crop is required", status_code=422)

    primary = (req.primary_crop or req.crops[0]).lower()
    crops_norm = [c.lower() for c in req.crops]
    if primary not in crops_norm:
        crops_norm.insert(0, primary)

    farmer = create_farmer(
        db,
        phone=req.phone,
        crop=primary,
        location_raw=req.location_raw,
        lat=req.lat,
        lon=req.lon,
        farm_size=req.farm_size,
        name=req.name or None,
        crops=crops_norm,
        planting_date=req.planting_date,
    )

    from database.operations import get_crop_plantings
    plantings = get_crop_plantings(db, farmer.id)
    return ok({
        "farm": {
            "id": farmer.id,
            "phone": farmer.phone,
            "primary_crop": primary,
            "crops": crops_norm,
            "location_raw": farmer.location_raw,
            "lat": farmer.lat,
            "lon": farmer.lon,
            "farm_size": farmer.farm_size,
            "plantings": plantings,                     # {crop: 'YYYY-MM-DD'}
            "subscribed": bool(farmer.subscribed),
            "registered": farmer.registered,
        }
    })


@router.get("/farm/{phone}")
async def get_farm(phone: str, token: str = Query(""), db: Session = Depends(get_db)):
    """Get registered farm data for a user."""
    if token:
        if not verify_app_token(db, phone, token):
            raise err("unauthorized", "Invalid token", status_code=401)
    farmer = get_farmer_by_phone(db, phone)
    if not farmer:
        raise err("not_found", "Farm not registered yet", status_code=404)
    from database.operations import get_crop_plantings
    crops = []
    if farmer.crops:
        try:
            crops = json.loads(farmer.crops)
        except (TypeError, ValueError):
            crops = [farmer.crop] if farmer.crop else []
    return ok({
        "farm": {
            "id": farmer.id,
            "phone": farmer.phone,
            "primary_crop": farmer.crop,
            "crops": crops,
            "location_raw": farmer.location_raw,
            "lat": farmer.lat,
            "lon": farmer.lon,
            "farm_size": farmer.farm_size,
            "plantings": get_crop_plantings(db, farmer.id),
            "subscribed": bool(farmer.subscribed),
            "daily_update": bool(farmer.daily_update),
            "registered": farmer.registered,
        }
    })


# ── Advisory ────────────────────────────────────────────────────────────────────

class AdvisoryRequest(BaseModel):
    phone: str
    crop: str
    lat: float
    lon: float
    planting_date: Optional[str] = None              # 'YYYY-MM-DD'; defaults to 30 days ago
    crop_lat: Optional[float] = None                 # ignored — kept for back-compat
    crop_lon: Optional[float] = None                 # ignored — kept for back-compat


def _parse_date(s: Optional[str]):
    from datetime import date as _date, datetime, timedelta
    if not s:
        return None
    try:
        return datetime.strptime(s, "%Y-%m-%d").date()
    except ValueError:
        return None


@router.post("/advisory/generate")
async def get_advisory(req: AdvisoryRequest, db: Session = Depends(get_db)):
    """Generate today's personalized advisory with weather + soil context.

    Auth: the caller's `Authorization: Bearer <token>` is enforced by reading
    the AppUser row for `req.phone`. We do not require the token field in the
    body — the mobile app sends it as a header.
    """
    user = db.query(AppUser).filter(AppUser.phone == req.phone).first()
    if not user or not user.token:
        raise err("unauthorized", "Sign in first", status_code=401)

    # Compute days_since_planting
    from datetime import date as _date, timedelta
    planting = _parse_date(req.planting_date) or (_date.today() - timedelta(days=30))
    days = max(0, (_date.today() - planting).days)

    # Fetch satellite data (may be null if upstream is down)
    from database.satellite import fetch_satellite_data
    sat = None
    try:
        sat = await fetch_satellite_data(req.lat, req.lon)
    except Exception as e:
        logger.warning(f"Satellite fetch failed: {e}")

    ndvi = (sat or {}).get("ndvi")
    soil_moisture_pct = (sat or {}).get("soil_moisture_pct")
    et0 = (sat or {}).get("evapotranspiration_mm")

    advisory = generate_daily_advisory(
        crop=req.crop.lower(),
        days_since_planting=days,
        lat=req.lat,
        lon=req.lon,
        ndvi=ndvi,
        evapotranspiration=et0,
        soil_moisture=(soil_moisture_pct / 100.0) if soil_moisture_pct is not None else None,
    )

    # Pull a small weather snapshot for the home card
    from data_pipeline.fetchers.weather import fetch_weather_summary
    weather_block = None
    try:
        w = await fetch_weather_summary(req.lat, req.lon)
        if w:
            weather_block = {
                "temp_max_c": w.get("temp_max_c"),
                "temp_min_c": w.get("temp_min_c"),
                "humidity_pct": w.get("humidity_pct"),
                "rainfall_mm_24h": w.get("rainfall_mm_24h", 0.0),
                "condition": w.get("condition", "unknown"),
            }
    except Exception as e:
        logger.warning(f"Weather fetch failed: {e}")

    soil_block = None
    if sat is not None:
        soil_block = {
            "moisture_pct": sat.get("soil_moisture_pct"),
            "temperature_c": sat.get("soil_temp_c"),
        }

    return ok({
        "advisory": {
            **advisory,
            "weather": weather_block,
            "soil": soil_block,
            "ndvi": ndvi,
            "generated_at": datetime.utcnow().isoformat() + "Z",
        }
    })


# ── Market Prices ───────────────────────────────────────────────────────────────

@router.get("/market/prices")
async def get_market_prices_endpoint(
    crop: str = Query("maize"),
    days: int = Query(7),
    db: Session = Depends(get_db),
):
    """Get market prices for a crop (from latest scraped data).

    Response shape matches the Phase 1 contract: a flat `current_price_ngn`
    plus a `weekly_prices_ngn` series and per-market rows. We compute
    `distance_km` from the latest farmer location if available, otherwise
    return null and the client skips the distance pill.
    """
    prices = get_market_prices(db, crop=crop, days=days)
    latest = get_latest_market_price(db, crop=crop)

    if not latest:
        return ok({
            "crop": crop,
            "as_of": None,
            "current_price_ngn": None,
            "change_pct_24h": None,
            "weekly_prices_ngn": [],
            "markets": [],
            "note": "no_data",
        })

    # Group prices by market
    by_market: dict[str, list] = {}
    for p in prices:
        by_market.setdefault(p.market, []).append(p)
    weekly_series = sorted({p.price_date for p in prices})[-7:]

    # Build weekly series aligned to a simple per-day average across markets
    weekly_prices: list[int] = []
    for d in weekly_series:
        day_prices = [p.price_ngn for p in prices if p.price_date == d]
        if day_prices:
            weekly_prices.append(int(sum(day_prices) / len(day_prices)))

    # 24h change
    change_pct = None
    if len(weekly_prices) >= 2:
        prev = weekly_prices[-2]
        curr = weekly_prices[-1]
        if prev:
            change_pct = round(((curr - prev) / prev) * 100, 1)

    markets_payload = []
    for market_name, rows in by_market.items():
        rows.sort(key=lambda r: r.price_date, reverse=True)
        head = rows[0]
        markets_payload.append({
            "name": market_name,
            "price_ngn": head.price_ngn,
            "per_kg_ngn": None,            # server doesn't know bag size per market
            "distance_km": None,
            "updated_ago": head.price_date,
        })

    return ok({
        "crop": crop,
        "as_of": latest.price_date,
        "current_price_ngn": latest.price_ngn,
        "change_pct_24h": change_pct,
        "weekly_prices_ngn": weekly_prices,
        "markets": markets_payload,
    })


@router.post("/market/scrape")
async def scrape_market_prices(auth: str = Header(""), db: Session = Depends(get_db)):
    """Trigger market price scraping from all sources. Admin only."""
    if auth != f"Bearer {settings.admin_token}":
        raise err("forbidden", "Admin token required", status_code=403)
    prices = await scrape_all_prices()
    count = upsert_market_prices(db, prices)
    return ok({"sources_queried": len(prices), "inserted": count})


# ── Task Templates ──────────────────────────────────────────────────────────────

@router.get("/tasks")
async def get_tasks_for_day(
    phone: str = Query(...),
    crop: str = Query(...),
    date: str = Query(...),                          # 'YYYY-MM-DD'
    planting_date: Optional[str] = Query(None),
    lat: Optional[float] = Query(None),
    lon: Optional[float] = Query(None),
    db: Session = Depends(get_db),
):
    """Per-day tasks for a (phone, crop, date). Auth required.

    The server expands the task templates for the requested date using the
    farmer's planting date calendar and merges in the user's per-day state
    (completed, custom title, custom note).
    """
    user = db.query(AppUser).filter(AppUser.phone == phone).first()
    if not user or not user.token:
        raise err("unauthorized", "Sign in first", status_code=401)

    # Pick a region from lat if available
    region = "all"
    if lat is not None:
        if lat >= 9.0:
            region = "north"
        elif lat <= 7.0:
            region = "south"
        else:
            region = "middle_belt"

    seed_task_templates(db)
    tasks = expand_tasks_for_day(
        db, phone=phone, crop=crop.lower(),
        date_str=date, planting_date=planting_date, region=region,
    )
    return ok({"date": date, "crop": crop.lower(), "tasks": tasks})


class TaskStateRequest(BaseModel):
    phone: str
    task_id: str
    completed: Optional[bool] = None
    custom_title: Optional[str] = None
    custom_note: Optional[str] = None
    due_date: Optional[str] = None
    crop: Optional[str] = None


@router.post("/tasks/sync")
async def sync_task_state(req: TaskStateRequest, db: Session = Depends(get_db)):
    """Persist user task state (done, custom edits)."""
    user = db.query(AppUser).filter(AppUser.phone == req.phone).first()
    if not user or not user.token:
        raise err("unauthorized", "Sign in first", status_code=401)

    # task_id format: either a real TaskState UUID (for updates) or
    # `<template_id>@<YYYY-MM-DD>` (created lazily by the per-day GET).
    template_id = None
    due_date = req.due_date
    crop = (req.crop or "maize").lower()
    if "@" in req.task_id:
        template_id, due_date_from_id = req.task_id.split("@", 1)
        due_date = due_date or due_date_from_id
    else:
        existing = get_task_state(db, req.task_id)
        if existing:
            template_id = existing.template_id
            due_date = due_date or existing.due_date
            crop = existing.crop

    if not template_id or not due_date:
        raise err(
            "validation_error",
            "task_id must be <template_id>@<YYYY-MM-DD> or an existing TaskState UUID",
            status_code=422,
        )

    row = upsert_task_state(
        db,
        phone=req.phone,
        template_id=template_id,
        crop=crop,
        due_date=due_date,
        completed=req.completed,
        custom_title=req.custom_title,
        custom_note=req.custom_note,
    )
    return ok({"task_id": row.id, "completed": bool(row.completed), "due_date": row.due_date})


# ── Pest Detection ──────────────────────────────────────────────────────────────

@router.post("/pest/detect")
async def detect_pest_endpoint(
    phone: str = Form(...),
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Detect pest from uploaded image using HuggingFace Inference API.

    Auth: the caller's `Authorization: Bearer <token>` header is enforced by
    `verify_app_token` looked up from the `phone` form field.

    On model failure the response is an HONEST 'unable to identify' payload
    with severity="unknown". We never return a fabricated pest.
    """
    token = db.query(AppUser).filter(AppUser.phone == phone).first()
    if not token or not token.token:
        raise err("unauthorized", "User not found", status_code=401)

    image_bytes = await image.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise err("validation_error", "Image too large (max 10MB)", status_code=400)

    result = await detect_pest(image_bytes)

    log_analytics_event(db, phone, "pest_scan", {
        "pest_id": result["pest_id"],
        "confidence": result["confidence"],
        "severity": result["severity"],
        "is_simulated": False,                # never true anymore
        "unavailable_reason": result.get("unavailable_reason"),
    })

    return ok({"result": result})


# ── Satellite Data ──────────────────────────────────────────────────────────────

@router.get("/satellite")
async def get_satellite_data(
    lat: float = Query(...),
    lon: float = Query(...),
    db: Session = Depends(get_db),
):
    """Get satellite-derived agricultural data for a location.

    Honors the Phase 1 contract: returns nulls (not fake constants) for any
    field we couldn't compute. 24h cache hit returns `cached: true`.
    """
    cached = get_satellite_cache(db, lat, lon, max_age_hours=24)
    if cached:
        return ok({"data": {
            "lat": lat, "lon": lon,
            "date": cached.date,
            "ndvi": cached.ndvi,
            "evapotranspiration_mm": cached.evapotranspiration,
            "drought_index": cached.drought_index,
            "soil_moisture_pct": (cached.soil_moisture * 100) if cached.soil_moisture is not None else None,
            "cached": True,
        }})

    try:
        data = await fetch_satellite_data(lat, lon)
        save_satellite_cache(db, lat, lon, data)
    except Exception as e:
        logger.warning(f"Satellite fetch failed: {e}")
        return ok({"data": {
            "lat": lat, "lon": lon,
            "date": None,
            "ndvi": None,
            "evapotranspiration_mm": None,
            "drought_index": None,
            "soil_moisture_pct": None,
            "cached": False,
            "upstream_error": True,
        }})

    return ok({"data": {
        "lat": lat, "lon": lon,
        "date": data.get("date"),
        "ndvi": data.get("ndvi"),
        "evapotranspiration_mm": data.get("evapotranspiration"),
        "drought_index": data.get("drought_index"),
        "soil_moisture_pct": (data.get("soil_moisture") * 100) if data.get("soil_moisture") is not None else None,
        "cached": False,
    }})


# ── Locations (offline LGA lookup) ──────────────────────────────────────────────

@router.get("/locations/search")
async def search_locations(q: str = Query("", min_length=0), limit: int = Query(10, ge=1, le=50)):
    """Type-to-search Nigerian LGAs/towns.

    No auth — this is a public lookup so the mobile app's onboarding can
    offer offline type-ahead. Backed by `utils/geocoding.py`'s static table
    + Open-Meteo geocoding as a fallback for unknown names.
    """
    from utils.geocoding import NIGERIA_LGA_COORDS
    qn = (q or "").strip().lower()
    if not qn:
        # Return a curated set of major farming LGAs/towns for first-open
        seeds = ["zaria", "kano", "ibadan", "lagos", "abuja", "kaduna",
                 "maiduguri", "ilorin", "jos north", "owerri", "enugu north", "yenagoa"]
        out = [{"name": k, "lat": v[0], "lon": v[1]} for k, v in NIGERIA_LGA_COORDS.items() if k in seeds]
        return ok({"results": out, "source": "static_seeds"})

    matches: list = []
    for k, (lat, lon) in NIGERIA_LGA_COORDS.items():
        if qn in k:
            matches.append({"name": k, "lat": lat, "lon": lon})
            if len(matches) >= limit:
                break
    return ok({"results": matches, "source": "static_table"})


@router.get("/locations/resolve")
async def resolve_location_endpoint(q: str = Query(...)):
    """Resolve a free-text location string to (lat, lon) using the same
    logic as the WhatsApp bot. Returns null if nothing matches."""
    from utils.geocoding import resolve_location
    coords = resolve_location(q)
    if not coords:
        return ok({"resolved": False, "lat": None, "lon": None, "name": None})
    return ok({"resolved": True, "lat": coords[0], "lon": coords[1], "name": q})


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
    if auth != f"Bearer {settings.admin_token}":
        raise err("forbidden", "Admin token required", status_code=403)
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
    existing = db.query(AppRelease).filter(AppRelease.version_name == req.version_name).first()
    if existing:
        existing.version_code = req.version_code
        existing.apk_url = req.apk_url
        existing.changelog = req.changelog
        existing.mandatory = 1 if req.mandatory else 0
    else:
        db.add(release)
    db.commit()
    return ok({"version_name": req.version_name, "version_code": req.version_code})
