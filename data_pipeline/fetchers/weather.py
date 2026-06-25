"""
Open-Meteo weather data fetcher.
Free API — no key required. 7-day hourly forecast, global coverage.
"""

import logging
from datetime import date, timedelta
from utils.constants import OPEN_METEO_URL
from utils.http_client import build_client

logger = logging.getLogger(__name__)


def fetch_weather_forecast(
    lat: float, lon: float, days: int = 7, timezone: str = "Africa/Lagos"
) -> dict:
    """
    Fetch weather forecast from Open-Meteo for a given location.

    Returns:
        {
            'daily': [
                {
                    'date': 'YYYY-MM-DD',
                    'temperature_c': float,
                    'temp_max': float,
                    'temp_min': float,
                    'humidity_percent': float,
                    'rainfall_mm': float,
                    'wind_speed_ms': float,
                    'solar_radiation_mj': float,
                    'rain_probability': float,
                },
                ...
            ],
            'location': {'lat': float, 'lon': float},
        }

    Raises:
        httpx.HTTPError on network or API failure.
    """
    params = {
        "latitude":                    lat,
        "longitude":                   lon,
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_sum",
            "relative_humidity_2m_max",
            "wind_speed_10m_max",
            "shortwave_radiation_sum",
            "precipitation_probability_max",
        ],
        "wind_speed_unit": "ms",
        "timezone":        timezone,
        "forecast_days":   days,
    }

    logger.info(f"Fetching Open-Meteo forecast for ({lat}, {lon})")
    client = build_client(timeout=15)
    response = client.get(OPEN_METEO_URL, params=params)
    response.raise_for_status()
    raw = response.json()

    daily_raw = raw.get("daily", {})
    dates     = daily_raw.get("time", [])

    daily = []
    for i, d in enumerate(dates):
        tmax = _safe(daily_raw, "temperature_2m_max", i)
        tmin = _safe(daily_raw, "temperature_2m_min", i)
        daily.append({
            "date":              d,
            "temperature_c":     round((tmax + tmin) / 2, 1),
            "temp_max":          tmax,
            "temp_min":          tmin,
            "humidity_percent":  _safe(daily_raw, "relative_humidity_2m_max", i),
            "rainfall_mm":       _safe(daily_raw, "precipitation_sum", i),
            "wind_speed_ms":     _safe(daily_raw, "wind_speed_10m_max", i),
            "solar_radiation_mj": _safe(daily_raw, "shortwave_radiation_sum", i),
            "rain_probability":  _safe(daily_raw, "precipitation_probability_max", i),
        })

    return {
        "daily":    daily,
        "location": {"lat": lat, "lon": lon},
    }


def _safe(data: dict, key: str, index: int, default: float = 0.0) -> float:
    """Safely extract a value from an Open-Meteo daily array."""
    try:
        val = data[key][index]
        return float(val) if val is not None else default
    except (KeyError, IndexError, TypeError):
        return default