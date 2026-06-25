"""
WhatsApp command handlers — one function per bot command.
Each handler takes a Farmer object and returns a message string.
"""

import logging
from datetime import date

from data_pipeline.fetchers.weather import fetch_weather_forecast
from data_pipeline.fetchers.soil_moisture import fetch_soil_moisture
from data_pipeline.fetchers.elevation import get_elevation
from data_pipeline.models.soil_trend import project_soil_moisture, get_irrigation_alert
from data_pipeline.models.pest_models import PestModel, check_humidity_pest_risk
from translation.soil_to_message import translate_soil_moisture
from translation.weather_to_message import translate_weather_forecast
from translation.pest_to_message import (
    translate_pest_risk, get_pest_signs_message, get_scouting_guide
)
from utils.constants import CROP_PESTS

logger = logging.getLogger(__name__)

HELP_MESSAGE = (
    "🌱 *FarmSmart Commands*\n\n"
    "SOIL    — Soil moisture & irrigation advice\n"
    "WEATHER — 3-day local forecast\n"
    "PEST    — Pest risk for your crop\n"
    "DAILY   — Subscribe to 6 AM daily updates\n"
    "STOP    — Pause all alerts\n"
    "START   — Resume alerts\n"
    "UPDATE  — Change crop, location, or farm size\n"
    "SCOUT   — How to inspect your farm\n"
    "SIGNS   — What to look for (pest symptoms)\n"
    "HELP    — Show this list\n\n"
    "_FarmSmart — Farm smart, no be guesswork_ 🇳🇬"
)


def get_soil_moisture_message(farmer) -> str:
    try:
        sm_data  = fetch_soil_moisture(farmer.lat, farmer.lon)
        weather  = fetch_weather_forecast(farmer.lat, farmer.lon, days=5)
        elev     = get_elevation(farmer.lat, farmer.lon)
        doy      = date.today().timetuple().tm_yday

        projection = project_soil_moisture(
            current_sm        = sm_data["sm_value"],
            forecast_days     = weather["daily"],
            elevation_m       = elev,
            latitude_deg      = farmer.lat,
            day_of_year_start = doy,
        )
        return translate_soil_moisture(
            sm_value = sm_data["sm_value"],
            sm_trend = projection["sm_trend"],
            crop     = farmer.crop,
            location = farmer.location_raw,
        )
    except Exception as e:
        logger.error(f"Soil command failed for {farmer.phone}: {e}")
        return "⚠️ Could not fetch soil data right now. Please try again in a few minutes."


def get_weather_message(farmer) -> str:
    try:
        weather = fetch_weather_forecast(farmer.lat, farmer.lon, days=3)
        return translate_weather_forecast(
            daily_forecasts = weather["daily"],
            location        = farmer.location_raw,
        )
    except Exception as e:
        logger.error(f"Weather command failed for {farmer.phone}: {e}")
        return "⚠️ Could not fetch weather data right now. Please try again later."


def get_pest_message(farmer) -> str:
    try:
        weather   = fetch_weather_forecast(farmer.lat, farmer.lon, days=7)
        daily     = weather["daily"]
        pests     = CROP_PESTS.get(farmer.crop.lower(), ["fall_armyworm"])
        messages  = []

        for pest_id in pests:
            model = PestModel.from_config(pest_id)
            for day in daily:
                model.add_daily_reading(
                    tmax=day.get("temp_max", 32),
                    tmin=day.get("temp_min", 22),
                )

            # Check humidity risk for fungal diseases
            humidity     = daily[-1].get("humidity_percent", 60) if daily else 60
            humidity_risk = check_humidity_pest_risk(humidity, 0)
            result       = model.add_daily_reading(
                tmax=daily[0].get("temp_max", 32) if daily else 32,
                tmin=daily[0].get("temp_min", 22) if daily else 22,
            )
            msg = translate_pest_risk(result, humidity_risk)
            if msg:
                messages.append(msg)

        if messages:
            return "\n\n".join(messages)
        return (
            f"✅ *Pest Risk for {farmer.crop.title()}*\n\n"
            f"Risk Level: 🟢 LOW / MINIMAL\n\n"
            f"No pest alerts at this time.\n"
            f"Continue monitoring your farm normally.\n\n"
            f"_Reply SCOUT for farm inspection tips_"
        )
    except Exception as e:
        logger.error(f"Pest command failed for {farmer.phone}: {e}")
        return "⚠️ Could not fetch pest data right now. Please try again later."


def get_help_message(farmer) -> str:
    return HELP_MESSAGE


def get_unknown_command(farmer) -> str:
    return (
        "❓ I didn't understand that command.\n\n"
        "Reply *HELP* to see all available commands.\n\n"
        "_Common commands: SOIL · WEATHER · PEST · DAILY_"
    )


def handle_stop(farmer) -> str:
    return (
        "⏸ *Alerts paused.*\n\n"
        "You won't receive automatic updates.\n"
        "Reply *START* to resume, or any command (SOIL, WEATHER, PEST) for instant reports.\n\n"
        "_We'll keep your farm data ready for when you return._"
    )


def handle_update(farmer) -> str:
    return (
        "✏️ *Update your farm profile*\n\n"
        "What would you like to change?\n\n"
        "Reply:\n"
        "UPDATE CROP — Change your crop\n"
        "UPDATE LOCATION — Change your farm location\n"
        "UPDATE SIZE — Change your farm size"
    )


def subscribe_daily(farmer) -> str:
    return (
        "✅ *Daily updates activated!*\n\n"
        "You'll receive a farm report every morning at 6 AM.\n"
        "It will include: soil status, weather, and any pest alerts.\n\n"
        "_Reply STOP anytime to pause alerts._"
    )


def get_pest_signs(farmer) -> str:
    pests = CROP_PESTS.get(farmer.crop.lower(), ["fall_armyworm"])
    # Return signs for the highest-priority pest for this crop
    from utils.constants import PEST_CONFIG
    pest_name = PEST_CONFIG[pests[0]]["name"]
    return get_pest_signs_message(pest_name)


def get_scouting_guide_message(farmer) -> str:
    return get_scouting_guide(farmer.crop)
