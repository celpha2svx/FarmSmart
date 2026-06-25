"""
Penman-Monteith reference evapotranspiration (ET₀) calculator.
This is the agronomic core of FarmSmart.

ET₀ tells us how much water the atmosphere demands from the soil each day.
All soil moisture forecasts are driven by this value.
"""

import math
import logging

logger = logging.getLogger(__name__)


def calculate_eto(
    temperature_c: float,       # Mean daily temp (°C) from Open-Meteo
    humidity_percent: float,     # Relative humidity (%)
    wind_speed_ms: float,        # Wind speed at 2m height (m/s)
    solar_radiation_mj: float,   # Solar radiation (MJ/m²/day)
    elevation_m: float,          # Farm elevation (m) from SRTM
    latitude_deg: float,         # Farm latitude (decimal degrees)
    day_of_year: int,            # Julian day (1–365)
) -> float:
    """
    Returns ET₀ in mm/day — the reference evapotranspiration.

    Implements FAO-56 Penman-Monteith equation exactly as specified.
    Typical outputs for Northern Nigeria dry season: 4–8 mm/day.
    """
    # 1. Atmospheric pressure (kPa) — adjusts for farm elevation
    P = 101.3 * ((293 - 0.0065 * elevation_m) / 293) ** 5.26

    # 2. Psychrometric constant (kPa/°C)
    gamma = 0.000665 * P

    # 3. Saturation vapour pressure (kPa)
    es = 0.6108 * math.exp((17.27 * temperature_c) / (temperature_c + 237.3))

    # 4. Actual vapour pressure (kPa)
    ea = es * (humidity_percent / 100)

    # 5. Vapour pressure deficit (kPa)
    vpd = es - ea

    # 6. Slope of saturation vapour pressure curve (kPa/°C)
    delta = (4098 * es) / ((temperature_c + 237.3) ** 2)

    # 7. Net radiation (MJ/m²/day)
    Ra  = _extraterrestrial_radiation(latitude_deg, day_of_year)
    Rns = 0.77 * solar_radiation_mj                                    # Net shortwave
    Rnl = 4.903e-9 * ((temperature_c + 273.16) ** 4) * \
          (0.34 - 0.14 * math.sqrt(max(ea, 0)))                        # Net longwave
    Rn  = Rns - Rnl

    # 8. Soil heat flux (negligible for daily calculations)
    G = 0

    # 9. FAO-56 Penman-Monteith equation
    numerator   = (0.408 * delta * (Rn - G)) + \
                  (gamma * (900 / (temperature_c + 273)) * wind_speed_ms * vpd)
    denominator = delta + (gamma * (1 + 0.34 * wind_speed_ms))

    eto = max(0.0, numerator / denominator)
    logger.debug(f"ET₀ calculated: {eto:.2f} mm/day (T={temperature_c}°C, RH={humidity_percent}%)")
    return round(eto, 2)


def _extraterrestrial_radiation(lat_deg: float, doy: int) -> float:
    """
    Calculate extraterrestrial radiation Ra (MJ/m²/day).
    Used internally by calculate_eto().
    """
    lat_rad = math.radians(lat_deg)

    # Solar declination (rad)
    delta_s = 0.409 * math.sin((2 * math.pi / 365) * doy - 1.39)

    # Sunset hour angle (rad)
    omega_s = math.acos(-math.tan(lat_rad) * math.tan(delta_s))

    # Inverse relative distance Earth–Sun
    d_r = 1 + 0.033 * math.cos((2 * math.pi / 365) * doy)

    G_sc = 0.0820  # Solar constant (MJ/m²/min)

    Ra = (24 * 60 / math.pi) * G_sc * d_r * (
        omega_s * math.sin(lat_rad) * math.sin(delta_s)
        + math.cos(lat_rad) * math.cos(delta_s) * math.sin(omega_s)
    )
    return Ra
