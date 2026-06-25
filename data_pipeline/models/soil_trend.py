"""
Soil moisture 3-day trend projection.

Combines current NASA SMAP satellite reading with ET₀ forecast
to project soil moisture forward 3–5 days.
"""

import logging
from data_pipeline.models.penman_monteith import calculate_eto
from utils.constants import SOIL_THRESHOLDS

logger = logging.getLogger(__name__)


def project_soil_moisture(
    current_sm: float,          # Current soil moisture (m³/m³) from NASA SMAP
    forecast_days: list[dict],  # List of daily weather dicts from Open-Meteo
    elevation_m: float,
    latitude_deg: float,
    day_of_year_start: int,
) -> dict:
    """
    Project soil moisture forward using ET₀ and expected rainfall.

    Args:
        current_sm:       Current soil moisture reading (m³/m³)
        forecast_days:    List of dicts with keys:
                            temperature_c, humidity_percent, wind_speed_ms,
                            solar_radiation_mj, rainfall_mm
        elevation_m:      Farm elevation for ET₀ calculation
        latitude_deg:     Farm latitude for ET₀ calculation
        day_of_year_start: Julian day for first forecast day

    Returns:
        dict with:
            projected_sm_day3: float
            daily_balance:     list of daily net water balance (mm)
            sm_trend:          float (change in m³/m³ over 3 days, approx)
            days_processed:    int
    """
    sm = current_sm
    daily_balance = []
    sm_history    = [current_sm]

    for i, day in enumerate(forecast_days[:5]):  # Cap at 5-day forecast
        doy = day_of_year_start + i

        eto = calculate_eto(
            temperature_c      = day.get("temperature_c", 28.0),
            humidity_percent   = day.get("humidity_percent", 60.0),
            wind_speed_ms      = day.get("wind_speed_ms", 2.0),
            solar_radiation_mj = day.get("solar_radiation_mj", 18.0),
            elevation_m        = elevation_m,
            latitude_deg       = latitude_deg,
            day_of_year        = doy,
        )

        rainfall_mm = day.get("rainfall_mm", 0.0)
        net_loss_mm = eto - rainfall_mm  # Positive = soil losing water

        # Convert mm water loss to change in volumetric soil moisture
        # Assumes ~150mm effective root zone depth (0–10cm SMAP layer ~100mm)
        ROOT_ZONE_MM  = 100.0
        sm_change     = -(net_loss_mm / ROOT_ZONE_MM)
        sm            = max(0.0, sm + sm_change)

        daily_balance.append({
            "day":          i + 1,
            "eto_mm":       round(eto, 2),
            "rainfall_mm":  round(rainfall_mm, 2),
            "net_loss_mm":  round(net_loss_mm, 2),
            "sm_projected": round(sm, 3),
        })
        sm_history.append(sm)

    sm_trend = sm_history[min(3, len(sm_history) - 1)] - sm_history[0]

    return {
        "initial_sm":       round(current_sm, 3),
        "projected_sm_day3": round(sm_history[min(3, len(sm_history) - 1)], 3),
        "sm_trend":         round(sm_trend, 4),
        "daily_balance":    daily_balance,
        "days_processed":   len(daily_balance),
    }


def get_irrigation_alert(
    current_sm: float,
    projected_sm: float,
    sm_trend: float,
    crop: str,
) -> dict:
    """
    Determine if an irrigation alert should be sent based on current
    soil moisture level and 3-day projection.

    Returns:
        dict with 'alert' (bool), 'urgency' ('HIGH'|'MEDIUM'|None),
        and 'reason' string.
    """
    t = SOIL_THRESHOLDS.get(crop.lower(), SOIL_THRESHOLDS["maize"])

    if current_sm < t["critical"]:
        return {"alert": True, "urgency": "HIGH",   "reason": "critically_low_now"}
    if current_sm < t["low"]:
        return {"alert": True, "urgency": "MEDIUM", "reason": "low_now"}
    if projected_sm < t["critical"] and sm_trend < -0.01:
        return {"alert": True, "urgency": "MEDIUM", "reason": "will_be_critical_soon"}
    if projected_sm < t["low"]:
        return {"alert": True, "urgency": "LOW",    "reason": "will_be_low_soon"}

    return {"alert": False, "urgency": None, "reason": "adequate"}
