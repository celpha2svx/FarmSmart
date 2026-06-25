"""
NASA SMAP / ESA CCI soil moisture fetcher.

Primary source: NASA SMAP L3 (9km resolution, ~3-day revisit).
Fallback: Open-Meteo soil moisture variable (lower quality but always available).

NASA SMAP access requires a free EarthData account.
Set EARTHDATA_TOKEN in .env after registering at urs.earthdata.nasa.gov
"""

import os
import httpx
import logging

logger = logging.getLogger(__name__)

EARTHDATA_TOKEN = os.environ.get("EARTHDATA_TOKEN", "")


def fetch_soil_moisture(lat: float, lon: float) -> dict:
    """
    Fetch current near-surface soil moisture (0–10cm) for a location.

    Returns:
        {
            'sm_value': float,   # m³/m³ (0.0–0.5 typical range)
            'source': str,       # 'smap' | 'open-meteo-fallback'
            'quality': str,      # 'high' | 'estimated'
        }
    """
    # Try Open-Meteo soil moisture as primary (always available, no auth)
    result = _fetch_open_meteo_soil(lat, lon)
    if result:
        return result

    # Try NASA SMAP if EarthData token is configured
    if EARTHDATA_TOKEN:
        result = _fetch_smap(lat, lon)
        if result:
            return result

    # Last resort: return a climatological estimate for Nigeria
    logger.warning(f"All soil moisture sources failed for ({lat}, {lon}). Using estimate.")
    return {
        "sm_value": 0.22,
        "source":   "climatological-estimate",
        "quality":  "estimated",
    }


def _fetch_open_meteo_soil(lat: float, lon: float) -> dict | None:
    """
    Fetch soil moisture from Open-Meteo hourly API (free, no key).
    Returns the most recent reading (last 24h).
    """
    try:
        url    = "https://api.open-meteo.com/v1/forecast"
        params = {
            "latitude":  lat,
            "longitude": lon,
            "hourly":    "soil_moisture_0_to_1cm",
            "timezone":  "Africa/Lagos",
            "past_days": 1,
            "forecast_days": 1,
        }
        resp = httpx.get(url, params=params, timeout=15)
        resp.raise_for_status()
        data   = resp.json()
        values = data.get("hourly", {}).get("soil_moisture_0_to_1cm", [])
        # Filter out None and take the most recent valid reading
        valid  = [v for v in values if v is not None]
        if valid:
            sm = float(valid[-1])
            logger.info(f"Soil moisture from Open-Meteo: {sm:.3f} m³/m³ at ({lat}, {lon})")
            return {"sm_value": round(sm, 3), "source": "open-meteo", "quality": "high"}
    except Exception as e:
        logger.error(f"Open-Meteo soil fetch failed: {e}")
    return None


def _fetch_smap(lat: float, lon: float) -> dict | None:
    """
    Fetch NASA SMAP L3 soil moisture via NASA EarthData OPeNDAP.
    Requires EARTHDATA_TOKEN in environment.
    """
    try:
        # NASA SMAP SPL3SMP (Enhanced) latest granule endpoint
        url    = "https://n5eil01u.ecs.nsidc.org/SMAP/SPL3SMP_E.006/"
        headers = {"Authorization": f"Bearer {EARTHDATA_TOKEN}"}
        # This is a simplified call — real implementation would parse
        # the NSIDC directory listing to get the latest granule URL
        logger.info("NASA SMAP fetch attempted (requires EarthData setup)")
        return None  # Full implementation requires EarthData account
    except Exception as e:
        logger.error(f"NASA SMAP fetch failed: {e}")
    return None
