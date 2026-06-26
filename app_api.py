"""
FarmSmart Mobile App API — auth, announcements, feedback, updates, analytics.
"""

import json
import logging
import httpx
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database.models import init_db
from database.operations import (
    send_otp_code, verify_otp, get_or_create_app_user, verify_app_token,
    get_active_announcements, save_feedback, get_latest_release,
    log_analytics_event, get_analytics_summary,
)
from utils.config import settings

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
