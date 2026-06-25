"""
FarmSmart — FastAPI application entry point.
Handles WhatsApp webhook verification + message routing.
"""

import os
import logging
import json
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.responses import PlainTextResponse
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy import text

from database.models import init_db
from database.operations import (
    get_farmer_by_phone, create_farmer, update_farmer, log_alert
)
from bot.whatsapp_handler import (
    send_whatsapp_message, extract_message, verify_webhook_signature,
)
from bot.sms_handler import send_sms, sms_format
from bot.telegram_handler import handle_telegram_webhook
from bot.registration import (
    is_registering, start_registration, handle_registration_step
)
from bot.commands import (
    get_soil_moisture_message, get_weather_message, get_pest_message,
    get_help_message, get_unknown_command, handle_stop, handle_update,
    subscribe_daily, get_pest_signs, get_scouting_guide_message,
)
from data_pipeline.scheduler import start_scheduler, stop_scheduler
from utils.helpers import normalize_command
from utils.config import settings
from utils.rate_limiter import is_rate_limited
from utils.admin_alerts import notify_admin

load_dotenv()

# ── Structured JSON logging ─────────────────────────────────────────────────────
class JSONFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level":     record.levelname,
            "logger":    record.name,
            "message":   record.getMessage(),
        }
        if record.exc_info and record.exc_info[0]:
            log_entry["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_entry)

_handler = logging.StreamHandler()
_handler.setFormatter(JSONFormatter())
logging.basicConfig(
    level=settings.log_level,
    handlers=[_handler],
    force=True,
)
logger = logging.getLogger("farmsmart")

# ── Database setup (with connection pooling) ────────────────────────────────────
_pool_config = {}
if settings.database_url.startswith("postgresql"):
    _pool_config = {
        "pool_size": 5,
        "max_overflow": 10,
        "pool_pre_ping": True,
        "pool_recycle": 3600,
    }

engine = init_db(settings.database_url, **_pool_config)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


def get_db() -> Session:
    return SessionLocal()


# ── Command router ─────────────────────────────────────────────────────────────
COMMANDS = {
    "SOIL":    get_soil_moisture_message,
    "WEATHER": get_weather_message,
    "PEST":    get_pest_message,
    "UPDATE":  handle_update,
    "STOP":    handle_stop,
    "HELP":    get_help_message,
    "DAILY":   subscribe_daily,
    "SCOUT":   get_scouting_guide_message,
    "SIGNS":   get_pest_signs,
    "START":   lambda f: "Alerts resumed! You'll receive updates again.",
}


def route_command(farmer, command: str) -> str:
    handler = COMMANDS.get(command, get_unknown_command)
    return handler(farmer)


def send_message(phone: str, message: str) -> bool:
    """Send a message via available channel: WhatsApp or SMS."""
    if settings.whatsapp_token:
        return send_whatsapp_message(phone, message)
    return send_sms(phone, sms_format(message))


# ── App lifespan (startup / shutdown) ──────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("FarmSmart starting up...")
    try:
        start_scheduler(get_db, send_whatsapp_message)
    except Exception as e:
        logger.error(f"Scheduler start failed: {e}")
        notify_admin(f"Scheduler failed to start: {e}")
    yield
    logger.info("FarmSmart shutting down...")
    stop_scheduler()


app = FastAPI(
    title="FarmSmart",
    description="Precision Agriculture Advisory Platform for Nigerian Smallholder Farmers",
    version="1.0.0",
    lifespan=lifespan,
)

# ── CORS middleware (allow WhatsApp Meta servers) ──────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


# ── Webhook verification (GET) — Meta handshake ────────────────────────────────
@app.get("/webhook")
async def verify_webhook(request: Request):
    """Meta verifies this endpoint when you configure the WhatsApp Cloud API."""
    mode      = request.query_params.get("hub.mode")
    token     = request.query_params.get("hub.verify_token")
    challenge = request.query_params.get("hub.challenge")

    if mode == "subscribe" and token == settings.verify_token:
        logger.info("WhatsApp webhook verified successfully")
        return PlainTextResponse(content=challenge)

    logger.warning("Webhook verification failed — token mismatch")
    return Response(status_code=403)


# ── Incoming message handler (POST) ───────────────────────────────────────────
@app.post("/webhook")
async def receive_message(request: Request):
    # Read raw body for signature verification
    raw_body = await request.body()
    sig_header = request.headers.get("X-Hub-Signature-256")

    if not verify_webhook_signature(raw_body, sig_header):
        logger.warning("Webhook rejected — invalid signature")
        return Response(status_code=403)

    body    = await request.json()
    payload = extract_message(body)

    if not payload:
        return {"status": "no_message"}

    phone   = payload["phone"]
    text    = normalize_command(payload["text"])

    # Rate limiting
    if is_rate_limited(phone):
        logger.warning(f"Rate limited: {phone}")
        return {"status": "rate_limited"}

    db = get_db()

    try:
        # ── Handle active registration flow ───────────────────────────────
        if is_registering(phone) or text in ("HI", "HELLO", "REGISTER", "START"):
            if not is_registering(phone):
                if text in ("HI", "HELLO", "REGISTER"):
                    farmer = get_farmer_by_phone(db, phone)
                    if farmer:
                        reply = (
                            f"Welcome back, {farmer.location_raw}!\n\n"
                            "Reply SOIL, WEATHER, or PEST for your farm report.\n"
                            "Reply HELP for all commands."
                        )
                        send_whatsapp_message(phone, reply)
                        return {"status": "processed"}
                    msg = start_registration(phone)
                    send_whatsapp_message(phone, msg)
                    return {"status": "registration_started"}

            msg, farmer_data = handle_registration_step(phone, text)
            if farmer_data:
                # Registration complete — save to DB
                new_farmer = create_farmer(
                    db,
                    phone        = farmer_data["phone"],
                    crop         = farmer_data["crop"],
                    location_raw = farmer_data["location_raw"],
                    lat          = farmer_data["lat"],
                    lon          = farmer_data["lon"],
                    farm_size    = farmer_data["farm_size"],
                )
                log_alert(db, new_farmer.id, "registration", msg)
            send_whatsapp_message(phone, msg)
            return {"status": "registration_step"}

        # ── Handle commands for registered farmers ─────────────────────────
        farmer = get_farmer_by_phone(db, phone)
        if not farmer:
            reply = start_registration(phone)
            send_whatsapp_message(phone, reply)
            return {"status": "registration_started"}

        # Handle STOP/START — update DB
        if text == "STOP":
            update_farmer(db, phone, subscribed=0)
        elif text == "START":
            update_farmer(db, phone, subscribed=1)
        elif text == "DAILY":
            update_farmer(db, phone, daily_update=1)

        reply = route_command(farmer, text)
        send_whatsapp_message(phone, reply)
        log_alert(db, farmer.id, "command", reply)
        return {"status": "processed"}

    finally:
        db.close()


# ── Telegram bot webhook ───────────────────────────────────────────────────────
@app.post("/telegram_webhook")
async def telegram_webhook(request: Request):
    """Receive updates from Telegram via webhook."""
    body = await request.json()
    return await handle_telegram_webhook(body)


# ── SMS webhook (Africa's Talking) ────────────────────────────────────────────
@app.post("/sms_webhook")
async def sms_webhook(request: Request):
    """Receive incoming SMS from Africa's Talking."""
    try:
        form = await request.form()
        phone = form.get("from", "").strip()
        text  = form.get("text", "").strip()
        # AT sometimes sends JSON too
        if not phone:
            body = await request.json()
            phone = body.get("from", "")
            text  = body.get("text", "")

        if not phone:
            return {"status": "no_phone"}

        cmd = normalize_command(text)
        db = get_db()

        try:
            if is_registering(phone) or cmd in ("REGISTER", "START"):
                if not is_registering(phone):
                    farmer = get_farmer_by_phone(db, phone)
                    if farmer:
                        send_sms(phone, sms_format(
                            f"Welcome back, {farmer.location_raw}! "
                            "Reply SOIL, WEATHER, or PEST."
                        ))
                        db.close()
                        return {"status": "processed"}
                    msg = start_registration(phone)
                    send_sms(phone, sms_format(msg))
                    db.close()
                    return {"status": "registration_started"}

                msg, farmer_data = handle_registration_step(phone, text)
                if farmer_data:
                    create_farmer(db, phone=farmer_data["phone"],
                                  crop=farmer_data["crop"],
                                  location_raw=farmer_data["location_raw"],
                                  lat=farmer_data["lat"],
                                  lon=farmer_data["lon"],
                                  farm_size=farmer_data["farm_size"])
                send_sms(phone, sms_format(msg))
                db.close()
                return {"status": "registration_step"}

            farmer = get_farmer_by_phone(db, phone)
            if not farmer:
                msg = start_registration(phone)
                send_sms(phone, sms_format(msg))
                db.close()
                return {"status": "registration_started"}

            if cmd == "STOP":
                update_farmer(db, phone, subscribed=0)
            elif cmd == "START":
                update_farmer(db, phone, subscribed=1)
            elif cmd == "DAILY":
                update_farmer(db, phone, daily_update=1)

            reply = route_command(farmer, cmd)
            send_sms(phone, sms_format(reply))
            log_alert(db, farmer.id, "command", reply)
            return {"status": "processed"}
        finally:
            db.close()
    except Exception as e:
        logger.error(f"SMS webhook error: {e}")
        return {"status": "error"}


# ── Test endpoint (browser-testable, no messaging account needed) ─────────────
@app.get("/test/{command}")
async def test_command(
    command: str,
    phone: str  = "2348012345678",
    crop: str   = "maize",
    location: str = "Zaria",
    lat: float  = 11.0780,
    lon: float  = 7.7020,
):
    """Test any command in your browser without a messaging account.

    Examples:
      GET /test/soil?crop=maize&lat=11.1&lon=7.7
      GET /test/weather?crop=tomato&lat=6.4&lon=7.5
      GET /test/pest?crop=cowpea&lat=10.3&lon=9.8
      GET /test/help
      GET /test/scout?crop=pepper
      GET /test/signs?crop=maize
    """
    from unittest.mock import MagicMock
    from bot.commands import (
        get_soil_moisture_message, get_weather_message, get_pest_message,
        get_help_message, get_unknown_command, get_pest_signs,
        get_scouting_guide_message,
    )

    farmer = MagicMock()
    farmer.phone = phone
    farmer.crop = crop.lower()
    farmer.location_raw = location
    farmer.lat = lat
    farmer.lon = lon
    farmer.farm_size = "medium"
    farmer.subscribed = 1
    farmer.daily_update = 1

    handlers = {
        "soil":    get_soil_moisture_message,
        "weather": get_weather_message,
        "pest":    get_pest_message,
        "help":    get_help_message,
        "scout":   get_scouting_guide_message,
        "signs":   get_pest_signs,
    }

    handler = handlers.get(command.lower(), get_unknown_command)
    try:
        msg = handler(farmer)
        return PlainTextResponse(content=msg)
    except Exception as e:
        return PlainTextResponse(
            content=f"Error: {type(e).__name__}: {e}",
            status_code=500,
        )


# ── Health check (with DB connectivity) ────────────────────────────────────────
@app.get("/health")
async def health_check():
    db_ok = False
    try:
        db = get_db()
        db.execute(text("SELECT 1"))
        db.close()
        db_ok = True
    except Exception as e:
        logger.error(f"Health check DB failure: {e}")

    return {
        "status": "ok" if db_ok else "degraded",
        "service": "FarmSmart",
        "version": "1.0.0",
        "database": "connected" if db_ok else "unreachable",
    }


# ── Local dev entry point ──────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)