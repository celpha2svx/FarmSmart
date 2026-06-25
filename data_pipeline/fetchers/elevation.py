"""
SRTM elevation data loader.
Used for lapse-rate temperature correction in Penman-Monteith.

For Nigeria's relatively flat terrain the elevation correction is small
but important for Jos Plateau farmers (~1200m elevation).

Strategy:
  1. Pre-built lookup table for major Nigerian farming regions.
  2. Open-Elevation API fallback (free, no key).
"""

import httpx
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# Pre-loaded elevation (metres) for major Nigerian farming regions
NIGERIA_ELEVATION: dict[tuple, float] = {
    # (lat_rounded_1dp, lon_rounded_1dp): elevation_m
    (10.5, 7.4):   612.0,   # Kaduna
    (11.1, 7.7):   656.0,   # Zaria
    (12.0, 8.6):   476.0,   # Kano
    (9.9,  8.9):  1220.0,   # Jos
    (7.4,  3.9):   150.0,   # Ibadan
    (7.1,  3.4):    60.0,   # Abeokuta
    (6.5,  3.4):     5.0,   # Lagos
    (7.8,  8.5):    97.0,   # Makurdi
    (9.6,  6.6):   260.0,   # Minna
    (8.5,  4.5):   307.0,   # Ilorin
    (4.8,  7.0):     5.0,   # Port Harcourt
    (10.3, 9.8):   597.0,   # Bauchi
    (13.1, 5.2):   264.0,   # Sokoto
}


def get_elevation(lat: float, lon: float) -> float:
    """
    Return farm elevation in metres.
    Uses lookup table first, then Open-Elevation API.
    """
    # Local lookup (rounded to 1 decimal place)
    key = (round(lat, 1), round(lon, 1))
    if key in NIGERIA_ELEVATION:
        elev = NIGERIA_ELEVATION[key]
        logger.debug(f"Elevation for ({lat}, {lon}) from table: {elev}m")
        return elev

    # API fallback
    return _fetch_elevation_api(lat, lon)


def _fetch_elevation_api(lat: float, lon: float) -> float:
    """Fetch elevation from Open-Elevation (free, no API key)."""
    try:
        url    = "https://api.open-elevation.com/api/v1/lookup"
        params = {"locations": f"{lat},{lon}"}
        resp   = httpx.get(url, params=params, timeout=10)
        resp.raise_for_status()
        results = resp.json().get("results", [])
        if results:
            elev = float(results[0].get("elevation", 250.0))
            logger.info(f"Elevation from API for ({lat}, {lon}): {elev}m")
            return elev
    except Exception as e:
        logger.warning(f"Elevation API failed for ({lat}, {lon}): {e}")

    # Default: Nigeria average elevation ~250m
    return 250.0
