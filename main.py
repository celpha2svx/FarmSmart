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
from dotenv import load_dotenv
from sqlalchemy.orm import sessionmaker, Session

from database.models import init_db
from database.operations import (
    get_farmer_by_phone, create_farmer, update_farmer, log_alert
)
from bot.whatsapp_handler import (
    send_whatsapp_message, extract_message, verify_webhook_signature,
)
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
    level=os.environ.get("LOG_LEVEL", "INFO"),
    handlers=[_handler],
    force=True,
)
logger = logging.getLogger("farmsmart")

# ── Database setup ─────────────────────────────────────────────────────────────
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./farmsmart.db")
engine       = init_db(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


def get_db() -> Session:
    return SessionLocal()


# ── WhatsApp config ────────────────────────────────────────────────────────────
VERIFY_TOKEN = os.environ.get("VERIFY_TOKEN", "farmsmart_verify")

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


# ── App lifespan (startup / shutdown) ──────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("FarmSmart starting up...")
    start_scheduler(get_db, send_whatsapp_message)
    yield
    logger.info("FarmSmart shutting down...")
    stop_scheduler()


app = FastAPI(
    title="FarmSmart",
    description="Precision Agriculture Advisory Platform for Nigerian Smallholder Farmers",
    version="1.0.0",
    lifespan=lifespan,
)


# ── Webhook verification (GET) — Meta handshake ────────────────────────────────
@app.get("/webhook")
async def verify_webhook(request: Request):
    """Meta verifies this endpoint when you configure the WhatsApp Cloud API."""
    mode      = request.query_params.get("hub.mode")
    token     = request.query_params.get("hub.verify_token")
    challenge = request.query_params.get("hub.challenge")

    if mode == "subscribe" and token == VERIFY_TOKEN:
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
    db      = get_db()

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


# ── Health check ───────────────────────────────────────────────────────────────
@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "FarmSmart", "version": "1.0.0"}


# ── Local dev entry point ──────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)