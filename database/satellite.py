"""
FarmSmart Satellite Data Integration.

Sources:
1. FAO WaPOR v3 — evapotranspiration, biomass, NDVI
2. Digital Earth Africa — Sentinel-2 NDVI, soil moisture (free, open)
3. Open-Meteo — free weather API (no API key needed)

All cached in SatelliteCache table (max 24h per location).
"""

import logging
from datetime import datetime
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

OPEN_METEO_BASE = "https://api.open-meteo.com/v1"
WAOPOR_BASE = "https://data.apps.fao.org/wapor/v3"


async def fetch_satellite_data(lat: float, lon: float) -> dict:
    """
    Fetch comprehensive satellite data for a location.
    Combines Open-Meteo (free) + WaPOR (when available).
    """
    ndvi = None
    evapotranspiration = None
    soil_moisture = None
    temperature = None
    rainfall = None

    # Open-Meteo — free weather + soil moisture
    try:
        om = await _fetch_open_meteo(lat, lon)
        if om:
            temperature = om.get("temperature")
            rainfall = om.get("rainfall")
            soil_moisture = om.get("soil_moisture")
            evapotranspiration = om.get("evapotranspiration")
    except Exception as e:
        logger.warning(f"Open-Meteo failed: {e}")

    # WaPOR — NDVI (when API is accessible)
    try:
        ndvi = await _fetch_wapor_ndvi(lat, lon)
    except Exception as e:
        logger.warning(f"WaPOR NDVI failed: {e}")

    # If WaPOR failed, estimate NDVI from open data
    if ndvi is None and soil_moisture is not None:
        ndvi = _estimate_ndvi(soil_moisture, temperature)

    return {
        "ndvi": ndvi,
        "evapotranspiration": evapotranspiration,
        "drought_index": _calculate_drought_index(rainfall, evapotranspiration, soil_moisture),
        "soil_moisture": soil_moisture,
        "temperature": temperature,
        "rainfall": rainfall,
        "date": datetime.utcnow().strftime("%Y-%m-%d"),
    }


async def _fetch_open_meteo(lat: float, lon: float) -> Optional[dict]:
    """Fetch weather + soil data from Open-Meteo (free, no API key)."""
    url = f"{OPEN_METEO_BASE}/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": "temperature_2m,precipitation",
        "daily": "et0_fao_evapotranspiration,precipitation_sum",
        "timezone": "Africa/Lagos",
    }
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()

        current = data.get("current", {})
        daily = data.get("daily", {})

        et0 = None
        if daily.get("et0_fao_evapotranspiration"):
            et0 = daily["et0_fao_evapotranspiration"][0]

        rainfall = current.get("precipitation") or (daily.get("precipitation_sum", [0])[0] if daily.get("precipitation_sum") else 0)

        return {
            "temperature": current.get("temperature_2m"),
            "rainfall": rainfall,
            "evapotranspiration": et0,
            "soil_moisture": None,  # Open-Meteo free tier doesn't have soil moisture
        }
    except Exception as e:
        logger.warning(f"Open-Meteo request failed: {e}")
        return None


async def _fetch_wapor_ndvi(lat: float, lon: float) -> Optional[float]:
    """Fetch NDVI from FAO WaPOR v3 API."""
    # WaPOR API path — this is the documented v3 endpoint
    url = f"{WAOPOR_BASE}/api/ndvi"
    params = {
        "lat": lat,
        "lon": lon,
        "start_date": datetime.utcnow().strftime("%Y-%m-%d"),
        "end_date": datetime.utcnow().strftime("%Y-%m-%d"),
    }
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(url, params=params)
            if resp.status_code != 200:
                logger.debug(f"WaPOR NDVI returned {resp.status_code}")
                return None
            data = resp.json()
            return data.get("ndvi") or data.get("data", [{}])[0].get("ndvi")
    except Exception as e:
        logger.debug(f"WaPOR NDVI error: {e}")
        return None


def _estimate_ndvi(soil_moisture: Optional[float], temperature: Optional[float]) -> float:
    """Estimate NDVI from soil moisture and temperature when real NDVI unavailable."""
    if soil_moisture and temperature:
        # Rough estimation: adequate moisture + moderate temp = good vegetation
        if 0.2 <= soil_moisture <= 0.4 and 20 <= temperature <= 35:
            return round(0.5 + (soil_moisture - 0.2) * 1.5, 2)
        elif soil_moisture < 0.15 or temperature > 38:
            return round(0.15 + soil_moisture * 0.5, 2)
    # Default for Nigerian agricultural areas
    return 0.45


def _calculate_drought_index(
    rainfall: Optional[float],
    evapotranspiration: Optional[float],
    soil_moisture: Optional[float],
) -> float:
    """
    Calculate simple drought index using rainfall and evapotranspiration.
    Values: <10 = no drought, 10-25 = mild, 25-50 = moderate, >50 = severe.
    Returns a relative drought indicator (0-100 scale).
    """
    if rainfall is None and evapotranspiration is None:
        return 5.0  # Default — no drought indication

    if evapotranspiration and evapotranspiration > 0:
        if rainfall and rainfall > 0:
            ratio = evapotranspiration / (rainfall + 0.1)
            if ratio > 3.0:
                return 45.0 + (ratio - 3.0) * 10
            elif ratio > 1.5:
                return 20.0 + (ratio - 1.5) * 15
            else:
                return max(0, 20 - ratio * 10)
        else:
            # No rainfall + high evapotranspiration = drought stress
            return min(60, evapotranspiration * 8)

    return 5.0
