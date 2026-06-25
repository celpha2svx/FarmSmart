"""
Tests for the Penman-Monteith ET₀ calculation.

Validates model accuracy using reference values for Northern Nigeria
dry season conditions. Expected ET₀ range: 4–8 mm/day.
"""

import pytest
from data_pipeline.models.penman_monteith import calculate_eto, _extraterrestrial_radiation


class TestExtraterrestrialRadiation:
    def test_kaduna_dry_season(self):
        """Kaduna (11°N), January (day 15) — lower sun angle."""
        Ra = _extraterrestrial_radiation(lat_deg=11.0, doy=15)
        assert 20 < Ra < 36, f"Ra={Ra:.2f} — expected 20–36 MJ/m²/day"

    def test_equatorial_dry_season(self):
        """Near equator, March (day 80) — high Ra expected."""
        Ra = _extraterrestrial_radiation(lat_deg=5.0, doy=80)
        assert 30 < Ra < 42, f"Ra={Ra:.2f} — expected 30–42 MJ/m²/day"


class TestCalculateEto:
    """
    Reference values cross-checked against FAO-56 example tables
    and CROPWAT model for Nigerian coordinates.
    """

    def test_kaduna_typical_dry_season(self):
        """Kaduna dry season (Nov–Feb): expect 5–8 mm/day."""
        eto = calculate_eto(
            temperature_c      = 28.0,
            humidity_percent   = 30.0,
            wind_speed_ms      = 2.5,
            solar_radiation_mj = 20.0,
            elevation_m        = 612.0,
            latitude_deg       = 11.05,
            day_of_year        = 15,
        )
        assert 5.0 <= eto <= 9.0, f"ET₀={eto:.2f} — dry season Kaduna expected 5–9 mm/day"

    def test_wet_season_lower_eto(self):
        """Wet season (Aug): high humidity → lower ET₀."""
        eto = calculate_eto(
            temperature_c      = 27.0,
            humidity_percent   = 80.0,
            wind_speed_ms      = 1.5,
            solar_radiation_mj = 14.0,
            elevation_m        = 612.0,
            latitude_deg       = 11.05,
            day_of_year        = 220,
        )
        assert 2.0 <= eto <= 6.0, f"ET₀={eto:.2f} — wet season expected 2–6 mm/day"

    def test_zero_eto_not_negative(self):
        """ET₀ must never be negative."""
        eto = calculate_eto(
            temperature_c      = 10.0,
            humidity_percent   = 99.0,
            wind_speed_ms      = 0.0,
            solar_radiation_mj = 0.0,
            elevation_m        = 0.0,
            latitude_deg       = 11.0,
            day_of_year        = 355,
        )
        assert eto >= 0, f"ET₀ must not be negative, got {eto}"

    def test_high_temperature_high_eto(self):
        """Sahel hot, dry day → very high ET₀."""
        eto = calculate_eto(
            temperature_c      = 40.0,
            humidity_percent   = 15.0,
            wind_speed_ms      = 4.0,
            solar_radiation_mj = 25.0,
            elevation_m        = 300.0,
            latitude_deg       = 13.0,
            day_of_year        = 90,
        )
        assert eto >= 8.0, f"ET₀={eto:.2f} — hot dry Sahel should be ≥8 mm/day"

    def test_returns_float(self):
        eto = calculate_eto(28, 60, 2, 18, 250, 11, 100)
        assert isinstance(eto, float)
