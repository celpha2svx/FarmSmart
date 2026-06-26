"""
Telegram bot handler — direct API calls, no external library needed.
"""

import logging
import json
from utils.http_client import build_client
from utils.config import settings

logger = logging.getLogger(__name__)

API_BASE = "https://api.telegram.org/bot"


def _token() -> str:
    return settings.telegram_token


async def send_message(chat_id: int, text: str) -> bool:
    """Send a message via Telegram Bot API."""
    token = _token()
    if not token:
        return False
    try:
        client = build_client(timeout=10)
        resp = client.post(
            f"{API_BASE}{token}/sendMessage",
            json={"chat_id": chat_id, "text": text, "parse_mode": "Markdown"},
        )
        resp.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"Telegram send failed: {e}")
        return False


async def handle_telegram_webhook(request_body: dict) -> dict:
    """Process incoming Telegram update and route to command handlers."""
    try:
        message = request_body.get("message", {})
        chat_id = message.get("chat", {}).get("id")
        text = (message.get("text") or "").strip()

        if not chat_id or not text:
            return {"status": "ignored"}

        user_id = f"tg_{chat_id}"
        cmd = text.upper()

        from database.operations import get_farmer_by_phone, create_farmer, update_farmer
        from database.models import init_db
        from sqlalchemy.orm import sessionmaker

        engine = init_db(settings.database_url)
        SessionLocal = sessionmaker(bind=engine)
        db = SessionLocal()

        try:
            from bot.registration import is_registering, start_registration, handle_registration_step
            from bot.commands import (
                get_soil_moisture_message, get_weather_message, get_pest_message,
                get_help_message, get_unknown_command, handle_stop, handle_update,
                subscribe_daily, get_pest_signs, get_scouting_guide_message,
            )

            if cmd in ("/START", "START", "HI", "HELLO", "REGISTER"):
                if not is_registering(user_id):
                    farmer = get_farmer_by_phone(db, user_id)
                    if farmer:
                        await send_message(chat_id, f"Welcome back, {farmer.location_raw}!\n\nSend SOIL, WEATHER, or PEST for your farm report.")
                        return {"status": "processed"}
                    msg = start_registration(user_id)
                    await send_message(chat_id, msg)
                    return {"status": "ok"}

            if is_registering(user_id):
                msg, farmer_data = handle_registration_step(user_id, text)
                if farmer_data:
                    farmer_data["phone"] = user_id
                    create_farmer(db, phone=farmer_data["phone"], crop=farmer_data["crop"],
                                  location_raw=farmer_data["location_raw"], lat=farmer_data["lat"],
                                  lon=farmer_data["lon"], farm_size=farmer_data["farm_size"])
                await send_message(chat_id, msg)
                return {"status": "ok"}

            farmer = get_farmer_by_phone(db, user_id)
            if not farmer:
                msg = start_registration(user_id)
                await send_message(chat_id, msg)
                return {"status": "ok"}

            # Strip leading / for command-style messages
            if cmd.startswith("/"):
                cmd = cmd[1:]

            COMMANDS = {
                "SOIL": get_soil_moisture_message,
                "WEATHER": get_weather_message,
                "PEST": get_pest_message,
                "HELP": get_help_message,
                "STOP": handle_stop,
                "UPDATE": handle_update,
                "DAILY": subscribe_daily,
                "SCOUT": get_scouting_guide_message,
                "SIGNS": get_pest_signs,
                "START": lambda f: "Alerts resumed!",
            }

            handler = COMMANDS.get(cmd, get_unknown_command)
            reply = handler(farmer)
            await send_message(chat_id, reply)

            if cmd == "STOP":
                update_farmer(db, user_id, subscribed=0)
            elif cmd == "START":
                update_farmer(db, user_id, subscribed=1)
            elif cmd == "DAILY":
                update_farmer(db, user_id, daily_update=1)

        finally:
            db.close()

        return {"status": "ok"}
    except Exception as e:
        logger.error(f"Telegram webhook error: {e}", exc_info=True)
        return {"status": "error", "detail": str(e)}