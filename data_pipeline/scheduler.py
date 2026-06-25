"""
APScheduler cron jobs for FarmSmart.

Jobs:
  - Every 6 hours: Fetch fresh weather + soil data for all active farms
  - Daily at 6 AM WAT: Send daily updates to subscribed farmers
"""

import logging
from datetime import date
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

logger = logging.getLogger(__name__)

_scheduler: BackgroundScheduler | None = None


def start_scheduler(db_session_factory, send_fn):
    """
    Start background scheduler.

    Args:
        db_session_factory: Callable that returns a SQLAlchemy Session
        send_fn:            Callable(phone, message) to send WhatsApp/SMS
    """
    global _scheduler
    _scheduler = BackgroundScheduler(timezone="Africa/Lagos")

    # Every 6 hours — pre-fetch and cache data for all farms
    _scheduler.add_job(
        func=lambda: _prefetch_all_farms(db_session_factory),
        trigger=CronTrigger(hour="0,6,12,18", minute=0),
        id="prefetch_farms",
        name="Pre-fetch farm data every 6 hours",
        replace_existing=True,
    )

    # Daily at 6 AM WAT — send daily update to all subscribed farmers
    _scheduler.add_job(
        func=lambda: _send_daily_updates(db_session_factory, send_fn),
        trigger=CronTrigger(hour=6, minute=0),
        id="daily_updates",
        name="Daily 6 AM farm updates",
        replace_existing=True,
    )

    _scheduler.start()
    logger.info("FarmSmart scheduler started (6-hourly fetch + 6AM daily alerts)")


def stop_scheduler():
    global _scheduler
    if _scheduler and _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("Scheduler stopped")


def _prefetch_all_farms(db_session_factory):
    """Fetch and log weather/soil data for all active farms."""
    try:
        from database.operations import get_all_subscribed_farmers
        from data_pipeline.fetchers.weather import fetch_weather_forecast
        from data_pipeline.fetchers.soil_moisture import fetch_soil_moisture

        db = db_session_factory()
        farmers = get_all_subscribed_farmers(db)
        logger.info(f"Pre-fetching data for {len(farmers)} active farms")

        for farmer in farmers:
            try:
                fetch_weather_forecast(farmer.lat, farmer.lon)
                fetch_soil_moisture(farmer.lat, farmer.lon)
            except Exception as e:
                logger.warning(f"Pre-fetch failed for farmer {farmer.phone}: {e}")

        db.close()
    except Exception as e:
        logger.error(f"Prefetch job failed: {e}")


def _send_daily_updates(db_session_factory, send_fn):
    """Send 6 AM daily farm report to all subscribed farmers."""
    try:
        from database.operations import get_daily_update_farmers, log_alert
        from bot.commands import get_soil_moisture_message, get_weather_message, get_pest_message

        db      = db_session_factory()
        farmers = get_daily_update_farmers(db)
        logger.info(f"Sending daily updates to {len(farmers)} farmers")

        for farmer in farmers:
            try:
                soil    = get_soil_moisture_message(farmer)
                weather = get_weather_message(farmer)
                pest    = get_pest_message(farmer)

                # Compose compact daily summary
                daily_msg = (
                    f"🌅 *FarmSmart Daily Update*\n"
                    f"Good morning! Here's your farm report.\n\n"
                    f"{soil}\n\n"
                    f"─────────────────\n\n"
                    f"{weather}"
                )

                # Send pest alert separately if HIGH/MEDIUM risk
                if "PEST ALERT" in pest or "Pest Advisory" in pest:
                    send_fn(farmer.phone, pest)
                    log_alert(db, farmer.id, "pest", pest, "HIGH", "whatsapp")

                send_fn(farmer.phone, daily_msg)
                log_alert(db, farmer.id, "daily", daily_msg, None, "whatsapp")

            except Exception as e:
                logger.error(f"Daily update failed for {farmer.phone}: {e}")

        db.close()
    except Exception as e:
        logger.error(f"Daily update job failed: {e}")
