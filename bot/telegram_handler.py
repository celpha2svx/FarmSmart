"""
Telegram bot handler — maps Telegram commands to FarmSmart's command handlers.
Uses FastAPI webhook mode (no polling).
"""

import logging
from telegram import Update, Bot
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from telegram.request import HTTPXRequest

from bot.commands import (
    get_soil_moisture_message, get_weather_message, get_pest_message,
    get_help_message, get_unknown_command, handle_stop, handle_update,
    subscribe_daily, get_pest_signs, get_scouting_guide_message,
)
from bot.registration import start_registration, handle_registration_step, is_registering
from database.operations import get_farmer_by_phone, create_farmer, update_farmer, log_alert
from utils.helpers import normalize_command
from utils.config import settings

logger = logging.getLogger(__name__)

_application: Application | None = None
_bot: Bot | None = None


async def _get_or_create_user(phone: str, db) -> tuple:
    """Get or create a Telegram user as a farmer."""
    from database.models import Farmer
    farmer = get_farmer_by_phone(db, phone)
    return farmer


def _make_farmer(phone: str, db):
    """Build a mock Farmer-like object from DB or create placeholder."""
    return get_farmer_by_phone(db, phone)


async def _start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /start command — same as REGISTER in WhatsApp."""
    user_id = str(update.effective_user.id)
    text = start_registration(f"tg_{user_id}")
    await update.message.reply_text(text)


async def _handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle incoming text message — same routing as WhatsApp."""
    from database.operations import get_farmer_by_phone
    from database.models import init_db
    from sqlalchemy.orm import sessionmaker
    from utils.helpers import normalize_command

    user_id = f"tg_{update.effective_user.id}"
    text = update.message.text.strip()
    cmd = normalize_command(text)

    # Quick-access commands
    if text.startswith("/"):
        cmd = text[1:].upper()

    engine = init_db(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()

    try:
        # Registration flow
        if is_registering(user_id) or cmd in ("HI", "HELLO", "REGISTER", "START"):
            if not is_registering(user_id):
                if cmd in ("HI", "HELLO", "REGISTER"):
                    farmer = get_farmer_by_phone(db, user_id)
                    if farmer:
                        await update.message.reply_text(
                            f"Welcome back, {farmer.location_raw}!\n\n"
                            "Send SOIL, WEATHER, or PEST for your farm report."
                        )
                        return
                    msg = start_registration(user_id)
                    await update.message.reply_text(msg)
                    return

            msg, farmer_data = handle_registration_step(user_id, text)
            if farmer_data:
                farmer_data["phone"] = user_id
                new_farmer = create_farmer(
                    db,
                    phone=farmer_data["phone"],
                    crop=farmer_data["crop"],
                    location_raw=farmer_data["location_raw"],
                    lat=farmer_data["lat"],
                    lon=farmer_data["lon"],
                    farm_size=farmer_data["farm_size"],
                )
            await update.message.reply_text(msg)
            return

        farmer = get_farmer_by_phone(db, user_id)
        if not farmer:
            msg = start_registration(user_id)
            await update.message.reply_text(msg)
            return

        # Route command
        from bot.commands import (
            get_soil_moisture_message, get_weather_message, get_pest_message,
            get_help_message, get_unknown_command, handle_stop, handle_update,
            subscribe_daily, get_pest_signs, get_scouting_guide_message,
        )
        COMMANDS = {
            "SOIL": get_soil_moisture_message,
            "WEATHER": get_weather_message,
            "PEST": get_pest_message,
            "UPDATE": handle_update,
            "STOP": handle_stop,
            "HELP": get_help_message,
            "DAILY": subscribe_daily,
            "SCOUT": get_scouting_guide_message,
            "SIGNS": get_pest_signs,
            "START": lambda f: "Alerts resumed!",
        }
        handler = COMMANDS.get(cmd, get_unknown_command)
        reply = handler(farmer)
        await update.message.reply_text(reply)

        if cmd == "STOP":
            update_farmer(db, user_id, subscribed=0)
        elif cmd == "START":
            update_farmer(db, user_id, subscribed=1)
        elif cmd == "DAILY":
            update_farmer(db, user_id, daily_update=1)

    finally:
        db.close()


async def _help(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(get_help_message(None))


async def _soil(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = f"tg_{update.effective_user.id}"
    engine = init_db(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        farmer = get_farmer_by_phone(db, user_id)
        if farmer:
            msg = get_soil_moisture_message(farmer)
            await update.message.reply_text(msg)
        else:
            await update.message.reply_text("Please register first with /start")
    finally:
        db.close()


async def _weather(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = f"tg_{update.effective_user.id}"
    engine = init_db(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        farmer = get_farmer_by_phone(db, user_id)
        if farmer:
            msg = get_weather_message(farmer)
            await update.message.reply_text(msg)
        else:
            await update.message.reply_text("Please register first with /start")
    finally:
        db.close()


async def _pest(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = f"tg_{update.effective_user.id}"
    engine = init_db(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        farmer = get_farmer_by_phone(db, user_id)
        if farmer:
            msg = get_pest_message(farmer)
            await update.message.reply_text(msg)
        else:
            await update.message.reply_text("Please register first with /start")
    finally:
        db.close()


async def _signs(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = f"tg_{update.effective_user.id}"
    engine = init_db(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        farmer = get_farmer_by_phone(db, user_id)
        if farmer:
            msg = get_pest_signs(farmer)
            await update.message.reply_text(msg)
        else:
            await update.message.reply_text("Please register first with /start")
    finally:
        db.close()


async def _scout(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = f"tg_{update.effective_user.id}"
    engine = init_db(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        farmer = get_farmer_by_phone(db, user_id)
        if farmer:
            msg = get_scouting_guide_message(farmer)
            await update.message.reply_text(msg)
        else:
            await update.message.reply_text("Please register first with /start")
    finally:
        db.close()


async def _daily(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = f"tg_{update.effective_user.id}"
    engine = init_db(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        farmer = get_farmer_by_phone(db, user_id)
        if farmer:
            msg = subscribe_daily(farmer)
            await update.message.reply_text(msg)
            update_farmer(db, user_id, daily_update=1)
        else:
            await update.message.reply_text("Please register first with /start")
    finally:
        db.close()


def build_application() -> Application:
    """Build and return a Telegram Application with all handlers."""
    token = settings.telegram_token
    if not token:
        logger.warning("TELEGRAM_TOKEN not set — Telegram bot disabled")
        return None

    request = HTTPXRequest(connection_pool_size=8)
    app = (
        Application.builder()
        .token(token)
        .request(request)
        .build()
    )

    app.add_handler(CommandHandler("start", _start))
    app.add_handler(CommandHandler("help", _help))
    app.add_handler(CommandHandler("soil", _soil))
    app.add_handler(CommandHandler("weather", _weather))
    app.add_handler(CommandHandler("pest", _pest))
    app.add_handler(CommandHandler("signs", _signs))
    app.add_handler(CommandHandler("scout", _scout))
    app.add_handler(CommandHandler("daily", _daily))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, _handle_message))

    return app


async def handle_telegram_webhook(request_body: dict) -> dict:
    """Process incoming Telegram update."""
    global _application
    try:
        if _application is None:
            _application = build_application()
            if _application is None:
                logger.warning("Telegram disabled — TELEGRAM_TOKEN not set")
                return {"status": "telegram_disabled"}
            await _application.initialize()

        update = Update.de_json(request_body, _application.bot)
        await _application.process_update(update)
        return {"status": "ok"}
    except Exception as e:
        logger.error(f"Telegram webhook error: {e}", exc_info=True)
        return {"status": "error", "detail": str(e)}