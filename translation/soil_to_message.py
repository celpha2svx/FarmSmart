"""
Translation layer: Soil moisture data → farmer-readable WhatsApp message.
No raw numbers ever reach the farmer. Only status labels and clear actions.
"""

from utils.constants import SOIL_THRESHOLDS


def translate_soil_moisture(
    sm_value: float,    # Current soil moisture (m³/m³) from NASA SMAP / Open-Meteo
    sm_trend: float,    # Projected 3-day change in m³/m³
    crop: str,          # Farmer's registered crop
    location: str = "your farm",
) -> str:
    """
    Convert soil moisture data to an actionable WhatsApp message.

    Args:
        sm_value: Current volumetric soil moisture (m³/m³)
        sm_trend: Change in soil moisture over next 3 days (negative = drying)
        crop:     Farmer's registered crop (e.g. 'maize')
        location: Farm location name for personalisation

    Returns:
        Formatted string ready to send via WhatsApp
    """
    t = SOIL_THRESHOLDS.get(crop.lower(), SOIL_THRESHOLDS["maize"])

    # ── Status & Action ────────────────────────────────────────────────────
    if sm_value < t["critical"]:
        status = "🔴 CRITICALLY LOW"
        action = "Irrigate IMMEDIATELY — crop stress is already occurring"
    elif sm_value < t["low"]:
        status = "🟡 LOW"
        action = "Irrigate within 24 hours"
    else:
        status = "🟢 ADEQUATE"
        action = "No irrigation needed now"

    # ── Trend ──────────────────────────────────────────────────────────────
    if sm_trend < -0.02:
        trend = "📉 Dropping fast — soil drying quickly"
    elif sm_trend < -0.01:
        trend = "📉 Dropping slowly"
    elif sm_trend < 0:
        trend = "→ Stable"
    else:
        trend = "📈 Improving (recent rain helped)"

    return (
        f"🌱 *Soil Moisture Status*\n"
        f"Crop: {crop.title()} | {location}\n\n"
        f"Status: {status}\n"
        f"{trend}\n\n"
        f"💧 *Recommended Action:*\n"
        f"{action}\n\n"
        f"_Check again tomorrow or reply SOIL_"
    ).strip()
